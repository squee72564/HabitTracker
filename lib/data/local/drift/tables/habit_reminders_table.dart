import 'package:drift/drift.dart';
import 'package:habit_tracker/data/local/drift/tables/habits_table.dart';

@DataClassName('HabitReminderRow')
class HabitReminders extends Table {
  TextColumn get habitId =>
      text().references(Habits, #id, onDelete: KeyAction.cascade)();

  BoolColumn get isEnabled => boolean().withDefault(const Constant(false))();

  IntColumn get reminderTimeMinutes =>
      integer().withDefault(const Constant(1200))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{habitId};
}
