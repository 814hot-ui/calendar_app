// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CalendarEntriesTable extends CalendarEntries
    with TableInfo<$CalendarEntriesTable, CalendarEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalendarEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> emotions =
      GeneratedColumn<String>(
        'emotions',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<String>>($CalendarEntriesTable.$converteremotions);
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    content,
    emotions,
    imagePath,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calendar_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<CalendarEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CalendarEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalendarEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      emotions: $CalendarEntriesTable.$converteremotions.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}emotions'],
        )!,
      ),
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
    );
  }

  @override
  $CalendarEntriesTable createAlias(String alias) {
    return $CalendarEntriesTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $converteremotions =
      const StringListConverter();
}

class CalendarEntry extends DataClass implements Insertable<CalendarEntry> {
  final int id;
  final DateTime date;
  final String content;
  final List<String> emotions;
  final String? imagePath;
  const CalendarEntry({
    required this.id,
    required this.date,
    required this.content,
    required this.emotions,
    this.imagePath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['content'] = Variable<String>(content);
    {
      map['emotions'] = Variable<String>(
        $CalendarEntriesTable.$converteremotions.toSql(emotions),
      );
    }
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    return map;
  }

  CalendarEntriesCompanion toCompanion(bool nullToAbsent) {
    return CalendarEntriesCompanion(
      id: Value(id),
      date: Value(date),
      content: Value(content),
      emotions: Value(emotions),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
    );
  }

  factory CalendarEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalendarEntry(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      content: serializer.fromJson<String>(json['content']),
      emotions: serializer.fromJson<List<String>>(json['emotions']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'content': serializer.toJson<String>(content),
      'emotions': serializer.toJson<List<String>>(emotions),
      'imagePath': serializer.toJson<String?>(imagePath),
    };
  }

  CalendarEntry copyWith({
    int? id,
    DateTime? date,
    String? content,
    List<String>? emotions,
    Value<String?> imagePath = const Value.absent(),
  }) => CalendarEntry(
    id: id ?? this.id,
    date: date ?? this.date,
    content: content ?? this.content,
    emotions: emotions ?? this.emotions,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
  );
  CalendarEntry copyWithCompanion(CalendarEntriesCompanion data) {
    return CalendarEntry(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      content: data.content.present ? data.content.value : this.content,
      emotions: data.emotions.present ? data.emotions.value : this.emotions,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalendarEntry(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('content: $content, ')
          ..write('emotions: $emotions, ')
          ..write('imagePath: $imagePath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, content, emotions, imagePath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalendarEntry &&
          other.id == this.id &&
          other.date == this.date &&
          other.content == this.content &&
          other.emotions == this.emotions &&
          other.imagePath == this.imagePath);
}

class CalendarEntriesCompanion extends UpdateCompanion<CalendarEntry> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<String> content;
  final Value<List<String>> emotions;
  final Value<String?> imagePath;
  const CalendarEntriesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.content = const Value.absent(),
    this.emotions = const Value.absent(),
    this.imagePath = const Value.absent(),
  });
  CalendarEntriesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required String content,
    required List<String> emotions,
    this.imagePath = const Value.absent(),
  }) : date = Value(date),
       content = Value(content),
       emotions = Value(emotions);
  static Insertable<CalendarEntry> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<String>? content,
    Expression<String>? emotions,
    Expression<String>? imagePath,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (content != null) 'content': content,
      if (emotions != null) 'emotions': emotions,
      if (imagePath != null) 'image_path': imagePath,
    });
  }

  CalendarEntriesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<String>? content,
    Value<List<String>>? emotions,
    Value<String?>? imagePath,
  }) {
    return CalendarEntriesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      content: content ?? this.content,
      emotions: emotions ?? this.emotions,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (emotions.present) {
      map['emotions'] = Variable<String>(
        $CalendarEntriesTable.$converteremotions.toSql(emotions.value),
      );
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalendarEntriesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('content: $content, ')
          ..write('emotions: $emotions, ')
          ..write('imagePath: $imagePath')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CalendarEntriesTable calendarEntries = $CalendarEntriesTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [calendarEntries];
}

typedef $$CalendarEntriesTableCreateCompanionBuilder =
    CalendarEntriesCompanion Function({
      Value<int> id,
      required DateTime date,
      required String content,
      required List<String> emotions,
      Value<String?> imagePath,
    });
typedef $$CalendarEntriesTableUpdateCompanionBuilder =
    CalendarEntriesCompanion Function({
      Value<int> id,
      Value<DateTime> date,
      Value<String> content,
      Value<List<String>> emotions,
      Value<String?> imagePath,
    });

class $$CalendarEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $CalendarEntriesTable> {
  $$CalendarEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get emotions => $composableBuilder(
    column: $table.emotions,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CalendarEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CalendarEntriesTable> {
  $$CalendarEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emotions => $composableBuilder(
    column: $table.emotions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CalendarEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CalendarEntriesTable> {
  $$CalendarEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get emotions =>
      $composableBuilder(column: $table.emotions, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);
}

class $$CalendarEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CalendarEntriesTable,
          CalendarEntry,
          $$CalendarEntriesTableFilterComposer,
          $$CalendarEntriesTableOrderingComposer,
          $$CalendarEntriesTableAnnotationComposer,
          $$CalendarEntriesTableCreateCompanionBuilder,
          $$CalendarEntriesTableUpdateCompanionBuilder,
          (
            CalendarEntry,
            BaseReferences<_$AppDatabase, $CalendarEntriesTable, CalendarEntry>,
          ),
          CalendarEntry,
          PrefetchHooks Function()
        > {
  $$CalendarEntriesTableTableManager(
    _$AppDatabase db,
    $CalendarEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CalendarEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CalendarEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CalendarEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<List<String>> emotions = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
              }) => CalendarEntriesCompanion(
                id: id,
                date: date,
                content: content,
                emotions: emotions,
                imagePath: imagePath,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime date,
                required String content,
                required List<String> emotions,
                Value<String?> imagePath = const Value.absent(),
              }) => CalendarEntriesCompanion.insert(
                id: id,
                date: date,
                content: content,
                emotions: emotions,
                imagePath: imagePath,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CalendarEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CalendarEntriesTable,
      CalendarEntry,
      $$CalendarEntriesTableFilterComposer,
      $$CalendarEntriesTableOrderingComposer,
      $$CalendarEntriesTableAnnotationComposer,
      $$CalendarEntriesTableCreateCompanionBuilder,
      $$CalendarEntriesTableUpdateCompanionBuilder,
      (
        CalendarEntry,
        BaseReferences<_$AppDatabase, $CalendarEntriesTable, CalendarEntry>,
      ),
      CalendarEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CalendarEntriesTableTableManager get calendarEntries =>
      $$CalendarEntriesTableTableManager(_db, _db.calendarEntries);
}
