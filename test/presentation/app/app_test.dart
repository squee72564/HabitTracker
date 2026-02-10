import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/data/data.dart';
import 'package:habit_tracker/domain/domain.dart';
import 'package:habit_tracker/presentation/presentation.dart';

void main() {
  testWidgets('startup sync cancels reminders when global reminders are off', (
    final WidgetTester tester,
  ) async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await _seedReminderData(database: database, remindersEnabled: false);
    final _FakeReminderNotificationScheduler scheduler =
        _FakeReminderNotificationScheduler();

    await tester.pumpWidget(
      HabitTrackerApp(database: database, notificationScheduler: scheduler),
    );
    await tester.pumpAndSettle();

    expect(scheduler.initializeCount, 1);
    expect(scheduler.cancelledHabitIds.contains('habit-1'), isTrue);
    expect(scheduler.scheduledMinutesByHabitId, isEmpty);
  });

  testWidgets(
    'startup sync schedules enabled reminders when global reminders are on',
    (final WidgetTester tester) async {
      final AppDatabase database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      await _seedReminderData(database: database, remindersEnabled: true);
      final _FakeReminderNotificationScheduler scheduler =
          _FakeReminderNotificationScheduler();

      await tester.pumpWidget(
        HabitTrackerApp(database: database, notificationScheduler: scheduler),
      );
      await tester.pumpAndSettle();

      expect(scheduler.initializeCount, 1);
      expect(scheduler.scheduledMinutesByHabitId['habit-1'], 21 * 60 + 15);
    },
  );
}

Future<void> _seedReminderData({
  required final AppDatabase database,
  required final bool remindersEnabled,
}) async {
  final DriftHabitRepository habitRepository = DriftHabitRepository(database);
  final DriftHabitReminderRepository reminderRepository =
      DriftHabitReminderRepository(database);
  final DriftAppSettingsRepository appSettingsRepository =
      DriftAppSettingsRepository(database);
  await habitRepository.saveHabit(
    Habit(
      id: 'habit-1',
      name: 'Read',
      iconKey: 'book',
      colorHex: '#1C7C54',
      mode: HabitMode.positive,
      createdAtUtc: DateTime.utc(2026, 2, 10, 1),
    ),
  );
  await reminderRepository.saveReminder(
    HabitReminder(
      habitId: 'habit-1',
      isEnabled: true,
      reminderTimeMinutes: 21 * 60 + 15,
    ),
  );
  await appSettingsRepository.saveSettings(
    AppSettings.defaults.copyWith(remindersEnabled: remindersEnabled),
  );
}

class _FakeReminderNotificationScheduler
    implements ReminderNotificationScheduler {
  int initializeCount = 0;
  bool notificationsAllowed = true;
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
  Future<void> initialize() async {
    initializeCount += 1;
  }

  @override
  Future<bool> requestNotificationsPermission() async {
    return true;
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
