import 'package:drift/drift.dart';
import 'package:habit_tracker/data/local/drift/converters.dart';

@DataClassName('HabitRecord')
class Habits extends Table {
  TextColumn get id => text()();

  TextColumn get name => text().withLength(min: 1, max: 40)();

  TextColumn get iconKey => text()();

  TextColumn get colorHex => text()();

  TextColumn get mode => text().map(const HabitModeConverter())();

  IntColumn get createdAtUtc => integer().map(const UtcDateTimeConverter())();

  IntColumn get archivedAtUtc =>
      integer().nullable().map(const NullableUtcDateTimeConverter())();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}
