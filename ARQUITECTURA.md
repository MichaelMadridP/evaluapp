# Arquitectura Técnica de EvaluApp

## Resumen Ejecutivo

EvaluApp es una aplicación móvil Flutter que funciona como un **sistema de gestión y predicción de notas académicas**. Permite a los estudiantes calcular sus promedios actuales y predecir qué notas necesitan obtener en evaluaciones futuras para alcanzar sus metas académicas.

---

## Flujo de Datos

### Arquitectura General

```
┌─────────────┐
│   Usuario   │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────┐
│     Interfaz de Usuario (Flutter)   │
│  ┌───────────┬────────────────────┐ │
│  │  Screens  │    Components      │ │
│  └───────────┴────────────────────┘ │
└────────────┬────────────────────────┘
             │
             ▼
┌─────────────────────────────────────┐
│        Capa de Lógica de Negocio    │
│  ┌──────────────────────────────┐  │
│  │  Data Models (MatterData,    │  │
│  │  DimensionData)              │  │
│  │  - Cálculos de promedios     │  │
│  │  - Cálculos de requeridos    │  │
│  └──────────────────────────────┘  │
└────────────┬────────────────────────┘
             │
             ▼
┌─────────────────────────────────────┐
│       Capa de Persistencia          │
│  ┌────────────┬──────────────────┐  │
│  │  Firebase  │ SharedPreferences│  │
│  │  Realtime  │  (Local)         │  │
│  │  Database  │                  │  │
│  └────────────┴──────────────────┘  │
└─────────────────────────────────────┘
```

---

## Componentes Principales

### 1. Capa de Presentación

#### Screens (Pantallas)
- **`auth.dart`**: Pantalla de inicio de sesión
- **`register.dart`**: Pantalla de registro de nuevos usuarios
- **`forgotten_pass.dart`**: Pantalla de recuperación de contraseña

#### Components (Componentes Reutilizables)
- **`matter.dart`**: Tarjeta que muestra una materia completa con todas sus dimensiones
- **`dimension.dart`**: Componente que muestra una dimensión con sus notas
- **`note.dart`**: Campo de entrada editable para una nota
- **`note_display_only.dart`**: Visualización de una nota (solo lectura, con código de colores)
- **`edit_matter.dart`**: Modal para crear/editar materias
- **`edit_dimension.dart`**: Modal para editar dimensiones
- **`display_program_data.dart`**: Lista scrollable de todas las materias

### 2. Capa de Lógica de Negocio

#### Modelos de Datos (`data_model/model.dart`)

##### DimensionData
Representa una categoría de evaluación:
- **Propiedades:**
  - `dimensionTitle`: Nombre de la dimensión
  - `numNotes`: Número total de evaluaciones
  - `noteList`: Lista de notas (0 = pendiente)
  - `percentageWeight`: Ponderación en porcentaje
  - `removeWorstNote`: Eliminar peor nota (bool)
  - `isDismissable`: Se puede eliminar (bool)
  
- **Métodos principales:**
  - `calculate()`: Calcula promedio y nota requerida
  - `isFinal()`: Verifica si todas las notas están ingresadas
  - `toMap()` / `fromMap()`: Serialización para Firebase

##### MatterData
Representa una materia completa:
- **Propiedades:**
  - `matterTitle`: Nombre de la materia
  - `dimension`: Lista de DimensionData
  - `targetNote`: Nota meta (por defecto 4.0)
  
- **Métodos principales:**
  - `calculate()`: Calcula promedio ponderado total
  - `isFinal()`: Verifica si todas las dimensiones están completas
  - `toMap()` / `fromMap()`: Serialización para Firebase

### 3. Capa de Persistencia

#### Firebase Realtime Database (`data_connect.dart`)

**Estructura de datos en Firebase:**
```
users/
  └── {userId}/
      ├── user/
      │   ├── userDisplayName
      │   └── userEmail
      └── data/
          └── matters/
              └── [Array de MatterData serializados]
```

**Funciones principales:**
- `createNewUserOnDatabase()`: Crea perfil de usuario nuevo
- `saveData()`: Guarda todas las materias en Firebase
- `getData()`: Recupera datos del usuario desde Firebase

#### SharedPreferences (`preferences.dart`)
Almacena datos locales:
- `userid`: ID del usuario autenticado
- `username`: Nombre del usuario

---

## Algoritmos de Cálculo Detallados

### Cálculo del Promedio de una Dimensión

