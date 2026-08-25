# 📊 EvaluApp

**Tu evaluador predictivo de notas académicas**

EvaluApp es una aplicación móvil desarrollada en Flutter que te ayuda a evaluar y predecir tu rendimiento académico. Calcula automáticamente tus promedios actuales y te muestra qué notas necesitas obtener en las próximas evaluaciones para alcanzar tu meta.

![Version](https://img.shields.io/badge/version-1.0.1-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.4.4-blue)
![Firebase](https://img.shields.io/badge/Firebase-enabled-orange)

---

## 🎯 ¿Qué hace EvaluApp?

EvaluApp es una herramienta diseñada para estudiantes que desean:

- **Calcular promedios automáticamente**: Ingresa tus notas y EvaluApp calcula tu promedio actual considerando las ponderaciones de cada evaluación
- **Predecir notas requeridas**: Descubre qué nota necesitas obtener en las próximas evaluaciones para alcanzar tu objetivo
- **Organizar por materias y dimensiones**: Gestiona múltiples materias, cada una con diferentes tipos de evaluaciones (exámenes, tareas, proyectos, etc.)
- **Sincronización en la nube**: Tus datos se guardan automáticamente en Firebase y se sincronizan entre dispositivos
- **Cálculos inteligentes**: Soporta ponderaciones porcentuales, eliminación de la peor nota, y redistribución automática de pesos

---

## ✨ Características Principales

### 🎓 Gestión de Materias
- Crea y administra múltiples materias (asignaturas)
- Establece una nota meta por materia (por defecto: 4.0)
- Visualiza promedio parcial o final según tus notas ingresadas
- Calcula automáticamente la nota mínima requerida para alcanzar tu meta

### 📏 Dimensiones Personalizables
Cada materia puede tener múltiples **dimensiones** (categorías de evaluación):
- **Exámenes** (40%)
- **Tareas** (20%)
- **Proyectos** (30%)
- **Participación** (10%)
- *...o cualquier combinación que necesites*

#### Características de las Dimensiones:
- **Ponderación porcentual**: Asigna un peso a cada dimensión
- **Número de notas**: Define cuántas evaluaciones tendrá cada dimensión
- **Eliminación de peor nota**: Opción para descartar la nota más baja automáticamente
- **Cálculo de requerido**: Muestra qué nota necesitas en las evaluaciones pendientes

### 🔐 Autenticación y Sincronización
- Sistema de registro e inicio de sesión con Firebase Authentication
- Recuperación de contraseña
- Sincronización automática de datos con Firebase Realtime Database
- Persistencia local con SharedPreferences

### 🎨 Interfaz Atractiva
- Diseño moderno con gradientes morados
- Tema coherente y profesional
- Interfaz intuitiva y fácil de usar
- Visualización clara de promedios y notas requeridas

---

## 🏗️ Arquitectura del Proyecto

### Estructura de Directorios

```
evaluapp/
├── lib/
│   ├── main.dart                      # Punto de entrada de la aplicación
│   ├── firebase_options.dart          # Configuración de Firebase
│   ├── screens/                       # Pantallas de la aplicación
│   │   ├── auth.dart                  # Pantalla de inicio de sesión
│   │   ├── register.dart              # Pantalla de registro
│   │   └── forgotten_pass.dart        # Pantalla de recuperación de contraseña
│   ├── components/                    # Componentes reutilizables
│   │   ├── matter.dart                # Tarjeta de materia
│   │   ├── dimension.dart             # Componente de dimensión
│   │   ├── note.dart                  # Campo de entrada de nota
│   │   ├── note_display_only.dart     # Visualización de nota (solo lectura)
│   │   ├── edit_matter.dart           # Editor de materia
│   │   ├── edit_dimension.dart        # Editor de dimensión
│   │   └── display_program_data.dart  # Visualización de todas las materias
│   └── data_model/                    # Modelos de datos y lógica de negocio
│       ├── model.dart                 # Clases DimensionData y MatterData
│       ├── data_connect.dart          # Conexión con Firebase
│       └── preferences.dart           # Gestión de preferencias locales
├── android/                           # Configuración Android
├── ios/                              # Configuración iOS
├── web/                              # Configuración Web
├── windows/                          # Configuración Windows
├── linux/                            # Configuración Linux
├── macos/                            # Configuración macOS
├── assets/                           # Recursos (imágenes, iconos)
├── pubspec.yaml                      # Dependencias del proyecto
└── firebase.json                     # Configuración de Firebase

```

### Stack Tecnológico

- **Framework**: Flutter 3.4.4+
- **Lenguaje**: Dart
- **Backend**: Firebase
  - Firebase Authentication (autenticación de usuarios)
  - Firebase Realtime Database (almacenamiento de datos)
- **Almacenamiento Local**: SharedPreferences
- **Gestión de Estado**: StatefulWidget

### Modelos de Datos

#### DimensionData
Representa una categoría de evaluación dentro de una materia:
```dart
class DimensionData {
  String dimensionTitle;          // Nombre (ej: "Exámenes")
  int numNotes;                   // Cantidad de evaluaciones
  List<double> noteList;          // Lista de notas ingresadas
  int percentageWeight;           // Ponderación (%)
  bool removeWorstNote;           // ¿Eliminar peor nota?
  bool isDismissable;             // ¿Se puede eliminar esta dimensión?
  
  // Calculados automáticamente:
  double average;                 // Promedio de la dimensión
  double minimumRequired;         // Nota mínima requerida
}
```

#### MatterData
Representa una materia completa con todas sus dimensiones:
```dart
class MatterData {
  String matterTitle;             // Nombre de la materia
  List<DimensionData> dimension;  // Lista de dimensiones
  double targetNote;              // Nota meta (por defecto: 4.0)
  
  // Calculados automáticamente:
  double average;                 // Promedio ponderado de la materia
  double minimumRequired;         // Nota mínima requerida para alcanzar meta
}
```

### Algoritmos de Cálculo

#### Cálculo del Promedio de una Dimensión
1. Filtra las notas mayores a 0 (las notas en 0 son consideradas "pendientes")
2. Si `removeWorstNote` es verdadero y hay más de 1 nota, elimina la peor
3. Calcula el promedio de las notas restantes
4. Calcula la nota mínima requerida en las evaluaciones pendientes

#### Cálculo del Promedio de una Materia
1. Calcula el promedio de cada dimensión
2. Identifica dimensiones sin notas y redistribuye su porcentaje
3. Calcula el promedio ponderado considerando los porcentajes ajustados
4. Calcula la nota requerida en las dimensiones pendientes

---

## 🚀 Instalación

### Prerrequisitos
- Flutter SDK (>=3.4.4)
- Dart SDK
- Android Studio / Xcode (para desarrollo móvil)
- Una cuenta de Firebase

### Pasos de Instalación

1. **Clonar el repositorio**
```bash
git clone <repository-url>
cd evaluapp
```

2. **Instalar dependencias**
```bash
flutter pub get
```

3. **Configurar Firebase**
   - Crea un proyecto en [Firebase Console](https://console.firebase.google.com/)
   - Habilita Firebase Authentication (Email/Password)
   - Habilita Firebase Realtime Database
   - Descarga los archivos de configuración para tus plataformas
   - Ejecuta: `flutterfire configure` (si tienes FlutterFire CLI)

4. **Actualizar el ID de la aplicación** (opcional)
```bash
dart run change_app_package_name:main com.tudominio.evaluapp
```

5. **Generar icono de la aplicación** (opcional)
```bash
flutter pub run flutter_launcher_icons:main
```

6. **Ejecutar la aplicación**
```bash
flutter run
```

---

## 📱 Uso de la Aplicación

### Primer Uso

1. **Registro**
   - Abre la aplicación
   - Toca "¿No tienes cuenta?"
   - Completa el formulario de registro
   - Verifica tu correo electrónico

2. **Inicio de Sesión**
   - Ingresa tu email y contraseña
   - Tus datos se sincronizarán automáticamente

### Gestión de Materias

#### Crear una Nueva Materia
1. Toca el botón **+** en la barra superior
2. Ingresa el nombre de la materia
3. Configura la nota meta (por defecto: 4.0)
4. Agrega dimensiones según necesites
5. Guarda la materia

#### Editar una Materia
1. Toca sobre el nombre de la materia
2. Modifica los campos necesarios
3. Guarda los cambios

#### Configurar Dimensiones
Para cada dimensión puedes configurar:
- **Nombre**: ej. "Exámenes", "Tareas", "Proyecto Final"
- **Ponderación**: Porcentaje que representa del total (deben sumar 100%)
- **Cantidad de notas**: Número de evaluaciones en esta dimensión
- **Eliminar peor nota**: Activa esta opción si se descarta la nota más baja

#### Ingresar Notas
1. En cada dimensión verás campos para ingresar notas
2. Ingresa las notas a medida que las obtienes
3. Las notas en 0 se consideran "pendientes"
4. Los cálculos se actualizan automáticamente

### Interpretación de Resultados

- **Promedio Parcial**: Se muestra cuando tienes notas pendientes
- **Promedio Final**: Se muestra cuando todas las notas están ingresadas
- **Requerido**: Nota mínima que necesitas en las evaluaciones pendientes para alcanzar tu meta

#### Código de Colores en "Requerido"
- **Verde**: Nota alcanzable (< 7.0)
- **Amarillo**: Nota difícil pero posible (7.0 - 10.0)
- **Rojo**: Nota imposible de alcanzar (> 10.0) - necesitas una nota superior al máximo

---

## 🔧 Dependencias Principales

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.6
  uuid: ^4.4.2
  firebase_core: ^3.13.0
  firebase_auth: ^5.5.2
  firebase_database: ^11.3.5
  shared_preferences: ^2.0.15
  package_info_plus: ^8.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  change_app_package_name: ^1.3.0
  flutter_launcher_icons: ^0.14.3
```

---

## 🎨 Personalización

### Cambiar Colores del Tema
Los colores principales están definidos en los archivos de componentes. Busca:
- `Color.fromARGB(255, 67, 2, 153)` - Púrpura oscuro
- `Color.fromARGB(255, 14, 0, 32)` - Casi negro
- `Color.fromARGB(255, 226, 205, 255)` - Púrpura claro

### Modificar la Nota Meta Predeterminada
En `lib/data_model/model.dart`, cambia:
```dart
double _targetNote = 4; // Cambia este valor
```

---

## 🐛 Solución de Problemas

### La aplicación no sincroniza con Firebase
- Verifica tu conexión a internet
- Asegúrate de que Firebase esté correctamente configurado
- Revisa las reglas de seguridad de Firebase Realtime Database

### Error al compilar para Android
- Verifica que el archivo `google-services.json` esté en `android/app/`
- Asegúrate de que el package name coincida en todos los archivos

### Las notas no se calculan correctamente
- Verifica que la suma de ponderaciones sea 100%
- Asegúrate de ingresar solo valores numéricos válidos

---

## 📄 Licencia

EvaluApp 2.0.1 - MikeMad 2026

---

## 👨‍💻 Autor

**Michael Madrid**

---

## 🔮 Versiones Futuras

Funcionalidades planeadas:
- Soporte para múltiples periodos académicos (semestres)
- Gráficos de evolución de notas
- Exportación de datos a PDF
- Notificaciones de fechas de evaluación
- Modo oscuro/claro
- Soporte para diferentes sistemas de calificación

---

## 📞 Soporte

Si encuentras algún bug o tienes sugerencias, por favor abre un issue en el repositorio.

---

**¡Buena suerte con tus estudios! 📚✨**