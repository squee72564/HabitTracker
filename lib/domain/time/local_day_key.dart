import 'package:habit_tracker/domain/value_objects/domain_constraints.dart';

String toLocalDayKey(final DateTime dateTime) {
  final DateTime localDateTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;
  return _formatDayKey(localDateTime);
}

String localDayKeyFromUtcAndOffset({
  required final DateTime occurredAtUtc,
  required final int tzOffsetMinutesAtEvent,
}) {
  if (!occurredAtUtc.isUtc) {
    throw ArgumentError.value(
      occurredAtUtc,
      'occurredAtUtc',
      'occurredAtUtc must be in UTC.',
    );
  }
  final DateTime localAtEvent = occurredAtUtc.add(
    Duration(minutes: tzOffsetMinutesAtEvent),
  );
  return _formatDayKey(localAtEvent);
}

bool isValidLocalDayKey(final String localDayKey) {
  return DomainConstraints.localDayKeyPattern.hasMatch(localDayKey);
}

String _formatDayKey(final DateTime dateTime) {
  final String year = dateTime.year.toString().padLeft(4, '0');
  final String month = dateTime.month.toString().padLeft(2, '0');
  final String day = dateTime.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
