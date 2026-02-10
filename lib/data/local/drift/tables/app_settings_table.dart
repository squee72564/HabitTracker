import 'package:drift/drift.dart';
import 'package:habit_tracker/data/local/drift/converters.dart';

@DataClassName('AppSettingsRow')
class AppSettingsTable extends Table {
  IntColumn get singletonId => integer().clientDefault(() => 1)();

  TextColumn get weekStart => text()
      .map(const AppWeekStartConverter())
      .withDefault(const Constant('monday'))();

  TextColumn get timeFormat => text()
      .map(const AppTimeFormatConverter())
      .withDefault(const Constant('12h'))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{singletonId};
}
