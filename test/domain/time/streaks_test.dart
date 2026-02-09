import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/domain.dart';

void main() {
  group('positive streak calculators', () {
    test(
      'calculates current streak from sorted unique completion day keys',
      () {
        final List<HabitEvent> events = <HabitEvent>[
          _event(
            id: 'event-1',
            eventType: HabitEventType.complete,
            localDayKey: '2026-02-07',
            occurredAtUtc: DateTime.utc(2026, 2, 7, 14),
          ),
          _event(
            id: 'event-2',
            eventType: HabitEventType.complete,
            localDayKey: '2026-02-09',
            occurredAtUtc: DateTime.utc(2026, 2, 9, 14),
          ),
          _event(
            id: 'event-3',
            eventType: HabitEventType.complete,
            localDayKey: '2026-02-08',
            occurredAtUtc: DateTime.utc(2026, 2, 8, 14),
          ),
          _event(
            id: 'event-4',
            eventType: HabitEventType.complete,
            localDayKey: '2026-02-08',
            occurredAtUtc: DateTime.utc(2026, 2, 8, 16),
          ),
        ];

        final int currentStreak = calculatePositiveCurrentStreak(
          events: events,
          referenceLocalDayKey: '2026-02-09',
        );

        expect(currentStreak, 3);
      },
    );

    test('calculates best streak across gaps and duplicate day keys', () {
      final List<HabitEvent> events = <HabitEvent>[
        _event(
          id: 'event-1',
          eventType: HabitEventType.complete,
          localDayKey: '2026-01-01',
          occurredAtUtc: DateTime.utc(2026, 1, 1, 14),
        ),
        _event(
          id: 'event-2',
          eventType: HabitEventType.complete,
          localDayKey: '2026-01-02',
          occurredAtUtc: DateTime.utc(2026, 1, 2, 14),
        ),
        _event(
          id: 'event-3',
          eventType: HabitEventType.complete,
          localDayKey: '2026-01-05',
          occurredAtUtc: DateTime.utc(2026, 1, 5, 14),
        ),
        _event(
          id: 'event-4',
          eventType: HabitEventType.complete,
          localDayKey: '2026-01-06',
          occurredAtUtc: DateTime.utc(2026, 1, 6, 14),
        ),
        _event(
          id: 'event-5',
          eventType: HabitEventType.complete,
          localDayKey: '2026-01-07',
          occurredAtUtc: DateTime.utc(2026, 1, 7, 14),
        ),
        _event(
          id: 'event-6',
          eventType: HabitEventType.complete,
          localDayKey: '2026-01-07',
          occurredAtUtc: DateTime.utc(2026, 1, 7, 16),
        ),
      ];

      final int bestStreak = calculatePositiveBestStreak(events: events);

      expect(bestStreak, 3);
    });

    test('keeps persisted local day keys stable across timezone changes', () {
      final DateTime occurredAtUtc = DateTime.utc(2026, 3, 15, 2);
      final String persistedLocalDayKey = localDayKeyFromUtcAndOffset(
        occurredAtUtc: occurredAtUtc,
        tzOffsetMinutesAtEvent: -300,
      );
      final HabitEvent event = _event(
        id: 'event-1',
        eventType: HabitEventType.complete,
        localDayKey: persistedLocalDayKey,
        occurredAtUtc: occurredAtUtc,
        tzOffsetMinutesAtEvent: -300,
      );

      expect(
        calculatePositiveCurrentStreak(
          events: <HabitEvent>[event],
          referenceLocalDayKey: persistedLocalDayKey,
        ),
        1,
      );
      expect(
        calculatePositiveCurrentStreak(
          events: <HabitEvent>[event],
          referenceLocalDayKey: '2026-03-15',
        ),
        0,
      );
    });

    test('handles midnight boundary transitions', () {
      final List<HabitEvent> events = <HabitEvent>[
        _event(
          id: 'event-1',
          eventType: HabitEventType.complete,
          localDayKey: '2026-05-10',
          occurredAtUtc: DateTime.utc(2026, 5, 11, 3, 59),
        ),
      ];

      expect(
        calculatePositiveCurrentStreak(
          events: events,
          referenceLocalDayKey: '2026-05-10',
        ),
        1,
      );
      expect(
        calculatePositiveCurrentStreak(
          events: events,
          referenceLocalDayKey: '2026-05-11',
        ),
        0,
      );
    });

    test('handles leap day and month boundary sequences', () {
      final List<HabitEvent> events = <HabitEvent>[
        _event(
          id: 'event-1',
          eventType: HabitEventType.complete,
          localDayKey: '2024-02-28',
          occurredAtUtc: DateTime.utc(2024, 2, 28, 12),
        ),
        _event(
          id: 'event-2',
          eventType: HabitEventType.complete,
          localDayKey: '2024-02-29',
          occurredAtUtc: DateTime.utc(2024, 2, 29, 12),
        ),
        _event(
          id: 'event-3',
          eventType: HabitEventType.complete,
          localDayKey: '2024-03-01',
          occurredAtUtc: DateTime.utc(2024, 3, 1, 12),
        ),
      ];

      expect(
        calculatePositiveCurrentStreak(
          events: events,
          referenceLocalDayKey: '2024-03-01',
        ),
        3,
      );
      expect(calculatePositiveBestStreak(events: events), 3);
    });
  });

  group('negative streak calculators', () {
    test('calculates elapsed duration from the latest relapse UTC instant', () {
      final List<HabitEvent> events = <HabitEvent>[
        _event(
          id: 'event-1',
          eventType: HabitEventType.relapse,
          localDayKey: '2026-02-10',
          occurredAtUtc: DateTime.utc(2026, 2, 10, 10),
        ),
        _event(
          id: 'event-2',
          eventType: HabitEventType.relapse,
          localDayKey: '2026-02-10',
          occurredAtUtc: DateTime.utc(2026, 2, 10, 12, 30),
        ),
      ];

      final Duration? currentStreak = calculateNegativeCurrentStreak(
        events: events,
        nowUtc: DateTime.utc(2026, 2, 10, 15),
      );

      expect(currentStreak, const Duration(hours: 2, minutes: 30));
    });

    test('returns null current streak when no relapse has been logged', () {
      final List<HabitEvent> events = <HabitEvent>[
        _event(
          id: 'event-1',
          eventType: HabitEventType.complete,
          localDayKey: '2026-02-10',
          occurredAtUtc: DateTime.utc(2026, 2, 10, 10),
        ),
      ];

      final Duration? currentStreak = calculateNegativeCurrentStreak(
        events: events,
        nowUtc: DateTime.utc(2026, 2, 10, 15),
      );

      expect(currentStreak, isNull);
    });

    test('computes Started X ago duration from createdAtUtc fallback', () {
      final Duration startedSince = calculateDurationSinceUtc(
        startedAtUtc: DateTime.utc(2026, 2, 1, 8),
        nowUtc: DateTime.utc(2026, 2, 5, 8),
      );

      expect(startedSince, const Duration(days: 4));
      expect(formatElapsedDurationShort(startedSince), '4d');
    });

    test('handles midnight boundary transitions', () {
      final List<HabitEvent> events = <HabitEvent>[
        _event(
          id: 'event-1',
          eventType: HabitEventType.relapse,
          localDayKey: '2026-04-10',
          occurredAtUtc: DateTime.utc(2026, 4, 10, 23, 59),
        ),
      ];

      final Duration? currentStreak = calculateNegativeCurrentStreak(
        events: events,
        nowUtc: DateTime.utc(2026, 4, 11, 0, 0),
      );

      expect(currentStreak, const Duration(minutes: 1));
    });

    test('handles leap day and month boundary elapsed durations', () {
      final List<HabitEvent> events = <HabitEvent>[
        _event(
          id: 'event-1',
          eventType: HabitEventType.relapse,
          localDayKey: '2024-02-29',
          occurredAtUtc: DateTime.utc(2024, 2, 29, 8),
        ),
      ];

      final Duration? currentStreak = calculateNegativeCurrentStreak(
        events: events,
        nowUtc: DateTime.utc(2024, 3, 1, 8),
      );

      expect(currentStreak, const Duration(days: 1));
      expect(formatElapsedDurationShort(currentStreak!), '1d');
    });
  });

  group('formatElapsedDurationShort', () {
    test('formats minute, hour, and day ranges', () {
      expect(formatElapsedDurationShort(Duration.zero), '0m');
      expect(formatElapsedDurationShort(const Duration(minutes: 59)), '59m');
      expect(
        formatElapsedDurationShort(const Duration(hours: 2, minutes: 5)),
        '2h 5m',
      );
      expect(
        formatElapsedDurationShort(const Duration(days: 3, hours: 4)),
        '3d 4h',
      );
    });
  });
}

HabitEvent _event({
  required final String id,
  required final HabitEventType eventType,
  required final String localDayKey,
  required final DateTime occurredAtUtc,
  final int tzOffsetMinutesAtEvent = 0,
}) {
  return HabitEvent(
    id: id,
    habitId: 'habit-1',
    eventType: eventType,
    occurredAtUtc: occurredAtUtc,
    localDayKey: localDayKey,
    tzOffsetMinutesAtEvent: tzOffsetMinutesAtEvent,
  );
}
