import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/domain.dart';

void main() {
  group('Habit', () {
    test('accepts UTC timestamps', () {
      final Habit habit = Habit(
        id: 'habit-1',
        name: 'Read',
        iconKey: 'book',
        colorHex: '#FFAA00',
        mode: HabitMode.positive,
        createdAtUtc: DateTime.utc(2026, 2, 9, 10),
      );

      expect(habit.createdAtUtc.isUtc, isTrue);
      expect(habit.isArchived, isFalse);
    });

    test('throws when createdAtUtc is not UTC', () {
      expect(
        () => Habit(
          id: 'habit-1',
          name: 'Read',
          iconKey: 'book',
          colorHex: '#FFAA00',
          mode: HabitMode.positive,
          createdAtUtc: DateTime(2026, 2, 9, 10),
        ),
        throwsArgumentError,
      );
    });

    test('throws when archivedAtUtc is not UTC', () {
      expect(
        () => Habit(
          id: 'habit-1',
          name: 'Read',
          iconKey: 'book',
          colorHex: '#FFAA00',
          mode: HabitMode.positive,
          createdAtUtc: DateTime.utc(2026, 2, 9, 10),
          archivedAtUtc: DateTime(2026, 2, 10, 7),
        ),
        throwsArgumentError,
      );
    });
  });

  group('HabitEvent', () {
    test('accepts valid UTC/local day key values', () {
      final HabitEvent event = HabitEvent(
        id: 'event-1',
        habitId: 'habit-1',
        eventType: HabitEventType.complete,
        occurredAtUtc: DateTime.utc(2026, 2, 9, 10),
        localDayKey: '2026-02-09',
        tzOffsetMinutesAtEvent: -300,
      );

      expect(event.occurredAtUtc.isUtc, isTrue);
      expect(event.localDayKey, '2026-02-09');
    });

    test('throws when occurredAtUtc is not UTC', () {
      expect(
        () => HabitEvent(
          id: 'event-1',
          habitId: 'habit-1',
          eventType: HabitEventType.complete,
          occurredAtUtc: DateTime(2026, 2, 9, 10),
          localDayKey: '2026-02-09',
          tzOffsetMinutesAtEvent: -300,
        ),
        throwsArgumentError,
      );
    });

    test('throws when localDayKey format is invalid', () {
      expect(
        () => HabitEvent(
          id: 'event-1',
          habitId: 'habit-1',
          eventType: HabitEventType.complete,
          occurredAtUtc: DateTime.utc(2026, 2, 9, 10),
          localDayKey: '2026/02/09',
          tzOffsetMinutesAtEvent: -300,
        ),
        throwsArgumentError,
      );
    });
  });
}
