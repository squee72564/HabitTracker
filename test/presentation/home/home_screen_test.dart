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
      expect(
        find.textContaining('Streak: 0 days (Best: 0 days)'),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('habit_card_quick_action_habit-1')),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Done today'), findsOneWidget);
      expect(
        find.textContaining('Streak: 1 day (Best: 1 day)'),
        findsOneWidget,
      );
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
      expect(
        find.textContaining('Streak: 0 days (Best: 0 days)'),
        findsOneWidget,
      );
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

      expect(find.byKey(const Key('home_grid_legend')), findsOneWidget);
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
    testWidgets('week start setting applies globally to grid headers', (
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

      await _pumpHomeScreen(
        tester: tester,
        repository: repository,
        eventRepository: _FakeHabitEventRepository(),
        appSettingsRepository: appSettingsRepository,
        clock: () => DateTime(2026, 2, 15, 9),
      );

      Text firstWeekday = tester.widget<Text>(
        find.byKey(const ValueKey<String>('habit_grid_weekday_habit-1_0')),
      );
      expect(firstWeekday.data, 'M');

      await tester.tap(find.byKey(const Key('home_open_settings_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings_week_start_switch')));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      firstWeekday = tester.widget<Text>(
        find.byKey(const ValueKey<String>('habit_grid_weekday_habit-1_0')),
      );
      expect(firstWeekday.data, 'S');
    });

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
  });
}

Future<void> _pumpHomeScreen({
  required final WidgetTester tester,
  required final HabitRepository repository,
  required final HabitEventRepository eventRepository,
  AppSettingsRepository? appSettingsRepository,
  HabitReminderRepository? habitReminderRepository,
  ReminderNotificationScheduler? notificationScheduler,
  DateTime Function()? clock,
}) async {
  final AppSettingsRepository resolvedAppSettingsRepository =
      appSettingsRepository ?? _FakeAppSettingsRepository();
  final HabitReminderRepository resolvedHabitReminderRepository =
      habitReminderRepository ?? _FakeHabitReminderRepository();
  final ReminderNotificationScheduler resolvedNotificationScheduler =
      notificationScheduler ?? _FakeReminderNotificationScheduler();

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: HomeScreen(
        habitRepository: repository,
        habitEventRepository: eventRepository,
        appSettingsRepository: resolvedAppSettingsRepository,
        habitReminderRepository: resolvedHabitReminderRepository,
        notificationScheduler: resolvedNotificationScheduler,
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
}

class _FakeAppSettingsRepository implements AppSettingsRepository {
  _FakeAppSettingsRepository({final AppSettings? seedSettings})
    : _settings = seedSettings ?? AppSettings.defaults;

  AppSettings _settings;

  @override
  Future<AppSettings> loadSettings() async {
    return _settings;
  }

  @override
  Future<void> saveSettings(final AppSettings settings) async {
    _settings = settings;
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
