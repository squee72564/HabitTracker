// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $HabitsTable extends Habits with TableInfo<$HabitsTable, HabitRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 40,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconKeyMeta = const VerificationMeta(
    'iconKey',
  );
  @override
  late final GeneratedColumn<String> iconKey = GeneratedColumn<String>(
    'icon_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
    'color_hex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<HabitMode, String> mode =
      GeneratedColumn<String>(
        'mode',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<HabitMode>($HabitsTable.$convertermode);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 0,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAtUtc =
      GeneratedColumn<int>(
        'created_at_utc',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($HabitsTable.$convertercreatedAtUtc);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> archivedAtUtc =
      GeneratedColumn<int>(
        'archived_at_utc',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($HabitsTable.$converterarchivedAtUtc);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    iconKey,
    colorHex,
    mode,
    note,
    createdAtUtc,
    archivedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habits';
  @override
  VerificationContext validateIntegrity(
    Insertable<HabitRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon_key')) {
      context.handle(
        _iconKeyMeta,
        iconKey.isAcceptableOrUnknown(data['icon_key']!, _iconKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_iconKeyMeta);
    }
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    } else if (isInserting) {
      context.missing(_colorHexMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HabitRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      iconKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_key'],
      )!,
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_hex'],
      )!,
      mode: $HabitsTable.$convertermode.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}mode'],
        )!,
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAtUtc: $HabitsTable.$convertercreatedAtUtc.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at_utc'],
        )!,
      ),
      archivedAtUtc: $HabitsTable.$converterarchivedAtUtc.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}archived_at_utc'],
        ),
      ),
    );
  }

  @override
  $HabitsTable createAlias(String alias) {
    return $HabitsTable(attachedDatabase, alias);
  }

  static TypeConverter<HabitMode, String> $convertermode =
      const HabitModeConverter();
  static TypeConverter<DateTime, int> $convertercreatedAtUtc =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime?, int?> $converterarchivedAtUtc =
      const NullableUtcDateTimeConverter();
}

