import 'package:drift/drift.dart';
import 'package:habit_tracker/data/local/drift/app_database.dart';
import 'package:habit_tracker/domain/domain.dart';

class DriftHabitReminderRepository implements HabitReminderRepository {
  const DriftHabitReminderRepository(this._database);

  final AppDatabase _database;

  @override
  Future<HabitReminder?> findReminderByHabitId(final String habitId) async {
    final HabitReminderRow? row = await (_database.select(
      _database.habitReminders,
    )..where((final tbl) => tbl.habitId.equals(habitId))).getSingleOrNull();
    if (row == null) {
      return null;
    }
    return _toDomainReminder(row);
  }

  @override
  Future<List<HabitReminder>> listReminders() async {
    final List<HabitReminderRow> rows =
        await (_database.select(_database.habitReminders)
              ..orderBy(<OrderingTerm Function($HabitRemindersTable)>[
                (final $HabitRemindersTable tbl) =>
                    OrderingTerm.asc(tbl.habitId),
              ]))
            .get();
    return rows.map(_toDomainReminder).toList(growable: false);
  }

  @override
  Future<void> saveReminder(final HabitReminder reminder) async {
    await _database
        .into(_database.habitReminders)
        .insert(
          _toReminderCompanion(reminder),
          mode: InsertMode.insertOrReplace,
        );
  }

  @override
  Future<void> deleteReminderByHabitId(final String habitId) async {
    await (_database.delete(
      _database.habitReminders,
    )..where((final tbl) => tbl.habitId.equals(habitId))).go();
  }
}

HabitReminder _toDomainReminder(final HabitReminderRow row) {
  return HabitReminder(
    habitId: row.habitId,
    isEnabled: row.isEnabled,
    reminderTimeMinutes: row.reminderTimeMinutes,
  );
}

HabitRemindersCompanion _toReminderCompanion(final HabitReminder reminder) {
  return HabitRemindersCompanion(
    habitId: Value<String>(reminder.habitId),
    isEnabled: Value<bool>(reminder.isEnabled),
    reminderTimeMinutes: Value<int>(reminder.reminderTimeMinutes),
  );
}