```
ENTRADA:
  - noteList: [nota1, nota2, ..., notaN]
  - removeWorstNote: boolean

PROCESO:
  1. Filtrar notas > 0 (pendientes son 0)
  2. SI removeWorstNote ES true Y hay > 1 nota ENTONCES
       - Encontrar nota mínima
       - Excluirla del cálculo
     FIN SI
  3. Sumar notas válidas
  4. Dividir por cantidad de notas válidas
  
SALIDA:
  - average: promedio de la dimensión
```

### Cálculo de Nota Requerida (Dimensión)

```
ENTRADA:
  - targetNote: nota meta
  - average: promedio actual
  - numNotes: total de notas
  - cNotes: notas ya ingresadas
  - sum: suma de notas ingresadas

PROCESO:
  notasPendientes = numNotes - cNotes
  SI notasPendientes > 0 ENTONCES
    minimumRequired = ((targetNote × numNotes) - sum) / notasPendientes
  SINO
    minimumRequired = 0
  FIN SI

SALIDA:
  - minimumRequired: nota mínima en cada evaluación pendiente
```

### Cálculo del Promedio Ponderado (Materia)

```
ENTRADA:
  - dimension[]: array de DimensionData
  
PROCESO:
  1. POR CADA dimensión:
       - Calcular su promedio (llamar a dimension.calculate())
  FIN POR CADA
  
  2. Identificar dimensiones sin notas:
       nonDistributedValue = suma de pesos de dimensiones sin notas
       
  3. Redistribuir peso no usado:
       SI hay dimensiones con notas ENTONCES
         nonUsedPercentajeAdjusted = nonDistributedValue / (total_dimensiones - dimensiones_sin_notas)
       FIN SI
       
  4. Calcular promedio ponderado ajustado:
       sum = 0
       POR CADA dimensión con notas:
         pesoAjustado = (peso_original + nonUsedPercentajeAdjusted) / 100
         sum += dimensión.average × pesoAjustado
       FIN POR CADA
       
SALIDA:
  - average: promedio ponderado de la materia
```

### Cálculo de Nota Requerida (Materia)

```
ENTRADA:
  - targetNote: nota meta
  - average: promedio actual
  - nonDistributedValue: % de peso no usado

PROCESO:
  SI nonDistributedValue > 0 ENTONCES
    pesoUsado = (100 - nonDistributedValue) / 100
    pesoNoUsado = nonDistributedValue / 100
    
    minimumRequired = (targetNote - (average × pesoUsado)) / pesoNoUsado
  SINO
    minimumRequired = 0  // Ya todas las notas están ingresadas
  FIN SI

SALIDA:
  - minimumRequired: nota promedio requerida en dimensiones pendientes
```

---

## Flujo de Interacción del Usuario

### Flujo de Autenticación

```
1. Usuario abre la app
   │
   ├──▶ ¿Tiene userId en SharedPreferences?
   │     │
   │     ├─ SÍ ──▶ Cargar datos desde Firebase ──▶ Mostrar HomeScreen
   │     │
   │     └─ NO ──▶ Mostrar AuthScreen
   │               │
   │               ├──▶ ¿Nuevo usuario?
   │               │     │
   │               │     └─ SÍ ──▶ RegisterScreen
   │               │                │
   │               │                ├─ Crear cuenta en Firebase Auth
   │               │                ├─ Crear perfil en Firebase Database
   │               │                └─ Guardar userId en SharedPreferences ──▶ HomeScreen
   │               │
   │               └──▶ Usuario existente
   │                     │
   │                     ├─ Ingresar credenciales
   │                     ├─ Autenticar con Firebase Auth
   │                     ├─ Cargar datos desde Firebase
   │                     └─ Guardar userId en SharedPreferences ──▶ HomeScreen
```

### Flujo de Gestión de Materias

```
1. Usuario en HomeScreen
   │
   ├──▶ Tocar botón "+"
   │     │
   │     └──▶ Crear nueva MatterData vacía
   │           │
   │           └──▶ Abrir EditMatter (modo ADD)
   │                 │
   │                 ├─ Usuario ingresa nombre
   │                 ├─ Configura nota meta
   │                 ├─ Agrega dimensiones
   │                 └─ Guardar ──▶ Agregar a allMattersData ──▶ saveData() a Firebase
   │
   └──▶ Tocar nombre de materia existente
         │
         └──▶ Abrir EditMatter (modo EDIT)
               │
               ├─ Modificar propiedades
               ├─ Editar/eliminar dimensiones
               └─ Guardar ──▶ Actualizar en allMattersData ──▶ saveData() a Firebase
```

### Flujo de Ingreso de Notas

