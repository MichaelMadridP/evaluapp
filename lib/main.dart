import 'package:flutter/material.dart';

import 'package:evaluapp/data_model/data_connect.dart';
import 'package:evaluapp/data_model/preferences.dart';
import 'package:evaluapp/data_model/model.dart';

import 'package:evaluapp/components/edit_matter.dart';
import 'package:evaluapp/components/display_program_data.dart';
import 'package:evaluapp/screens/auth.dart';
// Google Firebase Authentication
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';


//***************************************************************************************/
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSharedPreferences();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<String?> _getUserId() async {
    // Espera a que las preferencias estén listas y devuelve el userid
    return getStringPreference('userid');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EvaluApp',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: FutureBuilder<String?>(
        future: _getUserId(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final userId = snapshot.data;
          if (userId == null) {
            return const AuthScreen();
          } else {
            return const HomeScreen();
          }
        },
      ),
    );
  }
}

//***************************************************************************************/
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _addNewMatter(BuildContext context) {
    // Crear una nueva materia vacia y editarla
    // Si es válida, se agrega a la lista de materias
    final MatterData newMatter = MatterData(
      matterTitle: '',
      dimension: [
        DimensionData(
            dimensionTitle: '',
            numNotes: 1,
            noteList: [0],
            percentageWeight: 50,
            removeWorstNote: false,
            isDismissable: false),
      ],
    );
    // y editarla
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      useSafeArea: true,
      isDismissible: false,
      builder: (ctx) {
        return EditMatter(
          action: ActionType.add,
          matter: newMatter,
          idxMatter: 0,
          onMatterUpdateCB: () {
            setState(() {
              allMattersData.add(newMatter);
              saveData(); // Actualizar la base de datos
            });
          },
          onMatterDeleteCB: (int A) {}, // no se usa en este caso
        );
      },
    );
  }

  void _logout(BuildContext context) {
    // Eliminae el usuario de las preferencias locales
    removePreference('username');
    removePreference('userid');
    // Y volver a la pantalla de autenticación
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => const AuthScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        elevation: 14,
        child: Container(
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                  Color.fromARGB(255, 43, 0, 99),
                  Color.fromARGB(255, 67, 2, 153),
                ])),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Usuario Conectado:",
                    style: TextStyle(
                        fontSize: 14,
                        color: Color.fromARGB(255, 226, 205, 255))),
                Text(getStringPreference('username') ?? '',
                    style: const TextStyle(
                        fontSize: 20,
                        color: Color.fromARGB(255, 226, 205, 255))),
                const SizedBox(height: 10),
                ElevatedButton(
                    onPressed: () {
                      _logout(context);
                    },
                    child: const Text("Cerrar la Sesión")),
                const SizedBox(height: 40),
                const Text('EvaluApp 1.0.3 Build 26 - MikeMad 2025',
                    style:
                        TextStyle(color: Color.fromARGB(255, 226, 205, 255))),
              ],
            )),
      ),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 85, 2, 194),
        centerTitle: true,
        iconTheme:
            const IconThemeData(color: Color.fromARGB(255, 189, 138, 255)),
        title: const Text(
          'EvaluApp',
          style: TextStyle(
            color: Color.fromARGB(255, 226, 209, 250),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              //saveData(getStringPreference('userid')!, 0, "Default Period", allMattersData);
              _addNewMatter(context);
            },
            icon: const Icon(Icons.add),
            color: const Color.fromARGB(255, 189, 138, 255),
            focusColor: const Color.fromARGB(255, 226, 205, 255),
          ),
        ],
      ),
      body: Container(
        alignment: Alignment.topCenter,
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
              Color.fromARGB(255, 67, 2, 153),
              Color.fromARGB(255, 14, 0, 32)
            ])),
        child: DisplayProgramData(matters: allMattersData),
      ),
    );
  }
}
