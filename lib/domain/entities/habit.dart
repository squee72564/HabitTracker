import 'package:habit_tracker/domain/value_objects/habit_mode.dart';

class Habit {
  Habit({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorHex,
    required this.mode,
    required final DateTime createdAtUtc,
    final DateTime? archivedAtUtc,
  }) : createdAtUtc = _requireUtc(createdAtUtc, fieldName: 'createdAtUtc'),
       archivedAtUtc = archivedAtUtc == null
           ? null
           : _requireUtc(archivedAtUtc, fieldName: 'archivedAtUtc');

  final String id;
  final String name;
  final String iconKey;
  final String colorHex;
  final HabitMode mode;
  final DateTime createdAtUtc;
  final DateTime? archivedAtUtc;

  bool get isArchived => archivedAtUtc != null;

  Habit copyWith({
    final String? id,
    final String? name,
    final String? iconKey,
    final String? colorHex,
    final HabitMode? mode,
    final DateTime? createdAtUtc,
    final DateTime? archivedAtUtc,
    final bool clearArchivedAtUtc = false,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      colorHex: colorHex ?? this.colorHex,
      mode: mode ?? this.mode,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      archivedAtUtc: clearArchivedAtUtc
          ? null
          : archivedAtUtc ?? this.archivedAtUtc,
    );
  }
}

DateTime _requireUtc(
  final DateTime dateTime, {
  required final String fieldName,
}) {
  if (!dateTime.isUtc) {
    throw ArgumentError.value(
      dateTime,
      fieldName,
      '$fieldName must be in UTC.',
    );
  }
  return dateTime;
}
