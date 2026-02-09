import 'package:drift/drift.dart';
import 'package:habit_tracker/data/local/drift/converters.dart';

@DataClassName('HabitRecord')
class Habits extends Table {
  TextColumn get id => text()();

  TextColumn get name => text().withLength(min: 1, max: 40)();

  TextColumn get iconKey => text()();

  TextColumn get colorHex => text()();

  TextColumn get mode => text().map(const HabitModeConverter())();

  TextColumn get note => text().withLength(min: 0, max: 120).nullable()();

  IntColumn get createdAtUtc => integer().map(const UtcDateTimeConverter())();

  IntColumn get archivedAtUtc =>
      integer().nullable().map(const NullableUtcDateTimeConverter())();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}
