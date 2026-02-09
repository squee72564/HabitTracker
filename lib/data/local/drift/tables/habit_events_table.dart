import 'package:drift/drift.dart';
import 'package:habit_tracker/data/local/drift/converters.dart';
import 'package:habit_tracker/data/local/drift/tables/habits_table.dart';

@DataClassName('HabitEventRecord')
class HabitEvents extends Table {
  TextColumn get id => text()();

  TextColumn get habitId =>
      text().references(Habits, #id, onDelete: KeyAction.cascade)();

  TextColumn get eventType => text().map(const HabitEventTypeConverter())();

  IntColumn get occurredAtUtc => integer().map(const UtcDateTimeConverter())();

  TextColumn get localDayKey => text().withLength(min: 10, max: 10)();

  IntColumn get tzOffsetMinutesAtEvent => integer()();

  TextColumn get source => text().map(const HabitEventSourceConverter())();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}
