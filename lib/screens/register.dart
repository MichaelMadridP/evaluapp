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
  bool _isLoading = false;

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

    // Intentar la conexión
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final UserCredential userCredential =
          await auth.createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text);

      if (userCredential.user?.uid != null) {
        // Conexión exitosa
        await userCredential.user
            ?.updateDisplayName(_usernameController.text.trim());

        // Crear el usuario en la base de datos
        await createNewUserOnDatabase(userCredential.user!.uid,
            _usernameController.text.trim(), _emailController.text.trim());

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '¡Cuenta de ${_usernameController.text.trim()} creada exitosamente!'),
          duration: const Duration(seconds: 2),
        ));

        // Esperar brevemente antes de navegar
        await Future.delayed(const Duration(seconds: 2));

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
        msg = 'Error de registro: ${e.message ?? e.code}';
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
      return;
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
          'Registro',
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
                          Text('Crea una cuenta',
                              style: TextStyle(
                                color: colors.authSubtitle,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              )),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _usernameController,
                            enabled: !_isLoading,
                            style: TextStyle(color: colors.authText),
                            decoration: InputDecoration(
                                labelStyle:
                                    TextStyle(color: colors.authInputLabel),
                                labelText: 'Nombre',
                                hintText: 'Nombre',
                                icon: const Icon(Icons.person),
                                iconColor: colors.authInputIcon,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                      color: colors.authInputIcon, width: 2),
                                )),
                            keyboardType: TextInputType.name,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.words,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa tu nombre';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
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
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            enabled: !_isLoading,
                            style: TextStyle(color: colors.authText),
                            decoration: InputDecoration(
                                labelStyle:
                                    TextStyle(color: colors.authInputLabel),
                                labelText: 'Contraseña',
                                hintText: 'Contraseña',
                                icon: const Icon(Icons.password),
                                iconColor: colors.authInputIcon,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                      color: colors.authInputIcon, width: 2),
                                )),
                            keyboardType: TextInputType.visiblePassword,
                            autocorrect: false,
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa una contraseña';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    _doRegister(context);
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
                                : const Text('Crear Cuenta',
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
                Text('EvaluApp 2.1.0 - MikeMad 2026',
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
