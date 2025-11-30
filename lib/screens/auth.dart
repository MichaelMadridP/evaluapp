import 'package:evaluapp/data_model/data_connect.dart';
import 'package:evaluapp/data_model/preferences.dart';
import 'package:evaluapp/main.dart';
import 'package:evaluapp/screens/forgotten_pass.dart';
import 'package:evaluapp/screens/register.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:evaluapp/themes.dart';

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
      final UserCredential userCredential =
          await auth.signInWithEmailAndPassword(
              email: _emailController.text, password: _passwordController.text);

      if (userCredential.user?.uid != null) {
        // Conexión exitosa

        // Guardar el nombre de usuario en la BD y el userID en el archivo local de preferencias
        saveStringPreference(
            'username', userCredential.user!.displayName ?? '');
        saveStringPreference('userid', userCredential.user!.uid);

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
    final colors = ThemeProvider.of(context)!.colors;

    return Scaffold(
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
                          Text('Ingresa a tu cuenta',
                              style: TextStyle(
                                color: colors.authSubtitle,
                                fontSize: 18,
                              )),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _emailController,
                            style: TextStyle(color: colors.authText),
                            decoration: InputDecoration(
                                labelStyle:
                                    TextStyle(color: colors.authInputLabel),
                                labelText: 'Email',
                                hintText: 'Email',
                                icon: Icon(Icons.email),
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
                                icon: Icon(Icons.password),
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
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const ForgottenPassScreen()));
                            },
                            child: Text('¿Olvidaste tu contraseña?',
                                style: TextStyle(
                                    color: colors.authSubtitle, fontSize: 14)),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              _doLogin(context);
                            },
                            style: TextButton.styleFrom(
                                backgroundColor: colors.authButtonBackground,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(100))),
                            child: Text('   Iniciar Sesión   ',
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
                TextButton(
                    onPressed: () {
                      if (!context.mounted) return;
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const RegisterScreen()));
                    },
                    child: Text('¿No tienes cuenta?',
                        style: TextStyle(
                          color: colors.authSubtitle,
                          fontSize: 14,
                        ))),
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
