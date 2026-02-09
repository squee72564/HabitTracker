int captureTzOffsetMinutesAtEvent(final DateTime dateTime) {
  final DateTime localDateTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;
  return localDateTime.timeZoneOffset.inMinutes;
}
