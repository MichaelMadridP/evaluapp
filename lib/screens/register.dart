
import 'package:evaluapp/data_model/data_connect.dart';
import 'package:evaluapp/screens/auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
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

    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Por favor ingresa todos los datos solicitados'),
        duration: Duration(seconds: 3), // Duración personalizada
      ));
      return;
    }

    if (!_isValidEmail(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Por favor ingresa un email válido'),
        duration: Duration(seconds: 3), // Duración personalizada
      ));
      return;
    }

    // Intentar la conexión
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final UserCredential userCredential = await auth.createUserWithEmailAndPassword(
          email: _emailController.text, password: _passwordController.text);
      
      if (userCredential.user?.uid != null) {
        // Conexión exitosa
        // Actualizar el nombbre del usuario en el registro de autenticación del usuario en Firebase Auth
        await userCredential.user?.updateDisplayName(_usernameController.text);

        // Crear el usuario en la base de datos
        createNewUserOnDatabase(userCredential.user!.uid, _usernameController.text, _emailController.text);

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '¡Cuenta de ${_usernameController.text} creada exitosamente!'),
          duration: const Duration(seconds: 3), // Duración personalizada
        ));

        // Esperar a que el SnackBar desaparezca antes de navegar
        await Future.delayed(const Duration(seconds: 3));

        if (!context.mounted) return;
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const AuthScreen()));
      } else {
        msg = 'Error al crear cuenta';
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        msg = 'El correo ya está en uso por otra cuenta.';
      } else if (e.code == 'invalid-email') {
        msg = 'El correo no tiene un formato válido.';
      } else if (e.code == 'weak-password') {
        msg = 'La contraseña es demasiado débil.';
      } else if (e.code == 'operation-not-allowed') {
        msg =
            'La creación de cuentas con correo y contraseña no está habilitada.';
      } else {
        msg = 'Error de registro: ${e.message!.isEmpty ? e.message : e.code}';
      }
    }

    if (msg.isNotEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 3), // Duración personalizada
      ));
      return;
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
        title: const Text('Registro'),
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
                          const Text('Crea una cuenta',
                              style: TextStyle(
                                color: Color.fromARGB(255, 226, 205, 250),
                                fontSize: 18,
                              )),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _usernameController,
                            style: const TextStyle(
                                color: Color.fromARGB(255, 226, 205, 250)),
                            decoration: const InputDecoration(
                                labelStyle: TextStyle(
                                    color: Color.fromARGB(255, 226, 205, 250)),
                                labelText: 'Nombre',
                                hintText: 'Nombre',
                                icon: Icon(Icons.person),
                                iconColor: Color.fromARGB(255, 226, 205, 250),
                                border: OutlineInputBorder()),
                            keyboardType: TextInputType.name,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa tu nombre';
                              }
                              return null;
                            },
                          ),
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
                            child: const Text('   Crear Cuenta   ',
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
