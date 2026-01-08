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
  final String status;
  final String? siteName;
  final double totalDistance;
  final DateTime startTime;
  final DateTime? endTime;
  const Journey({
    required this.id,
    required this.userId,
    this.pjpId,
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
    String? status,
    Value<String?> siteName = const Value.absent(),
    double? totalDistance,
    DateTime? startTime,
    Value<DateTime?> endTime = const Value.absent(),
  }) => Journey(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    pjpId: pjpId.present ? pjpId.value : this.pjpId,
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
          ..write('speed: $speed, ')
          ..write('heading: $heading, ')
          ..write('accuracy: $accuracy, ')
          ..write('recordedAt: $recordedAt, ')
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
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    journeys,
    journeyBreadcrumbs,
  ];
}

typedef $$JourneysTableCreateCompanionBuilder =
    JourneysCompanion Function({
      required String id,
      required int userId,
      Value<String?> pjpId,
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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$JourneysTableTableManager get journeys =>
      $$JourneysTableTableManager(_db, _db.journeys);
  $$JourneyBreadcrumbsTableTableManager get journeyBreadcrumbs =>
      $$JourneyBreadcrumbsTableTableManager(_db, _db.journeyBreadcrumbs);
}
