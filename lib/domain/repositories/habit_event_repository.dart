import 'package:habit_tracker/domain/entities/habit_event.dart';

class DuplicateHabitCompletionException implements Exception {
  const DuplicateHabitCompletionException({
    required this.habitId,
    required this.localDayKey,
  });

  final String habitId;
  final String localDayKey;

  @override
  String toString() {
    return 'DuplicateHabitCompletionException(habitId: $habitId, localDayKey: $localDayKey)';
  }
}

abstract interface class HabitEventRepository {
  Future<void> saveEvent(HabitEvent event);

  Future<HabitEvent?> findEventById(String eventId);

  Future<List<HabitEvent>> listEventsForHabit(String habitId);

  Future<List<HabitEvent>> listEventsForHabitOnDay({
    required String habitId,
    required String localDayKey,
  });

  Future<void> deleteEventById(String eventId);
}
