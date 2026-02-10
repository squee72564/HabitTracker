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
      expect(
        find.text('Streak: 0 days (Best: 0 days) • Not done today'),
        findsOneWidget,
      );

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
      expect(
        find.text('Streak: 1 day (Best: 1 day) • Done today'),
        findsOneWidget,
      );
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
      expect(
        find.text('Streak: 1 day (Best: 1 day) • Done today'),
        findsOneWidget,
      );

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
      expect(
        find.text('Streak: 0 days (Best: 0 days) • Not done today'),
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
      expect(
        find.text('Streak: 1 day (Best: 1 day) • Done today'),
        findsOneWidget,
      );

      final List<HabitEvent> events = await eventRepository.listEventsForHabit(
        'habit-1',
      );
      expect(events.length, 1);
      expect(events.single.localDayKey, '2026-02-15');
      expect(events.single.eventType, HabitEventType.complete);
    });

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
    MaterialApp(theme: AppTheme.light(), home: homeScreen),
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
