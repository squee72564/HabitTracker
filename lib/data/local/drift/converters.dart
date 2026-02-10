import 'package:drift/drift.dart';
import 'package:habit_tracker/domain/domain.dart';

class UtcDateTimeConverter extends TypeConverter<DateTime, int> {
  const UtcDateTimeConverter();

  @override
  DateTime fromSql(final int fromDb) {
    return DateTime.fromMillisecondsSinceEpoch(fromDb, isUtc: true);
  }

  @override
  int toSql(final DateTime value) {
    if (!value.isUtc) {
      throw ArgumentError.value(
        value,
        'value',
        'DateTime values persisted to SQLite must be UTC.',
      );
    }
    return value.millisecondsSinceEpoch;
  }
}

class NullableUtcDateTimeConverter extends TypeConverter<DateTime?, int?> {
  const NullableUtcDateTimeConverter();

  @override
  DateTime? fromSql(final int? fromDb) {
    if (fromDb == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(fromDb, isUtc: true);
  }

  @override
  int? toSql(final DateTime? value) {
    if (value == null) {
      return null;
    }
    if (!value.isUtc) {
      throw ArgumentError.value(
        value,
        'value',
        'DateTime values persisted to SQLite must be UTC.',
      );
    }
    return value.millisecondsSinceEpoch;
  }
}

class HabitModeConverter extends TypeConverter<HabitMode, String> {
  const HabitModeConverter();

  @override
  HabitMode fromSql(final String fromDb) {
    return HabitMode.fromStorageValue(fromDb);
  }

  @override
  String toSql(final HabitMode value) {
    return value.storageValue;
  }
}

class AppWeekStartConverter extends TypeConverter<AppWeekStart, String> {
  const AppWeekStartConverter();

  @override
  AppWeekStart fromSql(final String fromDb) {
    return AppWeekStart.fromStorageValue(fromDb);
  }

  @override
  String toSql(final AppWeekStart value) {
    return value.storageValue;
  }
}

class AppTimeFormatConverter extends TypeConverter<AppTimeFormat, String> {
  const AppTimeFormatConverter();

  @override
  AppTimeFormat fromSql(final String fromDb) {
    return AppTimeFormat.fromStorageValue(fromDb);
  }

  @override
  String toSql(final AppTimeFormat value) {
    return value.storageValue;
  }
}

class HabitEventTypeConverter extends TypeConverter<HabitEventType, String> {
  const HabitEventTypeConverter();

  @override
  HabitEventType fromSql(final String fromDb) {
    return HabitEventType.fromStorageValue(fromDb);
  }

  @override
  String toSql(final HabitEventType value) {
    return value.storageValue;
  }
}

class HabitEventSourceConverter
    extends TypeConverter<HabitEventSource, String> {
  const HabitEventSourceConverter();

  @override
  HabitEventSource fromSql(final String fromDb) {
    return HabitEventSource.fromStorageValue(fromDb);
  }

  @override
  String toSql(final HabitEventSource value) {
    return value.storageValue;
  }
}
