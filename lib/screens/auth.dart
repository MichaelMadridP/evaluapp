import 'package:evaluapp/data_model/data_connect.dart';
import 'package:evaluapp/data_model/preferences.dart';
import 'package:evaluapp/main.dart';
import 'package:evaluapp/screens/forgotten_pass.dart';
import 'package:evaluapp/screens/register.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _doLogin(BuildContext context) async {
    String msg = '';

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Por favor ingresa tu email y contraseña')));
      return;
    }

    // Intentar la conexión
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final UserCredential userCredential = await auth.signInWithEmailAndPassword(
          email: _emailController.text, password: _passwordController.text);

      if (userCredential.user?.uid != null) {
        // Conexión exitosa

        // Guardar el nombre de usuario en la BD y el userID en el archivo local de preferencias
        saveStringPreference('username', userCredential.user!.displayName ?? '');
        saveStringPreference('userid',   userCredential.user!.uid);

        //Recuperar los datos de la base de datos
        await getData(userCredential.user!.uid, 0);

        if (!context.mounted) return;
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const HomeScreen()));
      } else {
        msg = 'Error al iniciar sesión';
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential') {
        msg = 'Las credenciales proporcionadas no son válidas.';
      } else if (e.code == 'user-not-found') {
        msg = 'No se encontró un usuario con ese email.';
      } else if (e.code == 'wrong-password') {
        msg = 'Usuario o Contraseña incorrecta.';
      } else {
        // Otros errores
        msg = 'Error de ingreso: ${e.message!.isEmpty ? e.message : e.code}';
      }
    }
    if (msg.isNotEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                          const Text('Ingresa a tu cuenta',
                              style: TextStyle(
                                color: Color.fromARGB(255, 226, 205, 250),
                                fontSize: 18,
                              )),
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
                          TextFormField(
                            controller: _passwordController,
                            style: const TextStyle(
                                color: Color.fromARGB(255, 226, 205, 250)),
                            decoration: const InputDecoration(
                                labelStyle: TextStyle(
                                    color: Color.fromARGB(255, 226, 205, 250)),
                                labelText: 'Contraseña',
                                hintText: 'Contraseña',
                                icon: Icon(Icons.password),
                                iconColor: Color.fromARGB(255, 226, 205, 250),
                                border: OutlineInputBorder()),
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa un email';
                              }
                              return null;
                            },
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const ForgottenPassScreen()));    
                            },
                            child: const Text('¿Olvidaste tu contraseña?',
                                style: TextStyle(
                                    color: Color.fromARGB(255, 226, 205, 250),
                                    fontSize: 14)),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              _doLogin(context);
                            },
                            style: TextButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 107, 68, 168),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(100))),
                            child: const Text('   Iniciar Sesión   ',
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
                TextButton(
                    onPressed: () {
                      if (!context.mounted) return;
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const RegisterScreen()));
                    },
                    child: const Text('¿No tienes cuenta?',
                        style: TextStyle(
                          color: Color.fromARGB(255, 226, 205, 250),
                          fontSize: 14,
                        ))),
                const SizedBox(height: 12),
                const SizedBox(height: 20),
                const SizedBox(height: 50),
                const Text('2025 © EvaluApp by Mikemad',
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
