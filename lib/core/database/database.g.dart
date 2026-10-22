// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
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
      maxTextLength: 60,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('folder'),
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    icon,
    color,
    isDefault,
    sortOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryRow> instance, {
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
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final String id;
  final String name;

  /// Key into `CategoryIcons`, never a raw icon code point.
  /// Raw code points break icon tree-shaking in release builds.
  final String icon;

  /// ARGB colour value.
  final int color;
  final bool isDefault;
  final int sortOrder;
  final DateTime createdAt;
  const CategoryRow({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.isDefault,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['icon'] = Variable<String>(icon);
    map['color'] = Variable<int>(color);
    map['is_default'] = Variable<bool>(isDefault);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      icon: Value(icon),
      color: Value(color),
      isDefault: Value(isDefault),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory CategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String>(json['icon']),
      color: serializer.fromJson<int>(json['color']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String>(icon),
      'color': serializer.toJson<int>(color),
      'isDefault': serializer.toJson<bool>(isDefault),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CategoryRow copyWith({
    String? id,
    String? name,
    String? icon,
    int? color,
    bool? isDefault,
    int? sortOrder,
    DateTime? createdAt,
  }) => CategoryRow(
    id: id ?? this.id,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    isDefault: isDefault ?? this.isDefault,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  CategoryRow copyWithCompanion(CategoriesCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      color: data.color.present ? data.color.value : this.color,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('isDefault: $isDefault, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, icon, color, isDefault, sortOrder, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.color == this.color &&
          other.isDefault == this.isDefault &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class CategoriesCompanion extends UpdateCompanion<CategoryRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> icon;
  final Value<int> color;
  final Value<bool> isDefault;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String name,
    this.icon = const Value.absent(),
    required int color,
    this.isDefault = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       color = Value(color);
  static Insertable<CategoryRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? icon,
    Expression<int>? color,
    Expression<bool>? isDefault,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      if (isDefault != null) 'is_default': isDefault,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? icon,
    Value<int>? color,
    Value<bool>? isDefault,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
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
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('isDefault: $isDefault, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, TaskRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id) ON DELETE SET NULL',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Priority, int> priority =
      GeneratedColumn<int>(
        'priority',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<Priority>($TasksTable.$converterpriority);
  @override
  late final GeneratedColumnWithTypeConverter<TaskStatus, int> status =
      GeneratedColumn<int>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<TaskStatus>($TasksTable.$converterstatus);
  static const VerificationMeta _deadlineMeta = const VerificationMeta(
    'deadline',
  );
  @override
  late final GeneratedColumn<DateTime> deadline = GeneratedColumn<DateTime>(
    'deadline',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isRecurringMeta = const VerificationMeta(
    'isRecurring',
  );
  @override
  late final GeneratedColumn<bool> isRecurring = GeneratedColumn<bool>(
    'is_recurring',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_recurring" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<RecurrenceType, int>
  recurrenceType = GeneratedColumn<int>(
    'recurrence_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<RecurrenceType>($TasksTable.$converterrecurrenceType);
  static const VerificationMeta _recurrenceDaysMeta = const VerificationMeta(
    'recurrenceDays',
  );
  @override
  late final GeneratedColumn<String> recurrenceDays = GeneratedColumn<String>(
    'recurrence_days',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recurrenceSourceIdMeta =
      const VerificationMeta('recurrenceSourceId');
  @override
  late final GeneratedColumn<String> recurrenceSourceId =
      GeneratedColumn<String>(
        'recurrence_source_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parentTaskIdMeta = const VerificationMeta(
    'parentTaskId',
  );
  @override
  late final GeneratedColumn<String> parentTaskId = GeneratedColumn<String>(
    'parent_task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('default_user'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<AlarmType, int> alarmType =
      GeneratedColumn<int>(
        'alarm_type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<AlarmType>($TasksTable.$converteralarmType);
  static const VerificationMeta _repeatUntilCompletedMeta =
      const VerificationMeta('repeatUntilCompleted');
  @override
  late final GeneratedColumn<bool> repeatUntilCompleted = GeneratedColumn<bool>(
    'repeat_until_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("repeat_until_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _repeatIntervalMinutesMeta =
      const VerificationMeta('repeatIntervalMinutes');
  @override
  late final GeneratedColumn<int> repeatIntervalMinutes = GeneratedColumn<int>(
    'repeat_interval_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(15),
  );
  static const VerificationMeta _maxRepeatCountMeta = const VerificationMeta(
    'maxRepeatCount',
  );
  @override
  late final GeneratedColumn<int> maxRepeatCount = GeneratedColumn<int>(
    'max_repeat_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(5),
  );
  static const VerificationMeta _currentRepeatCountMeta =
      const VerificationMeta('currentRepeatCount');
  @override
  late final GeneratedColumn<int> currentRepeatCount = GeneratedColumn<int>(
    'current_repeat_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _customNotificationTitleMeta =
      const VerificationMeta('customNotificationTitle');
  @override
  late final GeneratedColumn<String> customNotificationTitle =
      GeneratedColumn<String>(
        'custom_notification_title',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _customNotificationBodyMeta =
      const VerificationMeta('customNotificationBody');
  @override
  late final GeneratedColumn<String> customNotificationBody =
      GeneratedColumn<String>(
        'custom_notification_body',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  late final GeneratedColumnWithTypeConverter<NotificationSound, int>
  soundChoice = GeneratedColumn<int>(
    'sound_choice',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  ).withConverter<NotificationSound>($TasksTable.$convertersoundChoice);
  @override
  late final GeneratedColumnWithTypeConverter<NotificationVibration, int>
  vibrationChoice = GeneratedColumn<int>(
    'vibration_choice',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  ).withConverter<NotificationVibration>($TasksTable.$convertervibrationChoice);
  static const VerificationMeta _snoozeUntilMeta = const VerificationMeta(
    'snoozeUntil',
  );
  @override
  late final GeneratedColumn<DateTime> snoozeUntil = GeneratedColumn<DateTime>(
    'snooze_until',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    description,
    notes,
    categoryId,
    priority,
    status,
    deadline,
    isRecurring,
    recurrenceType,
    recurrenceDays,
    recurrenceSourceId,
    completedAt,
    parentTaskId,
    userId,
    alarmType,
    repeatUntilCompleted,
    repeatIntervalMinutes,
    maxRepeatCount,
    currentRepeatCount,
    customNotificationTitle,
    customNotificationBody,
    soundChoice,
    vibrationChoice,
    snoozeUntil,
    sortOrder,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('deadline')) {
      context.handle(
        _deadlineMeta,
        deadline.isAcceptableOrUnknown(data['deadline']!, _deadlineMeta),
      );
    }
    if (data.containsKey('is_recurring')) {
      context.handle(
        _isRecurringMeta,
        isRecurring.isAcceptableOrUnknown(
          data['is_recurring']!,
          _isRecurringMeta,
        ),
      );
    }
    if (data.containsKey('recurrence_days')) {
      context.handle(
        _recurrenceDaysMeta,
        recurrenceDays.isAcceptableOrUnknown(
          data['recurrence_days']!,
          _recurrenceDaysMeta,
        ),
      );
    }
    if (data.containsKey('recurrence_source_id')) {
      context.handle(
        _recurrenceSourceIdMeta,
        recurrenceSourceId.isAcceptableOrUnknown(
          data['recurrence_source_id']!,
          _recurrenceSourceIdMeta,
        ),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('parent_task_id')) {
      context.handle(
        _parentTaskIdMeta,
        parentTaskId.isAcceptableOrUnknown(
          data['parent_task_id']!,
          _parentTaskIdMeta,
        ),
      );
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('repeat_until_completed')) {
      context.handle(
        _repeatUntilCompletedMeta,
        repeatUntilCompleted.isAcceptableOrUnknown(
          data['repeat_until_completed']!,
          _repeatUntilCompletedMeta,
        ),
      );
    }
    if (data.containsKey('repeat_interval_minutes')) {
      context.handle(
        _repeatIntervalMinutesMeta,
        repeatIntervalMinutes.isAcceptableOrUnknown(
          data['repeat_interval_minutes']!,
          _repeatIntervalMinutesMeta,
        ),
      );
    }
    if (data.containsKey('max_repeat_count')) {
      context.handle(
        _maxRepeatCountMeta,
        maxRepeatCount.isAcceptableOrUnknown(
          data['max_repeat_count']!,
          _maxRepeatCountMeta,
        ),
      );
    }
    if (data.containsKey('current_repeat_count')) {
      context.handle(
        _currentRepeatCountMeta,
        currentRepeatCount.isAcceptableOrUnknown(
          data['current_repeat_count']!,
          _currentRepeatCountMeta,
        ),
      );
    }
    if (data.containsKey('custom_notification_title')) {
      context.handle(
        _customNotificationTitleMeta,
        customNotificationTitle.isAcceptableOrUnknown(
          data['custom_notification_title']!,
          _customNotificationTitleMeta,
        ),
      );
    }
    if (data.containsKey('custom_notification_body')) {
      context.handle(
        _customNotificationBodyMeta,
        customNotificationBody.isAcceptableOrUnknown(
          data['custom_notification_body']!,
          _customNotificationBodyMeta,
        ),
      );
    }
    if (data.containsKey('snooze_until')) {
      context.handle(
        _snoozeUntilMeta,
        snoozeUntil.isAcceptableOrUnknown(
          data['snooze_until']!,
          _snoozeUntilMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      priority: $TasksTable.$converterpriority.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}priority'],
        )!,
      ),
      status: $TasksTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}status'],
        )!,
      ),
      deadline: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deadline'],
      ),
      isRecurring: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_recurring'],
      )!,
      recurrenceType: $TasksTable.$converterrecurrenceType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}recurrence_type'],
        )!,
      ),
      recurrenceDays: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence_days'],
      ),
      recurrenceSourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence_source_id'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      parentTaskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_task_id'],
      ),
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      alarmType: $TasksTable.$converteralarmType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}alarm_type'],
        )!,
      ),
      repeatUntilCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}repeat_until_completed'],
      )!,
      repeatIntervalMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repeat_interval_minutes'],
      )!,
      maxRepeatCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_repeat_count'],
      )!,
      currentRepeatCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_repeat_count'],
      )!,
      customNotificationTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_notification_title'],
      ),
      customNotificationBody: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_notification_body'],
      ),
      soundChoice: $TasksTable.$convertersoundChoice.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}sound_choice'],
        )!,
      ),
      vibrationChoice: $TasksTable.$convertervibrationChoice.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}vibration_choice'],
        )!,
      ),
      snoozeUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}snooze_until'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Priority, int, int> $converterpriority =
      const EnumIndexConverter<Priority>(Priority.values);
  static JsonTypeConverter2<TaskStatus, int, int> $converterstatus =
      const EnumIndexConverter<TaskStatus>(TaskStatus.values);
  static JsonTypeConverter2<RecurrenceType, int, int> $converterrecurrenceType =
      const EnumIndexConverter<RecurrenceType>(RecurrenceType.values);
  static JsonTypeConverter2<AlarmType, int, int> $converteralarmType =
      const EnumIndexConverter<AlarmType>(AlarmType.values);
  static JsonTypeConverter2<NotificationSound, int, int> $convertersoundChoice =
      const EnumIndexConverter<NotificationSound>(NotificationSound.values);
  static JsonTypeConverter2<NotificationVibration, int, int>
  $convertervibrationChoice = const EnumIndexConverter<NotificationVibration>(
    NotificationVibration.values,
  );
}

