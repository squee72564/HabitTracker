import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:habit_tracker/data/local/drift/converters.dart';
import 'package:habit_tracker/data/local/drift/tables/habit_events_table.dart';
import 'package:habit_tracker/data/local/drift/tables/habits_table.dart';
import 'package:habit_tracker/domain/domain.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: <Type>[Habits, HabitEvents])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (final Migrator migrator) async {
      await migrator.createAll();
      await _createIndexes();
    },
    onUpgrade: (final Migrator migrator, final int from, final int to) async {
      // Versioned migrations will be added as schema evolves.
      await _createIndexes();
    },
    beforeOpen: (final OpeningDetails details) async {
      await customStatement('PRAGMA foreign_keys = ON;');
    },
  );

  static QueryExecutor openConnection() {
    return driftDatabase(name: 'habit_tracker.sqlite');
  }

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_habit_events_habit_id '
      'ON habit_events (habit_id);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_habit_events_occurred_at_utc '
      'ON habit_events (occurred_at_utc);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_habit_events_local_day_key '
      'ON habit_events (local_day_key);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_habits_active_query '
      'ON habits (archived_at_utc, created_at_utc);',
    );
  }
}
