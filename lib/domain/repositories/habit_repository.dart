import 'package:habit_tracker/domain/entities/habit.dart';

abstract interface class HabitRepository {
  Future<void> saveHabit(Habit habit);

  Future<Habit?> findHabitById(String habitId);

  Future<List<Habit>> listHabits({bool includeArchived = true});

  Future<List<Habit>> listActiveHabits();

  Future<void> archiveHabit({
    required String habitId,
    required DateTime archivedAtUtc,
  });

  Future<void> unarchiveHabit(String habitId);
}
