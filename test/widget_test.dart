import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evaluapp/main.dart';
import 'package:evaluapp/components/edit_matter.dart';
import 'package:evaluapp/components/edit_period.dart';
import 'package:evaluapp/components/note.dart';
import 'package:evaluapp/components/note_display_only.dart';
import 'package:evaluapp/screens/study_plan_screen.dart';
import 'package:evaluapp/themes.dart';
import 'package:evaluapp/data_model/model.dart';
import 'package:evaluapp/data_model/data_connect.dart';
import 'package:evaluapp/data_model/preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('DimensionData Unit Tests', () {
    test('Calcula promedio simple correctamente', () {
      final dimension = DimensionData(
        dimensionTitle: 'Tareas',
        numNotes: 3,
        noteList: [5.0, 6.0, 7.0],
        percentageWeight: 30,
        removeWorstNote: false,
        isDismissable: true,
      );

      dimension.calculate();

      expect(dimension.average, closeTo(6.0, 0.001));
      expect(dimension.isFinal(), isTrue);
      expect(dimension.minimumRequired, equals(0));
    });

    test('Elimina la peor nota cuando removeWorstNote es true y hay > 1 nota', () {
      final dimension = DimensionData(
        dimensionTitle: 'Controles',
        numNotes: 3,
        noteList: [3.0, 5.0, 7.0],
        percentageWeight: 40,
        removeWorstNote: true,
        isDismissable: true,
      );

      dimension.calculate();

      // Debe eliminar el 3.0 y promediar (5.0 + 7.0) / 2 = 6.0
      expect(dimension.average, closeTo(6.0, 0.001));
    });

    test('Calcula la nota minima requerida para evaluaciones pendientes', () {
      final dimension = DimensionData(
        dimensionTitle: 'Pruebas',
        numNotes: 2,
        noteList: [3.0, 0],
        percentageWeight: 50,
        removeWorstNote: false,
        isDismissable: false,
      );
      dimension.targetNote = 4.0;

      dimension.calculate();

      expect(dimension.average, closeTo(3.0, 0.001));
      expect(dimension.isFinal(), isFalse);
      // Para obtener promedio 4.0 en 2 notas con una nota 3.0: (4.0 * 2 - 3.0) / 1 = 5.0
      expect(dimension.minimumRequired, closeTo(5.0, 0.001));
    });

    test('Serializacion toMap y fromMap', () {
      final original = DimensionData(
        dimensionTitle: 'Laboratorios',
        numNotes: 2,
        noteList: [4.5, 6.5],
        percentageWeight: 30,
        removeWorstNote: true,
        isDismissable: false,
      );

      final map = original.toMap();
      final restored = DimensionData.fromMap(map);

      expect(restored.dimensionTitle, equals('Laboratorios'));
      expect(restored.numNotes, equals(2));
      expect(restored.noteList, equals([4.5, 6.5]));
      expect(restored.percentageWeight, equals(30));
      expect(restored.removeWorstNote, isTrue);
      expect(restored.isDismissable, isFalse);
    });
  });

  group('MatterData Unit Tests - Consistencia Matematica y Persistencia', () {
    test('Calcula promedio ponderado completo de una materia', () {
      final dim1 = DimensionData(
        dimensionTitle: 'Teoria',
        numNotes: 1,
        noteList: [5.0],
        percentageWeight: 60,
        removeWorstNote: false,
        isDismissable: false,
      );
      final dim2 = DimensionData(
        dimensionTitle: 'Practica',
        numNotes: 1,
        noteList: [6.0],
        percentageWeight: 40,
        removeWorstNote: false,
        isDismissable: false,
      );

      final matter = MatterData(
        matterTitle: 'Fisica I',
        dimension: [dim1, dim2],
      );

      matter.calculate();

      // Promedio = 5.0 * 0.60 + 6.0 * 0.40 = 3.0 + 2.4 = 5.4
      expect(matter.average, closeTo(5.4, 0.001));
      expect(matter.isFinal(), isTrue);
      expect(matter.minimumRequired, equals(0));
    });

    test('Consistencia Matematica: Normalizacion proporcional con dimensiones asimetricas', () {
      // Tareas 10% (nota 7.0), Controles 30% (nota 5.0), Examen 60% (pendiente 0)
      final dim1 = DimensionData(
        dimensionTitle: 'Tareas',
        numNotes: 1,
        noteList: [7.0],
        percentageWeight: 10,
        removeWorstNote: false,
        isDismissable: false,
      );
      final dim2 = DimensionData(
        dimensionTitle: 'Controles',
        numNotes: 1,
        noteList: [5.0],
        percentageWeight: 30,
        removeWorstNote: false,
        isDismissable: false,
      );
      final dim3 = DimensionData(
        dimensionTitle: 'Examen Final',
        numNotes: 1,
        noteList: [0],
        percentageWeight: 60,
        removeWorstNote: false,
        isDismissable: false,
      );

      final matter = MatterData(
        matterTitle: 'Calculo III',
        dimension: [dim1, dim2, dim3],
        targetNote: 4.0,
      );

      matter.calculate();

      // Peso activo = 10 + 30 = 40
      // Proporciones relativas: Tareas = 10/40 = 0.25, Controles = 30/40 = 0.75
      // Promedio parcial = 7.0 * 0.25 + 5.0 * 0.75 = 1.75 + 3.75 = 5.5
      expect(matter.average, closeTo(5.5, 0.001));

      // Nota requerida en el 60% restante para llegar a targetNote = 4.0:
      // (4.0 - (5.5 * 0.40)) / 0.60 = (4.0 - 2.2) / 0.60 = 1.8 / 0.60 = 3.0
      expect(matter.minimumRequired, closeTo(3.0, 0.001));
    });

    test('Persistencia: targetNote se guarda y restaura correctamente en fromMap()', () {
      final matter = MatterData(
        matterTitle: 'Estructuras de Datos',
        dimension: [
          DimensionData(
            dimensionTitle: 'Talleres',
            numNotes: 1,
            noteList: [4.0],
            percentageWeight: 100,
            removeWorstNote: false,
            isDismissable: false,
          )
        ],
        targetNote: 5.5,
      );

      final serialized = matter.toMap();
      expect(serialized['targetNote'], equals(5.5));

      final restored = MatterData.fromMap(serialized);
      expect(restored.targetNote, equals(5.5));
      expect(restored.dimension.first.targetNote, equals(5.5));
    });

    test('Inmutabilidad: Clonar dimensiones no afecta la lista original', () {
      final originalNotes = [4.0, 5.0, 6.0];
      final dim = DimensionData(
        dimensionTitle: 'Test',
        numNotes: 3,
        noteList: originalNotes,
        percentageWeight: 100,
        removeWorstNote: false,
        isDismissable: false,
      );

      // Simula la clonacion profunda en EditMatter.initState
      final clonedNotes = List<double>.from(dim.noteList);
      clonedNotes.removeLast(); // Modificacion en modal

      expect(clonedNotes.length, equals(2));
      expect(dim.noteList.length, equals(3));
      expect(dim.noteList, equals([4.0, 5.0, 6.0]));
    });

    test('Simula crear, editar y guardar una materia', () {
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

      final MatterData tempMatter = MatterData(matterTitle: '', dimension: [
        DimensionData(
            dimensionTitle: '',
            numNotes: 1,
            noteList: [0],
            percentageWeight: 100,
            removeWorstNote: false,
            isDismissable: false)
      ]);

      // Simular accion ADD
      tempMatter.dimension.clear();

      // Simular agregar una dimension
      tempMatter.dimension.add(DimensionData(
        dimensionTitle: 'Test Dim',
        numNotes: 1,
        noteList: [0],
        percentageWeight: 100,
        removeWorstNote: false,
        isDismissable: false,
      ));

      // Simular onPressOk
      newMatter.matterTitle = 'Calculo I';
      newMatter.targetNote = tempMatter.targetNote;
      newMatter.dimension.clear();
      for (int i = 0; i < tempMatter.dimension.length; i++) {
        newMatter.dimension.add(tempMatter.dimension[i]);
      }

      newMatter.calculate();

      expect(newMatter.matterTitle, equals('Calculo I'));
      expect(newMatter.dimension.length, equals(1));
      expect(newMatter.dimension[0].dimensionTitle, equals('Test Dim'));
    });
  });

  group('HomeScreen Widget Tests', () {
    testWidgets('Prueba flujo de agregar una nueva materia', (WidgetTester tester) async {
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({
        'userid': '', // userid vacio para evitar llamadas reales de Firebase
        'username': 'Test User',
        'isDarkMode': true,
      });

      await initSharedPreferences();

      // Pump HomeScreen envuelto en ThemeProvider y MaterialApp
      await tester.pumpWidget(
        ThemeProvider(
          colors: darkColors,
          isDarkMode: true,
          toggleTheme: (val) {},
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verificar que HomeScreen está presente
      expect(find.byType(HomeScreen), findsOneWidget);

      // Presionar el botón '+' en el AppBar
      final addButton = find.byIcon(Icons.add);
      expect(addButton, findsOneWidget);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Verificar que el modal EditMatter se despliega
      expect(find.byType(EditMatter), findsOneWidget);

      // Buscar campos de texto. El primer campo de texto en EditMatter es el nombre de la materia.
      final textFields = find.byType(TextField);
      // Debe haber al menos 2 campos inicialmente (Nombre Materia, Nota Objetivo)
      expect(textFields, findsAtLeastNWidgets(2));

      // Escribir nombre de la materia
      await tester.enterText(textFields.first, 'Matematica I');
      await tester.pump();

      // Presionar el botón '+' dentro del modal para añadir una dimensión
      final addDimButton = find.descendant(
        of: find.byType(EditMatter),
        matching: find.byIcon(Icons.add),
      );
      expect(addDimButton, findsOneWidget);
      await tester.tap(addDimButton);
      await tester.pumpAndSettle();

      // Después de añadir la dimensión, hay más campos de texto
      final textFieldsAfterDim = find.byType(TextField);
      
      // Escribir el nombre de la dimensión (tercer campo) y su ponderación (cuarto campo)
      await tester.enterText(textFieldsAfterDim.at(2), 'Pruebas');
      await tester.enterText(textFieldsAfterDim.at(3), '100');
      await tester.pumpAndSettle();

      // Presionar botón 'Ok' para guardar
      final okButton = find.text('Ok');
      expect(okButton, findsOneWidget);
      await tester.tap(okButton);
      await tester.pumpAndSettle();

      // El modal debe haberse cerrado
      expect(find.byType(EditMatter), findsNothing);

      // La nueva materia debe estar desplegada en HomeScreen
      expect(find.text('Matematica I'), findsOneWidget);
    });

    testWidgets('Prueba que el dialogo de errores tiene boton Ok', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'userid': '',
        'username': 'Test User',
        'isDarkMode': true,
      });
      await initSharedPreferences();

      await tester.pumpWidget(
        ThemeProvider(
          colors: darkColors,
          isDarkMode: true,
          toggleTheme: (val) {},
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Abrir modal
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Presionar Ok con campos vacios (lo que dispara el dialogo de errores)
      final okButton = find.text('Ok');
      expect(okButton, findsOneWidget);
      await tester.tap(okButton);
      await tester.pumpAndSettle();

      // El dialogo "Hay errores que corregir" debe estar visible
      expect(find.text('Hay errores que corregir'), findsOneWidget);

      // El boton 'Ok' del dialogo debe ser visible y cliqueable
      // Nota: habria 2 botones 'Ok' (el del dialog y el del modal de atras si no se cerro).
      // El del dialogo deberia ser el que está en el AlertDialog.
      final dialogOkButton = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Ok'),
      );
      expect(dialogOkButton, findsOneWidget);

      // Tocar el Ok del dialogo para cerrarlo
      await tester.tap(dialogOkButton);
      await tester.pumpAndSettle();

      // El dialogo debe haber desaparecido
      expect(find.text('Hay errores que corregir'), findsNothing);
    });
  });

  group('NoteDisplayOnly Widget Tests', () {
    testWidgets('Notas >= 4.0 (incluyendo redondeadas y 7.0) se despliegan en azul oscuro con texto blanco',
        (WidgetTester tester) async {
      // 3 notas: 1.2, 4.0, 6.7 -> promedio = 11.9 / 3 = 3.966666666666667
      const double rawAverage = (1.2 + 4.0 + 6.7) / 3.0;

      await tester.pumpWidget(
        ThemeProvider(
          colors: darkColors,
          isDarkMode: true,
          toggleTheme: (val) {},
          child: const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  NoteDisplayOnly(value: rawAverage),
                  NoteDisplayOnly(value: 7.0),
                  NoteDisplayOnly(value: 3.5),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Debe mostrar los textos correctos
      expect(find.text('4.0'), findsOneWidget);
      expect(find.text('7.0'), findsOneWidget);
      expect(find.text('3.5'), findsOneWidget);

      final containers = tester.widgetList<Container>(find.byType(Container)).toList();
      
      // El primero (4.0) debe ser azul oscuro noteGreen
      final dec1 = containers[0].decoration as BoxDecoration;
      expect(dec1.color, equals(const Color(0xFF1E3A8A)));

      // El segundo (7.0) también debe ser azul oscuro noteGreen
      final dec2 = containers[1].decoration as BoxDecoration;
      expect(dec2.color, equals(const Color(0xFF1E3A8A)));

      // El tercero (3.5) debe ser rojo noteRed
      final dec3 = containers[2].decoration as BoxDecoration;
      expect(dec3.color, equals(darkColors.noteRed));

      // Todos los textos deben ser blancos
      final text40 = tester.widget<Text>(find.text('4.0'));
      expect(text40.style?.color, equals(const Color(0xFFFFFFFF)));

      final text70 = tester.widget<Text>(find.text('7.0'));
      expect(text70.style?.color, equals(const Color(0xFFFFFFFF)));

      final text35 = tester.widget<Text>(find.text('3.5'));
      expect(text35.style?.color, equals(const Color(0xFFFFFFFF)));
    });
  });

  group('PeriodData Unit & State Tests', () {
    test('Creación, formateo de fechas y cálculo de materias', () {
      final period = PeriodData(
        name: 'Primer Semestre 2026',
        startDate: DateTime(2026, 3, 15),
        endDate: DateTime(2026, 7, 30),
        matters: [
          MatterData(
            matterTitle: 'Cálculo I',
            dimension: [
              DimensionData(
                dimensionTitle: 'Pruebas',
                numNotes: 2,
                noteList: [6.0, 6.0],
                percentageWeight: 100,
                removeWorstNote: false,
                isDismissable: false,
              ),
            ],
          ),
        ],
      );

      period.calculate();
      expect(period.matters.first.average, equals(6.0));
      expect(period.dateRangeFormatted, equals('15/03/2026 - 30/07/2026'));
    });

    test('Serialización toMap y fromMap de PeriodData', () {
      final original = PeriodData(
        name: 'Trimestre 1',
        startDate: DateTime(2026, 1, 10),
        endDate: DateTime(2026, 4, 15),
        matters: [
          MatterData(
            matterTitle: 'Física',
            dimension: [
              DimensionData(
                dimensionTitle: 'Laboratorios',
                numNotes: 1,
                noteList: [5.5],
                percentageWeight: 100,
                removeWorstNote: false,
                isDismissable: false,
              ),
            ],
          ),
        ],
      );

      final map = original.toMap();
      final restored = PeriodData.fromMap(map);

      expect(restored.id, equals(original.id));
      expect(restored.name, equals('Trimestre 1'));
      expect(restored.startDate?.day, equals(10));
      expect(restored.endDate?.month, equals(4));
      expect(restored.matters.length, equals(1));
      expect(restored.matters.first.matterTitle, equals('Física'));
    });

    test('Manejo de múltiples períodos y aislamiento de materias', () {
      allPeriodsData.clear();
      
      final p1 = PeriodData(name: 'Semestre 1', matters: [
        MatterData(matterTitle: 'Álgebra', dimension: []),
      ]);
      final p2 = PeriodData(name: 'Semestre 2', matters: [
        MatterData(matterTitle: 'Programación', dimension: []),
      ]);

      allPeriodsData.add(p1);
      allPeriodsData.add(p2);
      activePeriod = p1;

      // Al consultar allMattersData debe devolver las materias de p1
      expect(allMattersData.length, equals(1));
      expect(allMattersData.first.matterTitle, equals('Álgebra'));

      // Cambiar a p2
      setActivePeriod(p2.id);
      expect(activePeriod?.name, equals('Semestre 2'));
      expect(allMattersData.first.matterTitle, equals('Programación'));

      // Modificar p1 (renombrar)
      p1.name = 'Semestre 1 - Modificado';
      updatePeriod(p1);
      expect(allPeriodsData.firstWhere((p) => p.id == p1.id).name, equals('Semestre 1 - Modificado'));

      // Eliminar p2 (que estaba activo) -> debe reasignar a p1
      deletePeriod(p2.id);
      expect(allPeriodsData.length, equals(1));
      expect(activePeriod?.id, equals(p1.id));
    });
  });

  group('Period UI & Deletion Warning Widget Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'username': 'Test User',
        'userid': 'test_uid_123',
      });
      await initSharedPreferences();

      allPeriodsData.clear();
      final testPeriod = PeriodData(
        name: 'Primer Semestre 2026',
        startDate: DateTime(2026, 3, 15),
        endDate: DateTime(2026, 7, 30),
        matters: [
          MatterData(matterTitle: 'Química', dimension: []),
        ],
      );
      allPeriodsData.add(testPeriod);
      activePeriod = testPeriod;
    });

    testWidgets('HomeScreen muestra barra de período activo y abre PeriodSelectorModal',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ThemeProvider(
          colors: darkColors,
          isDarkMode: true,
          toggleTheme: (val) {},
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Debe mostrar el nombre del período y las fechas
      expect(find.text('PERÍODO ACADÉMICO'), findsOneWidget);
      expect(find.text('Primer Semestre 2026'), findsOneWidget);
      expect(find.text('15/03/2026 - 30/07/2026'), findsOneWidget);

      // Tocar la barra de período para abrir el modal
      await tester.tap(find.text('Primer Semestre 2026'));
      await tester.pumpAndSettle();

      // El modal de períodos debe estar visible
      expect(find.text('Períodos Académicos'), findsOneWidget);
      expect(find.text('Crear Nuevo Período'), findsOneWidget);
    });

    testWidgets('Advertencia de pérdida de datos al eliminar un período con materias',
        (WidgetTester tester) async {
      final periodWithMatters = PeriodData(
        name: 'Semestre con Datos',
        matters: [
          MatterData(matterTitle: 'Materia 1', dimension: []),
          MatterData(matterTitle: 'Materia 2', dimension: []),
        ],
      );

      await tester.pumpWidget(
        ThemeProvider(
          colors: darkColors,
          isDarkMode: true,
          toggleTheme: (val) {},
          child: MaterialApp(
            home: Scaffold(
              body: EditPeriod(
                action: ActionType.edit,
                period: periodWithMatters,
                onPeriodUpdateCB: () {},
                onPeriodDeleteCB: (id) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Presionar botón Eliminar
      final deleteButton = find.text('Eliminar');
      expect(deleteButton, findsOneWidget);
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // Debe aparecer el diálogo de advertencia explícito
      expect(find.text('¿Eliminar período en uso?'), findsOneWidget);
      expect(find.textContaining('Este período contiene 2 materias registradas'), findsOneWidget);
      expect(find.textContaining('se perderán permanentemente todas las materias'), findsOneWidget);
      expect(find.text('Eliminar Todo'), findsOneWidget);
    });
  });

  group('EvaluationDetail Unit Tests', () {
    test('Valores por defecto y cálculo de hasData', () {
      final defaultDetail = EvaluationDetail();
      expect(defaultDetail.confidenceLevel, equals(4));
      expect(defaultDetail.hasData, isFalse);
      expect(defaultDetail.dateFormatted, equals('Sin fecha'));

      final customDetail = EvaluationDetail(
        date: DateTime(2026, 8, 28),
        content: 'Cálculo multivariable',
        confidenceLevel: 2,
        notes: 'Repasar teorema de Green',
      );
      expect(customDetail.hasData, isTrue);
      expect(customDetail.confidenceLabel, equals('Bajo (2)'));
      expect(customDetail.dateFormatted, equals('28 Ago 2026'));
    });

    test('Serialización toMap y fromMap de EvaluationDetail', () {
      final original = EvaluationDetail(
        date: DateTime(2026, 9, 15),
        content: 'Física Clásica',
        confidenceLevel: 6,
        notes: 'Llevar formulario',
      );

      final map = original.toMap();
      final restored = EvaluationDetail.fromMap(map);

      expect(restored.date?.day, equals(15));
      expect(restored.content, equals('Física Clásica'));
      expect(restored.confidenceLevel, equals(6));
      expect(restored.notes, equals('Llevar formulario'));
    });

    test('Sincronización automática de evaluationDetails en DimensionData', () {
      final dim = DimensionData(
        dimensionTitle: 'Controles',
        numNotes: 2,
        noteList: [5.0, 6.0],
        percentageWeight: 50,
        removeWorstNote: false,
        isDismissable: false,
      );

      expect(dim.evaluationDetails.length, equals(2));

      // Asignar detalle a la primera nota
      dim.evaluationDetails[0].content = 'Control 1';
      dim.evaluationDetails[0].confidenceLevel = 3;

      // Serializar y restaurar
      final map = dim.toMap();
      final restored = DimensionData.fromMap(map);

      expect(restored.evaluationDetails.length, equals(2));
      expect(restored.evaluationDetails[0].content, equals('Control 1'));
      expect(restored.evaluationDetails[0].confidenceLevel, equals(3));
    });
  });

  group('StudyPlan & Note LongPress Widget Tests', () {
    testWidgets('LongPress en Note dispara el callback onLongPress',
        (WidgetTester tester) async {
      bool longPressed = false;
      final detail = EvaluationDetail(
        content: 'Prueba de LongPress',
        confidenceLevel: 2,
      );

      await tester.pumpWidget(
        ThemeProvider(
          colors: darkColors,
          isDarkMode: true,
          toggleTheme: (val) {},
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: Note(
                    iValue: 5.5,
                    label: '01',
                    isActive: true,
                    idxNote: 0,
                    evaluationDetail: detail,
                    onLongPress: () {
                      longPressed = true;
                    },
                    onNoteLostFocusCB: (pos, val) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Realizar long press sobre la casilla
      await tester.longPress(find.byType(Note));
      await tester.pumpAndSettle();

      expect(longPressed, isTrue);
    });

    testWidgets('StudyPlanScreen renderiza métricas y evaluaciones ordenadas por prioridad',
        (WidgetTester tester) async {
      allPeriodsData.clear();
      final period = PeriodData(
        name: 'Primer Semestre 2026',
        matters: [
          MatterData(
            matterTitle: 'Cálculo',
            dimension: [
              DimensionData(
                dimensionTitle: 'Certamen',
                numNotes: 2,
                noteList: [0, 0],
                percentageWeight: 100,
                removeWorstNote: false,
                isDismissable: false,
                evaluationDetails: [
                  EvaluationDetail(
                    content: 'Límites y Continuidad',
                    confidenceLevel: 2, // Crítico
                    date: DateTime(2026, 9, 10),
                  ),
                  EvaluationDetail(
                    content: 'Derivadas',
                    confidenceLevel: 6, // Alto
                    date: DateTime(2026, 10, 15),
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      allPeriodsData.add(period);
      activePeriod = period;

      await tester.pumpWidget(
        ThemeProvider(
          colors: darkColors,
          isDarkMode: true,
          toggleTheme: (val) {},
          child: const MaterialApp(
            home: StudyPlanScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verificar elementos del encabezado
      expect(find.text('Plan de Estudio'), findsOneWidget);
      expect(find.text('Período: Primer Semestre 2026'), findsOneWidget);
      expect(find.text('Foco Crítico'), findsOneWidget);

      // Debe listar las evaluaciones de Cálculo
      expect(find.text('Cálculo'), findsNWidgets(2));
      expect(find.text('Límites y Continuidad'), findsOneWidget);
      expect(find.text('Derivadas'), findsOneWidget);
    });
  });

  group('Session & Multiplatform Unit Tests', () {
    test('clearSessionData limpia períodos, materias y período activo', () {
      allPeriodsData.add(PeriodData(name: 'Prueba'));
      activePeriod = allPeriodsData.first;

      expect(allPeriodsData.isNotEmpty, isTrue);
      expect(activePeriod, isNotNull);

      clearSessionData();

      expect(allPeriodsData.isEmpty, isTrue);
      expect(activePeriod, isNull);
      expect(allMattersData.isEmpty, isTrue);
    });
  });

  group('Edge Cases & Validation Tests', () {
    testWidgets('NoteDisplayOnly maneja metas inalcanzables (>7.0) y metas ya aprobadas (<1.0)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ThemeProvider(
          colors: darkColors,
          isDarkMode: true,
          toggleTheme: (val) {},
          child: const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  NoteDisplayOnly(value: 8.5),
                  NoteDisplayOnly(value: 0.4),
                  NoteDisplayOnly(value: 0.0),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('>7.0'), findsOneWidget);
      expect(find.text('1.0'), findsOneWidget);
      expect(find.text('-'), findsOneWidget);
    });

    testWidgets('Note rechaza valores fuera de rango y despliega feedback SnackBar',
        (WidgetTester tester) async {
      double receivedNote = 0;
      await tester.pumpWidget(
        ThemeProvider(
          colors: darkColors,
          isDarkMode: true,
          toggleTheme: (val) {},
          child: MaterialApp(
            home: Scaffold(
              body: Note(
                iValue: 0,
                label: 'C1',
                isActive: true,
                idxNote: 0,
                onNoteLostFocusCB: (pos, val) {
                  receivedNote = val;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ingresar nota fuera de rango (8.5)
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), '8.5');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(receivedNote, equals(0.0));
      expect(find.text('Nota fuera de rango. Ingrese una nota entre 1.0 y 7.0'),
          findsOneWidget);
    });

    testWidgets('Las casillas Note activas e inactivas mantienen la misma altura', (WidgetTester tester) async {
      await tester.pumpWidget(
        ThemeProvider(
          colors: darkColors,
          isDarkMode: true,
          toggleTheme: (val) {},
          child: MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  Expanded(
                    child: Note(
                      iValue: 0,
                      label: '01',
                      isActive: true,
                      idxNote: 0,
                      onNoteLostFocusCB: (pos, val) {},
                    ),
                  ),
                  Expanded(
                    child: Note(
                      iValue: 0,
                      label: '02',
                      isActive: false,
                      idxNote: 1,
                      onNoteLostFocusCB: (pos, val) {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));
      final activeSize = tester.getSize(textFields.first);
      final inactiveSize = tester.getSize(textFields.last);

      expect(activeSize.height, equals(inactiveSize.height));
      expect(activeSize.width, equals(inactiveSize.width));
    });
  });
}
