import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/domain.dart';

void main() {
  group('buildHabitMonthCells week start alignment', () {
    test('uses Monday as the default week start', () {
      final List<HabitMonthCell> cells = buildHabitMonthCells(
        mode: HabitMode.positive,
        events: const <HabitEvent>[],
        monthLocal: DateTime(2026, 2, 1),
        referenceTodayLocalDayKey: '2026-02-15',
      );

      expect(cells.first.localDayKey, '2026-01-26');
      expect(cells.first.dateLocal.weekday, DateTime.monday);
    });

    test('supports Sunday week start for month grid alignment', () {
      final List<HabitMonthCell> cells = buildHabitMonthCells(
        mode: HabitMode.positive,
        events: const <HabitEvent>[],
        monthLocal: DateTime(2026, 2, 1),
        referenceTodayLocalDayKey: '2026-02-15',
        weekStart: AppWeekStart.sunday,
      );

      expect(cells.first.localDayKey, '2026-02-01');
      expect(cells.first.dateLocal.weekday, DateTime.sunday);
    });
  });

  group('buildHabitMonthCells Stage 8 regressions', () {
    test(
      'keeps historical completion on persisted localDayKey after timezone shift',
      () {
        final List<HabitMonthCell> cells = buildHabitMonthCells(
          mode: HabitMode.positive,
          events: <HabitEvent>[
            HabitEvent(
              id: 'event-1',
              habitId: 'habit-1',
              eventType: HabitEventType.complete,
              occurredAtUtc: DateTime.utc(2026, 3, 15, 2),
              localDayKey: '2026-03-14',
              tzOffsetMinutesAtEvent: -300,
            ),
          ],
          monthLocal: DateTime(2026, 3, 1),
          referenceTodayLocalDayKey: '2026-03-15',
        );

        expect(
          _cellForDay(cells, '2026-03-14').state,
          HabitMonthCellState.positiveDone,
        );
        expect(
          _cellForDay(cells, '2026-03-15').state,
          HabitMonthCellState.positiveMissed,
        );
      },
    );

    test('handles 12 months of realistic event volume within budget', () {
      final List<HabitEvent> events = _yearOfDailyCompletions(
        habitId: 'habit-1',
        startUtc: DateTime.utc(2025, 1, 1, 12),
      );
      final Stopwatch stopwatch = Stopwatch()..start();

      for (int iteration = 0; iteration < 24; iteration += 1) {
        for (int month = 1; month <= 12; month += 1) {
          final List<HabitMonthCell> positiveCells = buildHabitMonthCells(
            mode: HabitMode.positive,
            events: events,
            monthLocal: DateTime(2025, month, 1),
            referenceTodayLocalDayKey: '2025-12-31',
          );
          final List<HabitMonthCell> negativeCells = buildHabitMonthCells(
            mode: HabitMode.negative,
            events: events,
            monthLocal: DateTime(2025, month, 1),
            referenceTodayLocalDayKey: '2025-12-31',
          );
          expect(positiveCells.length, 42);
          expect(negativeCells.length, 42);
        }
      }

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(1200));
    });
  });
}

HabitMonthCell _cellForDay(
  final List<HabitMonthCell> cells,
  final String localDayKey,
) {
  return cells.singleWhere((final HabitMonthCell cell) {
    return cell.localDayKey == localDayKey;
  });
}

List<HabitEvent> _yearOfDailyCompletions({
  required final String habitId,
  required final DateTime startUtc,
}) {
  return List<HabitEvent>.generate(365, (final int index) {
    final DateTime occurredAtUtc = startUtc.add(Duration(days: index));
    return HabitEvent(
      id: 'event-$index',
      habitId: habitId,
      eventType: HabitEventType.complete,
      occurredAtUtc: occurredAtUtc,
      localDayKey: toLocalDayKey(occurredAtUtc),
      tzOffsetMinutesAtEvent: 0,
    );
  });
}
