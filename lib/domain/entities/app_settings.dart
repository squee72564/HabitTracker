import 'package:habit_tracker/domain/value_objects/app_time_format.dart';
import 'package:habit_tracker/domain/value_objects/app_week_start.dart';

class AppSettings {
  const AppSettings({
    this.weekStart = AppWeekStart.monday,
    this.timeFormat = AppTimeFormat.twelveHour,
  });

  static const AppSettings defaults = AppSettings();

  final AppWeekStart weekStart;
  final AppTimeFormat timeFormat;

  AppSettings copyWith({
    final AppWeekStart? weekStart,
    final AppTimeFormat? timeFormat,
  }) {
    return AppSettings(
      weekStart: weekStart ?? this.weekStart,
      timeFormat: timeFormat ?? this.timeFormat,
    );
  }
}
