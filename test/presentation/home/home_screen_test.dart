import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/core.dart';
import 'package:habit_tracker/domain/domain.dart';
import 'package:habit_tracker/presentation/home/home_screen.dart';

void main() {
  group('HomeScreen Stage 3 + Stage 4 flows', () {
    testWidgets('creates a habit from empty state', (
      final WidgetTester tester,
    ) async {
      final _FakeHabitRepository repository = _FakeHabitRepository();
      final _FakeHabitEventRepository eventRepository =
          _FakeHabitEventRepository();

      await _pumpHomeScreen(
        tester: tester,
        repository: repository,
        eventRepository: eventRepository,
      );

      expect(find.text('No habits yet'), findsOneWidget);

      await tester.tap(find.byKey(const Key('home_create_first_habit_button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('habit_form_name_field')),
        'Read Daily',
      );
      await tester.enterText(
        find.byKey(const Key('habit_form_note_field')),
        '20 minutes before bed',
      );

      await tester.tap(find.byKey(const Key('habit_form_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Read Daily'), findsOneWidget);
      expect(find.textContaining('Positive habit'), findsOneWidget);

      final List<Habit> activeHabits = await repository.listActiveHabits();
      expect(activeHabits.length, 1);
      expect(activeHabits.single.note, '20 minutes before bed');
    });

    testWidgets('shows inline validation errors in create form', (
      final WidgetTester tester,
    ) async {
      final _FakeHabitRepository repository = _FakeHabitRepository(
        seedHabits: <Habit>[
          Habit(
            id: 'habit-1',
            name: 'Read',
            iconKey: 'book',
            colorHex: '#1C7C54',
            mode: HabitMode.positive,
            createdAtUtc: DateTime.utc(2026, 2, 1, 8),
          ),
        ],
      );
      final _FakeHabitEventRepository eventRepository =
          _FakeHabitEventRepository();

      await _pumpHomeScreen(
        tester: tester,
        repository: repository,
        eventRepository: eventRepository,
      );

      await tester.tap(find.byKey(const Key('home_add_habit_fab')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('habit_form_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Name is required.'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('habit_form_name_field')),
        'read',
      );
      await tester.tap(find.byKey(const Key('habit_form_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Name already exists.'), findsOneWidget);

      final String longName = List<String>.filled(
        DomainConstraints.habitNameMaxLength + 1,
        'a',
      ).join();
      await tester.enterText(
        find.byKey(const Key('habit_form_name_field')),
        longName,
      );
      await tester.tap(find.byKey(const Key('habit_form_submit_button')));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Name must be 1-${DomainConstraints.habitNameMaxLength} characters.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('edits and archives an existing habit', (
      final WidgetTester tester,
    ) async {
      final _FakeHabitRepository repository = _FakeHabitRepository(
        seedHabits: <Habit>[
          Habit(
            id: 'habit-1',
            name: 'Read',
            iconKey: 'book',
            colorHex: '#1C7C54',
            mode: HabitMode.positive,
            note: 'Old note',
            createdAtUtc: DateTime.utc(2026, 2, 1, 8),
          ),
        ],
      );
      final _FakeHabitEventRepository eventRepository =
          _FakeHabitEventRepository();

      await _pumpHomeScreen(
        tester: tester,
        repository: repository,
        eventRepository: eventRepository,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('habit_card_menu_habit-1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Habit'));
      await tester.pumpAndSettle();

      final TextFormField nameField = tester.widget<TextFormField>(
        find.byKey(const Key('habit_form_name_field')),
      );
      final TextFormField noteField = tester.widget<TextFormField>(
        find.byKey(const Key('habit_form_note_field')),
      );
      expect(nameField.controller?.text, 'Read');
      expect(noteField.controller?.text, 'Old note');

      await tester.enterText(
        find.byKey(const Key('habit_form_name_field')),
        'Read Daily',
      );
      await tester.tap(find.byKey(const Key('habit_form_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Read Daily'), findsOneWidget);
      expect(find.textContaining('Positive habit'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('habit_card_menu_habit-1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive Habit'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('archive_confirm_button')));
      await tester.pumpAndSettle();

      expect(find.text('No habits yet'), findsOneWidget);

      final Habit? archivedHabit = await repository.findHabitById('habit-1');
      expect(archivedHabit, isNotNull);
      expect(archivedHabit?.archivedAtUtc, isNotNull);
    });

    testWidgets('positive quick action toggles done, undo, and re-done today', (
      final WidgetTester tester,
    ) async {
      final _FakeHabitRepository repository = _FakeHabitRepository(
        seedHabits: <Habit>[
          Habit(
            id: 'habit-1',
            name: 'Read',
            iconKey: 'book',
            colorHex: '#1C7C54',
            mode: HabitMode.positive,
            createdAtUtc: DateTime.utc(2026, 2, 1, 8),
          ),
        ],
      );
      final _FakeHabitEventRepository eventRepository =
          _FakeHabitEventRepository();
      final DateTime nowLocal = DateTime(2026, 2, 15, 9, 30);

      await _pumpHomeScreen(
        tester: tester,
        repository: repository,
        eventRepository: eventRepository,
        clock: () => nowLocal,
      );

      expect(find.textContaining('Not done today'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('habit_card_quick_action_habit-1')),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Done today'), findsOneWidget);
      List<HabitEvent> events = await eventRepository.listEventsForHabit(
        'habit-1',
      );
      expect(events.length, 1);
      expect(events.single.eventType, HabitEventType.complete);
      expect(events.single.localDayKey, '2026-02-15');
      expect(
        events.single.tzOffsetMinutesAtEvent,
        nowLocal.timeZoneOffset.inMinutes,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('habit_card_quick_action_habit-1')),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Not done today'), findsOneWidget);
      events = await eventRepository.listEventsForHabit('habit-1');
      expect(events, isEmpty);

      await tester.tap(
        find.byKey(const ValueKey<String>('habit_card_quick_action_habit-1')),
      );
      await tester.pumpAndSettle();

      events = await eventRepository.listEventsForHabit('habit-1');
      expect(events.length, 1);
      expect(events.single.eventType, HabitEventType.complete);
      expect(events.single.localDayKey, '2026-02-15');
    });

    testWidgets('negative quick action logs relapse now and allows backdate', (
      final WidgetTester tester,
    ) async {
      final _FakeHabitRepository repository = _FakeHabitRepository(
        seedHabits: <Habit>[
          Habit(
            id: 'habit-1',
            name: 'No Soda',
            iconKey: 'water',
            colorHex: '#8A2D3B',
            mode: HabitMode.negative,
            createdAtUtc: DateTime.utc(2026, 2, 1, 8),
          ),
        ],
      );
      final _FakeHabitEventRepository eventRepository =
          _FakeHabitEventRepository();
      final DateTime nowLocal = DateTime(2026, 2, 15, 14, 45);

      await _pumpHomeScreen(
        tester: tester,
        repository: repository,
        eventRepository: eventRepository,
        clock: () => nowLocal,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('habit_card_quick_action_habit-1')),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('habit_card_quick_action_habit-1')),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('habit_card_menu_habit-1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Backdate Relapse'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('backdate_relapse_date_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2026-02-12').last);
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('backdate_relapse_confirm_button')),
      );
      await tester.pumpAndSettle();

      final List<HabitEvent> events = await eventRepository.listEventsForHabit(
        'habit-1',
      );
      expect(events.length, 3);
      expect(
        events
            .where((final HabitEvent e) => e.localDayKey == '2026-02-15')
            .length,
        2,
      );
      expect(
        events.any((final HabitEvent e) => e.localDayKey == '2026-02-12'),
        isTrue,
      );
      expect(
        events.every(
          (final HabitEvent event) => event.eventType == HabitEventType.relapse,
        ),
        isTrue,
      );
    });
  });
}

Future<void> _pumpHomeScreen({
  required final WidgetTester tester,
  required final HabitRepository repository,
  required final HabitEventRepository eventRepository,
  DateTime Function()? clock,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: HomeScreen(
        habitRepository: repository,
        habitEventRepository: eventRepository,
        clock: clock ?? DateTime.now,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeHabitRepository implements HabitRepository {
  _FakeHabitRepository({final Iterable<Habit> seedHabits = const <Habit>[]}) {
    for (final Habit habit in seedHabits) {
      _habitsById[habit.id] = habit;
    }
  }

  final Map<String, Habit> _habitsById = <String, Habit>{};

  @override
  Future<void> saveHabit(final Habit habit) async {
    _habitsById[habit.id] = habit;
  }

  @override
  Future<Habit?> findHabitById(final String habitId) async {
    return _habitsById[habitId];
  }

  @override
  Future<List<Habit>> listHabits({final bool includeArchived = true}) async {
    final List<Habit> allHabits =
        _habitsById.values
            .where((final Habit habit) => includeArchived || !habit.isArchived)
            .toList(growable: false)
          ..sort(
            (final Habit a, final Habit b) =>
                a.createdAtUtc.compareTo(b.createdAtUtc),
          );
    return allHabits;
  }

  @override
  Future<List<Habit>> listActiveHabits() async {
    return listHabits(includeArchived: false);
  }

  @override
  Future<void> archiveHabit({
    required final String habitId,
    required final DateTime archivedAtUtc,
  }) async {
    final Habit? habit = _habitsById[habitId];
    if (habit == null) {
      return;
    }
    _habitsById[habitId] = habit.copyWith(archivedAtUtc: archivedAtUtc);
  }

  @override
  Future<void> unarchiveHabit(final String habitId) async {
    final Habit? habit = _habitsById[habitId];
    if (habit == null) {
      return;
    }
    _habitsById[habitId] = habit.copyWith(clearArchivedAtUtc: true);
  }
}

class _FakeHabitEventRepository implements HabitEventRepository {
  final Map<String, HabitEvent> _eventsById = <String, HabitEvent>{};

  @override
  Future<void> saveEvent(final HabitEvent event) async {
    if (event.eventType == HabitEventType.complete) {
      final bool duplicateCompletionExists = _eventsById.values.any(
        (final HabitEvent existingEvent) =>
            existingEvent.habitId == event.habitId &&
            existingEvent.localDayKey == event.localDayKey &&
            existingEvent.eventType == HabitEventType.complete,
      );
      if (duplicateCompletionExists) {
        throw DuplicateHabitCompletionException(
          habitId: event.habitId,
          localDayKey: event.localDayKey,
        );
      }
    }
    _eventsById[event.id] = event;
  }

  @override
  Future<HabitEvent?> findEventById(final String eventId) async {
    return _eventsById[eventId];
  }

  @override
  Future<List<HabitEvent>> listEventsForHabit(final String habitId) async {
    final List<HabitEvent> events =
        _eventsById.values
            .where((final HabitEvent event) => event.habitId == habitId)
            .toList(growable: false)
          ..sort(
            (final HabitEvent a, final HabitEvent b) =>
                a.occurredAtUtc.compareTo(b.occurredAtUtc),
          );
    return events;
  }

  @override
  Future<List<HabitEvent>> listEventsForHabitOnDay({
    required final String habitId,
    required final String localDayKey,
  }) async {
    final List<HabitEvent> events =
        _eventsById.values
            .where(
              (final HabitEvent event) =>
                  event.habitId == habitId && event.localDayKey == localDayKey,
            )
            .toList(growable: false)
          ..sort(
            (final HabitEvent a, final HabitEvent b) =>
                a.occurredAtUtc.compareTo(b.occurredAtUtc),
          );
    return events;
  }

  @override
  Future<void> deleteEventById(final String eventId) async {
    _eventsById.remove(eventId);
  }
}
