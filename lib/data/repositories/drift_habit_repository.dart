import 'package:drift/drift.dart';
import 'package:habit_tracker/data/local/drift/app_database.dart';
import 'package:habit_tracker/domain/domain.dart';

class DriftHabitRepository implements HabitRepository {
  const DriftHabitRepository(this._database);

  final AppDatabase _database;

  @override
  Future<void> saveHabit(final Habit habit) async {
    await _database
        .into(_database.habits)
        .insert(_toHabitCompanion(habit), mode: InsertMode.insertOrReplace);
  }

  @override
  Future<Habit?> findHabitById(final String habitId) async {
    final HabitRecord? record = await (_database.select(
      _database.habits,
    )..where((final tbl) => tbl.id.equals(habitId))).getSingleOrNull();
    if (record == null) {
      return null;
    }
    return _toDomainHabit(record);
  }

  @override
  Future<List<Habit>> listHabits({final bool includeArchived = true}) async {
    final SimpleSelectStatement<$HabitsTable, HabitRecord> query =
        _database.select(_database.habits)
          ..orderBy(<OrderingTerm Function($HabitsTable)>[
            (final $HabitsTable tbl) => OrderingTerm.asc(tbl.createdAtUtc),
          ]);

    if (!includeArchived) {
      query.where((final $HabitsTable tbl) => tbl.archivedAtUtc.isNull());
    }

    final List<HabitRecord> records = await query.get();
    return records.map(_toDomainHabit).toList(growable: false);
  }

  @override
  Future<List<Habit>> listActiveHabits() {
    return listHabits(includeArchived: false);
  }

  @override
  Future<void> archiveHabit({
    required final String habitId,
    required final DateTime archivedAtUtc,
  }) async {
    if (!archivedAtUtc.isUtc) {
      throw ArgumentError.value(
        archivedAtUtc,
        'archivedAtUtc',
        'archivedAtUtc must be UTC.',
      );
    }

    await (_database.update(_database.habits)
          ..where((final tbl) => tbl.id.equals(habitId)))
        .write(HabitsCompanion(archivedAtUtc: Value<DateTime?>(archivedAtUtc)));
  }

  @override
  Future<void> unarchiveHabit(final String habitId) async {
    await (_database.update(_database.habits)
          ..where((final tbl) => tbl.id.equals(habitId)))
        .write(const HabitsCompanion(archivedAtUtc: Value<DateTime?>(null)));
  }
}

HabitsCompanion _toHabitCompanion(final Habit habit) {
  return HabitsCompanion.insert(
    id: habit.id,
    name: habit.name,
    iconKey: habit.iconKey,
    colorHex: habit.colorHex,
    mode: habit.mode,
    createdAtUtc: habit.createdAtUtc,
    archivedAtUtc: Value<DateTime?>(habit.archivedAtUtc),
  );
}

Habit _toDomainHabit(final HabitRecord record) {
  return Habit(
    id: record.id,
    name: record.name,
    iconKey: record.iconKey,
    colorHex: record.colorHex,
    mode: record.mode,
    createdAtUtc: record.createdAtUtc,
    archivedAtUtc: record.archivedAtUtc,
  );
}
