class RelapseBackdateOutOfRangeException implements Exception {
  const RelapseBackdateOutOfRangeException({
    required this.selectedLocalDate,
    required this.nowLocalDate,
    required this.maxBackdateDays,
  });

  final DateTime selectedLocalDate;
  final DateTime nowLocalDate;
  final int maxBackdateDays;

  @override
  String toString() {
    return 'RelapseBackdateOutOfRangeException('
        'selectedLocalDate: $selectedLocalDate, '
        'nowLocalDate: $nowLocalDate, '
        'maxBackdateDays: $maxBackdateDays'
        ')';
  }
}

DateTime resolveBackdatedRelapseLocalDateTime({
  required final DateTime nowLocal,
  required final DateTime selectedLocalDate,
  final int maxBackdateDays = 7,
}) {
  if (maxBackdateDays < 1) {
    throw ArgumentError.value(
      maxBackdateDays,
      'maxBackdateDays',
      'maxBackdateDays must be at least 1.',
    );
  }

  final DateTime normalizedNowLocal = nowLocal.isUtc
      ? nowLocal.toLocal()
      : nowLocal;
  final DateTime normalizedSelectedLocalDate = selectedLocalDate.isUtc
      ? selectedLocalDate.toLocal()
      : selectedLocalDate;

  final DateTime nowLocalDateOnly = DateTime(
    normalizedNowLocal.year,
    normalizedNowLocal.month,
    normalizedNowLocal.day,
  );
  final DateTime selectedDateOnly = DateTime(
    normalizedSelectedLocalDate.year,
    normalizedSelectedLocalDate.month,
    normalizedSelectedLocalDate.day,
  );

  final DateTime earliestAllowedDate = nowLocalDateOnly.subtract(
    Duration(days: maxBackdateDays),
  );
  final DateTime latestAllowedDate = nowLocalDateOnly.subtract(
    const Duration(days: 1),
  );

  final bool isInAllowedRange =
      !selectedDateOnly.isBefore(earliestAllowedDate) &&
      !selectedDateOnly.isAfter(latestAllowedDate);
  if (!isInAllowedRange) {
    throw RelapseBackdateOutOfRangeException(
      selectedLocalDate: selectedDateOnly,
      nowLocalDate: nowLocalDateOnly,
      maxBackdateDays: maxBackdateDays,
    );
  }

  return DateTime(
    selectedDateOnly.year,
    selectedDateOnly.month,
    selectedDateOnly.day,
    normalizedNowLocal.hour,
    normalizedNowLocal.minute,
    normalizedNowLocal.second,
    normalizedNowLocal.millisecond,
    normalizedNowLocal.microsecond,
  );
}
