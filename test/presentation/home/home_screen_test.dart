import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/core.dart';
import 'package:habit_tracker/domain/domain.dart';
import 'package:habit_tracker/presentation/home/home_screen.dart';

void main() {
  group('HomeScreen Stage 3 + Stage 4 + Stage 5 flows', () {
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
      expect(find.textContaining('Streak: 0 days'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('habit_card_quick_action_habit-1')),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Done today'), findsOneWidget);
      expect(find.textContaining('Streak: 1 day'), findsOneWidget);
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
      expect(find.textContaining('Streak: 0 days'), findsOneWidget);
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

    testWidgets('negative habit without relapse shows Started X ago fallback', (
      final WidgetTester tester,
    ) async {
      final _FakeHabitRepository repository = _FakeHabitRepository(
        seedHabits: <Habit>[
          Habit(
            id: 'habit-1',
            name: 'No Sugar',
            iconKey: 'food',
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

      expect(find.textContaining('Started '), findsOneWidget);
      expect(find.textContaining('ago'), findsOneWidget);
    });

    testWidgets(
      'negative quick action logs relapse, undoes latest relapse, and allows backdate',
      (final WidgetTester tester) async {
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

        expect(find.textContaining('Started '), findsOneWidget);
        expect(find.textContaining('ago'), findsOneWidget);

        await tester.tap(
          find.byKey(const ValueKey<String>('habit_card_quick_action_habit-1')),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('since relapse'), findsOneWidget);

        await tester.tap(
          find.byKey(const ValueKey<String>('habit_card_quick_action_habit-1')),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Started '), findsOneWidget);
        expect(find.textContaining('ago'), findsOneWidget);

        await tester.tap(
          find.byKey(const ValueKey<String>('habit_card_menu_habit-1')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Backdate Relapse'));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('backdate_relapse_date_dropdown')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('2026-02-12').last);
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('backdate_relapse_confirm_button')),
        );
        await tester.pumpAndSettle();

        final List<HabitEvent> events = await eventRepository
            .listEventsForHabit('habit-1');
        expect(events.length, 1);
        expect(
          events.any((final HabitEvent e) => e.localDayKey == '2026-02-12'),
          isTrue,
        );
        expect(
          events.every(
            (final HabitEvent event) =>
                event.eventType == HabitEventType.relapse,
          ),
          isTrue,
        );
      },
    );

    testWidgets('negative quick action undo removes latest relapse first', (
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
          _FakeHabitEventRepository(
            seedEvents: <HabitEvent>[
              HabitEvent(
                id: 'event-1',
                habitId: 'habit-1',
                eventType: HabitEventType.relapse,
                occurredAtUtc: DateTime.utc(2026, 2, 12, 9),
                localDayKey: '2026-02-12',
                tzOffsetMinutesAtEvent: 0,
              ),
              HabitEvent(
                id: 'event-2',
                habitId: 'habit-1',
                eventType: HabitEventType.relapse,
                occurredAtUtc: DateTime.utc(2026, 2, 15, 9),
                localDayKey: '2026-02-15',
                tzOffsetMinutesAtEvent: 0,
              ),
            ],
          );

      await _pumpHomeScreen(
        tester: tester,
        repository: repository,
        eventRepository: eventRepository,
        clock: () => DateTime(2026, 2, 15, 10),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('habit_card_quick_action_habit-1')),
      );
      await tester.pumpAndSettle();

      List<HabitEvent> events = await eventRepository.listEventsForHabit(
        'habit-1',
      );
      expect(events.length, 1);
      expect(events.single.id, 'event-1');
      expect(events.single.localDayKey, '2026-02-12');

      await tester.tap(
        find.byKey(const ValueKey<String>('habit_card_quick_action_habit-1')),
      );
      await tester.pumpAndSettle();

      events = await eventRepository.listEventsForHabit('habit-1');
      expect(events, isEmpty);
      expect(find.textContaining('Started '), findsOneWidget);
      expect(find.textContaining('ago'), findsOneWidget);
    });
  });

  group('HomeScreen Stage 6 dashboard + grid flows', () {
    testWidgets('positive grid maps done, missed, and future cells', (
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
          _FakeHabitEventRepository(
            seedEvents: <HabitEvent>[
              HabitEvent(
                id: 'event-1',
                habitId: 'habit-1',
                eventType: HabitEventType.complete,
                occurredAtUtc: DateTime.utc(2026, 2, 10, 12),
                localDayKey: '2026-02-10',
                tzOffsetMinutesAtEvent: 0,
              ),
              HabitEvent(
                id: 'event-2',
                habitId: 'habit-1',
                eventType: HabitEventType.complete,
                occurredAtUtc: DateTime.utc(2026, 2, 15, 12),
                localDayKey: '2026-02-15',
                tzOffsetMinutesAtEvent: 0,
              ),
            ],
          );

      await _pumpHomeScreen(
        tester: tester,
        repository: repository,
        eventRepository: eventRepository,
        clock: () => DateTime(2026, 2, 15, 9),
      );

      expect(find.text('February 2026'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey<String>(
            'habit_grid_cell_habit-1_2026-02-10_positiveDone',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>(
            'habit_grid_cell_habit-1_2026-02-14_positiveMissed',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>(
            'habit_grid_cell_habit-1_2026-02-20_positiveFuture',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('negative grid marks relapse days and future days', (
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
          _FakeHabitEventRepository(
            seedEvents: <HabitEvent>[
              HabitEvent(
                id: 'event-1',
                habitId: 'habit-1',
                eventType: HabitEventType.relapse,
                occurredAtUtc: DateTime.utc(2026, 2, 12, 12),
                localDayKey: '2026-02-12',
                tzOffsetMinutesAtEvent: 0,
              ),
            ],
          );

      await _pumpHomeScreen(
        tester: tester,
        repository: repository,
        eventRepository: eventRepository,
        clock: () => DateTime(2026, 2, 15, 9),
      );

      expect(
        find.byKey(
          const ValueKey<String>(
            'habit_grid_cell_habit-1_2026-02-12_negativeRelapse',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>(
            'habit_grid_cell_habit-1_2026-02-11_negativeClear',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>(
            'habit_grid_cell_habit-1_2026-02-20_negativeFuture',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'positive grid tap toggles completion and preserves persisted day invariants',
      (final WidgetTester tester) async {
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

        await tester.tap(
          find.byKey(
            const ValueKey<String>('habit_grid_cell_tap_habit-1_2026-02-14'),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(
            const ValueKey<String>(
              'habit_grid_cell_habit-1_2026-02-14_positiveDone',
            ),
          ),
          findsOneWidget,
        );
        List<HabitEvent> events = await eventRepository.listEventsForHabit(
          'habit-1',
        );
        expect(events.length, 1);
        expect(events.single.eventType, HabitEventType.complete);
        expect(events.single.localDayKey, '2026-02-14');
        expect(
          events.single.occurredAtUtc,
          DateTime(2026, 2, 14, 9, 30).toUtc(),
        );
        expect(
          events.single.tzOffsetMinutesAtEvent,
          nowLocal.timeZoneOffset.inMinutes,
        );

        await tester.tap(
          find.byKey(
            const ValueKey<String>('habit_grid_cell_tap_habit-1_2026-02-14'),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(
            const ValueKey<String>(
              'habit_grid_cell_habit-1_2026-02-14_positiveMissed',
            ),
          ),
          findsOneWidget,
        );
        events = await eventRepository.listEventsForHabit('habit-1');
        expect(events, isEmpty);
      },
    );

    testWidgets(
      'grid edit guardrails allow positive historical edits while blocking future and too-old negative days',
      (final WidgetTester tester) async {
        final _FakeHabitRepository repository = _FakeHabitRepository(
          seedHabits: <Habit>[
            Habit(
              id: 'habit-positive',
              name: 'Read',
              iconKey: 'book',
              colorHex: '#1C7C54',
              mode: HabitMode.positive,
              createdAtUtc: DateTime.utc(2026, 2, 10, 8),
            ),
            Habit(
              id: 'habit-negative',
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

        await _pumpHomeScreen(
          tester: tester,
          repository: repository,
          eventRepository: eventRepository,
          clock: () => DateTime(2026, 2, 15, 9, 30),
        );

        Finder tapTarget = find.byKey(
          const ValueKey<String>(
            'habit_grid_cell_tap_habit-positive_2026-02-05',
          ),
        );
        await tester.ensureVisible(tapTarget);
        await tester.tap(tapTarget);
        await tester.pumpAndSettle();
        List<HabitEvent> positiveEvents = await eventRepository
            .listEventsForHabit('habit-positive');
        expect(positiveEvents, hasLength(1));
        expect(positiveEvents.single.localDayKey, '2026-02-05');
        expect(positiveEvents.single.eventType, HabitEventType.complete);

        tapTarget = find.byKey(
          const ValueKey<String>(
            'habit_grid_cell_tap_habit-positive_2026-02-20',
          ),
        );
        await tester.ensureVisible(tapTarget);
        await tester.tap(tapTarget);
        await tester.pump();
        positiveEvents = await eventRepository.listEventsForHabit(
          'habit-positive',
        );
        expect(positiveEvents, hasLength(1));

        tapTarget = find.byKey(
          const ValueKey<String>(
            'habit_grid_cell_tap_habit-negative_2026-02-07',
          ),
        );
        await tester.ensureVisible(tapTarget);
        await tester.tap(tapTarget);
        await tester.pump();
        expect(
          await eventRepository.listEventsForHabit('habit-negative'),
          isEmpty,
        );

        tapTarget = find.byKey(
          const ValueKey<String>(
            'habit_grid_cell_tap_habit-negative_2026-02-15',
          ),
        );
        await tester.ensureVisible(tapTarget);
        await tester.tap(tapTarget);
        await tester.pumpAndSettle();
        expect(
          find.byKey(
            const ValueKey<String>(
              'habit_grid_cell_habit-negative_2026-02-15_negativeRelapse',
            ),
          ),
          findsOneWidget,
        );
        tapTarget = find.byKey(
          const ValueKey<String>(
            'habit_grid_cell_tap_habit-negative_2026-02-15',
          ),
        );
        await tester.ensureVisible(tapTarget);
        await tester.tap(tapTarget);
        await tester.pumpAndSettle();
        expect(
          find.byKey(
            const ValueKey<String>(
              'habit_grid_cell_habit-negative_2026-02-15_negativeClear',
            ),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('month navigation updates label and current-month controls', (
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
        clock: () => DateTime(2026, 2, 15, 9),
      );

      expect(find.text('February 2026'), findsOneWidget);
      expect(find.byKey(const Key('home_month_current_chip')), findsOneWidget);

      await tester.tap(find.byKey(const Key('home_month_prev_button')));
      await tester.pumpAndSettle();

      expect(find.text('January 2026'), findsOneWidget);
      expect(find.byKey(const Key('home_month_current_chip')), findsNothing);
      expect(
        find.byKey(const Key('home_month_jump_current_button')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('home_month_jump_current_button')));
      await tester.pumpAndSettle();

      expect(find.text('February 2026'), findsOneWidget);
      expect(find.byKey(const Key('home_month_current_chip')), findsOneWidget);
    });

    testWidgets('small screens render cards and grids without overflow', (
      final WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final _FakeHabitRepository repository = _FakeHabitRepository(
        seedHabits: <Habit>[
          Habit(
            id: 'habit-1',
            name:
                'Very Long Habit Name That Should Truncate Cleanly On Small Screens',
            iconKey: 'book',
            colorHex: '#1C7C54',
            mode: HabitMode.positive,
            note:
                'Long note text that also needs truncation in compact layouts.',
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
        clock: () => DateTime(2026, 2, 15, 9),
      );

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(
          const ValueKey<String>(
            'habit_grid_cell_habit-1_2026-02-15_positiveMissed',
          ),
        ),
        findsOneWidget,
      );
    });
  });

  group('HomeScreen Stage 7 settings + reminders flows', () {
    testWidgets('time format toggle updates reminder labels', (
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
      final _FakeHabitReminderRepository reminderRepository =
          _FakeHabitReminderRepository(
            seedReminders: <HabitReminder>[
              HabitReminder(
                habitId: 'habit-1',
                isEnabled: true,
                reminderTimeMinutes: 13 * 60 + 5,
              ),
            ],
          );

      await _pumpHomeScreen(
        tester: tester,
        repository: repository,
        eventRepository: _FakeHabitEventRepository(),
        habitReminderRepository: reminderRepository,
      );

      await tester.tap(find.byKey(const Key('home_open_settings_button')));
      await tester.pumpAndSettle();

      expect(find.text('Daily at 1:05 PM'), findsOneWidget);
      await tester.tap(find.byKey(const Key('settings_time_format_switch')));
      await tester.pumpAndSettle();
      expect(find.text('Daily at 13:05'), findsOneWidget);
    });

    testWidgets('global reminder toggle pauses and resumes scheduling', (
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
      final _FakeAppSettingsRepository appSettingsRepository =
          _FakeAppSettingsRepository();
      final _FakeHabitReminderRepository reminderRepository =
          _FakeHabitReminderRepository(
            seedReminders: <HabitReminder>[
              HabitReminder(
                habitId: 'habit-1',
                isEnabled: true,
                reminderTimeMinutes: 13 * 60 + 5,
              ),
            ],
          );
      final _FakeReminderNotificationScheduler notificationScheduler =
          _FakeReminderNotificationScheduler();

      await _pumpHomeScreen(
        tester: tester,
        repository: repository,
        eventRepository: _FakeHabitEventRepository(),
        appSettingsRepository: appSettingsRepository,
        habitReminderRepository: reminderRepository,
        notificationScheduler: notificationScheduler,
      );

      await tester.tap(find.byKey(const Key('home_open_settings_button')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('settings_global_reminders_switch')),
      );
      await tester.pumpAndSettle();

      final AppSettings settingsWithGlobalOff = await appSettingsRepository
          .loadSettings();
      expect(settingsWithGlobalOff.remindersEnabled, isFalse);
      expect(
        notificationScheduler.cancelledHabitIds.contains('habit-1'),
        isTrue,
      );
      expect(
        find.text('Saved for 1:05 PM (global reminders off)'),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('settings_global_reminders_switch')),
      );
      await tester.pumpAndSettle();

      final AppSettings settingsWithGlobalOn = await appSettingsRepository
          .loadSettings();
      expect(settingsWithGlobalOn.remindersEnabled, isTrue);
      expect(
        notificationScheduler.scheduledMinutesByHabitId['habit-1'],
        13 * 60 + 5,
      );
      expect(find.text('Daily at 1:05 PM'), findsOneWidget);
    });

    testWidgets('enabling reminder requests permission and schedules', (
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
      final _FakeReminderNotificationScheduler notificationScheduler =
          _FakeReminderNotificationScheduler()
            ..notificationsAllowed = false
            ..grantPermissionOnRequest = true;

      await _pumpHomeScreen(
        tester: tester,
        repository: repository,
        eventRepository: _FakeHabitEventRepository(),
        notificationScheduler: notificationScheduler,
      );

      await tester.tap(find.byKey(const Key('home_open_settings_button')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('settings_reminder_toggle_habit-1')),
      );
      await tester.pumpAndSettle();

      expect(notificationScheduler.permissionRequestCount, 1);
      expect(notificationScheduler.scheduledMinutesByHabitId['habit-1'], 1200);
      expect(find.text('Daily at 8:00 PM'), findsOneWidget);
    });

    testWidgets(
      'enabling per-habit reminder while global reminders are off does not request permission',
      (final WidgetTester tester) async {
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
        final _FakeAppSettingsRepository appSettingsRepository =
            _FakeAppSettingsRepository(
              seedSettings: const AppSettings(remindersEnabled: false),
            );
        final _FakeHabitReminderRepository reminderRepository =
            _FakeHabitReminderRepository();
        final _FakeReminderNotificationScheduler notificationScheduler =
            _FakeReminderNotificationScheduler()
              ..notificationsAllowed = false
              ..grantPermissionOnRequest = false;

        await _pumpHomeScreen(
          tester: tester,
          repository: repository,
          eventRepository: _FakeHabitEventRepository(),
          appSettingsRepository: appSettingsRepository,
          habitReminderRepository: reminderRepository,
          notificationScheduler: notificationScheduler,
        );

        await tester.tap(find.byKey(const Key('home_open_settings_button')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(
            const ValueKey<String>('settings_reminder_toggle_habit-1'),
          ),
        );
        await tester.pumpAndSettle();

        final HabitReminder? reminder = await reminderRepository
            .findReminderByHabitId('habit-1');
        expect(reminder, isNotNull);
        expect(reminder?.isEnabled, isTrue);
        expect(notificationScheduler.permissionRequestCount, 0);
        expect(notificationScheduler.scheduledMinutesByHabitId, isEmpty);
      },
    );

    testWidgets('permission denial shows fallback and keeps reminder off', (
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
      final _FakeReminderNotificationScheduler notificationScheduler =
          _FakeReminderNotificationScheduler()
            ..notificationsAllowed = false
            ..grantPermissionOnRequest = false;

      await _pumpHomeScreen(
        tester: tester,
        repository: repository,
        eventRepository: _FakeHabitEventRepository(),
        notificationScheduler: notificationScheduler,
      );

      await tester.tap(find.byKey(const Key('home_open_settings_button')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('settings_reminder_toggle_habit-1')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('settings_permission_fallback_dialog')),
        findsOneWidget,
      );
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(notificationScheduler.scheduledMinutesByHabitId, isEmpty);
      expect(find.text('Reminder off'), findsOneWidget);
    });

    testWidgets('create form can enable and persist reminder', (
      final WidgetTester tester,
    ) async {
      final _FakeHabitRepository repository = _FakeHabitRepository();
      final _FakeHabitReminderRepository reminderRepository =
          _FakeHabitReminderRepository();
      final _FakeReminderNotificationScheduler notificationScheduler =
          _FakeReminderNotificationScheduler()
            ..notificationsAllowed = false
            ..grantPermissionOnRequest = true;

      await _pumpHomeScreen(
        tester: tester,
        repository: repository,
        eventRepository: _FakeHabitEventRepository(),
        habitReminderRepository: reminderRepository,
        notificationScheduler: notificationScheduler,
      );

      await tester.tap(find.byKey(const Key('home_create_first_habit_button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('habit_form_name_field')),
        'Read Daily',
      );
      final Finder reminderToggleFinder = find.byKey(
        const Key('habit_form_reminder_toggle'),
      );
      await tester.ensureVisible(reminderToggleFinder);
      await tester.tap(reminderToggleFinder);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('habit_form_submit_button')));
      await tester.pumpAndSettle();

      final Habit createdHabit = (await repository.listActiveHabits()).single;
      final HabitReminder? reminder = await reminderRepository
          .findReminderByHabitId(createdHabit.id);
      expect(notificationScheduler.permissionRequestCount, 1);
      expect(reminder, isNotNull);
      expect(reminder?.isEnabled, isTrue);
      expect(reminder?.reminderTimeMinutes, 1200);
      expect(
        notificationScheduler.scheduledMinutesByHabitId[createdHabit.id],
        1200,
      );
    });

    testWidgets(
      'create form can save enabled reminder while global reminders are off',
      (final WidgetTester tester) async {
        final _FakeHabitRepository repository = _FakeHabitRepository();
        final _FakeAppSettingsRepository appSettingsRepository =
            _FakeAppSettingsRepository(
              seedSettings: const AppSettings(remindersEnabled: false),
            );
        final _FakeHabitReminderRepository reminderRepository =
            _FakeHabitReminderRepository();
        final _FakeReminderNotificationScheduler notificationScheduler =
            _FakeReminderNotificationScheduler()
              ..notificationsAllowed = false
              ..grantPermissionOnRequest = false;

        await _pumpHomeScreen(
          tester: tester,
          repository: repository,
          eventRepository: _FakeHabitEventRepository(),
          appSettingsRepository: appSettingsRepository,
          habitReminderRepository: reminderRepository,
          notificationScheduler: notificationScheduler,
        );

        await tester.tap(
          find.byKey(const Key('home_create_first_habit_button')),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('habit_form_name_field')),
          'Read Daily',
        );
        final Finder reminderToggleFinder = find.byKey(
          const Key('habit_form_reminder_toggle'),
        );
        await tester.ensureVisible(reminderToggleFinder);
        await tester.tap(reminderToggleFinder);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('habit_form_submit_button')));
        await tester.pumpAndSettle();

        final Habit createdHabit = (await repository.listActiveHabits()).single;
        final HabitReminder? reminder = await reminderRepository
            .findReminderByHabitId(createdHabit.id);
        expect(reminder, isNotNull);
        expect(reminder?.isEnabled, isTrue);
        expect(reminder?.reminderTimeMinutes, 1200);
        expect(notificationScheduler.permissionRequestCount, 0);
        expect(
          notificationScheduler.scheduledMinutesByHabitId[createdHabit.id],
          isNull,
        );
      },
    );

    testWidgets('edit form preserves existing reminder row when turned off', (
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
      final _FakeHabitReminderRepository reminderRepository =
          _FakeHabitReminderRepository(
            seedReminders: <HabitReminder>[
              HabitReminder(
                habitId: 'habit-1',
                isEnabled: true,
                reminderTimeMinutes: 13 * 60 + 5,
              ),
            ],
          );
      final _FakeReminderNotificationScheduler notificationScheduler =
          _FakeReminderNotificationScheduler();

      await _pumpHomeScreen(
        tester: tester,
        repository: repository,
        eventRepository: _FakeHabitEventRepository(),
        habitReminderRepository: reminderRepository,
        notificationScheduler: notificationScheduler,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('habit_card_menu_habit-1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Habit'));
      await tester.pumpAndSettle();

      final SwitchListTile reminderToggle = tester.widget<SwitchListTile>(
        find.byKey(const Key('habit_form_reminder_toggle')),
      );
      expect(reminderToggle.value, isTrue);
      expect(find.text('Daily at 1:05 PM'), findsOneWidget);

      final Finder reminderToggleFinder = find.byKey(
        const Key('habit_form_reminder_toggle'),
      );
      await tester.ensureVisible(reminderToggleFinder);
      await tester.tap(reminderToggleFinder);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('habit_form_submit_button')));
      await tester.pumpAndSettle();

      final HabitReminder? reminder = await reminderRepository
          .findReminderByHabitId('habit-1');
      expect(reminder, isNotNull);
      expect(reminder?.isEnabled, isFalse);
      expect(reminder?.reminderTimeMinutes, 13 * 60 + 5);
      expect(
        notificationScheduler.cancelledHabitIds.contains('habit-1'),
        isTrue,
      );
    });

    testWidgets(
      'edit form without stored reminder keeps row absent when unchanged off',
      (final WidgetTester tester) async {
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
        final _FakeHabitReminderRepository reminderRepository =
            _FakeHabitReminderRepository();

        await _pumpHomeScreen(
          tester: tester,
          repository: repository,
          eventRepository: _FakeHabitEventRepository(),
          habitReminderRepository: reminderRepository,
        );

        await tester.tap(
          find.byKey(const ValueKey<String>('habit_card_menu_habit-1')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Edit Habit'));
        await tester.pumpAndSettle();

        final SwitchListTile reminderToggle = tester.widget<SwitchListTile>(
          find.byKey(const Key('habit_form_reminder_toggle')),
        );
        expect(reminderToggle.value, isFalse);
        expect(find.text('Reminder off'), findsOneWidget);

        await tester.tap(find.byKey(const Key('habit_form_submit_button')));
        await tester.pumpAndSettle();

        final HabitReminder? reminder = await reminderRepository
            .findReminderByHabitId('habit-1');
        expect(reminder, isNull);
      },
    );

    testWidgets('reset all data requires typed confirmation and wipes data', (
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
          _FakeHabitEventRepository(
            seedEvents: <HabitEvent>[
              HabitEvent(
                id: 'event-1',
                habitId: 'habit-1',
                eventType: HabitEventType.complete,
                occurredAtUtc: DateTime.utc(2026, 2, 1, 9),
                localDayKey: '2026-02-01',
                tzOffsetMinutesAtEvent: 0,
              ),
            ],
          );
      final _FakeAppSettingsRepository appSettingsRepository =
          _FakeAppSettingsRepository(
            seedSettings: const AppSettings(
              weekStart: AppWeekStart.sunday,
              remindersEnabled: false,
            ),
          );
      final _FakeHabitReminderRepository reminderRepository =
          _FakeHabitReminderRepository(
            seedReminders: <HabitReminder>[
              HabitReminder(
                habitId: 'habit-1',
                isEnabled: true,
                reminderTimeMinutes: 21 * 60,
              ),
            ],
          );
      final _FakeReminderNotificationScheduler notificationScheduler =
          _FakeReminderNotificationScheduler();

      await _pumpHomeScreen(
        tester: tester,
        repository: repository,
        eventRepository: eventRepository,
        appSettingsRepository: appSettingsRepository,
        habitReminderRepository: reminderRepository,
        notificationScheduler: notificationScheduler,
      );

      await tester.tap(find.byKey(const Key('home_open_settings_button')));
      await tester.pumpAndSettle();
      final Finder resetAllDataButton = find.byKey(
        const Key('settings_reset_all_data_button'),
      );
      await tester.scrollUntilVisible(resetAllDataButton, 200);
      await tester.tap(resetAllDataButton);
      await tester.pumpAndSettle();

      FilledButton confirmButton = tester.widget<FilledButton>(
        find.byKey(const Key('reset_data_confirm_button')),
      );
      expect(confirmButton.onPressed, isNull);

      await tester.enterText(
        find.byKey(const Key('reset_data_confirmation_field')),
        'WRONG',
      );
      await tester.pumpAndSettle();
      confirmButton = tester.widget<FilledButton>(
        find.byKey(const Key('reset_data_confirm_button')),
      );
      expect(confirmButton.onPressed, isNull);

      await tester.enterText(
        find.byKey(const Key('reset_data_confirmation_field')),
        'RESET',
      );
      await tester.pumpAndSettle();
      confirmButton = tester.widget<FilledButton>(
        find.byKey(const Key('reset_data_confirm_button')),
      );
      expect(confirmButton.onPressed, isNotNull);

      await tester.tap(find.byKey(const Key('reset_data_confirm_button')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('reset_data_success_dialog')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('reset_data_success_ok_button')));
      await tester.pumpAndSettle();

      expect(find.text('No habits yet'), findsOneWidget);
      expect(find.text('All data reset.'), findsOneWidget);
      expect(await repository.listActiveHabits(), isEmpty);
      expect(await eventRepository.listEventsForHabit('habit-1'), isEmpty);
      expect(await reminderRepository.findReminderByHabitId('habit-1'), isNull);
      expect(await appSettingsRepository.loadSettings(), AppSettings.defaults);
      expect(
        notificationScheduler.cancelledHabitIds.contains('habit-1'),
        isTrue,
      );
    });

    testWidgets('archived management can unarchive a habit', (
      final WidgetTester tester,
    ) async {
      final _FakeHabitRepository repository = _FakeHabitRepository(
        seedHabits: <Habit>[
          Habit(
            id: 'habit-archived',
            name: 'Journal',
            iconKey: 'book',
            colorHex: '#1C7C54',
            mode: HabitMode.positive,
            createdAtUtc: DateTime.utc(2026, 2, 1, 8),
            archivedAtUtc: DateTime.utc(2026, 2, 2, 8),
          ),
        ],
      );
      final _FakeAppSettingsRepository appSettingsRepository =
          _FakeAppSettingsRepository();
      final _FakeHabitReminderRepository reminderRepository =
          _FakeHabitReminderRepository(
            seedReminders: <HabitReminder>[
              HabitReminder(
                habitId: 'habit-archived',
                isEnabled: true,
                reminderTimeMinutes: 7 * 60 + 30,
              ),
            ],
          );
      final _FakeReminderNotificationScheduler notificationScheduler =
          _FakeReminderNotificationScheduler();

      await _pumpHomeScreen(
        tester: tester,
        repository: repository,
        eventRepository: _FakeHabitEventRepository(),
        appSettingsRepository: appSettingsRepository,
        habitReminderRepository: reminderRepository,
        notificationScheduler: notificationScheduler,
      );

      await tester.tap(find.byKey(const Key('home_open_settings_button')));
      await tester.pumpAndSettle();
      final Finder openArchivedButton = find.byKey(
        const Key('settings_open_archived_button'),
      );
      await tester.dragUntilVisible(
        openArchivedButton,
        find.byType(ListView).first,
        const Offset(0, -200),
      );
      final Offset openArchivedTapTarget =
          tester.getTopLeft(openArchivedButton) + const Offset(16, 16);
      await tester.tapAt(openArchivedTapTarget);
      await tester.pumpAndSettle();

      expect(find.text('Journal'), findsOneWidget);
      await tester.tap(
        find.byKey(
          const ValueKey<String>('archived_unarchive_button_habit-archived'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('archived_habits_empty_state')),
        findsOneWidget,
      );
      final Habit? unarchivedHabit = await repository.findHabitById(
        'habit-archived',
      );
      expect(unarchivedHabit, isNotNull);
      expect(unarchivedHabit!.archivedAtUtc, isNull);
      expect(
        notificationScheduler.scheduledMinutesByHabitId['habit-archived'],
        7 * 60 + 30,
      );

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Journal'), findsOneWidget);
    });

    testWidgets(
      'archived management permanent delete requires typed habit name',
      (final WidgetTester tester) async {
        final _FakeHabitRepository repository = _FakeHabitRepository(
          seedHabits: <Habit>[
            Habit(
              id: 'habit-archived',
              name: 'Journal',
              iconKey: 'book',
              colorHex: '#1C7C54',
              mode: HabitMode.positive,
              createdAtUtc: DateTime.utc(2026, 2, 1, 8),
              archivedAtUtc: DateTime.utc(2026, 2, 2, 8),
            ),
          ],
        );
        final _FakeHabitEventRepository eventRepository =
            _FakeHabitEventRepository(
              seedEvents: <HabitEvent>[
                HabitEvent(
                  id: 'event-1',
                  habitId: 'habit-archived',
                  eventType: HabitEventType.complete,
                  occurredAtUtc: DateTime.utc(2026, 2, 1, 9),
                  localDayKey: '2026-02-01',
                  tzOffsetMinutesAtEvent: 0,
                ),
              ],
            );
        final _FakeHabitReminderRepository reminderRepository =
            _FakeHabitReminderRepository(
              seedReminders: <HabitReminder>[
                HabitReminder(
                  habitId: 'habit-archived',
                  isEnabled: true,
                  reminderTimeMinutes: 18 * 60,
                ),
              ],
            );
        final _FakeReminderNotificationScheduler notificationScheduler =
            _FakeReminderNotificationScheduler();

        await _pumpHomeScreen(
          tester: tester,
          repository: repository,
          eventRepository: eventRepository,
          habitReminderRepository: reminderRepository,
          notificationScheduler: notificationScheduler,
        );

        await tester.tap(find.byKey(const Key('home_open_settings_button')));
        await tester.pumpAndSettle();
        final Finder openArchivedButton = find.byKey(
          const Key('settings_open_archived_button'),
        );
        await tester.dragUntilVisible(
          openArchivedButton,
          find.byType(ListView).first,
          const Offset(0, -200),
        );
        final Offset openArchivedTapTarget =
            tester.getTopLeft(openArchivedButton) + const Offset(16, 16);
        await tester.tapAt(openArchivedTapTarget);
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(
            const ValueKey<String>('archived_delete_button_habit-archived'),
          ),
        );
        await tester.pumpAndSettle();

        FilledButton deleteButton = tester.widget<FilledButton>(
          find.byKey(
            const ValueKey<String>(
              'archived_delete_confirm_button_habit-archived',
            ),
          ),
        );
        expect(deleteButton.onPressed, isNull);

        await tester.enterText(
          find.byKey(
            const ValueKey<String>(
              'archived_delete_confirmation_field_habit-archived',
            ),
          ),
          'journal',
        );
        await tester.pumpAndSettle();
        deleteButton = tester.widget<FilledButton>(
          find.byKey(
            const ValueKey<String>(
              'archived_delete_confirm_button_habit-archived',
            ),
          ),
        );
        expect(deleteButton.onPressed, isNull);

        await tester.enterText(
          find.byKey(
            const ValueKey<String>(
              'archived_delete_confirmation_field_habit-archived',
            ),
          ),
          'Journal',
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(
            const ValueKey<String>(
              'archived_delete_confirm_button_habit-archived',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Journal'), findsNothing);
        expect(await repository.findHabitById('habit-archived'), isNull);
        expect(
          await eventRepository.listEventsForHabit('habit-archived'),
          isEmpty,
        );
        expect(
          await reminderRepository.findReminderByHabitId('habit-archived'),
          isNull,
        );
        expect(
          notificationScheduler.cancelledHabitIds.contains('habit-archived'),
          isTrue,
        );
      },
    );
  });

  group('HomeScreen Stage 8 QA + accessibility flows', () {
    testWidgets('integration flow creates habit and updates streak + grid', (
      final WidgetTester tester,
    ) async {
      final _FakeHabitRepository repository = _FakeHabitRepository();
      final _FakeHabitEventRepository eventRepository =
          _FakeHabitEventRepository();
      final DateTime nowLocal = DateTime(2026, 2, 15, 9, 0);

      await _pumpHomeScreen(
        tester: tester,
        repository: repository,
        eventRepository: eventRepository,
        clock: () => nowLocal,
      );

      await tester.tap(find.byKey(const Key('home_create_first_habit_button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('habit_form_name_field')),
        'Meditate',
      );
      await tester.tap(find.byKey(const Key('habit_form_submit_button')));
      await tester.pumpAndSettle();

      final Habit createdHabit = (await repository.listActiveHabits()).single;
      expect(
        find.byKey(
          ValueKey<String>(
            'habit_grid_cell_${createdHabit.id}_2026-02-15_positiveMissed',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('Streak: 0 days'), findsOneWidget);
      expect(find.text('Not done today'), findsOneWidget);

      await tester.tap(
        find.byKey(
          ValueKey<String>('habit_card_quick_action_${createdHabit.id}'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          ValueKey<String>(
            'habit_grid_cell_${createdHabit.id}_2026-02-15_positiveDone',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('Streak: 1 day'), findsOneWidget);
      expect(find.text('Done today'), findsOneWidget);
      final List<HabitEvent> events = await eventRepository.listEventsForHabit(
        createdHabit.id,
      );
      expect(events.length, 1);
      expect(events.single.localDayKey, '2026-02-15');
    });

    testWidgets(
      'habit form icon picker uses icon-only paged grid and saves selected icon from another page',
      (final WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final _FakeHabitRepository repository = _FakeHabitRepository();

        await _pumpHomeScreen(
          tester: tester,
          repository: repository,
          eventRepository: _FakeHabitEventRepository(),
        );

        await tester.tap(
          find.byKey(const Key('home_create_first_habit_button')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('habit_form_icon_book')),
          findsOneWidget,
        );
        expect(find.text('Read'), findsNothing);
        expect(find.byTooltip('Read'), findsOneWidget);

        final Finder nextPageFinder = find.byKey(
          const Key('habit_form_icon_page_next'),
        );
        for (int i = 0; i < 5; i += 1) {
          if (find
              .byKey(const ValueKey<String>('habit_form_icon_sun'))
              .evaluate()
              .isNotEmpty) {
            break;
          }
          final IconButton nextPageButton = tester.widget<IconButton>(
            nextPageFinder,
          );
          if (nextPageButton.onPressed == null) {
            break;
          }
          await tester.ensureVisible(nextPageFinder);
          await tester.tap(nextPageFinder);
          await tester.pumpAndSettle();
        }
        expect(
          find.byKey(const ValueKey<String>('habit_form_icon_sun')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const ValueKey<String>('habit_form_icon_sun')),
        );
        await tester.enterText(
          find.byKey(const Key('habit_form_name_field')),
          'Morning Light',
        );
        await tester.tap(find.byKey(const Key('habit_form_submit_button')));
        await tester.pumpAndSettle();

        final List<Habit> habits = await repository.listActiveHabits();
        final Habit createdHabit = habits.firstWhere(
          (final Habit habit) => habit.name == 'Morning Light',
        );
        expect(createdHabit.iconKey, 'sun');
      },
    );

    testWidgets(
      'habit form icon picker remains stable on small screens with large text',
      (final WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 780);
        tester.view.devicePixelRatio = 1;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final _FakeHabitRepository repository = _FakeHabitRepository(
          seedHabits: <Habit>[
            Habit(
              id: 'habit-1',
              name: 'Existing Habit',
              iconKey: 'book',
              colorHex: '#1C7C54',
              mode: HabitMode.positive,
              createdAtUtc: DateTime.utc(2026, 2, 1, 8),
            ),
          ],
        );

        await _pumpHomeScreen(
          tester: tester,
          repository: repository,
          eventRepository: _FakeHabitEventRepository(),
          textScaleFactor: 1.8,
        );

        await tester.tap(find.byKey(const Key('home_add_habit_fab')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final Finder nextPageFinder = find.byKey(
          const Key('habit_form_icon_page_next'),
        );
        for (int i = 0; i < 5; i += 1) {
          if (find
              .byKey(const ValueKey<String>('habit_form_icon_sun'))
              .evaluate()
              .isNotEmpty) {
            break;
          }
          final IconButton nextPageButton = tester.widget<IconButton>(
            nextPageFinder,
          );
          if (nextPageButton.onPressed == null) {
            break;
          }
          await tester.ensureVisible(nextPageFinder);
          await tester.tap(nextPageFinder);
          await tester.pumpAndSettle();
        }
        expect(
          find.byKey(const ValueKey<String>('habit_form_icon_sun')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const ValueKey<String>('habit_form_icon_sun')),
        );
        await tester.enterText(
          find.byKey(const Key('habit_form_name_field')),
          'Accessibility Run',
        );
        await tester.tap(find.byKey(const Key('habit_form_submit_button')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final List<Habit> habits = await repository.listActiveHabits();
        final Habit createdHabit = habits.firstWhere(
          (final Habit habit) => habit.name == 'Accessibility Run',
        );
        expect(createdHabit.iconKey, 'sun');
      },
    );

    testWidgets('habit form saves custom colors as uppercase #RRGGBB', (
      final WidgetTester tester,
    ) async {
      final _FakeHabitRepository repository = _FakeHabitRepository();

      await _pumpHomeScreen(
        tester: tester,
        repository: repository,
        eventRepository: _FakeHabitEventRepository(),
      );

      await tester.tap(find.byKey(const Key('home_create_first_habit_button')));
      await tester.pumpAndSettle();

      final Finder customColorButton = find.byKey(
        const Key('habit_form_custom_color_button'),
      );
      await tester.ensureVisible(customColorButton);
      await tester.tap(customColorButton);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('habit_form_custom_color_input')),
        '#a1b2c3',
      );
      await tester.tap(
        find.byKey(const Key('habit_form_custom_color_apply_button')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('habit_form_name_field')),
        'Custom Color Habit',
      );
      await tester.tap(find.byKey(const Key('habit_form_submit_button')));
      await tester.pumpAndSettle();

      final Habit createdHabit = (await repository.listActiveHabits()).single;
      expect(createdHabit.colorHex, '#A1B2C3');
    });

    testWidgets(
      'edit flow preserves non-preset stored color and icon without fallback',
      (final WidgetTester tester) async {
        final _FakeHabitRepository repository = _FakeHabitRepository(
          seedHabits: <Habit>[
            Habit(
              id: 'habit-1',
              name: 'Sunlight',
              iconKey: 'sun',
              colorHex: '#A1B2C3',
              mode: HabitMode.positive,
              createdAtUtc: DateTime.utc(2026, 2, 1, 8),
            ),
          ],
        );

        await _pumpHomeScreen(
          tester: tester,
          repository: repository,
          eventRepository: _FakeHabitEventRepository(),
        );

        await tester.tap(
          find.byKey(const ValueKey<String>('habit_card_menu_habit-1')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Edit Habit'));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('habit_form_color_custom_selected')),
          findsOneWidget,
        );
        await tester.enterText(
          find.byKey(const Key('habit_form_name_field')),
          'Sunlight Daily',
        );
        await tester.tap(find.byKey(const Key('habit_form_submit_button')));
        await tester.pumpAndSettle();

        final Habit updatedHabit = (await repository.listActiveHabits()).single;
        expect(updatedHabit.colorHex, '#A1B2C3');
        expect(updatedHabit.iconKey, 'sun');
      },
    );

    testWidgets(
      'timezone shift does not rebucket historical local day keys in grid',
      (final WidgetTester tester) async {
        final _FakeHabitRepository repository = _FakeHabitRepository(
          seedHabits: <Habit>[
            Habit(
              id: 'habit-1',
              name: 'Read',
              iconKey: 'book',
              colorHex: '#1C7C54',
              mode: HabitMode.positive,
              createdAtUtc: DateTime.utc(2026, 3, 1, 8),
            ),
          ],
        );
        final _FakeHabitEventRepository eventRepository =
            _FakeHabitEventRepository(
              seedEvents: <HabitEvent>[
                HabitEvent(
                  id: 'event-1',
                  habitId: 'habit-1',
                  eventType: HabitEventType.complete,
                  occurredAtUtc: DateTime.utc(2026, 3, 15, 2),
                  localDayKey: '2026-03-14',
                  tzOffsetMinutesAtEvent: -300,
                ),
              ],
            );

        await _pumpHomeScreen(
          tester: tester,
          repository: repository,
          eventRepository: eventRepository,
          clock: () => DateTime(2026, 3, 14, 21),
        );
        expect(
          find.byKey(
            const ValueKey<String>(
              'habit_grid_cell_habit-1_2026-03-14_positiveDone',
            ),
          ),
          findsOneWidget,
        );
        expect(find.textContaining('Done today'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        await _pumpHomeScreen(
          tester: tester,
          repository: repository,
          eventRepository: eventRepository,
          clock: () => DateTime(2026, 3, 15, 9),
        );
        expect(
          find.byKey(
            const ValueKey<String>(
              'habit_grid_cell_habit-1_2026-03-14_positiveDone',
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey<String>(
              'habit_grid_cell_habit-1_2026-03-15_positiveMissed',
            ),
          ),
          findsOneWidget,
        );
        expect(find.textContaining('Not done today'), findsOneWidget);
      },
    );

    testWidgets('undo and re-log keep grid and streak in sync', (
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
        clock: () => DateTime(2026, 2, 15, 9, 30),
      );

      expect(
        find.byKey(
          const ValueKey<String>(
            'habit_grid_cell_habit-1_2026-02-15_positiveMissed',
          ),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('habit_card_quick_action_habit-1')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const ValueKey<String>(
            'habit_grid_cell_habit-1_2026-02-15_positiveDone',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('Streak: 1 day'), findsOneWidget);
      expect(find.text('Done today'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('habit_card_quick_action_habit-1')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const ValueKey<String>(
            'habit_grid_cell_habit-1_2026-02-15_positiveMissed',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('Streak: 0 days'), findsOneWidget);
      expect(find.text('Not done today'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('habit_card_quick_action_habit-1')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const ValueKey<String>(
            'habit_grid_cell_habit-1_2026-02-15_positiveDone',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('Streak: 1 day'), findsOneWidget);
      expect(find.text('Done today'), findsOneWidget);

      final List<HabitEvent> events = await eventRepository.listEventsForHabit(
        'habit-1',
      );
      expect(events.length, 1);
      expect(events.single.localDayKey, '2026-02-15');
      expect(events.single.eventType, HabitEventType.complete);
    });

    testWidgets(
      'negative quick action and grid taps remain behaviorally consistent',
      (final WidgetTester tester) async {
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

        await _pumpHomeScreen(
          tester: tester,
          repository: repository,
          eventRepository: eventRepository,
          clock: () => DateTime(2026, 2, 15, 9, 30),
        );

        await tester.tap(
          find.byKey(const ValueKey<String>('habit_card_quick_action_habit-1')),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(
            const ValueKey<String>(
              'habit_grid_cell_habit-1_2026-02-15_negativeRelapse',
            ),
          ),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(
            const ValueKey<String>('habit_grid_cell_tap_habit-1_2026-02-15'),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(
            const ValueKey<String>(
              'habit_grid_cell_habit-1_2026-02-15_negativeClear',
            ),
          ),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(
            const ValueKey<String>('habit_grid_cell_tap_habit-1_2026-02-15'),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(
            const ValueKey<String>(
              'habit_grid_cell_habit-1_2026-02-15_negativeRelapse',
            ),
          ),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const ValueKey<String>('habit_card_quick_action_habit-1')),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(
            const ValueKey<String>(
              'habit_grid_cell_habit-1_2026-02-15_negativeClear',
            ),
          ),
          findsOneWidget,
        );

        final List<HabitEvent> events = await eventRepository
            .listEventsForHabit('habit-1');
        expect(events, isEmpty);
      },
    );

    testWidgets('long names stay overflow-safe at large text scaling', (
      final WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final _FakeHabitRepository repository = _FakeHabitRepository(
        seedHabits: <Habit>[
          Habit(
            id: 'habit-1',
            name:
                'Extremely Long Habit Name That Must Stay Stable Under Accessibility Text Scaling',
            iconKey: 'journal',
            colorHex: '#255F85',
            mode: HabitMode.positive,
            note:
                'This note is intentionally long so subtitle rows still need safe truncation.',
            createdAtUtc: DateTime.utc(2026, 2, 1, 8),
          ),
        ],
      );

      await _pumpHomeScreen(
        tester: tester,
        repository: repository,
        eventRepository: _FakeHabitEventRepository(),
        clock: () => DateTime(2026, 2, 15, 9),
        textScaleFactor: 1.8,
      );

      expect(tester.takeException(), isNull);
      await tester.tap(
        find.byKey(const ValueKey<String>('habit_card_quick_action_habit-1')),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('dark theme defaults keep global surfaces readable', (
      final WidgetTester tester,
    ) async {
      await _pumpHomeScreen(
        tester: tester,
        repository: _FakeHabitRepository(
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
        ),
        eventRepository: _FakeHabitEventRepository(),
        clock: () => DateTime(2026, 2, 15, 9),
      );

      final ThemeData theme = Theme.of(tester.element(find.byType(HomeScreen)));
      expect(theme.brightness, Brightness.dark);

      _expectMinContrast(
        foreground: theme.colorScheme.onSurface,
        background: theme.colorScheme.surface,
        contextLabel: 'surface',
        minContrastRatio: 4.5,
      );
      _expectMinContrast(
        foreground: theme.colorScheme.onSurface,
        background:
            theme.dialogTheme.backgroundColor ??
            theme.colorScheme.surfaceContainerHighest,
        contextLabel: 'dialog surface',
        minContrastRatio: 4.5,
      );
      _expectMinContrast(
        foreground:
            theme.popupMenuTheme.textStyle?.color ??
            theme.colorScheme.onSurface,
        background:
            theme.popupMenuTheme.color ??
            theme.colorScheme.surfaceContainerHighest,
        contextLabel: 'popup menu',
        minContrastRatio: 4.5,
      );
      _expectMinContrast(
        foreground:
            theme.chipTheme.labelStyle?.color ??
            theme.colorScheme.onSurfaceVariant,
        background:
            theme.chipTheme.backgroundColor ??
            theme.colorScheme.surfaceContainerHighest,
        contextLabel: 'chip',
        minContrastRatio: 4.5,
      );
      _expectMinContrast(
        foreground:
            theme.snackBarTheme.contentTextStyle?.color ??
            theme.colorScheme.onInverseSurface,
        background:
            theme.snackBarTheme.backgroundColor ??
            theme.colorScheme.inverseSurface,
        contextLabel: 'snackbar',
        minContrastRatio: 4.5,
      );
    });

    testWidgets('habit card text and actions meet contrast thresholds', (
      final WidgetTester tester,
    ) async {
      const List<String> colorHexes = <String>[
        '#1C7C54',
        '#255F85',
        '#6A4C93',
        '#8A2D3B',
        '#B85C00',
        '#2E7D32',
        '#1565C0',
        '#5D4037',
        '#0E7490',
        '#7C3AED',
        '#BE123C',
        '#9A3412',
        '#14532D',
        '#1E3A8A',
        '#374151',
        '#0F766E',
      ];
      final List<Habit> seedHabits = List<Habit>.generate(colorHexes.length, (
        final int index,
      ) {
        return Habit(
          id: 'habit-${index + 1}',
          name: 'Habit ${index + 1}',
          iconKey: index.isEven ? 'book' : 'walk',
          colorHex: colorHexes[index],
          mode: switch (index) {
            2 || 3 => HabitMode.negative,
            _ => HabitMode.positive,
          },
          createdAtUtc: DateTime.utc(2026, 2, 1 + index, 8),
        );
      });
      final _FakeHabitEventRepository eventRepository =
          _FakeHabitEventRepository(
            seedEvents: <HabitEvent>[
              HabitEvent(
                id: 'event-positive-done',
                habitId: 'habit-2',
                eventType: HabitEventType.complete,
                occurredAtUtc: DateTime.utc(2026, 2, 15, 12),
                localDayKey: '2026-02-15',
                tzOffsetMinutesAtEvent: 0,
              ),
              HabitEvent(
                id: 'event-negative-relapse',
                habitId: 'habit-4',
                eventType: HabitEventType.relapse,
                occurredAtUtc: DateTime.utc(2026, 2, 15, 8),
                localDayKey: '2026-02-15',
                tzOffsetMinutesAtEvent: 0,
              ),
            ],
          );

      await _pumpHomeScreen(
        tester: tester,
        repository: _FakeHabitRepository(seedHabits: seedHabits),
        eventRepository: eventRepository,
        clock: () => DateTime(2026, 2, 15, 9),
      );

      for (final Habit habit in seedHabits) {
        final Finder cardFinder = find.byKey(
          ValueKey<String>('habit_card_${habit.id}'),
        );
        await tester.scrollUntilVisible(
          cardFinder,
          240,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        _expectHabitCardContrast(
          tester: tester,
          habitId: habit.id,
          minContrastRatio: 4.5,
        );
      }
    });
  });
}

void _expectHabitCardContrast({
  required final WidgetTester tester,
  required final String habitId,
  required final double minContrastRatio,
}) {
  final Finder cardFinder = find.byKey(ValueKey<String>('habit_card_$habitId'));
  final Card card = tester.widget<Card>(
    find.descendant(of: cardFinder, matching: find.byType(Card)),
  );
  final Color backgroundColor = card.color ?? Colors.transparent;

  final ListTile listTile = tester.widget<ListTile>(
    find.descendant(of: cardFinder, matching: find.byType(ListTile)),
  );
  final Text title = listTile.title! as Text;
  _expectMinContrast(
    foreground: title.style?.color,
    background: backgroundColor,
    contextLabel: '$habitId title',
    minContrastRatio: minContrastRatio,
  );

  final Widget subtitle = listTile.subtitle!;
  if (subtitle is Column) {
    for (final Text text in subtitle.children.whereType<Text>()) {
      _expectMinContrast(
        foreground: text.style?.color,
        background: backgroundColor,
        contextLabel: '$habitId subtitle',
        minContrastRatio: minContrastRatio,
      );
    }
  }

  final IconButton quickAction = tester.widget<IconButton>(
    find.byKey(ValueKey<String>('habit_card_quick_action_$habitId')),
  );
  _expectMinContrast(
    foreground: quickAction.color,
    background: backgroundColor,
    contextLabel: '$habitId quick action',
    minContrastRatio: minContrastRatio,
  );
}

void _expectMinContrast({
  required final Color? foreground,
  required final Color background,
  required final String contextLabel,
  required final double minContrastRatio,
}) {
  expect(
    foreground,
    isNotNull,
    reason: '$contextLabel should define an explicit foreground color.',
  );
  final double contrast = _contrastRatio(foreground!, background);
  expect(
    contrast,
    greaterThanOrEqualTo(minContrastRatio),
    reason:
        '$contextLabel contrast ratio ${contrast.toStringAsFixed(2)} must be >= $minContrastRatio.',
  );
}

double _contrastRatio(final Color foreground, final Color background) {
  final Color blendedForeground = foreground.a == 1
      ? foreground
      : Color.alphaBlend(foreground, background);
  final double foregroundLuminance = blendedForeground.computeLuminance();
  final double backgroundLuminance = background.computeLuminance();
  final double lighter = math.max(foregroundLuminance, backgroundLuminance);
  final double darker = math.min(foregroundLuminance, backgroundLuminance);
  return (lighter + 0.05) / (darker + 0.05);
}

Future<void> _pumpHomeScreen({
  required final WidgetTester tester,
  required final HabitRepository repository,
  required final HabitEventRepository eventRepository,
  AppSettingsRepository? appSettingsRepository,
  HabitReminderRepository? habitReminderRepository,
  ReminderNotificationScheduler? notificationScheduler,
  DateTime Function()? clock,
  double? textScaleFactor,
}) async {
  final AppSettingsRepository resolvedAppSettingsRepository =
      appSettingsRepository ?? _FakeAppSettingsRepository();
  final HabitReminderRepository resolvedHabitReminderRepository =
      habitReminderRepository ?? _FakeHabitReminderRepository();
  final ReminderNotificationScheduler resolvedNotificationScheduler =
      notificationScheduler ?? _FakeReminderNotificationScheduler();
  if (repository is _FakeHabitRepository &&
      eventRepository is _FakeHabitEventRepository &&
      resolvedHabitReminderRepository is _FakeHabitReminderRepository) {
    repository.deleteHabitHook = (final String habitId) async {
      await eventRepository.deleteEventsForHabit(habitId);
      await resolvedHabitReminderRepository.deleteReminderByHabitId(habitId);
    };
  }
  if (resolvedAppSettingsRepository is _FakeAppSettingsRepository) {
    resolvedAppSettingsRepository.resetAllDataHandler = () async {
      if (repository is _FakeHabitRepository) {
        await repository.clearAll();
      }
      if (eventRepository is _FakeHabitEventRepository) {
        await eventRepository.clearAll();
      }
      if (resolvedHabitReminderRepository is _FakeHabitReminderRepository) {
        await resolvedHabitReminderRepository.clearAll();
      }
    };
  }

  Widget homeScreen = HomeScreen(
    habitRepository: repository,
    habitEventRepository: eventRepository,
    appSettingsRepository: resolvedAppSettingsRepository,
    habitReminderRepository: resolvedHabitReminderRepository,
    notificationScheduler: resolvedNotificationScheduler,
    clock: clock ?? DateTime.now,
  );
  if (textScaleFactor != null) {
    final Widget child = homeScreen;
    homeScreen = Builder(
      builder: (final BuildContext context) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScaleFactor)),
          child: child,
        );
      },
    );
  }

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      home: homeScreen,
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
  Future<void> Function(String habitId)? deleteHabitHook;

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

  @override
  Future<void> deleteHabitPermanently(final String habitId) async {
    final Habit? habit = _habitsById[habitId];
    if (habit == null) {
      return;
    }
    if (!habit.isArchived) {
      throw StateError('Habit must be archived before permanent delete.');
    }
    _habitsById.remove(habitId);
    await deleteHabitHook?.call(habitId);
  }

  Future<void> clearAll() async {
    _habitsById.clear();
  }
}

class _FakeHabitEventRepository implements HabitEventRepository {
  _FakeHabitEventRepository({
    final Iterable<HabitEvent> seedEvents = const <HabitEvent>[],
  }) {
    for (final HabitEvent event in seedEvents) {
      _eventsById[event.id] = event;
    }
  }

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

  Future<void> deleteEventsForHabit(final String habitId) async {
    _eventsById.removeWhere(
      (final String _, final HabitEvent event) => event.habitId == habitId,
    );
  }

  Future<void> clearAll() async {
    _eventsById.clear();
  }
}

class _FakeAppSettingsRepository implements AppSettingsRepository {
  _FakeAppSettingsRepository({final AppSettings? seedSettings})
    : _settings = seedSettings ?? AppSettings.defaults;

  AppSettings _settings;
  Future<void> Function()? resetAllDataHandler;

  @override
  Future<AppSettings> loadSettings() async {
    return _settings;
  }

  @override
  Future<void> saveSettings(final AppSettings settings) async {
    _settings = settings;
  }

  @override
  Future<void> resetAllData() async {
    await resetAllDataHandler?.call();
    _settings = AppSettings.defaults;
  }
}

class _FakeHabitReminderRepository implements HabitReminderRepository {
  _FakeHabitReminderRepository({
    final Iterable<HabitReminder> seedReminders = const <HabitReminder>[],
  }) {
    for (final HabitReminder reminder in seedReminders) {
      _remindersByHabitId[reminder.habitId] = reminder;
    }
  }

  final Map<String, HabitReminder> _remindersByHabitId =
      <String, HabitReminder>{};

  @override
  Future<void> deleteReminderByHabitId(final String habitId) async {
    _remindersByHabitId.remove(habitId);
  }

  @override
  Future<HabitReminder?> findReminderByHabitId(final String habitId) async {
    return _remindersByHabitId[habitId];
  }

  @override
  Future<List<HabitReminder>> listReminders() async {
    return _remindersByHabitId.values.toList(growable: false);
  }

  @override
  Future<void> saveReminder(final HabitReminder reminder) async {
    _remindersByHabitId[reminder.habitId] = reminder;
  }

  Future<void> clearAll() async {
    _remindersByHabitId.clear();
  }
}

class _FakeReminderNotificationScheduler
    implements ReminderNotificationScheduler {
  bool notificationsAllowed = true;
  bool grantPermissionOnRequest = true;
  int permissionRequestCount = 0;
  final Map<String, int> scheduledMinutesByHabitId = <String, int>{};
  final Set<String> cancelledHabitIds = <String>{};

  @override
  Future<bool> areNotificationsAllowed() async {
    return notificationsAllowed;
  }

  @override
  Future<void> cancelReminder({required final String habitId}) async {
    cancelledHabitIds.add(habitId);
    scheduledMinutesByHabitId.remove(habitId);
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestNotificationsPermission() async {
    permissionRequestCount += 1;
    notificationsAllowed = grantPermissionOnRequest;
    return grantPermissionOnRequest;
  }

  @override
  Future<void> scheduleDailyReminder({
    required final String habitId,
    required final String habitName,
    required final int reminderTimeMinutes,
  }) async {
    scheduledMinutesByHabitId[habitId] = reminderTimeMinutes;
  }
}
