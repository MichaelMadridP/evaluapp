import 'package:evaluapp/data_model/data_connect.dart';
import 'package:evaluapp/screens/auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:evaluapp/themes.dart';

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
      final UserCredential userCredential =
          await auth.createUserWithEmailAndPassword(
              email: _emailController.text, password: _passwordController.text);

      if (userCredential.user?.uid != null) {
        // Conexión exitosa
        // Actualizar el nombbre del usuario en el registro de autenticación del usuario en Firebase Auth
        await userCredential.user?.updateDisplayName(_usernameController.text);

        // Crear el usuario en la base de datos
        createNewUserOnDatabase(userCredential.user!.uid,
            _usernameController.text, _emailController.text);

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
        title: const Text('Registro'),
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
                          Text('Crea una cuenta',
                              style: TextStyle(
                                color: colors.authSubtitle,
                                fontSize: 18,
                              )),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _usernameController,
                            style: TextStyle(color: colors.authText),
                            decoration: InputDecoration(
                                labelStyle:
                                    TextStyle(color: colors.authInputLabel),
                                labelText: 'Nombre',
                                hintText: 'Nombre',
                                icon: const Icon(Icons.person),
                                iconColor: colors.authInputIcon,
                                border: const OutlineInputBorder()),
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
                          TextFormField(
                            controller: _passwordController,
                            style: TextStyle(color: colors.authText),
                            decoration: InputDecoration(
                                labelStyle:
                                    TextStyle(color: colors.authInputLabel),
                                labelText: 'Contraseña',
                                hintText: 'Contraseña',
                                icon: const Icon(Icons.password),
                                iconColor: colors.authInputIcon,
                                border: const OutlineInputBorder()),
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
                                backgroundColor: colors.authButtonBackground,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(100))),
                            child: Text('   Crear Cuenta   ',
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
                Text('2024 © EvaluApp by Mikemad',
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
