import 'package:flutter/material.dart';

/// Clase para almacenar la paleta de colores del tema
class AppColors {
  // Colores de fondo principales
  final Color backgroundGradientStart;
  final Color backgroundGradientEnd;

  // Colores del AppBar
  final Color appBarBackground;
  final Color appBarIcon;
  final Color appBarTitle;

  // Colores del Drawer
  final Color drawerGradientStart;
  final Color drawerGradientEnd;
  final Color drawerText;
  final Color drawerButton;

  // Colores de Cards
  final Color matterCardBackground;
  final Color matterCardBorder;
  final Color matterCardTitle;
  final Color matterCardText;

  final Color dimensionCardBackground;
  final Color dimensionCardText;

  final Color editMatterBackground;
  final Color editDimensionBackground;
  final Color editDimensionText;

  // Colores de autenticación
  final Color authBackground;
  final Color authCardBackground;
  final Color authTitle;
  final Color authSubtitle;
  final Color authText;
  final Color authInputLabel;
  final Color authInputIcon;
  final Color authButtonBackground;
  final Color authButtonText;
  final Color authFooterText;

  // Colores de campos de nota
  final Color noteFieldBackground;
  final Color noteFieldText;
  final Color noteFieldBorder;

  // Colores de visualización de notas (semáforo)
  final Color noteGreen;
  final Color noteYellow;
  final Color noteRed;
  final Color noteGrey;

  const AppColors({
    required this.backgroundGradientStart,
    required this.backgroundGradientEnd,
    required this.appBarBackground,
    required this.appBarIcon,
    required this.appBarTitle,
    required this.drawerGradientStart,
    required this.drawerGradientEnd,
    required this.drawerText,
    required this.drawerButton,
    required this.matterCardBackground,
    required this.matterCardBorder,
    required this.matterCardTitle,
    required this.matterCardText,
    required this.dimensionCardBackground,
    required this.dimensionCardText,
    required this.editMatterBackground,
    required this.editDimensionBackground,
    required this.editDimensionText,
    required this.authBackground,
    required this.authCardBackground,
    required this.authTitle,
    required this.authSubtitle,
    required this.authText,
    required this.authInputLabel,
    required this.authInputIcon,
    required this.authButtonBackground,
    required this.authButtonText,
    required this.authFooterText,
    required this.noteFieldBackground,
    required this.noteFieldText,
    required this.noteFieldBorder,
    required this.noteGreen,
    required this.noteYellow,
    required this.noteRed,
    required this.noteGrey,
  });
}

/// Paleta de colores para modo oscuro (actual)
const AppColors darkColors = AppColors(
  // Fondo principal - gradiente púrpura oscuro
  backgroundGradientStart: Color.fromARGB(255, 67, 2, 153),
  backgroundGradientEnd: Color.fromARGB(255, 14, 0, 32),

  // AppBar
  appBarBackground: Color.fromARGB(255, 85, 2, 194),
  appBarIcon: Color.fromARGB(255, 189, 138, 255),
  appBarTitle: Color.fromARGB(255, 226, 209, 250),

  // Drawer
  drawerGradientStart: Color.fromARGB(255, 43, 0, 99),
  drawerGradientEnd: Color.fromARGB(255, 67, 2, 153),
  drawerText: Color.fromARGB(255, 226, 205, 255),
  drawerButton: Color.fromARGB(255, 226, 205, 255),

  // Matter Card
  matterCardBackground: Color.fromARGB(255, 39, 1, 83),
  matterCardBorder: Color.fromARGB(255, 90, 75, 112),
  matterCardTitle: Color.fromARGB(255, 221, 201, 248),
  matterCardText: Color.fromARGB(255, 179, 157, 209),

  // Dimension Card
  dimensionCardBackground: Color.fromARGB(255, 58, 0, 134),
  dimensionCardText: Color.fromARGB(255, 221, 201, 248),

  // Edit
  editMatterBackground: Color.fromARGB(255, 107, 68, 168),
  editDimensionBackground: Color.fromARGB(255, 162, 123, 255),
  editDimensionText: Color.fromARGB(255, 22, 20, 26),

  // Autenticación
  authBackground: Color.fromARGB(255, 67, 2, 153),
  authCardBackground: Color.fromARGB(255, 61, 8, 131),
  authTitle: Color.fromARGB(255, 239, 227, 252),
  authSubtitle: Color.fromARGB(255, 226, 205, 250),
  authText: Color.fromARGB(255, 226, 205, 250),
  authInputLabel: Color.fromARGB(255, 226, 205, 250),
  authInputIcon: Color.fromARGB(255, 226, 205, 250),
  authButtonBackground: Color.fromARGB(255, 107, 68, 168),
  authButtonText: Color.fromARGB(255, 226, 205, 250),
  authFooterText: Color.fromRGBO(179, 163, 197, 1),

  // Campos de nota
  noteFieldBackground: Color.fromARGB(255, 221, 201, 248),
  noteFieldText: Color.fromARGB(255, 14, 0, 32),
  noteFieldBorder: Color.fromARGB(255, 221, 201, 248),

  // Semáforo de notas
  noteGreen: Color.fromARGB(255, 117, 245, 66),
  noteYellow: Colors.yellow,
  noteRed: Colors.red,
  noteGrey: Colors.grey,
);

