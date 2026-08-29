import 'package:evaluapp/utils/evaluation_date_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateEvaluationDate', () {
    final today = DateTime(2026, 8, 28, 15, 30);

    test('advierte solo cuando la fecha es anterior al día actual', () {
      expect(
        validateEvaluationDate(
          date: DateTime(2026, 8, 27),
          now: today,
        ).map((warning) => warning.message),
        contains(
          'Esta fecha es una fecha pasada, ¿estás seguro de continuar?',
        ),
      );
      expect(
        validateEvaluationDate(
          date: DateTime(2026, 8, 28),
          now: today,
        ),
        isEmpty,
      );
    });

    test('exige que la fecha sea posterior a la nota anterior', () {
      final warnings = validateEvaluationDate(
        date: DateTime(2026, 9, 10),
        now: today,
        previousDate: DateTime(2026, 9, 10),
      );

      expect(
        warnings.map((warning) => warning.message),
        contains('La fecha debe ser posterior a la fecha de la nota anterior.'),
      );
    });

    test('exige que la fecha sea anterior a la nota siguiente', () {
      final warnings = validateEvaluationDate(
        date: DateTime(2026, 10, 11),
        now: today,
        nextDate: DateTime(2026, 10, 10),
      );

      expect(
        warnings.map((warning) => warning.message),
        contains('La fecha debe ser anterior a la fecha de la nota siguiente.'),
      );
    });

    test('acepta los límites inclusivos del período', () {
      final startWarnings = validateEvaluationDate(
        date: DateTime(2026, 8, 28),
        now: today,
        periodStartDate: DateTime(2026, 8, 28),
        periodEndDate: DateTime(2026, 12, 20),
      );
      final endWarnings = validateEvaluationDate(
        date: DateTime(2026, 12, 20),
        now: today,
        periodStartDate: DateTime(2026, 8, 28),
        periodEndDate: DateTime(2026, 12, 20),
      );

      expect(startWarnings, isEmpty);
      expect(endWarnings, isEmpty);
    });

    test('advierte fuera del período solo si ambos límites están definidos',
        () {
      final warnings = validateEvaluationDate(
        date: DateTime(2027, 1, 5),
        now: today,
        periodStartDate: DateTime(2026, 8, 1),
        periodEndDate: DateTime(2026, 12, 20),
      );
      final incompletePeriodWarnings = validateEvaluationDate(
        date: DateTime(2027, 1, 5),
        now: today,
        periodStartDate: DateTime(2026, 8, 1),
      );

      expect(
        warnings.map((warning) => warning.message),
        contains(
          'La fecha está fuera de las fechas de inicio y término del período.',
        ),
      );
      expect(incompletePeriodWarnings, isEmpty);
    });

    test('devuelve todas las advertencias aplicables', () {
      final warnings = validateEvaluationDate(
        date: DateTime(2026, 7, 1),
        now: today,
        previousDate: DateTime(2026, 8, 1),
        periodStartDate: DateTime(2026, 8, 1),
        periodEndDate: DateTime(2026, 12, 20),
      );

      expect(warnings, hasLength(3));
    });
  });
}
