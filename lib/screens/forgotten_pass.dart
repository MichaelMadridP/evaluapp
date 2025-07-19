import 'package:evaluapp/screens/auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  void _doRegister(BuildContext context) async {
    String msg = '';

    if ((!_isValidEmail(_emailController.text)) ||
        (_emailController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Por favor ingresa un email válido'),
        duration: Duration(seconds: 3), // Duración personalizada
      ));
      return;
    }

    // Intentar el envio de la confirmación de email
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailController.text);

      // Mensaje de éxito
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Correo de restablecimiento enviado. Revisa tu bandeja de entrada.'),
        duration: Duration(seconds: 3),
      ));

      // Esperar a que el SnackBar desaparezca antes de navegar
      await Future.delayed(const Duration(seconds: 3));

      if (!context.mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const AuthScreen()));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') {
        msg = 'El correo electrónico no tiene un formato válido.';
      } else if (e.code == 'user-not-found') {
        msg = 'Error al enviar el correo de restablecimiento.';
      } else {
        msg = 'Error al enviar el correo de restablecimiento: ${e.message}';
      }
    } catch (e) {
      msg =
          'Ocurrió un error inesperado. Por favor, inténtalo de nuevo más tarde.';
    }

    if (msg.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 3),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 183, 131, 252),
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
        title: const Text('Olvido de Contraseña'),
      ),
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
              Color.fromARGB(255, 67, 2, 153),
              Color.fromARGB(255, 14, 0, 32)
            ])),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const SizedBox(height: 40),
                const Text('EvaluApp',
                    style: TextStyle(
                      color: Color.fromARGB(255, 239, 227, 252),
                      fontSize: 30,
                    )),
                const SizedBox(height: 20),
                const Text('Tu evaluador predictivo de notas',
                    style: TextStyle(
                      color: Color.fromARGB(255, 226, 205, 250),
                      fontSize: 18,
                    )),
                const SizedBox(height: 14),
                Card(
                  color: const Color.fromARGB(255, 61, 8, 131),
                  margin: const EdgeInsets.only(top: 20),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Ingresa tu email',
                              style: TextStyle(
                                color: Color.fromARGB(255, 226, 205, 250),
                                fontSize: 18,
                              )),
                          const Center(
                            child: Text(
                                'Si este correo existe en nuestra base de datos, te enviaremos un correo con las instrucciones para recuperar tu contraseña.',
                                style: TextStyle(
                                  color: Color.fromARGB(255, 226, 205, 250),
                                  fontSize: 14,
                                )),
                          ),
                          const SizedBox(height: 14),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(
                                color: Color.fromARGB(255, 226, 205, 250)),
                            decoration: const InputDecoration(
                                labelStyle: TextStyle(
                                    color: Color.fromARGB(255, 226, 205, 250)),
                                labelText: 'Email',
                                hintText: 'Email',
                                icon: Icon(Icons.email),
                                iconColor: Color.fromARGB(255, 226, 205, 250),
                                border: OutlineInputBorder()),
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
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              _doRegister(context);
                            },
                            style: TextButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 107, 68, 168),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(100))),
                            child: const Text(
                                '   Enviar Email de Recuperación   ',
                                style: TextStyle(
                                    color: Color.fromARGB(255, 226, 205, 250),
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
                const Text('2024 © EvaluApp by Mikemad',
                    style: TextStyle(
                      color: Color.fromRGBO(179, 163, 197, 1),
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
