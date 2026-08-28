import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const String defaultEvaluAppMailRelayUrl =
    'https://evaluapp-mail-relay.michael-madrid-p.workers.dev';

const String evaluAppMailRelayUrl = String.fromEnvironment(
  'EVALUAPP_MAIL_RELAY_URL',
  defaultValue: defaultEvaluAppMailRelayUrl,
);

typedef EmailDiagnosticLogger = void Function(String message);

void _defaultEmailDiagnosticLogger(String message) {
  if (kDebugMode) {
    debugPrint('[EmailService] $message');
  }
}

class EmailSendResult {
  const EmailSendResult.success({this.messageId})
      : success = true,
        errorCode = null,
        errorMessage = null;

  const EmailSendResult.failure({
    required this.errorCode,
    required this.errorMessage,
  })  : success = false,
        messageId = null;

  final bool success;
  final String? messageId;
  final String? errorCode;
  final String? errorMessage;
}

abstract interface class AuthTokenProvider {
  bool get hasAuthenticatedUser;

  Future<String?> getIdToken({bool forceRefresh = false});
}

class FirebaseAuthTokenProvider implements AuthTokenProvider {
  FirebaseAuthTokenProvider({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  @override
  bool get hasAuthenticatedUser => _firebaseAuth.currentUser != null;

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) {
    return _firebaseAuth.currentUser?.getIdToken(forceRefresh) ??
        Future<String?>.value();
  }
}

abstract interface class EmailSender {
  Future<EmailSendResult> sendReport({
    required List<String> recipients,
    required String subject,
    required String html,
    required String text,
  });
}

class EmailService implements EmailSender {
  EmailService({
    http.Client? client,
    AuthTokenProvider? authTokenProvider,
    String relayBaseUrl = evaluAppMailRelayUrl,
    EmailDiagnosticLogger? diagnosticLogger,
    this.timeout = const Duration(seconds: 20),
  })  : _client = client ?? http.Client(),
        _authTokenProvider = authTokenProvider ?? FirebaseAuthTokenProvider(),
        _sendUri = buildSendUri(relayBaseUrl),
        _diagnosticLogger = diagnosticLogger ?? _defaultEmailDiagnosticLogger;

  static const int maxRecipients = 5;
  static final RegExp _emailPattern =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  final http.Client _client;
  final AuthTokenProvider _authTokenProvider;
  final Uri? _sendUri;
  final EmailDiagnosticLogger _diagnosticLogger;
  final Duration timeout;

  @override
  Future<EmailSendResult> sendReport({
    required List<String> recipients,
    required String subject,
    required String html,
    required String text,
  }) async {
    _log('relayConfigured=${_sendUri != null}');
    if (_sendUri != null) {
      _log('relayHost=${_sendUri.host} endpointPath=${_sendUri.path}');
    }

    final normalizedRecipients = normalizeRecipients(recipients);
    if (normalizedRecipients.isEmpty) {
      return const EmailSendResult.failure(
        errorCode: 'RECIPIENTS_REQUIRED',
        errorMessage: 'Agrega al menos un destinatario.',
      );
    }
    if (normalizedRecipients.length > maxRecipients) {
      return const EmailSendResult.failure(
        errorCode: 'TOO_MANY_RECIPIENTS',
        errorMessage:
            'Puedes enviar el reporte a un máximo de 5 destinatarios.',
      );
    }
    if (normalizedRecipients.any((email) => !_emailPattern.hasMatch(email))) {
      return const EmailSendResult.failure(
        errorCode: 'INVALID_RECIPIENT',
        errorMessage: 'Revisa las direcciones de correo ingresadas.',
      );
    }
    final authenticated = _authTokenProvider.hasAuthenticatedUser;
    _log('firebaseUserPresent=$authenticated');
    if (!authenticated) {
      return const EmailSendResult.failure(
        errorCode: 'AUTH_REQUIRED',
        errorMessage: 'Inicia sesión nuevamente para enviar el reporte.',
      );
    }
    if (_sendUri == null) {
      return const EmailSendResult.failure(
        errorCode: 'RELAY_NOT_CONFIGURED',
        errorMessage: 'El envío directo no está configurado en esta versión.',
      );
    }

    try {
      final token = await _authTokenProvider.getIdToken();
      _log('firebaseTokenPresent=${token != null && token.isNotEmpty}');
      if (token == null || token.isEmpty) {
        return const EmailSendResult.failure(
          errorCode: 'AUTH_REQUIRED',
          errorMessage: 'Inicia sesión nuevamente para enviar el reporte.',
        );
      }

      final payload = jsonEncode({
        'to': normalizedRecipients,
        'subject': subject,
        'html': html,
        'text': text,
      });
      _log(
        'requestStarted=true htmlBytes=${utf8.encode(html).length} '
        'textBytes=${utf8.encode(text).length} '
        'requestBytes=${utf8.encode(payload).length}',
      );

      var response = await _post(
        token: token,
        payload: payload,
      );
      _log('responseStatus=${response.statusCode}');

      if (response.statusCode == 401) {
        _log('tokenRefreshAttempted=true');
        final refreshedToken =
            await _authTokenProvider.getIdToken(forceRefresh: true);
        if (refreshedToken != null && refreshedToken.isNotEmpty) {
          response = await _post(
            token: refreshedToken,
            payload: payload,
          );
          _log('retryResponseStatus=${response.statusCode}');
        }
      }

      final result = _parseResponse(response);
      if (!result.success) {
        _log('responseErrorCode=${result.errorCode ?? 'UNKNOWN'}');
      }
      return result;
    } on TimeoutException {
      _log('networkFailure=timeout');
      return const EmailSendResult.failure(
        errorCode: 'TIMEOUT',
        errorMessage: 'El envío tardó demasiado. Inténtalo nuevamente.',
      );
    } on http.ClientException catch (error) {
      _log('networkFailure=${_classifyClientException(error)}');
      return const EmailSendResult.failure(
        errorCode: 'NETWORK_ERROR',
        errorMessage: 'No se pudo conectar al servicio de correo.',
      );
    } on FirebaseAuthException {
      _log('firebaseTokenFailure=true');
      return const EmailSendResult.failure(
        errorCode: 'AUTH_REQUIRED',
        errorMessage: 'Tu sesión expiró. Inicia sesión nuevamente.',
      );
    } catch (error) {
      _log('unexpectedFailure=${error.runtimeType}');
      return const EmailSendResult.failure(
        errorCode: 'UNEXPECTED_ERROR',
        errorMessage: 'No se pudo enviar el reporte.',
      );
    }
  }