class HabitRecord extends DataClass implements Insertable<HabitRecord> {
  final String id;
  final String name;
  final String iconKey;
  final String colorHex;
  final HabitMode mode;
  final String? note;
  final DateTime createdAtUtc;
  final DateTime? archivedAtUtc;
  const HabitRecord({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorHex,
    required this.mode,
    this.note,
    required this.createdAtUtc,
    this.archivedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['icon_key'] = Variable<String>(iconKey);
    map['color_hex'] = Variable<String>(colorHex);
    {
      map['mode'] = Variable<String>($HabitsTable.$convertermode.toSql(mode));
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    {
      map['created_at_utc'] = Variable<int>(
        $HabitsTable.$convertercreatedAtUtc.toSql(createdAtUtc),
      );
    }
    if (!nullToAbsent || archivedAtUtc != null) {
      map['archived_at_utc'] = Variable<int>(
        $HabitsTable.$converterarchivedAtUtc.toSql(archivedAtUtc),
      );
    }
    return map;
  }

  HabitsCompanion toCompanion(bool nullToAbsent) {
    return HabitsCompanion(
      id: Value(id),
      name: Value(name),
      iconKey: Value(iconKey),
      colorHex: Value(colorHex),
      mode: Value(mode),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAtUtc: Value(createdAtUtc),
      archivedAtUtc: archivedAtUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAtUtc),
    );
  }

  factory HabitRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitRecord(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      iconKey: serializer.fromJson<String>(json['iconKey']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
      mode: serializer.fromJson<HabitMode>(json['mode']),
      note: serializer.fromJson<String?>(json['note']),
      createdAtUtc: serializer.fromJson<DateTime>(json['createdAtUtc']),
      archivedAtUtc: serializer.fromJson<DateTime?>(json['archivedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'iconKey': serializer.toJson<String>(iconKey),
      'colorHex': serializer.toJson<String>(colorHex),
      'mode': serializer.toJson<HabitMode>(mode),
      'note': serializer.toJson<String?>(note),
      'createdAtUtc': serializer.toJson<DateTime>(createdAtUtc),
      'archivedAtUtc': serializer.toJson<DateTime?>(archivedAtUtc),
    };
  }

  HabitRecord copyWith({
    String? id,
    String? name,
    String? iconKey,
    String? colorHex,
    HabitMode? mode,
    Value<String?> note = const Value.absent(),
    DateTime? createdAtUtc,
    Value<DateTime?> archivedAtUtc = const Value.absent(),
  }) => HabitRecord(
    id: id ?? this.id,
    name: name ?? this.name,
    iconKey: iconKey ?? this.iconKey,
    colorHex: colorHex ?? this.colorHex,
    mode: mode ?? this.mode,
    note: note.present ? note.value : this.note,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    archivedAtUtc: archivedAtUtc.present
        ? archivedAtUtc.value
        : this.archivedAtUtc,
  );
  HabitRecord copyWithCompanion(HabitsCompanion data) {
    return HabitRecord(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      iconKey: data.iconKey.present ? data.iconKey.value : this.iconKey,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      mode: data.mode.present ? data.mode.value : this.mode,
      note: data.note.present ? data.note.value : this.note,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
      archivedAtUtc: data.archivedAtUtc.present
          ? data.archivedAtUtc.value
          : this.archivedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitRecord(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('iconKey: $iconKey, ')
          ..write('colorHex: $colorHex, ')
          ..write('mode: $mode, ')
          ..write('note: $note, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('archivedAtUtc: $archivedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    iconKey,
    colorHex,
    mode,
    note,
    createdAtUtc,
    archivedAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitRecord &&
          other.id == this.id &&
          other.name == this.name &&
          other.iconKey == this.iconKey &&
          other.colorHex == this.colorHex &&
          other.mode == this.mode &&
          other.note == this.note &&
          other.createdAtUtc == this.createdAtUtc &&
          other.archivedAtUtc == this.archivedAtUtc);
}

class HabitsCompanion extends UpdateCompanion<HabitRecord> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> iconKey;
  final Value<String> colorHex;
  final Value<HabitMode> mode;
  final Value<String?> note;
  final Value<DateTime> createdAtUtc;
  final Value<DateTime?> archivedAtUtc;
  final Value<int> rowid;
  const HabitsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.mode = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.archivedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HabitsCompanion.insert({
    required String id,
    required String name,
    required String iconKey,
    required String colorHex,
    required HabitMode mode,
    this.note = const Value.absent(),
    required DateTime createdAtUtc,
    this.archivedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       iconKey = Value(iconKey),
       colorHex = Value(colorHex),
       mode = Value(mode),
       createdAtUtc = Value(createdAtUtc);
  static Insertable<HabitRecord> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? iconKey,
    Expression<String>? colorHex,
    Expression<String>? mode,
    Expression<String>? note,
    Expression<int>? createdAtUtc,
    Expression<int>? archivedAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (iconKey != null) 'icon_key': iconKey,
      if (colorHex != null) 'color_hex': colorHex,
      if (mode != null) 'mode': mode,
      if (note != null) 'note': note,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (archivedAtUtc != null) 'archived_at_utc': archivedAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HabitsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? iconKey,
    Value<String>? colorHex,
    Value<HabitMode>? mode,
    Value<String?>? note,
    Value<DateTime>? createdAtUtc,
    Value<DateTime?>? archivedAtUtc,
    Value<int>? rowid,
  }) {
    return HabitsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      colorHex: colorHex ?? this.colorHex,
      mode: mode ?? this.mode,
      note: note ?? this.note,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      archivedAtUtc: archivedAtUtc ?? this.archivedAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (iconKey.present) {
      map['icon_key'] = Variable<String>(iconKey.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(
        $HabitsTable.$convertermode.toSql(mode.value),
      );
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<int>(
        $HabitsTable.$convertercreatedAtUtc.toSql(createdAtUtc.value),
      );
    }
    if (archivedAtUtc.present) {
      map['archived_at_utc'] = Variable<int>(
        $HabitsTable.$converterarchivedAtUtc.toSql(archivedAtUtc.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('iconKey: $iconKey, ')
          ..write('colorHex: $colorHex, ')
          ..write('mode: $mode, ')
          ..write('note: $note, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('archivedAtUtc: $archivedAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HabitEventsTable extends HabitEvents
    with TableInfo<$HabitEventsTable, HabitEventRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _habitIdMeta = const VerificationMeta(
    'habitId',
  );
  @override
  late final GeneratedColumn<String> habitId = GeneratedColumn<String>(
    'habit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES habits (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<HabitEventType, String>
  eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<HabitEventType>($HabitEventsTable.$convertereventType);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> occurredAtUtc =
      GeneratedColumn<int>(
        'occurred_at_utc',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($HabitEventsTable.$converteroccurredAtUtc);
  static const VerificationMeta _localDayKeyMeta = const VerificationMeta(
    'localDayKey',
  );
  @override
  late final GeneratedColumn<String> localDayKey = GeneratedColumn<String>(
    'local_day_key',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 10,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tzOffsetMinutesAtEventMeta =
      const VerificationMeta('tzOffsetMinutesAtEvent');
  @override
  late final GeneratedColumn<int> tzOffsetMinutesAtEvent = GeneratedColumn<int>(
    'tz_offset_minutes_at_event',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<HabitEventSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<HabitEventSource>($HabitEventsTable.$convertersource);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    habitId,
    eventType,
    occurredAtUtc,
    localDayKey,
    tzOffsetMinutesAtEvent,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habit_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<HabitEventRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('habit_id')) {
      context.handle(
        _habitIdMeta,
        habitId.isAcceptableOrUnknown(data['habit_id']!, _habitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_habitIdMeta);
    }
    if (data.containsKey('local_day_key')) {
      context.handle(
        _localDayKeyMeta,
        localDayKey.isAcceptableOrUnknown(
          data['local_day_key']!,
          _localDayKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localDayKeyMeta);
    }
    if (data.containsKey('tz_offset_minutes_at_event')) {
      context.handle(
        _tzOffsetMinutesAtEventMeta,
        tzOffsetMinutesAtEvent.isAcceptableOrUnknown(
          data['tz_offset_minutes_at_event']!,
          _tzOffsetMinutesAtEventMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tzOffsetMinutesAtEventMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HabitEventRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitEventRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      habitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}habit_id'],
      )!,
      eventType: $HabitEventsTable.$convertereventType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}event_type'],
        )!,
      ),
      occurredAtUtc: $HabitEventsTable.$converteroccurredAtUtc.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}occurred_at_utc'],
        )!,
      ),
      localDayKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_day_key'],
      )!,
      tzOffsetMinutesAtEvent: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tz_offset_minutes_at_event'],
      )!,
      source: $HabitEventsTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
    );
  }

  @override
  $HabitEventsTable createAlias(String alias) {
    return $HabitEventsTable(attachedDatabase, alias);
  }

  static TypeConverter<HabitEventType, String> $convertereventType =
      const HabitEventTypeConverter();
  static TypeConverter<DateTime, int> $converteroccurredAtUtc =
      const UtcDateTimeConverter();
  static TypeConverter<HabitEventSource, String> $convertersource =
      const HabitEventSourceConverter();
}

class HabitEventRecord extends DataClass
    implements Insertable<HabitEventRecord> {
  final String id;
  final String habitId;
  final HabitEventType eventType;
  final DateTime occurredAtUtc;
  final String localDayKey;
  final int tzOffsetMinutesAtEvent;
  final HabitEventSource source;
  const HabitEventRecord({
    required this.id,
    required this.habitId,
    required this.eventType,
    required this.occurredAtUtc,
    required this.localDayKey,
    required this.tzOffsetMinutesAtEvent,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['habit_id'] = Variable<String>(habitId);
    {
      map['event_type'] = Variable<String>(
        $HabitEventsTable.$convertereventType.toSql(eventType),
      );
    }
    {
      map['occurred_at_utc'] = Variable<int>(
        $HabitEventsTable.$converteroccurredAtUtc.toSql(occurredAtUtc),
      );
    }
    map['local_day_key'] = Variable<String>(localDayKey);
    map['tz_offset_minutes_at_event'] = Variable<int>(tzOffsetMinutesAtEvent);
    {
      map['source'] = Variable<String>(
        $HabitEventsTable.$convertersource.toSql(source),
      );
    }
    return map;
  }

  HabitEventsCompanion toCompanion(bool nullToAbsent) {
    return HabitEventsCompanion(
      id: Value(id),
      habitId: Value(habitId),
      eventType: Value(eventType),
      occurredAtUtc: Value(occurredAtUtc),
      localDayKey: Value(localDayKey),
      tzOffsetMinutesAtEvent: Value(tzOffsetMinutesAtEvent),
      source: Value(source),
    );
  }

  factory HabitEventRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitEventRecord(
      id: serializer.fromJson<String>(json['id']),
      habitId: serializer.fromJson<String>(json['habitId']),
      eventType: serializer.fromJson<HabitEventType>(json['eventType']),
      occurredAtUtc: serializer.fromJson<DateTime>(json['occurredAtUtc']),
      localDayKey: serializer.fromJson<String>(json['localDayKey']),
      tzOffsetMinutesAtEvent: serializer.fromJson<int>(
        json['tzOffsetMinutesAtEvent'],
      ),
      source: serializer.fromJson<HabitEventSource>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'habitId': serializer.toJson<String>(habitId),
      'eventType': serializer.toJson<HabitEventType>(eventType),
      'occurredAtUtc': serializer.toJson<DateTime>(occurredAtUtc),
      'localDayKey': serializer.toJson<String>(localDayKey),
      'tzOffsetMinutesAtEvent': serializer.toJson<int>(tzOffsetMinutesAtEvent),
      'source': serializer.toJson<HabitEventSource>(source),
    };
  }

  HabitEventRecord copyWith({
    String? id,
    String? habitId,
    HabitEventType? eventType,
    DateTime? occurredAtUtc,
    String? localDayKey,
    int? tzOffsetMinutesAtEvent,
    HabitEventSource? source,
  }) => HabitEventRecord(
    id: id ?? this.id,
    habitId: habitId ?? this.habitId,
    eventType: eventType ?? this.eventType,
    occurredAtUtc: occurredAtUtc ?? this.occurredAtUtc,
    localDayKey: localDayKey ?? this.localDayKey,
    tzOffsetMinutesAtEvent:
        tzOffsetMinutesAtEvent ?? this.tzOffsetMinutesAtEvent,
    source: source ?? this.source,
  );
  HabitEventRecord copyWithCompanion(HabitEventsCompanion data) {
    return HabitEventRecord(
      id: data.id.present ? data.id.value : this.id,
      habitId: data.habitId.present ? data.habitId.value : this.habitId,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      occurredAtUtc: data.occurredAtUtc.present
          ? data.occurredAtUtc.value
          : this.occurredAtUtc,
      localDayKey: data.localDayKey.present
          ? data.localDayKey.value
          : this.localDayKey,
      tzOffsetMinutesAtEvent: data.tzOffsetMinutesAtEvent.present
          ? data.tzOffsetMinutesAtEvent.value
          : this.tzOffsetMinutesAtEvent,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitEventRecord(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('eventType: $eventType, ')
          ..write('occurredAtUtc: $occurredAtUtc, ')
          ..write('localDayKey: $localDayKey, ')
          ..write('tzOffsetMinutesAtEvent: $tzOffsetMinutesAtEvent, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    habitId,
    eventType,
    occurredAtUtc,
    localDayKey,
    tzOffsetMinutesAtEvent,
    source,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitEventRecord &&
          other.id == this.id &&
          other.habitId == this.habitId &&
          other.eventType == this.eventType &&
          other.occurredAtUtc == this.occurredAtUtc &&
          other.localDayKey == this.localDayKey &&
          other.tzOffsetMinutesAtEvent == this.tzOffsetMinutesAtEvent &&
          other.source == this.source);
}

class HabitEventsCompanion extends UpdateCompanion<HabitEventRecord> {
  final Value<String> id;
  final Value<String> habitId;
  final Value<HabitEventType> eventType;
  final Value<DateTime> occurredAtUtc;
  final Value<String> localDayKey;
  final Value<int> tzOffsetMinutesAtEvent;
  final Value<HabitEventSource> source;
  final Value<int> rowid;
  const HabitEventsCompanion({
    this.id = const Value.absent(),
    this.habitId = const Value.absent(),
    this.eventType = const Value.absent(),
    this.occurredAtUtc = const Value.absent(),
    this.localDayKey = const Value.absent(),
    this.tzOffsetMinutesAtEvent = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HabitEventsCompanion.insert({
    required String id,
    required String habitId,
    required HabitEventType eventType,
    required DateTime occurredAtUtc,
    required String localDayKey,
    required int tzOffsetMinutesAtEvent,
    required HabitEventSource source,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       habitId = Value(habitId),
       eventType = Value(eventType),
       occurredAtUtc = Value(occurredAtUtc),
       localDayKey = Value(localDayKey),
       tzOffsetMinutesAtEvent = Value(tzOffsetMinutesAtEvent),
       source = Value(source);
  static Insertable<HabitEventRecord> custom({
    Expression<String>? id,
    Expression<String>? habitId,
    Expression<String>? eventType,
    Expression<int>? occurredAtUtc,
    Expression<String>? localDayKey,
    Expression<int>? tzOffsetMinutesAtEvent,
    Expression<String>? source,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (habitId != null) 'habit_id': habitId,
      if (eventType != null) 'event_type': eventType,
      if (occurredAtUtc != null) 'occurred_at_utc': occurredAtUtc,
      if (localDayKey != null) 'local_day_key': localDayKey,
      if (tzOffsetMinutesAtEvent != null)
        'tz_offset_minutes_at_event': tzOffsetMinutesAtEvent,
      if (source != null) 'source': source,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HabitEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? habitId,
    Value<HabitEventType>? eventType,
    Value<DateTime>? occurredAtUtc,
    Value<String>? localDayKey,
    Value<int>? tzOffsetMinutesAtEvent,
    Value<HabitEventSource>? source,
    Value<int>? rowid,
  }) {
    return HabitEventsCompanion(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      eventType: eventType ?? this.eventType,
      occurredAtUtc: occurredAtUtc ?? this.occurredAtUtc,
      localDayKey: localDayKey ?? this.localDayKey,
      tzOffsetMinutesAtEvent:
          tzOffsetMinutesAtEvent ?? this.tzOffsetMinutesAtEvent,
      source: source ?? this.source,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (habitId.present) {
      map['habit_id'] = Variable<String>(habitId.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(
        $HabitEventsTable.$convertereventType.toSql(eventType.value),
      );
    }
    if (occurredAtUtc.present) {
      map['occurred_at_utc'] = Variable<int>(
        $HabitEventsTable.$converteroccurredAtUtc.toSql(occurredAtUtc.value),
      );
    }
    if (localDayKey.present) {
      map['local_day_key'] = Variable<String>(localDayKey.value);
    }
    if (tzOffsetMinutesAtEvent.present) {
      map['tz_offset_minutes_at_event'] = Variable<int>(
        tzOffsetMinutesAtEvent.value,
      );
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $HabitEventsTable.$convertersource.toSql(source.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitEventsCompanion(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('eventType: $eventType, ')
          ..write('occurredAtUtc: $occurredAtUtc, ')
          ..write('localDayKey: $localDayKey, ')
          ..write('tzOffsetMinutesAtEvent: $tzOffsetMinutesAtEvent, ')
          ..write('source: $source, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTableTable extends AppSettingsTable
    with TableInfo<$AppSettingsTableTable, AppSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _singletonIdMeta = const VerificationMeta(
    'singletonId',
  );
  @override
  late final GeneratedColumn<int> singletonId = GeneratedColumn<int>(
    'singleton_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: () => 1,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AppWeekStart, String> weekStart =
      GeneratedColumn<String>(
        'week_start',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('monday'),
      ).withConverter<AppWeekStart>($AppSettingsTableTable.$converterweekStart);
  @override
  late final GeneratedColumnWithTypeConverter<AppTimeFormat, String>
  timeFormat = GeneratedColumn<String>(
    'time_format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('12h'),
  ).withConverter<AppTimeFormat>($AppSettingsTableTable.$convertertimeFormat);
  static const VerificationMeta _remindersEnabledMeta = const VerificationMeta(
    'remindersEnabled',
  );
  @override
  late final GeneratedColumn<bool> remindersEnabled = GeneratedColumn<bool>(
    'reminders_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("reminders_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    singletonId,
    weekStart,
    timeFormat,
    remindersEnabled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('singleton_id')) {
      context.handle(
        _singletonIdMeta,
        singletonId.isAcceptableOrUnknown(
          data['singleton_id']!,
          _singletonIdMeta,
        ),
      );
    }
    if (data.containsKey('reminders_enabled')) {
      context.handle(
        _remindersEnabledMeta,
        remindersEnabled.isAcceptableOrUnknown(
          data['reminders_enabled']!,
          _remindersEnabledMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {singletonId};
  @override
  AppSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingsRow(
      singletonId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}singleton_id'],
      )!,
      weekStart: $AppSettingsTableTable.$converterweekStart.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}week_start'],
        )!,
      ),
      timeFormat: $AppSettingsTableTable.$convertertimeFormat.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}time_format'],
        )!,
      ),
      remindersEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reminders_enabled'],
      )!,
    );
  }

  @override
  $AppSettingsTableTable createAlias(String alias) {
    return $AppSettingsTableTable(attachedDatabase, alias);
  }

  static TypeConverter<AppWeekStart, String> $converterweekStart =
      const AppWeekStartConverter();
  static TypeConverter<AppTimeFormat, String> $convertertimeFormat =
      const AppTimeFormatConverter();
}

class AppSettingsRow extends DataClass implements Insertable<AppSettingsRow> {
  final int singletonId;
  final AppWeekStart weekStart;
  final AppTimeFormat timeFormat;
  final bool remindersEnabled;
  const AppSettingsRow({
    required this.singletonId,
    required this.weekStart,
    required this.timeFormat,
    required this.remindersEnabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['singleton_id'] = Variable<int>(singletonId);
    {
      map['week_start'] = Variable<String>(
        $AppSettingsTableTable.$converterweekStart.toSql(weekStart),
      );
    }
    {
      map['time_format'] = Variable<String>(
        $AppSettingsTableTable.$convertertimeFormat.toSql(timeFormat),
      );
    }
    map['reminders_enabled'] = Variable<bool>(remindersEnabled);
    return map;
  }

  AppSettingsTableCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsTableCompanion(
      singletonId: Value(singletonId),
      weekStart: Value(weekStart),
      timeFormat: Value(timeFormat),
      remindersEnabled: Value(remindersEnabled),
    );
  }

  factory AppSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingsRow(
      singletonId: serializer.fromJson<int>(json['singletonId']),
      weekStart: serializer.fromJson<AppWeekStart>(json['weekStart']),
      timeFormat: serializer.fromJson<AppTimeFormat>(json['timeFormat']),
      remindersEnabled: serializer.fromJson<bool>(json['remindersEnabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'singletonId': serializer.toJson<int>(singletonId),
      'weekStart': serializer.toJson<AppWeekStart>(weekStart),
      'timeFormat': serializer.toJson<AppTimeFormat>(timeFormat),
      'remindersEnabled': serializer.toJson<bool>(remindersEnabled),
    };
  }

  AppSettingsRow copyWith({
    int? singletonId,
    AppWeekStart? weekStart,
    AppTimeFormat? timeFormat,
    bool? remindersEnabled,
  }) => AppSettingsRow(
    singletonId: singletonId ?? this.singletonId,
    weekStart: weekStart ?? this.weekStart,
    timeFormat: timeFormat ?? this.timeFormat,
    remindersEnabled: remindersEnabled ?? this.remindersEnabled,
  );
  AppSettingsRow copyWithCompanion(AppSettingsTableCompanion data) {
    return AppSettingsRow(
      singletonId: data.singletonId.present
          ? data.singletonId.value
          : this.singletonId,
      weekStart: data.weekStart.present ? data.weekStart.value : this.weekStart,
      timeFormat: data.timeFormat.present
          ? data.timeFormat.value
          : this.timeFormat,
      remindersEnabled: data.remindersEnabled.present
          ? data.remindersEnabled.value
          : this.remindersEnabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsRow(')
          ..write('singletonId: $singletonId, ')
          ..write('weekStart: $weekStart, ')
          ..write('timeFormat: $timeFormat, ')
          ..write('remindersEnabled: $remindersEnabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(singletonId, weekStart, timeFormat, remindersEnabled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingsRow &&
          other.singletonId == this.singletonId &&
          other.weekStart == this.weekStart &&
          other.timeFormat == this.timeFormat &&
          other.remindersEnabled == this.remindersEnabled);
}

class AppSettingsTableCompanion extends UpdateCompanion<AppSettingsRow> {
  final Value<int> singletonId;
  final Value<AppWeekStart> weekStart;
  final Value<AppTimeFormat> timeFormat;
  final Value<bool> remindersEnabled;
  const AppSettingsTableCompanion({
    this.singletonId = const Value.absent(),
    this.weekStart = const Value.absent(),
    this.timeFormat = const Value.absent(),
    this.remindersEnabled = const Value.absent(),
  });
  AppSettingsTableCompanion.insert({
    this.singletonId = const Value.absent(),
    this.weekStart = const Value.absent(),
    this.timeFormat = const Value.absent(),
    this.remindersEnabled = const Value.absent(),
  });
  static Insertable<AppSettingsRow> custom({
    Expression<int>? singletonId,
    Expression<String>? weekStart,
    Expression<String>? timeFormat,
    Expression<bool>? remindersEnabled,
  }) {
    return RawValuesInsertable({
      if (singletonId != null) 'singleton_id': singletonId,
      if (weekStart != null) 'week_start': weekStart,
      if (timeFormat != null) 'time_format': timeFormat,
      if (remindersEnabled != null) 'reminders_enabled': remindersEnabled,
    });
  }

  AppSettingsTableCompanion copyWith({
    Value<int>? singletonId,
    Value<AppWeekStart>? weekStart,
    Value<AppTimeFormat>? timeFormat,
    Value<bool>? remindersEnabled,
  }) {
    return AppSettingsTableCompanion(
      singletonId: singletonId ?? this.singletonId,
      weekStart: weekStart ?? this.weekStart,
      timeFormat: timeFormat ?? this.timeFormat,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (singletonId.present) {
      map['singleton_id'] = Variable<int>(singletonId.value);
    }
    if (weekStart.present) {
      map['week_start'] = Variable<String>(
        $AppSettingsTableTable.$converterweekStart.toSql(weekStart.value),
      );
    }
    if (timeFormat.present) {
      map['time_format'] = Variable<String>(
        $AppSettingsTableTable.$convertertimeFormat.toSql(timeFormat.value),
      );
    }
    if (remindersEnabled.present) {
      map['reminders_enabled'] = Variable<bool>(remindersEnabled.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsTableCompanion(')
          ..write('singletonId: $singletonId, ')
          ..write('weekStart: $weekStart, ')
          ..write('timeFormat: $timeFormat, ')
          ..write('remindersEnabled: $remindersEnabled')
          ..write(')'))
        .toString();
  }
}

class $HabitRemindersTable extends HabitReminders
    with TableInfo<$HabitRemindersTable, HabitReminderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitRemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _habitIdMeta = const VerificationMeta(
    'habitId',
  );
  @override
  late final GeneratedColumn<String> habitId = GeneratedColumn<String>(
    'habit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES habits (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _isEnabledMeta = const VerificationMeta(
    'isEnabled',
  );
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
    'is_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _reminderTimeMinutesMeta =
      const VerificationMeta('reminderTimeMinutes');
  @override
  late final GeneratedColumn<int> reminderTimeMinutes = GeneratedColumn<int>(
    'reminder_time_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1200),
  );
  @override
  List<GeneratedColumn> get $columns => [
    habitId,
    isEnabled,
    reminderTimeMinutes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habit_reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<HabitReminderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('habit_id')) {
      context.handle(
        _habitIdMeta,
        habitId.isAcceptableOrUnknown(data['habit_id']!, _habitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_habitIdMeta);
    }
    if (data.containsKey('is_enabled')) {
      context.handle(
        _isEnabledMeta,
        isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta),
      );
    }
    if (data.containsKey('reminder_time_minutes')) {
      context.handle(
        _reminderTimeMinutesMeta,
        reminderTimeMinutes.isAcceptableOrUnknown(
          data['reminder_time_minutes']!,
          _reminderTimeMinutesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {habitId};
  @override
  HabitReminderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitReminderRow(
      habitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}habit_id'],
      )!,
      isEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_enabled'],
      )!,
      reminderTimeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_time_minutes'],
      )!,
    );
  }

  @override
  $HabitRemindersTable createAlias(String alias) {
    return $HabitRemindersTable(attachedDatabase, alias);
  }
}

class HabitReminderRow extends DataClass
    implements Insertable<HabitReminderRow> {
  final String habitId;
  final bool isEnabled;
  final int reminderTimeMinutes;
  const HabitReminderRow({
    required this.habitId,
    required this.isEnabled,
    required this.reminderTimeMinutes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['habit_id'] = Variable<String>(habitId);
    map['is_enabled'] = Variable<bool>(isEnabled);
    map['reminder_time_minutes'] = Variable<int>(reminderTimeMinutes);
    return map;
  }

  HabitRemindersCompanion toCompanion(bool nullToAbsent) {
    return HabitRemindersCompanion(
      habitId: Value(habitId),
      isEnabled: Value(isEnabled),
      reminderTimeMinutes: Value(reminderTimeMinutes),
    );
  }

  factory HabitReminderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitReminderRow(
      habitId: serializer.fromJson<String>(json['habitId']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
      reminderTimeMinutes: serializer.fromJson<int>(
        json['reminderTimeMinutes'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'habitId': serializer.toJson<String>(habitId),
      'isEnabled': serializer.toJson<bool>(isEnabled),
      'reminderTimeMinutes': serializer.toJson<int>(reminderTimeMinutes),
    };
  }

  HabitReminderRow copyWith({
    String? habitId,
    bool? isEnabled,
    int? reminderTimeMinutes,
  }) => HabitReminderRow(
    habitId: habitId ?? this.habitId,
    isEnabled: isEnabled ?? this.isEnabled,
    reminderTimeMinutes: reminderTimeMinutes ?? this.reminderTimeMinutes,
  );
  HabitReminderRow copyWithCompanion(HabitRemindersCompanion data) {
    return HabitReminderRow(
      habitId: data.habitId.present ? data.habitId.value : this.habitId,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
      reminderTimeMinutes: data.reminderTimeMinutes.present
          ? data.reminderTimeMinutes.value
          : this.reminderTimeMinutes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitReminderRow(')
          ..write('habitId: $habitId, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('reminderTimeMinutes: $reminderTimeMinutes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(habitId, isEnabled, reminderTimeMinutes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitReminderRow &&
          other.habitId == this.habitId &&
          other.isEnabled == this.isEnabled &&
          other.reminderTimeMinutes == this.reminderTimeMinutes);
}

class HabitRemindersCompanion extends UpdateCompanion<HabitReminderRow> {
  final Value<String> habitId;
  final Value<bool> isEnabled;
  final Value<int> reminderTimeMinutes;
  final Value<int> rowid;
  const HabitRemindersCompanion({
    this.habitId = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.reminderTimeMinutes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HabitRemindersCompanion.insert({
    required String habitId,
    this.isEnabled = const Value.absent(),
    this.reminderTimeMinutes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : habitId = Value(habitId);
  static Insertable<HabitReminderRow> custom({
    Expression<String>? habitId,
    Expression<bool>? isEnabled,
    Expression<int>? reminderTimeMinutes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (habitId != null) 'habit_id': habitId,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (reminderTimeMinutes != null)
        'reminder_time_minutes': reminderTimeMinutes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HabitRemindersCompanion copyWith({
    Value<String>? habitId,
    Value<bool>? isEnabled,
    Value<int>? reminderTimeMinutes,
    Value<int>? rowid,
  }) {
    return HabitRemindersCompanion(
      habitId: habitId ?? this.habitId,
      isEnabled: isEnabled ?? this.isEnabled,
      reminderTimeMinutes: reminderTimeMinutes ?? this.reminderTimeMinutes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (habitId.present) {
      map['habit_id'] = Variable<String>(habitId.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (reminderTimeMinutes.present) {
      map['reminder_time_minutes'] = Variable<int>(reminderTimeMinutes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitRemindersCompanion(')
          ..write('habitId: $habitId, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('reminderTimeMinutes: $reminderTimeMinutes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $HabitsTable habits = $HabitsTable(this);
  late final $HabitEventsTable habitEvents = $HabitEventsTable(this);
  late final $AppSettingsTableTable appSettingsTable = $AppSettingsTableTable(
    this,
  );
  late final $HabitRemindersTable habitReminders = $HabitRemindersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    habits,
    habitEvents,
    appSettingsTable,
    habitReminders,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'habits',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('habit_events', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'habits',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('habit_reminders', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$HabitsTableCreateCompanionBuilder =
    HabitsCompanion Function({
      required String id,
      required String name,
      required String iconKey,
      required String colorHex,
      required HabitMode mode,
      Value<String?> note,
      required DateTime createdAtUtc,
      Value<DateTime?> archivedAtUtc,
      Value<int> rowid,
    });
typedef $$HabitsTableUpdateCompanionBuilder =
    HabitsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> iconKey,
      Value<String> colorHex,
      Value<HabitMode> mode,
      Value<String?> note,
      Value<DateTime> createdAtUtc,
      Value<DateTime?> archivedAtUtc,
      Value<int> rowid,
    });

final class $$HabitsTableReferences
    extends BaseReferences<_$AppDatabase, $HabitsTable, HabitRecord> {
  $$HabitsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$HabitEventsTable, List<HabitEventRecord>>
  _habitEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.habitEvents,
    aliasName: $_aliasNameGenerator(db.habits.id, db.habitEvents.habitId),
  );

  $$HabitEventsTableProcessedTableManager get habitEventsRefs {
    final manager = $$HabitEventsTableTableManager(
      $_db,
      $_db.habitEvents,
    ).filter((f) => f.habitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_habitEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$HabitRemindersTable, List<HabitReminderRow>>
  _habitRemindersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.habitReminders,
    aliasName: $_aliasNameGenerator(db.habits.id, db.habitReminders.habitId),
  );

  $$HabitRemindersTableProcessedTableManager get habitRemindersRefs {
    final manager = $$HabitRemindersTableTableManager(
      $_db,
      $_db.habitReminders,
    ).filter((f) => f.habitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_habitRemindersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$HabitsTableFilterComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<HabitMode, HabitMode, String> get mode =>
      $composableBuilder(
        column: $table.mode,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAtUtc =>
      $composableBuilder(
        column: $table.createdAtUtc,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get archivedAtUtc =>
      $composableBuilder(
        column: $table.archivedAtUtc,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  Expression<bool> habitEventsRefs(
    Expression<bool> Function($$HabitEventsTableFilterComposer f) f,
  ) {
    final $$HabitEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habitEvents,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitEventsTableFilterComposer(
            $db: $db,
            $table: $db.habitEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> habitRemindersRefs(
    Expression<bool> Function($$HabitRemindersTableFilterComposer f) f,
  ) {
    final $$HabitRemindersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habitReminders,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitRemindersTableFilterComposer(
            $db: $db,
            $table: $db.habitReminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HabitsTableOrderingComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get archivedAtUtc => $composableBuilder(
    column: $table.archivedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HabitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get iconKey =>
      $composableBuilder(column: $table.iconKey, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumnWithTypeConverter<HabitMode, String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAtUtc =>
      $composableBuilder(
        column: $table.createdAtUtc,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime?, int> get archivedAtUtc =>
      $composableBuilder(
        column: $table.archivedAtUtc,
        builder: (column) => column,
      );

  Expression<T> habitEventsRefs<T extends Object>(
    Expression<T> Function($$HabitEventsTableAnnotationComposer a) f,
  ) {
    final $$HabitEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habitEvents,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.habitEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> habitRemindersRefs<T extends Object>(
    Expression<T> Function($$HabitRemindersTableAnnotationComposer a) f,
  ) {
    final $$HabitRemindersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habitReminders,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitRemindersTableAnnotationComposer(
            $db: $db,
            $table: $db.habitReminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HabitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HabitsTable,
          HabitRecord,
          $$HabitsTableFilterComposer,
          $$HabitsTableOrderingComposer,
          $$HabitsTableAnnotationComposer,
          $$HabitsTableCreateCompanionBuilder,
          $$HabitsTableUpdateCompanionBuilder,
          (HabitRecord, $$HabitsTableReferences),
          HabitRecord,
          PrefetchHooks Function({
            bool habitEventsRefs,
            bool habitRemindersRefs,
          })
        > {
  $$HabitsTableTableManager(_$AppDatabase db, $HabitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> iconKey = const Value.absent(),
                Value<String> colorHex = const Value.absent(),
                Value<HabitMode> mode = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAtUtc = const Value.absent(),
                Value<DateTime?> archivedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitsCompanion(
                id: id,
                name: name,
                iconKey: iconKey,
                colorHex: colorHex,
                mode: mode,
                note: note,
                createdAtUtc: createdAtUtc,
                archivedAtUtc: archivedAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String iconKey,
                required String colorHex,
                required HabitMode mode,
                Value<String?> note = const Value.absent(),
                required DateTime createdAtUtc,
                Value<DateTime?> archivedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitsCompanion.insert(
                id: id,
                name: name,
                iconKey: iconKey,
                colorHex: colorHex,
                mode: mode,
                note: note,
                createdAtUtc: createdAtUtc,
                archivedAtUtc: archivedAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$HabitsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({habitEventsRefs = false, habitRemindersRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (habitEventsRefs) db.habitEvents,
                    if (habitRemindersRefs) db.habitReminders,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (habitEventsRefs)
                        await $_getPrefetchedData<
                          HabitRecord,
                          $HabitsTable,
                          HabitEventRecord
                        >(
                          currentTable: table,
                          referencedTable: $$HabitsTableReferences
                              ._habitEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HabitsTableReferences(
                                db,
                                table,
                                p0,
                              ).habitEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.habitId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (habitRemindersRefs)
                        await $_getPrefetchedData<
                          HabitRecord,
                          $HabitsTable,
                          HabitReminderRow
                        >(
                          currentTable: table,
                          referencedTable: $$HabitsTableReferences
                              ._habitRemindersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HabitsTableReferences(
                                db,
                                table,
                                p0,
                              ).habitRemindersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.habitId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$HabitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HabitsTable,
      HabitRecord,
      $$HabitsTableFilterComposer,
      $$HabitsTableOrderingComposer,
      $$HabitsTableAnnotationComposer,
      $$HabitsTableCreateCompanionBuilder,
      $$HabitsTableUpdateCompanionBuilder,
      (HabitRecord, $$HabitsTableReferences),
      HabitRecord,
      PrefetchHooks Function({bool habitEventsRefs, bool habitRemindersRefs})
    >;
typedef $$HabitEventsTableCreateCompanionBuilder =
    HabitEventsCompanion Function({
      required String id,
      required String habitId,
      required HabitEventType eventType,
      required DateTime occurredAtUtc,
      required String localDayKey,
      required int tzOffsetMinutesAtEvent,
      required HabitEventSource source,
      Value<int> rowid,
    });
typedef $$HabitEventsTableUpdateCompanionBuilder =
    HabitEventsCompanion Function({
      Value<String> id,
      Value<String> habitId,
      Value<HabitEventType> eventType,
      Value<DateTime> occurredAtUtc,
      Value<String> localDayKey,
      Value<int> tzOffsetMinutesAtEvent,
      Value<HabitEventSource> source,
      Value<int> rowid,
    });

final class $$HabitEventsTableReferences
    extends BaseReferences<_$AppDatabase, $HabitEventsTable, HabitEventRecord> {
  $$HabitEventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HabitsTable _habitIdTable(_$AppDatabase db) => db.habits.createAlias(
    $_aliasNameGenerator(db.habitEvents.habitId, db.habits.id),
  );

  $$HabitsTableProcessedTableManager get habitId {
    final $_column = $_itemColumn<String>('habit_id')!;

    final manager = $$HabitsTableTableManager(
      $_db,
      $_db.habits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_habitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$HabitEventsTableFilterComposer
    extends Composer<_$AppDatabase, $HabitEventsTable> {
  $$HabitEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<HabitEventType, HabitEventType, String>
  get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get occurredAtUtc =>
      $composableBuilder(
        column: $table.occurredAtUtc,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get localDayKey => $composableBuilder(
    column: $table.localDayKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tzOffsetMinutesAtEvent => $composableBuilder(
    column: $table.tzOffsetMinutesAtEvent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<HabitEventSource, HabitEventSource, String>
  get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$HabitsTableFilterComposer get habitId {
    final $$HabitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableFilterComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $HabitEventsTable> {
  $$HabitEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get occurredAtUtc => $composableBuilder(
    column: $table.occurredAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localDayKey => $composableBuilder(
    column: $table.localDayKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tzOffsetMinutesAtEvent => $composableBuilder(
    column: $table.tzOffsetMinutesAtEvent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  $$HabitsTableOrderingComposer get habitId {
    final $$HabitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableOrderingComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HabitEventsTable> {
  $$HabitEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<HabitEventType, String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get occurredAtUtc =>
      $composableBuilder(
        column: $table.occurredAtUtc,
        builder: (column) => column,
      );

  GeneratedColumn<String> get localDayKey => $composableBuilder(
    column: $table.localDayKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tzOffsetMinutesAtEvent => $composableBuilder(
    column: $table.tzOffsetMinutesAtEvent,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<HabitEventSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  $$HabitsTableAnnotationComposer get habitId {
    final $$HabitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableAnnotationComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HabitEventsTable,
          HabitEventRecord,
          $$HabitEventsTableFilterComposer,
          $$HabitEventsTableOrderingComposer,
          $$HabitEventsTableAnnotationComposer,
          $$HabitEventsTableCreateCompanionBuilder,
          $$HabitEventsTableUpdateCompanionBuilder,
          (HabitEventRecord, $$HabitEventsTableReferences),
          HabitEventRecord,
          PrefetchHooks Function({bool habitId})
        > {
  $$HabitEventsTableTableManager(_$AppDatabase db, $HabitEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> habitId = const Value.absent(),
                Value<HabitEventType> eventType = const Value.absent(),
                Value<DateTime> occurredAtUtc = const Value.absent(),
                Value<String> localDayKey = const Value.absent(),
                Value<int> tzOffsetMinutesAtEvent = const Value.absent(),
                Value<HabitEventSource> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitEventsCompanion(
                id: id,
                habitId: habitId,
                eventType: eventType,
                occurredAtUtc: occurredAtUtc,
                localDayKey: localDayKey,
                tzOffsetMinutesAtEvent: tzOffsetMinutesAtEvent,
                source: source,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String habitId,
                required HabitEventType eventType,
                required DateTime occurredAtUtc,
                required String localDayKey,
                required int tzOffsetMinutesAtEvent,
                required HabitEventSource source,
                Value<int> rowid = const Value.absent(),
              }) => HabitEventsCompanion.insert(
                id: id,
                habitId: habitId,
                eventType: eventType,
                occurredAtUtc: occurredAtUtc,
                localDayKey: localDayKey,
                tzOffsetMinutesAtEvent: tzOffsetMinutesAtEvent,
                source: source,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$HabitEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({habitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (habitId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.habitId,
                                referencedTable: $$HabitEventsTableReferences
                                    ._habitIdTable(db),
                                referencedColumn: $$HabitEventsTableReferences
                                    ._habitIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$HabitEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HabitEventsTable,
      HabitEventRecord,
      $$HabitEventsTableFilterComposer,
      $$HabitEventsTableOrderingComposer,
      $$HabitEventsTableAnnotationComposer,
      $$HabitEventsTableCreateCompanionBuilder,
      $$HabitEventsTableUpdateCompanionBuilder,
      (HabitEventRecord, $$HabitEventsTableReferences),
      HabitEventRecord,
      PrefetchHooks Function({bool habitId})
    >;
typedef $$AppSettingsTableTableCreateCompanionBuilder =
    AppSettingsTableCompanion Function({
      Value<int> singletonId,
      Value<AppWeekStart> weekStart,
      Value<AppTimeFormat> timeFormat,
      Value<bool> remindersEnabled,
    });
typedef $$AppSettingsTableTableUpdateCompanionBuilder =
    AppSettingsTableCompanion Function({
      Value<int> singletonId,
      Value<AppWeekStart> weekStart,
      Value<AppTimeFormat> timeFormat,
      Value<bool> remindersEnabled,
    });

class $$AppSettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTableTable> {
  $$AppSettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get singletonId => $composableBuilder(
    column: $table.singletonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AppWeekStart, AppWeekStart, String>
  get weekStart => $composableBuilder(
    column: $table.weekStart,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<AppTimeFormat, AppTimeFormat, String>
  get timeFormat => $composableBuilder(
    column: $table.timeFormat,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get remindersEnabled => $composableBuilder(
    column: $table.remindersEnabled,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTableTable> {
  $$AppSettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get singletonId => $composableBuilder(
    column: $table.singletonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weekStart => $composableBuilder(
    column: $table.weekStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeFormat => $composableBuilder(
    column: $table.timeFormat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get remindersEnabled => $composableBuilder(
    column: $table.remindersEnabled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTableTable> {
  $$AppSettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get singletonId => $composableBuilder(
    column: $table.singletonId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<AppWeekStart, String> get weekStart =>
      $composableBuilder(column: $table.weekStart, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AppTimeFormat, String> get timeFormat =>
      $composableBuilder(
        column: $table.timeFormat,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get remindersEnabled => $composableBuilder(
    column: $table.remindersEnabled,
    builder: (column) => column,
  );
}

class $$AppSettingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTableTable,
          AppSettingsRow,
          $$AppSettingsTableTableFilterComposer,
          $$AppSettingsTableTableOrderingComposer,
          $$AppSettingsTableTableAnnotationComposer,
          $$AppSettingsTableTableCreateCompanionBuilder,
          $$AppSettingsTableTableUpdateCompanionBuilder,
          (
            AppSettingsRow,
            BaseReferences<
              _$AppDatabase,
              $AppSettingsTableTable,
              AppSettingsRow
            >,
          ),
          AppSettingsRow,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableTableManager(
    _$AppDatabase db,
    $AppSettingsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> singletonId = const Value.absent(),
                Value<AppWeekStart> weekStart = const Value.absent(),
                Value<AppTimeFormat> timeFormat = const Value.absent(),
                Value<bool> remindersEnabled = const Value.absent(),
              }) => AppSettingsTableCompanion(
                singletonId: singletonId,
                weekStart: weekStart,
                timeFormat: timeFormat,
                remindersEnabled: remindersEnabled,
              ),
          createCompanionCallback:
              ({
                Value<int> singletonId = const Value.absent(),
                Value<AppWeekStart> weekStart = const Value.absent(),
                Value<AppTimeFormat> timeFormat = const Value.absent(),
                Value<bool> remindersEnabled = const Value.absent(),
              }) => AppSettingsTableCompanion.insert(
                singletonId: singletonId,
                weekStart: weekStart,
                timeFormat: timeFormat,
                remindersEnabled: remindersEnabled,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTableTable,
      AppSettingsRow,
      $$AppSettingsTableTableFilterComposer,
      $$AppSettingsTableTableOrderingComposer,
      $$AppSettingsTableTableAnnotationComposer,
      $$AppSettingsTableTableCreateCompanionBuilder,
      $$AppSettingsTableTableUpdateCompanionBuilder,
      (
        AppSettingsRow,
        BaseReferences<_$AppDatabase, $AppSettingsTableTable, AppSettingsRow>,
      ),
      AppSettingsRow,
      PrefetchHooks Function()
    >;
typedef $$HabitRemindersTableCreateCompanionBuilder =
    HabitRemindersCompanion Function({
      required String habitId,
      Value<bool> isEnabled,
      Value<int> reminderTimeMinutes,
      Value<int> rowid,
    });
typedef $$HabitRemindersTableUpdateCompanionBuilder =
    HabitRemindersCompanion Function({
      Value<String> habitId,
      Value<bool> isEnabled,
      Value<int> reminderTimeMinutes,
      Value<int> rowid,
    });

final class $$HabitRemindersTableReferences
    extends
        BaseReferences<_$AppDatabase, $HabitRemindersTable, HabitReminderRow> {
  $$HabitRemindersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $HabitsTable _habitIdTable(_$AppDatabase db) => db.habits.createAlias(
    $_aliasNameGenerator(db.habitReminders.habitId, db.habits.id),
  );

  $$HabitsTableProcessedTableManager get habitId {
    final $_column = $_itemColumn<String>('habit_id')!;

    final manager = $$HabitsTableTableManager(
      $_db,
      $_db.habits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_habitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$HabitRemindersTableFilterComposer
    extends Composer<_$AppDatabase, $HabitRemindersTable> {
  $$HabitRemindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderTimeMinutes => $composableBuilder(
    column: $table.reminderTimeMinutes,
    builder: (column) => ColumnFilters(column),
  );

  $$HabitsTableFilterComposer get habitId {
    final $$HabitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableFilterComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitRemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $HabitRemindersTable> {
  $$HabitRemindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderTimeMinutes => $composableBuilder(
    column: $table.reminderTimeMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  $$HabitsTableOrderingComposer get habitId {
    final $$HabitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableOrderingComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitRemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $HabitRemindersTable> {
  $$HabitRemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  GeneratedColumn<int> get reminderTimeMinutes => $composableBuilder(
    column: $table.reminderTimeMinutes,
    builder: (column) => column,
  );

  $$HabitsTableAnnotationComposer get habitId {
    final $$HabitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableAnnotationComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitRemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HabitRemindersTable,
          HabitReminderRow,
          $$HabitRemindersTableFilterComposer,
          $$HabitRemindersTableOrderingComposer,
          $$HabitRemindersTableAnnotationComposer,
          $$HabitRemindersTableCreateCompanionBuilder,
          $$HabitRemindersTableUpdateCompanionBuilder,
          (HabitReminderRow, $$HabitRemindersTableReferences),
          HabitReminderRow,
          PrefetchHooks Function({bool habitId})
        > {
  $$HabitRemindersTableTableManager(
    _$AppDatabase db,
    $HabitRemindersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitRemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitRemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitRemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> habitId = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<int> reminderTimeMinutes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitRemindersCompanion(
                habitId: habitId,
                isEnabled: isEnabled,
                reminderTimeMinutes: reminderTimeMinutes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String habitId,
                Value<bool> isEnabled = const Value.absent(),
                Value<int> reminderTimeMinutes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitRemindersCompanion.insert(
                habitId: habitId,
                isEnabled: isEnabled,
                reminderTimeMinutes: reminderTimeMinutes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$HabitRemindersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({habitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (habitId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.habitId,
                                referencedTable: $$HabitRemindersTableReferences
                                    ._habitIdTable(db),
                                referencedColumn:
                                    $$HabitRemindersTableReferences
                                        ._habitIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$HabitRemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HabitRemindersTable,
      HabitReminderRow,
      $$HabitRemindersTableFilterComposer,
      $$HabitRemindersTableOrderingComposer,
      $$HabitRemindersTableAnnotationComposer,
      $$HabitRemindersTableCreateCompanionBuilder,
      $$HabitRemindersTableUpdateCompanionBuilder,
      (HabitReminderRow, $$HabitRemindersTableReferences),
      HabitReminderRow,
      PrefetchHooks Function({bool habitId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$HabitsTableTableManager get habits =>
      $$HabitsTableTableManager(_db, _db.habits);
  $$HabitEventsTableTableManager get habitEvents =>
      $$HabitEventsTableTableManager(_db, _db.habitEvents);
  $$AppSettingsTableTableTableManager get appSettingsTable =>
      $$AppSettingsTableTableTableManager(_db, _db.appSettingsTable);
  $$HabitRemindersTableTableManager get habitReminders =>
      $$HabitRemindersTableTableManager(_db, _db.habitReminders);
}
