import 'package:habit_tracker/domain/entities/habit_event.dart';
import 'package:habit_tracker/domain/value_objects/habit_event_type.dart';
import 'package:habit_tracker/domain/value_objects/habit_mode.dart';

enum HabitMonthCellState {
  positiveDone,
  positiveMissed,
  positiveFuture,
  negativeRelapse,
  negativeClear,
  negativeFuture,
}

class HabitMonthCell {
  const HabitMonthCell({
    required this.dateLocal,
    required this.localDayKey,
    required this.isInMonth,
    required this.state,
  });

  final DateTime dateLocal;
  final String localDayKey;
  final bool isInMonth;
  final HabitMonthCellState state;
}

DateTime toMonthStart(final DateTime dateTime) {
  final DateTime localDateTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;
  return DateTime(localDateTime.year, localDateTime.month);
}

String formatMonthLabel(final DateTime monthLocal) {
  final DateTime monthStart = toMonthStart(monthLocal);
  return '${_monthNames[monthStart.month - 1]} ${monthStart.year}';
}

List<HabitMonthCell> buildHabitMonthCells({
  required final HabitMode mode,
  required final Iterable<HabitEvent> events,
  required final DateTime monthLocal,
  required final String referenceTodayLocalDayKey,
}) {
  final DateTime monthStart = toMonthStart(monthLocal);
  final DateTime todayDate = _parseLocalDayKey(referenceTodayLocalDayKey);
  final DateTime gridStart = _gridStartForMonth(monthStart);
  final Set<String> completeDayKeys = events
      .where(
        (final HabitEvent event) => event.eventType == HabitEventType.complete,
      )
      .map((final HabitEvent event) => event.localDayKey)
      .toSet();
  final Set<String> relapseDayKeys = events
      .where(
        (final HabitEvent event) => event.eventType == HabitEventType.relapse,
      )
      .map((final HabitEvent event) => event.localDayKey)
      .toSet();

  return List<HabitMonthCell>.generate(42, (final int index) {
    final DateTime date = DateTime(
      gridStart.year,
      gridStart.month,
      gridStart.day + index,
    );
    final String localDayKey = _formatLocalDayKey(date);
    final bool isFuture = date.isAfter(todayDate);
    final bool isInMonth =
        date.year == monthStart.year && date.month == monthStart.month;

    if (mode == HabitMode.positive) {
      if (isFuture) {
        return HabitMonthCell(
          dateLocal: date,
          localDayKey: localDayKey,
          isInMonth: isInMonth,
          state: HabitMonthCellState.positiveFuture,
        );
      }
      return HabitMonthCell(
        dateLocal: date,
        localDayKey: localDayKey,
        isInMonth: isInMonth,
        state: completeDayKeys.contains(localDayKey)
            ? HabitMonthCellState.positiveDone
            : HabitMonthCellState.positiveMissed,
      );
    }

    if (isFuture) {
      return HabitMonthCell(
        dateLocal: date,
        localDayKey: localDayKey,
        isInMonth: isInMonth,
        state: HabitMonthCellState.negativeFuture,
      );
    }

    return HabitMonthCell(
      dateLocal: date,
      localDayKey: localDayKey,
      isInMonth: isInMonth,
      state: relapseDayKeys.contains(localDayKey)
          ? HabitMonthCellState.negativeRelapse
          : HabitMonthCellState.negativeClear,
    );
  });
}

DateTime _gridStartForMonth(final DateTime monthStart) {
  final int leadingDays = (monthStart.weekday - DateTime.monday) % 7;
  return monthStart.subtract(Duration(days: leadingDays));
}

DateTime _parseLocalDayKey(final String localDayKey) {
  final List<String> parts = localDayKey.split('-');
  if (parts.length != 3) {
    throw ArgumentError.value(
      localDayKey,
      'referenceTodayLocalDayKey',
      'referenceTodayLocalDayKey must use YYYY-MM-DD format.',
    );
  }

  final int? year = int.tryParse(parts[0]);
  final int? month = int.tryParse(parts[1]);
  final int? day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) {
    throw ArgumentError.value(
      localDayKey,
      'referenceTodayLocalDayKey',
      'referenceTodayLocalDayKey must use YYYY-MM-DD format.',
    );
  }

  final DateTime parsed = DateTime(year, month, day);
  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    throw ArgumentError.value(
      localDayKey,
      'referenceTodayLocalDayKey',
      'referenceTodayLocalDayKey must represent a valid calendar date.',
    );
  }
  return parsed;
}

String _formatLocalDayKey(final DateTime dateTime) {
  final String year = dateTime.year.toString().padLeft(4, '0');
  final String month = dateTime.month.toString().padLeft(2, '0');
  final String day = dateTime.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

const List<String> _monthNames = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
