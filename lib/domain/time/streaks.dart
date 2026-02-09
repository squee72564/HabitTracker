import 'package:habit_tracker/domain/entities/habit_event.dart';
import 'package:habit_tracker/domain/value_objects/habit_event_type.dart';

int calculatePositiveCurrentStreak({
  required final Iterable<HabitEvent> events,
  required final String referenceLocalDayKey,
}) {
  final Set<DateTime> completionDates = _completionDates(events);
  if (completionDates.isEmpty) {
    return 0;
  }

  DateTime cursor = _parseLocalDayKey(referenceLocalDayKey);
  int streak = 0;
  while (completionDates.contains(cursor)) {
    streak += 1;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

int calculatePositiveBestStreak({required final Iterable<HabitEvent> events}) {
  final List<DateTime> sortedCompletionDates = _completionDates(events).toList(
    growable: false,
  )..sort((final DateTime a, final DateTime b) => a.compareTo(b));
  if (sortedCompletionDates.isEmpty) {
    return 0;
  }

  int bestStreak = 1;
  int currentStreak = 1;
  for (int index = 1; index < sortedCompletionDates.length; index += 1) {
    final int dayDelta = sortedCompletionDates[index]
        .difference(sortedCompletionDates[index - 1])
        .inDays;
    if (dayDelta == 1) {
      currentStreak += 1;
    } else {
      currentStreak = 1;
    }
    if (currentStreak > bestStreak) {
      bestStreak = currentStreak;
    }
  }
  return bestStreak;
}

Duration? calculateNegativeCurrentStreak({
  required final Iterable<HabitEvent> events,
  required final DateTime nowUtc,
}) {
  _assertUtc(nowUtc, fieldName: 'nowUtc');

  DateTime? latestRelapseUtc;
  for (final HabitEvent event in events) {
    if (event.eventType != HabitEventType.relapse) {
      continue;
    }
    final DateTime occurredAtUtc = event.occurredAtUtc;
    if (latestRelapseUtc == null || occurredAtUtc.isAfter(latestRelapseUtc)) {
      latestRelapseUtc = occurredAtUtc;
    }
  }
  if (latestRelapseUtc == null) {
    return null;
  }

  return _nonNegative(nowUtc.difference(latestRelapseUtc));
}

Duration calculateDurationSinceUtc({
  required final DateTime startedAtUtc,
  required final DateTime nowUtc,
}) {
  _assertUtc(startedAtUtc, fieldName: 'startedAtUtc');
  _assertUtc(nowUtc, fieldName: 'nowUtc');
  return _nonNegative(nowUtc.difference(startedAtUtc));
}

String formatElapsedDurationShort(final Duration duration) {
  final Duration safeDuration = _nonNegative(duration);
  final int days = safeDuration.inDays;
  final int hours = safeDuration.inHours % 24;
  final int minutes = safeDuration.inMinutes % 60;

  if (days > 0) {
    return hours > 0 ? '${days}d ${hours}h' : '${days}d';
  }
  if (hours > 0) {
    return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
  }
  return '${safeDuration.inMinutes}m';
}

Set<DateTime> _completionDates(final Iterable<HabitEvent> events) {
  return events
      .where(
        (final HabitEvent event) => event.eventType == HabitEventType.complete,
      )
      .map((final HabitEvent event) => _parseLocalDayKey(event.localDayKey))
      .toSet();
}

DateTime _parseLocalDayKey(final String localDayKey) {
  final List<String> parts = localDayKey.split('-');
  if (parts.length != 3) {
    throw ArgumentError.value(
      localDayKey,
      'localDayKey',
      'localDayKey must use YYYY-MM-DD format.',
    );
  }

  final int? year = int.tryParse(parts[0]);
  final int? month = int.tryParse(parts[1]);
  final int? day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) {
    throw ArgumentError.value(
      localDayKey,
      'localDayKey',
      'localDayKey must use YYYY-MM-DD format.',
    );
  }

  final DateTime parsed = DateTime.utc(year, month, day);
  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    throw ArgumentError.value(
      localDayKey,
      'localDayKey',
      'localDayKey must represent a valid calendar date.',
    );
  }
  return parsed;
}

DateTime _assertUtc(
  final DateTime dateTime, {
  required final String fieldName,
}) {
  if (!dateTime.isUtc) {
    throw ArgumentError.value(dateTime, fieldName, '$fieldName must be UTC.');
  }
  return dateTime;
}

Duration _nonNegative(final Duration duration) {
  return duration.isNegative ? Duration.zero : duration;
}
