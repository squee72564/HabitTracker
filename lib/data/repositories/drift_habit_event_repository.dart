import 'package:drift/drift.dart';
import 'package:habit_tracker/data/local/drift/app_database.dart';
import 'package:habit_tracker/domain/domain.dart';

class DriftHabitEventRepository implements HabitEventRepository {
  const DriftHabitEventRepository(this._database);

  final AppDatabase _database;

  @override
  Future<void> saveEvent(final HabitEvent event) async {
    await _database.transaction(() async {
      if (event.eventType == HabitEventType.complete) {
        final HabitEventRecord? existingCompletion =
            await (_database.select(_database.habitEvents)..where(
                  (final tbl) =>
                      tbl.habitId.equals(event.habitId) &
                      tbl.localDayKey.equals(event.localDayKey) &
                      tbl.eventType.equals(
                        HabitEventType.complete.storageValue,
                      ),
                ))
                .getSingleOrNull();
        if (existingCompletion != null) {
          throw DuplicateHabitCompletionException(
            habitId: event.habitId,
            localDayKey: event.localDayKey,
          );
        }
      }

      await _database
          .into(_database.habitEvents)
          .insert(_toEventCompanion(event), mode: InsertMode.insert);
    });
  }

  @override
  Future<HabitEvent?> findEventById(final String eventId) async {
    final HabitEventRecord? record = await (_database.select(
      _database.habitEvents,
    )..where((final tbl) => tbl.id.equals(eventId))).getSingleOrNull();
    if (record == null) {
      return null;
    }
    return _toDomainEvent(record);
  }

  @override
  Future<List<HabitEvent>> listEventsForHabit(final String habitId) async {
    final List<HabitEventRecord> records =
        await (_database.select(_database.habitEvents)
              ..where((final tbl) => tbl.habitId.equals(habitId))
              ..orderBy(<OrderingTerm Function($HabitEventsTable)>[
                (final $HabitEventsTable tbl) =>
                    OrderingTerm.asc(tbl.occurredAtUtc),
              ]))
            .get();
    return records.map(_toDomainEvent).toList(growable: false);
  }

  @override
  Future<List<HabitEvent>> listEventsForHabitOnDay({
    required final String habitId,
    required final String localDayKey,
  }) async {
    final List<HabitEventRecord> records =
        await (_database.select(_database.habitEvents)
              ..where(
                (final tbl) =>
                    tbl.habitId.equals(habitId) &
                    tbl.localDayKey.equals(localDayKey),
              )
              ..orderBy(<OrderingTerm Function($HabitEventsTable)>[
                (final $HabitEventsTable tbl) =>
                    OrderingTerm.asc(tbl.occurredAtUtc),
              ]))
            .get();
    return records.map(_toDomainEvent).toList(growable: false);
  }

  @override
  Future<void> deleteEventById(final String eventId) async {
    await (_database.delete(
      _database.habitEvents,
    )..where((final tbl) => tbl.id.equals(eventId))).go();
  }
}

HabitEventsCompanion _toEventCompanion(final HabitEvent event) {
  return HabitEventsCompanion.insert(
    id: event.id,
    habitId: event.habitId,
    eventType: event.eventType,
    occurredAtUtc: event.occurredAtUtc,
    localDayKey: event.localDayKey,
    tzOffsetMinutesAtEvent: event.tzOffsetMinutesAtEvent,
    source: event.source,
  );
}

HabitEvent _toDomainEvent(final HabitEventRecord record) {
  return HabitEvent(
    id: record.id,
    habitId: record.habitId,
    eventType: record.eventType,
    occurredAtUtc: record.occurredAtUtc,
    localDayKey: record.localDayKey,
    tzOffsetMinutesAtEvent: record.tzOffsetMinutesAtEvent,
    source: record.source,
  );
}
