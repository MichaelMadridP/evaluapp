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
  final Color noteBadgeTextLight;
  final Color noteBadgeTextDark;

  // Colores para estados de notas (aprobado/reprobado)
  final Color notePassColor;
  final Color noteFailColor;

  // Colores de texto y elementos generales
  final Color primaryTextColor;
  final Color errorTextColor;
  final Color warningTextColor;
  final Color iconDeleteColor;

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
    this.noteBadgeTextLight = const Color(0xFFFFFFFF),
    this.noteBadgeTextDark = const Color(0xFF140F1E),
    required this.notePassColor,
    required this.noteFailColor,
    required this.primaryTextColor,
    required this.errorTextColor,
    required this.warningTextColor,
    required this.iconDeleteColor,
  });
}

/// Paleta de colores para modo oscuro calibrada para WCAG 2.1 AA/AAA
const AppColors darkColors = AppColors(
  // Fondo principal - gradiente suave Slate / Deep Violet
  backgroundGradientStart: Color(0xFF1A102C),
  backgroundGradientEnd: Color(0xFF0E0818),

  // AppBar
  appBarBackground: Color(0xFF261842),
  appBarIcon: Color(0xFFD0BCFF),
  appBarTitle: Color(0xFFF4EEFF),

  // Drawer
  drawerGradientStart: Color(0xFF1E1234),
  drawerGradientEnd: Color(0xFF120A20),
  drawerText: Color(0xFFEBE2FA),
  drawerButton: Color(0xFFD0BCFF),

  // Matter Card
  matterCardBackground: Color(0xFF22163A),
  matterCardBorder: Color(0xFF4E3E69),
  matterCardTitle: Color(0xFFE8DEFF),
  matterCardText: Color(0xFFC4B6DC),

  // Dimension Card
  dimensionCardBackground: Color(0xFF2C1E4A),
  dimensionCardText: Color(0xFFF0EAFA),

  // Edit Modal & Sub-cards
  editMatterBackground: Color(0xFF1C1230),
  editDimensionBackground: Color(0xFF281C44),
  editDimensionText: Color(0xFFF0EAFA),

  // Autenticación
  authBackground: Color(0xFF1A102C),
  authCardBackground: Color(0xFF24183E),
  authTitle: Color(0xFFF4EEFF),
  authSubtitle: Color(0xFFC4B6DC),
  authText: Color(0xFFF0EAFA),
  authInputLabel: Color(0xFFC4B6DC),
  authInputIcon: Color(0xFFD0BCFF),
  authButtonBackground: Color(0xFF7C3AED),
  authButtonText: Color(0xFFFFFFFF),
  authFooterText: Color(0xFFA899C0),

  // Campos de nota
  noteFieldBackground: Color(0xFF302250),
  noteFieldText: Color(0xFFFFFFFF),
  noteFieldBorder: Color(0xFF5C4B7A),

  // Semáforo de notas (alto contraste)
  noteGreen: Color(0xFF1E3A8A), // Azul oscuro (Blue 900, CR 9.81:1 con blanco)
  noteYellow: Color(0xFFF59E0B), // Amber (CR 8.76:1 con texto oscuro)
  noteRed: Color(0xFFB91C1C), // Crimson (CR 6.47:1 con blanco)
  noteGrey: Color(0xFF475569), // Slate (CR 7.58:1 con blanco)
  noteBadgeTextLight: Color(0xFFFFFFFF),
  noteBadgeTextDark: Color(0xFF140F1E),

  // Estados de notas (alto contraste sobre fondo oscuro #2C1E4A)
  notePassColor: Color(0xFF64B5F6), // Azul suave 300 (CR 6.81:1)
  noteFailColor: Color(0xFFFF6E6E), // Coral suave 300 (CR 5.54:1)

  // Textos y elementos generales
  primaryTextColor: Color(0xFFF0EAFA),
  errorTextColor: Color(0xFFFF8080),
  warningTextColor: Color(0xFFFFC107),
  iconDeleteColor: Color(0xFFFF7878),
);

/// Paleta de colores para modo claro calibrada para WCAG 2.1 AA/AAA
const AppColors lightColors = AppColors(
  // Fondo principal - tonos marfil lavanda limpios
  backgroundGradientStart: Color(0xFFF8F6FC),
  backgroundGradientEnd: Color(0xFFF0ECF8),

  // AppBar - Púrpura profundo de alta autoridad con elementos blancos
  appBarBackground: Color(0xFF673AB7),
  appBarIcon: Color(0xFFFFFFFF),
  appBarTitle: Color(0xFFFFFFFF),

  // Drawer
  drawerGradientStart: Color(0xFFF5F0FC),
  drawerGradientEnd: Color(0xFFEBE2F8),
  drawerText: Color(0xFF211438),
  drawerButton: Color(0xFF673AB7),

  // Matter Card - Tarjeta blanca definida con borde sutil
  matterCardBackground: Color(0xFFFFFFFF),
  matterCardBorder: Color(0xFFDCD2EB),
  matterCardTitle: Color(0xFF3C1C73),
  matterCardText: Color(0xFF554173),

  // Dimension Card
  dimensionCardBackground: Color(0xFFF6F2FC),
  dimensionCardText: Color(0xFF261840),

  // Edit Modal & Sub-cards
  editMatterBackground: Color(0xFFFFFFFF),
  editDimensionBackground: Color(0xFFF5F0FC),
  editDimensionText: Color(0xFF211438),

  // Autenticación
  authBackground: Color(0xFFF8F6FC),
  authCardBackground: Color(0xFFFFFFFF),
  authTitle: Color(0xFF361869),
  authSubtitle: Color(0xFF5A4678),
  authText: Color(0xFF211438),
  authInputLabel: Color(0xFF5A4678),
  authInputIcon: Color(0xFF673AB7),
  authButtonBackground: Color(0xFF673AB7),
  authButtonText: Color(0xFFFFFFFF),
  authFooterText: Color(0xFF6E5F87),

  // Campos de nota
  noteFieldBackground: Color(0xFFFFFFFF),
  noteFieldText: Color(0xFF211438),
  noteFieldBorder: Color(0xFFC3B4DA),

  // Semáforo de notas (alto contraste)
  noteGreen: Color(0xFF1E3A8A), // Azul oscuro (Blue 900, CR 9.81:1 con blanco)
  noteYellow: Color(0xFFF59E0B),
  noteRed: Color(0xFFB91C1C),
  noteGrey: Color(0xFF475569),
  noteBadgeTextLight: Color(0xFFFFFFFF),
  noteBadgeTextDark: Color(0xFF140F1E),

  // Estados de notas (alto contraste sobre fondo claro #F6F2FC)
  notePassColor: Color(0xFF105CC4), // Azul profundo 700 (CR 5.68:1)
  noteFailColor: Color(0xFFC61818), // Rojo profundo 700 (CR 5.37:1)

  // Textos y elementos generales
  primaryTextColor: Color(0xFF211438),
  errorTextColor: Color(0xFFC61818),
  warningTextColor: Color(0xFFB46400),
  iconDeleteColor: Color(0xFFD21E1E),
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
