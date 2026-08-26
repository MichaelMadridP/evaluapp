import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evaluapp/data_model/model.dart';
import 'package:evaluapp/data_model/data_connect.dart';
import 'package:evaluapp/data_model/preferences.dart';
import 'package:evaluapp/services/period_report_service.dart';
import 'package:evaluapp/components/period_report_modal.dart';
import 'package:evaluapp/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PeriodReportService Unit Tests', () {
    late PeriodData samplePeriod;

    setUp(() {
      samplePeriod = PeriodData(
        name: 'Segundo Semestre 2026',
        startDate: DateTime(2026, 8, 25),
        endDate: DateTime(2026, 12, 30),
        matters: [
          MatterData(
            matterTitle: 'Economía',
            targetNote: 4.0,
            dimension: [
              DimensionData(
                dimensionTitle: 'Tareas',
                numNotes: 3,
                noteList: [5.0, 6.0, 0],
                percentageWeight: 40,
                removeWorstNote: false,
                isDismissable: false,
                evaluationDetails: [
                  EvaluationDetail(content: 'Tarea 1 Microeconomía'),
                  EvaluationDetail(content: 'Tarea 2 Elasticidad'),
                  EvaluationDetail(
                    content: 'Tarea 3 Mercado',
                    date: DateTime(2026, 9, 20),
                    confidenceLevel: 3,
                    notes: 'Revisar fórmulas de excedente',
                  ),
                ],
              ),
              DimensionData(
                dimensionTitle: 'Examen',
                numNotes: 1,
                noteList: [0],
                percentageWeight: 60,
                removeWorstNote: false,
                isDismissable: false,
                evaluationDetails: [
                  EvaluationDetail(
                    content: 'Examen Final de Cátedra',
                    date: DateTime(2026, 12, 15),
                    confidenceLevel: 2,
                    notes: 'Hacer resumen de todos los capítulos',
                  ),
                ],
              ),
            ],
          ),
          MatterData(
            matterTitle: 'Cálculo',
            targetNote: 5.0,
            dimension: [
              DimensionData(
                dimensionTitle: 'Controles',
                numNotes: 2,
                noteList: [5.5, 6.5],
                percentageWeight: 100,
                removeWorstNote: false,
                isDismissable: false,
              ),
            ],
          ),
        ],
      );
    });

    test('calculatePeriodStats genera métricas globales correctas', () {
      final stats = PeriodReportService.calculatePeriodStats(samplePeriod);

      expect(stats['totalMatters'], equals(2));
      expect(stats['totalNotes'], equals(6)); // 3 + 1 + 2
      expect(stats['completedNotes'], equals(4)); // 2 en tareas + 0 en examen + 2 en controles
      expect(stats['pendingNotes'], equals(2)); // 1 en tareas + 1 en examen
      expect(stats['overallAverage'], greaterThan(0));
    });

    test('generateSubject incluye el nombre del período y usuario', () {
      final subject = PeriodReportService.generateSubject(
        period: samplePeriod,
        userName: 'Michael',
      );

      expect(subject, contains('[EvaluApp]'));
      expect(subject, contains('Segundo Semestre 2026'));
      expect(subject, contains('Michael'));
    });

    test('generatePlainTextReport sin Plan de Estudio omite notas y fechas de estudio', () {
      final report = PeriodReportService.generatePlainTextReport(
        period: samplePeriod,
        userName: 'Michael',
        includeStudyPlan: false,
      );

      expect(report, contains('EVALUAPP - REPORTE DE AVANCE ACADÉMICO'));
      expect(report, contains('ECONOMÍA'));
      expect(report, contains('CÁLCULO'));
      expect(report, contains('Nota Objetivo: 4.0'));
      expect(report, contains('Tareas (40%)'));
      expect(report, contains('5.0, 6.0'));
      // No debe contener la sección explícita de plan de estudio
      expect(report, isNot(contains('🎯 Plan de Estudio (Evaluaciones Faltantes)')));
      expect(report, isNot(contains('Revisar fórmulas de excedente')));
    });

    test('generatePlainTextReport con Plan de Estudio incluye fechas, confianza y apuntes', () {
      final report = PeriodReportService.generatePlainTextReport(
        period: samplePeriod,
        userName: 'Michael',
        includeStudyPlan: true,
      );

      expect(report, contains('🎯 Plan de Estudio (Evaluaciones Faltantes)'));
      expect(report, contains('Tarea 3 Mercado'));
      expect(report, contains('Revisar fórmulas de excedente'));
      expect(report, contains('Examen Final de Cátedra'));
      expect(report, contains('Hacer resumen de todos los capítulos'));
      expect(report, contains('15 Dic 2026'));
    });

    test('generateHtmlReport genera código HTML válido con estructura completa', () {
      final html = PeriodReportService.generateHtmlReport(
        period: samplePeriod,
        userName: 'Michael',
        includeStudyPlan: true,
      );

      expect(html, contains('<!DOCTYPE html>'));
      expect(html, contains('Segundo Semestre 2026'));
      expect(html, contains('Economía'));
      expect(html, contains('Cálculo'));
      expect(html, contains('Tarea 3 Mercado'));
      expect(html, contains('Revisar fórmulas de excedente'));
    });

    test('generateMailtoUri codifica parámetros correctamente', () {
      final uri = PeriodReportService.generateMailtoUri(
        recipients: ['luis@gmail.com', 'maria@gmail.com'],
        subject: 'Reporte Académico',
        body: 'Hola, este es mi reporte',
      );

      expect(uri.scheme, equals('mailto'));
      expect(uri.path, equals('luis@gmail.com,maria@gmail.com'));
      expect(uri.queryParameters['subject'], equals('Reporte Académico'));
      expect(uri.queryParameters['body'], equals('Hola, este es mi reporte'));
    });
  });

  group('PeriodReportModal Widget Tests', () {
    late PeriodData testPeriod;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'report_recipients_list': ['luis@gmail.com'],
        'username': 'Estudiante Test',
      });
      await initSharedPreferences();

      testPeriod = PeriodData(
        name: 'Primer Semestre 2026',
        matters: [
          MatterData(
            matterTitle: 'Física',
            targetNote: 4.0,
            dimension: [
              DimensionData(
                dimensionTitle: 'Laboratorio',
                numNotes: 2,
                noteList: [6.0, 0],
                percentageWeight: 100,
                removeWorstNote: false,
                isDismissable: false,
                evaluationDetails: [
                  EvaluationDetail(content: 'Lab 1 Óptica'),
                  EvaluationDetail(
                    content: 'Lab 2 Circuitos',
                    confidenceLevel: 5,
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      allPeriodsData.clear();
      allPeriodsData.add(testPeriod);
      activePeriod = testPeriod;
    });

    testWidgets('PeriodReportModal renderiza correctamente y carga destinatarios iniciales',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ThemeProvider(
          colors: darkColors,
          isDarkMode: true,
          toggleTheme: (val) {},
          child: MaterialApp(
            home: Scaffold(
              body: PeriodReportModal(initialPeriod: testPeriod),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reporte del Período'), findsOneWidget);
      expect(find.text('Destinatarios (Mails)'), findsOneWidget);
      expect(find.text('luis@gmail.com'), findsOneWidget);
      expect(find.text('Incluir Plan de Estudio'), findsOneWidget);
      expect(find.text('Copiar'), findsOneWidget);
      expect(find.text('Enviar Reporte'), findsOneWidget);
    });

    testWidgets('Agregar nuevo correo válido lo incluye en la lista y persiste en SharedPreferences',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ThemeProvider(
          colors: darkColors,
          isDarkMode: true,
          toggleTheme: (val) {},
          child: MaterialApp(
            home: Scaffold(
              body: PeriodReportModal(initialPeriod: testPeriod),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final inputField = find.byType(TextField);
      expect(inputField, findsOneWidget);

      await tester.enterText(inputField, 'maria@gmail.com');
      await tester.tap(find.byTooltip('Agregar correo'));
      await tester.pumpAndSettle();

      expect(find.text('maria@gmail.com'), findsOneWidget);
      expect(getReportRecipients(), contains('maria@gmail.com'));
    });

    testWidgets('Eliminar un correo lo quita de la lista y actualiza SharedPreferences',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ThemeProvider(
          colors: darkColors,
          isDarkMode: true,
          toggleTheme: (val) {},
          child: MaterialApp(
            home: Scaffold(
              body: PeriodReportModal(initialPeriod: testPeriod),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('luis@gmail.com'), findsOneWidget);

      final deleteIcon = find.byIcon(Icons.close_rounded);
      expect(deleteIcon, findsOneWidget);
      await tester.tap(deleteIcon);
      await tester.pumpAndSettle();

      expect(find.text('luis@gmail.com'), findsNothing);
      expect(getReportRecipients(), isEmpty);
    });

    testWidgets('Alternar vista previa muestra y oculta el cuadro de texto formateado',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ThemeProvider(
          colors: darkColors,
          isDarkMode: true,
          toggleTheme: (val) {},
          child: MaterialApp(
            home: Scaffold(
              body: PeriodReportModal(initialPeriod: testPeriod),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ver vista previa del reporte'), findsOneWidget);
      expect(find.byType(SelectableText), findsNothing);

      await tester.tap(find.text('Ver vista previa del reporte'));
      await tester.pumpAndSettle();

      expect(find.text('Ocultar vista previa'), findsOneWidget);
      expect(find.byType(SelectableText), findsOneWidget);
      expect(find.textContaining('FÍSICA'), findsOneWidget);
    });
  });
}
