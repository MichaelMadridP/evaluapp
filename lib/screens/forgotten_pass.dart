import 'package:evaluapp/screens/auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:evaluapp/themes.dart';

class ForgottenPassScreen extends StatefulWidget {
  const ForgottenPassScreen({super.key});

  @override
  State<ForgottenPassScreen> createState() => _ForgottenPassScreenState();
}

class _ForgottenPassScreenState extends State<ForgottenPassScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  void _sendRecoveryEmail(BuildContext context) async {
    String msg = '';

    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Por favor ingresa tu email'),
        duration: Duration(seconds: 3),
      ));
      return;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Por favor ingresa un email válido'),
        duration: Duration(seconds: 3),
      ));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Intentar enviar el correo de recuperación
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      await auth.sendPasswordResetEmail(email: _emailController.text.trim());

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Correo de recuperación enviado a ${_emailController.text.trim()}'),
        duration: const Duration(seconds: 2),
      ));

      await Future.delayed(const Duration(seconds: 2));

      if (!context.mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const AuthScreen()));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        msg = 'No se encontró un usuario con ese email.';
      } else if (e.code == 'invalid-email') {
        msg = 'El correo no tiene un formato válido.';
      } else {
        msg = 'Error: ${e.message ?? e.code}';
      }
    } catch (e) {
      msg = 'Error inesperado: $e';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }

    if (msg.isNotEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 3),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeProvider.of(context)!.colors;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.appBarBackground,
        iconTheme: IconThemeData(color: colors.appBarIcon),
        title: Text(
          'Recuperar Contraseña',
          style: TextStyle(color: colors.appBarTitle),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading
              ? null
              : () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AuthScreen()));
                },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [colors.authBackground, colors.backgroundGradientEnd])),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const SizedBox(height: 30),
                Text('EvaluApp',
                    style: TextStyle(
                      color: colors.authTitle,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    )),
                const SizedBox(height: 12),
                Text('Tu evaluador predictivo de notas',
                    style: TextStyle(
                      color: colors.authSubtitle,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    )),
                const SizedBox(height: 14),
                Card(
                  color: colors.authCardBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                        color: colors.matterCardBorder.withValues(alpha: 0.4)),
                  ),
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Recuperar Contraseña',
                              style: TextStyle(
                                color: colors.authSubtitle,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              )),
                          const SizedBox(height: 14),
                          Text(
                            'Ingresa tu email y te enviaremos un correo para recuperar tu contraseña',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.authText,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _emailController,
                            enabled: !_isLoading,
                            style: TextStyle(color: colors.authText),
                            decoration: InputDecoration(
                                labelStyle:
                                    TextStyle(color: colors.authInputLabel),
                                labelText: 'Email',
                                hintText: 'Email',
                                icon: const Icon(Icons.email),
                                iconColor: colors.authInputIcon,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                      color: colors.authInputIcon, width: 2),
                                )),
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa un email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    _sendRecoveryEmail(context);
                                  },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: colors.authButtonBackground,
                                foregroundColor: colors.authButtonText,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 36, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24))),
                            child: _isLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: colors.authButtonText,
                                    ),
                                  )
                                : const Text('Enviar Correo',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Text('EvaluApp 2.0.1 - MikeMad 2026',
                    style: TextStyle(
                      color: colors.authFooterText,
                      fontSize: 11,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
