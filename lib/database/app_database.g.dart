// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $JourneysTable extends Journeys with TableInfo<$JourneysTable, Journey> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JourneysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pjpIdMeta = const VerificationMeta('pjpId');
  @override
  late final GeneratedColumn<String> pjpId = GeneratedColumn<String>(
    'pjp_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dealerIdMeta = const VerificationMeta(
    'dealerId',
  );
  @override
  late final GeneratedColumn<String> dealerId = GeneratedColumn<String>(
    'dealer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _verifiedDealerIdMeta = const VerificationMeta(
    'verifiedDealerId',
  );
  @override
  late final GeneratedColumn<int> verifiedDealerId = GeneratedColumn<int>(
    'verified_dealer_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ACTIVE'),
  );
  static const VerificationMeta _siteNameMeta = const VerificationMeta(
    'siteName',
  );
  @override
  late final GeneratedColumn<String> siteName = GeneratedColumn<String>(
    'site_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalDistanceMeta = const VerificationMeta(
    'totalDistance',
  );
  @override
  late final GeneratedColumn<double> totalDistance = GeneratedColumn<double>(
    'total_distance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
    'end_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    pjpId,
    taskId,
    dealerId,
    verifiedDealerId,
    status,
    siteName,
    totalDistance,
    startTime,
    endTime,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journeys';
  @override
  VerificationContext validateIntegrity(
    Insertable<Journey> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('pjp_id')) {
      context.handle(
        _pjpIdMeta,
        pjpId.isAcceptableOrUnknown(data['pjp_id']!, _pjpIdMeta),
      );
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    }
    if (data.containsKey('dealer_id')) {
      context.handle(
        _dealerIdMeta,
        dealerId.isAcceptableOrUnknown(data['dealer_id']!, _dealerIdMeta),
      );
    }
    if (data.containsKey('verified_dealer_id')) {
      context.handle(
        _verifiedDealerIdMeta,
        verifiedDealerId.isAcceptableOrUnknown(
          data['verified_dealer_id']!,
          _verifiedDealerIdMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('site_name')) {
      context.handle(
        _siteNameMeta,
        siteName.isAcceptableOrUnknown(data['site_name']!, _siteNameMeta),
      );
    }
    if (data.containsKey('total_distance')) {
      context.handle(
        _totalDistanceMeta,
        totalDistance.isAcceptableOrUnknown(
          data['total_distance']!,
          _totalDistanceMeta,
        ),
      );
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Journey map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Journey(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      pjpId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pjp_id'],
      ),
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      ),
      dealerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dealer_id'],
      ),
      verifiedDealerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}verified_dealer_id'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      siteName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}site_name'],
      ),
      totalDistance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_distance'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_time'],
      ),
    );
  }

  @override
  $JourneysTable createAlias(String alias) {
    return $JourneysTable(attachedDatabase, alias);
  }
}

class Journey extends DataClass implements Insertable<Journey> {
  final String id;
  final int userId;
  final String? pjpId;
  final String? taskId;
  final String? dealerId;
  final int? verifiedDealerId;
  final String status;
  final String? siteName;
  final double totalDistance;
  final DateTime startTime;
  final DateTime? endTime;
  const Journey({
    required this.id,
    required this.userId,
    this.pjpId,
    this.taskId,
    this.dealerId,
    this.verifiedDealerId,
    required this.status,
    this.siteName,
    required this.totalDistance,
    required this.startTime,
    this.endTime,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<int>(userId);
    if (!nullToAbsent || pjpId != null) {
      map['pjp_id'] = Variable<String>(pjpId);
    }
    if (!nullToAbsent || taskId != null) {
      map['task_id'] = Variable<String>(taskId);
    }
    if (!nullToAbsent || dealerId != null) {
      map['dealer_id'] = Variable<String>(dealerId);
    }
    if (!nullToAbsent || verifiedDealerId != null) {
      map['verified_dealer_id'] = Variable<int>(verifiedDealerId);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || siteName != null) {
      map['site_name'] = Variable<String>(siteName);
    }
    map['total_distance'] = Variable<double>(totalDistance);
    map['start_time'] = Variable<DateTime>(startTime);
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<DateTime>(endTime);
    }
    return map;
  }

  JourneysCompanion toCompanion(bool nullToAbsent) {
    return JourneysCompanion(
      id: Value(id),
      userId: Value(userId),
      pjpId: pjpId == null && nullToAbsent
          ? const Value.absent()
          : Value(pjpId),
      taskId: taskId == null && nullToAbsent
          ? const Value.absent()
          : Value(taskId),
      dealerId: dealerId == null && nullToAbsent
          ? const Value.absent()
          : Value(dealerId),
      verifiedDealerId: verifiedDealerId == null && nullToAbsent
          ? const Value.absent()
          : Value(verifiedDealerId),
      status: Value(status),
      siteName: siteName == null && nullToAbsent
          ? const Value.absent()
          : Value(siteName),
      totalDistance: Value(totalDistance),
      startTime: Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
    );
  }

