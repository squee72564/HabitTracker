import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/domain.dart';
import 'package:habit_tracker/presentation/presentation.dart';

void main() {
  testWidgets('renders home scaffold', (final WidgetTester tester) async {
    await tester.pumpWidget(
      HabitTrackerApp(
        habitRepository: _EmptyHabitRepository(),
        habitEventRepository: _EmptyHabitEventRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Habit Tracker'), findsOneWidget);
    expect(find.text('No habits yet'), findsOneWidget);
  });
}

class _EmptyHabitRepository implements HabitRepository {
  @override
  Future<void> archiveHabit({
    required final String habitId,
    required final DateTime archivedAtUtc,
  }) async {}

  @override
  Future<Habit?> findHabitById(final String habitId) async {
    return null;
  }

  @override
  Future<List<Habit>> listActiveHabits() async {
    return <Habit>[];
  }

  @override
  Future<List<Habit>> listHabits({final bool includeArchived = true}) async {
    return <Habit>[];
  }

  @override
  Future<void> saveHabit(final Habit habit) async {}

  @override
  Future<void> unarchiveHabit(final String habitId) async {}
}

class _EmptyHabitEventRepository implements HabitEventRepository {
  @override
  Future<void> deleteEventById(final String eventId) async {}

  @override
  Future<HabitEvent?> findEventById(final String eventId) async {
    return null;
  }

  @override
  Future<List<HabitEvent>> listEventsForHabit(final String habitId) async {
    return <HabitEvent>[];
  }

  @override
  Future<List<HabitEvent>> listEventsForHabitOnDay({
    required final String habitId,
    required final String localDayKey,
  }) async {
    return <HabitEvent>[];
  }

  @override
  Future<void> saveEvent(final HabitEvent event) async {}
}