```
1. Usuario ve Matter Card en HomeScreen
   │
   ├──▶ POR CADA Dimension en la materia:
   │     │
   │     └──▶ Mostrar campos Note (editables)
   │           │
   │           └──▶ Usuario ingresa/modifica nota
   │                 │
   │                 ├─ onChanged() ──▶ Actualizar noteList
   │                 ├─ dimension.calculate()
   │                 ├─ matter.calculate()
   │                 ├─ setState() ──▶ Actualizar UI
   │                 └─ saveData() ──▶ Guardar en Firebase
   │
   └──▶ Visualizar resultados actualizados:
         ├─ Promedio actual (parcial/final)
         └─ Nota requerida (con código de colores)
```

---

## Gestión de Estado

EvaluApp utiliza **StatefulWidget** para la gestión de estado local:

### Estado Global
- `allMattersData`: Lista global de todas las materias (en `data_connect.dart`)
- Modificaciones a esta lista se reflejan automáticamente en Firebase

### Estado Local (por Widget)
- Cada `Matter`, `Dimension`, `EditMatter` mantiene su propio estado
- Callbacks (`onMatterUpdateCB`, `onMatterDeleteCB`) comunican cambios a widgets padres
- `setState()` dispara reconstrucción de UI

### Patrón de Actualización

```
┌─────────────────────────────┐
│  Usuario modifica una nota  │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│    onChanged() callback     │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ Actualizar noteList         │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ dimension.calculate()       │
│ matter.calculate()          │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│    setState(() {...})       │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│  Reconstruir Widget Tree    │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│    saveData() a Firebase    │
└─────────────────────────────┘
```

---

## Código de Colores para Notas Requeridas

La visualización de la "nota requerida" utiliza un sistema de colores:

```dart
// En note_display_only.dart
Color getColorForNote(double value) {
  if (value == 0) return Colors.grey;           // Sin nota
  if (value < 4.0) return Colors.red;           // Reprobado
  if (value >= 7.0) return Colors.yellow;       // Difícil de alcanzar
  return Color.fromARGB(255, 117, 245, 66);     // Alcanzable (verde)
}
```

**Interpretación:**
- **Gris**: No hay nota ingresada / No aplica
- **Verde (< 7.0)**: Meta alcanzable con esfuerzo normal
- **Amarillo (7.0 - 10.0)**: Meta difícil pero técnicamente posible
- **Rojo (> 10.0 o < 4.0)**: Meta imposible o ya reprobado

---

## Consideraciones de Seguridad

### Firebase Security Rules (Recomendadas)

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid"
      }
    }
  }
}
```

Esto asegura que:
- Solo usuarios autenticados pueden acceder a sus propios datos
- Cada usuario solo puede leer/escribir su propia información

---

## Optimizaciones Implementadas

1. **Cálculo Lazy**: Los promedios se calculan solo cuando se muestran o modifican
2. **Serialización Eficiente**: Solo se envían a Firebase los datos necesarios
3. **Cache Local**: SharedPreferences evita reautenticación constante
4. **Validación de Entrada**: Los campos de nota solo aceptan valores numéricos

---

## Posibles Mejoras Futuras

### Arquitectura
- [ ] Implementar state management con Provider o Riverpod
- [ ] Separar lógica de negocio en servicios independientes
- [ ] Implementar patrón Repository para abstracción de datos

### Funcionalidad
- [ ] Soporte para múltiples periodos académicos
- [ ] Gráficos de evolución con charts_flutter
- [ ] Modo offline con sincronización posterior
- [ ] Exportación a PDF/Excel

### Performance
- [ ] Lazy loading de materias
- [ ] Optimización de reconstrucciones con const widgets
- [ ] Implementar debounce en saveData()

---

## Diagrama de Clases Simplificado

```
┌──────────────────────┐
│   MatterData         │
├──────────────────────┤
│ - matterTitle        │
│ - dimension[]        │
│ - targetNote         │
│ - _average           │
│ - _minimumRequired   │
├──────────────────────┤
│ + calculate()        │
│ + isFinal()          │
│ + toMap()            │
│ + fromMap()          │
└──────────┬───────────┘
           │
           │ 1:N
           │
           ▼
┌──────────────────────┐
│  DimensionData       │
├──────────────────────┤
│ - dimensionTitle     │
│ - numNotes           │
│ - noteList[]         │
│ - percentageWeight   │
│ - removeWorstNote    │
│ - _average           │
│ - _minimumRequired   │
├──────────────────────┤
│ + calculate()        │
│ + isFinal()          │
│ + toMap()            │
│ + fromMap()          │
└──────────────────────┘
```

---

## Conclusión

EvaluApp es una aplicación bien estructurada que separa claramente las responsabilidades en capas (presentación, lógica de negocio, persistencia). Los algoritmos de cálculo son robustos y manejan casos edge como redistribución de pesos y eliminación de peor nota. La integración con Firebase proporciona sincronización confiable entre dispositivos.
