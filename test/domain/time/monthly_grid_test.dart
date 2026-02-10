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
}
