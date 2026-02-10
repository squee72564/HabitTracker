abstract interface class ReminderNotificationScheduler {
  Future<void> initialize();

  Future<bool> areNotificationsAllowed();

  Future<bool> requestNotificationsPermission();

  Future<void> scheduleDailyReminder({
    required String habitId,
    required String habitName,
    required int reminderTimeMinutes,
  });

  Future<void> cancelReminder({required String habitId});
}