/// Paleta de colores para modo claro
const AppColors lightColors = AppColors(
  // Fondo principal - gradiente púrpura claro
  backgroundGradientStart: Color.fromARGB(255, 240, 230, 255),
  backgroundGradientEnd: Color.fromARGB(255, 250, 248, 255),

  // AppBar
  appBarBackground: Color.fromARGB(255, 155, 100, 230),
  appBarIcon: Color.fromARGB(255, 90, 40, 180),
  appBarTitle: Color.fromARGB(255, 255, 255, 255),

  // Drawer
  drawerGradientStart: Color.fromARGB(255, 200, 170, 255),
  drawerGradientEnd: Color.fromARGB(255, 180, 140, 255),
  drawerText: Color.fromARGB(255, 40, 20, 80),
  drawerButton: Color.fromARGB(255, 40, 20, 80),

  // Matter Card
  matterCardBackground: Color.fromARGB(255, 245, 240, 255),
  matterCardBorder: Color.fromARGB(255, 180, 150, 220),
  matterCardTitle: Color.fromARGB(255, 80, 40, 140),
  matterCardText: Color.fromARGB(255, 100, 60, 160),

  // Dimension Card
  dimensionCardBackground: Color.fromARGB(255, 235, 225, 255),
  dimensionCardText: Color.fromARGB(255, 70, 30, 130),

  // Edit
  editMatterBackground: Color.fromARGB(255, 200, 170, 240),
  editDimensionBackground: Color.fromARGB(255, 220, 200, 255),
  editDimensionText: Color.fromARGB(255, 40, 20, 80),

  // Autenticación
  authBackground: Color.fromARGB(255, 240, 230, 255),
  authCardBackground: Color.fromARGB(255, 250, 245, 255),
  authTitle: Color.fromARGB(255, 70, 30, 130),
  authSubtitle: Color.fromARGB(255, 100, 60, 160),
  authText: Color.fromARGB(255, 100, 60, 160),
  authInputLabel: Color.fromARGB(255, 100, 60, 160),
  authInputIcon: Color.fromARGB(255, 100, 60, 160),
  authButtonBackground: Color.fromARGB(255, 155, 100, 230),
  authButtonText: Color.fromARGB(255, 255, 255, 255),
  authFooterText: Color.fromARGB(255, 120, 80, 180),

  // Campos de nota
  noteFieldBackground: Color.fromARGB(255, 255, 255, 255),
  noteFieldText: Color.fromARGB(255, 40, 20, 80),
  noteFieldBorder: Color.fromARGB(255, 180, 150, 220),

  // Semáforo de notas (mantener los mismos colores funcionales)
  noteGreen: Color.fromARGB(255, 76, 175, 80),
  noteYellow: Color.fromARGB(255, 255, 193, 7),
  noteRed: Color.fromARGB(255, 244, 67, 54),
  noteGrey: Color.fromARGB(255, 158, 158, 158),
);

/// Provider de tema usando InheritedWidget
class ThemeProvider extends InheritedWidget {
  final AppColors colors;
  final bool isDarkMode;
  final Function(bool) toggleTheme;

  const ThemeProvider({
    super.key,
    required this.colors,
    required this.isDarkMode,
    required this.toggleTheme,
    required super.child,
  });

  static ThemeProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeProvider>();
  }

  @override
  bool updateShouldNotify(ThemeProvider oldWidget) {
    return colors != oldWidget.colors || isDarkMode != oldWidget.isDarkMode;
  }
}
