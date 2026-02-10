import 'package:drift/drift.dart';
import 'package:habit_tracker/data/local/drift/app_database.dart';
import 'package:habit_tracker/domain/domain.dart';

class DriftAppSettingsRepository implements AppSettingsRepository {
  const DriftAppSettingsRepository(this._database);

  final AppDatabase _database;

  static const int _singletonId = 1;

  @override
  Future<AppSettings> loadSettings() async {
    final AppSettingsRow? row =
        await (_database.select(_database.appSettingsTable)
              ..where((final tbl) => tbl.singletonId.equals(_singletonId)))
            .getSingleOrNull();

    if (row == null) {
      return AppSettings.defaults;
    }
    return AppSettings(
      weekStart: row.weekStart,
      timeFormat: row.timeFormat,
      remindersEnabled: row.remindersEnabled,
    );
  }

  @override
  Future<void> saveSettings(final AppSettings settings) async {
    await _database
        .into(_database.appSettingsTable)
        .insert(
          AppSettingsTableCompanion(
            singletonId: const Value<int>(_singletonId),
            weekStart: Value<AppWeekStart>(settings.weekStart),
            timeFormat: Value<AppTimeFormat>(settings.timeFormat),
            remindersEnabled: Value<bool>(settings.remindersEnabled),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }
}
