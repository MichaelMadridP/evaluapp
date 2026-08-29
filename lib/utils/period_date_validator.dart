const invalidPeriodStartDateMessage =
    'La fecha de inicio es posterior a la fecha de término.';
const invalidPeriodEndDateMessage =
    'La fecha de término es anterior a la fecha de inicio.';

String? validatePeriodStartDate({
  required DateTime startDate,
  DateTime? endDate,
}) {
  if (endDate != null && startDate.isAfter(endDate)) {
    return invalidPeriodStartDateMessage;
  }
  return null;
}

String? validatePeriodEndDate({
  required DateTime endDate,
  DateTime? startDate,
}) {
  if (startDate != null && endDate.isBefore(startDate)) {
    return invalidPeriodEndDateMessage;
  }
  return null;
}
