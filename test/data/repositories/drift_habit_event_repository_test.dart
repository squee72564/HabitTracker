import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/data/data.dart';
import 'package:habit_tracker/domain/domain.dart';

void main() {
  late AppDatabase database;
  late DriftHabitRepository habitRepository;
  late DriftHabitEventRepository eventRepository;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    habitRepository = DriftHabitRepository(database);
    eventRepository = DriftHabitEventRepository(database);

    await habitRepository.saveHabit(
      Habit(
        id: 'habit-1',
        name: 'Read',
        iconKey: 'book',
        colorHex: '#FFAA00',
        mode: HabitMode.positive,
        createdAtUtc: DateTime.utc(2026, 2, 10, 1),
      ),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('saves and queries events by habit/day', () async {
    final HabitEvent eventA = _event(
      id: 'event-1',
      habitId: 'habit-1',
      eventType: HabitEventType.complete,
      occurredAtUtc: DateTime.utc(2026, 2, 10, 5),
      localDayKey: '2026-02-10',
    );
    final HabitEvent eventB = _event(
      id: 'event-2',
      habitId: 'habit-1',
      eventType: HabitEventType.relapse,
      occurredAtUtc: DateTime.utc(2026, 2, 11, 5),
      localDayKey: '2026-02-11',
    );

    await eventRepository.saveEvent(eventA);
    await eventRepository.saveEvent(eventB);

    final HabitEvent? loaded = await eventRepository.findEventById(eventA.id);
    expect(loaded, isNotNull);
    expect(loaded!.eventType, HabitEventType.complete);

    final List<HabitEvent> allForHabit = await eventRepository
        .listEventsForHabit('habit-1');
    expect(allForHabit.map((final e) => e.id).toList(), <String>[
      'event-1',
      'event-2',
    ]);

    final List<HabitEvent> sameDay = await eventRepository
        .listEventsForHabitOnDay(habitId: 'habit-1', localDayKey: '2026-02-10');
    expect(sameDay.length, 1);
    expect(sameDay.single.id, 'event-1');
  });

  test(
    'prevents duplicate completion for same habit and local day key',
    () async {
      final HabitEvent first = _event(
        id: 'event-1',
        habitId: 'habit-1',
        eventType: HabitEventType.complete,
        occurredAtUtc: DateTime.utc(2026, 2, 10, 5),
        localDayKey: '2026-02-10',
      );
      final HabitEvent duplicate = _event(
        id: 'event-2',
        habitId: 'habit-1',
        eventType: HabitEventType.complete,
        occurredAtUtc: DateTime.utc(2026, 2, 10, 7),
        localDayKey: '2026-02-10',
      );

      await eventRepository.saveEvent(first);
      await expectLater(
        () => eventRepository.saveEvent(duplicate),
        throwsA(isA<DuplicateHabitCompletionException>()),
      );

      final List<HabitEvent> dayEvents = await eventRepository
          .listEventsForHabitOnDay(
            habitId: 'habit-1',
            localDayKey: '2026-02-10',
          );
      expect(dayEvents.length, 1);
      expect(dayEvents.single.id, 'event-1');
    },
  );

  test(
    'allows multiple relapse events on same day and supports delete',
    () async {
      final HabitEvent relapseA = _event(
        id: 'event-1',
        habitId: 'habit-1',
        eventType: HabitEventType.relapse,
        occurredAtUtc: DateTime.utc(2026, 2, 10, 5),
        localDayKey: '2026-02-10',
      );
      final HabitEvent relapseB = _event(
        id: 'event-2',
        habitId: 'habit-1',
        eventType: HabitEventType.relapse,
        occurredAtUtc: DateTime.utc(2026, 2, 10, 7),
        localDayKey: '2026-02-10',
      );

      await eventRepository.saveEvent(relapseA);
      await eventRepository.saveEvent(relapseB);

      final List<HabitEvent> dayEventsBeforeDelete = await eventRepository
          .listEventsForHabitOnDay(
            habitId: 'habit-1',
            localDayKey: '2026-02-10',
          );
      expect(dayEventsBeforeDelete.length, 2);

      await eventRepository.deleteEventById('event-1');
      final List<HabitEvent> dayEventsAfterDelete = await eventRepository
          .listEventsForHabitOnDay(
            habitId: 'habit-1',
            localDayKey: '2026-02-10',
          );
      expect(dayEventsAfterDelete.length, 1);
      expect(dayEventsAfterDelete.single.id, 'event-2');
    },
  );
}

HabitEvent _event({
  required final String id,
  required final String habitId,
  required final HabitEventType eventType,
  required final DateTime occurredAtUtc,
  required final String localDayKey,
}) {
  return HabitEvent(
    id: id,
    habitId: habitId,
    eventType: eventType,
    occurredAtUtc: occurredAtUtc,
    localDayKey: localDayKey,
    tzOffsetMinutesAtEvent: -300,
    source: HabitEventSource.manual,
  );
}
