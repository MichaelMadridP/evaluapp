import 'package:flutter/material.dart';

import 'package:evaluapp/data_model/data_connect.dart';
import 'package:evaluapp/data_model/preferences.dart';
import 'package:evaluapp/data_model/model.dart';
import 'package:evaluapp/themes.dart';

import 'package:evaluapp/components/edit_matter.dart';
import 'package:evaluapp/components/period_selector_modal.dart';
import 'package:evaluapp/components/display_program_data.dart';
import 'package:evaluapp/screens/auth.dart';
import 'package:evaluapp/screens/study_plan_screen.dart';
// Google Firebase Authentication
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

//***************************************************************************************/
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSharedPreferences();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = true; // Por defecto modo oscuro

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final isDark = getBoolPreference('isDarkMode') ?? true;
    setState(() {
      _isDarkMode = isDark;
    });
  }

  void _toggleTheme(bool isDark) {
    setState(() {
      _isDarkMode = isDark;
    });
    saveBoolPreference('isDarkMode', isDark);
  }

  Future<String?> _initAppSession() async {
    final userId = getStringPreference('userid');
    if (userId != null && userId.isNotEmpty) {
      try {
        await getData(userId, 0);
      } catch (e) {
        debugPrint(
            'Error al recuperar datos de Firebase al iniciar sesión: $e');
      }
    }
    return userId;
  }

  @override
  Widget build(BuildContext context) {
    final currentColors = _isDarkMode ? darkColors : lightColors;

    return ThemeProvider(
      colors: currentColors,
      isDarkMode: _isDarkMode,
      toggleTheme: _toggleTheme,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'EvaluApp',
        theme: ThemeData(
          useMaterial3: true,
          brightness: _isDarkMode ? Brightness.dark : Brightness.light,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF673AB7),
            brightness: _isDarkMode ? Brightness.dark : Brightness.light,
            primary: currentColors.authButtonBackground,
            secondary: currentColors.appBarIcon,
            surface: currentColors.matterCardBackground,
            error: currentColors.errorTextColor,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: currentColors.authButtonBackground,
              foregroundColor: currentColors.authButtonText,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        home: FutureBuilder<String?>(
          future: _initAppSession(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Scaffold(
                body: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        currentColors.backgroundGradientStart,
                        currentColors.backgroundGradientEnd,
                      ],
                    ),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            }
            final userId = snapshot.data;
            if (userId == null || userId.isEmpty) {
              return const AuthScreen();
            } else {
              return const HomeScreen();
            }
          },
        ),
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

  void _openPeriodSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      builder: (ctx) {
        return PeriodSelectorModal(
          onPeriodChangedCB: () {
            setState(() {});
          },
        );
      },
    );
  }

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

  Future<void> _logout(BuildContext context) async {
    // 1. Cerrar sesión en Firebase Auth
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Error al cerrar sesión en Firebase Auth: $e');
    }

    // 2. Limpiar datos en memoria para evitar filtración entre sesiones
    allPeriodsData.clear();
    activePeriod = null;

    // 3. Eliminar el usuario de las preferencias locales
    removePreference('username');
    removePreference('userid');
    removePreference('activePeriodId');

    // 4. Volver a la pantalla de autenticación
    if (!context.mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => const AuthScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.of(context)!;
    final colors = theme.colors;

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        elevation: 8,
        child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                  colors.drawerGradientStart,
                  colors.drawerGradientEnd,
                ])),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Usuario Conectado:",
                    style: TextStyle(
                        fontSize: 14,
                        color: colors.drawerText.withValues(alpha: 0.8))),
                const SizedBox(height: 4),
                Text(getStringPreference('username') ?? '',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colors.drawerText)),
                const SizedBox(height: 24),
                // Selector de tema
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.light_mode, color: colors.drawerText),
                    const SizedBox(width: 8),
                    Switch(
                      value: theme.isDarkMode,
                      onChanged: (value) {
                        theme.toggleTheme(value);
                      },
                      activeThumbColor: theme.isDarkMode
                          ? colors.appBarIcon
                          : colors.appBarBackground,
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.dark_mode, color: colors.drawerText),
                  ],
                ),
                Text(
                  theme.isDarkMode ? 'Modo Oscuro' : 'Modo Claro',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.drawerText,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        colors.drawerButton.withValues(alpha: 0.15),
                    foregroundColor: colors.drawerText,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                          color: colors.drawerButton.withValues(alpha: 0.3)),
                    ),
                  ),
                  icon:
                      Icon(Icons.psychology_outlined, color: colors.drawerButton),
                  label: const Text(
                    "Plan de Estudio",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const StudyPlanScreen()),
                    ).then((_) => setState(() {}));
                  },
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        colors.drawerButton.withValues(alpha: 0.15),
                    foregroundColor: colors.drawerText,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                          color: colors.drawerButton.withValues(alpha: 0.3)),
                    ),
                  ),
                  icon:
                      Icon(Icons.calendar_month, color: colors.drawerButton),
                  label: const Text(
                    "Gestionar Períodos",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _openPeriodSelector(context);
                  },
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.drawerButton,
                      foregroundColor: theme.isDarkMode
                          ? const Color(0xFF140F1E)
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    onPressed: () {
                      _logout(context);
                    },
                    child: const Text("Cerrar la Sesión",
                        style: TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(height: 40),
                Text('EvaluApp 2.0.1 - MikeMad 2026',
                    style: TextStyle(
                        fontSize: 11,
                        color: colors.drawerText.withValues(alpha: 0.7))),
              ],
            )),
      ),
      appBar: AppBar(
        backgroundColor: colors.appBarBackground,
        centerTitle: true,
        iconTheme: IconThemeData(color: colors.appBarIcon),
        title: Text(
          'EvaluApp',
          style: TextStyle(
            color: colors.appBarTitle,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Plan de Estudio',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const StudyPlanScreen()),
              ).then((_) => setState(() {}));
            },
            icon: const Icon(Icons.psychology_outlined),
            color: colors.appBarIcon,
          ),
          IconButton(
            tooltip: 'Agregar Materia',
            onPressed: () {
              _addNewMatter(context);
            },
            icon: const Icon(Icons.add),
            color: colors.appBarIcon,
            focusColor: colors.appBarTitle,
          ),
        ],
      ),
      body: Container(
        alignment: Alignment.topCenter,
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
              colors.backgroundGradientStart,
              colors.backgroundGradientEnd
            ])),
        child: Column(
          children: [
            // Barra interactiva del período activo
            InkWell(
              onTap: () => _openPeriodSelector(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                decoration: BoxDecoration(
                  color: colors.matterCardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.matterCardBorder,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      color: colors.drawerButton,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'PERÍODO ACADÉMICO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  color: colors.drawerButton,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activePeriod?.name ?? 'Sin período',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colors.matterCardTitle,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (activePeriod?.dateRangeFormatted.isNotEmpty ??
                              false)
                            Text(
                              activePeriod!.dateRangeFormatted,
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.matterCardText
                                    .withValues(alpha: 0.8),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: colors.matterCardText,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: DisplayProgramData(
                key: ValueKey(activePeriod?.id ?? 'default_period'),
                matters: allMattersData,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
