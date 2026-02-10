import 'package:habit_tracker/domain/entities/habit_reminder.dart';

abstract interface class HabitReminderRepository {
  Future<HabitReminder?> findReminderByHabitId(String habitId);

  Future<List<HabitReminder>> listReminders();

  Future<void> saveReminder(HabitReminder reminder);

  Future<void> deleteReminderByHabitId(String habitId);
}
