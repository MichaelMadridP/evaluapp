import 'package:evaluapp/utils/period_date_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validación de fechas del período', () {
    test('rechaza el inicio si es posterior al término', () {
      expect(
        validatePeriodStartDate(
          startDate: DateTime(2026, 8, 20),
          endDate: DateTime(2026, 8, 10),
        ),
        invalidPeriodStartDateMessage,
      );
    });

    test('rechaza el término si es anterior al inicio', () {
      expect(
        validatePeriodEndDate(
          startDate: DateTime(2026, 8, 20),
          endDate: DateTime(2026, 8, 10),
        ),
        invalidPeriodEndDateMessage,
      );
    });

    test('acepta fechas iguales o en orden cronológico', () {
      expect(
        validatePeriodStartDate(
          startDate: DateTime(2026, 8, 10),
          endDate: DateTime(2026, 8, 10),
        ),
        isNull,
      );
      expect(
        validatePeriodEndDate(
          startDate: DateTime(2026, 8, 10),
          endDate: DateTime(2026, 8, 20),
        ),
        isNull,
      );
    });

    test('acepta que la otra fecha aún no esté definida', () {
      expect(
        validatePeriodStartDate(startDate: DateTime(2026, 8, 20)),
        isNull,
      );
      expect(
        validatePeriodEndDate(endDate: DateTime(2026, 8, 10)),
        isNull,
      );
    });
  });
}
