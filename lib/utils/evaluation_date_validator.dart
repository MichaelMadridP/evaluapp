class EvaluationDateWarning {
  const EvaluationDateWarning(this.message);

  final String message;
}

List<EvaluationDateWarning> validateEvaluationDate({
  required DateTime date,
  required DateTime now,
  DateTime? previousDate,
  DateTime? nextDate,
  DateTime? periodStartDate,
  DateTime? periodEndDate,
}) {
  final selectedDay = DateTime(date.year, date.month, date.day);
  final today = DateTime(now.year, now.month, now.day);
  final warnings = <EvaluationDateWarning>[];

  if (selectedDay.isBefore(today)) {
    warnings.add(const EvaluationDateWarning(
      'Esta fecha es una fecha pasada, ¿estás seguro de continuar?',
    ));
  }

  if (previousDate != null) {
    final previousDay =
        DateTime(previousDate.year, previousDate.month, previousDate.day);
    if (!selectedDay.isAfter(previousDay)) {
      warnings.add(const EvaluationDateWarning(
        'La fecha debe ser posterior a la fecha de la nota anterior.',
      ));
    }
  }

  if (nextDate != null) {
    final nextDay = DateTime(nextDate.year, nextDate.month, nextDate.day);
    if (!selectedDay.isBefore(nextDay)) {
      warnings.add(const EvaluationDateWarning(
        'La fecha debe ser anterior a la fecha de la nota siguiente.',
      ));
    }
  }

  if (periodStartDate != null && periodEndDate != null) {
    final periodStart = DateTime(
      periodStartDate.year,
      periodStartDate.month,
      periodStartDate.day,
    );
    final periodEnd = DateTime(
      periodEndDate.year,
      periodEndDate.month,
      periodEndDate.day,
    );
    if (selectedDay.isBefore(periodStart) || selectedDay.isAfter(periodEnd)) {
      warnings.add(const EvaluationDateWarning(
        'La fecha está fuera de las fechas de inicio y término del período.',
      ));
    }
  }

  return warnings;
}
