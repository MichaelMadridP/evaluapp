import 'dart:convert';

import 'package:evaluapp/services/email_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class FakeAuthTokenProvider implements AuthTokenProvider {
  FakeAuthTokenProvider({
    this.authenticated = true,
    this.token = 'valid-token',
  });

  bool authenticated;
  String? token;
  int calls = 0;
  final List<bool> forceRefreshCalls = [];

  @override
  bool get hasAuthenticatedUser => authenticated;

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    calls++;
    forceRefreshCalls.add(forceRefresh);
    return token;
  }
}

void main() {
  const relayUrl = 'https://relay.example.test';

  EmailService serviceWith({
    required MockClient client,
    FakeAuthTokenProvider? auth,
    Duration timeout = const Duration(seconds: 1),
  }) {
    return EmailService(
      client: client,
      authTokenProvider: auth ?? FakeAuthTokenProvider(),
      relayBaseUrl: relayUrl,
      timeout: timeout,
    );
  }

  Future<EmailSendResult> send(EmailService service,
      {List<String> recipients = const ['student@example.com']}) {
    return service.sendReport(
      recipients: recipients,
      subject: 'Reporte',
      html: '<html>Reporte</html>',
      text: 'Reporte',
    );
  }

  test('usuario autenticado y respuesta 200 retorna messageId', () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode({'success': true, 'messageId': 'msg_123'}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final result = await send(serviceWith(client: client));

    expect(result.success, isTrue);
    expect(result.messageId, 'msg_123');
    expect(captured.url.toString(), '$relayUrl/send');
    expect(captured.headers['Authorization'], 'Bearer valid-token');
    final payload = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(payload['html'], '<html>Reporte</html>');
    expect(payload['text'], 'Reporte');
  });

  test('configuración productiva resuelve exactamente POST /send', () {
    expect(evaluAppMailRelayUrl, defaultEvaluAppMailRelayUrl);
    expect(
      EmailService.buildSendUri(evaluAppMailRelayUrl).toString(),
      'https://evaluapp-mail-relay.michael-madrid-p.workers.dev/send',
    );
  });

  test('normaliza /send sin producir /send/send', () {
    expect(
      EmailService.buildSendUri('$relayUrl/send/').toString(),
      '$relayUrl/send',
    );
  });

  test('rechaza relay sin HTTPS o sin host antes de ejecutar HTTP', () async {
    var requests = 0;
    final diagnostics = <String>[];
    final client = MockClient((_) async {
      requests++;
      return http.Response('{}', 200);
    });
    final service = EmailService(
      client: client,
      authTokenProvider: FakeAuthTokenProvider(),
      relayBaseUrl: 'evaluapp-mail-relay.example.test',
      diagnosticLogger: diagnostics.add,
    );

    final result = await send(service);

    expect(result.errorCode, 'RELAY_NOT_CONFIGURED');
    expect(requests, 0);
    expect(diagnostics, contains('relayConfigured=false'));
  });

  test('diagnóstico de red es seguro y no registra payload ni token', () async {
    final diagnostics = <String>[];
    final client = MockClient((_) async {
      throw http.ClientException('Failed host lookup: relay.example.test');
    });
    final service = EmailService(
      client: client,
      authTokenProvider: FakeAuthTokenProvider(token: 'super-secret-token'),
      relayBaseUrl: relayUrl,
      diagnosticLogger: diagnostics.add,
    );

    final result = await service.sendReport(
      recipients: const ['student@example.com'],
      subject: 'Private subject',
      html: '<html>Private academic content</html>',
      text: 'Private academic content',
    );

    expect(result.errorCode, 'NETWORK_ERROR');
    expect(diagnostics, contains('networkFailure=dns'));
    final joined = diagnostics.join('\n');
    expect(joined, isNot(contains('super-secret-token')));
    expect(joined, isNot(contains('student@example.com')));
    expect(joined, isNot(contains('Private academic content')));
  });

  test('usuario no autenticado no ejecuta HTTP', () async {
    var requests = 0;
    final client = MockClient((_) async {
      requests++;
      return http.Response('{}', 200);
    });
    final auth = FakeAuthTokenProvider(authenticated: false);

    final result = await send(serviceWith(client: client, auth: auth));

    expect(result.success, isFalse);
    expect(result.errorCode, 'AUTH_REQUIRED');
    expect(requests, 0);
    expect(auth.calls, 0);
  });

  test('401 refresca el token una sola vez y traduce el error', () async {
    var requests = 0;
    final client = MockClient((_) async {
      requests++;
      return http.Response(
        jsonEncode({
          'success': false,
          'error': {'code': 'INVALID_TOKEN', 'message': 'internal detail'}
        }),
        401,
      );
    });
    final auth = FakeAuthTokenProvider();

    final result = await send(serviceWith(client: client, auth: auth));

    expect(result.success, isFalse);
    expect(result.errorCode, 'INVALID_TOKEN');
    expect(requests, 2);
    expect(auth.forceRefreshCalls, [false, true]);
    expect(result.errorMessage, isNot(contains('internal detail')));
  });

  test('429 retorna RATE_LIMITED con mensaje amigable', () async {
    final client = MockClient((_) async => http.Response(
          jsonEncode({
            'success': false,
            'error': {'code': 'RATE_LIMITED', 'message': 'Daily limit'}
          }),
          429,
        ));

    final result = await send(serviceWith(client: client));

    expect(result.success, isFalse);
    expect(result.errorCode, 'RATE_LIMITED');
    expect(result.errorMessage, contains('límite diario'));
  });

  for (final status in [500, 502]) {
    test('$status retorna un error de servidor controlado', () async {
      final client = MockClient((_) async => http.Response(
            jsonEncode({'success': false, 'error': {}}),
            status,
          ));

      final result = await send(serviceWith(client: client));

      expect(result.success, isFalse);
      expect(result.errorCode,
          status == 502 ? 'EMAIL_PROVIDER_ERROR' : 'SERVER_ERROR');
    });
  }

  test('timeout retorna TIMEOUT', () async {
    final client = MockClient((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return http.Response('{}', 200);
    });

    final result = await send(serviceWith(
      client: client,
      timeout: const Duration(milliseconds: 10),
    ));

    expect(result.success, isFalse);
    expect(result.errorCode, 'TIMEOUT');
  });

  test('respuesta JSON inválida retorna INVALID_RESPONSE', () async {
    final client =
        MockClient((_) async => http.Response('<html>bad</html>', 200));

    final result = await send(serviceWith(client: client));

    expect(result.success, isFalse);
    expect(result.errorCode, 'INVALID_RESPONSE');
  });

  test('lista vacía se rechaza sin HTTP', () async {
    var requests = 0;
    final client = MockClient((_) async {
      requests++;
      return http.Response('{}', 200);
    });

    final result = await send(serviceWith(client: client), recipients: []);

    expect(result.errorCode, 'RECIPIENTS_REQUIRED');
    expect(requests, 0);
  });

  test('más de cinco destinatarios se rechazan sin HTTP', () async {
    var requests = 0;
    final client = MockClient((_) async {
      requests++;
      return http.Response('{}', 200);
    });
    final recipients = List.generate(6, (i) => 'user$i@example.com');

    final result =
        await send(serviceWith(client: client), recipients: recipients);

    expect(result.errorCode, 'TOO_MANY_RECIPIENTS');
    expect(requests, 0);
  });

  test('destinatarios se recortan y deduplican sin distinguir mayúsculas',
      () async {
    late Map<String, dynamic> payload;
    final client = MockClient((request) async {
      payload = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(jsonEncode({'success': true}), 200);
    });

    final result = await send(
      serviceWith(client: client),
      recipients: const [
        ' Student@Example.com ',
        'student@example.com',
        'teacher@example.com',
      ],
    );

    expect(result.success, isTrue);
    expect(payload['to'], ['student@example.com', 'teacher@example.com']);
  });
}