class TaskRow extends DataClass implements Insertable<TaskRow> {
  final String id;
  final String title;
  final String? description;
  final String? notes;
  final String? categoryId;
  final Priority priority;
  final TaskStatus status;
  final DateTime? deadline;
  final bool isRecurring;
  final RecurrenceType recurrenceType;

  /// CSV of ISO weekday numbers (1 = Monday … 7 = Sunday) for `customWeekly`.
  final String? recurrenceDays;

  /// Id of the original task in a recurrence chain. Null for the first
  /// occurrence. Prevents duplicate chains when regenerating.
  final String? recurrenceSourceId;
  final DateTime? completedAt;
  final String? parentTaskId;
  final String? userId;
  final AlarmType alarmType;
  final bool repeatUntilCompleted;
  final int repeatIntervalMinutes;
  final int maxRepeatCount;
  final int currentRepeatCount;
  final String? customNotificationTitle;
  final String? customNotificationBody;
  final NotificationSound soundChoice;
  final NotificationVibration vibrationChoice;
  final DateTime? snoozeUntil;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  const TaskRow({
    required this.id,
    required this.title,
    this.description,
    this.notes,
    this.categoryId,
    required this.priority,
    required this.status,
    this.deadline,
    required this.isRecurring,
    required this.recurrenceType,
    this.recurrenceDays,
    this.recurrenceSourceId,
    this.completedAt,
    this.parentTaskId,
    this.userId,
    required this.alarmType,
    required this.repeatUntilCompleted,
    required this.repeatIntervalMinutes,
    required this.maxRepeatCount,
    required this.currentRepeatCount,
    this.customNotificationTitle,
    this.customNotificationBody,
    required this.soundChoice,
    required this.vibrationChoice,
    this.snoozeUntil,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    {
      map['priority'] = Variable<int>(
        $TasksTable.$converterpriority.toSql(priority),
      );
    }
    {
      map['status'] = Variable<int>($TasksTable.$converterstatus.toSql(status));
    }
    if (!nullToAbsent || deadline != null) {
      map['deadline'] = Variable<DateTime>(deadline);
    }
    map['is_recurring'] = Variable<bool>(isRecurring);
    {
      map['recurrence_type'] = Variable<int>(
        $TasksTable.$converterrecurrenceType.toSql(recurrenceType),
      );
    }
    if (!nullToAbsent || recurrenceDays != null) {
      map['recurrence_days'] = Variable<String>(recurrenceDays);
    }
    if (!nullToAbsent || recurrenceSourceId != null) {
      map['recurrence_source_id'] = Variable<String>(recurrenceSourceId);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || parentTaskId != null) {
      map['parent_task_id'] = Variable<String>(parentTaskId);
    }
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    {
      map['alarm_type'] = Variable<int>(
        $TasksTable.$converteralarmType.toSql(alarmType),
      );
    }
    map['repeat_until_completed'] = Variable<bool>(repeatUntilCompleted);
    map['repeat_interval_minutes'] = Variable<int>(repeatIntervalMinutes);
    map['max_repeat_count'] = Variable<int>(maxRepeatCount);
    map['current_repeat_count'] = Variable<int>(currentRepeatCount);
    if (!nullToAbsent || customNotificationTitle != null) {
      map['custom_notification_title'] = Variable<String>(
        customNotificationTitle,
      );
    }
    if (!nullToAbsent || customNotificationBody != null) {
      map['custom_notification_body'] = Variable<String>(
        customNotificationBody,
      );
    }
    {
      map['sound_choice'] = Variable<int>(
        $TasksTable.$convertersoundChoice.toSql(soundChoice),
      );
    }
    {
      map['vibration_choice'] = Variable<int>(
        $TasksTable.$convertervibrationChoice.toSql(vibrationChoice),
      );
    }
    if (!nullToAbsent || snoozeUntil != null) {
      map['snooze_until'] = Variable<DateTime>(snoozeUntil);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      priority: Value(priority),
      status: Value(status),
      deadline: deadline == null && nullToAbsent
          ? const Value.absent()
          : Value(deadline),
      isRecurring: Value(isRecurring),
      recurrenceType: Value(recurrenceType),
      recurrenceDays: recurrenceDays == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceDays),
      recurrenceSourceId: recurrenceSourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceSourceId),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      parentTaskId: parentTaskId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentTaskId),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      alarmType: Value(alarmType),
      repeatUntilCompleted: Value(repeatUntilCompleted),
      repeatIntervalMinutes: Value(repeatIntervalMinutes),
      maxRepeatCount: Value(maxRepeatCount),
      currentRepeatCount: Value(currentRepeatCount),
      customNotificationTitle: customNotificationTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(customNotificationTitle),
      customNotificationBody: customNotificationBody == null && nullToAbsent
          ? const Value.absent()
          : Value(customNotificationBody),
      soundChoice: Value(soundChoice),
      vibrationChoice: Value(vibrationChoice),
      snoozeUntil: snoozeUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(snoozeUntil),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TaskRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      notes: serializer.fromJson<String?>(json['notes']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      priority: $TasksTable.$converterpriority.fromJson(
        serializer.fromJson<int>(json['priority']),
      ),
      status: $TasksTable.$converterstatus.fromJson(
        serializer.fromJson<int>(json['status']),
      ),
      deadline: serializer.fromJson<DateTime?>(json['deadline']),
      isRecurring: serializer.fromJson<bool>(json['isRecurring']),
      recurrenceType: $TasksTable.$converterrecurrenceType.fromJson(
        serializer.fromJson<int>(json['recurrenceType']),
      ),
      recurrenceDays: serializer.fromJson<String?>(json['recurrenceDays']),
      recurrenceSourceId: serializer.fromJson<String?>(
        json['recurrenceSourceId'],
      ),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      parentTaskId: serializer.fromJson<String?>(json['parentTaskId']),
      userId: serializer.fromJson<String?>(json['userId']),
      alarmType: $TasksTable.$converteralarmType.fromJson(
        serializer.fromJson<int>(json['alarmType']),
      ),
      repeatUntilCompleted: serializer.fromJson<bool>(
        json['repeatUntilCompleted'],
      ),
      repeatIntervalMinutes: serializer.fromJson<int>(
        json['repeatIntervalMinutes'],
      ),
      maxRepeatCount: serializer.fromJson<int>(json['maxRepeatCount']),
      currentRepeatCount: serializer.fromJson<int>(json['currentRepeatCount']),
      customNotificationTitle: serializer.fromJson<String?>(
        json['customNotificationTitle'],
      ),
      customNotificationBody: serializer.fromJson<String?>(
        json['customNotificationBody'],
      ),
      soundChoice: $TasksTable.$convertersoundChoice.fromJson(
        serializer.fromJson<int>(json['soundChoice']),
      ),
      vibrationChoice: $TasksTable.$convertervibrationChoice.fromJson(
        serializer.fromJson<int>(json['vibrationChoice']),
      ),
      snoozeUntil: serializer.fromJson<DateTime?>(json['snoozeUntil']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'notes': serializer.toJson<String?>(notes),
      'categoryId': serializer.toJson<String?>(categoryId),
      'priority': serializer.toJson<int>(
        $TasksTable.$converterpriority.toJson(priority),
      ),
      'status': serializer.toJson<int>(
        $TasksTable.$converterstatus.toJson(status),
      ),
      'deadline': serializer.toJson<DateTime?>(deadline),
      'isRecurring': serializer.toJson<bool>(isRecurring),
      'recurrenceType': serializer.toJson<int>(
        $TasksTable.$converterrecurrenceType.toJson(recurrenceType),
      ),
      'recurrenceDays': serializer.toJson<String?>(recurrenceDays),
      'recurrenceSourceId': serializer.toJson<String?>(recurrenceSourceId),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'parentTaskId': serializer.toJson<String?>(parentTaskId),
      'userId': serializer.toJson<String?>(userId),
      'alarmType': serializer.toJson<int>(
        $TasksTable.$converteralarmType.toJson(alarmType),
      ),
      'repeatUntilCompleted': serializer.toJson<bool>(repeatUntilCompleted),
      'repeatIntervalMinutes': serializer.toJson<int>(repeatIntervalMinutes),
      'maxRepeatCount': serializer.toJson<int>(maxRepeatCount),
      'currentRepeatCount': serializer.toJson<int>(currentRepeatCount),
      'customNotificationTitle': serializer.toJson<String?>(
        customNotificationTitle,
      ),
      'customNotificationBody': serializer.toJson<String?>(
        customNotificationBody,
      ),
      'soundChoice': serializer.toJson<int>(
        $TasksTable.$convertersoundChoice.toJson(soundChoice),
      ),
      'vibrationChoice': serializer.toJson<int>(
        $TasksTable.$convertervibrationChoice.toJson(vibrationChoice),
      ),
      'snoozeUntil': serializer.toJson<DateTime?>(snoozeUntil),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TaskRow copyWith({
    String? id,
    String? title,
    Value<String?> description = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    Priority? priority,
    TaskStatus? status,
    Value<DateTime?> deadline = const Value.absent(),
    bool? isRecurring,
    RecurrenceType? recurrenceType,
    Value<String?> recurrenceDays = const Value.absent(),
    Value<String?> recurrenceSourceId = const Value.absent(),
    Value<DateTime?> completedAt = const Value.absent(),
    Value<String?> parentTaskId = const Value.absent(),
    Value<String?> userId = const Value.absent(),
    AlarmType? alarmType,
    bool? repeatUntilCompleted,
    int? repeatIntervalMinutes,
    int? maxRepeatCount,
    int? currentRepeatCount,
    Value<String?> customNotificationTitle = const Value.absent(),
    Value<String?> customNotificationBody = const Value.absent(),
    NotificationSound? soundChoice,
    NotificationVibration? vibrationChoice,
    Value<DateTime?> snoozeUntil = const Value.absent(),
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => TaskRow(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    notes: notes.present ? notes.value : this.notes,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    priority: priority ?? this.priority,
    status: status ?? this.status,
    deadline: deadline.present ? deadline.value : this.deadline,
    isRecurring: isRecurring ?? this.isRecurring,
    recurrenceType: recurrenceType ?? this.recurrenceType,
    recurrenceDays: recurrenceDays.present
        ? recurrenceDays.value
        : this.recurrenceDays,
    recurrenceSourceId: recurrenceSourceId.present
        ? recurrenceSourceId.value
        : this.recurrenceSourceId,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    parentTaskId: parentTaskId.present ? parentTaskId.value : this.parentTaskId,
    userId: userId.present ? userId.value : this.userId,
    alarmType: alarmType ?? this.alarmType,
    repeatUntilCompleted: repeatUntilCompleted ?? this.repeatUntilCompleted,
    repeatIntervalMinutes: repeatIntervalMinutes ?? this.repeatIntervalMinutes,
    maxRepeatCount: maxRepeatCount ?? this.maxRepeatCount,
    currentRepeatCount: currentRepeatCount ?? this.currentRepeatCount,
    customNotificationTitle: customNotificationTitle.present
        ? customNotificationTitle.value
        : this.customNotificationTitle,
    customNotificationBody: customNotificationBody.present
        ? customNotificationBody.value
        : this.customNotificationBody,
    soundChoice: soundChoice ?? this.soundChoice,
    vibrationChoice: vibrationChoice ?? this.vibrationChoice,
    snoozeUntil: snoozeUntil.present ? snoozeUntil.value : this.snoozeUntil,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TaskRow copyWithCompanion(TasksCompanion data) {
    return TaskRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      notes: data.notes.present ? data.notes.value : this.notes,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      priority: data.priority.present ? data.priority.value : this.priority,
      status: data.status.present ? data.status.value : this.status,
      deadline: data.deadline.present ? data.deadline.value : this.deadline,
      isRecurring: data.isRecurring.present
          ? data.isRecurring.value
          : this.isRecurring,
      recurrenceType: data.recurrenceType.present
          ? data.recurrenceType.value
          : this.recurrenceType,
      recurrenceDays: data.recurrenceDays.present
          ? data.recurrenceDays.value
          : this.recurrenceDays,
      recurrenceSourceId: data.recurrenceSourceId.present
          ? data.recurrenceSourceId.value
          : this.recurrenceSourceId,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      parentTaskId: data.parentTaskId.present
          ? data.parentTaskId.value
          : this.parentTaskId,
      userId: data.userId.present ? data.userId.value : this.userId,
      alarmType: data.alarmType.present ? data.alarmType.value : this.alarmType,
      repeatUntilCompleted: data.repeatUntilCompleted.present
          ? data.repeatUntilCompleted.value
          : this.repeatUntilCompleted,
      repeatIntervalMinutes: data.repeatIntervalMinutes.present
          ? data.repeatIntervalMinutes.value
          : this.repeatIntervalMinutes,
      maxRepeatCount: data.maxRepeatCount.present
          ? data.maxRepeatCount.value
          : this.maxRepeatCount,
      currentRepeatCount: data.currentRepeatCount.present
          ? data.currentRepeatCount.value
          : this.currentRepeatCount,
      customNotificationTitle: data.customNotificationTitle.present
          ? data.customNotificationTitle.value
          : this.customNotificationTitle,
      customNotificationBody: data.customNotificationBody.present
          ? data.customNotificationBody.value
          : this.customNotificationBody,
      soundChoice: data.soundChoice.present
          ? data.soundChoice.value
          : this.soundChoice,
      vibrationChoice: data.vibrationChoice.present
          ? data.vibrationChoice.value
          : this.vibrationChoice,
      snoozeUntil: data.snoozeUntil.present
          ? data.snoozeUntil.value
          : this.snoozeUntil,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('notes: $notes, ')
          ..write('categoryId: $categoryId, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('deadline: $deadline, ')
          ..write('isRecurring: $isRecurring, ')
          ..write('recurrenceType: $recurrenceType, ')
          ..write('recurrenceDays: $recurrenceDays, ')
          ..write('recurrenceSourceId: $recurrenceSourceId, ')
          ..write('completedAt: $completedAt, ')
          ..write('parentTaskId: $parentTaskId, ')
          ..write('userId: $userId, ')
          ..write('alarmType: $alarmType, ')
          ..write('repeatUntilCompleted: $repeatUntilCompleted, ')
          ..write('repeatIntervalMinutes: $repeatIntervalMinutes, ')
          ..write('maxRepeatCount: $maxRepeatCount, ')
          ..write('currentRepeatCount: $currentRepeatCount, ')
          ..write('customNotificationTitle: $customNotificationTitle, ')
          ..write('customNotificationBody: $customNotificationBody, ')
          ..write('soundChoice: $soundChoice, ')
          ..write('vibrationChoice: $vibrationChoice, ')
          ..write('snoozeUntil: $snoozeUntil, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    title,
    description,
    notes,
    categoryId,
    priority,
    status,
    deadline,
    isRecurring,
    recurrenceType,
    recurrenceDays,
    recurrenceSourceId,
    completedAt,
    parentTaskId,
    userId,
    alarmType,
    repeatUntilCompleted,
    repeatIntervalMinutes,
    maxRepeatCount,
    currentRepeatCount,
    customNotificationTitle,
    customNotificationBody,
    soundChoice,
    vibrationChoice,
    snoozeUntil,
    sortOrder,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.notes == this.notes &&
          other.categoryId == this.categoryId &&
          other.priority == this.priority &&
          other.status == this.status &&
          other.deadline == this.deadline &&
          other.isRecurring == this.isRecurring &&
          other.recurrenceType == this.recurrenceType &&
          other.recurrenceDays == this.recurrenceDays &&
          other.recurrenceSourceId == this.recurrenceSourceId &&
          other.completedAt == this.completedAt &&
          other.parentTaskId == this.parentTaskId &&
          other.userId == this.userId &&
          other.alarmType == this.alarmType &&
          other.repeatUntilCompleted == this.repeatUntilCompleted &&
          other.repeatIntervalMinutes == this.repeatIntervalMinutes &&
          other.maxRepeatCount == this.maxRepeatCount &&
          other.currentRepeatCount == this.currentRepeatCount &&
          other.customNotificationTitle == this.customNotificationTitle &&
          other.customNotificationBody == this.customNotificationBody &&
          other.soundChoice == this.soundChoice &&
          other.vibrationChoice == this.vibrationChoice &&
          other.snoozeUntil == this.snoozeUntil &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TasksCompanion extends UpdateCompanion<TaskRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<String?> notes;
  final Value<String?> categoryId;
  final Value<Priority> priority;
  final Value<TaskStatus> status;
  final Value<DateTime?> deadline;
  final Value<bool> isRecurring;
  final Value<RecurrenceType> recurrenceType;
  final Value<String?> recurrenceDays;
  final Value<String?> recurrenceSourceId;
  final Value<DateTime?> completedAt;
  final Value<String?> parentTaskId;
  final Value<String?> userId;
  final Value<AlarmType> alarmType;
  final Value<bool> repeatUntilCompleted;
  final Value<int> repeatIntervalMinutes;
  final Value<int> maxRepeatCount;
  final Value<int> currentRepeatCount;
  final Value<String?> customNotificationTitle;
  final Value<String?> customNotificationBody;
  final Value<NotificationSound> soundChoice;
  final Value<NotificationVibration> vibrationChoice;
  final Value<DateTime?> snoozeUntil;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.notes = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.priority = const Value.absent(),
    this.status = const Value.absent(),
    this.deadline = const Value.absent(),
    this.isRecurring = const Value.absent(),
    this.recurrenceType = const Value.absent(),
    this.recurrenceDays = const Value.absent(),
    this.recurrenceSourceId = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.parentTaskId = const Value.absent(),
    this.userId = const Value.absent(),
    this.alarmType = const Value.absent(),
    this.repeatUntilCompleted = const Value.absent(),
    this.repeatIntervalMinutes = const Value.absent(),
    this.maxRepeatCount = const Value.absent(),
    this.currentRepeatCount = const Value.absent(),
    this.customNotificationTitle = const Value.absent(),
    this.customNotificationBody = const Value.absent(),
    this.soundChoice = const Value.absent(),
    this.vibrationChoice = const Value.absent(),
    this.snoozeUntil = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    required String title,
    this.description = const Value.absent(),
    this.notes = const Value.absent(),
    this.categoryId = const Value.absent(),
    required Priority priority,
    required TaskStatus status,
    this.deadline = const Value.absent(),
    this.isRecurring = const Value.absent(),
    required RecurrenceType recurrenceType,
    this.recurrenceDays = const Value.absent(),
    this.recurrenceSourceId = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.parentTaskId = const Value.absent(),
    this.userId = const Value.absent(),
    this.alarmType = const Value.absent(),
    this.repeatUntilCompleted = const Value.absent(),
    this.repeatIntervalMinutes = const Value.absent(),
    this.maxRepeatCount = const Value.absent(),
    this.currentRepeatCount = const Value.absent(),
    this.customNotificationTitle = const Value.absent(),
    this.customNotificationBody = const Value.absent(),
    this.soundChoice = const Value.absent(),
    this.vibrationChoice = const Value.absent(),
    this.snoozeUntil = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       priority = Value(priority),
       status = Value(status),
       recurrenceType = Value(recurrenceType);
  static Insertable<TaskRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? notes,
    Expression<String>? categoryId,
    Expression<int>? priority,
    Expression<int>? status,
    Expression<DateTime>? deadline,
    Expression<bool>? isRecurring,
    Expression<int>? recurrenceType,
    Expression<String>? recurrenceDays,
    Expression<String>? recurrenceSourceId,
    Expression<DateTime>? completedAt,
    Expression<String>? parentTaskId,
    Expression<String>? userId,
    Expression<int>? alarmType,
    Expression<bool>? repeatUntilCompleted,
    Expression<int>? repeatIntervalMinutes,
    Expression<int>? maxRepeatCount,
    Expression<int>? currentRepeatCount,
    Expression<String>? customNotificationTitle,
    Expression<String>? customNotificationBody,
    Expression<int>? soundChoice,
    Expression<int>? vibrationChoice,
    Expression<DateTime>? snoozeUntil,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (notes != null) 'notes': notes,
      if (categoryId != null) 'category_id': categoryId,
      if (priority != null) 'priority': priority,
      if (status != null) 'status': status,
      if (deadline != null) 'deadline': deadline,
      if (isRecurring != null) 'is_recurring': isRecurring,
      if (recurrenceType != null) 'recurrence_type': recurrenceType,
      if (recurrenceDays != null) 'recurrence_days': recurrenceDays,
      if (recurrenceSourceId != null)
        'recurrence_source_id': recurrenceSourceId,
      if (completedAt != null) 'completed_at': completedAt,
      if (parentTaskId != null) 'parent_task_id': parentTaskId,
      if (userId != null) 'user_id': userId,
      if (alarmType != null) 'alarm_type': alarmType,
      if (repeatUntilCompleted != null)
        'repeat_until_completed': repeatUntilCompleted,
      if (repeatIntervalMinutes != null)
        'repeat_interval_minutes': repeatIntervalMinutes,
      if (maxRepeatCount != null) 'max_repeat_count': maxRepeatCount,
      if (currentRepeatCount != null)
        'current_repeat_count': currentRepeatCount,
      if (customNotificationTitle != null)
        'custom_notification_title': customNotificationTitle,
      if (customNotificationBody != null)
        'custom_notification_body': customNotificationBody,
      if (soundChoice != null) 'sound_choice': soundChoice,
      if (vibrationChoice != null) 'vibration_choice': vibrationChoice,
      if (snoozeUntil != null) 'snooze_until': snoozeUntil,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? description,
    Value<String?>? notes,
    Value<String?>? categoryId,
    Value<Priority>? priority,
    Value<TaskStatus>? status,
    Value<DateTime?>? deadline,
    Value<bool>? isRecurring,
    Value<RecurrenceType>? recurrenceType,
    Value<String?>? recurrenceDays,
    Value<String?>? recurrenceSourceId,
    Value<DateTime?>? completedAt,
    Value<String?>? parentTaskId,
    Value<String?>? userId,
    Value<AlarmType>? alarmType,
    Value<bool>? repeatUntilCompleted,
    Value<int>? repeatIntervalMinutes,
    Value<int>? maxRepeatCount,
    Value<int>? currentRepeatCount,
    Value<String?>? customNotificationTitle,
    Value<String?>? customNotificationBody,
    Value<NotificationSound>? soundChoice,
    Value<NotificationVibration>? vibrationChoice,
    Value<DateTime?>? snoozeUntil,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      categoryId: categoryId ?? this.categoryId,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      deadline: deadline ?? this.deadline,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceDays: recurrenceDays ?? this.recurrenceDays,
      recurrenceSourceId: recurrenceSourceId ?? this.recurrenceSourceId,
      completedAt: completedAt ?? this.completedAt,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      userId: userId ?? this.userId,
      alarmType: alarmType ?? this.alarmType,
      repeatUntilCompleted: repeatUntilCompleted ?? this.repeatUntilCompleted,
      repeatIntervalMinutes:
          repeatIntervalMinutes ?? this.repeatIntervalMinutes,
      maxRepeatCount: maxRepeatCount ?? this.maxRepeatCount,
      currentRepeatCount: currentRepeatCount ?? this.currentRepeatCount,
      customNotificationTitle:
          customNotificationTitle ?? this.customNotificationTitle,
      customNotificationBody:
          customNotificationBody ?? this.customNotificationBody,
      soundChoice: soundChoice ?? this.soundChoice,
      vibrationChoice: vibrationChoice ?? this.vibrationChoice,
      snoozeUntil: snoozeUntil ?? this.snoozeUntil,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(
        $TasksTable.$converterpriority.toSql(priority.value),
      );
    }
    if (status.present) {
      map['status'] = Variable<int>(
        $TasksTable.$converterstatus.toSql(status.value),
      );
    }
    if (deadline.present) {
      map['deadline'] = Variable<DateTime>(deadline.value);
    }
    if (isRecurring.present) {
      map['is_recurring'] = Variable<bool>(isRecurring.value);
    }
    if (recurrenceType.present) {
      map['recurrence_type'] = Variable<int>(
        $TasksTable.$converterrecurrenceType.toSql(recurrenceType.value),
      );
    }
    if (recurrenceDays.present) {
      map['recurrence_days'] = Variable<String>(recurrenceDays.value);
    }
    if (recurrenceSourceId.present) {
      map['recurrence_source_id'] = Variable<String>(recurrenceSourceId.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (parentTaskId.present) {
      map['parent_task_id'] = Variable<String>(parentTaskId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (alarmType.present) {
      map['alarm_type'] = Variable<int>(
        $TasksTable.$converteralarmType.toSql(alarmType.value),
      );
    }
    if (repeatUntilCompleted.present) {
      map['repeat_until_completed'] = Variable<bool>(
        repeatUntilCompleted.value,
      );
    }
    if (repeatIntervalMinutes.present) {
      map['repeat_interval_minutes'] = Variable<int>(
        repeatIntervalMinutes.value,
      );
    }
    if (maxRepeatCount.present) {
      map['max_repeat_count'] = Variable<int>(maxRepeatCount.value);
    }
    if (currentRepeatCount.present) {
      map['current_repeat_count'] = Variable<int>(currentRepeatCount.value);
    }
    if (customNotificationTitle.present) {
      map['custom_notification_title'] = Variable<String>(
        customNotificationTitle.value,
      );
    }
    if (customNotificationBody.present) {
      map['custom_notification_body'] = Variable<String>(
        customNotificationBody.value,
      );
    }
    if (soundChoice.present) {
      map['sound_choice'] = Variable<int>(
        $TasksTable.$convertersoundChoice.toSql(soundChoice.value),
      );
    }
    if (vibrationChoice.present) {
      map['vibration_choice'] = Variable<int>(
        $TasksTable.$convertervibrationChoice.toSql(vibrationChoice.value),
      );
    }
    if (snoozeUntil.present) {
      map['snooze_until'] = Variable<DateTime>(snoozeUntil.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('notes: $notes, ')
          ..write('categoryId: $categoryId, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('deadline: $deadline, ')
          ..write('isRecurring: $isRecurring, ')
          ..write('recurrenceType: $recurrenceType, ')
          ..write('recurrenceDays: $recurrenceDays, ')
          ..write('recurrenceSourceId: $recurrenceSourceId, ')
          ..write('completedAt: $completedAt, ')
          ..write('parentTaskId: $parentTaskId, ')
          ..write('userId: $userId, ')
          ..write('alarmType: $alarmType, ')
          ..write('repeatUntilCompleted: $repeatUntilCompleted, ')
          ..write('repeatIntervalMinutes: $repeatIntervalMinutes, ')
          ..write('maxRepeatCount: $maxRepeatCount, ')
          ..write('currentRepeatCount: $currentRepeatCount, ')
          ..write('customNotificationTitle: $customNotificationTitle, ')
          ..write('customNotificationBody: $customNotificationBody, ')
          ..write('soundChoice: $soundChoice, ')
          ..write('vibrationChoice: $vibrationChoice, ')
          ..write('snoozeUntil: $snoozeUntil, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RemindersTable extends Reminders
    with TableInfo<$RemindersTable, ReminderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<ReminderKind, int> kind =
      GeneratedColumn<int>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<ReminderKind>($RemindersTable.$converterkind);
  static const VerificationMeta _minutesBeforeMeta = const VerificationMeta(
    'minutesBefore',
  );
  @override
  late final GeneratedColumn<int> minutesBefore = GeneratedColumn<int>(
    'minutes_before',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scheduledAtMeta = const VerificationMeta(
    'scheduledAt',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledAt = GeneratedColumn<DateTime>(
    'scheduled_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notificationIdMeta = const VerificationMeta(
    'notificationId',
  );
  @override
  late final GeneratedColumn<int> notificationId = GeneratedColumn<int>(
    'notification_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _notifiedAtMeta = const VerificationMeta(
    'notifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> notifiedAt = GeneratedColumn<DateTime>(
    'notified_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    kind,
    minutesBefore,
    scheduledAt,
    notificationId,
    enabled,
    notifiedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReminderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('minutes_before')) {
      context.handle(
        _minutesBeforeMeta,
        minutesBefore.isAcceptableOrUnknown(
          data['minutes_before']!,
          _minutesBeforeMeta,
        ),
      );
    }
    if (data.containsKey('scheduled_at')) {
      context.handle(
        _scheduledAtMeta,
        scheduledAt.isAcceptableOrUnknown(
          data['scheduled_at']!,
          _scheduledAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledAtMeta);
    }
    if (data.containsKey('notification_id')) {
      context.handle(
        _notificationIdMeta,
        notificationId.isAcceptableOrUnknown(
          data['notification_id']!,
          _notificationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_notificationIdMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('notified_at')) {
      context.handle(
        _notifiedAtMeta,
        notifiedAt.isAcceptableOrUnknown(data['notified_at']!, _notifiedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReminderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReminderRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      kind: $RemindersTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}kind'],
        )!,
      ),
      minutesBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minutes_before'],
      ),
      scheduledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_at'],
      )!,
      notificationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}notification_id'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      notifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}notified_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ReminderKind, int, int> $converterkind =
      const EnumIndexConverter<ReminderKind>(ReminderKind.values);
}

class ReminderRow extends DataClass implements Insertable<ReminderRow> {
  final String id;
  final String taskId;
  final ReminderKind kind;

  /// Minutes before the deadline; null for [ReminderKind.atDeadline],
  /// [ReminderKind.overdue] and [ReminderKind.custom].
  final int? minutesBefore;

  /// Absolute time the reminder should fire. Recomputed whenever the task
  /// deadline changes.
  final DateTime scheduledAt;

  /// Android/iOS notification id. Unique so rescheduling replaces cleanly.
  final int notificationId;
  final bool enabled;

  /// Set once the app has observed that this reminder's time passed, so the
  /// notification centre is not populated twice for the same reminder.
  final DateTime? notifiedAt;
  final DateTime createdAt;
  const ReminderRow({
    required this.id,
    required this.taskId,
    required this.kind,
    this.minutesBefore,
    required this.scheduledAt,
    required this.notificationId,
    required this.enabled,
    this.notifiedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['task_id'] = Variable<String>(taskId);
    {
      map['kind'] = Variable<int>($RemindersTable.$converterkind.toSql(kind));
    }
    if (!nullToAbsent || minutesBefore != null) {
      map['minutes_before'] = Variable<int>(minutesBefore);
    }
    map['scheduled_at'] = Variable<DateTime>(scheduledAt);
    map['notification_id'] = Variable<int>(notificationId);
    map['enabled'] = Variable<bool>(enabled);
    if (!nullToAbsent || notifiedAt != null) {
      map['notified_at'] = Variable<DateTime>(notifiedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      taskId: Value(taskId),
      kind: Value(kind),
      minutesBefore: minutesBefore == null && nullToAbsent
          ? const Value.absent()
          : Value(minutesBefore),
      scheduledAt: Value(scheduledAt),
      notificationId: Value(notificationId),
      enabled: Value(enabled),
      notifiedAt: notifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(notifiedAt),
      createdAt: Value(createdAt),
    );
  }

  factory ReminderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReminderRow(
      id: serializer.fromJson<String>(json['id']),
      taskId: serializer.fromJson<String>(json['taskId']),
      kind: $RemindersTable.$converterkind.fromJson(
        serializer.fromJson<int>(json['kind']),
      ),
      minutesBefore: serializer.fromJson<int?>(json['minutesBefore']),
      scheduledAt: serializer.fromJson<DateTime>(json['scheduledAt']),
      notificationId: serializer.fromJson<int>(json['notificationId']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      notifiedAt: serializer.fromJson<DateTime?>(json['notifiedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'taskId': serializer.toJson<String>(taskId),
      'kind': serializer.toJson<int>(
        $RemindersTable.$converterkind.toJson(kind),
      ),
      'minutesBefore': serializer.toJson<int?>(minutesBefore),
      'scheduledAt': serializer.toJson<DateTime>(scheduledAt),
      'notificationId': serializer.toJson<int>(notificationId),
      'enabled': serializer.toJson<bool>(enabled),
      'notifiedAt': serializer.toJson<DateTime?>(notifiedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ReminderRow copyWith({
    String? id,
    String? taskId,
    ReminderKind? kind,
    Value<int?> minutesBefore = const Value.absent(),
    DateTime? scheduledAt,
    int? notificationId,
    bool? enabled,
    Value<DateTime?> notifiedAt = const Value.absent(),
    DateTime? createdAt,
  }) => ReminderRow(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    kind: kind ?? this.kind,
    minutesBefore: minutesBefore.present
        ? minutesBefore.value
        : this.minutesBefore,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    notificationId: notificationId ?? this.notificationId,
    enabled: enabled ?? this.enabled,
    notifiedAt: notifiedAt.present ? notifiedAt.value : this.notifiedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  ReminderRow copyWithCompanion(RemindersCompanion data) {
    return ReminderRow(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      kind: data.kind.present ? data.kind.value : this.kind,
      minutesBefore: data.minutesBefore.present
          ? data.minutesBefore.value
          : this.minutesBefore,
      scheduledAt: data.scheduledAt.present
          ? data.scheduledAt.value
          : this.scheduledAt,
      notificationId: data.notificationId.present
          ? data.notificationId.value
          : this.notificationId,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      notifiedAt: data.notifiedAt.present
          ? data.notifiedAt.value
          : this.notifiedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReminderRow(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('kind: $kind, ')
          ..write('minutesBefore: $minutesBefore, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('notificationId: $notificationId, ')
          ..write('enabled: $enabled, ')
          ..write('notifiedAt: $notifiedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    taskId,
    kind,
    minutesBefore,
    scheduledAt,
    notificationId,
    enabled,
    notifiedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReminderRow &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.kind == this.kind &&
          other.minutesBefore == this.minutesBefore &&
          other.scheduledAt == this.scheduledAt &&
          other.notificationId == this.notificationId &&
          other.enabled == this.enabled &&
          other.notifiedAt == this.notifiedAt &&
          other.createdAt == this.createdAt);
}

class RemindersCompanion extends UpdateCompanion<ReminderRow> {
  final Value<String> id;
  final Value<String> taskId;
  final Value<ReminderKind> kind;
  final Value<int?> minutesBefore;
  final Value<DateTime> scheduledAt;
  final Value<int> notificationId;
  final Value<bool> enabled;
  final Value<DateTime?> notifiedAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.kind = const Value.absent(),
    this.minutesBefore = const Value.absent(),
    this.scheduledAt = const Value.absent(),
    this.notificationId = const Value.absent(),
    this.enabled = const Value.absent(),
    this.notifiedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RemindersCompanion.insert({
    required String id,
    required String taskId,
    required ReminderKind kind,
    this.minutesBefore = const Value.absent(),
    required DateTime scheduledAt,
    required int notificationId,
    this.enabled = const Value.absent(),
    this.notifiedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       taskId = Value(taskId),
       kind = Value(kind),
       scheduledAt = Value(scheduledAt),
       notificationId = Value(notificationId);
  static Insertable<ReminderRow> custom({
    Expression<String>? id,
    Expression<String>? taskId,
    Expression<int>? kind,
    Expression<int>? minutesBefore,
    Expression<DateTime>? scheduledAt,
    Expression<int>? notificationId,
    Expression<bool>? enabled,
    Expression<DateTime>? notifiedAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (kind != null) 'kind': kind,
      if (minutesBefore != null) 'minutes_before': minutesBefore,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
      if (notificationId != null) 'notification_id': notificationId,
      if (enabled != null) 'enabled': enabled,
      if (notifiedAt != null) 'notified_at': notifiedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RemindersCompanion copyWith({
    Value<String>? id,
    Value<String>? taskId,
    Value<ReminderKind>? kind,
    Value<int?>? minutesBefore,
    Value<DateTime>? scheduledAt,
    Value<int>? notificationId,
    Value<bool>? enabled,
    Value<DateTime?>? notifiedAt,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return RemindersCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      kind: kind ?? this.kind,
      minutesBefore: minutesBefore ?? this.minutesBefore,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      notificationId: notificationId ?? this.notificationId,
      enabled: enabled ?? this.enabled,
      notifiedAt: notifiedAt ?? this.notifiedAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<int>(
        $RemindersTable.$converterkind.toSql(kind.value),
      );
    }
    if (minutesBefore.present) {
      map['minutes_before'] = Variable<int>(minutesBefore.value);
    }
    if (scheduledAt.present) {
      map['scheduled_at'] = Variable<DateTime>(scheduledAt.value);
    }
    if (notificationId.present) {
      map['notification_id'] = Variable<int>(notificationId.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (notifiedAt.present) {
      map['notified_at'] = Variable<DateTime>(notifiedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemindersCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('kind: $kind, ')
          ..write('minutesBefore: $minutesBefore, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('notificationId: $notificationId, ')
          ..write('enabled: $enabled, ')
          ..write('notifiedAt: $notifiedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskNotificationsTable extends TaskNotifications
    with TableInfo<$TaskNotificationsTable, TaskNotificationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskNotificationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<NotificationCategory, int>
  category =
      GeneratedColumn<int>(
        'category',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<NotificationCategory>(
        $TaskNotificationsTable.$convertercategory,
      );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _readAtMeta = const VerificationMeta('readAt');
  @override
  late final GeneratedColumn<DateTime> readAt = GeneratedColumn<DateTime>(
    'read_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    category,
    title,
    body,
    createdAt,
    readAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_notifications';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskNotificationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('read_at')) {
      context.handle(
        _readAtMeta,
        readAt.isAcceptableOrUnknown(data['read_at']!, _readAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskNotificationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskNotificationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      ),
      category: $TaskNotificationsTable.$convertercategory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}category'],
        )!,
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      readAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}read_at'],
      ),
    );
  }

  @override
  $TaskNotificationsTable createAlias(String alias) {
    return $TaskNotificationsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<NotificationCategory, int, int> $convertercategory =
      const EnumIndexConverter<NotificationCategory>(
        NotificationCategory.values,
      );
}

class TaskNotificationRow extends DataClass
    implements Insertable<TaskNotificationRow> {
  final String id;
  final String? taskId;
  final NotificationCategory category;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;
  const TaskNotificationRow({
    required this.id,
    this.taskId,
    required this.category,
    required this.title,
    required this.body,
    required this.createdAt,
    this.readAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || taskId != null) {
      map['task_id'] = Variable<String>(taskId);
    }
    {
      map['category'] = Variable<int>(
        $TaskNotificationsTable.$convertercategory.toSql(category),
      );
    }
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || readAt != null) {
      map['read_at'] = Variable<DateTime>(readAt);
    }
    return map;
  }

  TaskNotificationsCompanion toCompanion(bool nullToAbsent) {
    return TaskNotificationsCompanion(
      id: Value(id),
      taskId: taskId == null && nullToAbsent
          ? const Value.absent()
          : Value(taskId),
      category: Value(category),
      title: Value(title),
      body: Value(body),
      createdAt: Value(createdAt),
      readAt: readAt == null && nullToAbsent
          ? const Value.absent()
          : Value(readAt),
    );
  }

  factory TaskNotificationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskNotificationRow(
      id: serializer.fromJson<String>(json['id']),
      taskId: serializer.fromJson<String?>(json['taskId']),
      category: $TaskNotificationsTable.$convertercategory.fromJson(
        serializer.fromJson<int>(json['category']),
      ),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      readAt: serializer.fromJson<DateTime?>(json['readAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'taskId': serializer.toJson<String?>(taskId),
      'category': serializer.toJson<int>(
        $TaskNotificationsTable.$convertercategory.toJson(category),
      ),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'readAt': serializer.toJson<DateTime?>(readAt),
    };
  }

  TaskNotificationRow copyWith({
    String? id,
    Value<String?> taskId = const Value.absent(),
    NotificationCategory? category,
    String? title,
    String? body,
    DateTime? createdAt,
    Value<DateTime?> readAt = const Value.absent(),
  }) => TaskNotificationRow(
    id: id ?? this.id,
    taskId: taskId.present ? taskId.value : this.taskId,
    category: category ?? this.category,
    title: title ?? this.title,
    body: body ?? this.body,
    createdAt: createdAt ?? this.createdAt,
    readAt: readAt.present ? readAt.value : this.readAt,
  );
  TaskNotificationRow copyWithCompanion(TaskNotificationsCompanion data) {
    return TaskNotificationRow(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      category: data.category.present ? data.category.value : this.category,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      readAt: data.readAt.present ? data.readAt.value : this.readAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskNotificationRow(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('category: $category, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('readAt: $readAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, taskId, category, title, body, createdAt, readAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskNotificationRow &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.category == this.category &&
          other.title == this.title &&
          other.body == this.body &&
          other.createdAt == this.createdAt &&
          other.readAt == this.readAt);
}

class TaskNotificationsCompanion extends UpdateCompanion<TaskNotificationRow> {
  final Value<String> id;
  final Value<String?> taskId;
  final Value<NotificationCategory> category;
  final Value<String> title;
  final Value<String> body;
  final Value<DateTime> createdAt;
  final Value<DateTime?> readAt;
  final Value<int> rowid;
  const TaskNotificationsCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.category = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.readAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskNotificationsCompanion.insert({
    required String id,
    this.taskId = const Value.absent(),
    required NotificationCategory category,
    required String title,
    required String body,
    this.createdAt = const Value.absent(),
    this.readAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       category = Value(category),
       title = Value(title),
       body = Value(body);
  static Insertable<TaskNotificationRow> custom({
    Expression<String>? id,
    Expression<String>? taskId,
    Expression<int>? category,
    Expression<String>? title,
    Expression<String>? body,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? readAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (category != null) 'category': category,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (createdAt != null) 'created_at': createdAt,
      if (readAt != null) 'read_at': readAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskNotificationsCompanion copyWith({
    Value<String>? id,
    Value<String?>? taskId,
    Value<NotificationCategory>? category,
    Value<String>? title,
    Value<String>? body,
    Value<DateTime>? createdAt,
    Value<DateTime?>? readAt,
    Value<int>? rowid,
  }) {
    return TaskNotificationsCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      category: category ?? this.category,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (category.present) {
      map['category'] = Variable<int>(
        $TaskNotificationsTable.$convertercategory.toSql(category.value),
      );
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (readAt.present) {
      map['read_at'] = Variable<DateTime>(readAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskNotificationsCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('category: $category, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('readAt: $readAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSettingRow extends DataClass implements Insertable<AppSettingRow> {
  final String key;
  final String value;
  const AppSettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSettingRow copyWith({String? key, String? value}) =>
      AppSettingRow(key: key ?? this.key, value: value ?? this.value);
  AppSettingRow copyWithCompanion(AppSettingsCompanion data) {
    return AppSettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $TaskNotificationsTable taskNotifications =
      $TaskNotificationsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    categories,
    tasks,
    reminders,
    taskNotifications,
    appSettings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'categories',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tasks', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tasks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('reminders', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('task_notifications', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  required String id,
  required String name,
  Value<String> icon,
  required int color,
  Value<bool> isDefault,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> icon,
  Value<int> color,
  Value<bool> isDefault,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TasksTable, List<TaskRow>> _tasksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.tasks,
    aliasName: 'categories__id__tasks__category_id',
  );

  $$TasksTableProcessedTableManager get tasksRefs {
    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_tasksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
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

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> tasksRefs(
    Expression<bool> Function($$TasksTableFilterComposer f) f,
  ) {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
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

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
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

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> tasksRefs<T extends Object>(
    Expression<T> Function($$TasksTableAnnotationComposer a) f,
  ) {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          CategoryRow,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (CategoryRow, $$CategoriesTableReferences),
          CategoryRow,
          PrefetchHooks Function({bool tasksRefs})
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                name: name,
                icon: icon,
                color: color,
                isDefault: isDefault,
                sortOrder: sortOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> icon = const Value.absent(),
                required int color,
                Value<bool> isDefault = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                name: name,
                icon: icon,
                color: color,
                isDefault: isDefault,
                sortOrder: sortOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategoriesTable, CategoryRow>(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({tasksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (tasksRefs) db.tasks],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (tasksRefs)
                    await $_getPrefetchedData<
                      CategoryRow,
                      $CategoriesTable,
                      TaskRow
                    >(
                      currentTable: table,
                      referencedTable: $$CategoriesTableReferences
                          ._tasksRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CategoriesTableReferences(db, table, p0).tasksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.categoryId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      CategoryRow,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (CategoryRow, $$CategoriesTableReferences),
      CategoryRow,
      PrefetchHooks Function({bool tasksRefs})
    >;
typedef $$TasksTableCreateCompanionBuilder = TasksCompanion Function({
  required String id,
  required String title,
  Value<String?> description,
  Value<String?> notes,
  Value<String?> categoryId,
  required Priority priority,
  required TaskStatus status,
  Value<DateTime?> deadline,
  Value<bool> isRecurring,
  required RecurrenceType recurrenceType,
  Value<String?> recurrenceDays,
  Value<String?> recurrenceSourceId,
  Value<DateTime?> completedAt,
  Value<String?> parentTaskId,
  Value<String?> userId,
  Value<AlarmType> alarmType,
  Value<bool> repeatUntilCompleted,
  Value<int> repeatIntervalMinutes,
  Value<int> maxRepeatCount,
  Value<int> currentRepeatCount,
  Value<String?> customNotificationTitle,
  Value<String?> customNotificationBody,
  Value<NotificationSound> soundChoice,
  Value<NotificationVibration> vibrationChoice,
  Value<DateTime?> snoozeUntil,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$TasksTableUpdateCompanionBuilder = TasksCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String?> description,
  Value<String?> notes,
  Value<String?> categoryId,
  Value<Priority> priority,
  Value<TaskStatus> status,
  Value<DateTime?> deadline,
  Value<bool> isRecurring,
  Value<RecurrenceType> recurrenceType,
  Value<String?> recurrenceDays,
  Value<String?> recurrenceSourceId,
  Value<DateTime?> completedAt,
  Value<String?> parentTaskId,
  Value<String?> userId,
  Value<AlarmType> alarmType,
  Value<bool> repeatUntilCompleted,
  Value<int> repeatIntervalMinutes,
  Value<int> maxRepeatCount,
  Value<int> currentRepeatCount,
  Value<String?> customNotificationTitle,
  Value<String?> customNotificationBody,
  Value<NotificationSound> soundChoice,
  Value<NotificationVibration> vibrationChoice,
  Value<DateTime?> snoozeUntil,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$TasksTableReferences
    extends BaseReferences<_$AppDatabase, $TasksTable, TaskRow> {
  $$TasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('tasks__category_id__categories__id');

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<String>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TasksTable _parentTaskIdTable(_$AppDatabase db) =>
      db.tasks.createAlias('tasks__parent_task_id__tasks__id');

  $$TasksTableProcessedTableManager? get parentTaskId {
    final $_column = $_itemColumn<String>('parent_task_id');
    if ($_column == null) return null;
    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentTaskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$RemindersTable, List<ReminderRow>>
  _remindersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.reminders,
    aliasName: 'tasks__id__reminders__task_id',
  );

  $$RemindersTableProcessedTableManager get remindersRefs {
    final manager = $$RemindersTableTableManager(
      $_db,
      $_db.reminders,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_remindersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TaskNotificationsTable, List<TaskNotificationRow>>
  _taskNotificationsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.taskNotifications,
        aliasName: 'tasks__id__task_notifications__task_id',
      );

  $$TaskNotificationsTableProcessedTableManager get taskNotificationsRefs {
    final manager = $$TaskNotificationsTableTableManager(
      $_db,
      $_db.taskNotifications,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _taskNotificationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Priority, Priority, int> get priority =>
      $composableBuilder(
        column: $table.priority,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<TaskStatus, TaskStatus, int> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get deadline => $composableBuilder(
    column: $table.deadline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRecurring => $composableBuilder(
    column: $table.isRecurring,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<RecurrenceType, RecurrenceType, int>
  get recurrenceType => $composableBuilder(
    column: $table.recurrenceType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get recurrenceDays => $composableBuilder(
    column: $table.recurrenceDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurrenceSourceId => $composableBuilder(
    column: $table.recurrenceSourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AlarmType, AlarmType, int> get alarmType =>
      $composableBuilder(
        column: $table.alarmType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get repeatUntilCompleted => $composableBuilder(
    column: $table.repeatUntilCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repeatIntervalMinutes => $composableBuilder(
    column: $table.repeatIntervalMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxRepeatCount => $composableBuilder(
    column: $table.maxRepeatCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentRepeatCount => $composableBuilder(
    column: $table.currentRepeatCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customNotificationTitle => $composableBuilder(
    column: $table.customNotificationTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customNotificationBody => $composableBuilder(
    column: $table.customNotificationBody,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<NotificationSound, NotificationSound, int>
  get soundChoice => $composableBuilder(
    column: $table.soundChoice,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<
    NotificationVibration,
    NotificationVibration,
    int
  >
  get vibrationChoice => $composableBuilder(
    column: $table.vibrationChoice,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get snoozeUntil => $composableBuilder(
    column: $table.snoozeUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TasksTableFilterComposer get parentTaskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentTaskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> remindersRefs(
    Expression<bool> Function($$RemindersTableFilterComposer f) f,
  ) {
    final $$RemindersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reminders,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemindersTableFilterComposer(
            $db: $db,
            $table: $db.reminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> taskNotificationsRefs(
    Expression<bool> Function($$TaskNotificationsTableFilterComposer f) f,
  ) {
    final $$TaskNotificationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskNotifications,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskNotificationsTableFilterComposer(
            $db: $db,
            $table: $db.taskNotifications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deadline => $composableBuilder(
    column: $table.deadline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRecurring => $composableBuilder(
    column: $table.isRecurring,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recurrenceType => $composableBuilder(
    column: $table.recurrenceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrenceDays => $composableBuilder(
    column: $table.recurrenceDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrenceSourceId => $composableBuilder(
    column: $table.recurrenceSourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get alarmType => $composableBuilder(
    column: $table.alarmType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get repeatUntilCompleted => $composableBuilder(
    column: $table.repeatUntilCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repeatIntervalMinutes => $composableBuilder(
    column: $table.repeatIntervalMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxRepeatCount => $composableBuilder(
    column: $table.maxRepeatCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentRepeatCount => $composableBuilder(
    column: $table.currentRepeatCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customNotificationTitle => $composableBuilder(
    column: $table.customNotificationTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customNotificationBody => $composableBuilder(
    column: $table.customNotificationBody,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get soundChoice => $composableBuilder(
    column: $table.soundChoice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get vibrationChoice => $composableBuilder(
    column: $table.vibrationChoice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get snoozeUntil => $composableBuilder(
    column: $table.snoozeUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TasksTableOrderingComposer get parentTaskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentTaskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Priority, int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TaskStatus, int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get deadline =>
      $composableBuilder(column: $table.deadline, builder: (column) => column);

  GeneratedColumn<bool> get isRecurring => $composableBuilder(
    column: $table.isRecurring,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<RecurrenceType, int> get recurrenceType =>
      $composableBuilder(
        column: $table.recurrenceType,
        builder: (column) => column,
      );

  GeneratedColumn<String> get recurrenceDays => $composableBuilder(
    column: $table.recurrenceDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recurrenceSourceId => $composableBuilder(
    column: $table.recurrenceSourceId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AlarmType, int> get alarmType =>
      $composableBuilder(column: $table.alarmType, builder: (column) => column);

  GeneratedColumn<bool> get repeatUntilCompleted => $composableBuilder(
    column: $table.repeatUntilCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get repeatIntervalMinutes => $composableBuilder(
    column: $table.repeatIntervalMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get maxRepeatCount => $composableBuilder(
    column: $table.maxRepeatCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentRepeatCount => $composableBuilder(
    column: $table.currentRepeatCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customNotificationTitle => $composableBuilder(
    column: $table.customNotificationTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customNotificationBody => $composableBuilder(
    column: $table.customNotificationBody,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<NotificationSound, int> get soundChoice =>
      $composableBuilder(
        column: $table.soundChoice,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<NotificationVibration, int>
  get vibrationChoice => $composableBuilder(
    column: $table.vibrationChoice,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get snoozeUntil => $composableBuilder(
    column: $table.snoozeUntil,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TasksTableAnnotationComposer get parentTaskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentTaskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> remindersRefs<T extends Object>(
    Expression<T> Function($$RemindersTableAnnotationComposer a) f,
  ) {
    final $$RemindersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reminders,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemindersTableAnnotationComposer(
            $db: $db,
            $table: $db.reminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> taskNotificationsRefs<T extends Object>(
    Expression<T> Function($$TaskNotificationsTableAnnotationComposer a) f,
  ) {
    final $$TaskNotificationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.taskNotifications,
          getReferencedColumn: (t) => t.taskId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TaskNotificationsTableAnnotationComposer(
                $db: $db,
                $table: $db.taskNotifications,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTable,
          TaskRow,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (TaskRow, $$TasksTableReferences),
          TaskRow,
          PrefetchHooks Function({
            bool categoryId,
            bool parentTaskId,
            bool remindersRefs,
            bool taskNotificationsRefs,
          })
        > {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<Priority> priority = const Value.absent(),
                Value<TaskStatus> status = const Value.absent(),
                Value<DateTime?> deadline = const Value.absent(),
                Value<bool> isRecurring = const Value.absent(),
                Value<RecurrenceType> recurrenceType = const Value.absent(),
                Value<String?> recurrenceDays = const Value.absent(),
                Value<String?> recurrenceSourceId = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> parentTaskId = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<AlarmType> alarmType = const Value.absent(),
                Value<bool> repeatUntilCompleted = const Value.absent(),
                Value<int> repeatIntervalMinutes = const Value.absent(),
                Value<int> maxRepeatCount = const Value.absent(),
                Value<int> currentRepeatCount = const Value.absent(),
                Value<String?> customNotificationTitle = const Value.absent(),
                Value<String?> customNotificationBody = const Value.absent(),
                Value<NotificationSound> soundChoice = const Value.absent(),
                Value<NotificationVibration> vibrationChoice =
                    const Value.absent(),
                Value<DateTime?> snoozeUntil = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                title: title,
                description: description,
                notes: notes,
                categoryId: categoryId,
                priority: priority,
                status: status,
                deadline: deadline,
                isRecurring: isRecurring,
                recurrenceType: recurrenceType,
                recurrenceDays: recurrenceDays,
                recurrenceSourceId: recurrenceSourceId,
                completedAt: completedAt,
                parentTaskId: parentTaskId,
                userId: userId,
                alarmType: alarmType,
                repeatUntilCompleted: repeatUntilCompleted,
                repeatIntervalMinutes: repeatIntervalMinutes,
                maxRepeatCount: maxRepeatCount,
                currentRepeatCount: currentRepeatCount,
                customNotificationTitle: customNotificationTitle,
                customNotificationBody: customNotificationBody,
                soundChoice: soundChoice,
                vibrationChoice: vibrationChoice,
                snoozeUntil: snoozeUntil,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> description = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                required Priority priority,
                required TaskStatus status,
                Value<DateTime?> deadline = const Value.absent(),
                Value<bool> isRecurring = const Value.absent(),
                required RecurrenceType recurrenceType,
                Value<String?> recurrenceDays = const Value.absent(),
                Value<String?> recurrenceSourceId = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> parentTaskId = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<AlarmType> alarmType = const Value.absent(),
                Value<bool> repeatUntilCompleted = const Value.absent(),
                Value<int> repeatIntervalMinutes = const Value.absent(),
                Value<int> maxRepeatCount = const Value.absent(),
                Value<int> currentRepeatCount = const Value.absent(),
                Value<String?> customNotificationTitle = const Value.absent(),
                Value<String?> customNotificationBody = const Value.absent(),
                Value<NotificationSound> soundChoice = const Value.absent(),
                Value<NotificationVibration> vibrationChoice =
                    const Value.absent(),
                Value<DateTime?> snoozeUntil = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                title: title,
                description: description,
                notes: notes,
                categoryId: categoryId,
                priority: priority,
                status: status,
                deadline: deadline,
                isRecurring: isRecurring,
                recurrenceType: recurrenceType,
                recurrenceDays: recurrenceDays,
                recurrenceSourceId: recurrenceSourceId,
                completedAt: completedAt,
                parentTaskId: parentTaskId,
                userId: userId,
                alarmType: alarmType,
                repeatUntilCompleted: repeatUntilCompleted,
                repeatIntervalMinutes: repeatIntervalMinutes,
                maxRepeatCount: maxRepeatCount,
                currentRepeatCount: currentRepeatCount,
                customNotificationTitle: customNotificationTitle,
                customNotificationBody: customNotificationBody,
                soundChoice: soundChoice,
                vibrationChoice: vibrationChoice,
                snoozeUntil: snoozeUntil,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TasksTable, TaskRow>(table),
                  $$TasksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                categoryId = false,
                parentTaskId = false,
                remindersRefs = false,
                taskNotificationsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (remindersRefs) db.reminders,
                    if (taskNotificationsRefs) db.taskNotifications,
                  ],
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
                        if (categoryId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.categoryId,
                            referencedTable: $$TasksTableReferences
                                ._categoryIdTable(db),
                            referencedColumn: $$TasksTableReferences
                                ._categoryIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (parentTaskId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.parentTaskId,
                            referencedTable: $$TasksTableReferences
                                ._parentTaskIdTable(db),
                            referencedColumn: $$TasksTableReferences
                                ._parentTaskIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (remindersRefs)
                        await $_getPrefetchedData<
                          TaskRow,
                          $TasksTable,
                          ReminderRow
                        >(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences
                              ._remindersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TasksTableReferences(
                                db,
                                table,
                                p0,
                              ).remindersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (taskNotificationsRefs)
                        await $_getPrefetchedData<
                          TaskRow,
                          $TasksTable,
                          TaskNotificationRow
                        >(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences
                              ._taskNotificationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TasksTableReferences(
                                db,
                                table,
                                p0,
                              ).taskNotificationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
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

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTable,
      TaskRow,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (TaskRow, $$TasksTableReferences),
      TaskRow,
      PrefetchHooks Function({
        bool categoryId,
        bool parentTaskId,
        bool remindersRefs,
        bool taskNotificationsRefs,
      })
    >;
typedef $$RemindersTableCreateCompanionBuilder = RemindersCompanion Function({
  required String id,
  required String taskId,
  required ReminderKind kind,
  Value<int?> minutesBefore,
  required DateTime scheduledAt,
  required int notificationId,
  Value<bool> enabled,
  Value<DateTime?> notifiedAt,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$RemindersTableUpdateCompanionBuilder = RemindersCompanion Function({
  Value<String> id,
  Value<String> taskId,
  Value<ReminderKind> kind,
  Value<int?> minutesBefore,
  Value<DateTime> scheduledAt,
  Value<int> notificationId,
  Value<bool> enabled,
  Value<DateTime?> notifiedAt,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$RemindersTableReferences
    extends BaseReferences<_$AppDatabase, $RemindersTable, ReminderRow> {
  $$RemindersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TasksTable _taskIdTable(_$AppDatabase db) =>
      db.tasks.createAlias('reminders__task_id__tasks__id');

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RemindersTableFilterComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableFilterComposer({
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

  ColumnWithTypeConverterFilters<ReminderKind, ReminderKind, int> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get minutesBefore => $composableBuilder(
    column: $table.minutesBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get notificationId => $composableBuilder(
    column: $table.notificationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get notifiedAt => $composableBuilder(
    column: $table.notifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableOrderingComposer({
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

  ColumnOrderings<int> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minutesBefore => $composableBuilder(
    column: $table.minutesBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get notificationId => $composableBuilder(
    column: $table.notificationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get notifiedAt => $composableBuilder(
    column: $table.notifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ReminderKind, int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get minutesBefore => $composableBuilder(
    column: $table.minutesBefore,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get notificationId => $composableBuilder(
    column: $table.notificationId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<DateTime> get notifiedAt => $composableBuilder(
    column: $table.notifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemindersTable,
          ReminderRow,
          $$RemindersTableFilterComposer,
          $$RemindersTableOrderingComposer,
          $$RemindersTableAnnotationComposer,
          $$RemindersTableCreateCompanionBuilder,
          $$RemindersTableUpdateCompanionBuilder,
          (ReminderRow, $$RemindersTableReferences),
          ReminderRow,
          PrefetchHooks Function({bool taskId})
        > {
  $$RemindersTableTableManager(_$AppDatabase db, $RemindersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> taskId = const Value.absent(),
                Value<ReminderKind> kind = const Value.absent(),
                Value<int?> minutesBefore = const Value.absent(),
                Value<DateTime> scheduledAt = const Value.absent(),
                Value<int> notificationId = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<DateTime?> notifiedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemindersCompanion(
                id: id,
                taskId: taskId,
                kind: kind,
                minutesBefore: minutesBefore,
                scheduledAt: scheduledAt,
                notificationId: notificationId,
                enabled: enabled,
                notifiedAt: notifiedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String taskId,
                required ReminderKind kind,
                Value<int?> minutesBefore = const Value.absent(),
                required DateTime scheduledAt,
                required int notificationId,
                Value<bool> enabled = const Value.absent(),
                Value<DateTime?> notifiedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemindersCompanion.insert(
                id: id,
                taskId: taskId,
                kind: kind,
                minutesBefore: minutesBefore,
                scheduledAt: scheduledAt,
                notificationId: notificationId,
                enabled: enabled,
                notifiedAt: notifiedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RemindersTable, ReminderRow>(table),
                  $$RemindersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
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
                    if (taskId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.taskId,
                        referencedTable: $$RemindersTableReferences
                            ._taskIdTable(db),
                        referencedColumn: $$RemindersTableReferences
                            ._taskIdTable(db)
                            .id,
                      ) as T;
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

typedef $$RemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemindersTable,
      ReminderRow,
      $$RemindersTableFilterComposer,
      $$RemindersTableOrderingComposer,
      $$RemindersTableAnnotationComposer,
      $$RemindersTableCreateCompanionBuilder,
      $$RemindersTableUpdateCompanionBuilder,
      (ReminderRow, $$RemindersTableReferences),
      ReminderRow,
      PrefetchHooks Function({bool taskId})
    >;
typedef $$TaskNotificationsTableCreateCompanionBuilder =
    TaskNotificationsCompanion Function({
      required String id,
      Value<String?> taskId,
      required NotificationCategory category,
      required String title,
      required String body,
      Value<DateTime> createdAt,
      Value<DateTime?> readAt,
      Value<int> rowid,
    });
typedef $$TaskNotificationsTableUpdateCompanionBuilder =
    TaskNotificationsCompanion Function({
      Value<String> id,
      Value<String?> taskId,
      Value<NotificationCategory> category,
      Value<String> title,
      Value<String> body,
      Value<DateTime> createdAt,
      Value<DateTime?> readAt,
      Value<int> rowid,
    });

final class $$TaskNotificationsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TaskNotificationsTable,
          TaskNotificationRow
        > {
  $$TaskNotificationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TasksTable _taskIdTable(_$AppDatabase db) =>
      db.tasks.createAlias('task_notifications__task_id__tasks__id');

  $$TasksTableProcessedTableManager? get taskId {
    final $_column = $_itemColumn<String>('task_id');
    if ($_column == null) return null;
    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TaskNotificationsTableFilterComposer
    extends Composer<_$AppDatabase, $TaskNotificationsTable> {
  $$TaskNotificationsTableFilterComposer({
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

  ColumnWithTypeConverterFilters<
    NotificationCategory,
    NotificationCategory,
    int
  >
  get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get readAt => $composableBuilder(
    column: $table.readAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskNotificationsTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskNotificationsTable> {
  $$TaskNotificationsTableOrderingComposer({
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

  ColumnOrderings<int> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get readAt => $composableBuilder(
    column: $table.readAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskNotificationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskNotificationsTable> {
  $$TaskNotificationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<NotificationCategory, int> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get readAt =>
      $composableBuilder(column: $table.readAt, builder: (column) => column);

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskNotificationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskNotificationsTable,
          TaskNotificationRow,
          $$TaskNotificationsTableFilterComposer,
          $$TaskNotificationsTableOrderingComposer,
          $$TaskNotificationsTableAnnotationComposer,
          $$TaskNotificationsTableCreateCompanionBuilder,
          $$TaskNotificationsTableUpdateCompanionBuilder,
          (TaskNotificationRow, $$TaskNotificationsTableReferences),
          TaskNotificationRow,
          PrefetchHooks Function({bool taskId})
        > {
  $$TaskNotificationsTableTableManager(
    _$AppDatabase db,
    $TaskNotificationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskNotificationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskNotificationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskNotificationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> taskId = const Value.absent(),
                Value<NotificationCategory> category = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> readAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskNotificationsCompanion(
                id: id,
                taskId: taskId,
                category: category,
                title: title,
                body: body,
                createdAt: createdAt,
                readAt: readAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> taskId = const Value.absent(),
                required NotificationCategory category,
                required String title,
                required String body,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> readAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskNotificationsCompanion.insert(
                id: id,
                taskId: taskId,
                category: category,
                title: title,
                body: body,
                createdAt: createdAt,
                readAt: readAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TaskNotificationsTable, TaskNotificationRow>(
                    table,
                  ),
                  $$TaskNotificationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
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
                    if (taskId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.taskId,
                        referencedTable: $$TaskNotificationsTableReferences
                            ._taskIdTable(db),
                        referencedColumn: $$TaskNotificationsTableReferences
                            ._taskIdTable(db)
                            .id,
                      ) as T;
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

typedef $$TaskNotificationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskNotificationsTable,
      TaskNotificationRow,
      $$TaskNotificationsTableFilterComposer,
      $$TaskNotificationsTableOrderingComposer,
      $$TaskNotificationsTableAnnotationComposer,
      $$TaskNotificationsTableCreateCompanionBuilder,
      $$TaskNotificationsTableUpdateCompanionBuilder,
      (TaskNotificationRow, $$TaskNotificationsTableReferences),
      TaskNotificationRow,
      PrefetchHooks Function({bool taskId})
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSettingRow,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSettingRow,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingRow>,
          ),
          AppSettingRow,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSettingRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AppSettingsTable,
                    AppSettingRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSettingRow,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSettingRow,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingRow>,
      ),
      AppSettingRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db, _db.reminders);
  $$TaskNotificationsTableTableManager get taskNotifications =>
      $$TaskNotificationsTableTableManager(_db, _db.taskNotifications);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
