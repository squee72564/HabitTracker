import 'package:habit_tracker/domain/value_objects/domain_constraints.dart';
import 'package:habit_tracker/domain/value_objects/habit_event_source.dart';
import 'package:habit_tracker/domain/value_objects/habit_event_type.dart';

class HabitEvent {
  HabitEvent({
    required this.id,
    required this.habitId,
    required this.eventType,
    required final DateTime occurredAtUtc,
    required this.localDayKey,
    required this.tzOffsetMinutesAtEvent,
    this.source = HabitEventSource.manual,
  }) : occurredAtUtc = _requireUtc(occurredAtUtc) {
    if (!DomainConstraints.localDayKeyPattern.hasMatch(localDayKey)) {
      throw ArgumentError.value(
        localDayKey,
        'localDayKey',
        'localDayKey must use YYYY-MM-DD format.',
      );
    }
  }

  final String id;
  final String habitId;
  final HabitEventType eventType;
  final DateTime occurredAtUtc;
  final String localDayKey;
  final int tzOffsetMinutesAtEvent;
  final HabitEventSource source;

  HabitEvent copyWith({
    final String? id,
    final String? habitId,
    final HabitEventType? eventType,
    final DateTime? occurredAtUtc,
    final String? localDayKey,
    final int? tzOffsetMinutesAtEvent,
    final HabitEventSource? source,
  }) {
    return HabitEvent(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      eventType: eventType ?? this.eventType,
      occurredAtUtc: occurredAtUtc ?? this.occurredAtUtc,
      localDayKey: localDayKey ?? this.localDayKey,
      tzOffsetMinutesAtEvent:
          tzOffsetMinutesAtEvent ?? this.tzOffsetMinutesAtEvent,
      source: source ?? this.source,
    );
  }
}

DateTime _requireUtc(final DateTime dateTime) {
  if (!dateTime.isUtc) {
    throw ArgumentError.value(
      dateTime,
      'occurredAtUtc',
      'occurredAtUtc must be in UTC.',
    );
  }
  return dateTime;
}
