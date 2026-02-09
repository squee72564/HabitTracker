import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/data/data.dart';
import 'package:habit_tracker/domain/domain.dart';

void main() {
  late AppDatabase database;
  late DriftHabitRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = DriftHabitRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('saves and loads habits by id', () async {
    final Habit habit = _habit(
      id: 'habit-1',
      name: 'Read',
      note: 'Before breakfast',
      createdAtUtc: DateTime.utc(2026, 2, 10, 1),
    );

    await repository.saveHabit(habit);
    final Habit? loaded = await repository.findHabitById(habit.id);

    expect(loaded, isNotNull);
    expect(loaded!.id, habit.id);
    expect(loaded.name, habit.name);
    expect(loaded.note, habit.note);
    expect(loaded.createdAtUtc, habit.createdAtUtc);
    expect(loaded.archivedAtUtc, isNull);
  });

  test('updates habit data via save and lists active habits', () async {
    final Habit habit = _habit(
      id: 'habit-1',
      name: 'Read',
      createdAtUtc: DateTime.utc(2026, 2, 10, 1),
    );
    await repository.saveHabit(habit);

    final Habit updated = habit.copyWith(
      name: 'Read Daily',
      note: null,
      clearNote: true,
    );
    await repository.saveHabit(updated);

    final Habit? loaded = await repository.findHabitById(habit.id);
    expect(loaded, isNotNull);
    expect(loaded!.name, 'Read Daily');
    expect(loaded.note, isNull);

    final List<Habit> active = await repository.listActiveHabits();
    expect(active.length, 1);
    expect(active.single.id, habit.id);
  });

  test(
    'archives and unarchives habits using archivedAtUtc soft delete',
    () async {
      final Habit habit = _habit(
        id: 'habit-1',
        name: 'Read',
        createdAtUtc: DateTime.utc(2026, 2, 10, 1),
      );
      await repository.saveHabit(habit);

      final DateTime archivedAtUtc = DateTime.utc(2026, 2, 11, 2);
      await repository.archiveHabit(
        habitId: habit.id,
        archivedAtUtc: archivedAtUtc,
      );

      final Habit? archivedHabit = await repository.findHabitById(habit.id);
      expect(archivedHabit, isNotNull);
      expect(archivedHabit!.archivedAtUtc, archivedAtUtc);

      final List<Habit> activeAfterArchive = await repository
          .listActiveHabits();
      expect(activeAfterArchive, isEmpty);

      await repository.unarchiveHabit(habit.id);
      final List<Habit> activeAfterUnarchive = await repository
          .listActiveHabits();
      expect(activeAfterUnarchive.length, 1);
      expect(activeAfterUnarchive.single.id, habit.id);
      expect(activeAfterUnarchive.single.archivedAtUtc, isNull);
    },
  );
}

Habit _habit({
  required final String id,
  required final String name,
  final String? note,
  required final DateTime createdAtUtc,
}) {
  return Habit(
    id: id,
    name: name,
    iconKey: 'book',
    colorHex: '#FFAA00',
    mode: HabitMode.positive,
    note: note,
    createdAtUtc: createdAtUtc,
  );
}