  factory Journey.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Journey(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      pjpId: serializer.fromJson<String?>(json['pjpId']),
      taskId: serializer.fromJson<String?>(json['taskId']),
      dealerId: serializer.fromJson<String?>(json['dealerId']),
      verifiedDealerId: serializer.fromJson<int?>(json['verifiedDealerId']),
      status: serializer.fromJson<String>(json['status']),
      siteName: serializer.fromJson<String?>(json['siteName']),
      totalDistance: serializer.fromJson<double>(json['totalDistance']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime?>(json['endTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<int>(userId),
      'pjpId': serializer.toJson<String?>(pjpId),
      'taskId': serializer.toJson<String?>(taskId),
      'dealerId': serializer.toJson<String?>(dealerId),
      'verifiedDealerId': serializer.toJson<int?>(verifiedDealerId),
      'status': serializer.toJson<String>(status),
      'siteName': serializer.toJson<String?>(siteName),
      'totalDistance': serializer.toJson<double>(totalDistance),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime?>(endTime),
    };
  }

  Journey copyWith({
    String? id,
    int? userId,
    Value<String?> pjpId = const Value.absent(),
    Value<String?> taskId = const Value.absent(),
    Value<String?> dealerId = const Value.absent(),
    Value<int?> verifiedDealerId = const Value.absent(),
    String? status,
    Value<String?> siteName = const Value.absent(),
    double? totalDistance,
    DateTime? startTime,
    Value<DateTime?> endTime = const Value.absent(),
  }) => Journey(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    pjpId: pjpId.present ? pjpId.value : this.pjpId,
    taskId: taskId.present ? taskId.value : this.taskId,
    dealerId: dealerId.present ? dealerId.value : this.dealerId,
    verifiedDealerId: verifiedDealerId.present
        ? verifiedDealerId.value
        : this.verifiedDealerId,
    status: status ?? this.status,
    siteName: siteName.present ? siteName.value : this.siteName,
    totalDistance: totalDistance ?? this.totalDistance,
    startTime: startTime ?? this.startTime,
    endTime: endTime.present ? endTime.value : this.endTime,
  );
  Journey copyWithCompanion(JourneysCompanion data) {
    return Journey(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      pjpId: data.pjpId.present ? data.pjpId.value : this.pjpId,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      dealerId: data.dealerId.present ? data.dealerId.value : this.dealerId,
      verifiedDealerId: data.verifiedDealerId.present
          ? data.verifiedDealerId.value
          : this.verifiedDealerId,
      status: data.status.present ? data.status.value : this.status,
      siteName: data.siteName.present ? data.siteName.value : this.siteName,
      totalDistance: data.totalDistance.present
          ? data.totalDistance.value
          : this.totalDistance,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Journey(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('pjpId: $pjpId, ')
          ..write('taskId: $taskId, ')
          ..write('dealerId: $dealerId, ')
          ..write('verifiedDealerId: $verifiedDealerId, ')
          ..write('status: $status, ')
          ..write('siteName: $siteName, ')
          ..write('totalDistance: $totalDistance, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    pjpId,
    taskId,
    dealerId,
    verifiedDealerId,
    status,
    siteName,
    totalDistance,
    startTime,
    endTime,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Journey &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.pjpId == this.pjpId &&
          other.taskId == this.taskId &&
          other.dealerId == this.dealerId &&
          other.verifiedDealerId == this.verifiedDealerId &&
          other.status == this.status &&
          other.siteName == this.siteName &&
          other.totalDistance == this.totalDistance &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime);
}

class JourneysCompanion extends UpdateCompanion<Journey> {
  final Value<String> id;
  final Value<int> userId;
  final Value<String?> pjpId;
  final Value<String?> taskId;
  final Value<String?> dealerId;
  final Value<int?> verifiedDealerId;
  final Value<String> status;
  final Value<String?> siteName;
  final Value<double> totalDistance;
  final Value<DateTime> startTime;
  final Value<DateTime?> endTime;
  final Value<int> rowid;
  const JourneysCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.pjpId = const Value.absent(),
    this.taskId = const Value.absent(),
    this.dealerId = const Value.absent(),
    this.verifiedDealerId = const Value.absent(),
    this.status = const Value.absent(),
    this.siteName = const Value.absent(),
    this.totalDistance = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JourneysCompanion.insert({
    required String id,
    required int userId,
    this.pjpId = const Value.absent(),
    this.taskId = const Value.absent(),
    this.dealerId = const Value.absent(),
    this.verifiedDealerId = const Value.absent(),
    this.status = const Value.absent(),
    this.siteName = const Value.absent(),
    this.totalDistance = const Value.absent(),
    required DateTime startTime,
    this.endTime = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       startTime = Value(startTime);
  static Insertable<Journey> custom({
    Expression<String>? id,
    Expression<int>? userId,
    Expression<String>? pjpId,
    Expression<String>? taskId,
    Expression<String>? dealerId,
    Expression<int>? verifiedDealerId,
    Expression<String>? status,
    Expression<String>? siteName,
    Expression<double>? totalDistance,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (pjpId != null) 'pjp_id': pjpId,
      if (taskId != null) 'task_id': taskId,
      if (dealerId != null) 'dealer_id': dealerId,
      if (verifiedDealerId != null) 'verified_dealer_id': verifiedDealerId,
      if (status != null) 'status': status,
      if (siteName != null) 'site_name': siteName,
      if (totalDistance != null) 'total_distance': totalDistance,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JourneysCompanion copyWith({
    Value<String>? id,
    Value<int>? userId,
    Value<String?>? pjpId,
    Value<String?>? taskId,
    Value<String?>? dealerId,
    Value<int?>? verifiedDealerId,
    Value<String>? status,
    Value<String?>? siteName,
    Value<double>? totalDistance,
    Value<DateTime>? startTime,
    Value<DateTime?>? endTime,
    Value<int>? rowid,
  }) {
    return JourneysCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      pjpId: pjpId ?? this.pjpId,
      taskId: taskId ?? this.taskId,
      dealerId: dealerId ?? this.dealerId,
      verifiedDealerId: verifiedDealerId ?? this.verifiedDealerId,
      status: status ?? this.status,
      siteName: siteName ?? this.siteName,
      totalDistance: totalDistance ?? this.totalDistance,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (pjpId.present) {
      map['pjp_id'] = Variable<String>(pjpId.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (dealerId.present) {
      map['dealer_id'] = Variable<String>(dealerId.value);
    }
    if (verifiedDealerId.present) {
      map['verified_dealer_id'] = Variable<int>(verifiedDealerId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (siteName.present) {
      map['site_name'] = Variable<String>(siteName.value);
    }
    if (totalDistance.present) {
      map['total_distance'] = Variable<double>(totalDistance.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JourneysCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('pjpId: $pjpId, ')
          ..write('taskId: $taskId, ')
          ..write('dealerId: $dealerId, ')
          ..write('verifiedDealerId: $verifiedDealerId, ')
          ..write('status: $status, ')
          ..write('siteName: $siteName, ')
          ..write('totalDistance: $totalDistance, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JourneyBreadcrumbsTable extends JourneyBreadcrumbs
    with TableInfo<$JourneyBreadcrumbsTable, JourneyBreadcrumb> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JourneyBreadcrumbsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _journeyIdMeta = const VerificationMeta(
    'journeyId',
  );
  @override
  late final GeneratedColumn<String> journeyId = GeneratedColumn<String>(
    'journey_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES journeys (id)',
    ),
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _h3IndexMeta = const VerificationMeta(
    'h3Index',
  );
  @override
  late final GeneratedColumn<String> h3Index = GeneratedColumn<String>(
    'h3_index',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalDistanceMeta = const VerificationMeta(
    'totalDistance',
  );
  @override
  late final GeneratedColumn<double> totalDistance = GeneratedColumn<double>(
    'total_distance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _speedMeta = const VerificationMeta('speed');
  @override
  late final GeneratedColumn<double> speed = GeneratedColumn<double>(
    'speed',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _headingMeta = const VerificationMeta(
    'heading',
  );
  @override
  late final GeneratedColumn<double> heading = GeneratedColumn<double>(
    'heading',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accuracyMeta = const VerificationMeta(
    'accuracy',
  );
  @override
  late final GeneratedColumn<double> accuracy = GeneratedColumn<double>(
    'accuracy',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    journeyId,
    latitude,
    longitude,
    h3Index,
    totalDistance,
    speed,
    heading,
    accuracy,
    recordedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journey_breadcrumbs';
  @override
  VerificationContext validateIntegrity(
    Insertable<JourneyBreadcrumb> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('journey_id')) {
      context.handle(
        _journeyIdMeta,
        journeyId.isAcceptableOrUnknown(data['journey_id']!, _journeyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_journeyIdMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('h3_index')) {
      context.handle(
        _h3IndexMeta,
        h3Index.isAcceptableOrUnknown(data['h3_index']!, _h3IndexMeta),
      );
    } else if (isInserting) {
      context.missing(_h3IndexMeta);
    }
    if (data.containsKey('total_distance')) {
      context.handle(
        _totalDistanceMeta,
        totalDistance.isAcceptableOrUnknown(
          data['total_distance']!,
          _totalDistanceMeta,
        ),
      );
    }
    if (data.containsKey('speed')) {
      context.handle(
        _speedMeta,
        speed.isAcceptableOrUnknown(data['speed']!, _speedMeta),
      );
    }
    if (data.containsKey('heading')) {
      context.handle(
        _headingMeta,
        heading.isAcceptableOrUnknown(data['heading']!, _headingMeta),
      );
    }
    if (data.containsKey('accuracy')) {
      context.handle(
        _accuracyMeta,
        accuracy.isAcceptableOrUnknown(data['accuracy']!, _accuracyMeta),
      );
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JourneyBreadcrumb map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JourneyBreadcrumb(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      journeyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}journey_id'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      h3Index: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}h3_index'],
      )!,
      totalDistance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_distance'],
      )!,
      speed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed'],
      ),
      heading: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}heading'],
      ),
      accuracy: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy'],
      ),
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
    );
  }

  @override
  $JourneyBreadcrumbsTable createAlias(String alias) {
    return $JourneyBreadcrumbsTable(attachedDatabase, alias);
  }
}

class JourneyBreadcrumb extends DataClass
    implements Insertable<JourneyBreadcrumb> {
  final String id;
  final String journeyId;
  final double latitude;
  final double longitude;
  final String h3Index;
  final double totalDistance;
  final double? speed;
  final double? heading;
  final double? accuracy;
  final DateTime recordedAt;
  const JourneyBreadcrumb({
    required this.id,
    required this.journeyId,
    required this.latitude,
    required this.longitude,
    required this.h3Index,
    required this.totalDistance,
    this.speed,
    this.heading,
    this.accuracy,
    required this.recordedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['journey_id'] = Variable<String>(journeyId);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['h3_index'] = Variable<String>(h3Index);
    map['total_distance'] = Variable<double>(totalDistance);
    if (!nullToAbsent || speed != null) {
      map['speed'] = Variable<double>(speed);
    }
    if (!nullToAbsent || heading != null) {
      map['heading'] = Variable<double>(heading);
    }
    if (!nullToAbsent || accuracy != null) {
      map['accuracy'] = Variable<double>(accuracy);
    }
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    return map;
  }

  JourneyBreadcrumbsCompanion toCompanion(bool nullToAbsent) {
    return JourneyBreadcrumbsCompanion(
      id: Value(id),
      journeyId: Value(journeyId),
      latitude: Value(latitude),
      longitude: Value(longitude),
      h3Index: Value(h3Index),
      totalDistance: Value(totalDistance),
      speed: speed == null && nullToAbsent
          ? const Value.absent()
          : Value(speed),
      heading: heading == null && nullToAbsent
          ? const Value.absent()
          : Value(heading),
      accuracy: accuracy == null && nullToAbsent
          ? const Value.absent()
          : Value(accuracy),
      recordedAt: Value(recordedAt),
    );
  }

  factory JourneyBreadcrumb.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JourneyBreadcrumb(
      id: serializer.fromJson<String>(json['id']),
      journeyId: serializer.fromJson<String>(json['journeyId']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      h3Index: serializer.fromJson<String>(json['h3Index']),
      totalDistance: serializer.fromJson<double>(json['totalDistance']),
      speed: serializer.fromJson<double?>(json['speed']),
      heading: serializer.fromJson<double?>(json['heading']),
      accuracy: serializer.fromJson<double?>(json['accuracy']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'journeyId': serializer.toJson<String>(journeyId),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'h3Index': serializer.toJson<String>(h3Index),
      'totalDistance': serializer.toJson<double>(totalDistance),
      'speed': serializer.toJson<double?>(speed),
      'heading': serializer.toJson<double?>(heading),
      'accuracy': serializer.toJson<double?>(accuracy),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
    };
  }

  JourneyBreadcrumb copyWith({
    String? id,
    String? journeyId,
    double? latitude,
    double? longitude,
    String? h3Index,
    double? totalDistance,
    Value<double?> speed = const Value.absent(),
    Value<double?> heading = const Value.absent(),
    Value<double?> accuracy = const Value.absent(),
    DateTime? recordedAt,
  }) => JourneyBreadcrumb(
    id: id ?? this.id,
    journeyId: journeyId ?? this.journeyId,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    h3Index: h3Index ?? this.h3Index,
    totalDistance: totalDistance ?? this.totalDistance,
    speed: speed.present ? speed.value : this.speed,
    heading: heading.present ? heading.value : this.heading,
    accuracy: accuracy.present ? accuracy.value : this.accuracy,
    recordedAt: recordedAt ?? this.recordedAt,
  );
  JourneyBreadcrumb copyWithCompanion(JourneyBreadcrumbsCompanion data) {
    return JourneyBreadcrumb(
      id: data.id.present ? data.id.value : this.id,
      journeyId: data.journeyId.present ? data.journeyId.value : this.journeyId,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      h3Index: data.h3Index.present ? data.h3Index.value : this.h3Index,
      totalDistance: data.totalDistance.present
          ? data.totalDistance.value
          : this.totalDistance,
      speed: data.speed.present ? data.speed.value : this.speed,
      heading: data.heading.present ? data.heading.value : this.heading,
      accuracy: data.accuracy.present ? data.accuracy.value : this.accuracy,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JourneyBreadcrumb(')
          ..write('id: $id, ')
          ..write('journeyId: $journeyId, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('h3Index: $h3Index, ')
          ..write('totalDistance: $totalDistance, ')
          ..write('speed: $speed, ')
          ..write('heading: $heading, ')
          ..write('accuracy: $accuracy, ')
          ..write('recordedAt: $recordedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    journeyId,
    latitude,
    longitude,
    h3Index,
    totalDistance,
    speed,
    heading,
    accuracy,
    recordedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JourneyBreadcrumb &&
          other.id == this.id &&
          other.journeyId == this.journeyId &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.h3Index == this.h3Index &&
          other.totalDistance == this.totalDistance &&
          other.speed == this.speed &&
          other.heading == this.heading &&
          other.accuracy == this.accuracy &&
          other.recordedAt == this.recordedAt);
}

class JourneyBreadcrumbsCompanion extends UpdateCompanion<JourneyBreadcrumb> {
  final Value<String> id;
  final Value<String> journeyId;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<String> h3Index;
  final Value<double> totalDistance;
  final Value<double?> speed;
  final Value<double?> heading;
  final Value<double?> accuracy;
  final Value<DateTime> recordedAt;
  final Value<int> rowid;
  const JourneyBreadcrumbsCompanion({
    this.id = const Value.absent(),
    this.journeyId = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.h3Index = const Value.absent(),
    this.totalDistance = const Value.absent(),
    this.speed = const Value.absent(),
    this.heading = const Value.absent(),
    this.accuracy = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JourneyBreadcrumbsCompanion.insert({
    required String id,
    required String journeyId,
    required double latitude,
    required double longitude,
    required String h3Index,
    this.totalDistance = const Value.absent(),
    this.speed = const Value.absent(),
    this.heading = const Value.absent(),
    this.accuracy = const Value.absent(),
    required DateTime recordedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       journeyId = Value(journeyId),
       latitude = Value(latitude),
       longitude = Value(longitude),
       h3Index = Value(h3Index),
       recordedAt = Value(recordedAt);
  static Insertable<JourneyBreadcrumb> custom({
    Expression<String>? id,
    Expression<String>? journeyId,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? h3Index,
    Expression<double>? totalDistance,
    Expression<double>? speed,
    Expression<double>? heading,
    Expression<double>? accuracy,
    Expression<DateTime>? recordedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (journeyId != null) 'journey_id': journeyId,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (h3Index != null) 'h3_index': h3Index,
      if (totalDistance != null) 'total_distance': totalDistance,
      if (speed != null) 'speed': speed,
      if (heading != null) 'heading': heading,
      if (accuracy != null) 'accuracy': accuracy,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JourneyBreadcrumbsCompanion copyWith({
    Value<String>? id,
    Value<String>? journeyId,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<String>? h3Index,
    Value<double>? totalDistance,
    Value<double?>? speed,
    Value<double?>? heading,
    Value<double?>? accuracy,
    Value<DateTime>? recordedAt,
    Value<int>? rowid,
  }) {
    return JourneyBreadcrumbsCompanion(
      id: id ?? this.id,
      journeyId: journeyId ?? this.journeyId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      h3Index: h3Index ?? this.h3Index,
      totalDistance: totalDistance ?? this.totalDistance,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      accuracy: accuracy ?? this.accuracy,
      recordedAt: recordedAt ?? this.recordedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (journeyId.present) {
      map['journey_id'] = Variable<String>(journeyId.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (h3Index.present) {
      map['h3_index'] = Variable<String>(h3Index.value);
    }
    if (totalDistance.present) {
      map['total_distance'] = Variable<double>(totalDistance.value);
    }
    if (speed.present) {
      map['speed'] = Variable<double>(speed.value);
    }
    if (heading.present) {
      map['heading'] = Variable<double>(heading.value);
    }
    if (accuracy.present) {
      map['accuracy'] = Variable<double>(accuracy.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JourneyBreadcrumbsCompanion(')
          ..write('id: $id, ')
          ..write('journeyId: $journeyId, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('h3Index: $h3Index, ')
          ..write('totalDistance: $totalDistance, ')
          ..write('speed: $speed, ')
          ..write('heading: $heading, ')
          ..write('accuracy: $accuracy, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JourneyOpsQueueTable extends JourneyOpsQueue
    with TableInfo<$JourneyOpsQueueTable, JourneyOpsQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JourneyOpsQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _opIdMeta = const VerificationMeta('opId');
  @override
  late final GeneratedColumn<String> opId = GeneratedColumn<String>(
    'op_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _journeyIdMeta = const VerificationMeta(
    'journeyId',
  );
  @override
  late final GeneratedColumn<String> journeyId = GeneratedColumn<String>(
    'journey_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    opId,
    journeyId,
    userId,
    type,
    payload,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journey_ops_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<JourneyOpsQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('op_id')) {
      context.handle(
        _opIdMeta,
        opId.isAcceptableOrUnknown(data['op_id']!, _opIdMeta),
      );
    } else if (isInserting) {
      context.missing(_opIdMeta);
    }
    if (data.containsKey('journey_id')) {
      context.handle(
        _journeyIdMeta,
        journeyId.isAcceptableOrUnknown(data['journey_id']!, _journeyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_journeyIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {opId};
  @override
  JourneyOpsQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JourneyOpsQueueData(
      opId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op_id'],
      )!,
      journeyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}journey_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $JourneyOpsQueueTable createAlias(String alias) {
    return $JourneyOpsQueueTable(attachedDatabase, alias);
  }
}

class JourneyOpsQueueData extends DataClass
    implements Insertable<JourneyOpsQueueData> {
  final String opId;
  final String journeyId;
  final int userId;
  final String type;
  final String payload;
  final DateTime createdAt;
  const JourneyOpsQueueData({
    required this.opId,
    required this.journeyId,
    required this.userId,
    required this.type,
    required this.payload,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['op_id'] = Variable<String>(opId);
    map['journey_id'] = Variable<String>(journeyId);
    map['user_id'] = Variable<int>(userId);
    map['type'] = Variable<String>(type);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  JourneyOpsQueueCompanion toCompanion(bool nullToAbsent) {
    return JourneyOpsQueueCompanion(
      opId: Value(opId),
      journeyId: Value(journeyId),
      userId: Value(userId),
      type: Value(type),
      payload: Value(payload),
      createdAt: Value(createdAt),
    );
  }

  factory JourneyOpsQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JourneyOpsQueueData(
      opId: serializer.fromJson<String>(json['opId']),
      journeyId: serializer.fromJson<String>(json['journeyId']),
      userId: serializer.fromJson<int>(json['userId']),
      type: serializer.fromJson<String>(json['type']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'opId': serializer.toJson<String>(opId),
      'journeyId': serializer.toJson<String>(journeyId),
      'userId': serializer.toJson<int>(userId),
      'type': serializer.toJson<String>(type),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  JourneyOpsQueueData copyWith({
    String? opId,
    String? journeyId,
    int? userId,
    String? type,
    String? payload,
    DateTime? createdAt,
  }) => JourneyOpsQueueData(
    opId: opId ?? this.opId,
    journeyId: journeyId ?? this.journeyId,
    userId: userId ?? this.userId,
    type: type ?? this.type,
    payload: payload ?? this.payload,
    createdAt: createdAt ?? this.createdAt,
  );
  JourneyOpsQueueData copyWithCompanion(JourneyOpsQueueCompanion data) {
    return JourneyOpsQueueData(
      opId: data.opId.present ? data.opId.value : this.opId,
      journeyId: data.journeyId.present ? data.journeyId.value : this.journeyId,
      userId: data.userId.present ? data.userId.value : this.userId,
      type: data.type.present ? data.type.value : this.type,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JourneyOpsQueueData(')
          ..write('opId: $opId, ')
          ..write('journeyId: $journeyId, ')
          ..write('userId: $userId, ')
          ..write('type: $type, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(opId, journeyId, userId, type, payload, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JourneyOpsQueueData &&
          other.opId == this.opId &&
          other.journeyId == this.journeyId &&
          other.userId == this.userId &&
          other.type == this.type &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt);
}

class JourneyOpsQueueCompanion extends UpdateCompanion<JourneyOpsQueueData> {
  final Value<String> opId;
  final Value<String> journeyId;
  final Value<int> userId;
  final Value<String> type;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const JourneyOpsQueueCompanion({
    this.opId = const Value.absent(),
    this.journeyId = const Value.absent(),
    this.userId = const Value.absent(),
    this.type = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JourneyOpsQueueCompanion.insert({
    required String opId,
    required String journeyId,
    required int userId,
    required String type,
    required String payload,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : opId = Value(opId),
       journeyId = Value(journeyId),
       userId = Value(userId),
       type = Value(type),
       payload = Value(payload),
       createdAt = Value(createdAt);
  static Insertable<JourneyOpsQueueData> custom({
    Expression<String>? opId,
    Expression<String>? journeyId,
    Expression<int>? userId,
    Expression<String>? type,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (opId != null) 'op_id': opId,
      if (journeyId != null) 'journey_id': journeyId,
      if (userId != null) 'user_id': userId,
      if (type != null) 'type': type,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JourneyOpsQueueCompanion copyWith({
    Value<String>? opId,
    Value<String>? journeyId,
    Value<int>? userId,
    Value<String>? type,
    Value<String>? payload,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return JourneyOpsQueueCompanion(
      opId: opId ?? this.opId,
      journeyId: journeyId ?? this.journeyId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (opId.present) {
      map['op_id'] = Variable<String>(opId.value);
    }
    if (journeyId.present) {
      map['journey_id'] = Variable<String>(journeyId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
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
    return (StringBuffer('JourneyOpsQueueCompanion(')
          ..write('opId: $opId, ')
          ..write('journeyId: $journeyId, ')
          ..write('userId: $userId, ')
          ..write('type: $type, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalDailyVisitReportsTable extends LocalDailyVisitReports
    with TableInfo<$LocalDailyVisitReportsTable, LocalDailyVisitReport> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalDailyVisitReportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dealerIdMeta = const VerificationMeta(
    'dealerId',
  );
  @override
  late final GeneratedColumn<String> dealerId = GeneratedColumn<String>(
    'dealer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subDealerIdMeta = const VerificationMeta(
    'subDealerId',
  );
  @override
  late final GeneratedColumn<String> subDealerId = GeneratedColumn<String>(
    'sub_dealer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reportDateMeta = const VerificationMeta(
    'reportDate',
  );
  @override
  late final GeneratedColumn<DateTime> reportDate = GeneratedColumn<DateTime>(
    'report_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dealerTypeMeta = const VerificationMeta(
    'dealerType',
  );
  @override
  late final GeneratedColumn<String> dealerType = GeneratedColumn<String>(
    'dealer_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _visitTypeMeta = const VerificationMeta(
    'visitType',
  );
  @override
  late final GeneratedColumn<String> visitType = GeneratedColumn<String>(
    'visit_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dealerTotalPotentialMeta =
      const VerificationMeta('dealerTotalPotential');
  @override
  late final GeneratedColumn<double> dealerTotalPotential =
      GeneratedColumn<double>(
        'dealer_total_potential',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _dealerBestPotentialMeta =
      const VerificationMeta('dealerBestPotential');
  @override
  late final GeneratedColumn<double> dealerBestPotential =
      GeneratedColumn<double>(
        'dealer_best_potential',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _brandSellingMeta = const VerificationMeta(
    'brandSelling',
  );
  @override
  late final GeneratedColumn<String> brandSelling = GeneratedColumn<String>(
    'brand_selling',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contactPersonMeta = const VerificationMeta(
    'contactPerson',
  );
  @override
  late final GeneratedColumn<String> contactPerson = GeneratedColumn<String>(
    'contact_person',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contactPersonPhoneNoMeta =
      const VerificationMeta('contactPersonPhoneNo');
  @override
  late final GeneratedColumn<String> contactPersonPhoneNo =
      GeneratedColumn<String>(
        'contact_person_phone_no',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _todayOrderMtMeta = const VerificationMeta(
    'todayOrderMt',
  );
  @override
  late final GeneratedColumn<double> todayOrderMt = GeneratedColumn<double>(
    'today_order_mt',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _todayCollectionRupeesMeta =
      const VerificationMeta('todayCollectionRupees');
  @override
  late final GeneratedColumn<double> todayCollectionRupees =
      GeneratedColumn<double>(
        'today_collection_rupees',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _overdueAmountMeta = const VerificationMeta(
    'overdueAmount',
  );
  @override
  late final GeneratedColumn<double> overdueAmount = GeneratedColumn<double>(
    'overdue_amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _feedbacksMeta = const VerificationMeta(
    'feedbacks',
  );
  @override
  late final GeneratedColumn<String> feedbacks = GeneratedColumn<String>(
    'feedbacks',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _solutionBySalespersonMeta =
      const VerificationMeta('solutionBySalesperson');
  @override
  late final GeneratedColumn<String> solutionBySalesperson =
      GeneratedColumn<String>(
        'solution_by_salesperson',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _anyRemarksMeta = const VerificationMeta(
    'anyRemarks',
  );
  @override
  late final GeneratedColumn<String> anyRemarks = GeneratedColumn<String>(
    'any_remarks',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _checkInTimeMeta = const VerificationMeta(
    'checkInTime',
  );
  @override
  late final GeneratedColumn<DateTime> checkInTime = GeneratedColumn<DateTime>(
    'check_in_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _checkOutTimeMeta = const VerificationMeta(
    'checkOutTime',
  );
  @override
  late final GeneratedColumn<DateTime> checkOutTime = GeneratedColumn<DateTime>(
    'check_out_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeSpentinLocMeta = const VerificationMeta(
    'timeSpentinLoc',
  );
  @override
  late final GeneratedColumn<String> timeSpentinLoc = GeneratedColumn<String>(
    'time_spentin_loc',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inTimeImageUrlMeta = const VerificationMeta(
    'inTimeImageUrl',
  );
  @override
  late final GeneratedColumn<String> inTimeImageUrl = GeneratedColumn<String>(
    'in_time_image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _outTimeImageUrlMeta = const VerificationMeta(
    'outTimeImageUrl',
  );
  @override
  late final GeneratedColumn<String> outTimeImageUrl = GeneratedColumn<String>(
    'out_time_image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pjpIdMeta = const VerificationMeta('pjpId');
  @override
  late final GeneratedColumn<String> pjpId = GeneratedColumn<String>(
    'pjp_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dailyTaskIdMeta = const VerificationMeta(
    'dailyTaskId',
  );
  @override
  late final GeneratedColumn<String> dailyTaskId = GeneratedColumn<String>(
    'daily_task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerTypeMeta = const VerificationMeta(
    'customerType',
  );
  @override
  late final GeneratedColumn<String> customerType = GeneratedColumn<String>(
    'customer_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _partyTypeMeta = const VerificationMeta(
    'partyType',
  );
  @override
  late final GeneratedColumn<String> partyType = GeneratedColumn<String>(
    'party_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameOfPartyMeta = const VerificationMeta(
    'nameOfParty',
  );
  @override
  late final GeneratedColumn<String> nameOfParty = GeneratedColumn<String>(
    'name_of_party',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contactNoOfPartyMeta = const VerificationMeta(
    'contactNoOfParty',
  );
  @override
  late final GeneratedColumn<String> contactNoOfParty = GeneratedColumn<String>(
    'contact_no_of_party',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expectedActivationDateMeta =
      const VerificationMeta('expectedActivationDate');
  @override
  late final GeneratedColumn<DateTime> expectedActivationDate =
      GeneratedColumn<DateTime>(
        'expected_activation_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _currentDealerOutstandingAmtMeta =
      const VerificationMeta('currentDealerOutstandingAmt');
  @override
  late final GeneratedColumn<double> currentDealerOutstandingAmt =
      GeneratedColumn<double>(
        'current_dealer_outstanding_amt',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('PENDING'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    dealerId,
    subDealerId,
    reportDate,
    dealerType,
    location,
    latitude,
    longitude,
    visitType,
    dealerTotalPotential,
    dealerBestPotential,
    brandSelling,
    contactPerson,
    contactPersonPhoneNo,
    todayOrderMt,
    todayCollectionRupees,
    overdueAmount,
    feedbacks,
    solutionBySalesperson,
    anyRemarks,
    checkInTime,
    checkOutTime,
    timeSpentinLoc,
    inTimeImageUrl,
    outTimeImageUrl,
    pjpId,
    dailyTaskId,
    customerType,
    partyType,
    nameOfParty,
    contactNoOfParty,
    expectedActivationDate,
    currentDealerOutstandingAmt,
    idempotencyKey,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_daily_visit_reports';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalDailyVisitReport> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('dealer_id')) {
      context.handle(
        _dealerIdMeta,
        dealerId.isAcceptableOrUnknown(data['dealer_id']!, _dealerIdMeta),
      );
    }
    if (data.containsKey('sub_dealer_id')) {
      context.handle(
        _subDealerIdMeta,
        subDealerId.isAcceptableOrUnknown(
          data['sub_dealer_id']!,
          _subDealerIdMeta,
        ),
      );
    }
    if (data.containsKey('report_date')) {
      context.handle(
        _reportDateMeta,
        reportDate.isAcceptableOrUnknown(data['report_date']!, _reportDateMeta),
      );
    }
    if (data.containsKey('dealer_type')) {
      context.handle(
        _dealerTypeMeta,
        dealerType.isAcceptableOrUnknown(data['dealer_type']!, _dealerTypeMeta),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('visit_type')) {
      context.handle(
        _visitTypeMeta,
        visitType.isAcceptableOrUnknown(data['visit_type']!, _visitTypeMeta),
      );
    }
    if (data.containsKey('dealer_total_potential')) {
      context.handle(
        _dealerTotalPotentialMeta,
        dealerTotalPotential.isAcceptableOrUnknown(
          data['dealer_total_potential']!,
          _dealerTotalPotentialMeta,
        ),
      );
    }
    if (data.containsKey('dealer_best_potential')) {
      context.handle(
        _dealerBestPotentialMeta,
        dealerBestPotential.isAcceptableOrUnknown(
          data['dealer_best_potential']!,
          _dealerBestPotentialMeta,
        ),
      );
    }
    if (data.containsKey('brand_selling')) {
      context.handle(
        _brandSellingMeta,
        brandSelling.isAcceptableOrUnknown(
          data['brand_selling']!,
          _brandSellingMeta,
        ),
      );
    }
    if (data.containsKey('contact_person')) {
      context.handle(
        _contactPersonMeta,
        contactPerson.isAcceptableOrUnknown(
          data['contact_person']!,
          _contactPersonMeta,
        ),
      );
    }
    if (data.containsKey('contact_person_phone_no')) {
      context.handle(
        _contactPersonPhoneNoMeta,
        contactPersonPhoneNo.isAcceptableOrUnknown(
          data['contact_person_phone_no']!,
          _contactPersonPhoneNoMeta,
        ),
      );
    }
    if (data.containsKey('today_order_mt')) {
      context.handle(
        _todayOrderMtMeta,
        todayOrderMt.isAcceptableOrUnknown(
          data['today_order_mt']!,
          _todayOrderMtMeta,
        ),
      );
    }
    if (data.containsKey('today_collection_rupees')) {
      context.handle(
        _todayCollectionRupeesMeta,
        todayCollectionRupees.isAcceptableOrUnknown(
          data['today_collection_rupees']!,
          _todayCollectionRupeesMeta,
        ),
      );
    }
    if (data.containsKey('overdue_amount')) {
      context.handle(
        _overdueAmountMeta,
        overdueAmount.isAcceptableOrUnknown(
          data['overdue_amount']!,
          _overdueAmountMeta,
        ),
      );
    }
    if (data.containsKey('feedbacks')) {
      context.handle(
        _feedbacksMeta,
        feedbacks.isAcceptableOrUnknown(data['feedbacks']!, _feedbacksMeta),
      );
    }
    if (data.containsKey('solution_by_salesperson')) {
      context.handle(
        _solutionBySalespersonMeta,
        solutionBySalesperson.isAcceptableOrUnknown(
          data['solution_by_salesperson']!,
          _solutionBySalespersonMeta,
        ),
      );
    }
    if (data.containsKey('any_remarks')) {
      context.handle(
        _anyRemarksMeta,
        anyRemarks.isAcceptableOrUnknown(data['any_remarks']!, _anyRemarksMeta),
      );
    }
    if (data.containsKey('check_in_time')) {
      context.handle(
        _checkInTimeMeta,
        checkInTime.isAcceptableOrUnknown(
          data['check_in_time']!,
          _checkInTimeMeta,
        ),
      );
    }
    if (data.containsKey('check_out_time')) {
      context.handle(
        _checkOutTimeMeta,
        checkOutTime.isAcceptableOrUnknown(
          data['check_out_time']!,
          _checkOutTimeMeta,
        ),
      );
    }
    if (data.containsKey('time_spentin_loc')) {
      context.handle(
        _timeSpentinLocMeta,
        timeSpentinLoc.isAcceptableOrUnknown(
          data['time_spentin_loc']!,
          _timeSpentinLocMeta,
        ),
      );
    }
    if (data.containsKey('in_time_image_url')) {
      context.handle(
        _inTimeImageUrlMeta,
        inTimeImageUrl.isAcceptableOrUnknown(
          data['in_time_image_url']!,
          _inTimeImageUrlMeta,
        ),
      );
    }
    if (data.containsKey('out_time_image_url')) {
      context.handle(
        _outTimeImageUrlMeta,
        outTimeImageUrl.isAcceptableOrUnknown(
          data['out_time_image_url']!,
          _outTimeImageUrlMeta,
        ),
      );
    }
    if (data.containsKey('pjp_id')) {
      context.handle(
        _pjpIdMeta,
        pjpId.isAcceptableOrUnknown(data['pjp_id']!, _pjpIdMeta),
      );
    }
    if (data.containsKey('daily_task_id')) {
      context.handle(
        _dailyTaskIdMeta,
        dailyTaskId.isAcceptableOrUnknown(
          data['daily_task_id']!,
          _dailyTaskIdMeta,
        ),
      );
    }
    if (data.containsKey('customer_type')) {
      context.handle(
        _customerTypeMeta,
        customerType.isAcceptableOrUnknown(
          data['customer_type']!,
          _customerTypeMeta,
        ),
      );
    }
    if (data.containsKey('party_type')) {
      context.handle(
        _partyTypeMeta,
        partyType.isAcceptableOrUnknown(data['party_type']!, _partyTypeMeta),
      );
    }
    if (data.containsKey('name_of_party')) {
      context.handle(
        _nameOfPartyMeta,
        nameOfParty.isAcceptableOrUnknown(
          data['name_of_party']!,
          _nameOfPartyMeta,
        ),
      );
    }
    if (data.containsKey('contact_no_of_party')) {
      context.handle(
        _contactNoOfPartyMeta,
        contactNoOfParty.isAcceptableOrUnknown(
          data['contact_no_of_party']!,
          _contactNoOfPartyMeta,
        ),
      );
    }
    if (data.containsKey('expected_activation_date')) {
      context.handle(
        _expectedActivationDateMeta,
        expectedActivationDate.isAcceptableOrUnknown(
          data['expected_activation_date']!,
          _expectedActivationDateMeta,
        ),
      );
    }
    if (data.containsKey('current_dealer_outstanding_amt')) {
      context.handle(
        _currentDealerOutstandingAmtMeta,
        currentDealerOutstandingAmt.isAcceptableOrUnknown(
          data['current_dealer_outstanding_amt']!,
          _currentDealerOutstandingAmtMeta,
        ),
      );
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalDailyVisitReport map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalDailyVisitReport(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      dealerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dealer_id'],
      ),
      subDealerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sub_dealer_id'],
      ),
      reportDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}report_date'],
      ),
      dealerType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dealer_type'],
      ),
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      visitType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visit_type'],
      ),
      dealerTotalPotential: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}dealer_total_potential'],
      ),
      dealerBestPotential: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}dealer_best_potential'],
      ),
      brandSelling: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand_selling'],
      ),
      contactPerson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_person'],
      ),
      contactPersonPhoneNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_person_phone_no'],
      ),
      todayOrderMt: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}today_order_mt'],
      ),
      todayCollectionRupees: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}today_collection_rupees'],
      ),
      overdueAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}overdue_amount'],
      ),
      feedbacks: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}feedbacks'],
      ),
      solutionBySalesperson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}solution_by_salesperson'],
      ),
      anyRemarks: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}any_remarks'],
      ),
      checkInTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}check_in_time'],
      ),
      checkOutTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}check_out_time'],
      ),
      timeSpentinLoc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_spentin_loc'],
      ),
      inTimeImageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}in_time_image_url'],
      ),
      outTimeImageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}out_time_image_url'],
      ),
      pjpId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pjp_id'],
      ),
      dailyTaskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}daily_task_id'],
      ),
      customerType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_type'],
      ),
      partyType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}party_type'],
      ),
      nameOfParty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_of_party'],
      ),
      contactNoOfParty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_no_of_party'],
      ),
      expectedActivationDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expected_activation_date'],
      ),
      currentDealerOutstandingAmt: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_dealer_outstanding_amt'],
      ),
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $LocalDailyVisitReportsTable createAlias(String alias) {
    return $LocalDailyVisitReportsTable(attachedDatabase, alias);
  }
}

class LocalDailyVisitReport extends DataClass
    implements Insertable<LocalDailyVisitReport> {
  final String id;
  final int userId;
  final String? dealerId;
  final String? subDealerId;
  final DateTime? reportDate;
  final String? dealerType;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? visitType;
  final double? dealerTotalPotential;
  final double? dealerBestPotential;
  final String? brandSelling;
  final String? contactPerson;
  final String? contactPersonPhoneNo;
  final double? todayOrderMt;
  final double? todayCollectionRupees;
  final double? overdueAmount;
  final String? feedbacks;
  final String? solutionBySalesperson;
  final String? anyRemarks;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? timeSpentinLoc;
  final String? inTimeImageUrl;
  final String? outTimeImageUrl;
  final String? pjpId;
  final String? dailyTaskId;
  final String? customerType;
  final String? partyType;
  final String? nameOfParty;
  final String? contactNoOfParty;
  final DateTime? expectedActivationDate;
  final double? currentDealerOutstandingAmt;
  final String? idempotencyKey;
  final String syncStatus;
  const LocalDailyVisitReport({
    required this.id,
    required this.userId,
    this.dealerId,
    this.subDealerId,
    this.reportDate,
    this.dealerType,
    this.location,
    this.latitude,
    this.longitude,
    this.visitType,
    this.dealerTotalPotential,
    this.dealerBestPotential,
    this.brandSelling,
    this.contactPerson,
    this.contactPersonPhoneNo,
    this.todayOrderMt,
    this.todayCollectionRupees,
    this.overdueAmount,
    this.feedbacks,
    this.solutionBySalesperson,
    this.anyRemarks,
    this.checkInTime,
    this.checkOutTime,
    this.timeSpentinLoc,
    this.inTimeImageUrl,
    this.outTimeImageUrl,
    this.pjpId,
    this.dailyTaskId,
    this.customerType,
    this.partyType,
    this.nameOfParty,
    this.contactNoOfParty,
    this.expectedActivationDate,
    this.currentDealerOutstandingAmt,
    this.idempotencyKey,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<int>(userId);
    if (!nullToAbsent || dealerId != null) {
      map['dealer_id'] = Variable<String>(dealerId);
    }
    if (!nullToAbsent || subDealerId != null) {
      map['sub_dealer_id'] = Variable<String>(subDealerId);
    }
    if (!nullToAbsent || reportDate != null) {
      map['report_date'] = Variable<DateTime>(reportDate);
    }
    if (!nullToAbsent || dealerType != null) {
      map['dealer_type'] = Variable<String>(dealerType);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    if (!nullToAbsent || visitType != null) {
      map['visit_type'] = Variable<String>(visitType);
    }
    if (!nullToAbsent || dealerTotalPotential != null) {
      map['dealer_total_potential'] = Variable<double>(dealerTotalPotential);
    }
    if (!nullToAbsent || dealerBestPotential != null) {
      map['dealer_best_potential'] = Variable<double>(dealerBestPotential);
    }
    if (!nullToAbsent || brandSelling != null) {
      map['brand_selling'] = Variable<String>(brandSelling);
    }
    if (!nullToAbsent || contactPerson != null) {
      map['contact_person'] = Variable<String>(contactPerson);
    }
    if (!nullToAbsent || contactPersonPhoneNo != null) {
      map['contact_person_phone_no'] = Variable<String>(contactPersonPhoneNo);
    }
    if (!nullToAbsent || todayOrderMt != null) {
      map['today_order_mt'] = Variable<double>(todayOrderMt);
    }
    if (!nullToAbsent || todayCollectionRupees != null) {
      map['today_collection_rupees'] = Variable<double>(todayCollectionRupees);
    }
    if (!nullToAbsent || overdueAmount != null) {
      map['overdue_amount'] = Variable<double>(overdueAmount);
    }
    if (!nullToAbsent || feedbacks != null) {
      map['feedbacks'] = Variable<String>(feedbacks);
    }
    if (!nullToAbsent || solutionBySalesperson != null) {
      map['solution_by_salesperson'] = Variable<String>(solutionBySalesperson);
    }
    if (!nullToAbsent || anyRemarks != null) {
      map['any_remarks'] = Variable<String>(anyRemarks);
    }
    if (!nullToAbsent || checkInTime != null) {
      map['check_in_time'] = Variable<DateTime>(checkInTime);
    }
    if (!nullToAbsent || checkOutTime != null) {
      map['check_out_time'] = Variable<DateTime>(checkOutTime);
    }
    if (!nullToAbsent || timeSpentinLoc != null) {
      map['time_spentin_loc'] = Variable<String>(timeSpentinLoc);
    }
    if (!nullToAbsent || inTimeImageUrl != null) {
      map['in_time_image_url'] = Variable<String>(inTimeImageUrl);
    }
    if (!nullToAbsent || outTimeImageUrl != null) {
      map['out_time_image_url'] = Variable<String>(outTimeImageUrl);
    }
    if (!nullToAbsent || pjpId != null) {
      map['pjp_id'] = Variable<String>(pjpId);
    }
    if (!nullToAbsent || dailyTaskId != null) {
      map['daily_task_id'] = Variable<String>(dailyTaskId);
    }
    if (!nullToAbsent || customerType != null) {
      map['customer_type'] = Variable<String>(customerType);
    }
    if (!nullToAbsent || partyType != null) {
      map['party_type'] = Variable<String>(partyType);
    }
    if (!nullToAbsent || nameOfParty != null) {
      map['name_of_party'] = Variable<String>(nameOfParty);
    }
    if (!nullToAbsent || contactNoOfParty != null) {
      map['contact_no_of_party'] = Variable<String>(contactNoOfParty);
    }
    if (!nullToAbsent || expectedActivationDate != null) {
      map['expected_activation_date'] = Variable<DateTime>(
        expectedActivationDate,
      );
    }
    if (!nullToAbsent || currentDealerOutstandingAmt != null) {
      map['current_dealer_outstanding_amt'] = Variable<double>(
        currentDealerOutstandingAmt,
      );
    }
    if (!nullToAbsent || idempotencyKey != null) {
      map['idempotency_key'] = Variable<String>(idempotencyKey);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  LocalDailyVisitReportsCompanion toCompanion(bool nullToAbsent) {
    return LocalDailyVisitReportsCompanion(
      id: Value(id),
      userId: Value(userId),
      dealerId: dealerId == null && nullToAbsent
          ? const Value.absent()
          : Value(dealerId),
      subDealerId: subDealerId == null && nullToAbsent
          ? const Value.absent()
          : Value(subDealerId),
      reportDate: reportDate == null && nullToAbsent
          ? const Value.absent()
          : Value(reportDate),
      dealerType: dealerType == null && nullToAbsent
          ? const Value.absent()
          : Value(dealerType),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      visitType: visitType == null && nullToAbsent
          ? const Value.absent()
          : Value(visitType),
      dealerTotalPotential: dealerTotalPotential == null && nullToAbsent
          ? const Value.absent()
          : Value(dealerTotalPotential),
      dealerBestPotential: dealerBestPotential == null && nullToAbsent
          ? const Value.absent()
          : Value(dealerBestPotential),
      brandSelling: brandSelling == null && nullToAbsent
          ? const Value.absent()
          : Value(brandSelling),
      contactPerson: contactPerson == null && nullToAbsent
          ? const Value.absent()
          : Value(contactPerson),
      contactPersonPhoneNo: contactPersonPhoneNo == null && nullToAbsent
          ? const Value.absent()
          : Value(contactPersonPhoneNo),
      todayOrderMt: todayOrderMt == null && nullToAbsent
          ? const Value.absent()
          : Value(todayOrderMt),
      todayCollectionRupees: todayCollectionRupees == null && nullToAbsent
          ? const Value.absent()
          : Value(todayCollectionRupees),
      overdueAmount: overdueAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(overdueAmount),
      feedbacks: feedbacks == null && nullToAbsent
          ? const Value.absent()
          : Value(feedbacks),
      solutionBySalesperson: solutionBySalesperson == null && nullToAbsent
          ? const Value.absent()
          : Value(solutionBySalesperson),
      anyRemarks: anyRemarks == null && nullToAbsent
          ? const Value.absent()
          : Value(anyRemarks),
      checkInTime: checkInTime == null && nullToAbsent
          ? const Value.absent()
          : Value(checkInTime),
      checkOutTime: checkOutTime == null && nullToAbsent
          ? const Value.absent()
          : Value(checkOutTime),
      timeSpentinLoc: timeSpentinLoc == null && nullToAbsent
          ? const Value.absent()
          : Value(timeSpentinLoc),
      inTimeImageUrl: inTimeImageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(inTimeImageUrl),
      outTimeImageUrl: outTimeImageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(outTimeImageUrl),
      pjpId: pjpId == null && nullToAbsent
          ? const Value.absent()
          : Value(pjpId),
      dailyTaskId: dailyTaskId == null && nullToAbsent
          ? const Value.absent()
          : Value(dailyTaskId),
      customerType: customerType == null && nullToAbsent
          ? const Value.absent()
          : Value(customerType),
      partyType: partyType == null && nullToAbsent
          ? const Value.absent()
          : Value(partyType),
      nameOfParty: nameOfParty == null && nullToAbsent
          ? const Value.absent()
          : Value(nameOfParty),
      contactNoOfParty: contactNoOfParty == null && nullToAbsent
          ? const Value.absent()
          : Value(contactNoOfParty),
      expectedActivationDate: expectedActivationDate == null && nullToAbsent
          ? const Value.absent()
          : Value(expectedActivationDate),
      currentDealerOutstandingAmt:
          currentDealerOutstandingAmt == null && nullToAbsent
          ? const Value.absent()
          : Value(currentDealerOutstandingAmt),
      idempotencyKey: idempotencyKey == null && nullToAbsent
          ? const Value.absent()
          : Value(idempotencyKey),
      syncStatus: Value(syncStatus),
    );
  }

  factory LocalDailyVisitReport.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalDailyVisitReport(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      dealerId: serializer.fromJson<String?>(json['dealerId']),
      subDealerId: serializer.fromJson<String?>(json['subDealerId']),
      reportDate: serializer.fromJson<DateTime?>(json['reportDate']),
      dealerType: serializer.fromJson<String?>(json['dealerType']),
      location: serializer.fromJson<String?>(json['location']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      visitType: serializer.fromJson<String?>(json['visitType']),
      dealerTotalPotential: serializer.fromJson<double?>(
        json['dealerTotalPotential'],
      ),
      dealerBestPotential: serializer.fromJson<double?>(
        json['dealerBestPotential'],
      ),
      brandSelling: serializer.fromJson<String?>(json['brandSelling']),
      contactPerson: serializer.fromJson<String?>(json['contactPerson']),
      contactPersonPhoneNo: serializer.fromJson<String?>(
        json['contactPersonPhoneNo'],
      ),
      todayOrderMt: serializer.fromJson<double?>(json['todayOrderMt']),
      todayCollectionRupees: serializer.fromJson<double?>(
        json['todayCollectionRupees'],
      ),
      overdueAmount: serializer.fromJson<double?>(json['overdueAmount']),
      feedbacks: serializer.fromJson<String?>(json['feedbacks']),
      solutionBySalesperson: serializer.fromJson<String?>(
        json['solutionBySalesperson'],
      ),
      anyRemarks: serializer.fromJson<String?>(json['anyRemarks']),
      checkInTime: serializer.fromJson<DateTime?>(json['checkInTime']),
      checkOutTime: serializer.fromJson<DateTime?>(json['checkOutTime']),
      timeSpentinLoc: serializer.fromJson<String?>(json['timeSpentinLoc']),
      inTimeImageUrl: serializer.fromJson<String?>(json['inTimeImageUrl']),
      outTimeImageUrl: serializer.fromJson<String?>(json['outTimeImageUrl']),
      pjpId: serializer.fromJson<String?>(json['pjpId']),
      dailyTaskId: serializer.fromJson<String?>(json['dailyTaskId']),
      customerType: serializer.fromJson<String?>(json['customerType']),
      partyType: serializer.fromJson<String?>(json['partyType']),
      nameOfParty: serializer.fromJson<String?>(json['nameOfParty']),
      contactNoOfParty: serializer.fromJson<String?>(json['contactNoOfParty']),
      expectedActivationDate: serializer.fromJson<DateTime?>(
        json['expectedActivationDate'],
      ),
      currentDealerOutstandingAmt: serializer.fromJson<double?>(
        json['currentDealerOutstandingAmt'],
      ),
      idempotencyKey: serializer.fromJson<String?>(json['idempotencyKey']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<int>(userId),
      'dealerId': serializer.toJson<String?>(dealerId),
      'subDealerId': serializer.toJson<String?>(subDealerId),
      'reportDate': serializer.toJson<DateTime?>(reportDate),
      'dealerType': serializer.toJson<String?>(dealerType),
      'location': serializer.toJson<String?>(location),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'visitType': serializer.toJson<String?>(visitType),
      'dealerTotalPotential': serializer.toJson<double?>(dealerTotalPotential),
      'dealerBestPotential': serializer.toJson<double?>(dealerBestPotential),
      'brandSelling': serializer.toJson<String?>(brandSelling),
      'contactPerson': serializer.toJson<String?>(contactPerson),
      'contactPersonPhoneNo': serializer.toJson<String?>(contactPersonPhoneNo),
      'todayOrderMt': serializer.toJson<double?>(todayOrderMt),
      'todayCollectionRupees': serializer.toJson<double?>(
        todayCollectionRupees,
      ),
      'overdueAmount': serializer.toJson<double?>(overdueAmount),
      'feedbacks': serializer.toJson<String?>(feedbacks),
      'solutionBySalesperson': serializer.toJson<String?>(
        solutionBySalesperson,
      ),
      'anyRemarks': serializer.toJson<String?>(anyRemarks),
      'checkInTime': serializer.toJson<DateTime?>(checkInTime),
      'checkOutTime': serializer.toJson<DateTime?>(checkOutTime),
      'timeSpentinLoc': serializer.toJson<String?>(timeSpentinLoc),
      'inTimeImageUrl': serializer.toJson<String?>(inTimeImageUrl),
      'outTimeImageUrl': serializer.toJson<String?>(outTimeImageUrl),
      'pjpId': serializer.toJson<String?>(pjpId),
      'dailyTaskId': serializer.toJson<String?>(dailyTaskId),
      'customerType': serializer.toJson<String?>(customerType),
      'partyType': serializer.toJson<String?>(partyType),
      'nameOfParty': serializer.toJson<String?>(nameOfParty),
      'contactNoOfParty': serializer.toJson<String?>(contactNoOfParty),
      'expectedActivationDate': serializer.toJson<DateTime?>(
        expectedActivationDate,
      ),
      'currentDealerOutstandingAmt': serializer.toJson<double?>(
        currentDealerOutstandingAmt,
      ),
      'idempotencyKey': serializer.toJson<String?>(idempotencyKey),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  LocalDailyVisitReport copyWith({
    String? id,
    int? userId,
    Value<String?> dealerId = const Value.absent(),
    Value<String?> subDealerId = const Value.absent(),
    Value<DateTime?> reportDate = const Value.absent(),
    Value<String?> dealerType = const Value.absent(),
    Value<String?> location = const Value.absent(),
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    Value<String?> visitType = const Value.absent(),
    Value<double?> dealerTotalPotential = const Value.absent(),
    Value<double?> dealerBestPotential = const Value.absent(),
    Value<String?> brandSelling = const Value.absent(),
    Value<String?> contactPerson = const Value.absent(),
    Value<String?> contactPersonPhoneNo = const Value.absent(),
    Value<double?> todayOrderMt = const Value.absent(),
    Value<double?> todayCollectionRupees = const Value.absent(),
    Value<double?> overdueAmount = const Value.absent(),
    Value<String?> feedbacks = const Value.absent(),
    Value<String?> solutionBySalesperson = const Value.absent(),
    Value<String?> anyRemarks = const Value.absent(),
    Value<DateTime?> checkInTime = const Value.absent(),
    Value<DateTime?> checkOutTime = const Value.absent(),
    Value<String?> timeSpentinLoc = const Value.absent(),
    Value<String?> inTimeImageUrl = const Value.absent(),
    Value<String?> outTimeImageUrl = const Value.absent(),
    Value<String?> pjpId = const Value.absent(),
    Value<String?> dailyTaskId = const Value.absent(),
    Value<String?> customerType = const Value.absent(),
    Value<String?> partyType = const Value.absent(),
    Value<String?> nameOfParty = const Value.absent(),
    Value<String?> contactNoOfParty = const Value.absent(),
    Value<DateTime?> expectedActivationDate = const Value.absent(),
    Value<double?> currentDealerOutstandingAmt = const Value.absent(),
    Value<String?> idempotencyKey = const Value.absent(),
    String? syncStatus,
  }) => LocalDailyVisitReport(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    dealerId: dealerId.present ? dealerId.value : this.dealerId,
    subDealerId: subDealerId.present ? subDealerId.value : this.subDealerId,
    reportDate: reportDate.present ? reportDate.value : this.reportDate,
    dealerType: dealerType.present ? dealerType.value : this.dealerType,
    location: location.present ? location.value : this.location,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    visitType: visitType.present ? visitType.value : this.visitType,
    dealerTotalPotential: dealerTotalPotential.present
        ? dealerTotalPotential.value
        : this.dealerTotalPotential,
    dealerBestPotential: dealerBestPotential.present
        ? dealerBestPotential.value
        : this.dealerBestPotential,
    brandSelling: brandSelling.present ? brandSelling.value : this.brandSelling,
    contactPerson: contactPerson.present
        ? contactPerson.value
        : this.contactPerson,
    contactPersonPhoneNo: contactPersonPhoneNo.present
        ? contactPersonPhoneNo.value
        : this.contactPersonPhoneNo,
    todayOrderMt: todayOrderMt.present ? todayOrderMt.value : this.todayOrderMt,
    todayCollectionRupees: todayCollectionRupees.present
        ? todayCollectionRupees.value
        : this.todayCollectionRupees,
    overdueAmount: overdueAmount.present
        ? overdueAmount.value
        : this.overdueAmount,
    feedbacks: feedbacks.present ? feedbacks.value : this.feedbacks,
    solutionBySalesperson: solutionBySalesperson.present
        ? solutionBySalesperson.value
        : this.solutionBySalesperson,
    anyRemarks: anyRemarks.present ? anyRemarks.value : this.anyRemarks,
    checkInTime: checkInTime.present ? checkInTime.value : this.checkInTime,
    checkOutTime: checkOutTime.present ? checkOutTime.value : this.checkOutTime,
    timeSpentinLoc: timeSpentinLoc.present
        ? timeSpentinLoc.value
        : this.timeSpentinLoc,
    inTimeImageUrl: inTimeImageUrl.present
        ? inTimeImageUrl.value
        : this.inTimeImageUrl,
    outTimeImageUrl: outTimeImageUrl.present
        ? outTimeImageUrl.value
        : this.outTimeImageUrl,
    pjpId: pjpId.present ? pjpId.value : this.pjpId,
    dailyTaskId: dailyTaskId.present ? dailyTaskId.value : this.dailyTaskId,
    customerType: customerType.present ? customerType.value : this.customerType,
    partyType: partyType.present ? partyType.value : this.partyType,
    nameOfParty: nameOfParty.present ? nameOfParty.value : this.nameOfParty,
    contactNoOfParty: contactNoOfParty.present
        ? contactNoOfParty.value
        : this.contactNoOfParty,
    expectedActivationDate: expectedActivationDate.present
        ? expectedActivationDate.value
        : this.expectedActivationDate,
    currentDealerOutstandingAmt: currentDealerOutstandingAmt.present
        ? currentDealerOutstandingAmt.value
        : this.currentDealerOutstandingAmt,
    idempotencyKey: idempotencyKey.present
        ? idempotencyKey.value
        : this.idempotencyKey,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  LocalDailyVisitReport copyWithCompanion(
    LocalDailyVisitReportsCompanion data,
  ) {
    return LocalDailyVisitReport(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      dealerId: data.dealerId.present ? data.dealerId.value : this.dealerId,
      subDealerId: data.subDealerId.present
          ? data.subDealerId.value
          : this.subDealerId,
      reportDate: data.reportDate.present
          ? data.reportDate.value
          : this.reportDate,
      dealerType: data.dealerType.present
          ? data.dealerType.value
          : this.dealerType,
      location: data.location.present ? data.location.value : this.location,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      visitType: data.visitType.present ? data.visitType.value : this.visitType,
      dealerTotalPotential: data.dealerTotalPotential.present
          ? data.dealerTotalPotential.value
          : this.dealerTotalPotential,
      dealerBestPotential: data.dealerBestPotential.present
          ? data.dealerBestPotential.value
          : this.dealerBestPotential,
      brandSelling: data.brandSelling.present
          ? data.brandSelling.value
          : this.brandSelling,
      contactPerson: data.contactPerson.present
          ? data.contactPerson.value
          : this.contactPerson,
      contactPersonPhoneNo: data.contactPersonPhoneNo.present
          ? data.contactPersonPhoneNo.value
          : this.contactPersonPhoneNo,
      todayOrderMt: data.todayOrderMt.present
          ? data.todayOrderMt.value
          : this.todayOrderMt,
      todayCollectionRupees: data.todayCollectionRupees.present
          ? data.todayCollectionRupees.value
          : this.todayCollectionRupees,
      overdueAmount: data.overdueAmount.present
          ? data.overdueAmount.value
          : this.overdueAmount,
      feedbacks: data.feedbacks.present ? data.feedbacks.value : this.feedbacks,
      solutionBySalesperson: data.solutionBySalesperson.present
          ? data.solutionBySalesperson.value
          : this.solutionBySalesperson,
      anyRemarks: data.anyRemarks.present
          ? data.anyRemarks.value
          : this.anyRemarks,
      checkInTime: data.checkInTime.present
          ? data.checkInTime.value
          : this.checkInTime,
      checkOutTime: data.checkOutTime.present
          ? data.checkOutTime.value
          : this.checkOutTime,
      timeSpentinLoc: data.timeSpentinLoc.present
          ? data.timeSpentinLoc.value
          : this.timeSpentinLoc,
      inTimeImageUrl: data.inTimeImageUrl.present
          ? data.inTimeImageUrl.value
          : this.inTimeImageUrl,
      outTimeImageUrl: data.outTimeImageUrl.present
          ? data.outTimeImageUrl.value
          : this.outTimeImageUrl,
      pjpId: data.pjpId.present ? data.pjpId.value : this.pjpId,
      dailyTaskId: data.dailyTaskId.present
          ? data.dailyTaskId.value
          : this.dailyTaskId,
      customerType: data.customerType.present
          ? data.customerType.value
          : this.customerType,
      partyType: data.partyType.present ? data.partyType.value : this.partyType,
      nameOfParty: data.nameOfParty.present
          ? data.nameOfParty.value
          : this.nameOfParty,
      contactNoOfParty: data.contactNoOfParty.present
          ? data.contactNoOfParty.value
          : this.contactNoOfParty,
      expectedActivationDate: data.expectedActivationDate.present
          ? data.expectedActivationDate.value
          : this.expectedActivationDate,
      currentDealerOutstandingAmt: data.currentDealerOutstandingAmt.present
          ? data.currentDealerOutstandingAmt.value
          : this.currentDealerOutstandingAmt,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalDailyVisitReport(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('dealerId: $dealerId, ')
          ..write('subDealerId: $subDealerId, ')
          ..write('reportDate: $reportDate, ')
          ..write('dealerType: $dealerType, ')
          ..write('location: $location, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('visitType: $visitType, ')
          ..write('dealerTotalPotential: $dealerTotalPotential, ')
          ..write('dealerBestPotential: $dealerBestPotential, ')
          ..write('brandSelling: $brandSelling, ')
          ..write('contactPerson: $contactPerson, ')
          ..write('contactPersonPhoneNo: $contactPersonPhoneNo, ')
          ..write('todayOrderMt: $todayOrderMt, ')
          ..write('todayCollectionRupees: $todayCollectionRupees, ')
          ..write('overdueAmount: $overdueAmount, ')
          ..write('feedbacks: $feedbacks, ')
          ..write('solutionBySalesperson: $solutionBySalesperson, ')
          ..write('anyRemarks: $anyRemarks, ')
          ..write('checkInTime: $checkInTime, ')
          ..write('checkOutTime: $checkOutTime, ')
          ..write('timeSpentinLoc: $timeSpentinLoc, ')
          ..write('inTimeImageUrl: $inTimeImageUrl, ')
          ..write('outTimeImageUrl: $outTimeImageUrl, ')
          ..write('pjpId: $pjpId, ')
          ..write('dailyTaskId: $dailyTaskId, ')
          ..write('customerType: $customerType, ')
          ..write('partyType: $partyType, ')
          ..write('nameOfParty: $nameOfParty, ')
          ..write('contactNoOfParty: $contactNoOfParty, ')
          ..write('expectedActivationDate: $expectedActivationDate, ')
          ..write('currentDealerOutstandingAmt: $currentDealerOutstandingAmt, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    userId,
    dealerId,
    subDealerId,
    reportDate,
    dealerType,
    location,
    latitude,
    longitude,
    visitType,
    dealerTotalPotential,
    dealerBestPotential,
    brandSelling,
    contactPerson,
    contactPersonPhoneNo,
    todayOrderMt,
    todayCollectionRupees,
    overdueAmount,
    feedbacks,
    solutionBySalesperson,
    anyRemarks,
    checkInTime,
    checkOutTime,
    timeSpentinLoc,
    inTimeImageUrl,
    outTimeImageUrl,
    pjpId,
    dailyTaskId,
    customerType,
    partyType,
    nameOfParty,
    contactNoOfParty,
    expectedActivationDate,
    currentDealerOutstandingAmt,
    idempotencyKey,
    syncStatus,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalDailyVisitReport &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.dealerId == this.dealerId &&
          other.subDealerId == this.subDealerId &&
          other.reportDate == this.reportDate &&
          other.dealerType == this.dealerType &&
          other.location == this.location &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.visitType == this.visitType &&
          other.dealerTotalPotential == this.dealerTotalPotential &&
          other.dealerBestPotential == this.dealerBestPotential &&
          other.brandSelling == this.brandSelling &&
          other.contactPerson == this.contactPerson &&
          other.contactPersonPhoneNo == this.contactPersonPhoneNo &&
          other.todayOrderMt == this.todayOrderMt &&
          other.todayCollectionRupees == this.todayCollectionRupees &&
          other.overdueAmount == this.overdueAmount &&
          other.feedbacks == this.feedbacks &&
          other.solutionBySalesperson == this.solutionBySalesperson &&
          other.anyRemarks == this.anyRemarks &&
          other.checkInTime == this.checkInTime &&
          other.checkOutTime == this.checkOutTime &&
          other.timeSpentinLoc == this.timeSpentinLoc &&
          other.inTimeImageUrl == this.inTimeImageUrl &&
          other.outTimeImageUrl == this.outTimeImageUrl &&
          other.pjpId == this.pjpId &&
          other.dailyTaskId == this.dailyTaskId &&
          other.customerType == this.customerType &&
          other.partyType == this.partyType &&
          other.nameOfParty == this.nameOfParty &&
          other.contactNoOfParty == this.contactNoOfParty &&
          other.expectedActivationDate == this.expectedActivationDate &&
          other.currentDealerOutstandingAmt ==
              this.currentDealerOutstandingAmt &&
          other.idempotencyKey == this.idempotencyKey &&
          other.syncStatus == this.syncStatus);
}

class LocalDailyVisitReportsCompanion
    extends UpdateCompanion<LocalDailyVisitReport> {
  final Value<String> id;
  final Value<int> userId;
  final Value<String?> dealerId;
  final Value<String?> subDealerId;
  final Value<DateTime?> reportDate;
  final Value<String?> dealerType;
  final Value<String?> location;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<String?> visitType;
  final Value<double?> dealerTotalPotential;
  final Value<double?> dealerBestPotential;
  final Value<String?> brandSelling;
  final Value<String?> contactPerson;
  final Value<String?> contactPersonPhoneNo;
  final Value<double?> todayOrderMt;
  final Value<double?> todayCollectionRupees;
  final Value<double?> overdueAmount;
  final Value<String?> feedbacks;
  final Value<String?> solutionBySalesperson;
  final Value<String?> anyRemarks;
  final Value<DateTime?> checkInTime;
  final Value<DateTime?> checkOutTime;
  final Value<String?> timeSpentinLoc;
  final Value<String?> inTimeImageUrl;
  final Value<String?> outTimeImageUrl;
  final Value<String?> pjpId;
  final Value<String?> dailyTaskId;
  final Value<String?> customerType;
  final Value<String?> partyType;
  final Value<String?> nameOfParty;
  final Value<String?> contactNoOfParty;
  final Value<DateTime?> expectedActivationDate;
  final Value<double?> currentDealerOutstandingAmt;
  final Value<String?> idempotencyKey;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const LocalDailyVisitReportsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.dealerId = const Value.absent(),
    this.subDealerId = const Value.absent(),
    this.reportDate = const Value.absent(),
    this.dealerType = const Value.absent(),
    this.location = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.visitType = const Value.absent(),
    this.dealerTotalPotential = const Value.absent(),
    this.dealerBestPotential = const Value.absent(),
    this.brandSelling = const Value.absent(),
    this.contactPerson = const Value.absent(),
    this.contactPersonPhoneNo = const Value.absent(),
    this.todayOrderMt = const Value.absent(),
    this.todayCollectionRupees = const Value.absent(),
    this.overdueAmount = const Value.absent(),
    this.feedbacks = const Value.absent(),
    this.solutionBySalesperson = const Value.absent(),
    this.anyRemarks = const Value.absent(),
    this.checkInTime = const Value.absent(),
    this.checkOutTime = const Value.absent(),
    this.timeSpentinLoc = const Value.absent(),
    this.inTimeImageUrl = const Value.absent(),
    this.outTimeImageUrl = const Value.absent(),
    this.pjpId = const Value.absent(),
    this.dailyTaskId = const Value.absent(),
    this.customerType = const Value.absent(),
    this.partyType = const Value.absent(),
    this.nameOfParty = const Value.absent(),
    this.contactNoOfParty = const Value.absent(),
    this.expectedActivationDate = const Value.absent(),
    this.currentDealerOutstandingAmt = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalDailyVisitReportsCompanion.insert({
    required String id,
    required int userId,
    this.dealerId = const Value.absent(),
    this.subDealerId = const Value.absent(),
    this.reportDate = const Value.absent(),
    this.dealerType = const Value.absent(),
    this.location = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.visitType = const Value.absent(),
    this.dealerTotalPotential = const Value.absent(),
    this.dealerBestPotential = const Value.absent(),
    this.brandSelling = const Value.absent(),
    this.contactPerson = const Value.absent(),
    this.contactPersonPhoneNo = const Value.absent(),
    this.todayOrderMt = const Value.absent(),
    this.todayCollectionRupees = const Value.absent(),
    this.overdueAmount = const Value.absent(),
    this.feedbacks = const Value.absent(),
    this.solutionBySalesperson = const Value.absent(),
    this.anyRemarks = const Value.absent(),
    this.checkInTime = const Value.absent(),
    this.checkOutTime = const Value.absent(),
    this.timeSpentinLoc = const Value.absent(),
    this.inTimeImageUrl = const Value.absent(),
    this.outTimeImageUrl = const Value.absent(),
    this.pjpId = const Value.absent(),
    this.dailyTaskId = const Value.absent(),
    this.customerType = const Value.absent(),
    this.partyType = const Value.absent(),
    this.nameOfParty = const Value.absent(),
    this.contactNoOfParty = const Value.absent(),
    this.expectedActivationDate = const Value.absent(),
    this.currentDealerOutstandingAmt = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId);
  static Insertable<LocalDailyVisitReport> custom({
    Expression<String>? id,
    Expression<int>? userId,
    Expression<String>? dealerId,
    Expression<String>? subDealerId,
    Expression<DateTime>? reportDate,
    Expression<String>? dealerType,
    Expression<String>? location,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? visitType,
    Expression<double>? dealerTotalPotential,
    Expression<double>? dealerBestPotential,
    Expression<String>? brandSelling,
    Expression<String>? contactPerson,
    Expression<String>? contactPersonPhoneNo,
    Expression<double>? todayOrderMt,
    Expression<double>? todayCollectionRupees,
    Expression<double>? overdueAmount,
    Expression<String>? feedbacks,
    Expression<String>? solutionBySalesperson,
    Expression<String>? anyRemarks,
    Expression<DateTime>? checkInTime,
    Expression<DateTime>? checkOutTime,
    Expression<String>? timeSpentinLoc,
    Expression<String>? inTimeImageUrl,
    Expression<String>? outTimeImageUrl,
    Expression<String>? pjpId,
    Expression<String>? dailyTaskId,
    Expression<String>? customerType,
    Expression<String>? partyType,
    Expression<String>? nameOfParty,
    Expression<String>? contactNoOfParty,
    Expression<DateTime>? expectedActivationDate,
    Expression<double>? currentDealerOutstandingAmt,
    Expression<String>? idempotencyKey,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (dealerId != null) 'dealer_id': dealerId,
      if (subDealerId != null) 'sub_dealer_id': subDealerId,
      if (reportDate != null) 'report_date': reportDate,
      if (dealerType != null) 'dealer_type': dealerType,
      if (location != null) 'location': location,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (visitType != null) 'visit_type': visitType,
      if (dealerTotalPotential != null)
        'dealer_total_potential': dealerTotalPotential,
      if (dealerBestPotential != null)
        'dealer_best_potential': dealerBestPotential,
      if (brandSelling != null) 'brand_selling': brandSelling,
      if (contactPerson != null) 'contact_person': contactPerson,
      if (contactPersonPhoneNo != null)
        'contact_person_phone_no': contactPersonPhoneNo,
      if (todayOrderMt != null) 'today_order_mt': todayOrderMt,
      if (todayCollectionRupees != null)
        'today_collection_rupees': todayCollectionRupees,
      if (overdueAmount != null) 'overdue_amount': overdueAmount,
      if (feedbacks != null) 'feedbacks': feedbacks,
      if (solutionBySalesperson != null)
        'solution_by_salesperson': solutionBySalesperson,
      if (anyRemarks != null) 'any_remarks': anyRemarks,
      if (checkInTime != null) 'check_in_time': checkInTime,
      if (checkOutTime != null) 'check_out_time': checkOutTime,
      if (timeSpentinLoc != null) 'time_spentin_loc': timeSpentinLoc,
      if (inTimeImageUrl != null) 'in_time_image_url': inTimeImageUrl,
      if (outTimeImageUrl != null) 'out_time_image_url': outTimeImageUrl,
      if (pjpId != null) 'pjp_id': pjpId,
      if (dailyTaskId != null) 'daily_task_id': dailyTaskId,
      if (customerType != null) 'customer_type': customerType,
      if (partyType != null) 'party_type': partyType,
      if (nameOfParty != null) 'name_of_party': nameOfParty,
      if (contactNoOfParty != null) 'contact_no_of_party': contactNoOfParty,
      if (expectedActivationDate != null)
        'expected_activation_date': expectedActivationDate,
      if (currentDealerOutstandingAmt != null)
        'current_dealer_outstanding_amt': currentDealerOutstandingAmt,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalDailyVisitReportsCompanion copyWith({
    Value<String>? id,
    Value<int>? userId,
    Value<String?>? dealerId,
    Value<String?>? subDealerId,
    Value<DateTime?>? reportDate,
    Value<String?>? dealerType,
    Value<String?>? location,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<String?>? visitType,
    Value<double?>? dealerTotalPotential,
    Value<double?>? dealerBestPotential,
    Value<String?>? brandSelling,
    Value<String?>? contactPerson,
    Value<String?>? contactPersonPhoneNo,
    Value<double?>? todayOrderMt,
    Value<double?>? todayCollectionRupees,
    Value<double?>? overdueAmount,
    Value<String?>? feedbacks,
    Value<String?>? solutionBySalesperson,
    Value<String?>? anyRemarks,
    Value<DateTime?>? checkInTime,
    Value<DateTime?>? checkOutTime,
    Value<String?>? timeSpentinLoc,
    Value<String?>? inTimeImageUrl,
    Value<String?>? outTimeImageUrl,
    Value<String?>? pjpId,
    Value<String?>? dailyTaskId,
    Value<String?>? customerType,
    Value<String?>? partyType,
    Value<String?>? nameOfParty,
    Value<String?>? contactNoOfParty,
    Value<DateTime?>? expectedActivationDate,
    Value<double?>? currentDealerOutstandingAmt,
    Value<String?>? idempotencyKey,
    Value<String>? syncStatus,
    Value<int>? rowid,
  }) {
    return LocalDailyVisitReportsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      dealerId: dealerId ?? this.dealerId,
      subDealerId: subDealerId ?? this.subDealerId,
      reportDate: reportDate ?? this.reportDate,
      dealerType: dealerType ?? this.dealerType,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      visitType: visitType ?? this.visitType,
      dealerTotalPotential: dealerTotalPotential ?? this.dealerTotalPotential,
      dealerBestPotential: dealerBestPotential ?? this.dealerBestPotential,
      brandSelling: brandSelling ?? this.brandSelling,
      contactPerson: contactPerson ?? this.contactPerson,
      contactPersonPhoneNo: contactPersonPhoneNo ?? this.contactPersonPhoneNo,
      todayOrderMt: todayOrderMt ?? this.todayOrderMt,
      todayCollectionRupees:
          todayCollectionRupees ?? this.todayCollectionRupees,
      overdueAmount: overdueAmount ?? this.overdueAmount,
      feedbacks: feedbacks ?? this.feedbacks,
      solutionBySalesperson:
          solutionBySalesperson ?? this.solutionBySalesperson,
      anyRemarks: anyRemarks ?? this.anyRemarks,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      timeSpentinLoc: timeSpentinLoc ?? this.timeSpentinLoc,
      inTimeImageUrl: inTimeImageUrl ?? this.inTimeImageUrl,
      outTimeImageUrl: outTimeImageUrl ?? this.outTimeImageUrl,
      pjpId: pjpId ?? this.pjpId,
      dailyTaskId: dailyTaskId ?? this.dailyTaskId,
      customerType: customerType ?? this.customerType,
      partyType: partyType ?? this.partyType,
      nameOfParty: nameOfParty ?? this.nameOfParty,
      contactNoOfParty: contactNoOfParty ?? this.contactNoOfParty,
      expectedActivationDate:
          expectedActivationDate ?? this.expectedActivationDate,
      currentDealerOutstandingAmt:
          currentDealerOutstandingAmt ?? this.currentDealerOutstandingAmt,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (dealerId.present) {
      map['dealer_id'] = Variable<String>(dealerId.value);
    }
    if (subDealerId.present) {
      map['sub_dealer_id'] = Variable<String>(subDealerId.value);
    }
    if (reportDate.present) {
      map['report_date'] = Variable<DateTime>(reportDate.value);
    }
    if (dealerType.present) {
      map['dealer_type'] = Variable<String>(dealerType.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (visitType.present) {
      map['visit_type'] = Variable<String>(visitType.value);
    }
    if (dealerTotalPotential.present) {
      map['dealer_total_potential'] = Variable<double>(
        dealerTotalPotential.value,
      );
    }
    if (dealerBestPotential.present) {
      map['dealer_best_potential'] = Variable<double>(
        dealerBestPotential.value,
      );
    }
    if (brandSelling.present) {
      map['brand_selling'] = Variable<String>(brandSelling.value);
    }
    if (contactPerson.present) {
      map['contact_person'] = Variable<String>(contactPerson.value);
    }
    if (contactPersonPhoneNo.present) {
      map['contact_person_phone_no'] = Variable<String>(
        contactPersonPhoneNo.value,
      );
    }
    if (todayOrderMt.present) {
      map['today_order_mt'] = Variable<double>(todayOrderMt.value);
    }
    if (todayCollectionRupees.present) {
      map['today_collection_rupees'] = Variable<double>(
        todayCollectionRupees.value,
      );
    }
    if (overdueAmount.present) {
      map['overdue_amount'] = Variable<double>(overdueAmount.value);
    }
    if (feedbacks.present) {
      map['feedbacks'] = Variable<String>(feedbacks.value);
    }
    if (solutionBySalesperson.present) {
      map['solution_by_salesperson'] = Variable<String>(
        solutionBySalesperson.value,
      );
    }
    if (anyRemarks.present) {
      map['any_remarks'] = Variable<String>(anyRemarks.value);
    }
    if (checkInTime.present) {
      map['check_in_time'] = Variable<DateTime>(checkInTime.value);
    }
    if (checkOutTime.present) {
      map['check_out_time'] = Variable<DateTime>(checkOutTime.value);
    }
    if (timeSpentinLoc.present) {
      map['time_spentin_loc'] = Variable<String>(timeSpentinLoc.value);
    }
    if (inTimeImageUrl.present) {
      map['in_time_image_url'] = Variable<String>(inTimeImageUrl.value);
    }
    if (outTimeImageUrl.present) {
      map['out_time_image_url'] = Variable<String>(outTimeImageUrl.value);
    }
    if (pjpId.present) {
      map['pjp_id'] = Variable<String>(pjpId.value);
    }
    if (dailyTaskId.present) {
      map['daily_task_id'] = Variable<String>(dailyTaskId.value);
    }
    if (customerType.present) {
      map['customer_type'] = Variable<String>(customerType.value);
    }
    if (partyType.present) {
      map['party_type'] = Variable<String>(partyType.value);
    }
    if (nameOfParty.present) {
      map['name_of_party'] = Variable<String>(nameOfParty.value);
    }
    if (contactNoOfParty.present) {
      map['contact_no_of_party'] = Variable<String>(contactNoOfParty.value);
    }
    if (expectedActivationDate.present) {
      map['expected_activation_date'] = Variable<DateTime>(
        expectedActivationDate.value,
      );
    }
    if (currentDealerOutstandingAmt.present) {
      map['current_dealer_outstanding_amt'] = Variable<double>(
        currentDealerOutstandingAmt.value,
      );
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalDailyVisitReportsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('dealerId: $dealerId, ')
          ..write('subDealerId: $subDealerId, ')
          ..write('reportDate: $reportDate, ')
          ..write('dealerType: $dealerType, ')
          ..write('location: $location, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('visitType: $visitType, ')
          ..write('dealerTotalPotential: $dealerTotalPotential, ')
          ..write('dealerBestPotential: $dealerBestPotential, ')
          ..write('brandSelling: $brandSelling, ')
          ..write('contactPerson: $contactPerson, ')
          ..write('contactPersonPhoneNo: $contactPersonPhoneNo, ')
          ..write('todayOrderMt: $todayOrderMt, ')
          ..write('todayCollectionRupees: $todayCollectionRupees, ')
          ..write('overdueAmount: $overdueAmount, ')
          ..write('feedbacks: $feedbacks, ')
          ..write('solutionBySalesperson: $solutionBySalesperson, ')
          ..write('anyRemarks: $anyRemarks, ')
          ..write('checkInTime: $checkInTime, ')
          ..write('checkOutTime: $checkOutTime, ')
          ..write('timeSpentinLoc: $timeSpentinLoc, ')
          ..write('inTimeImageUrl: $inTimeImageUrl, ')
          ..write('outTimeImageUrl: $outTimeImageUrl, ')
          ..write('pjpId: $pjpId, ')
          ..write('dailyTaskId: $dailyTaskId, ')
          ..write('customerType: $customerType, ')
          ..write('partyType: $partyType, ')
          ..write('nameOfParty: $nameOfParty, ')
          ..write('contactNoOfParty: $contactNoOfParty, ')
          ..write('expectedActivationDate: $expectedActivationDate, ')
          ..write('currentDealerOutstandingAmt: $currentDealerOutstandingAmt, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localFilesMeta = const VerificationMeta(
    'localFiles',
  );
  @override
  late final GeneratedColumn<String> localFiles = GeneratedColumn<String>(
    'local_files',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('PENDING'),
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityType,
    payload,
    localFiles,
    status,
    retryCount,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('local_files')) {
      context.handle(
        _localFilesMeta,
        localFiles.isAcceptableOrUnknown(data['local_files']!, _localFilesMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      localFiles: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_files'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final String id;
  final String entityType;
  final String payload;
  final String? localFiles;
  final String status;
  final int retryCount;
  final DateTime createdAt;
  const SyncQueueData({
    required this.id,
    required this.entityType,
    required this.payload,
    this.localFiles,
    required this.status,
    required this.retryCount,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['payload'] = Variable<String>(payload);
    if (!nullToAbsent || localFiles != null) {
      map['local_files'] = Variable<String>(localFiles);
    }
    map['status'] = Variable<String>(status);
    map['retry_count'] = Variable<int>(retryCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      entityType: Value(entityType),
      payload: Value(payload),
      localFiles: localFiles == null && nullToAbsent
          ? const Value.absent()
          : Value(localFiles),
      status: Value(status),
      retryCount: Value(retryCount),
      createdAt: Value(createdAt),
    );
  }

  factory SyncQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      id: serializer.fromJson<String>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      payload: serializer.fromJson<String>(json['payload']),
      localFiles: serializer.fromJson<String?>(json['localFiles']),
      status: serializer.fromJson<String>(json['status']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entityType': serializer.toJson<String>(entityType),
      'payload': serializer.toJson<String>(payload),
      'localFiles': serializer.toJson<String?>(localFiles),
      'status': serializer.toJson<String>(status),
      'retryCount': serializer.toJson<int>(retryCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SyncQueueData copyWith({
    String? id,
    String? entityType,
    String? payload,
    Value<String?> localFiles = const Value.absent(),
    String? status,
    int? retryCount,
    DateTime? createdAt,
  }) => SyncQueueData(
    id: id ?? this.id,
    entityType: entityType ?? this.entityType,
    payload: payload ?? this.payload,
    localFiles: localFiles.present ? localFiles.value : this.localFiles,
    status: status ?? this.status,
    retryCount: retryCount ?? this.retryCount,
    createdAt: createdAt ?? this.createdAt,
  );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      payload: data.payload.present ? data.payload.value : this.payload,
      localFiles: data.localFiles.present
          ? data.localFiles.value
          : this.localFiles,
      status: data.status.present ? data.status.value : this.status,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('payload: $payload, ')
          ..write('localFiles: $localFiles, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityType,
    payload,
    localFiles,
    status,
    retryCount,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.payload == this.payload &&
          other.localFiles == this.localFiles &&
          other.status == this.status &&
          other.retryCount == this.retryCount &&
          other.createdAt == this.createdAt);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<String> id;
  final Value<String> entityType;
  final Value<String> payload;
  final Value<String?> localFiles;
  final Value<String> status;
  final Value<int> retryCount;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.payload = const Value.absent(),
    this.localFiles = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    required String id,
    required String entityType,
    required String payload,
    this.localFiles = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entityType = Value(entityType),
       payload = Value(payload),
       createdAt = Value(createdAt);
  static Insertable<SyncQueueData> custom({
    Expression<String>? id,
    Expression<String>? entityType,
    Expression<String>? payload,
    Expression<String>? localFiles,
    Expression<String>? status,
    Expression<int>? retryCount,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (payload != null) 'payload': payload,
      if (localFiles != null) 'local_files': localFiles,
      if (status != null) 'status': status,
      if (retryCount != null) 'retry_count': retryCount,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncQueueCompanion copyWith({
    Value<String>? id,
    Value<String>? entityType,
    Value<String>? payload,
    Value<String?>? localFiles,
    Value<String>? status,
    Value<int>? retryCount,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      payload: payload ?? this.payload,
      localFiles: localFiles ?? this.localFiles,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
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
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (localFiles.present) {
      map['local_files'] = Variable<String>(localFiles.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
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
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('payload: $payload, ')
          ..write('localFiles: $localFiles, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalDealersTable extends LocalDealers
    with TableInfo<$LocalDealersTable, LocalDealer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalDealersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Dealer'),
  );
  static const VerificationMeta _parentDealerIdMeta = const VerificationMeta(
    'parentDealerId',
  );
  @override
  late final GeneratedColumn<String> parentDealerId = GeneratedColumn<String>(
    'parent_dealer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _regionMeta = const VerificationMeta('region');
  @override
  late final GeneratedColumn<String> region = GeneratedColumn<String>(
    'region',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _areaMeta = const VerificationMeta('area');
  @override
  late final GeneratedColumn<String> area = GeneratedColumn<String>(
    'area',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _phoneNoMeta = const VerificationMeta(
    'phoneNo',
  );
  @override
  late final GeneratedColumn<String> phoneNo = GeneratedColumn<String>(
    'phone_no',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _pinCodeMeta = const VerificationMeta(
    'pinCode',
  );
  @override
  late final GeneratedColumn<String> pinCode = GeneratedColumn<String>(
    'pin_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateOfBirthMeta = const VerificationMeta(
    'dateOfBirth',
  );
  @override
  late final GeneratedColumn<DateTime> dateOfBirth = GeneratedColumn<DateTime>(
    'date_of_birth',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _anniversaryDateMeta = const VerificationMeta(
    'anniversaryDate',
  );
  @override
  late final GeneratedColumn<DateTime> anniversaryDate =
      GeneratedColumn<DateTime>(
        'anniversary_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _totalPotentialMeta = const VerificationMeta(
    'totalPotential',
  );
  @override
  late final GeneratedColumn<double> totalPotential = GeneratedColumn<double>(
    'total_potential',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _bestPotentialMeta = const VerificationMeta(
    'bestPotential',
  );
  @override
  late final GeneratedColumn<double> bestPotential = GeneratedColumn<double>(
    'best_potential',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _brandSellingMeta = const VerificationMeta(
    'brandSelling',
  );
  @override
  late final GeneratedColumn<String> brandSelling = GeneratedColumn<String>(
    'brand_selling',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _feedbacksMeta = const VerificationMeta(
    'feedbacks',
  );
  @override
  late final GeneratedColumn<String> feedbacks = GeneratedColumn<String>(
    'feedbacks',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _remarksMeta = const VerificationMeta(
    'remarks',
  );
  @override
  late final GeneratedColumn<String> remarks = GeneratedColumn<String>(
    'remarks',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dealerDevelopmentStatusMeta =
      const VerificationMeta('dealerDevelopmentStatus');
  @override
  late final GeneratedColumn<String> dealerDevelopmentStatus =
      GeneratedColumn<String>(
        'dealer_development_status',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _dealerDevelopmentObstacleMeta =
      const VerificationMeta('dealerDevelopmentObstacle');
  @override
  late final GeneratedColumn<String> dealerDevelopmentObstacle =
      GeneratedColumn<String>(
        'dealer_development_obstacle',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _salesGrowthPercentageMeta =
      const VerificationMeta('salesGrowthPercentage');
  @override
  late final GeneratedColumn<double> salesGrowthPercentage =
      GeneratedColumn<double>(
        'sales_growth_percentage',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _noOfPJPMeta = const VerificationMeta(
    'noOfPJP',
  );
  @override
  late final GeneratedColumn<int> noOfPJP = GeneratedColumn<int>(
    'no_of_p_j_p',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _verificationStatusMeta =
      const VerificationMeta('verificationStatus');
  @override
  late final GeneratedColumn<String> verificationStatus =
      GeneratedColumn<String>(
        'verification_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('PENDING'),
      );
  static const VerificationMeta _whatsappNoMeta = const VerificationMeta(
    'whatsappNo',
  );
  @override
  late final GeneratedColumn<String> whatsappNo = GeneratedColumn<String>(
    'whatsapp_no',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailIdMeta = const VerificationMeta(
    'emailId',
  );
  @override
  late final GeneratedColumn<String> emailId = GeneratedColumn<String>(
    'email_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _businessTypeMeta = const VerificationMeta(
    'businessType',
  );
  @override
  late final GeneratedColumn<String> businessType = GeneratedColumn<String>(
    'business_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameOfFirmMeta = const VerificationMeta(
    'nameOfFirm',
  );
  @override
  late final GeneratedColumn<String> nameOfFirm = GeneratedColumn<String>(
    'name_of_firm',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _underSalesPromoterNameMeta =
      const VerificationMeta('underSalesPromoterName');
  @override
  late final GeneratedColumn<String> underSalesPromoterName =
      GeneratedColumn<String>(
        'under_sales_promoter_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _gstinNoMeta = const VerificationMeta(
    'gstinNo',
  );
  @override
  late final GeneratedColumn<String> gstinNo = GeneratedColumn<String>(
    'gstin_no',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _panNoMeta = const VerificationMeta('panNo');
  @override
  late final GeneratedColumn<String> panNo = GeneratedColumn<String>(
    'pan_no',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tradeLicNoMeta = const VerificationMeta(
    'tradeLicNo',
  );
  @override
  late final GeneratedColumn<String> tradeLicNo = GeneratedColumn<String>(
    'trade_lic_no',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _aadharNoMeta = const VerificationMeta(
    'aadharNo',
  );
  @override
  late final GeneratedColumn<String> aadharNo = GeneratedColumn<String>(
    'aadhar_no',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _godownSizeSqFtMeta = const VerificationMeta(
    'godownSizeSqFt',
  );
  @override
  late final GeneratedColumn<int> godownSizeSqFt = GeneratedColumn<int>(
    'godown_size_sq_ft',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _godownCapacityMTBagsMeta =
      const VerificationMeta('godownCapacityMTBags');
  @override
  late final GeneratedColumn<String> godownCapacityMTBags =
      GeneratedColumn<String>(
        'godown_capacity_m_t_bags',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _godownAddressLineMeta = const VerificationMeta(
    'godownAddressLine',
  );
  @override
  late final GeneratedColumn<String> godownAddressLine =
      GeneratedColumn<String>(
        'godown_address_line',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _godownLandMarkMeta = const VerificationMeta(
    'godownLandMark',
  );
  @override
  late final GeneratedColumn<String> godownLandMark = GeneratedColumn<String>(
    'godown_land_mark',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _godownDistrictMeta = const VerificationMeta(
    'godownDistrict',
  );
  @override
  late final GeneratedColumn<String> godownDistrict = GeneratedColumn<String>(
    'godown_district',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _godownAreaMeta = const VerificationMeta(
    'godownArea',
  );
  @override
  late final GeneratedColumn<String> godownArea = GeneratedColumn<String>(
    'godown_area',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _godownRegionMeta = const VerificationMeta(
    'godownRegion',
  );
  @override
  late final GeneratedColumn<String> godownRegion = GeneratedColumn<String>(
    'godown_region',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _godownPinCodeMeta = const VerificationMeta(
    'godownPinCode',
  );
  @override
  late final GeneratedColumn<String> godownPinCode = GeneratedColumn<String>(
    'godown_pin_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _residentialAddressLineMeta =
      const VerificationMeta('residentialAddressLine');
  @override
  late final GeneratedColumn<String> residentialAddressLine =
      GeneratedColumn<String>(
        'residential_address_line',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _residentialLandMarkMeta =
      const VerificationMeta('residentialLandMark');
  @override
  late final GeneratedColumn<String> residentialLandMark =
      GeneratedColumn<String>(
        'residential_land_mark',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _residentialDistrictMeta =
      const VerificationMeta('residentialDistrict');
  @override
  late final GeneratedColumn<String> residentialDistrict =
      GeneratedColumn<String>(
        'residential_district',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _residentialAreaMeta = const VerificationMeta(
    'residentialArea',
  );
  @override
  late final GeneratedColumn<String> residentialArea = GeneratedColumn<String>(
    'residential_area',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _residentialRegionMeta = const VerificationMeta(
    'residentialRegion',
  );
  @override
  late final GeneratedColumn<String> residentialRegion =
      GeneratedColumn<String>(
        'residential_region',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _residentialPinCodeMeta =
      const VerificationMeta('residentialPinCode');
  @override
  late final GeneratedColumn<String> residentialPinCode =
      GeneratedColumn<String>(
        'residential_pin_code',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _bankAccountNameMeta = const VerificationMeta(
    'bankAccountName',
  );
  @override
  late final GeneratedColumn<String> bankAccountName = GeneratedColumn<String>(
    'bank_account_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bankNameMeta = const VerificationMeta(
    'bankName',
  );
  @override
  late final GeneratedColumn<String> bankName = GeneratedColumn<String>(
    'bank_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bankBranchAddressMeta = const VerificationMeta(
    'bankBranchAddress',
  );
  @override
  late final GeneratedColumn<String> bankBranchAddress =
      GeneratedColumn<String>(
        'bank_branch_address',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _bankAccountNumberMeta = const VerificationMeta(
    'bankAccountNumber',
  );
  @override
  late final GeneratedColumn<String> bankAccountNumber =
      GeneratedColumn<String>(
        'bank_account_number',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _bankIfscCodeMeta = const VerificationMeta(
    'bankIfscCode',
  );
  @override
  late final GeneratedColumn<String> bankIfscCode = GeneratedColumn<String>(
    'bank_ifsc_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _brandNameMeta = const VerificationMeta(
    'brandName',
  );
  @override
  late final GeneratedColumn<String> brandName = GeneratedColumn<String>(
    'brand_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _monthlySaleMTMeta = const VerificationMeta(
    'monthlySaleMT',
  );
  @override
  late final GeneratedColumn<double> monthlySaleMT = GeneratedColumn<double>(
    'monthly_sale_m_t',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noOfDealersMeta = const VerificationMeta(
    'noOfDealers',
  );
  @override
  late final GeneratedColumn<int> noOfDealers = GeneratedColumn<int>(
    'no_of_dealers',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _areaCoveredMeta = const VerificationMeta(
    'areaCovered',
  );
  @override
  late final GeneratedColumn<String> areaCovered = GeneratedColumn<String>(
    'area_covered',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _projectedMonthlySalesBestCementMTMeta =
      const VerificationMeta('projectedMonthlySalesBestCementMT');
  @override
  late final GeneratedColumn<double> projectedMonthlySalesBestCementMT =
      GeneratedColumn<double>(
        'projected_monthly_sales_best_cement_m_t',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _noOfEmployeesInSalesMeta =
      const VerificationMeta('noOfEmployeesInSales');
  @override
  late final GeneratedColumn<int> noOfEmployeesInSales = GeneratedColumn<int>(
    'no_of_employees_in_sales',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _declarationNameMeta = const VerificationMeta(
    'declarationName',
  );
  @override
  late final GeneratedColumn<String> declarationName = GeneratedColumn<String>(
    'declaration_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _declarationPlaceMeta = const VerificationMeta(
    'declarationPlace',
  );
  @override
  late final GeneratedColumn<String> declarationPlace = GeneratedColumn<String>(
    'declaration_place',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _declarationDateMeta = const VerificationMeta(
    'declarationDate',
  );
  @override
  late final GeneratedColumn<DateTime> declarationDate =
      GeneratedColumn<DateTime>(
        'declaration_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _tradeLicencePicUrlMeta =
      const VerificationMeta('tradeLicencePicUrl');
  @override
  late final GeneratedColumn<String> tradeLicencePicUrl =
      GeneratedColumn<String>(
        'trade_licence_pic_url',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _shopPicUrlMeta = const VerificationMeta(
    'shopPicUrl',
  );
  @override
  late final GeneratedColumn<String> shopPicUrl = GeneratedColumn<String>(
    'shop_pic_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dealerPicUrlMeta = const VerificationMeta(
    'dealerPicUrl',
  );
  @override
  late final GeneratedColumn<String> dealerPicUrl = GeneratedColumn<String>(
    'dealer_pic_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _blankChequePicUrlMeta = const VerificationMeta(
    'blankChequePicUrl',
  );
  @override
  late final GeneratedColumn<String> blankChequePicUrl =
      GeneratedColumn<String>(
        'blank_cheque_pic_url',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _partnershipDeedPicUrlMeta =
      const VerificationMeta('partnershipDeedPicUrl');
  @override
  late final GeneratedColumn<String> partnershipDeedPicUrl =
      GeneratedColumn<String>(
        'partnership_deed_pic_url',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    type,
    parentDealerId,
    name,
    region,
    area,
    phoneNo,
    address,
    pinCode,
    latitude,
    longitude,
    dateOfBirth,
    anniversaryDate,
    totalPotential,
    bestPotential,
    brandSelling,
    feedbacks,
    remarks,
    dealerDevelopmentStatus,
    dealerDevelopmentObstacle,
    salesGrowthPercentage,
    noOfPJP,
    verificationStatus,
    whatsappNo,
    emailId,
    businessType,
    nameOfFirm,
    underSalesPromoterName,
    gstinNo,
    panNo,
    tradeLicNo,
    aadharNo,
    godownSizeSqFt,
    godownCapacityMTBags,
    godownAddressLine,
    godownLandMark,
    godownDistrict,
    godownArea,
    godownRegion,
    godownPinCode,
    residentialAddressLine,
    residentialLandMark,
    residentialDistrict,
    residentialArea,
    residentialRegion,
    residentialPinCode,
    bankAccountName,
    bankName,
    bankBranchAddress,
    bankAccountNumber,
    bankIfscCode,
    brandName,
    monthlySaleMT,
    noOfDealers,
    areaCovered,
    projectedMonthlySalesBestCementMT,
    noOfEmployeesInSales,
    declarationName,
    declarationPlace,
    declarationDate,
    tradeLicencePicUrl,
    shopPicUrl,
    dealerPicUrl,
    blankChequePicUrl,
    partnershipDeedPicUrl,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_dealers';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalDealer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('parent_dealer_id')) {
      context.handle(
        _parentDealerIdMeta,
        parentDealerId.isAcceptableOrUnknown(
          data['parent_dealer_id']!,
          _parentDealerIdMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('region')) {
      context.handle(
        _regionMeta,
        region.isAcceptableOrUnknown(data['region']!, _regionMeta),
      );
    }
    if (data.containsKey('area')) {
      context.handle(
        _areaMeta,
        area.isAcceptableOrUnknown(data['area']!, _areaMeta),
      );
    }
    if (data.containsKey('phone_no')) {
      context.handle(
        _phoneNoMeta,
        phoneNo.isAcceptableOrUnknown(data['phone_no']!, _phoneNoMeta),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('pin_code')) {
      context.handle(
        _pinCodeMeta,
        pinCode.isAcceptableOrUnknown(data['pin_code']!, _pinCodeMeta),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('date_of_birth')) {
      context.handle(
        _dateOfBirthMeta,
        dateOfBirth.isAcceptableOrUnknown(
          data['date_of_birth']!,
          _dateOfBirthMeta,
        ),
      );
    }
    if (data.containsKey('anniversary_date')) {
      context.handle(
        _anniversaryDateMeta,
        anniversaryDate.isAcceptableOrUnknown(
          data['anniversary_date']!,
          _anniversaryDateMeta,
        ),
      );
    }
    if (data.containsKey('total_potential')) {
      context.handle(
        _totalPotentialMeta,
        totalPotential.isAcceptableOrUnknown(
          data['total_potential']!,
          _totalPotentialMeta,
        ),
      );
    }
    if (data.containsKey('best_potential')) {
      context.handle(
        _bestPotentialMeta,
        bestPotential.isAcceptableOrUnknown(
          data['best_potential']!,
          _bestPotentialMeta,
        ),
      );
    }
    if (data.containsKey('brand_selling')) {
      context.handle(
        _brandSellingMeta,
        brandSelling.isAcceptableOrUnknown(
          data['brand_selling']!,
          _brandSellingMeta,
        ),
      );
    }
    if (data.containsKey('feedbacks')) {
      context.handle(
        _feedbacksMeta,
        feedbacks.isAcceptableOrUnknown(data['feedbacks']!, _feedbacksMeta),
      );
    }
    if (data.containsKey('remarks')) {
      context.handle(
        _remarksMeta,
        remarks.isAcceptableOrUnknown(data['remarks']!, _remarksMeta),
      );
    }
    if (data.containsKey('dealer_development_status')) {
      context.handle(
        _dealerDevelopmentStatusMeta,
        dealerDevelopmentStatus.isAcceptableOrUnknown(
          data['dealer_development_status']!,
          _dealerDevelopmentStatusMeta,
        ),
      );
    }
    if (data.containsKey('dealer_development_obstacle')) {
      context.handle(
        _dealerDevelopmentObstacleMeta,
        dealerDevelopmentObstacle.isAcceptableOrUnknown(
          data['dealer_development_obstacle']!,
          _dealerDevelopmentObstacleMeta,
        ),
      );
    }
    if (data.containsKey('sales_growth_percentage')) {
      context.handle(
        _salesGrowthPercentageMeta,
        salesGrowthPercentage.isAcceptableOrUnknown(
          data['sales_growth_percentage']!,
          _salesGrowthPercentageMeta,
        ),
      );
    }
    if (data.containsKey('no_of_p_j_p')) {
      context.handle(
        _noOfPJPMeta,
        noOfPJP.isAcceptableOrUnknown(data['no_of_p_j_p']!, _noOfPJPMeta),
      );
    }
    if (data.containsKey('verification_status')) {
      context.handle(
        _verificationStatusMeta,
        verificationStatus.isAcceptableOrUnknown(
          data['verification_status']!,
          _verificationStatusMeta,
        ),
      );
    }
    if (data.containsKey('whatsapp_no')) {
      context.handle(
        _whatsappNoMeta,
        whatsappNo.isAcceptableOrUnknown(data['whatsapp_no']!, _whatsappNoMeta),
      );
    }
    if (data.containsKey('email_id')) {
      context.handle(
        _emailIdMeta,
        emailId.isAcceptableOrUnknown(data['email_id']!, _emailIdMeta),
      );
    }
    if (data.containsKey('business_type')) {
      context.handle(
        _businessTypeMeta,
        businessType.isAcceptableOrUnknown(
          data['business_type']!,
          _businessTypeMeta,
        ),
      );
    }
    if (data.containsKey('name_of_firm')) {
      context.handle(
        _nameOfFirmMeta,
        nameOfFirm.isAcceptableOrUnknown(
          data['name_of_firm']!,
          _nameOfFirmMeta,
        ),
      );
    }
    if (data.containsKey('under_sales_promoter_name')) {
      context.handle(
        _underSalesPromoterNameMeta,
        underSalesPromoterName.isAcceptableOrUnknown(
          data['under_sales_promoter_name']!,
          _underSalesPromoterNameMeta,
        ),
      );
    }
    if (data.containsKey('gstin_no')) {
      context.handle(
        _gstinNoMeta,
        gstinNo.isAcceptableOrUnknown(data['gstin_no']!, _gstinNoMeta),
      );
    }
    if (data.containsKey('pan_no')) {
      context.handle(
        _panNoMeta,
        panNo.isAcceptableOrUnknown(data['pan_no']!, _panNoMeta),
      );
    }
    if (data.containsKey('trade_lic_no')) {
      context.handle(
        _tradeLicNoMeta,
        tradeLicNo.isAcceptableOrUnknown(
          data['trade_lic_no']!,
          _tradeLicNoMeta,
        ),
      );
    }
    if (data.containsKey('aadhar_no')) {
      context.handle(
        _aadharNoMeta,
        aadharNo.isAcceptableOrUnknown(data['aadhar_no']!, _aadharNoMeta),
      );
    }
    if (data.containsKey('godown_size_sq_ft')) {
      context.handle(
        _godownSizeSqFtMeta,
        godownSizeSqFt.isAcceptableOrUnknown(
          data['godown_size_sq_ft']!,
          _godownSizeSqFtMeta,
        ),
      );
    }
    if (data.containsKey('godown_capacity_m_t_bags')) {
      context.handle(
        _godownCapacityMTBagsMeta,
        godownCapacityMTBags.isAcceptableOrUnknown(
          data['godown_capacity_m_t_bags']!,
          _godownCapacityMTBagsMeta,
        ),
      );
    }
    if (data.containsKey('godown_address_line')) {
      context.handle(
        _godownAddressLineMeta,
        godownAddressLine.isAcceptableOrUnknown(
          data['godown_address_line']!,
          _godownAddressLineMeta,
        ),
      );
    }
    if (data.containsKey('godown_land_mark')) {
      context.handle(
        _godownLandMarkMeta,
        godownLandMark.isAcceptableOrUnknown(
          data['godown_land_mark']!,
          _godownLandMarkMeta,
        ),
      );
    }
    if (data.containsKey('godown_district')) {
      context.handle(
        _godownDistrictMeta,
        godownDistrict.isAcceptableOrUnknown(
          data['godown_district']!,
          _godownDistrictMeta,
        ),
      );
    }
    if (data.containsKey('godown_area')) {
      context.handle(
        _godownAreaMeta,
        godownArea.isAcceptableOrUnknown(data['godown_area']!, _godownAreaMeta),
      );
    }
    if (data.containsKey('godown_region')) {
      context.handle(
        _godownRegionMeta,
        godownRegion.isAcceptableOrUnknown(
          data['godown_region']!,
          _godownRegionMeta,
        ),
      );
    }
    if (data.containsKey('godown_pin_code')) {
      context.handle(
        _godownPinCodeMeta,
        godownPinCode.isAcceptableOrUnknown(
          data['godown_pin_code']!,
          _godownPinCodeMeta,
        ),
      );
    }
    if (data.containsKey('residential_address_line')) {
      context.handle(
        _residentialAddressLineMeta,
        residentialAddressLine.isAcceptableOrUnknown(
          data['residential_address_line']!,
          _residentialAddressLineMeta,
        ),
      );
    }
    if (data.containsKey('residential_land_mark')) {
      context.handle(
        _residentialLandMarkMeta,
        residentialLandMark.isAcceptableOrUnknown(
          data['residential_land_mark']!,
          _residentialLandMarkMeta,
        ),
      );
    }
    if (data.containsKey('residential_district')) {
      context.handle(
        _residentialDistrictMeta,
        residentialDistrict.isAcceptableOrUnknown(
          data['residential_district']!,
          _residentialDistrictMeta,
        ),
      );
    }
    if (data.containsKey('residential_area')) {
      context.handle(
        _residentialAreaMeta,
        residentialArea.isAcceptableOrUnknown(
          data['residential_area']!,
          _residentialAreaMeta,
        ),
      );
    }
    if (data.containsKey('residential_region')) {
      context.handle(
        _residentialRegionMeta,
        residentialRegion.isAcceptableOrUnknown(
          data['residential_region']!,
          _residentialRegionMeta,
        ),
      );
    }
    if (data.containsKey('residential_pin_code')) {
      context.handle(
        _residentialPinCodeMeta,
        residentialPinCode.isAcceptableOrUnknown(
          data['residential_pin_code']!,
          _residentialPinCodeMeta,
        ),
      );
    }
    if (data.containsKey('bank_account_name')) {
      context.handle(
        _bankAccountNameMeta,
        bankAccountName.isAcceptableOrUnknown(
          data['bank_account_name']!,
          _bankAccountNameMeta,
        ),
      );
    }
    if (data.containsKey('bank_name')) {
      context.handle(
        _bankNameMeta,
        bankName.isAcceptableOrUnknown(data['bank_name']!, _bankNameMeta),
      );
    }
    if (data.containsKey('bank_branch_address')) {
      context.handle(
        _bankBranchAddressMeta,
        bankBranchAddress.isAcceptableOrUnknown(
          data['bank_branch_address']!,
          _bankBranchAddressMeta,
        ),
      );
    }
    if (data.containsKey('bank_account_number')) {
      context.handle(
        _bankAccountNumberMeta,
        bankAccountNumber.isAcceptableOrUnknown(
          data['bank_account_number']!,
          _bankAccountNumberMeta,
        ),
      );
    }
    if (data.containsKey('bank_ifsc_code')) {
      context.handle(
        _bankIfscCodeMeta,
        bankIfscCode.isAcceptableOrUnknown(
          data['bank_ifsc_code']!,
          _bankIfscCodeMeta,
        ),
      );
    }
    if (data.containsKey('brand_name')) {
      context.handle(
        _brandNameMeta,
        brandName.isAcceptableOrUnknown(data['brand_name']!, _brandNameMeta),
      );
    }
    if (data.containsKey('monthly_sale_m_t')) {
      context.handle(
        _monthlySaleMTMeta,
        monthlySaleMT.isAcceptableOrUnknown(
          data['monthly_sale_m_t']!,
          _monthlySaleMTMeta,
        ),
      );
    }
    if (data.containsKey('no_of_dealers')) {
      context.handle(
        _noOfDealersMeta,
        noOfDealers.isAcceptableOrUnknown(
          data['no_of_dealers']!,
          _noOfDealersMeta,
        ),
      );
    }
    if (data.containsKey('area_covered')) {
      context.handle(
        _areaCoveredMeta,
        areaCovered.isAcceptableOrUnknown(
          data['area_covered']!,
          _areaCoveredMeta,
        ),
      );
    }
    if (data.containsKey('projected_monthly_sales_best_cement_m_t')) {
      context.handle(
        _projectedMonthlySalesBestCementMTMeta,
        projectedMonthlySalesBestCementMT.isAcceptableOrUnknown(
          data['projected_monthly_sales_best_cement_m_t']!,
          _projectedMonthlySalesBestCementMTMeta,
        ),
      );
    }
    if (data.containsKey('no_of_employees_in_sales')) {
      context.handle(
        _noOfEmployeesInSalesMeta,
        noOfEmployeesInSales.isAcceptableOrUnknown(
          data['no_of_employees_in_sales']!,
          _noOfEmployeesInSalesMeta,
        ),
      );
    }
    if (data.containsKey('declaration_name')) {
      context.handle(
        _declarationNameMeta,
        declarationName.isAcceptableOrUnknown(
          data['declaration_name']!,
          _declarationNameMeta,
        ),
      );
    }
    if (data.containsKey('declaration_place')) {
      context.handle(
        _declarationPlaceMeta,
        declarationPlace.isAcceptableOrUnknown(
          data['declaration_place']!,
          _declarationPlaceMeta,
        ),
      );
    }
    if (data.containsKey('declaration_date')) {
      context.handle(
        _declarationDateMeta,
        declarationDate.isAcceptableOrUnknown(
          data['declaration_date']!,
          _declarationDateMeta,
        ),
      );
    }
    if (data.containsKey('trade_licence_pic_url')) {
      context.handle(
        _tradeLicencePicUrlMeta,
        tradeLicencePicUrl.isAcceptableOrUnknown(
          data['trade_licence_pic_url']!,
          _tradeLicencePicUrlMeta,
        ),
      );
    }
    if (data.containsKey('shop_pic_url')) {
      context.handle(
        _shopPicUrlMeta,
        shopPicUrl.isAcceptableOrUnknown(
          data['shop_pic_url']!,
          _shopPicUrlMeta,
        ),
      );
    }
    if (data.containsKey('dealer_pic_url')) {
      context.handle(
        _dealerPicUrlMeta,
        dealerPicUrl.isAcceptableOrUnknown(
          data['dealer_pic_url']!,
          _dealerPicUrlMeta,
        ),
      );
    }
    if (data.containsKey('blank_cheque_pic_url')) {
      context.handle(
        _blankChequePicUrlMeta,
        blankChequePicUrl.isAcceptableOrUnknown(
          data['blank_cheque_pic_url']!,
          _blankChequePicUrlMeta,
        ),
      );
    }
    if (data.containsKey('partnership_deed_pic_url')) {
      context.handle(
        _partnershipDeedPicUrlMeta,
        partnershipDeedPicUrl.isAcceptableOrUnknown(
          data['partnership_deed_pic_url']!,
          _partnershipDeedPicUrlMeta,
        ),
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
  LocalDealer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalDealer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      parentDealerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_dealer_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      region: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}region'],
      )!,
      area: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}area'],
      )!,
      phoneNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone_no'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      )!,
      pinCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pin_code'],
      ),
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      dateOfBirth: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_of_birth'],
      ),
      anniversaryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}anniversary_date'],
      ),
      totalPotential: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_potential'],
      )!,
      bestPotential: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}best_potential'],
      )!,
      brandSelling: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand_selling'],
      ),
      feedbacks: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}feedbacks'],
      )!,
      remarks: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remarks'],
      ),
      dealerDevelopmentStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dealer_development_status'],
      ),
      dealerDevelopmentObstacle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dealer_development_obstacle'],
      ),
      salesGrowthPercentage: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sales_growth_percentage'],
      ),
      noOfPJP: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}no_of_p_j_p'],
      ),
      verificationStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}verification_status'],
      )!,
      whatsappNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}whatsapp_no'],
      ),
      emailId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email_id'],
      ),
      businessType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_type'],
      ),
      nameOfFirm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_of_firm'],
      ),
      underSalesPromoterName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}under_sales_promoter_name'],
      ),
      gstinNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gstin_no'],
      ),
      panNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pan_no'],
      ),
      tradeLicNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trade_lic_no'],
      ),
      aadharNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aadhar_no'],
      ),
      godownSizeSqFt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}godown_size_sq_ft'],
      ),
      godownCapacityMTBags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}godown_capacity_m_t_bags'],
      ),
      godownAddressLine: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}godown_address_line'],
      ),
      godownLandMark: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}godown_land_mark'],
      ),
      godownDistrict: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}godown_district'],
      ),
      godownArea: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}godown_area'],
      ),
      godownRegion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}godown_region'],
      ),
      godownPinCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}godown_pin_code'],
      ),
      residentialAddressLine: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}residential_address_line'],
      ),
      residentialLandMark: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}residential_land_mark'],
      ),
      residentialDistrict: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}residential_district'],
      ),
      residentialArea: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}residential_area'],
      ),
      residentialRegion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}residential_region'],
      ),
      residentialPinCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}residential_pin_code'],
      ),
      bankAccountName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_account_name'],
      ),
      bankName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_name'],
      ),
      bankBranchAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_branch_address'],
      ),
      bankAccountNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_account_number'],
      ),
      bankIfscCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_ifsc_code'],
      ),
      brandName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand_name'],
      ),
      monthlySaleMT: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monthly_sale_m_t'],
      ),
      noOfDealers: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}no_of_dealers'],
      ),
      areaCovered: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}area_covered'],
      ),
      projectedMonthlySalesBestCementMT: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}projected_monthly_sales_best_cement_m_t'],
      ),
      noOfEmployeesInSales: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}no_of_employees_in_sales'],
      ),
      declarationName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}declaration_name'],
      ),
      declarationPlace: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}declaration_place'],
      ),
      declarationDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}declaration_date'],
      ),
      tradeLicencePicUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trade_licence_pic_url'],
      ),
      shopPicUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shop_pic_url'],
      ),
      dealerPicUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dealer_pic_url'],
      ),
      blankChequePicUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}blank_cheque_pic_url'],
      ),
      partnershipDeedPicUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}partnership_deed_pic_url'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $LocalDealersTable createAlias(String alias) {
    return $LocalDealersTable(attachedDatabase, alias);
  }
}

class LocalDealer extends DataClass implements Insertable<LocalDealer> {
  final String id;
  final int? userId;
  final String type;
  final String? parentDealerId;
  final String name;
  final String region;
  final String area;
  final String phoneNo;
  final String address;
  final String? pinCode;
  final double? latitude;
  final double? longitude;
  final DateTime? dateOfBirth;
  final DateTime? anniversaryDate;
  final double totalPotential;
  final double bestPotential;
  final String? brandSelling;
  final String feedbacks;
  final String? remarks;
  final String? dealerDevelopmentStatus;
  final String? dealerDevelopmentObstacle;
  final double? salesGrowthPercentage;
  final int? noOfPJP;
  final String verificationStatus;
  final String? whatsappNo;
  final String? emailId;
  final String? businessType;
  final String? nameOfFirm;
  final String? underSalesPromoterName;
  final String? gstinNo;
  final String? panNo;
  final String? tradeLicNo;
  final String? aadharNo;
  final int? godownSizeSqFt;
  final String? godownCapacityMTBags;
  final String? godownAddressLine;
  final String? godownLandMark;
  final String? godownDistrict;
  final String? godownArea;
  final String? godownRegion;
  final String? godownPinCode;
  final String? residentialAddressLine;
  final String? residentialLandMark;
  final String? residentialDistrict;
  final String? residentialArea;
  final String? residentialRegion;
  final String? residentialPinCode;
  final String? bankAccountName;
  final String? bankName;
  final String? bankBranchAddress;
  final String? bankAccountNumber;
  final String? bankIfscCode;
  final String? brandName;
  final double? monthlySaleMT;
  final int? noOfDealers;
  final String? areaCovered;
  final double? projectedMonthlySalesBestCementMT;
  final int? noOfEmployeesInSales;
  final String? declarationName;
  final String? declarationPlace;
  final DateTime? declarationDate;
  final String? tradeLicencePicUrl;
  final String? shopPicUrl;
  final String? dealerPicUrl;
  final String? blankChequePicUrl;
  final String? partnershipDeedPicUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  const LocalDealer({
    required this.id,
    this.userId,
    required this.type,
    this.parentDealerId,
    required this.name,
    required this.region,
    required this.area,
    required this.phoneNo,
    required this.address,
    this.pinCode,
    this.latitude,
    this.longitude,
    this.dateOfBirth,
    this.anniversaryDate,
    required this.totalPotential,
    required this.bestPotential,
    this.brandSelling,
    required this.feedbacks,
    this.remarks,
    this.dealerDevelopmentStatus,
    this.dealerDevelopmentObstacle,
    this.salesGrowthPercentage,
    this.noOfPJP,
    required this.verificationStatus,
    this.whatsappNo,
    this.emailId,
    this.businessType,
    this.nameOfFirm,
    this.underSalesPromoterName,
    this.gstinNo,
    this.panNo,
    this.tradeLicNo,
    this.aadharNo,
    this.godownSizeSqFt,
    this.godownCapacityMTBags,
    this.godownAddressLine,
    this.godownLandMark,
    this.godownDistrict,
    this.godownArea,
    this.godownRegion,
    this.godownPinCode,
    this.residentialAddressLine,
    this.residentialLandMark,
    this.residentialDistrict,
    this.residentialArea,
    this.residentialRegion,
    this.residentialPinCode,
    this.bankAccountName,
    this.bankName,
    this.bankBranchAddress,
    this.bankAccountNumber,
    this.bankIfscCode,
    this.brandName,
    this.monthlySaleMT,
    this.noOfDealers,
    this.areaCovered,
    this.projectedMonthlySalesBestCementMT,
    this.noOfEmployeesInSales,
    this.declarationName,
    this.declarationPlace,
    this.declarationDate,
    this.tradeLicencePicUrl,
    this.shopPicUrl,
    this.dealerPicUrl,
    this.blankChequePicUrl,
    this.partnershipDeedPicUrl,
    this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<int>(userId);
    }
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || parentDealerId != null) {
      map['parent_dealer_id'] = Variable<String>(parentDealerId);
    }
    map['name'] = Variable<String>(name);
    map['region'] = Variable<String>(region);
    map['area'] = Variable<String>(area);
    map['phone_no'] = Variable<String>(phoneNo);
    map['address'] = Variable<String>(address);
    if (!nullToAbsent || pinCode != null) {
      map['pin_code'] = Variable<String>(pinCode);
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    if (!nullToAbsent || dateOfBirth != null) {
      map['date_of_birth'] = Variable<DateTime>(dateOfBirth);
    }
    if (!nullToAbsent || anniversaryDate != null) {
      map['anniversary_date'] = Variable<DateTime>(anniversaryDate);
    }
    map['total_potential'] = Variable<double>(totalPotential);
    map['best_potential'] = Variable<double>(bestPotential);
    if (!nullToAbsent || brandSelling != null) {
      map['brand_selling'] = Variable<String>(brandSelling);
    }
    map['feedbacks'] = Variable<String>(feedbacks);
    if (!nullToAbsent || remarks != null) {
      map['remarks'] = Variable<String>(remarks);
    }
    if (!nullToAbsent || dealerDevelopmentStatus != null) {
      map['dealer_development_status'] = Variable<String>(
        dealerDevelopmentStatus,
      );
    }
    if (!nullToAbsent || dealerDevelopmentObstacle != null) {
      map['dealer_development_obstacle'] = Variable<String>(
        dealerDevelopmentObstacle,
      );
    }
    if (!nullToAbsent || salesGrowthPercentage != null) {
      map['sales_growth_percentage'] = Variable<double>(salesGrowthPercentage);
    }
    if (!nullToAbsent || noOfPJP != null) {
      map['no_of_p_j_p'] = Variable<int>(noOfPJP);
    }
    map['verification_status'] = Variable<String>(verificationStatus);
    if (!nullToAbsent || whatsappNo != null) {
      map['whatsapp_no'] = Variable<String>(whatsappNo);
    }
    if (!nullToAbsent || emailId != null) {
      map['email_id'] = Variable<String>(emailId);
    }
    if (!nullToAbsent || businessType != null) {
      map['business_type'] = Variable<String>(businessType);
    }
    if (!nullToAbsent || nameOfFirm != null) {
      map['name_of_firm'] = Variable<String>(nameOfFirm);
    }
    if (!nullToAbsent || underSalesPromoterName != null) {
      map['under_sales_promoter_name'] = Variable<String>(
        underSalesPromoterName,
      );
    }
    if (!nullToAbsent || gstinNo != null) {
      map['gstin_no'] = Variable<String>(gstinNo);
    }
    if (!nullToAbsent || panNo != null) {
      map['pan_no'] = Variable<String>(panNo);
    }
    if (!nullToAbsent || tradeLicNo != null) {
      map['trade_lic_no'] = Variable<String>(tradeLicNo);
    }
    if (!nullToAbsent || aadharNo != null) {
      map['aadhar_no'] = Variable<String>(aadharNo);
    }
    if (!nullToAbsent || godownSizeSqFt != null) {
      map['godown_size_sq_ft'] = Variable<int>(godownSizeSqFt);
    }
    if (!nullToAbsent || godownCapacityMTBags != null) {
      map['godown_capacity_m_t_bags'] = Variable<String>(godownCapacityMTBags);
    }
    if (!nullToAbsent || godownAddressLine != null) {
      map['godown_address_line'] = Variable<String>(godownAddressLine);
    }
    if (!nullToAbsent || godownLandMark != null) {
      map['godown_land_mark'] = Variable<String>(godownLandMark);
    }
    if (!nullToAbsent || godownDistrict != null) {
      map['godown_district'] = Variable<String>(godownDistrict);
    }
    if (!nullToAbsent || godownArea != null) {
      map['godown_area'] = Variable<String>(godownArea);
    }
    if (!nullToAbsent || godownRegion != null) {
      map['godown_region'] = Variable<String>(godownRegion);
    }
    if (!nullToAbsent || godownPinCode != null) {
      map['godown_pin_code'] = Variable<String>(godownPinCode);
    }
    if (!nullToAbsent || residentialAddressLine != null) {
      map['residential_address_line'] = Variable<String>(
        residentialAddressLine,
      );
    }
    if (!nullToAbsent || residentialLandMark != null) {
      map['residential_land_mark'] = Variable<String>(residentialLandMark);
    }
    if (!nullToAbsent || residentialDistrict != null) {
      map['residential_district'] = Variable<String>(residentialDistrict);
    }
    if (!nullToAbsent || residentialArea != null) {
      map['residential_area'] = Variable<String>(residentialArea);
    }
    if (!nullToAbsent || residentialRegion != null) {
      map['residential_region'] = Variable<String>(residentialRegion);
    }
    if (!nullToAbsent || residentialPinCode != null) {
      map['residential_pin_code'] = Variable<String>(residentialPinCode);
    }
    if (!nullToAbsent || bankAccountName != null) {
      map['bank_account_name'] = Variable<String>(bankAccountName);
    }
    if (!nullToAbsent || bankName != null) {
      map['bank_name'] = Variable<String>(bankName);
    }
    if (!nullToAbsent || bankBranchAddress != null) {
      map['bank_branch_address'] = Variable<String>(bankBranchAddress);
    }
    if (!nullToAbsent || bankAccountNumber != null) {
      map['bank_account_number'] = Variable<String>(bankAccountNumber);
    }
    if (!nullToAbsent || bankIfscCode != null) {
      map['bank_ifsc_code'] = Variable<String>(bankIfscCode);
    }
    if (!nullToAbsent || brandName != null) {
      map['brand_name'] = Variable<String>(brandName);
    }
    if (!nullToAbsent || monthlySaleMT != null) {
      map['monthly_sale_m_t'] = Variable<double>(monthlySaleMT);
    }
    if (!nullToAbsent || noOfDealers != null) {
      map['no_of_dealers'] = Variable<int>(noOfDealers);
    }
    if (!nullToAbsent || areaCovered != null) {
      map['area_covered'] = Variable<String>(areaCovered);
    }
    if (!nullToAbsent || projectedMonthlySalesBestCementMT != null) {
      map['projected_monthly_sales_best_cement_m_t'] = Variable<double>(
        projectedMonthlySalesBestCementMT,
      );
    }
    if (!nullToAbsent || noOfEmployeesInSales != null) {
      map['no_of_employees_in_sales'] = Variable<int>(noOfEmployeesInSales);
    }
    if (!nullToAbsent || declarationName != null) {
      map['declaration_name'] = Variable<String>(declarationName);
    }
    if (!nullToAbsent || declarationPlace != null) {
      map['declaration_place'] = Variable<String>(declarationPlace);
    }
    if (!nullToAbsent || declarationDate != null) {
      map['declaration_date'] = Variable<DateTime>(declarationDate);
    }
    if (!nullToAbsent || tradeLicencePicUrl != null) {
      map['trade_licence_pic_url'] = Variable<String>(tradeLicencePicUrl);
    }
    if (!nullToAbsent || shopPicUrl != null) {
      map['shop_pic_url'] = Variable<String>(shopPicUrl);
    }
    if (!nullToAbsent || dealerPicUrl != null) {
      map['dealer_pic_url'] = Variable<String>(dealerPicUrl);
    }
    if (!nullToAbsent || blankChequePicUrl != null) {
      map['blank_cheque_pic_url'] = Variable<String>(blankChequePicUrl);
    }
    if (!nullToAbsent || partnershipDeedPicUrl != null) {
      map['partnership_deed_pic_url'] = Variable<String>(partnershipDeedPicUrl);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  LocalDealersCompanion toCompanion(bool nullToAbsent) {
    return LocalDealersCompanion(
      id: Value(id),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      type: Value(type),
      parentDealerId: parentDealerId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentDealerId),
      name: Value(name),
      region: Value(region),
      area: Value(area),
      phoneNo: Value(phoneNo),
      address: Value(address),
      pinCode: pinCode == null && nullToAbsent
          ? const Value.absent()
          : Value(pinCode),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      dateOfBirth: dateOfBirth == null && nullToAbsent
          ? const Value.absent()
          : Value(dateOfBirth),
      anniversaryDate: anniversaryDate == null && nullToAbsent
          ? const Value.absent()
          : Value(anniversaryDate),
      totalPotential: Value(totalPotential),
      bestPotential: Value(bestPotential),
      brandSelling: brandSelling == null && nullToAbsent
          ? const Value.absent()
          : Value(brandSelling),
      feedbacks: Value(feedbacks),
      remarks: remarks == null && nullToAbsent
          ? const Value.absent()
          : Value(remarks),
      dealerDevelopmentStatus: dealerDevelopmentStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(dealerDevelopmentStatus),
      dealerDevelopmentObstacle:
          dealerDevelopmentObstacle == null && nullToAbsent
          ? const Value.absent()
          : Value(dealerDevelopmentObstacle),
      salesGrowthPercentage: salesGrowthPercentage == null && nullToAbsent
          ? const Value.absent()
          : Value(salesGrowthPercentage),
      noOfPJP: noOfPJP == null && nullToAbsent
          ? const Value.absent()
          : Value(noOfPJP),
      verificationStatus: Value(verificationStatus),
      whatsappNo: whatsappNo == null && nullToAbsent
          ? const Value.absent()
          : Value(whatsappNo),
      emailId: emailId == null && nullToAbsent
          ? const Value.absent()
          : Value(emailId),
      businessType: businessType == null && nullToAbsent
          ? const Value.absent()
          : Value(businessType),
      nameOfFirm: nameOfFirm == null && nullToAbsent
          ? const Value.absent()
          : Value(nameOfFirm),
      underSalesPromoterName: underSalesPromoterName == null && nullToAbsent
          ? const Value.absent()
          : Value(underSalesPromoterName),
      gstinNo: gstinNo == null && nullToAbsent
          ? const Value.absent()
          : Value(gstinNo),
      panNo: panNo == null && nullToAbsent
          ? const Value.absent()
          : Value(panNo),
      tradeLicNo: tradeLicNo == null && nullToAbsent
          ? const Value.absent()
          : Value(tradeLicNo),
      aadharNo: aadharNo == null && nullToAbsent
          ? const Value.absent()
          : Value(aadharNo),
      godownSizeSqFt: godownSizeSqFt == null && nullToAbsent
          ? const Value.absent()
          : Value(godownSizeSqFt),
      godownCapacityMTBags: godownCapacityMTBags == null && nullToAbsent
          ? const Value.absent()
          : Value(godownCapacityMTBags),
      godownAddressLine: godownAddressLine == null && nullToAbsent
          ? const Value.absent()
          : Value(godownAddressLine),
      godownLandMark: godownLandMark == null && nullToAbsent
          ? const Value.absent()
          : Value(godownLandMark),
      godownDistrict: godownDistrict == null && nullToAbsent
          ? const Value.absent()
          : Value(godownDistrict),
      godownArea: godownArea == null && nullToAbsent
          ? const Value.absent()
          : Value(godownArea),
      godownRegion: godownRegion == null && nullToAbsent
          ? const Value.absent()
          : Value(godownRegion),
      godownPinCode: godownPinCode == null && nullToAbsent
          ? const Value.absent()
          : Value(godownPinCode),
      residentialAddressLine: residentialAddressLine == null && nullToAbsent
          ? const Value.absent()
          : Value(residentialAddressLine),
      residentialLandMark: residentialLandMark == null && nullToAbsent
          ? const Value.absent()
          : Value(residentialLandMark),
      residentialDistrict: residentialDistrict == null && nullToAbsent
          ? const Value.absent()
          : Value(residentialDistrict),
      residentialArea: residentialArea == null && nullToAbsent
          ? const Value.absent()
          : Value(residentialArea),
      residentialRegion: residentialRegion == null && nullToAbsent
          ? const Value.absent()
          : Value(residentialRegion),
      residentialPinCode: residentialPinCode == null && nullToAbsent
          ? const Value.absent()
          : Value(residentialPinCode),
      bankAccountName: bankAccountName == null && nullToAbsent
          ? const Value.absent()
          : Value(bankAccountName),
      bankName: bankName == null && nullToAbsent
          ? const Value.absent()
          : Value(bankName),
      bankBranchAddress: bankBranchAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(bankBranchAddress),
      bankAccountNumber: bankAccountNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(bankAccountNumber),
      bankIfscCode: bankIfscCode == null && nullToAbsent
          ? const Value.absent()
          : Value(bankIfscCode),
      brandName: brandName == null && nullToAbsent
          ? const Value.absent()
          : Value(brandName),
      monthlySaleMT: monthlySaleMT == null && nullToAbsent
          ? const Value.absent()
          : Value(monthlySaleMT),
      noOfDealers: noOfDealers == null && nullToAbsent
          ? const Value.absent()
          : Value(noOfDealers),
      areaCovered: areaCovered == null && nullToAbsent
          ? const Value.absent()
          : Value(areaCovered),
      projectedMonthlySalesBestCementMT:
          projectedMonthlySalesBestCementMT == null && nullToAbsent
          ? const Value.absent()
          : Value(projectedMonthlySalesBestCementMT),
      noOfEmployeesInSales: noOfEmployeesInSales == null && nullToAbsent
          ? const Value.absent()
          : Value(noOfEmployeesInSales),
      declarationName: declarationName == null && nullToAbsent
          ? const Value.absent()
          : Value(declarationName),
      declarationPlace: declarationPlace == null && nullToAbsent
          ? const Value.absent()
          : Value(declarationPlace),
      declarationDate: declarationDate == null && nullToAbsent
          ? const Value.absent()
          : Value(declarationDate),
      tradeLicencePicUrl: tradeLicencePicUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(tradeLicencePicUrl),
      shopPicUrl: shopPicUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(shopPicUrl),
      dealerPicUrl: dealerPicUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(dealerPicUrl),
      blankChequePicUrl: blankChequePicUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(blankChequePicUrl),
      partnershipDeedPicUrl: partnershipDeedPicUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(partnershipDeedPicUrl),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory LocalDealer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalDealer(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<int?>(json['userId']),
      type: serializer.fromJson<String>(json['type']),
      parentDealerId: serializer.fromJson<String?>(json['parentDealerId']),
      name: serializer.fromJson<String>(json['name']),
      region: serializer.fromJson<String>(json['region']),
      area: serializer.fromJson<String>(json['area']),
      phoneNo: serializer.fromJson<String>(json['phoneNo']),
      address: serializer.fromJson<String>(json['address']),
      pinCode: serializer.fromJson<String?>(json['pinCode']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      dateOfBirth: serializer.fromJson<DateTime?>(json['dateOfBirth']),
      anniversaryDate: serializer.fromJson<DateTime?>(json['anniversaryDate']),
      totalPotential: serializer.fromJson<double>(json['totalPotential']),
      bestPotential: serializer.fromJson<double>(json['bestPotential']),
      brandSelling: serializer.fromJson<String?>(json['brandSelling']),
      feedbacks: serializer.fromJson<String>(json['feedbacks']),
      remarks: serializer.fromJson<String?>(json['remarks']),
      dealerDevelopmentStatus: serializer.fromJson<String?>(
        json['dealerDevelopmentStatus'],
      ),
      dealerDevelopmentObstacle: serializer.fromJson<String?>(
        json['dealerDevelopmentObstacle'],
      ),
      salesGrowthPercentage: serializer.fromJson<double?>(
        json['salesGrowthPercentage'],
      ),
      noOfPJP: serializer.fromJson<int?>(json['noOfPJP']),
      verificationStatus: serializer.fromJson<String>(
        json['verificationStatus'],
      ),
      whatsappNo: serializer.fromJson<String?>(json['whatsappNo']),
      emailId: serializer.fromJson<String?>(json['emailId']),
      businessType: serializer.fromJson<String?>(json['businessType']),
      nameOfFirm: serializer.fromJson<String?>(json['nameOfFirm']),
      underSalesPromoterName: serializer.fromJson<String?>(
        json['underSalesPromoterName'],
      ),
      gstinNo: serializer.fromJson<String?>(json['gstinNo']),
      panNo: serializer.fromJson<String?>(json['panNo']),
      tradeLicNo: serializer.fromJson<String?>(json['tradeLicNo']),
      aadharNo: serializer.fromJson<String?>(json['aadharNo']),
      godownSizeSqFt: serializer.fromJson<int?>(json['godownSizeSqFt']),
      godownCapacityMTBags: serializer.fromJson<String?>(
        json['godownCapacityMTBags'],
      ),
      godownAddressLine: serializer.fromJson<String?>(
        json['godownAddressLine'],
      ),
      godownLandMark: serializer.fromJson<String?>(json['godownLandMark']),
      godownDistrict: serializer.fromJson<String?>(json['godownDistrict']),
      godownArea: serializer.fromJson<String?>(json['godownArea']),
      godownRegion: serializer.fromJson<String?>(json['godownRegion']),
      godownPinCode: serializer.fromJson<String?>(json['godownPinCode']),
      residentialAddressLine: serializer.fromJson<String?>(
        json['residentialAddressLine'],
      ),
      residentialLandMark: serializer.fromJson<String?>(
        json['residentialLandMark'],
      ),
      residentialDistrict: serializer.fromJson<String?>(
        json['residentialDistrict'],
      ),
      residentialArea: serializer.fromJson<String?>(json['residentialArea']),
      residentialRegion: serializer.fromJson<String?>(
        json['residentialRegion'],
      ),
      residentialPinCode: serializer.fromJson<String?>(
        json['residentialPinCode'],
      ),
      bankAccountName: serializer.fromJson<String?>(json['bankAccountName']),
      bankName: serializer.fromJson<String?>(json['bankName']),
      bankBranchAddress: serializer.fromJson<String?>(
        json['bankBranchAddress'],
      ),
      bankAccountNumber: serializer.fromJson<String?>(
        json['bankAccountNumber'],
      ),
      bankIfscCode: serializer.fromJson<String?>(json['bankIfscCode']),
      brandName: serializer.fromJson<String?>(json['brandName']),
      monthlySaleMT: serializer.fromJson<double?>(json['monthlySaleMT']),
      noOfDealers: serializer.fromJson<int?>(json['noOfDealers']),
      areaCovered: serializer.fromJson<String?>(json['areaCovered']),
      projectedMonthlySalesBestCementMT: serializer.fromJson<double?>(
        json['projectedMonthlySalesBestCementMT'],
      ),
      noOfEmployeesInSales: serializer.fromJson<int?>(
        json['noOfEmployeesInSales'],
      ),
      declarationName: serializer.fromJson<String?>(json['declarationName']),
      declarationPlace: serializer.fromJson<String?>(json['declarationPlace']),
      declarationDate: serializer.fromJson<DateTime?>(json['declarationDate']),
      tradeLicencePicUrl: serializer.fromJson<String?>(
        json['tradeLicencePicUrl'],
      ),
      shopPicUrl: serializer.fromJson<String?>(json['shopPicUrl']),
      dealerPicUrl: serializer.fromJson<String?>(json['dealerPicUrl']),
      blankChequePicUrl: serializer.fromJson<String?>(
        json['blankChequePicUrl'],
      ),
      partnershipDeedPicUrl: serializer.fromJson<String?>(
        json['partnershipDeedPicUrl'],
      ),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<int?>(userId),
      'type': serializer.toJson<String>(type),
      'parentDealerId': serializer.toJson<String?>(parentDealerId),
      'name': serializer.toJson<String>(name),
      'region': serializer.toJson<String>(region),
      'area': serializer.toJson<String>(area),
      'phoneNo': serializer.toJson<String>(phoneNo),
      'address': serializer.toJson<String>(address),
      'pinCode': serializer.toJson<String?>(pinCode),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'dateOfBirth': serializer.toJson<DateTime?>(dateOfBirth),
      'anniversaryDate': serializer.toJson<DateTime?>(anniversaryDate),
      'totalPotential': serializer.toJson<double>(totalPotential),
      'bestPotential': serializer.toJson<double>(bestPotential),
      'brandSelling': serializer.toJson<String?>(brandSelling),
      'feedbacks': serializer.toJson<String>(feedbacks),
      'remarks': serializer.toJson<String?>(remarks),
      'dealerDevelopmentStatus': serializer.toJson<String?>(
        dealerDevelopmentStatus,
      ),
      'dealerDevelopmentObstacle': serializer.toJson<String?>(
        dealerDevelopmentObstacle,
      ),
      'salesGrowthPercentage': serializer.toJson<double?>(
        salesGrowthPercentage,
      ),
      'noOfPJP': serializer.toJson<int?>(noOfPJP),
      'verificationStatus': serializer.toJson<String>(verificationStatus),
      'whatsappNo': serializer.toJson<String?>(whatsappNo),
      'emailId': serializer.toJson<String?>(emailId),
      'businessType': serializer.toJson<String?>(businessType),
      'nameOfFirm': serializer.toJson<String?>(nameOfFirm),
      'underSalesPromoterName': serializer.toJson<String?>(
        underSalesPromoterName,
      ),
      'gstinNo': serializer.toJson<String?>(gstinNo),
      'panNo': serializer.toJson<String?>(panNo),
      'tradeLicNo': serializer.toJson<String?>(tradeLicNo),
      'aadharNo': serializer.toJson<String?>(aadharNo),
      'godownSizeSqFt': serializer.toJson<int?>(godownSizeSqFt),
      'godownCapacityMTBags': serializer.toJson<String?>(godownCapacityMTBags),
      'godownAddressLine': serializer.toJson<String?>(godownAddressLine),
      'godownLandMark': serializer.toJson<String?>(godownLandMark),
      'godownDistrict': serializer.toJson<String?>(godownDistrict),
      'godownArea': serializer.toJson<String?>(godownArea),
      'godownRegion': serializer.toJson<String?>(godownRegion),
      'godownPinCode': serializer.toJson<String?>(godownPinCode),
      'residentialAddressLine': serializer.toJson<String?>(
        residentialAddressLine,
      ),
      'residentialLandMark': serializer.toJson<String?>(residentialLandMark),
      'residentialDistrict': serializer.toJson<String?>(residentialDistrict),
      'residentialArea': serializer.toJson<String?>(residentialArea),
      'residentialRegion': serializer.toJson<String?>(residentialRegion),
      'residentialPinCode': serializer.toJson<String?>(residentialPinCode),
      'bankAccountName': serializer.toJson<String?>(bankAccountName),
      'bankName': serializer.toJson<String?>(bankName),
      'bankBranchAddress': serializer.toJson<String?>(bankBranchAddress),
      'bankAccountNumber': serializer.toJson<String?>(bankAccountNumber),
      'bankIfscCode': serializer.toJson<String?>(bankIfscCode),
      'brandName': serializer.toJson<String?>(brandName),
      'monthlySaleMT': serializer.toJson<double?>(monthlySaleMT),
      'noOfDealers': serializer.toJson<int?>(noOfDealers),
      'areaCovered': serializer.toJson<String?>(areaCovered),
      'projectedMonthlySalesBestCementMT': serializer.toJson<double?>(
        projectedMonthlySalesBestCementMT,
      ),
      'noOfEmployeesInSales': serializer.toJson<int?>(noOfEmployeesInSales),
      'declarationName': serializer.toJson<String?>(declarationName),
      'declarationPlace': serializer.toJson<String?>(declarationPlace),
      'declarationDate': serializer.toJson<DateTime?>(declarationDate),
      'tradeLicencePicUrl': serializer.toJson<String?>(tradeLicencePicUrl),
      'shopPicUrl': serializer.toJson<String?>(shopPicUrl),
      'dealerPicUrl': serializer.toJson<String?>(dealerPicUrl),
      'blankChequePicUrl': serializer.toJson<String?>(blankChequePicUrl),
      'partnershipDeedPicUrl': serializer.toJson<String?>(
        partnershipDeedPicUrl,
      ),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  LocalDealer copyWith({
    String? id,
    Value<int?> userId = const Value.absent(),
    String? type,
    Value<String?> parentDealerId = const Value.absent(),
    String? name,
    String? region,
    String? area,
    String? phoneNo,
    String? address,
    Value<String?> pinCode = const Value.absent(),
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    Value<DateTime?> dateOfBirth = const Value.absent(),
    Value<DateTime?> anniversaryDate = const Value.absent(),
    double? totalPotential,
    double? bestPotential,
    Value<String?> brandSelling = const Value.absent(),
    String? feedbacks,
    Value<String?> remarks = const Value.absent(),
    Value<String?> dealerDevelopmentStatus = const Value.absent(),
    Value<String?> dealerDevelopmentObstacle = const Value.absent(),
    Value<double?> salesGrowthPercentage = const Value.absent(),
    Value<int?> noOfPJP = const Value.absent(),
    String? verificationStatus,
    Value<String?> whatsappNo = const Value.absent(),
    Value<String?> emailId = const Value.absent(),
    Value<String?> businessType = const Value.absent(),
    Value<String?> nameOfFirm = const Value.absent(),
    Value<String?> underSalesPromoterName = const Value.absent(),
    Value<String?> gstinNo = const Value.absent(),
    Value<String?> panNo = const Value.absent(),
    Value<String?> tradeLicNo = const Value.absent(),
    Value<String?> aadharNo = const Value.absent(),
    Value<int?> godownSizeSqFt = const Value.absent(),
    Value<String?> godownCapacityMTBags = const Value.absent(),
    Value<String?> godownAddressLine = const Value.absent(),
    Value<String?> godownLandMark = const Value.absent(),
    Value<String?> godownDistrict = const Value.absent(),
    Value<String?> godownArea = const Value.absent(),
    Value<String?> godownRegion = const Value.absent(),
    Value<String?> godownPinCode = const Value.absent(),
    Value<String?> residentialAddressLine = const Value.absent(),
    Value<String?> residentialLandMark = const Value.absent(),
    Value<String?> residentialDistrict = const Value.absent(),
    Value<String?> residentialArea = const Value.absent(),
    Value<String?> residentialRegion = const Value.absent(),
    Value<String?> residentialPinCode = const Value.absent(),
    Value<String?> bankAccountName = const Value.absent(),
    Value<String?> bankName = const Value.absent(),
    Value<String?> bankBranchAddress = const Value.absent(),
    Value<String?> bankAccountNumber = const Value.absent(),
    Value<String?> bankIfscCode = const Value.absent(),
    Value<String?> brandName = const Value.absent(),
    Value<double?> monthlySaleMT = const Value.absent(),
    Value<int?> noOfDealers = const Value.absent(),
    Value<String?> areaCovered = const Value.absent(),
    Value<double?> projectedMonthlySalesBestCementMT = const Value.absent(),
    Value<int?> noOfEmployeesInSales = const Value.absent(),
    Value<String?> declarationName = const Value.absent(),
    Value<String?> declarationPlace = const Value.absent(),
    Value<DateTime?> declarationDate = const Value.absent(),
    Value<String?> tradeLicencePicUrl = const Value.absent(),
    Value<String?> shopPicUrl = const Value.absent(),
    Value<String?> dealerPicUrl = const Value.absent(),
    Value<String?> blankChequePicUrl = const Value.absent(),
    Value<String?> partnershipDeedPicUrl = const Value.absent(),
    Value<DateTime?> createdAt = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => LocalDealer(
    id: id ?? this.id,
    userId: userId.present ? userId.value : this.userId,
    type: type ?? this.type,
    parentDealerId: parentDealerId.present
        ? parentDealerId.value
        : this.parentDealerId,
    name: name ?? this.name,
    region: region ?? this.region,
    area: area ?? this.area,
    phoneNo: phoneNo ?? this.phoneNo,
    address: address ?? this.address,
    pinCode: pinCode.present ? pinCode.value : this.pinCode,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    dateOfBirth: dateOfBirth.present ? dateOfBirth.value : this.dateOfBirth,
    anniversaryDate: anniversaryDate.present
        ? anniversaryDate.value
        : this.anniversaryDate,
    totalPotential: totalPotential ?? this.totalPotential,
    bestPotential: bestPotential ?? this.bestPotential,
    brandSelling: brandSelling.present ? brandSelling.value : this.brandSelling,
    feedbacks: feedbacks ?? this.feedbacks,
    remarks: remarks.present ? remarks.value : this.remarks,
    dealerDevelopmentStatus: dealerDevelopmentStatus.present
        ? dealerDevelopmentStatus.value
        : this.dealerDevelopmentStatus,
    dealerDevelopmentObstacle: dealerDevelopmentObstacle.present
        ? dealerDevelopmentObstacle.value
        : this.dealerDevelopmentObstacle,
    salesGrowthPercentage: salesGrowthPercentage.present
        ? salesGrowthPercentage.value
        : this.salesGrowthPercentage,
    noOfPJP: noOfPJP.present ? noOfPJP.value : this.noOfPJP,
    verificationStatus: verificationStatus ?? this.verificationStatus,
    whatsappNo: whatsappNo.present ? whatsappNo.value : this.whatsappNo,
    emailId: emailId.present ? emailId.value : this.emailId,
    businessType: businessType.present ? businessType.value : this.businessType,
    nameOfFirm: nameOfFirm.present ? nameOfFirm.value : this.nameOfFirm,
    underSalesPromoterName: underSalesPromoterName.present
        ? underSalesPromoterName.value
        : this.underSalesPromoterName,
    gstinNo: gstinNo.present ? gstinNo.value : this.gstinNo,
    panNo: panNo.present ? panNo.value : this.panNo,
    tradeLicNo: tradeLicNo.present ? tradeLicNo.value : this.tradeLicNo,
    aadharNo: aadharNo.present ? aadharNo.value : this.aadharNo,
    godownSizeSqFt: godownSizeSqFt.present
        ? godownSizeSqFt.value
        : this.godownSizeSqFt,
    godownCapacityMTBags: godownCapacityMTBags.present
        ? godownCapacityMTBags.value
        : this.godownCapacityMTBags,
    godownAddressLine: godownAddressLine.present
        ? godownAddressLine.value
        : this.godownAddressLine,
    godownLandMark: godownLandMark.present
        ? godownLandMark.value
        : this.godownLandMark,
    godownDistrict: godownDistrict.present
        ? godownDistrict.value
        : this.godownDistrict,
    godownArea: godownArea.present ? godownArea.value : this.godownArea,
    godownRegion: godownRegion.present ? godownRegion.value : this.godownRegion,
    godownPinCode: godownPinCode.present
        ? godownPinCode.value
        : this.godownPinCode,
    residentialAddressLine: residentialAddressLine.present
        ? residentialAddressLine.value
        : this.residentialAddressLine,
    residentialLandMark: residentialLandMark.present
        ? residentialLandMark.value
        : this.residentialLandMark,
    residentialDistrict: residentialDistrict.present
        ? residentialDistrict.value
        : this.residentialDistrict,
    residentialArea: residentialArea.present
        ? residentialArea.value
        : this.residentialArea,
    residentialRegion: residentialRegion.present
        ? residentialRegion.value
        : this.residentialRegion,
    residentialPinCode: residentialPinCode.present
        ? residentialPinCode.value
        : this.residentialPinCode,
    bankAccountName: bankAccountName.present
        ? bankAccountName.value
        : this.bankAccountName,
    bankName: bankName.present ? bankName.value : this.bankName,
    bankBranchAddress: bankBranchAddress.present
        ? bankBranchAddress.value
        : this.bankBranchAddress,
    bankAccountNumber: bankAccountNumber.present
        ? bankAccountNumber.value
        : this.bankAccountNumber,
    bankIfscCode: bankIfscCode.present ? bankIfscCode.value : this.bankIfscCode,
    brandName: brandName.present ? brandName.value : this.brandName,
    monthlySaleMT: monthlySaleMT.present
        ? monthlySaleMT.value
        : this.monthlySaleMT,
    noOfDealers: noOfDealers.present ? noOfDealers.value : this.noOfDealers,
    areaCovered: areaCovered.present ? areaCovered.value : this.areaCovered,
    projectedMonthlySalesBestCementMT: projectedMonthlySalesBestCementMT.present
        ? projectedMonthlySalesBestCementMT.value
        : this.projectedMonthlySalesBestCementMT,
    noOfEmployeesInSales: noOfEmployeesInSales.present
        ? noOfEmployeesInSales.value
        : this.noOfEmployeesInSales,
    declarationName: declarationName.present
        ? declarationName.value
        : this.declarationName,
    declarationPlace: declarationPlace.present
        ? declarationPlace.value
        : this.declarationPlace,
    declarationDate: declarationDate.present
        ? declarationDate.value
        : this.declarationDate,
    tradeLicencePicUrl: tradeLicencePicUrl.present
        ? tradeLicencePicUrl.value
        : this.tradeLicencePicUrl,
    shopPicUrl: shopPicUrl.present ? shopPicUrl.value : this.shopPicUrl,
    dealerPicUrl: dealerPicUrl.present ? dealerPicUrl.value : this.dealerPicUrl,
    blankChequePicUrl: blankChequePicUrl.present
        ? blankChequePicUrl.value
        : this.blankChequePicUrl,
    partnershipDeedPicUrl: partnershipDeedPicUrl.present
        ? partnershipDeedPicUrl.value
        : this.partnershipDeedPicUrl,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  LocalDealer copyWithCompanion(LocalDealersCompanion data) {
    return LocalDealer(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      type: data.type.present ? data.type.value : this.type,
      parentDealerId: data.parentDealerId.present
          ? data.parentDealerId.value
          : this.parentDealerId,
      name: data.name.present ? data.name.value : this.name,
      region: data.region.present ? data.region.value : this.region,
      area: data.area.present ? data.area.value : this.area,
      phoneNo: data.phoneNo.present ? data.phoneNo.value : this.phoneNo,
      address: data.address.present ? data.address.value : this.address,
      pinCode: data.pinCode.present ? data.pinCode.value : this.pinCode,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      dateOfBirth: data.dateOfBirth.present
          ? data.dateOfBirth.value
          : this.dateOfBirth,
      anniversaryDate: data.anniversaryDate.present
          ? data.anniversaryDate.value
          : this.anniversaryDate,
      totalPotential: data.totalPotential.present
          ? data.totalPotential.value
          : this.totalPotential,
      bestPotential: data.bestPotential.present
          ? data.bestPotential.value
          : this.bestPotential,
      brandSelling: data.brandSelling.present
          ? data.brandSelling.value
          : this.brandSelling,
      feedbacks: data.feedbacks.present ? data.feedbacks.value : this.feedbacks,
      remarks: data.remarks.present ? data.remarks.value : this.remarks,
      dealerDevelopmentStatus: data.dealerDevelopmentStatus.present
          ? data.dealerDevelopmentStatus.value
          : this.dealerDevelopmentStatus,
      dealerDevelopmentObstacle: data.dealerDevelopmentObstacle.present
          ? data.dealerDevelopmentObstacle.value
          : this.dealerDevelopmentObstacle,
      salesGrowthPercentage: data.salesGrowthPercentage.present
          ? data.salesGrowthPercentage.value
          : this.salesGrowthPercentage,
      noOfPJP: data.noOfPJP.present ? data.noOfPJP.value : this.noOfPJP,
      verificationStatus: data.verificationStatus.present
          ? data.verificationStatus.value
          : this.verificationStatus,
      whatsappNo: data.whatsappNo.present
          ? data.whatsappNo.value
          : this.whatsappNo,
      emailId: data.emailId.present ? data.emailId.value : this.emailId,
      businessType: data.businessType.present
          ? data.businessType.value
          : this.businessType,
      nameOfFirm: data.nameOfFirm.present
          ? data.nameOfFirm.value
          : this.nameOfFirm,
      underSalesPromoterName: data.underSalesPromoterName.present
          ? data.underSalesPromoterName.value
          : this.underSalesPromoterName,
      gstinNo: data.gstinNo.present ? data.gstinNo.value : this.gstinNo,
      panNo: data.panNo.present ? data.panNo.value : this.panNo,
      tradeLicNo: data.tradeLicNo.present
          ? data.tradeLicNo.value
          : this.tradeLicNo,
      aadharNo: data.aadharNo.present ? data.aadharNo.value : this.aadharNo,
      godownSizeSqFt: data.godownSizeSqFt.present
          ? data.godownSizeSqFt.value
          : this.godownSizeSqFt,
      godownCapacityMTBags: data.godownCapacityMTBags.present
          ? data.godownCapacityMTBags.value
          : this.godownCapacityMTBags,
      godownAddressLine: data.godownAddressLine.present
          ? data.godownAddressLine.value
          : this.godownAddressLine,
      godownLandMark: data.godownLandMark.present
          ? data.godownLandMark.value
          : this.godownLandMark,
      godownDistrict: data.godownDistrict.present
          ? data.godownDistrict.value
          : this.godownDistrict,
      godownArea: data.godownArea.present
          ? data.godownArea.value
          : this.godownArea,
      godownRegion: data.godownRegion.present
          ? data.godownRegion.value
          : this.godownRegion,
      godownPinCode: data.godownPinCode.present
          ? data.godownPinCode.value
          : this.godownPinCode,
      residentialAddressLine: data.residentialAddressLine.present
          ? data.residentialAddressLine.value
          : this.residentialAddressLine,
      residentialLandMark: data.residentialLandMark.present
          ? data.residentialLandMark.value
          : this.residentialLandMark,
      residentialDistrict: data.residentialDistrict.present
          ? data.residentialDistrict.value
          : this.residentialDistrict,
      residentialArea: data.residentialArea.present
          ? data.residentialArea.value
          : this.residentialArea,
      residentialRegion: data.residentialRegion.present
          ? data.residentialRegion.value
          : this.residentialRegion,
      residentialPinCode: data.residentialPinCode.present
          ? data.residentialPinCode.value
          : this.residentialPinCode,
      bankAccountName: data.bankAccountName.present
          ? data.bankAccountName.value
          : this.bankAccountName,
      bankName: data.bankName.present ? data.bankName.value : this.bankName,
      bankBranchAddress: data.bankBranchAddress.present
          ? data.bankBranchAddress.value
          : this.bankBranchAddress,
      bankAccountNumber: data.bankAccountNumber.present
          ? data.bankAccountNumber.value
          : this.bankAccountNumber,
      bankIfscCode: data.bankIfscCode.present
          ? data.bankIfscCode.value
          : this.bankIfscCode,
      brandName: data.brandName.present ? data.brandName.value : this.brandName,
      monthlySaleMT: data.monthlySaleMT.present
          ? data.monthlySaleMT.value
          : this.monthlySaleMT,
      noOfDealers: data.noOfDealers.present
          ? data.noOfDealers.value
          : this.noOfDealers,
      areaCovered: data.areaCovered.present
          ? data.areaCovered.value
          : this.areaCovered,
      projectedMonthlySalesBestCementMT:
          data.projectedMonthlySalesBestCementMT.present
          ? data.projectedMonthlySalesBestCementMT.value
          : this.projectedMonthlySalesBestCementMT,
      noOfEmployeesInSales: data.noOfEmployeesInSales.present
          ? data.noOfEmployeesInSales.value
          : this.noOfEmployeesInSales,
      declarationName: data.declarationName.present
          ? data.declarationName.value
          : this.declarationName,
      declarationPlace: data.declarationPlace.present
          ? data.declarationPlace.value
          : this.declarationPlace,
      declarationDate: data.declarationDate.present
          ? data.declarationDate.value
          : this.declarationDate,
      tradeLicencePicUrl: data.tradeLicencePicUrl.present
          ? data.tradeLicencePicUrl.value
          : this.tradeLicencePicUrl,
      shopPicUrl: data.shopPicUrl.present
          ? data.shopPicUrl.value
          : this.shopPicUrl,
      dealerPicUrl: data.dealerPicUrl.present
          ? data.dealerPicUrl.value
          : this.dealerPicUrl,
      blankChequePicUrl: data.blankChequePicUrl.present
          ? data.blankChequePicUrl.value
          : this.blankChequePicUrl,
      partnershipDeedPicUrl: data.partnershipDeedPicUrl.present
          ? data.partnershipDeedPicUrl.value
          : this.partnershipDeedPicUrl,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalDealer(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('type: $type, ')
          ..write('parentDealerId: $parentDealerId, ')
          ..write('name: $name, ')
          ..write('region: $region, ')
          ..write('area: $area, ')
          ..write('phoneNo: $phoneNo, ')
          ..write('address: $address, ')
          ..write('pinCode: $pinCode, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('dateOfBirth: $dateOfBirth, ')
          ..write('anniversaryDate: $anniversaryDate, ')
          ..write('totalPotential: $totalPotential, ')
          ..write('bestPotential: $bestPotential, ')
          ..write('brandSelling: $brandSelling, ')
          ..write('feedbacks: $feedbacks, ')
          ..write('remarks: $remarks, ')
          ..write('dealerDevelopmentStatus: $dealerDevelopmentStatus, ')
          ..write('dealerDevelopmentObstacle: $dealerDevelopmentObstacle, ')
          ..write('salesGrowthPercentage: $salesGrowthPercentage, ')
          ..write('noOfPJP: $noOfPJP, ')
          ..write('verificationStatus: $verificationStatus, ')
          ..write('whatsappNo: $whatsappNo, ')
          ..write('emailId: $emailId, ')
          ..write('businessType: $businessType, ')
          ..write('nameOfFirm: $nameOfFirm, ')
          ..write('underSalesPromoterName: $underSalesPromoterName, ')
          ..write('gstinNo: $gstinNo, ')
          ..write('panNo: $panNo, ')
          ..write('tradeLicNo: $tradeLicNo, ')
          ..write('aadharNo: $aadharNo, ')
          ..write('godownSizeSqFt: $godownSizeSqFt, ')
          ..write('godownCapacityMTBags: $godownCapacityMTBags, ')
          ..write('godownAddressLine: $godownAddressLine, ')
          ..write('godownLandMark: $godownLandMark, ')
          ..write('godownDistrict: $godownDistrict, ')
          ..write('godownArea: $godownArea, ')
          ..write('godownRegion: $godownRegion, ')
          ..write('godownPinCode: $godownPinCode, ')
          ..write('residentialAddressLine: $residentialAddressLine, ')
          ..write('residentialLandMark: $residentialLandMark, ')
          ..write('residentialDistrict: $residentialDistrict, ')
          ..write('residentialArea: $residentialArea, ')
          ..write('residentialRegion: $residentialRegion, ')
          ..write('residentialPinCode: $residentialPinCode, ')
          ..write('bankAccountName: $bankAccountName, ')
          ..write('bankName: $bankName, ')
          ..write('bankBranchAddress: $bankBranchAddress, ')
          ..write('bankAccountNumber: $bankAccountNumber, ')
          ..write('bankIfscCode: $bankIfscCode, ')
          ..write('brandName: $brandName, ')
          ..write('monthlySaleMT: $monthlySaleMT, ')
          ..write('noOfDealers: $noOfDealers, ')
          ..write('areaCovered: $areaCovered, ')
          ..write(
            'projectedMonthlySalesBestCementMT: $projectedMonthlySalesBestCementMT, ',
          )
          ..write('noOfEmployeesInSales: $noOfEmployeesInSales, ')
          ..write('declarationName: $declarationName, ')
          ..write('declarationPlace: $declarationPlace, ')
          ..write('declarationDate: $declarationDate, ')
          ..write('tradeLicencePicUrl: $tradeLicencePicUrl, ')
          ..write('shopPicUrl: $shopPicUrl, ')
          ..write('dealerPicUrl: $dealerPicUrl, ')
          ..write('blankChequePicUrl: $blankChequePicUrl, ')
          ..write('partnershipDeedPicUrl: $partnershipDeedPicUrl, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    userId,
    type,
    parentDealerId,
    name,
    region,
    area,
    phoneNo,
    address,
    pinCode,
    latitude,
    longitude,
    dateOfBirth,
    anniversaryDate,
    totalPotential,
    bestPotential,
    brandSelling,
    feedbacks,
    remarks,
    dealerDevelopmentStatus,
    dealerDevelopmentObstacle,
    salesGrowthPercentage,
    noOfPJP,
    verificationStatus,
    whatsappNo,
    emailId,
    businessType,
    nameOfFirm,
    underSalesPromoterName,
    gstinNo,
    panNo,
    tradeLicNo,
    aadharNo,
    godownSizeSqFt,
    godownCapacityMTBags,
    godownAddressLine,
    godownLandMark,
    godownDistrict,
    godownArea,
    godownRegion,
    godownPinCode,
    residentialAddressLine,
    residentialLandMark,
    residentialDistrict,
    residentialArea,
    residentialRegion,
    residentialPinCode,
    bankAccountName,
    bankName,
    bankBranchAddress,
    bankAccountNumber,
    bankIfscCode,
    brandName,
    monthlySaleMT,
    noOfDealers,
    areaCovered,
    projectedMonthlySalesBestCementMT,
    noOfEmployeesInSales,
    declarationName,
    declarationPlace,
    declarationDate,
    tradeLicencePicUrl,
    shopPicUrl,
    dealerPicUrl,
    blankChequePicUrl,
    partnershipDeedPicUrl,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalDealer &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.type == this.type &&
          other.parentDealerId == this.parentDealerId &&
          other.name == this.name &&
          other.region == this.region &&
          other.area == this.area &&
          other.phoneNo == this.phoneNo &&
          other.address == this.address &&
          other.pinCode == this.pinCode &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.dateOfBirth == this.dateOfBirth &&
          other.anniversaryDate == this.anniversaryDate &&
          other.totalPotential == this.totalPotential &&
          other.bestPotential == this.bestPotential &&
          other.brandSelling == this.brandSelling &&
          other.feedbacks == this.feedbacks &&
          other.remarks == this.remarks &&
          other.dealerDevelopmentStatus == this.dealerDevelopmentStatus &&
          other.dealerDevelopmentObstacle == this.dealerDevelopmentObstacle &&
          other.salesGrowthPercentage == this.salesGrowthPercentage &&
          other.noOfPJP == this.noOfPJP &&
          other.verificationStatus == this.verificationStatus &&
          other.whatsappNo == this.whatsappNo &&
          other.emailId == this.emailId &&
          other.businessType == this.businessType &&
          other.nameOfFirm == this.nameOfFirm &&
          other.underSalesPromoterName == this.underSalesPromoterName &&
          other.gstinNo == this.gstinNo &&
          other.panNo == this.panNo &&
          other.tradeLicNo == this.tradeLicNo &&
          other.aadharNo == this.aadharNo &&
          other.godownSizeSqFt == this.godownSizeSqFt &&
          other.godownCapacityMTBags == this.godownCapacityMTBags &&
          other.godownAddressLine == this.godownAddressLine &&
          other.godownLandMark == this.godownLandMark &&
          other.godownDistrict == this.godownDistrict &&
          other.godownArea == this.godownArea &&
          other.godownRegion == this.godownRegion &&
          other.godownPinCode == this.godownPinCode &&
          other.residentialAddressLine == this.residentialAddressLine &&
          other.residentialLandMark == this.residentialLandMark &&
          other.residentialDistrict == this.residentialDistrict &&
          other.residentialArea == this.residentialArea &&
          other.residentialRegion == this.residentialRegion &&
          other.residentialPinCode == this.residentialPinCode &&
          other.bankAccountName == this.bankAccountName &&
          other.bankName == this.bankName &&
          other.bankBranchAddress == this.bankBranchAddress &&
          other.bankAccountNumber == this.bankAccountNumber &&
          other.bankIfscCode == this.bankIfscCode &&
          other.brandName == this.brandName &&
          other.monthlySaleMT == this.monthlySaleMT &&
          other.noOfDealers == this.noOfDealers &&
          other.areaCovered == this.areaCovered &&
          other.projectedMonthlySalesBestCementMT ==
              this.projectedMonthlySalesBestCementMT &&
          other.noOfEmployeesInSales == this.noOfEmployeesInSales &&
          other.declarationName == this.declarationName &&
          other.declarationPlace == this.declarationPlace &&
          other.declarationDate == this.declarationDate &&
          other.tradeLicencePicUrl == this.tradeLicencePicUrl &&
          other.shopPicUrl == this.shopPicUrl &&
          other.dealerPicUrl == this.dealerPicUrl &&
          other.blankChequePicUrl == this.blankChequePicUrl &&
          other.partnershipDeedPicUrl == this.partnershipDeedPicUrl &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalDealersCompanion extends UpdateCompanion<LocalDealer> {
  final Value<String> id;
  final Value<int?> userId;
  final Value<String> type;
  final Value<String?> parentDealerId;
  final Value<String> name;
  final Value<String> region;
  final Value<String> area;
  final Value<String> phoneNo;
  final Value<String> address;
  final Value<String?> pinCode;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<DateTime?> dateOfBirth;
  final Value<DateTime?> anniversaryDate;
  final Value<double> totalPotential;
  final Value<double> bestPotential;
  final Value<String?> brandSelling;
  final Value<String> feedbacks;
  final Value<String?> remarks;
  final Value<String?> dealerDevelopmentStatus;
  final Value<String?> dealerDevelopmentObstacle;
  final Value<double?> salesGrowthPercentage;
  final Value<int?> noOfPJP;
  final Value<String> verificationStatus;
  final Value<String?> whatsappNo;
  final Value<String?> emailId;
  final Value<String?> businessType;
  final Value<String?> nameOfFirm;
  final Value<String?> underSalesPromoterName;
  final Value<String?> gstinNo;
  final Value<String?> panNo;
  final Value<String?> tradeLicNo;
  final Value<String?> aadharNo;
  final Value<int?> godownSizeSqFt;
  final Value<String?> godownCapacityMTBags;
  final Value<String?> godownAddressLine;
  final Value<String?> godownLandMark;
  final Value<String?> godownDistrict;
  final Value<String?> godownArea;
  final Value<String?> godownRegion;
  final Value<String?> godownPinCode;
  final Value<String?> residentialAddressLine;
  final Value<String?> residentialLandMark;
  final Value<String?> residentialDistrict;
  final Value<String?> residentialArea;
  final Value<String?> residentialRegion;
  final Value<String?> residentialPinCode;
  final Value<String?> bankAccountName;
  final Value<String?> bankName;
  final Value<String?> bankBranchAddress;
  final Value<String?> bankAccountNumber;
  final Value<String?> bankIfscCode;
  final Value<String?> brandName;
  final Value<double?> monthlySaleMT;
  final Value<int?> noOfDealers;
  final Value<String?> areaCovered;
  final Value<double?> projectedMonthlySalesBestCementMT;
  final Value<int?> noOfEmployeesInSales;
  final Value<String?> declarationName;
  final Value<String?> declarationPlace;
  final Value<DateTime?> declarationDate;
  final Value<String?> tradeLicencePicUrl;
  final Value<String?> shopPicUrl;
  final Value<String?> dealerPicUrl;
  final Value<String?> blankChequePicUrl;
  final Value<String?> partnershipDeedPicUrl;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const LocalDealersCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.type = const Value.absent(),
    this.parentDealerId = const Value.absent(),
    this.name = const Value.absent(),
    this.region = const Value.absent(),
    this.area = const Value.absent(),
    this.phoneNo = const Value.absent(),
    this.address = const Value.absent(),
    this.pinCode = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.dateOfBirth = const Value.absent(),
    this.anniversaryDate = const Value.absent(),
    this.totalPotential = const Value.absent(),
    this.bestPotential = const Value.absent(),
    this.brandSelling = const Value.absent(),
    this.feedbacks = const Value.absent(),
    this.remarks = const Value.absent(),
    this.dealerDevelopmentStatus = const Value.absent(),
    this.dealerDevelopmentObstacle = const Value.absent(),
    this.salesGrowthPercentage = const Value.absent(),
    this.noOfPJP = const Value.absent(),
    this.verificationStatus = const Value.absent(),
    this.whatsappNo = const Value.absent(),
    this.emailId = const Value.absent(),
    this.businessType = const Value.absent(),
    this.nameOfFirm = const Value.absent(),
    this.underSalesPromoterName = const Value.absent(),
    this.gstinNo = const Value.absent(),
    this.panNo = const Value.absent(),
    this.tradeLicNo = const Value.absent(),
    this.aadharNo = const Value.absent(),
    this.godownSizeSqFt = const Value.absent(),
    this.godownCapacityMTBags = const Value.absent(),
    this.godownAddressLine = const Value.absent(),
    this.godownLandMark = const Value.absent(),
    this.godownDistrict = const Value.absent(),
    this.godownArea = const Value.absent(),
    this.godownRegion = const Value.absent(),
    this.godownPinCode = const Value.absent(),
    this.residentialAddressLine = const Value.absent(),
    this.residentialLandMark = const Value.absent(),
    this.residentialDistrict = const Value.absent(),
    this.residentialArea = const Value.absent(),
    this.residentialRegion = const Value.absent(),
    this.residentialPinCode = const Value.absent(),
    this.bankAccountName = const Value.absent(),
    this.bankName = const Value.absent(),
    this.bankBranchAddress = const Value.absent(),
    this.bankAccountNumber = const Value.absent(),
    this.bankIfscCode = const Value.absent(),
    this.brandName = const Value.absent(),
    this.monthlySaleMT = const Value.absent(),
    this.noOfDealers = const Value.absent(),
    this.areaCovered = const Value.absent(),
    this.projectedMonthlySalesBestCementMT = const Value.absent(),
    this.noOfEmployeesInSales = const Value.absent(),
    this.declarationName = const Value.absent(),
    this.declarationPlace = const Value.absent(),
    this.declarationDate = const Value.absent(),
    this.tradeLicencePicUrl = const Value.absent(),
    this.shopPicUrl = const Value.absent(),
    this.dealerPicUrl = const Value.absent(),
    this.blankChequePicUrl = const Value.absent(),
    this.partnershipDeedPicUrl = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalDealersCompanion.insert({
    required String id,
    this.userId = const Value.absent(),
    this.type = const Value.absent(),
    this.parentDealerId = const Value.absent(),
    required String name,
    this.region = const Value.absent(),
    this.area = const Value.absent(),
    this.phoneNo = const Value.absent(),
    this.address = const Value.absent(),
    this.pinCode = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.dateOfBirth = const Value.absent(),
    this.anniversaryDate = const Value.absent(),
    this.totalPotential = const Value.absent(),
    this.bestPotential = const Value.absent(),
    this.brandSelling = const Value.absent(),
    this.feedbacks = const Value.absent(),
    this.remarks = const Value.absent(),
    this.dealerDevelopmentStatus = const Value.absent(),
    this.dealerDevelopmentObstacle = const Value.absent(),
    this.salesGrowthPercentage = const Value.absent(),
    this.noOfPJP = const Value.absent(),
    this.verificationStatus = const Value.absent(),
    this.whatsappNo = const Value.absent(),
    this.emailId = const Value.absent(),
    this.businessType = const Value.absent(),
    this.nameOfFirm = const Value.absent(),
    this.underSalesPromoterName = const Value.absent(),
    this.gstinNo = const Value.absent(),
    this.panNo = const Value.absent(),
    this.tradeLicNo = const Value.absent(),
    this.aadharNo = const Value.absent(),
    this.godownSizeSqFt = const Value.absent(),
    this.godownCapacityMTBags = const Value.absent(),
    this.godownAddressLine = const Value.absent(),
    this.godownLandMark = const Value.absent(),
    this.godownDistrict = const Value.absent(),
    this.godownArea = const Value.absent(),
    this.godownRegion = const Value.absent(),
    this.godownPinCode = const Value.absent(),
    this.residentialAddressLine = const Value.absent(),
    this.residentialLandMark = const Value.absent(),
    this.residentialDistrict = const Value.absent(),
    this.residentialArea = const Value.absent(),
    this.residentialRegion = const Value.absent(),
    this.residentialPinCode = const Value.absent(),
    this.bankAccountName = const Value.absent(),
    this.bankName = const Value.absent(),
    this.bankBranchAddress = const Value.absent(),
    this.bankAccountNumber = const Value.absent(),
    this.bankIfscCode = const Value.absent(),
    this.brandName = const Value.absent(),
    this.monthlySaleMT = const Value.absent(),
    this.noOfDealers = const Value.absent(),
    this.areaCovered = const Value.absent(),
    this.projectedMonthlySalesBestCementMT = const Value.absent(),
    this.noOfEmployeesInSales = const Value.absent(),
    this.declarationName = const Value.absent(),
    this.declarationPlace = const Value.absent(),
    this.declarationDate = const Value.absent(),
    this.tradeLicencePicUrl = const Value.absent(),
    this.shopPicUrl = const Value.absent(),
    this.dealerPicUrl = const Value.absent(),
    this.blankChequePicUrl = const Value.absent(),
    this.partnershipDeedPicUrl = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<LocalDealer> custom({
    Expression<String>? id,
    Expression<int>? userId,
    Expression<String>? type,
    Expression<String>? parentDealerId,
    Expression<String>? name,
    Expression<String>? region,
    Expression<String>? area,
    Expression<String>? phoneNo,
    Expression<String>? address,
    Expression<String>? pinCode,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<DateTime>? dateOfBirth,
    Expression<DateTime>? anniversaryDate,
    Expression<double>? totalPotential,
    Expression<double>? bestPotential,
    Expression<String>? brandSelling,
    Expression<String>? feedbacks,
    Expression<String>? remarks,
    Expression<String>? dealerDevelopmentStatus,
    Expression<String>? dealerDevelopmentObstacle,
    Expression<double>? salesGrowthPercentage,
    Expression<int>? noOfPJP,
    Expression<String>? verificationStatus,
    Expression<String>? whatsappNo,
    Expression<String>? emailId,
    Expression<String>? businessType,
    Expression<String>? nameOfFirm,
    Expression<String>? underSalesPromoterName,
    Expression<String>? gstinNo,
    Expression<String>? panNo,
    Expression<String>? tradeLicNo,
    Expression<String>? aadharNo,
    Expression<int>? godownSizeSqFt,
    Expression<String>? godownCapacityMTBags,
    Expression<String>? godownAddressLine,
    Expression<String>? godownLandMark,
    Expression<String>? godownDistrict,
    Expression<String>? godownArea,
    Expression<String>? godownRegion,
    Expression<String>? godownPinCode,
    Expression<String>? residentialAddressLine,
    Expression<String>? residentialLandMark,
    Expression<String>? residentialDistrict,
    Expression<String>? residentialArea,
    Expression<String>? residentialRegion,
    Expression<String>? residentialPinCode,
    Expression<String>? bankAccountName,
    Expression<String>? bankName,
    Expression<String>? bankBranchAddress,
    Expression<String>? bankAccountNumber,
    Expression<String>? bankIfscCode,
    Expression<String>? brandName,
    Expression<double>? monthlySaleMT,
    Expression<int>? noOfDealers,
    Expression<String>? areaCovered,
    Expression<double>? projectedMonthlySalesBestCementMT,
    Expression<int>? noOfEmployeesInSales,
    Expression<String>? declarationName,
    Expression<String>? declarationPlace,
    Expression<DateTime>? declarationDate,
    Expression<String>? tradeLicencePicUrl,
    Expression<String>? shopPicUrl,
    Expression<String>? dealerPicUrl,
    Expression<String>? blankChequePicUrl,
    Expression<String>? partnershipDeedPicUrl,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (type != null) 'type': type,
      if (parentDealerId != null) 'parent_dealer_id': parentDealerId,
      if (name != null) 'name': name,
      if (region != null) 'region': region,
      if (area != null) 'area': area,
      if (phoneNo != null) 'phone_no': phoneNo,
      if (address != null) 'address': address,
      if (pinCode != null) 'pin_code': pinCode,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
      if (anniversaryDate != null) 'anniversary_date': anniversaryDate,
      if (totalPotential != null) 'total_potential': totalPotential,
      if (bestPotential != null) 'best_potential': bestPotential,
      if (brandSelling != null) 'brand_selling': brandSelling,
      if (feedbacks != null) 'feedbacks': feedbacks,
      if (remarks != null) 'remarks': remarks,
      if (dealerDevelopmentStatus != null)
        'dealer_development_status': dealerDevelopmentStatus,
      if (dealerDevelopmentObstacle != null)
        'dealer_development_obstacle': dealerDevelopmentObstacle,
      if (salesGrowthPercentage != null)
        'sales_growth_percentage': salesGrowthPercentage,
      if (noOfPJP != null) 'no_of_p_j_p': noOfPJP,
      if (verificationStatus != null) 'verification_status': verificationStatus,
      if (whatsappNo != null) 'whatsapp_no': whatsappNo,
      if (emailId != null) 'email_id': emailId,
      if (businessType != null) 'business_type': businessType,
      if (nameOfFirm != null) 'name_of_firm': nameOfFirm,
      if (underSalesPromoterName != null)
        'under_sales_promoter_name': underSalesPromoterName,
      if (gstinNo != null) 'gstin_no': gstinNo,
      if (panNo != null) 'pan_no': panNo,
      if (tradeLicNo != null) 'trade_lic_no': tradeLicNo,
      if (aadharNo != null) 'aadhar_no': aadharNo,
      if (godownSizeSqFt != null) 'godown_size_sq_ft': godownSizeSqFt,
      if (godownCapacityMTBags != null)
        'godown_capacity_m_t_bags': godownCapacityMTBags,
      if (godownAddressLine != null) 'godown_address_line': godownAddressLine,
      if (godownLandMark != null) 'godown_land_mark': godownLandMark,
      if (godownDistrict != null) 'godown_district': godownDistrict,
      if (godownArea != null) 'godown_area': godownArea,
      if (godownRegion != null) 'godown_region': godownRegion,
      if (godownPinCode != null) 'godown_pin_code': godownPinCode,
      if (residentialAddressLine != null)
        'residential_address_line': residentialAddressLine,
      if (residentialLandMark != null)
        'residential_land_mark': residentialLandMark,
      if (residentialDistrict != null)
        'residential_district': residentialDistrict,
      if (residentialArea != null) 'residential_area': residentialArea,
      if (residentialRegion != null) 'residential_region': residentialRegion,
      if (residentialPinCode != null)
        'residential_pin_code': residentialPinCode,
      if (bankAccountName != null) 'bank_account_name': bankAccountName,
      if (bankName != null) 'bank_name': bankName,
      if (bankBranchAddress != null) 'bank_branch_address': bankBranchAddress,
      if (bankAccountNumber != null) 'bank_account_number': bankAccountNumber,
      if (bankIfscCode != null) 'bank_ifsc_code': bankIfscCode,
      if (brandName != null) 'brand_name': brandName,
      if (monthlySaleMT != null) 'monthly_sale_m_t': monthlySaleMT,
      if (noOfDealers != null) 'no_of_dealers': noOfDealers,
      if (areaCovered != null) 'area_covered': areaCovered,
      if (projectedMonthlySalesBestCementMT != null)
        'projected_monthly_sales_best_cement_m_t':
            projectedMonthlySalesBestCementMT,
      if (noOfEmployeesInSales != null)
        'no_of_employees_in_sales': noOfEmployeesInSales,
      if (declarationName != null) 'declaration_name': declarationName,
      if (declarationPlace != null) 'declaration_place': declarationPlace,
      if (declarationDate != null) 'declaration_date': declarationDate,
      if (tradeLicencePicUrl != null)
        'trade_licence_pic_url': tradeLicencePicUrl,
      if (shopPicUrl != null) 'shop_pic_url': shopPicUrl,
      if (dealerPicUrl != null) 'dealer_pic_url': dealerPicUrl,
      if (blankChequePicUrl != null) 'blank_cheque_pic_url': blankChequePicUrl,
      if (partnershipDeedPicUrl != null)
        'partnership_deed_pic_url': partnershipDeedPicUrl,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalDealersCompanion copyWith({
    Value<String>? id,
    Value<int?>? userId,
    Value<String>? type,
    Value<String?>? parentDealerId,
    Value<String>? name,
    Value<String>? region,
    Value<String>? area,
    Value<String>? phoneNo,
    Value<String>? address,
    Value<String?>? pinCode,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<DateTime?>? dateOfBirth,
    Value<DateTime?>? anniversaryDate,
    Value<double>? totalPotential,
    Value<double>? bestPotential,
    Value<String?>? brandSelling,
    Value<String>? feedbacks,
    Value<String?>? remarks,
    Value<String?>? dealerDevelopmentStatus,
    Value<String?>? dealerDevelopmentObstacle,
    Value<double?>? salesGrowthPercentage,
    Value<int?>? noOfPJP,
    Value<String>? verificationStatus,
    Value<String?>? whatsappNo,
    Value<String?>? emailId,
    Value<String?>? businessType,
    Value<String?>? nameOfFirm,
    Value<String?>? underSalesPromoterName,
    Value<String?>? gstinNo,
    Value<String?>? panNo,
    Value<String?>? tradeLicNo,
    Value<String?>? aadharNo,
    Value<int?>? godownSizeSqFt,
    Value<String?>? godownCapacityMTBags,
    Value<String?>? godownAddressLine,
    Value<String?>? godownLandMark,
    Value<String?>? godownDistrict,
    Value<String?>? godownArea,
    Value<String?>? godownRegion,
    Value<String?>? godownPinCode,
    Value<String?>? residentialAddressLine,
    Value<String?>? residentialLandMark,
    Value<String?>? residentialDistrict,
    Value<String?>? residentialArea,
    Value<String?>? residentialRegion,
    Value<String?>? residentialPinCode,
    Value<String?>? bankAccountName,
    Value<String?>? bankName,
    Value<String?>? bankBranchAddress,
    Value<String?>? bankAccountNumber,
    Value<String?>? bankIfscCode,
    Value<String?>? brandName,
    Value<double?>? monthlySaleMT,
    Value<int?>? noOfDealers,
    Value<String?>? areaCovered,
    Value<double?>? projectedMonthlySalesBestCementMT,
    Value<int?>? noOfEmployeesInSales,
    Value<String?>? declarationName,
    Value<String?>? declarationPlace,
    Value<DateTime?>? declarationDate,
    Value<String?>? tradeLicencePicUrl,
    Value<String?>? shopPicUrl,
    Value<String?>? dealerPicUrl,
    Value<String?>? blankChequePicUrl,
    Value<String?>? partnershipDeedPicUrl,
    Value<DateTime?>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalDealersCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      parentDealerId: parentDealerId ?? this.parentDealerId,
      name: name ?? this.name,
      region: region ?? this.region,
      area: area ?? this.area,
      phoneNo: phoneNo ?? this.phoneNo,
      address: address ?? this.address,
      pinCode: pinCode ?? this.pinCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      anniversaryDate: anniversaryDate ?? this.anniversaryDate,
      totalPotential: totalPotential ?? this.totalPotential,
      bestPotential: bestPotential ?? this.bestPotential,
      brandSelling: brandSelling ?? this.brandSelling,
      feedbacks: feedbacks ?? this.feedbacks,
      remarks: remarks ?? this.remarks,
      dealerDevelopmentStatus:
          dealerDevelopmentStatus ?? this.dealerDevelopmentStatus,
      dealerDevelopmentObstacle:
          dealerDevelopmentObstacle ?? this.dealerDevelopmentObstacle,
      salesGrowthPercentage:
          salesGrowthPercentage ?? this.salesGrowthPercentage,
      noOfPJP: noOfPJP ?? this.noOfPJP,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      whatsappNo: whatsappNo ?? this.whatsappNo,
      emailId: emailId ?? this.emailId,
      businessType: businessType ?? this.businessType,
      nameOfFirm: nameOfFirm ?? this.nameOfFirm,
      underSalesPromoterName:
          underSalesPromoterName ?? this.underSalesPromoterName,
      gstinNo: gstinNo ?? this.gstinNo,
      panNo: panNo ?? this.panNo,
      tradeLicNo: tradeLicNo ?? this.tradeLicNo,
      aadharNo: aadharNo ?? this.aadharNo,
      godownSizeSqFt: godownSizeSqFt ?? this.godownSizeSqFt,
      godownCapacityMTBags: godownCapacityMTBags ?? this.godownCapacityMTBags,
      godownAddressLine: godownAddressLine ?? this.godownAddressLine,
      godownLandMark: godownLandMark ?? this.godownLandMark,
      godownDistrict: godownDistrict ?? this.godownDistrict,
      godownArea: godownArea ?? this.godownArea,
      godownRegion: godownRegion ?? this.godownRegion,
      godownPinCode: godownPinCode ?? this.godownPinCode,
      residentialAddressLine:
          residentialAddressLine ?? this.residentialAddressLine,
      residentialLandMark: residentialLandMark ?? this.residentialLandMark,
      residentialDistrict: residentialDistrict ?? this.residentialDistrict,
      residentialArea: residentialArea ?? this.residentialArea,
      residentialRegion: residentialRegion ?? this.residentialRegion,
      residentialPinCode: residentialPinCode ?? this.residentialPinCode,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      bankName: bankName ?? this.bankName,
      bankBranchAddress: bankBranchAddress ?? this.bankBranchAddress,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankIfscCode: bankIfscCode ?? this.bankIfscCode,
      brandName: brandName ?? this.brandName,
      monthlySaleMT: monthlySaleMT ?? this.monthlySaleMT,
      noOfDealers: noOfDealers ?? this.noOfDealers,
      areaCovered: areaCovered ?? this.areaCovered,
      projectedMonthlySalesBestCementMT:
          projectedMonthlySalesBestCementMT ??
          this.projectedMonthlySalesBestCementMT,
      noOfEmployeesInSales: noOfEmployeesInSales ?? this.noOfEmployeesInSales,
      declarationName: declarationName ?? this.declarationName,
      declarationPlace: declarationPlace ?? this.declarationPlace,
      declarationDate: declarationDate ?? this.declarationDate,
      tradeLicencePicUrl: tradeLicencePicUrl ?? this.tradeLicencePicUrl,
      shopPicUrl: shopPicUrl ?? this.shopPicUrl,
      dealerPicUrl: dealerPicUrl ?? this.dealerPicUrl,
      blankChequePicUrl: blankChequePicUrl ?? this.blankChequePicUrl,
      partnershipDeedPicUrl:
          partnershipDeedPicUrl ?? this.partnershipDeedPicUrl,
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
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (parentDealerId.present) {
      map['parent_dealer_id'] = Variable<String>(parentDealerId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (region.present) {
      map['region'] = Variable<String>(region.value);
    }
    if (area.present) {
      map['area'] = Variable<String>(area.value);
    }
    if (phoneNo.present) {
      map['phone_no'] = Variable<String>(phoneNo.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (pinCode.present) {
      map['pin_code'] = Variable<String>(pinCode.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (dateOfBirth.present) {
      map['date_of_birth'] = Variable<DateTime>(dateOfBirth.value);
    }
    if (anniversaryDate.present) {
      map['anniversary_date'] = Variable<DateTime>(anniversaryDate.value);
    }
    if (totalPotential.present) {
      map['total_potential'] = Variable<double>(totalPotential.value);
    }
    if (bestPotential.present) {
      map['best_potential'] = Variable<double>(bestPotential.value);
    }
    if (brandSelling.present) {
      map['brand_selling'] = Variable<String>(brandSelling.value);
    }
    if (feedbacks.present) {
      map['feedbacks'] = Variable<String>(feedbacks.value);
    }
    if (remarks.present) {
      map['remarks'] = Variable<String>(remarks.value);
    }
    if (dealerDevelopmentStatus.present) {
      map['dealer_development_status'] = Variable<String>(
        dealerDevelopmentStatus.value,
      );
    }
    if (dealerDevelopmentObstacle.present) {
      map['dealer_development_obstacle'] = Variable<String>(
        dealerDevelopmentObstacle.value,
      );
    }
    if (salesGrowthPercentage.present) {
      map['sales_growth_percentage'] = Variable<double>(
        salesGrowthPercentage.value,
      );
    }
    if (noOfPJP.present) {
      map['no_of_p_j_p'] = Variable<int>(noOfPJP.value);
    }
    if (verificationStatus.present) {
      map['verification_status'] = Variable<String>(verificationStatus.value);
    }
    if (whatsappNo.present) {
      map['whatsapp_no'] = Variable<String>(whatsappNo.value);
    }
    if (emailId.present) {
      map['email_id'] = Variable<String>(emailId.value);
    }
    if (businessType.present) {
      map['business_type'] = Variable<String>(businessType.value);
    }
    if (nameOfFirm.present) {
      map['name_of_firm'] = Variable<String>(nameOfFirm.value);
    }
    if (underSalesPromoterName.present) {
      map['under_sales_promoter_name'] = Variable<String>(
        underSalesPromoterName.value,
      );
    }
    if (gstinNo.present) {
      map['gstin_no'] = Variable<String>(gstinNo.value);
    }
    if (panNo.present) {
      map['pan_no'] = Variable<String>(panNo.value);
    }
    if (tradeLicNo.present) {
      map['trade_lic_no'] = Variable<String>(tradeLicNo.value);
    }
    if (aadharNo.present) {
      map['aadhar_no'] = Variable<String>(aadharNo.value);
    }
    if (godownSizeSqFt.present) {
      map['godown_size_sq_ft'] = Variable<int>(godownSizeSqFt.value);
    }
    if (godownCapacityMTBags.present) {
      map['godown_capacity_m_t_bags'] = Variable<String>(
        godownCapacityMTBags.value,
      );
    }
    if (godownAddressLine.present) {
      map['godown_address_line'] = Variable<String>(godownAddressLine.value);
    }
    if (godownLandMark.present) {
      map['godown_land_mark'] = Variable<String>(godownLandMark.value);
    }
    if (godownDistrict.present) {
      map['godown_district'] = Variable<String>(godownDistrict.value);
    }
    if (godownArea.present) {
      map['godown_area'] = Variable<String>(godownArea.value);
    }
    if (godownRegion.present) {
      map['godown_region'] = Variable<String>(godownRegion.value);
    }
    if (godownPinCode.present) {
      map['godown_pin_code'] = Variable<String>(godownPinCode.value);
    }
    if (residentialAddressLine.present) {
      map['residential_address_line'] = Variable<String>(
        residentialAddressLine.value,
      );
    }
    if (residentialLandMark.present) {
      map['residential_land_mark'] = Variable<String>(
        residentialLandMark.value,
      );
    }
    if (residentialDistrict.present) {
      map['residential_district'] = Variable<String>(residentialDistrict.value);
    }
    if (residentialArea.present) {
      map['residential_area'] = Variable<String>(residentialArea.value);
    }
    if (residentialRegion.present) {
      map['residential_region'] = Variable<String>(residentialRegion.value);
    }
    if (residentialPinCode.present) {
      map['residential_pin_code'] = Variable<String>(residentialPinCode.value);
    }
    if (bankAccountName.present) {
      map['bank_account_name'] = Variable<String>(bankAccountName.value);
    }
    if (bankName.present) {
      map['bank_name'] = Variable<String>(bankName.value);
    }
    if (bankBranchAddress.present) {
      map['bank_branch_address'] = Variable<String>(bankBranchAddress.value);
    }
    if (bankAccountNumber.present) {
      map['bank_account_number'] = Variable<String>(bankAccountNumber.value);
    }
    if (bankIfscCode.present) {
      map['bank_ifsc_code'] = Variable<String>(bankIfscCode.value);
    }
    if (brandName.present) {
      map['brand_name'] = Variable<String>(brandName.value);
    }
    if (monthlySaleMT.present) {
      map['monthly_sale_m_t'] = Variable<double>(monthlySaleMT.value);
    }
    if (noOfDealers.present) {
      map['no_of_dealers'] = Variable<int>(noOfDealers.value);
    }
    if (areaCovered.present) {
      map['area_covered'] = Variable<String>(areaCovered.value);
    }
    if (projectedMonthlySalesBestCementMT.present) {
      map['projected_monthly_sales_best_cement_m_t'] = Variable<double>(
        projectedMonthlySalesBestCementMT.value,
      );
    }
    if (noOfEmployeesInSales.present) {
      map['no_of_employees_in_sales'] = Variable<int>(
        noOfEmployeesInSales.value,
      );
    }
    if (declarationName.present) {
      map['declaration_name'] = Variable<String>(declarationName.value);
    }
    if (declarationPlace.present) {
      map['declaration_place'] = Variable<String>(declarationPlace.value);
    }
    if (declarationDate.present) {
      map['declaration_date'] = Variable<DateTime>(declarationDate.value);
    }
    if (tradeLicencePicUrl.present) {
      map['trade_licence_pic_url'] = Variable<String>(tradeLicencePicUrl.value);
    }
    if (shopPicUrl.present) {
      map['shop_pic_url'] = Variable<String>(shopPicUrl.value);
    }
    if (dealerPicUrl.present) {
      map['dealer_pic_url'] = Variable<String>(dealerPicUrl.value);
    }
    if (blankChequePicUrl.present) {
      map['blank_cheque_pic_url'] = Variable<String>(blankChequePicUrl.value);
    }
    if (partnershipDeedPicUrl.present) {
      map['partnership_deed_pic_url'] = Variable<String>(
        partnershipDeedPicUrl.value,
      );
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
    return (StringBuffer('LocalDealersCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('type: $type, ')
          ..write('parentDealerId: $parentDealerId, ')
          ..write('name: $name, ')
          ..write('region: $region, ')
          ..write('area: $area, ')
          ..write('phoneNo: $phoneNo, ')
          ..write('address: $address, ')
          ..write('pinCode: $pinCode, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('dateOfBirth: $dateOfBirth, ')
          ..write('anniversaryDate: $anniversaryDate, ')
          ..write('totalPotential: $totalPotential, ')
          ..write('bestPotential: $bestPotential, ')
          ..write('brandSelling: $brandSelling, ')
          ..write('feedbacks: $feedbacks, ')
          ..write('remarks: $remarks, ')
          ..write('dealerDevelopmentStatus: $dealerDevelopmentStatus, ')
          ..write('dealerDevelopmentObstacle: $dealerDevelopmentObstacle, ')
          ..write('salesGrowthPercentage: $salesGrowthPercentage, ')
          ..write('noOfPJP: $noOfPJP, ')
          ..write('verificationStatus: $verificationStatus, ')
          ..write('whatsappNo: $whatsappNo, ')
          ..write('emailId: $emailId, ')
          ..write('businessType: $businessType, ')
          ..write('nameOfFirm: $nameOfFirm, ')
          ..write('underSalesPromoterName: $underSalesPromoterName, ')
          ..write('gstinNo: $gstinNo, ')
          ..write('panNo: $panNo, ')
          ..write('tradeLicNo: $tradeLicNo, ')
          ..write('aadharNo: $aadharNo, ')
          ..write('godownSizeSqFt: $godownSizeSqFt, ')
          ..write('godownCapacityMTBags: $godownCapacityMTBags, ')
          ..write('godownAddressLine: $godownAddressLine, ')
          ..write('godownLandMark: $godownLandMark, ')
          ..write('godownDistrict: $godownDistrict, ')
          ..write('godownArea: $godownArea, ')
          ..write('godownRegion: $godownRegion, ')
          ..write('godownPinCode: $godownPinCode, ')
          ..write('residentialAddressLine: $residentialAddressLine, ')
          ..write('residentialLandMark: $residentialLandMark, ')
          ..write('residentialDistrict: $residentialDistrict, ')
          ..write('residentialArea: $residentialArea, ')
          ..write('residentialRegion: $residentialRegion, ')
          ..write('residentialPinCode: $residentialPinCode, ')
          ..write('bankAccountName: $bankAccountName, ')
          ..write('bankName: $bankName, ')
          ..write('bankBranchAddress: $bankBranchAddress, ')
          ..write('bankAccountNumber: $bankAccountNumber, ')
          ..write('bankIfscCode: $bankIfscCode, ')
          ..write('brandName: $brandName, ')
          ..write('monthlySaleMT: $monthlySaleMT, ')
          ..write('noOfDealers: $noOfDealers, ')
          ..write('areaCovered: $areaCovered, ')
          ..write(
            'projectedMonthlySalesBestCementMT: $projectedMonthlySalesBestCementMT, ',
          )
          ..write('noOfEmployeesInSales: $noOfEmployeesInSales, ')
          ..write('declarationName: $declarationName, ')
          ..write('declarationPlace: $declarationPlace, ')
          ..write('declarationDate: $declarationDate, ')
          ..write('tradeLicencePicUrl: $tradeLicencePicUrl, ')
          ..write('shopPicUrl: $shopPicUrl, ')
          ..write('dealerPicUrl: $dealerPicUrl, ')
          ..write('blankChequePicUrl: $blankChequePicUrl, ')
          ..write('partnershipDeedPicUrl: $partnershipDeedPicUrl, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $JourneysTable journeys = $JourneysTable(this);
  late final $JourneyBreadcrumbsTable journeyBreadcrumbs =
      $JourneyBreadcrumbsTable(this);
  late final $JourneyOpsQueueTable journeyOpsQueue = $JourneyOpsQueueTable(
    this,
  );
  late final $LocalDailyVisitReportsTable localDailyVisitReports =
      $LocalDailyVisitReportsTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $LocalDealersTable localDealers = $LocalDealersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    journeys,
    journeyBreadcrumbs,
    journeyOpsQueue,
    localDailyVisitReports,
    syncQueue,
    localDealers,
  ];
}

typedef $$JourneysTableCreateCompanionBuilder =
    JourneysCompanion Function({
      required String id,
      required int userId,
      Value<String?> pjpId,
      Value<String?> taskId,
      Value<String?> dealerId,
      Value<int?> verifiedDealerId,
      Value<String> status,
      Value<String?> siteName,
      Value<double> totalDistance,
      required DateTime startTime,
      Value<DateTime?> endTime,
      Value<int> rowid,
    });
typedef $$JourneysTableUpdateCompanionBuilder =
    JourneysCompanion Function({
      Value<String> id,
      Value<int> userId,
      Value<String?> pjpId,
      Value<String?> taskId,
      Value<String?> dealerId,
      Value<int?> verifiedDealerId,
      Value<String> status,
      Value<String?> siteName,
      Value<double> totalDistance,
      Value<DateTime> startTime,
      Value<DateTime?> endTime,
      Value<int> rowid,
    });

final class $$JourneysTableReferences
    extends BaseReferences<_$AppDatabase, $JourneysTable, Journey> {
  $$JourneysTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$JourneyBreadcrumbsTable, List<JourneyBreadcrumb>>
  _journeyBreadcrumbsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.journeyBreadcrumbs,
        aliasName: $_aliasNameGenerator(
          db.journeys.id,
          db.journeyBreadcrumbs.journeyId,
        ),
      );

  $$JourneyBreadcrumbsTableProcessedTableManager get journeyBreadcrumbsRefs {
    final manager = $$JourneyBreadcrumbsTableTableManager(
      $_db,
      $_db.journeyBreadcrumbs,
    ).filter((f) => f.journeyId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _journeyBreadcrumbsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$JourneysTableFilterComposer
    extends Composer<_$AppDatabase, $JourneysTable> {
  $$JourneysTableFilterComposer({
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

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pjpId => $composableBuilder(
    column: $table.pjpId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dealerId => $composableBuilder(
    column: $table.dealerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get verifiedDealerId => $composableBuilder(
    column: $table.verifiedDealerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get siteName => $composableBuilder(
    column: $table.siteName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalDistance => $composableBuilder(
    column: $table.totalDistance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> journeyBreadcrumbsRefs(
    Expression<bool> Function($$JourneyBreadcrumbsTableFilterComposer f) f,
  ) {
    final $$JourneyBreadcrumbsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.journeyBreadcrumbs,
      getReferencedColumn: (t) => t.journeyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JourneyBreadcrumbsTableFilterComposer(
            $db: $db,
            $table: $db.journeyBreadcrumbs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$JourneysTableOrderingComposer
    extends Composer<_$AppDatabase, $JourneysTable> {
  $$JourneysTableOrderingComposer({
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

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pjpId => $composableBuilder(
    column: $table.pjpId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dealerId => $composableBuilder(
    column: $table.dealerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get verifiedDealerId => $composableBuilder(
    column: $table.verifiedDealerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get siteName => $composableBuilder(
    column: $table.siteName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalDistance => $composableBuilder(
    column: $table.totalDistance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JourneysTableAnnotationComposer
    extends Composer<_$AppDatabase, $JourneysTable> {
  $$JourneysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get pjpId =>
      $composableBuilder(column: $table.pjpId, builder: (column) => column);

  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<String> get dealerId =>
      $composableBuilder(column: $table.dealerId, builder: (column) => column);

  GeneratedColumn<int> get verifiedDealerId => $composableBuilder(
    column: $table.verifiedDealerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get siteName =>
      $composableBuilder(column: $table.siteName, builder: (column) => column);

  GeneratedColumn<double> get totalDistance => $composableBuilder(
    column: $table.totalDistance,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  Expression<T> journeyBreadcrumbsRefs<T extends Object>(
    Expression<T> Function($$JourneyBreadcrumbsTableAnnotationComposer a) f,
  ) {
    final $$JourneyBreadcrumbsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.journeyBreadcrumbs,
          getReferencedColumn: (t) => t.journeyId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$JourneyBreadcrumbsTableAnnotationComposer(
                $db: $db,
                $table: $db.journeyBreadcrumbs,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$JourneysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JourneysTable,
          Journey,
          $$JourneysTableFilterComposer,
          $$JourneysTableOrderingComposer,
          $$JourneysTableAnnotationComposer,
          $$JourneysTableCreateCompanionBuilder,
          $$JourneysTableUpdateCompanionBuilder,
          (Journey, $$JourneysTableReferences),
          Journey,
          PrefetchHooks Function({bool journeyBreadcrumbsRefs})
        > {
  $$JourneysTableTableManager(_$AppDatabase db, $JourneysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JourneysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JourneysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JourneysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<String?> pjpId = const Value.absent(),
                Value<String?> taskId = const Value.absent(),
                Value<String?> dealerId = const Value.absent(),
                Value<int?> verifiedDealerId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> siteName = const Value.absent(),
                Value<double> totalDistance = const Value.absent(),
                Value<DateTime> startTime = const Value.absent(),
                Value<DateTime?> endTime = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JourneysCompanion(
                id: id,
                userId: userId,
                pjpId: pjpId,
                taskId: taskId,
                dealerId: dealerId,
                verifiedDealerId: verifiedDealerId,
                status: status,
                siteName: siteName,
                totalDistance: totalDistance,
                startTime: startTime,
                endTime: endTime,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int userId,
                Value<String?> pjpId = const Value.absent(),
                Value<String?> taskId = const Value.absent(),
                Value<String?> dealerId = const Value.absent(),
                Value<int?> verifiedDealerId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> siteName = const Value.absent(),
                Value<double> totalDistance = const Value.absent(),
                required DateTime startTime,
                Value<DateTime?> endTime = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JourneysCompanion.insert(
                id: id,
                userId: userId,
                pjpId: pjpId,
                taskId: taskId,
                dealerId: dealerId,
                verifiedDealerId: verifiedDealerId,
                status: status,
                siteName: siteName,
                totalDistance: totalDistance,
                startTime: startTime,
                endTime: endTime,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$JourneysTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({journeyBreadcrumbsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (journeyBreadcrumbsRefs) db.journeyBreadcrumbs,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (journeyBreadcrumbsRefs)
                    await $_getPrefetchedData<
                      Journey,
                      $JourneysTable,
                      JourneyBreadcrumb
                    >(
                      currentTable: table,
                      referencedTable: $$JourneysTableReferences
                          ._journeyBreadcrumbsRefsTable(db),
                      managerFromTypedResult: (p0) => $$JourneysTableReferences(
                        db,
                        table,
                        p0,
                      ).journeyBreadcrumbsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.journeyId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$JourneysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JourneysTable,
      Journey,
      $$JourneysTableFilterComposer,
      $$JourneysTableOrderingComposer,
      $$JourneysTableAnnotationComposer,
      $$JourneysTableCreateCompanionBuilder,
      $$JourneysTableUpdateCompanionBuilder,
      (Journey, $$JourneysTableReferences),
      Journey,
      PrefetchHooks Function({bool journeyBreadcrumbsRefs})
    >;
typedef $$JourneyBreadcrumbsTableCreateCompanionBuilder =
    JourneyBreadcrumbsCompanion Function({
      required String id,
      required String journeyId,
      required double latitude,
      required double longitude,
      required String h3Index,
      Value<double> totalDistance,
      Value<double?> speed,
      Value<double?> heading,
      Value<double?> accuracy,
      required DateTime recordedAt,
      Value<int> rowid,
    });
typedef $$JourneyBreadcrumbsTableUpdateCompanionBuilder =
    JourneyBreadcrumbsCompanion Function({
      Value<String> id,
      Value<String> journeyId,
      Value<double> latitude,
      Value<double> longitude,
      Value<String> h3Index,
      Value<double> totalDistance,
      Value<double?> speed,
      Value<double?> heading,
      Value<double?> accuracy,
      Value<DateTime> recordedAt,
      Value<int> rowid,
    });

final class $$JourneyBreadcrumbsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $JourneyBreadcrumbsTable,
          JourneyBreadcrumb
        > {
  $$JourneyBreadcrumbsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $JourneysTable _journeyIdTable(_$AppDatabase db) =>
      db.journeys.createAlias(
        $_aliasNameGenerator(db.journeyBreadcrumbs.journeyId, db.journeys.id),
      );

  $$JourneysTableProcessedTableManager get journeyId {
    final $_column = $_itemColumn<String>('journey_id')!;

    final manager = $$JourneysTableTableManager(
      $_db,
      $_db.journeys,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_journeyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$JourneyBreadcrumbsTableFilterComposer
    extends Composer<_$AppDatabase, $JourneyBreadcrumbsTable> {
  $$JourneyBreadcrumbsTableFilterComposer({
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

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get h3Index => $composableBuilder(
    column: $table.h3Index,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalDistance => $composableBuilder(
    column: $table.totalDistance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get heading => $composableBuilder(
    column: $table.heading,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$JourneysTableFilterComposer get journeyId {
    final $$JourneysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.journeyId,
      referencedTable: $db.journeys,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JourneysTableFilterComposer(
            $db: $db,
            $table: $db.journeys,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JourneyBreadcrumbsTableOrderingComposer
    extends Composer<_$AppDatabase, $JourneyBreadcrumbsTable> {
  $$JourneyBreadcrumbsTableOrderingComposer({
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

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get h3Index => $composableBuilder(
    column: $table.h3Index,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalDistance => $composableBuilder(
    column: $table.totalDistance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get heading => $composableBuilder(
    column: $table.heading,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$JourneysTableOrderingComposer get journeyId {
    final $$JourneysTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.journeyId,
      referencedTable: $db.journeys,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JourneysTableOrderingComposer(
            $db: $db,
            $table: $db.journeys,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JourneyBreadcrumbsTableAnnotationComposer
    extends Composer<_$AppDatabase, $JourneyBreadcrumbsTable> {
  $$JourneyBreadcrumbsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get h3Index =>
      $composableBuilder(column: $table.h3Index, builder: (column) => column);

  GeneratedColumn<double> get totalDistance => $composableBuilder(
    column: $table.totalDistance,
    builder: (column) => column,
  );

  GeneratedColumn<double> get speed =>
      $composableBuilder(column: $table.speed, builder: (column) => column);

  GeneratedColumn<double> get heading =>
      $composableBuilder(column: $table.heading, builder: (column) => column);

  GeneratedColumn<double> get accuracy =>
      $composableBuilder(column: $table.accuracy, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  $$JourneysTableAnnotationComposer get journeyId {
    final $$JourneysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.journeyId,
      referencedTable: $db.journeys,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JourneysTableAnnotationComposer(
            $db: $db,
            $table: $db.journeys,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JourneyBreadcrumbsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JourneyBreadcrumbsTable,
          JourneyBreadcrumb,
          $$JourneyBreadcrumbsTableFilterComposer,
          $$JourneyBreadcrumbsTableOrderingComposer,
          $$JourneyBreadcrumbsTableAnnotationComposer,
          $$JourneyBreadcrumbsTableCreateCompanionBuilder,
          $$JourneyBreadcrumbsTableUpdateCompanionBuilder,
          (JourneyBreadcrumb, $$JourneyBreadcrumbsTableReferences),
          JourneyBreadcrumb,
          PrefetchHooks Function({bool journeyId})
        > {
  $$JourneyBreadcrumbsTableTableManager(
    _$AppDatabase db,
    $JourneyBreadcrumbsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JourneyBreadcrumbsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JourneyBreadcrumbsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JourneyBreadcrumbsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> journeyId = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<String> h3Index = const Value.absent(),
                Value<double> totalDistance = const Value.absent(),
                Value<double?> speed = const Value.absent(),
                Value<double?> heading = const Value.absent(),
                Value<double?> accuracy = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JourneyBreadcrumbsCompanion(
                id: id,
                journeyId: journeyId,
                latitude: latitude,
                longitude: longitude,
                h3Index: h3Index,
                totalDistance: totalDistance,
                speed: speed,
                heading: heading,
                accuracy: accuracy,
                recordedAt: recordedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String journeyId,
                required double latitude,
                required double longitude,
                required String h3Index,
                Value<double> totalDistance = const Value.absent(),
                Value<double?> speed = const Value.absent(),
                Value<double?> heading = const Value.absent(),
                Value<double?> accuracy = const Value.absent(),
                required DateTime recordedAt,
                Value<int> rowid = const Value.absent(),
              }) => JourneyBreadcrumbsCompanion.insert(
                id: id,
                journeyId: journeyId,
                latitude: latitude,
                longitude: longitude,
                h3Index: h3Index,
                totalDistance: totalDistance,
                speed: speed,
                heading: heading,
                accuracy: accuracy,
                recordedAt: recordedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$JourneyBreadcrumbsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({journeyId = false}) {
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
                    if (journeyId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.journeyId,
                                referencedTable:
                                    $$JourneyBreadcrumbsTableReferences
                                        ._journeyIdTable(db),
                                referencedColumn:
                                    $$JourneyBreadcrumbsTableReferences
                                        ._journeyIdTable(db)
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

typedef $$JourneyBreadcrumbsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JourneyBreadcrumbsTable,
      JourneyBreadcrumb,
      $$JourneyBreadcrumbsTableFilterComposer,
      $$JourneyBreadcrumbsTableOrderingComposer,
      $$JourneyBreadcrumbsTableAnnotationComposer,
      $$JourneyBreadcrumbsTableCreateCompanionBuilder,
      $$JourneyBreadcrumbsTableUpdateCompanionBuilder,
      (JourneyBreadcrumb, $$JourneyBreadcrumbsTableReferences),
      JourneyBreadcrumb,
      PrefetchHooks Function({bool journeyId})
    >;
typedef $$JourneyOpsQueueTableCreateCompanionBuilder =
    JourneyOpsQueueCompanion Function({
      required String opId,
      required String journeyId,
      required int userId,
      required String type,
      required String payload,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$JourneyOpsQueueTableUpdateCompanionBuilder =
    JourneyOpsQueueCompanion Function({
      Value<String> opId,
      Value<String> journeyId,
      Value<int> userId,
      Value<String> type,
      Value<String> payload,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$JourneyOpsQueueTableFilterComposer
    extends Composer<_$AppDatabase, $JourneyOpsQueueTable> {
  $$JourneyOpsQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get opId => $composableBuilder(
    column: $table.opId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get journeyId => $composableBuilder(
    column: $table.journeyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JourneyOpsQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $JourneyOpsQueueTable> {
  $$JourneyOpsQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get opId => $composableBuilder(
    column: $table.opId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get journeyId => $composableBuilder(
    column: $table.journeyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JourneyOpsQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $JourneyOpsQueueTable> {
  $$JourneyOpsQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get opId =>
      $composableBuilder(column: $table.opId, builder: (column) => column);

  GeneratedColumn<String> get journeyId =>
      $composableBuilder(column: $table.journeyId, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$JourneyOpsQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JourneyOpsQueueTable,
          JourneyOpsQueueData,
          $$JourneyOpsQueueTableFilterComposer,
          $$JourneyOpsQueueTableOrderingComposer,
          $$JourneyOpsQueueTableAnnotationComposer,
          $$JourneyOpsQueueTableCreateCompanionBuilder,
          $$JourneyOpsQueueTableUpdateCompanionBuilder,
          (
            JourneyOpsQueueData,
            BaseReferences<
              _$AppDatabase,
              $JourneyOpsQueueTable,
              JourneyOpsQueueData
            >,
          ),
          JourneyOpsQueueData,
          PrefetchHooks Function()
        > {
  $$JourneyOpsQueueTableTableManager(
    _$AppDatabase db,
    $JourneyOpsQueueTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JourneyOpsQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JourneyOpsQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JourneyOpsQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> opId = const Value.absent(),
                Value<String> journeyId = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JourneyOpsQueueCompanion(
                opId: opId,
                journeyId: journeyId,
                userId: userId,
                type: type,
                payload: payload,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String opId,
                required String journeyId,
                required int userId,
                required String type,
                required String payload,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => JourneyOpsQueueCompanion.insert(
                opId: opId,
                journeyId: journeyId,
                userId: userId,
                type: type,
                payload: payload,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JourneyOpsQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JourneyOpsQueueTable,
      JourneyOpsQueueData,
      $$JourneyOpsQueueTableFilterComposer,
      $$JourneyOpsQueueTableOrderingComposer,
      $$JourneyOpsQueueTableAnnotationComposer,
      $$JourneyOpsQueueTableCreateCompanionBuilder,
      $$JourneyOpsQueueTableUpdateCompanionBuilder,
      (
        JourneyOpsQueueData,
        BaseReferences<
          _$AppDatabase,
          $JourneyOpsQueueTable,
          JourneyOpsQueueData
        >,
      ),
      JourneyOpsQueueData,
      PrefetchHooks Function()
    >;
typedef $$LocalDailyVisitReportsTableCreateCompanionBuilder =
    LocalDailyVisitReportsCompanion Function({
      required String id,
      required int userId,
      Value<String?> dealerId,
      Value<String?> subDealerId,
      Value<DateTime?> reportDate,
      Value<String?> dealerType,
      Value<String?> location,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<String?> visitType,
      Value<double?> dealerTotalPotential,
      Value<double?> dealerBestPotential,
      Value<String?> brandSelling,
      Value<String?> contactPerson,
      Value<String?> contactPersonPhoneNo,
      Value<double?> todayOrderMt,
      Value<double?> todayCollectionRupees,
      Value<double?> overdueAmount,
      Value<String?> feedbacks,
      Value<String?> solutionBySalesperson,
      Value<String?> anyRemarks,
      Value<DateTime?> checkInTime,
      Value<DateTime?> checkOutTime,
      Value<String?> timeSpentinLoc,
      Value<String?> inTimeImageUrl,
      Value<String?> outTimeImageUrl,
      Value<String?> pjpId,
      Value<String?> dailyTaskId,
      Value<String?> customerType,
      Value<String?> partyType,
      Value<String?> nameOfParty,
      Value<String?> contactNoOfParty,
      Value<DateTime?> expectedActivationDate,
      Value<double?> currentDealerOutstandingAmt,
      Value<String?> idempotencyKey,
      Value<String> syncStatus,
      Value<int> rowid,
    });
typedef $$LocalDailyVisitReportsTableUpdateCompanionBuilder =
    LocalDailyVisitReportsCompanion Function({
      Value<String> id,
      Value<int> userId,
      Value<String?> dealerId,
      Value<String?> subDealerId,
      Value<DateTime?> reportDate,
      Value<String?> dealerType,
      Value<String?> location,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<String?> visitType,
      Value<double?> dealerTotalPotential,
      Value<double?> dealerBestPotential,
      Value<String?> brandSelling,
      Value<String?> contactPerson,
      Value<String?> contactPersonPhoneNo,
      Value<double?> todayOrderMt,
      Value<double?> todayCollectionRupees,
      Value<double?> overdueAmount,
      Value<String?> feedbacks,
      Value<String?> solutionBySalesperson,
      Value<String?> anyRemarks,
      Value<DateTime?> checkInTime,
      Value<DateTime?> checkOutTime,
      Value<String?> timeSpentinLoc,
      Value<String?> inTimeImageUrl,
      Value<String?> outTimeImageUrl,
      Value<String?> pjpId,
      Value<String?> dailyTaskId,
      Value<String?> customerType,
      Value<String?> partyType,
      Value<String?> nameOfParty,
      Value<String?> contactNoOfParty,
      Value<DateTime?> expectedActivationDate,
      Value<double?> currentDealerOutstandingAmt,
      Value<String?> idempotencyKey,
      Value<String> syncStatus,
      Value<int> rowid,
    });

class $$LocalDailyVisitReportsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalDailyVisitReportsTable> {
  $$LocalDailyVisitReportsTableFilterComposer({
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

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dealerId => $composableBuilder(
    column: $table.dealerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subDealerId => $composableBuilder(
    column: $table.subDealerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reportDate => $composableBuilder(
    column: $table.reportDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dealerType => $composableBuilder(
    column: $table.dealerType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visitType => $composableBuilder(
    column: $table.visitType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get dealerTotalPotential => $composableBuilder(
    column: $table.dealerTotalPotential,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get dealerBestPotential => $composableBuilder(
    column: $table.dealerBestPotential,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brandSelling => $composableBuilder(
    column: $table.brandSelling,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contactPerson => $composableBuilder(
    column: $table.contactPerson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contactPersonPhoneNo => $composableBuilder(
    column: $table.contactPersonPhoneNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get todayOrderMt => $composableBuilder(
    column: $table.todayOrderMt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get todayCollectionRupees => $composableBuilder(
    column: $table.todayCollectionRupees,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get overdueAmount => $composableBuilder(
    column: $table.overdueAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get feedbacks => $composableBuilder(
    column: $table.feedbacks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get solutionBySalesperson => $composableBuilder(
    column: $table.solutionBySalesperson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get anyRemarks => $composableBuilder(
    column: $table.anyRemarks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get checkInTime => $composableBuilder(
    column: $table.checkInTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get checkOutTime => $composableBuilder(
    column: $table.checkOutTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeSpentinLoc => $composableBuilder(
    column: $table.timeSpentinLoc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inTimeImageUrl => $composableBuilder(
    column: $table.inTimeImageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outTimeImageUrl => $composableBuilder(
    column: $table.outTimeImageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pjpId => $composableBuilder(
    column: $table.pjpId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dailyTaskId => $composableBuilder(
    column: $table.dailyTaskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerType => $composableBuilder(
    column: $table.customerType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partyType => $composableBuilder(
    column: $table.partyType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameOfParty => $composableBuilder(
    column: $table.nameOfParty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contactNoOfParty => $composableBuilder(
    column: $table.contactNoOfParty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expectedActivationDate => $composableBuilder(
    column: $table.expectedActivationDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get currentDealerOutstandingAmt => $composableBuilder(
    column: $table.currentDealerOutstandingAmt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalDailyVisitReportsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalDailyVisitReportsTable> {
  $$LocalDailyVisitReportsTableOrderingComposer({
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

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dealerId => $composableBuilder(
    column: $table.dealerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subDealerId => $composableBuilder(
    column: $table.subDealerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reportDate => $composableBuilder(
    column: $table.reportDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dealerType => $composableBuilder(
    column: $table.dealerType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visitType => $composableBuilder(
    column: $table.visitType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get dealerTotalPotential => $composableBuilder(
    column: $table.dealerTotalPotential,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get dealerBestPotential => $composableBuilder(
    column: $table.dealerBestPotential,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brandSelling => $composableBuilder(
    column: $table.brandSelling,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contactPerson => $composableBuilder(
    column: $table.contactPerson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contactPersonPhoneNo => $composableBuilder(
    column: $table.contactPersonPhoneNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get todayOrderMt => $composableBuilder(
    column: $table.todayOrderMt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get todayCollectionRupees => $composableBuilder(
    column: $table.todayCollectionRupees,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get overdueAmount => $composableBuilder(
    column: $table.overdueAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get feedbacks => $composableBuilder(
    column: $table.feedbacks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get solutionBySalesperson => $composableBuilder(
    column: $table.solutionBySalesperson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get anyRemarks => $composableBuilder(
    column: $table.anyRemarks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get checkInTime => $composableBuilder(
    column: $table.checkInTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get checkOutTime => $composableBuilder(
    column: $table.checkOutTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeSpentinLoc => $composableBuilder(
    column: $table.timeSpentinLoc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inTimeImageUrl => $composableBuilder(
    column: $table.inTimeImageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outTimeImageUrl => $composableBuilder(
    column: $table.outTimeImageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pjpId => $composableBuilder(
    column: $table.pjpId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dailyTaskId => $composableBuilder(
    column: $table.dailyTaskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerType => $composableBuilder(
    column: $table.customerType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partyType => $composableBuilder(
    column: $table.partyType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameOfParty => $composableBuilder(
    column: $table.nameOfParty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contactNoOfParty => $composableBuilder(
    column: $table.contactNoOfParty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expectedActivationDate => $composableBuilder(
    column: $table.expectedActivationDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get currentDealerOutstandingAmt => $composableBuilder(
    column: $table.currentDealerOutstandingAmt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalDailyVisitReportsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalDailyVisitReportsTable> {
  $$LocalDailyVisitReportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get dealerId =>
      $composableBuilder(column: $table.dealerId, builder: (column) => column);

  GeneratedColumn<String> get subDealerId => $composableBuilder(
    column: $table.subDealerId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get reportDate => $composableBuilder(
    column: $table.reportDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dealerType => $composableBuilder(
    column: $table.dealerType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get visitType =>
      $composableBuilder(column: $table.visitType, builder: (column) => column);

  GeneratedColumn<double> get dealerTotalPotential => $composableBuilder(
    column: $table.dealerTotalPotential,
    builder: (column) => column,
  );

  GeneratedColumn<double> get dealerBestPotential => $composableBuilder(
    column: $table.dealerBestPotential,
    builder: (column) => column,
  );

  GeneratedColumn<String> get brandSelling => $composableBuilder(
    column: $table.brandSelling,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contactPerson => $composableBuilder(
    column: $table.contactPerson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contactPersonPhoneNo => $composableBuilder(
    column: $table.contactPersonPhoneNo,
    builder: (column) => column,
  );

  GeneratedColumn<double> get todayOrderMt => $composableBuilder(
    column: $table.todayOrderMt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get todayCollectionRupees => $composableBuilder(
    column: $table.todayCollectionRupees,
    builder: (column) => column,
  );

  GeneratedColumn<double> get overdueAmount => $composableBuilder(
    column: $table.overdueAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get feedbacks =>
      $composableBuilder(column: $table.feedbacks, builder: (column) => column);

  GeneratedColumn<String> get solutionBySalesperson => $composableBuilder(
    column: $table.solutionBySalesperson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get anyRemarks => $composableBuilder(
    column: $table.anyRemarks,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get checkInTime => $composableBuilder(
    column: $table.checkInTime,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get checkOutTime => $composableBuilder(
    column: $table.checkOutTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timeSpentinLoc => $composableBuilder(
    column: $table.timeSpentinLoc,
    builder: (column) => column,
  );

  GeneratedColumn<String> get inTimeImageUrl => $composableBuilder(
    column: $table.inTimeImageUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get outTimeImageUrl => $composableBuilder(
    column: $table.outTimeImageUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pjpId =>
      $composableBuilder(column: $table.pjpId, builder: (column) => column);

  GeneratedColumn<String> get dailyTaskId => $composableBuilder(
    column: $table.dailyTaskId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerType => $composableBuilder(
    column: $table.customerType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get partyType =>
      $composableBuilder(column: $table.partyType, builder: (column) => column);

  GeneratedColumn<String> get nameOfParty => $composableBuilder(
    column: $table.nameOfParty,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contactNoOfParty => $composableBuilder(
    column: $table.contactNoOfParty,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get expectedActivationDate => $composableBuilder(
    column: $table.expectedActivationDate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get currentDealerOutstandingAmt => $composableBuilder(
    column: $table.currentDealerOutstandingAmt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$LocalDailyVisitReportsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalDailyVisitReportsTable,
          LocalDailyVisitReport,
          $$LocalDailyVisitReportsTableFilterComposer,
          $$LocalDailyVisitReportsTableOrderingComposer,
          $$LocalDailyVisitReportsTableAnnotationComposer,
          $$LocalDailyVisitReportsTableCreateCompanionBuilder,
          $$LocalDailyVisitReportsTableUpdateCompanionBuilder,
          (
            LocalDailyVisitReport,
            BaseReferences<
              _$AppDatabase,
              $LocalDailyVisitReportsTable,
              LocalDailyVisitReport
            >,
          ),
          LocalDailyVisitReport,
          PrefetchHooks Function()
        > {
  $$LocalDailyVisitReportsTableTableManager(
    _$AppDatabase db,
    $LocalDailyVisitReportsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalDailyVisitReportsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalDailyVisitReportsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalDailyVisitReportsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<String?> dealerId = const Value.absent(),
                Value<String?> subDealerId = const Value.absent(),
                Value<DateTime?> reportDate = const Value.absent(),
                Value<String?> dealerType = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<String?> visitType = const Value.absent(),
                Value<double?> dealerTotalPotential = const Value.absent(),
                Value<double?> dealerBestPotential = const Value.absent(),
                Value<String?> brandSelling = const Value.absent(),
                Value<String?> contactPerson = const Value.absent(),
                Value<String?> contactPersonPhoneNo = const Value.absent(),
                Value<double?> todayOrderMt = const Value.absent(),
                Value<double?> todayCollectionRupees = const Value.absent(),
                Value<double?> overdueAmount = const Value.absent(),
                Value<String?> feedbacks = const Value.absent(),
                Value<String?> solutionBySalesperson = const Value.absent(),
                Value<String?> anyRemarks = const Value.absent(),
                Value<DateTime?> checkInTime = const Value.absent(),
                Value<DateTime?> checkOutTime = const Value.absent(),
                Value<String?> timeSpentinLoc = const Value.absent(),
                Value<String?> inTimeImageUrl = const Value.absent(),
                Value<String?> outTimeImageUrl = const Value.absent(),
                Value<String?> pjpId = const Value.absent(),
                Value<String?> dailyTaskId = const Value.absent(),
                Value<String?> customerType = const Value.absent(),
                Value<String?> partyType = const Value.absent(),
                Value<String?> nameOfParty = const Value.absent(),
                Value<String?> contactNoOfParty = const Value.absent(),
                Value<DateTime?> expectedActivationDate = const Value.absent(),
                Value<double?> currentDealerOutstandingAmt =
                    const Value.absent(),
                Value<String?> idempotencyKey = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalDailyVisitReportsCompanion(
                id: id,
                userId: userId,
                dealerId: dealerId,
                subDealerId: subDealerId,
                reportDate: reportDate,
                dealerType: dealerType,
                location: location,
                latitude: latitude,
                longitude: longitude,
                visitType: visitType,
                dealerTotalPotential: dealerTotalPotential,
                dealerBestPotential: dealerBestPotential,
                brandSelling: brandSelling,
                contactPerson: contactPerson,
                contactPersonPhoneNo: contactPersonPhoneNo,
                todayOrderMt: todayOrderMt,
                todayCollectionRupees: todayCollectionRupees,
                overdueAmount: overdueAmount,
                feedbacks: feedbacks,
                solutionBySalesperson: solutionBySalesperson,
                anyRemarks: anyRemarks,
                checkInTime: checkInTime,
                checkOutTime: checkOutTime,
                timeSpentinLoc: timeSpentinLoc,
                inTimeImageUrl: inTimeImageUrl,
                outTimeImageUrl: outTimeImageUrl,
                pjpId: pjpId,
                dailyTaskId: dailyTaskId,
                customerType: customerType,
                partyType: partyType,
                nameOfParty: nameOfParty,
                contactNoOfParty: contactNoOfParty,
                expectedActivationDate: expectedActivationDate,
                currentDealerOutstandingAmt: currentDealerOutstandingAmt,
                idempotencyKey: idempotencyKey,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int userId,
                Value<String?> dealerId = const Value.absent(),
                Value<String?> subDealerId = const Value.absent(),
                Value<DateTime?> reportDate = const Value.absent(),
                Value<String?> dealerType = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<String?> visitType = const Value.absent(),
                Value<double?> dealerTotalPotential = const Value.absent(),
                Value<double?> dealerBestPotential = const Value.absent(),
                Value<String?> brandSelling = const Value.absent(),
                Value<String?> contactPerson = const Value.absent(),
                Value<String?> contactPersonPhoneNo = const Value.absent(),
                Value<double?> todayOrderMt = const Value.absent(),
                Value<double?> todayCollectionRupees = const Value.absent(),
                Value<double?> overdueAmount = const Value.absent(),
                Value<String?> feedbacks = const Value.absent(),
                Value<String?> solutionBySalesperson = const Value.absent(),
                Value<String?> anyRemarks = const Value.absent(),
                Value<DateTime?> checkInTime = const Value.absent(),
                Value<DateTime?> checkOutTime = const Value.absent(),
                Value<String?> timeSpentinLoc = const Value.absent(),
                Value<String?> inTimeImageUrl = const Value.absent(),
                Value<String?> outTimeImageUrl = const Value.absent(),
                Value<String?> pjpId = const Value.absent(),
                Value<String?> dailyTaskId = const Value.absent(),
                Value<String?> customerType = const Value.absent(),
                Value<String?> partyType = const Value.absent(),
                Value<String?> nameOfParty = const Value.absent(),
                Value<String?> contactNoOfParty = const Value.absent(),
                Value<DateTime?> expectedActivationDate = const Value.absent(),
                Value<double?> currentDealerOutstandingAmt =
                    const Value.absent(),
                Value<String?> idempotencyKey = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalDailyVisitReportsCompanion.insert(
                id: id,
                userId: userId,
                dealerId: dealerId,
                subDealerId: subDealerId,
                reportDate: reportDate,
                dealerType: dealerType,
                location: location,
                latitude: latitude,
                longitude: longitude,
                visitType: visitType,
                dealerTotalPotential: dealerTotalPotential,
                dealerBestPotential: dealerBestPotential,
                brandSelling: brandSelling,
                contactPerson: contactPerson,
                contactPersonPhoneNo: contactPersonPhoneNo,
                todayOrderMt: todayOrderMt,
                todayCollectionRupees: todayCollectionRupees,
                overdueAmount: overdueAmount,
                feedbacks: feedbacks,
                solutionBySalesperson: solutionBySalesperson,
                anyRemarks: anyRemarks,
                checkInTime: checkInTime,
                checkOutTime: checkOutTime,
                timeSpentinLoc: timeSpentinLoc,
                inTimeImageUrl: inTimeImageUrl,
                outTimeImageUrl: outTimeImageUrl,
                pjpId: pjpId,
                dailyTaskId: dailyTaskId,
                customerType: customerType,
                partyType: partyType,
                nameOfParty: nameOfParty,
                contactNoOfParty: contactNoOfParty,
                expectedActivationDate: expectedActivationDate,
                currentDealerOutstandingAmt: currentDealerOutstandingAmt,
                idempotencyKey: idempotencyKey,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalDailyVisitReportsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalDailyVisitReportsTable,
      LocalDailyVisitReport,
      $$LocalDailyVisitReportsTableFilterComposer,
      $$LocalDailyVisitReportsTableOrderingComposer,
      $$LocalDailyVisitReportsTableAnnotationComposer,
      $$LocalDailyVisitReportsTableCreateCompanionBuilder,
      $$LocalDailyVisitReportsTableUpdateCompanionBuilder,
      (
        LocalDailyVisitReport,
        BaseReferences<
          _$AppDatabase,
          $LocalDailyVisitReportsTable,
          LocalDailyVisitReport
        >,
      ),
      LocalDailyVisitReport,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueTableCreateCompanionBuilder =
    SyncQueueCompanion Function({
      required String id,
      required String entityType,
      required String payload,
      Value<String?> localFiles,
      Value<String> status,
      Value<int> retryCount,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$SyncQueueTableUpdateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<String> id,
      Value<String> entityType,
      Value<String> payload,
      Value<String?> localFiles,
      Value<String> status,
      Value<int> retryCount,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
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

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localFiles => $composableBuilder(
    column: $table.localFiles,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
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

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localFiles => $composableBuilder(
    column: $table.localFiles,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get localFiles => $composableBuilder(
    column: $table.localFiles,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTable,
          SyncQueueData,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (
            SyncQueueData,
            BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
          ),
          SyncQueueData,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String?> localFiles = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueCompanion(
                id: id,
                entityType: entityType,
                payload: payload,
                localFiles: localFiles,
                status: status,
                retryCount: retryCount,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entityType,
                required String payload,
                Value<String?> localFiles = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueCompanion.insert(
                id: id,
                entityType: entityType,
                payload: payload,
                localFiles: localFiles,
                status: status,
                retryCount: retryCount,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTable,
      SyncQueueData,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (
        SyncQueueData,
        BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
      ),
      SyncQueueData,
      PrefetchHooks Function()
    >;
typedef $$LocalDealersTableCreateCompanionBuilder =
    LocalDealersCompanion Function({
      required String id,
      Value<int?> userId,
      Value<String> type,
      Value<String?> parentDealerId,
      required String name,
      Value<String> region,
      Value<String> area,
      Value<String> phoneNo,
      Value<String> address,
      Value<String?> pinCode,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<DateTime?> dateOfBirth,
      Value<DateTime?> anniversaryDate,
      Value<double> totalPotential,
      Value<double> bestPotential,
      Value<String?> brandSelling,
      Value<String> feedbacks,
      Value<String?> remarks,
      Value<String?> dealerDevelopmentStatus,
      Value<String?> dealerDevelopmentObstacle,
      Value<double?> salesGrowthPercentage,
      Value<int?> noOfPJP,
      Value<String> verificationStatus,
      Value<String?> whatsappNo,
      Value<String?> emailId,
      Value<String?> businessType,
      Value<String?> nameOfFirm,
      Value<String?> underSalesPromoterName,
      Value<String?> gstinNo,
      Value<String?> panNo,
      Value<String?> tradeLicNo,
      Value<String?> aadharNo,
      Value<int?> godownSizeSqFt,
      Value<String?> godownCapacityMTBags,
      Value<String?> godownAddressLine,
      Value<String?> godownLandMark,
      Value<String?> godownDistrict,
      Value<String?> godownArea,
      Value<String?> godownRegion,
      Value<String?> godownPinCode,
      Value<String?> residentialAddressLine,
      Value<String?> residentialLandMark,
      Value<String?> residentialDistrict,
      Value<String?> residentialArea,
      Value<String?> residentialRegion,
      Value<String?> residentialPinCode,
      Value<String?> bankAccountName,
      Value<String?> bankName,
      Value<String?> bankBranchAddress,
      Value<String?> bankAccountNumber,
      Value<String?> bankIfscCode,
      Value<String?> brandName,
      Value<double?> monthlySaleMT,
      Value<int?> noOfDealers,
      Value<String?> areaCovered,
      Value<double?> projectedMonthlySalesBestCementMT,
      Value<int?> noOfEmployeesInSales,
      Value<String?> declarationName,
      Value<String?> declarationPlace,
      Value<DateTime?> declarationDate,
      Value<String?> tradeLicencePicUrl,
      Value<String?> shopPicUrl,
      Value<String?> dealerPicUrl,
      Value<String?> blankChequePicUrl,
      Value<String?> partnershipDeedPicUrl,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalDealersTableUpdateCompanionBuilder =
    LocalDealersCompanion Function({
      Value<String> id,
      Value<int?> userId,
      Value<String> type,
      Value<String?> parentDealerId,
      Value<String> name,
      Value<String> region,
      Value<String> area,
      Value<String> phoneNo,
      Value<String> address,
      Value<String?> pinCode,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<DateTime?> dateOfBirth,
      Value<DateTime?> anniversaryDate,
      Value<double> totalPotential,
      Value<double> bestPotential,
      Value<String?> brandSelling,
      Value<String> feedbacks,
      Value<String?> remarks,
      Value<String?> dealerDevelopmentStatus,
      Value<String?> dealerDevelopmentObstacle,
      Value<double?> salesGrowthPercentage,
      Value<int?> noOfPJP,
      Value<String> verificationStatus,
      Value<String?> whatsappNo,
      Value<String?> emailId,
      Value<String?> businessType,
      Value<String?> nameOfFirm,
      Value<String?> underSalesPromoterName,
      Value<String?> gstinNo,
      Value<String?> panNo,
      Value<String?> tradeLicNo,
      Value<String?> aadharNo,
      Value<int?> godownSizeSqFt,
      Value<String?> godownCapacityMTBags,
      Value<String?> godownAddressLine,
      Value<String?> godownLandMark,
      Value<String?> godownDistrict,
      Value<String?> godownArea,
      Value<String?> godownRegion,
      Value<String?> godownPinCode,
      Value<String?> residentialAddressLine,
      Value<String?> residentialLandMark,
      Value<String?> residentialDistrict,
      Value<String?> residentialArea,
      Value<String?> residentialRegion,
      Value<String?> residentialPinCode,
      Value<String?> bankAccountName,
      Value<String?> bankName,
      Value<String?> bankBranchAddress,
      Value<String?> bankAccountNumber,
      Value<String?> bankIfscCode,
      Value<String?> brandName,
      Value<double?> monthlySaleMT,
      Value<int?> noOfDealers,
      Value<String?> areaCovered,
      Value<double?> projectedMonthlySalesBestCementMT,
      Value<int?> noOfEmployeesInSales,
      Value<String?> declarationName,
      Value<String?> declarationPlace,
      Value<DateTime?> declarationDate,
      Value<String?> tradeLicencePicUrl,
      Value<String?> shopPicUrl,
      Value<String?> dealerPicUrl,
      Value<String?> blankChequePicUrl,
      Value<String?> partnershipDeedPicUrl,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

class $$LocalDealersTableFilterComposer
    extends Composer<_$AppDatabase, $LocalDealersTable> {
  $$LocalDealersTableFilterComposer({
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

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentDealerId => $composableBuilder(
    column: $table.parentDealerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get region => $composableBuilder(
    column: $table.region,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get area => $composableBuilder(
    column: $table.area,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phoneNo => $composableBuilder(
    column: $table.phoneNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pinCode => $composableBuilder(
    column: $table.pinCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateOfBirth => $composableBuilder(
    column: $table.dateOfBirth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get anniversaryDate => $composableBuilder(
    column: $table.anniversaryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalPotential => $composableBuilder(
    column: $table.totalPotential,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bestPotential => $composableBuilder(
    column: $table.bestPotential,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brandSelling => $composableBuilder(
    column: $table.brandSelling,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get feedbacks => $composableBuilder(
    column: $table.feedbacks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remarks => $composableBuilder(
    column: $table.remarks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dealerDevelopmentStatus => $composableBuilder(
    column: $table.dealerDevelopmentStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dealerDevelopmentObstacle => $composableBuilder(
    column: $table.dealerDevelopmentObstacle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get salesGrowthPercentage => $composableBuilder(
    column: $table.salesGrowthPercentage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get noOfPJP => $composableBuilder(
    column: $table.noOfPJP,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get verificationStatus => $composableBuilder(
    column: $table.verificationStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get whatsappNo => $composableBuilder(
    column: $table.whatsappNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emailId => $composableBuilder(
    column: $table.emailId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessType => $composableBuilder(
    column: $table.businessType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameOfFirm => $composableBuilder(
    column: $table.nameOfFirm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get underSalesPromoterName => $composableBuilder(
    column: $table.underSalesPromoterName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gstinNo => $composableBuilder(
    column: $table.gstinNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get panNo => $composableBuilder(
    column: $table.panNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tradeLicNo => $composableBuilder(
    column: $table.tradeLicNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aadharNo => $composableBuilder(
    column: $table.aadharNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get godownSizeSqFt => $composableBuilder(
    column: $table.godownSizeSqFt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get godownCapacityMTBags => $composableBuilder(
    column: $table.godownCapacityMTBags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get godownAddressLine => $composableBuilder(
    column: $table.godownAddressLine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get godownLandMark => $composableBuilder(
    column: $table.godownLandMark,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get godownDistrict => $composableBuilder(
    column: $table.godownDistrict,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get godownArea => $composableBuilder(
    column: $table.godownArea,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get godownRegion => $composableBuilder(
    column: $table.godownRegion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get godownPinCode => $composableBuilder(
    column: $table.godownPinCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get residentialAddressLine => $composableBuilder(
    column: $table.residentialAddressLine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get residentialLandMark => $composableBuilder(
    column: $table.residentialLandMark,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get residentialDistrict => $composableBuilder(
    column: $table.residentialDistrict,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get residentialArea => $composableBuilder(
    column: $table.residentialArea,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get residentialRegion => $composableBuilder(
    column: $table.residentialRegion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get residentialPinCode => $composableBuilder(
    column: $table.residentialPinCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bankAccountName => $composableBuilder(
    column: $table.bankAccountName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bankName => $composableBuilder(
    column: $table.bankName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bankBranchAddress => $composableBuilder(
    column: $table.bankBranchAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bankAccountNumber => $composableBuilder(
    column: $table.bankAccountNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bankIfscCode => $composableBuilder(
    column: $table.bankIfscCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brandName => $composableBuilder(
    column: $table.brandName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get monthlySaleMT => $composableBuilder(
    column: $table.monthlySaleMT,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get noOfDealers => $composableBuilder(
    column: $table.noOfDealers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get areaCovered => $composableBuilder(
    column: $table.areaCovered,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get projectedMonthlySalesBestCementMT =>
      $composableBuilder(
        column: $table.projectedMonthlySalesBestCementMT,
        builder: (column) => ColumnFilters(column),
      );

  ColumnFilters<int> get noOfEmployeesInSales => $composableBuilder(
    column: $table.noOfEmployeesInSales,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get declarationName => $composableBuilder(
    column: $table.declarationName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get declarationPlace => $composableBuilder(
    column: $table.declarationPlace,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get declarationDate => $composableBuilder(
    column: $table.declarationDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tradeLicencePicUrl => $composableBuilder(
    column: $table.tradeLicencePicUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shopPicUrl => $composableBuilder(
    column: $table.shopPicUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dealerPicUrl => $composableBuilder(
    column: $table.dealerPicUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get blankChequePicUrl => $composableBuilder(
    column: $table.blankChequePicUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partnershipDeedPicUrl => $composableBuilder(
    column: $table.partnershipDeedPicUrl,
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
}

class $$LocalDealersTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalDealersTable> {
  $$LocalDealersTableOrderingComposer({
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

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentDealerId => $composableBuilder(
    column: $table.parentDealerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get region => $composableBuilder(
    column: $table.region,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get area => $composableBuilder(
    column: $table.area,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phoneNo => $composableBuilder(
    column: $table.phoneNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pinCode => $composableBuilder(
    column: $table.pinCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateOfBirth => $composableBuilder(
    column: $table.dateOfBirth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get anniversaryDate => $composableBuilder(
    column: $table.anniversaryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalPotential => $composableBuilder(
    column: $table.totalPotential,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bestPotential => $composableBuilder(
    column: $table.bestPotential,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brandSelling => $composableBuilder(
    column: $table.brandSelling,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get feedbacks => $composableBuilder(
    column: $table.feedbacks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remarks => $composableBuilder(
    column: $table.remarks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dealerDevelopmentStatus => $composableBuilder(
    column: $table.dealerDevelopmentStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dealerDevelopmentObstacle => $composableBuilder(
    column: $table.dealerDevelopmentObstacle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get salesGrowthPercentage => $composableBuilder(
    column: $table.salesGrowthPercentage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get noOfPJP => $composableBuilder(
    column: $table.noOfPJP,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get verificationStatus => $composableBuilder(
    column: $table.verificationStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get whatsappNo => $composableBuilder(
    column: $table.whatsappNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emailId => $composableBuilder(
    column: $table.emailId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessType => $composableBuilder(
    column: $table.businessType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameOfFirm => $composableBuilder(
    column: $table.nameOfFirm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get underSalesPromoterName => $composableBuilder(
    column: $table.underSalesPromoterName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gstinNo => $composableBuilder(
    column: $table.gstinNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get panNo => $composableBuilder(
    column: $table.panNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tradeLicNo => $composableBuilder(
    column: $table.tradeLicNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aadharNo => $composableBuilder(
    column: $table.aadharNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get godownSizeSqFt => $composableBuilder(
    column: $table.godownSizeSqFt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get godownCapacityMTBags => $composableBuilder(
    column: $table.godownCapacityMTBags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get godownAddressLine => $composableBuilder(
    column: $table.godownAddressLine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get godownLandMark => $composableBuilder(
    column: $table.godownLandMark,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get godownDistrict => $composableBuilder(
    column: $table.godownDistrict,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get godownArea => $composableBuilder(
    column: $table.godownArea,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get godownRegion => $composableBuilder(
    column: $table.godownRegion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get godownPinCode => $composableBuilder(
    column: $table.godownPinCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get residentialAddressLine => $composableBuilder(
    column: $table.residentialAddressLine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get residentialLandMark => $composableBuilder(
    column: $table.residentialLandMark,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get residentialDistrict => $composableBuilder(
    column: $table.residentialDistrict,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get residentialArea => $composableBuilder(
    column: $table.residentialArea,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get residentialRegion => $composableBuilder(
    column: $table.residentialRegion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get residentialPinCode => $composableBuilder(
    column: $table.residentialPinCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bankAccountName => $composableBuilder(
    column: $table.bankAccountName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bankName => $composableBuilder(
    column: $table.bankName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bankBranchAddress => $composableBuilder(
    column: $table.bankBranchAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bankAccountNumber => $composableBuilder(
    column: $table.bankAccountNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bankIfscCode => $composableBuilder(
    column: $table.bankIfscCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brandName => $composableBuilder(
    column: $table.brandName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get monthlySaleMT => $composableBuilder(
    column: $table.monthlySaleMT,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get noOfDealers => $composableBuilder(
    column: $table.noOfDealers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get areaCovered => $composableBuilder(
    column: $table.areaCovered,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get projectedMonthlySalesBestCementMT =>
      $composableBuilder(
        column: $table.projectedMonthlySalesBestCementMT,
        builder: (column) => ColumnOrderings(column),
      );

  ColumnOrderings<int> get noOfEmployeesInSales => $composableBuilder(
    column: $table.noOfEmployeesInSales,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get declarationName => $composableBuilder(
    column: $table.declarationName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get declarationPlace => $composableBuilder(
    column: $table.declarationPlace,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get declarationDate => $composableBuilder(
    column: $table.declarationDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tradeLicencePicUrl => $composableBuilder(
    column: $table.tradeLicencePicUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shopPicUrl => $composableBuilder(
    column: $table.shopPicUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dealerPicUrl => $composableBuilder(
    column: $table.dealerPicUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get blankChequePicUrl => $composableBuilder(
    column: $table.blankChequePicUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partnershipDeedPicUrl => $composableBuilder(
    column: $table.partnershipDeedPicUrl,
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
}

class $$LocalDealersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalDealersTable> {
  $$LocalDealersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get parentDealerId => $composableBuilder(
    column: $table.parentDealerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get region =>
      $composableBuilder(column: $table.region, builder: (column) => column);

  GeneratedColumn<String> get area =>
      $composableBuilder(column: $table.area, builder: (column) => column);

  GeneratedColumn<String> get phoneNo =>
      $composableBuilder(column: $table.phoneNo, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get pinCode =>
      $composableBuilder(column: $table.pinCode, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<DateTime> get dateOfBirth => $composableBuilder(
    column: $table.dateOfBirth,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get anniversaryDate => $composableBuilder(
    column: $table.anniversaryDate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalPotential => $composableBuilder(
    column: $table.totalPotential,
    builder: (column) => column,
  );

  GeneratedColumn<double> get bestPotential => $composableBuilder(
    column: $table.bestPotential,
    builder: (column) => column,
  );

  GeneratedColumn<String> get brandSelling => $composableBuilder(
    column: $table.brandSelling,
    builder: (column) => column,
  );

  GeneratedColumn<String> get feedbacks =>
      $composableBuilder(column: $table.feedbacks, builder: (column) => column);

  GeneratedColumn<String> get remarks =>
      $composableBuilder(column: $table.remarks, builder: (column) => column);

  GeneratedColumn<String> get dealerDevelopmentStatus => $composableBuilder(
    column: $table.dealerDevelopmentStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dealerDevelopmentObstacle => $composableBuilder(
    column: $table.dealerDevelopmentObstacle,
    builder: (column) => column,
  );

  GeneratedColumn<double> get salesGrowthPercentage => $composableBuilder(
    column: $table.salesGrowthPercentage,
    builder: (column) => column,
  );

  GeneratedColumn<int> get noOfPJP =>
      $composableBuilder(column: $table.noOfPJP, builder: (column) => column);

  GeneratedColumn<String> get verificationStatus => $composableBuilder(
    column: $table.verificationStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get whatsappNo => $composableBuilder(
    column: $table.whatsappNo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get emailId =>
      $composableBuilder(column: $table.emailId, builder: (column) => column);

  GeneratedColumn<String> get businessType => $composableBuilder(
    column: $table.businessType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nameOfFirm => $composableBuilder(
    column: $table.nameOfFirm,
    builder: (column) => column,
  );

  GeneratedColumn<String> get underSalesPromoterName => $composableBuilder(
    column: $table.underSalesPromoterName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gstinNo =>
      $composableBuilder(column: $table.gstinNo, builder: (column) => column);

  GeneratedColumn<String> get panNo =>
      $composableBuilder(column: $table.panNo, builder: (column) => column);

  GeneratedColumn<String> get tradeLicNo => $composableBuilder(
    column: $table.tradeLicNo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get aadharNo =>
      $composableBuilder(column: $table.aadharNo, builder: (column) => column);

  GeneratedColumn<int> get godownSizeSqFt => $composableBuilder(
    column: $table.godownSizeSqFt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get godownCapacityMTBags => $composableBuilder(
    column: $table.godownCapacityMTBags,
    builder: (column) => column,
  );

  GeneratedColumn<String> get godownAddressLine => $composableBuilder(
    column: $table.godownAddressLine,
    builder: (column) => column,
  );

  GeneratedColumn<String> get godownLandMark => $composableBuilder(
    column: $table.godownLandMark,
    builder: (column) => column,
  );

  GeneratedColumn<String> get godownDistrict => $composableBuilder(
    column: $table.godownDistrict,
    builder: (column) => column,
  );

  GeneratedColumn<String> get godownArea => $composableBuilder(
    column: $table.godownArea,
    builder: (column) => column,
  );

  GeneratedColumn<String> get godownRegion => $composableBuilder(
    column: $table.godownRegion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get godownPinCode => $composableBuilder(
    column: $table.godownPinCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get residentialAddressLine => $composableBuilder(
    column: $table.residentialAddressLine,
    builder: (column) => column,
  );

  GeneratedColumn<String> get residentialLandMark => $composableBuilder(
    column: $table.residentialLandMark,
    builder: (column) => column,
  );

  GeneratedColumn<String> get residentialDistrict => $composableBuilder(
    column: $table.residentialDistrict,
    builder: (column) => column,
  );

  GeneratedColumn<String> get residentialArea => $composableBuilder(
    column: $table.residentialArea,
    builder: (column) => column,
  );

  GeneratedColumn<String> get residentialRegion => $composableBuilder(
    column: $table.residentialRegion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get residentialPinCode => $composableBuilder(
    column: $table.residentialPinCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bankAccountName => $composableBuilder(
    column: $table.bankAccountName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bankName =>
      $composableBuilder(column: $table.bankName, builder: (column) => column);

  GeneratedColumn<String> get bankBranchAddress => $composableBuilder(
    column: $table.bankBranchAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bankAccountNumber => $composableBuilder(
    column: $table.bankAccountNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bankIfscCode => $composableBuilder(
    column: $table.bankIfscCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get brandName =>
      $composableBuilder(column: $table.brandName, builder: (column) => column);

  GeneratedColumn<double> get monthlySaleMT => $composableBuilder(
    column: $table.monthlySaleMT,
    builder: (column) => column,
  );

  GeneratedColumn<int> get noOfDealers => $composableBuilder(
    column: $table.noOfDealers,
    builder: (column) => column,
  );

  GeneratedColumn<String> get areaCovered => $composableBuilder(
    column: $table.areaCovered,
    builder: (column) => column,
  );

  GeneratedColumn<double> get projectedMonthlySalesBestCementMT =>
      $composableBuilder(
        column: $table.projectedMonthlySalesBestCementMT,
        builder: (column) => column,
      );

  GeneratedColumn<int> get noOfEmployeesInSales => $composableBuilder(
    column: $table.noOfEmployeesInSales,
    builder: (column) => column,
  );

  GeneratedColumn<String> get declarationName => $composableBuilder(
    column: $table.declarationName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get declarationPlace => $composableBuilder(
    column: $table.declarationPlace,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get declarationDate => $composableBuilder(
    column: $table.declarationDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tradeLicencePicUrl => $composableBuilder(
    column: $table.tradeLicencePicUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get shopPicUrl => $composableBuilder(
    column: $table.shopPicUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dealerPicUrl => $composableBuilder(
    column: $table.dealerPicUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get blankChequePicUrl => $composableBuilder(
    column: $table.blankChequePicUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get partnershipDeedPicUrl => $composableBuilder(
    column: $table.partnershipDeedPicUrl,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalDealersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalDealersTable,
          LocalDealer,
          $$LocalDealersTableFilterComposer,
          $$LocalDealersTableOrderingComposer,
          $$LocalDealersTableAnnotationComposer,
          $$LocalDealersTableCreateCompanionBuilder,
          $$LocalDealersTableUpdateCompanionBuilder,
          (
            LocalDealer,
            BaseReferences<_$AppDatabase, $LocalDealersTable, LocalDealer>,
          ),
          LocalDealer,
          PrefetchHooks Function()
        > {
  $$LocalDealersTableTableManager(_$AppDatabase db, $LocalDealersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalDealersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalDealersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalDealersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int?> userId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> parentDealerId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> region = const Value.absent(),
                Value<String> area = const Value.absent(),
                Value<String> phoneNo = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<String?> pinCode = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<DateTime?> dateOfBirth = const Value.absent(),
                Value<DateTime?> anniversaryDate = const Value.absent(),
                Value<double> totalPotential = const Value.absent(),
                Value<double> bestPotential = const Value.absent(),
                Value<String?> brandSelling = const Value.absent(),
                Value<String> feedbacks = const Value.absent(),
                Value<String?> remarks = const Value.absent(),
                Value<String?> dealerDevelopmentStatus = const Value.absent(),
                Value<String?> dealerDevelopmentObstacle = const Value.absent(),
                Value<double?> salesGrowthPercentage = const Value.absent(),
                Value<int?> noOfPJP = const Value.absent(),
                Value<String> verificationStatus = const Value.absent(),
                Value<String?> whatsappNo = const Value.absent(),
                Value<String?> emailId = const Value.absent(),
                Value<String?> businessType = const Value.absent(),
                Value<String?> nameOfFirm = const Value.absent(),
                Value<String?> underSalesPromoterName = const Value.absent(),
                Value<String?> gstinNo = const Value.absent(),
                Value<String?> panNo = const Value.absent(),
                Value<String?> tradeLicNo = const Value.absent(),
                Value<String?> aadharNo = const Value.absent(),
                Value<int?> godownSizeSqFt = const Value.absent(),
                Value<String?> godownCapacityMTBags = const Value.absent(),
                Value<String?> godownAddressLine = const Value.absent(),
                Value<String?> godownLandMark = const Value.absent(),
                Value<String?> godownDistrict = const Value.absent(),
                Value<String?> godownArea = const Value.absent(),
                Value<String?> godownRegion = const Value.absent(),
                Value<String?> godownPinCode = const Value.absent(),
                Value<String?> residentialAddressLine = const Value.absent(),
                Value<String?> residentialLandMark = const Value.absent(),
                Value<String?> residentialDistrict = const Value.absent(),
                Value<String?> residentialArea = const Value.absent(),
                Value<String?> residentialRegion = const Value.absent(),
                Value<String?> residentialPinCode = const Value.absent(),
                Value<String?> bankAccountName = const Value.absent(),
                Value<String?> bankName = const Value.absent(),
                Value<String?> bankBranchAddress = const Value.absent(),
                Value<String?> bankAccountNumber = const Value.absent(),
                Value<String?> bankIfscCode = const Value.absent(),
                Value<String?> brandName = const Value.absent(),
                Value<double?> monthlySaleMT = const Value.absent(),
                Value<int?> noOfDealers = const Value.absent(),
                Value<String?> areaCovered = const Value.absent(),
                Value<double?> projectedMonthlySalesBestCementMT =
                    const Value.absent(),
                Value<int?> noOfEmployeesInSales = const Value.absent(),
                Value<String?> declarationName = const Value.absent(),
                Value<String?> declarationPlace = const Value.absent(),
                Value<DateTime?> declarationDate = const Value.absent(),
                Value<String?> tradeLicencePicUrl = const Value.absent(),
                Value<String?> shopPicUrl = const Value.absent(),
                Value<String?> dealerPicUrl = const Value.absent(),
                Value<String?> blankChequePicUrl = const Value.absent(),
                Value<String?> partnershipDeedPicUrl = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalDealersCompanion(
                id: id,
                userId: userId,
                type: type,
                parentDealerId: parentDealerId,
                name: name,
                region: region,
                area: area,
                phoneNo: phoneNo,
                address: address,
                pinCode: pinCode,
                latitude: latitude,
                longitude: longitude,
                dateOfBirth: dateOfBirth,
                anniversaryDate: anniversaryDate,
                totalPotential: totalPotential,
                bestPotential: bestPotential,
                brandSelling: brandSelling,
                feedbacks: feedbacks,
                remarks: remarks,
                dealerDevelopmentStatus: dealerDevelopmentStatus,
                dealerDevelopmentObstacle: dealerDevelopmentObstacle,
                salesGrowthPercentage: salesGrowthPercentage,
                noOfPJP: noOfPJP,
                verificationStatus: verificationStatus,
                whatsappNo: whatsappNo,
                emailId: emailId,
                businessType: businessType,
                nameOfFirm: nameOfFirm,
                underSalesPromoterName: underSalesPromoterName,
                gstinNo: gstinNo,
                panNo: panNo,
                tradeLicNo: tradeLicNo,
                aadharNo: aadharNo,
                godownSizeSqFt: godownSizeSqFt,
                godownCapacityMTBags: godownCapacityMTBags,
                godownAddressLine: godownAddressLine,
                godownLandMark: godownLandMark,
                godownDistrict: godownDistrict,
                godownArea: godownArea,
                godownRegion: godownRegion,
                godownPinCode: godownPinCode,
                residentialAddressLine: residentialAddressLine,
                residentialLandMark: residentialLandMark,
                residentialDistrict: residentialDistrict,
                residentialArea: residentialArea,
                residentialRegion: residentialRegion,
                residentialPinCode: residentialPinCode,
                bankAccountName: bankAccountName,
                bankName: bankName,
                bankBranchAddress: bankBranchAddress,
                bankAccountNumber: bankAccountNumber,
                bankIfscCode: bankIfscCode,
                brandName: brandName,
                monthlySaleMT: monthlySaleMT,
                noOfDealers: noOfDealers,
                areaCovered: areaCovered,
                projectedMonthlySalesBestCementMT:
                    projectedMonthlySalesBestCementMT,
                noOfEmployeesInSales: noOfEmployeesInSales,
                declarationName: declarationName,
                declarationPlace: declarationPlace,
                declarationDate: declarationDate,
                tradeLicencePicUrl: tradeLicencePicUrl,
                shopPicUrl: shopPicUrl,
                dealerPicUrl: dealerPicUrl,
                blankChequePicUrl: blankChequePicUrl,
                partnershipDeedPicUrl: partnershipDeedPicUrl,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<int?> userId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> parentDealerId = const Value.absent(),
                required String name,
                Value<String> region = const Value.absent(),
                Value<String> area = const Value.absent(),
                Value<String> phoneNo = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<String?> pinCode = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<DateTime?> dateOfBirth = const Value.absent(),
                Value<DateTime?> anniversaryDate = const Value.absent(),
                Value<double> totalPotential = const Value.absent(),
                Value<double> bestPotential = const Value.absent(),
                Value<String?> brandSelling = const Value.absent(),
                Value<String> feedbacks = const Value.absent(),
                Value<String?> remarks = const Value.absent(),
                Value<String?> dealerDevelopmentStatus = const Value.absent(),
                Value<String?> dealerDevelopmentObstacle = const Value.absent(),
                Value<double?> salesGrowthPercentage = const Value.absent(),
                Value<int?> noOfPJP = const Value.absent(),
                Value<String> verificationStatus = const Value.absent(),
                Value<String?> whatsappNo = const Value.absent(),
                Value<String?> emailId = const Value.absent(),
                Value<String?> businessType = const Value.absent(),
                Value<String?> nameOfFirm = const Value.absent(),
                Value<String?> underSalesPromoterName = const Value.absent(),
                Value<String?> gstinNo = const Value.absent(),
                Value<String?> panNo = const Value.absent(),
                Value<String?> tradeLicNo = const Value.absent(),
                Value<String?> aadharNo = const Value.absent(),
                Value<int?> godownSizeSqFt = const Value.absent(),
                Value<String?> godownCapacityMTBags = const Value.absent(),
                Value<String?> godownAddressLine = const Value.absent(),
                Value<String?> godownLandMark = const Value.absent(),
                Value<String?> godownDistrict = const Value.absent(),
                Value<String?> godownArea = const Value.absent(),
                Value<String?> godownRegion = const Value.absent(),
                Value<String?> godownPinCode = const Value.absent(),
                Value<String?> residentialAddressLine = const Value.absent(),
                Value<String?> residentialLandMark = const Value.absent(),
                Value<String?> residentialDistrict = const Value.absent(),
                Value<String?> residentialArea = const Value.absent(),
                Value<String?> residentialRegion = const Value.absent(),
                Value<String?> residentialPinCode = const Value.absent(),
                Value<String?> bankAccountName = const Value.absent(),
                Value<String?> bankName = const Value.absent(),
                Value<String?> bankBranchAddress = const Value.absent(),
                Value<String?> bankAccountNumber = const Value.absent(),
                Value<String?> bankIfscCode = const Value.absent(),
                Value<String?> brandName = const Value.absent(),
                Value<double?> monthlySaleMT = const Value.absent(),
                Value<int?> noOfDealers = const Value.absent(),
                Value<String?> areaCovered = const Value.absent(),
                Value<double?> projectedMonthlySalesBestCementMT =
                    const Value.absent(),
                Value<int?> noOfEmployeesInSales = const Value.absent(),
                Value<String?> declarationName = const Value.absent(),
                Value<String?> declarationPlace = const Value.absent(),
                Value<DateTime?> declarationDate = const Value.absent(),
                Value<String?> tradeLicencePicUrl = const Value.absent(),
                Value<String?> shopPicUrl = const Value.absent(),
                Value<String?> dealerPicUrl = const Value.absent(),
                Value<String?> blankChequePicUrl = const Value.absent(),
                Value<String?> partnershipDeedPicUrl = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalDealersCompanion.insert(
                id: id,
                userId: userId,
                type: type,
                parentDealerId: parentDealerId,
                name: name,
                region: region,
                area: area,
                phoneNo: phoneNo,
                address: address,
                pinCode: pinCode,
                latitude: latitude,
                longitude: longitude,
                dateOfBirth: dateOfBirth,
                anniversaryDate: anniversaryDate,
                totalPotential: totalPotential,
                bestPotential: bestPotential,
                brandSelling: brandSelling,
                feedbacks: feedbacks,
                remarks: remarks,
                dealerDevelopmentStatus: dealerDevelopmentStatus,
                dealerDevelopmentObstacle: dealerDevelopmentObstacle,
                salesGrowthPercentage: salesGrowthPercentage,
                noOfPJP: noOfPJP,
                verificationStatus: verificationStatus,
                whatsappNo: whatsappNo,
                emailId: emailId,
                businessType: businessType,
                nameOfFirm: nameOfFirm,
                underSalesPromoterName: underSalesPromoterName,
                gstinNo: gstinNo,
                panNo: panNo,
                tradeLicNo: tradeLicNo,
                aadharNo: aadharNo,
                godownSizeSqFt: godownSizeSqFt,
                godownCapacityMTBags: godownCapacityMTBags,
                godownAddressLine: godownAddressLine,
                godownLandMark: godownLandMark,
                godownDistrict: godownDistrict,
                godownArea: godownArea,
                godownRegion: godownRegion,
                godownPinCode: godownPinCode,
                residentialAddressLine: residentialAddressLine,
                residentialLandMark: residentialLandMark,
                residentialDistrict: residentialDistrict,
                residentialArea: residentialArea,
                residentialRegion: residentialRegion,
                residentialPinCode: residentialPinCode,
                bankAccountName: bankAccountName,
                bankName: bankName,
                bankBranchAddress: bankBranchAddress,
                bankAccountNumber: bankAccountNumber,
                bankIfscCode: bankIfscCode,
                brandName: brandName,
                monthlySaleMT: monthlySaleMT,
                noOfDealers: noOfDealers,
                areaCovered: areaCovered,
                projectedMonthlySalesBestCementMT:
                    projectedMonthlySalesBestCementMT,
                noOfEmployeesInSales: noOfEmployeesInSales,
                declarationName: declarationName,
                declarationPlace: declarationPlace,
                declarationDate: declarationDate,
                tradeLicencePicUrl: tradeLicencePicUrl,
                shopPicUrl: shopPicUrl,
                dealerPicUrl: dealerPicUrl,
                blankChequePicUrl: blankChequePicUrl,
                partnershipDeedPicUrl: partnershipDeedPicUrl,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalDealersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalDealersTable,
      LocalDealer,
      $$LocalDealersTableFilterComposer,
      $$LocalDealersTableOrderingComposer,
      $$LocalDealersTableAnnotationComposer,
      $$LocalDealersTableCreateCompanionBuilder,
      $$LocalDealersTableUpdateCompanionBuilder,
      (
        LocalDealer,
        BaseReferences<_$AppDatabase, $LocalDealersTable, LocalDealer>,
      ),
      LocalDealer,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$JourneysTableTableManager get journeys =>
      $$JourneysTableTableManager(_db, _db.journeys);
  $$JourneyBreadcrumbsTableTableManager get journeyBreadcrumbs =>
      $$JourneyBreadcrumbsTableTableManager(_db, _db.journeyBreadcrumbs);
  $$JourneyOpsQueueTableTableManager get journeyOpsQueue =>
      $$JourneyOpsQueueTableTableManager(_db, _db.journeyOpsQueue);
  $$LocalDailyVisitReportsTableTableManager get localDailyVisitReports =>
      $$LocalDailyVisitReportsTableTableManager(
        _db,
        _db.localDailyVisitReports,
      );
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$LocalDealersTableTableManager get localDealers =>
      $$LocalDealersTableTableManager(_db, _db.localDealers);
}
