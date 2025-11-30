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

    if (!_isValidEmail(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Por favor ingresa un email válido'),
        duration: Duration(seconds: 3),
      ));
      return;
    }

    // Intentar enviar el correo de recuperación
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      await auth.sendPasswordResetEmail(email: _emailController.text);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text('Correo de recuperación enviado a ${_emailController.text}'),
        duration: const Duration(seconds: 3),
      ));

      await Future.delayed(const Duration(seconds: 3));

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
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AuthScreen()));
              },
            ),
          ],
        ),
        title: const Text('Recuperar Contraseña'),
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
                const SizedBox(height: 40),
                Text('EvaluApp',
                    style: TextStyle(
                      color: colors.authTitle,
                      fontSize: 30,
                    )),
                const SizedBox(height: 20),
                Text('Tu evaluador predictivo de notas',
                    style: TextStyle(
                      color: colors.authSubtitle,
                      fontSize: 18,
                    )),
                const SizedBox(height: 14),
                Card(
                  color: colors.authCardBackground,
                  margin: const EdgeInsets.only(top: 20),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Recuperar Contraseña',
                              style: TextStyle(
                                color: colors.authSubtitle,
                                fontSize: 18,
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
                            style: TextStyle(color: colors.authText),
                            decoration: InputDecoration(
                                labelStyle:
                                    TextStyle(color: colors.authInputLabel),
                                labelText: 'Email',
                                hintText: 'Email',
                                icon: const Icon(Icons.email),
                                iconColor: colors.authInputIcon,
                                border: const OutlineInputBorder()),
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
                          TextButton(
                            onPressed: () {
                              _sendRecoveryEmail(context);
                            },
                            style: TextButton.styleFrom(
                                backgroundColor: colors.authButtonBackground,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(100))),
                            child: Text('   Enviar Correo   ',
                                style: TextStyle(
                                    color: colors.authButtonText,
                                    fontSize: 14)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const SizedBox(height: 12),
                const SizedBox(height: 20),
                const SizedBox(height: 50),
                Text('2025 © EvaluApp by Mikemad',
                    style: TextStyle(
                      color: colors.authFooterText,
                      fontSize: 10,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
