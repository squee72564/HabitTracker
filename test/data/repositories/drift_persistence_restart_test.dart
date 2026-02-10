import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/data/data.dart';
import 'package:habit_tracker/domain/domain.dart';

void main() {
  test('persists habits/events across database reopen', () async {
    final Directory tempDir = await Directory.systemTemp.createTemp(
      'habit_tracker_stage2_',
    );
    final File databaseFile = File('${tempDir.path}/habit_tracker.sqlite');

    final AppDatabase firstOpen = AppDatabase(NativeDatabase(databaseFile));
    final DriftHabitRepository firstHabitRepository = DriftHabitRepository(
      firstOpen,
    );
    final DriftHabitEventRepository firstEventRepository =
        DriftHabitEventRepository(firstOpen);
    final DriftAppSettingsRepository firstSettingsRepository =
        DriftAppSettingsRepository(firstOpen);
    final DriftHabitReminderRepository firstReminderRepository =
        DriftHabitReminderRepository(firstOpen);

    final Habit habit = Habit(
      id: 'habit-1',
      name: 'Read',
      iconKey: 'book',
      colorHex: '#FFAA00',
      mode: HabitMode.positive,
      createdAtUtc: DateTime.utc(2026, 2, 10, 1),
    );
    await firstHabitRepository.saveHabit(habit);
    await firstEventRepository.saveEvent(
      HabitEvent(
        id: 'event-1',
        habitId: habit.id,
        eventType: HabitEventType.complete,
        occurredAtUtc: DateTime.utc(2026, 2, 10, 5),
        localDayKey: '2026-02-10',
        tzOffsetMinutesAtEvent: -300,
        source: HabitEventSource.manual,
      ),
    );
    await firstHabitRepository.archiveHabit(
      habitId: habit.id,
      archivedAtUtc: DateTime.utc(2026, 2, 12, 2),
    );
    await firstSettingsRepository.saveSettings(
      const AppSettings(
        weekStart: AppWeekStart.sunday,
        timeFormat: AppTimeFormat.twentyFourHour,
      ),
    );
    await firstReminderRepository.saveReminder(
      HabitReminder(
        habitId: habit.id,
        isEnabled: true,
        reminderTimeMinutes: 21 * 60 + 15,
      ),
    );
    await firstOpen.close();

    final AppDatabase secondOpen = AppDatabase(NativeDatabase(databaseFile));
    final DriftHabitRepository secondHabitRepository = DriftHabitRepository(
      secondOpen,
    );
    final DriftHabitEventRepository secondEventRepository =
        DriftHabitEventRepository(secondOpen);
    final DriftAppSettingsRepository secondSettingsRepository =
        DriftAppSettingsRepository(secondOpen);
    final DriftHabitReminderRepository secondReminderRepository =
        DriftHabitReminderRepository(secondOpen);

    final Habit? persistedHabit = await secondHabitRepository.findHabitById(
      habit.id,
    );
    final List<HabitEvent> persistedEvents = await secondEventRepository
        .listEventsForHabit(habit.id);
    final AppSettings persistedSettings = await secondSettingsRepository
        .loadSettings();
    final HabitReminder? persistedReminder = await secondReminderRepository
        .findReminderByHabitId(habit.id);

    expect(persistedHabit, isNotNull);
    expect(persistedHabit!.archivedAtUtc, DateTime.utc(2026, 2, 12, 2));
    expect(persistedEvents.length, 1);
    expect(persistedEvents.single.localDayKey, '2026-02-10');
    expect(persistedSettings.weekStart, AppWeekStart.sunday);
    expect(persistedSettings.timeFormat, AppTimeFormat.twentyFourHour);
    expect(persistedReminder, isNotNull);
    expect(persistedReminder!.isEnabled, isTrue);
    expect(persistedReminder.reminderTimeMinutes, 21 * 60 + 15);

    await secondOpen.close();
    await tempDir.delete(recursive: true);
  });
}