  Future<http.Response> _post({
    required String token,
    required String payload,
  }) {
    return _client
        .post(
          _sendUri!,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json; charset=utf-8',
          },
          body: payload,
        )
        .timeout(timeout);
  }

  EmailSendResult _parseResponse(http.Response response) {
    Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      return const EmailSendResult.failure(
        errorCode: 'INVALID_RESPONSE',
        errorMessage: 'El servicio devolvió una respuesta no válida.',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      return const EmailSendResult.failure(
        errorCode: 'INVALID_RESPONSE',
        errorMessage: 'El servicio devolvió una respuesta no válida.',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded['success'] == true) {
        return EmailSendResult.success(
          messageId: decoded['messageId']?.toString(),
        );
      }
      return const EmailSendResult.failure(
        errorCode: 'INVALID_RESPONSE',
        errorMessage: 'El servicio devolvió una respuesta no válida.',
      );
    }

    final error = decoded['error'];
    final workerCode =
        error is Map<String, dynamic> ? error['code']?.toString() : null;
    final fallbackCode = switch (response.statusCode) {
      401 => 'UNAUTHORIZED',
      429 => 'RATE_LIMITED',
      502 => 'EMAIL_PROVIDER_ERROR',
      _ when response.statusCode >= 500 => 'SERVER_ERROR',
      _ => 'REQUEST_REJECTED',
    };

    return EmailSendResult.failure(
      errorCode: workerCode ?? fallbackCode,
      errorMessage: _friendlyMessage(workerCode ?? fallbackCode),
    );
  }

  static List<String> normalizeRecipients(List<String> recipients) {
    final result = <String>[];
    final seen = <String>{};
    for (final raw in recipients) {
      final email = raw.trim().toLowerCase();
      if (email.isNotEmpty && seen.add(email)) {
        result.add(email);
      }
    }
    return result;
  }

  static Uri? buildSendUri(String relayBaseUrl) {
    final raw = relayBaseUrl.trim();
    if (raw.isEmpty) return null;

    final uri = Uri.tryParse(raw);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      return null;
    }

    final basePath = uri.path.replaceFirst(RegExp(r'/+$'), '');
    final sendPath = basePath.endsWith('/send') ? basePath : '$basePath/send';
    return uri.replace(path: sendPath.isEmpty ? '/send' : sendPath);
  }

  void _log(String message) => _diagnosticLogger(message);

  static String _classifyClientException(http.ClientException error) {
    final message = error.message.toLowerCase();
    if (message.contains('host lookup') ||
        message.contains('dns') ||
        message.contains('name resolution')) {
      return 'dns';
    }
    if (message.contains('handshake') ||
        message.contains('certificate') ||
        message.contains('tls')) {
      return 'tls';
    }
    if (message.contains('no host') ||
        message.contains('invalid uri') ||
        message.contains('unsupported scheme')) {
      return 'invalid_url';
    }
    if (message.contains('connection') || message.contains('socket')) {
      return 'socket';
    }
    return 'client_exception';
  }

  static String _friendlyMessage(String code) {
    return switch (code) {
      'RATE_LIMITED' =>
        'Alcanzaste el límite diario de envíos. Inténtalo mañana.',
      'UNAUTHORIZED' ||
      'INVALID_TOKEN' =>
        'Tu sesión expiró. Inicia sesión nuevamente.',
      'INVALID_REQUEST' ||
      'REQUEST_REJECTED' =>
        'El reporte no pudo enviarse. Revisa los datos ingresados.',
      'PAYLOAD_TOO_LARGE' => 'El reporte es demasiado grande para enviarlo.',
      'EMAIL_PROVIDER_ERROR' ||
      'SERVER_ERROR' =>
        'El servicio de correo no está disponible. Inténtalo más tarde.',
      _ => 'No se pudo enviar el reporte.',
    };
  }
}
