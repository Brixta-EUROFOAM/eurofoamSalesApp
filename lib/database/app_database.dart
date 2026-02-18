import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

part 'app_database.g.dart';

// 1. The Parent Table (Context)
class Journeys extends Table {
  TextColumn get id => text()(); // UUID
  IntColumn get userId => integer()();
  TextColumn get pjpId => text().nullable()();
  TextColumn get taskId => text().nullable()(); 
  TextColumn get dealerId => text().nullable()(); 
  IntColumn get verifiedDealerId => integer().nullable()();

  TextColumn get status => text().withDefault(const Constant('ACTIVE'))();
  TextColumn get siteName => text().nullable()();
  RealColumn get totalDistance => real().withDefault(const Constant(0.0))();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// 2. The Child Tab
class JourneyBreadcrumbs extends Table {
  TextColumn get id => text()();
  TextColumn get journeyId => text().references(Journeys, #id)();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  TextColumn get h3Index => text()(); // The Hexagon ID
  RealColumn get totalDistance => real().withDefault(const Constant(0.0))();
  RealColumn get speed => real().nullable()();
  RealColumn get heading => real().nullable()();
  RealColumn get accuracy => real().nullable()();
  DateTimeColumn get recordedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// 3. Define the Outbox Table - to keep sync logic separate
class JourneyOpsQueue extends Table {
  TextColumn get opId => text()(); // UUID for Idempotency
  TextColumn get journeyId => text()();
  IntColumn get userId => integer()();
  TextColumn get type => text()(); // 'START', 'MOVE', 'STOP'
  TextColumn get payload => text()(); // The JSON body for the server
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {opId};
}

@DriftDatabase(tables: [Journeys, JourneyBreadcrumbs, JourneyOpsQueue])
class AppDatabase extends _$AppDatabase {
  // Singleton pattern for global access
  static final AppDatabase _instance = AppDatabase();
  static AppDatabase get instance => _instance;

  AppDatabase() : super(_openConnection());

  // 🔄 BUMP VERSION HERE
  @override
  int get schemaVersion => 4;

  // 🔄 DEFINE MIGRATION STRATEGY
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(journeyOpsQueue);
        }
        if (from < 3) {
          await m.addColumn(
            journeyBreadcrumbs,
            journeyBreadcrumbs.totalDistance,
          );
        }
        if (from < 4) {
          await m.addColumn(journeys, journeys.taskId);
          await m.addColumn(journeys, journeys.dealerId);
          await m.addColumn(journeys, journeys.verifiedDealerId);
        }
      },
    );
  }

  // HELPERS
  // 1. START local db journey
  Future<String> startLocalJourney({
    required int userId,
    required String? pjpId,
    required String? siteName,
    String? taskId,
    String? dealerId,
    int? verifiedDealerId,
  }) async {
    final uuid = const Uuid().v4();

    await into(journeys).insert(
      JourneysCompanion.insert(
        id: uuid,
        userId: userId,
        pjpId: Value(pjpId),
        taskId: Value(taskId),
        dealerId: Value(dealerId),
        verifiedDealerId: Value(verifiedDealerId),
        siteName: Value(siteName),
        startTime: DateTime.now(),
        status: const Value('ACTIVE'),
        totalDistance: const Value(0.0),
      ),
    );

    return uuid;
  }

  Future<List<JourneyBreadcrumb>> getBreadcrumbsForJourney(String journeyId) {
    return (select(journeyBreadcrumbs)
          ..where((t) => t.journeyId.equals(journeyId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.recordedAt, mode: OrderingMode.asc),
          ]))
        .get();
  }

  // 2. MOVE (Insert Breadcrumb)
  Future<void> insertBreadcrumb(JourneyBreadcrumbsCompanion crumb) async {
    await into(journeyBreadcrumbs).insert(crumb);
  }

  // 3. STOP (Finalize Journey)
  Future<void> stopLocalJourney(String journeyId, double distance) async {
    await (update(journeys)..where((tbl) => tbl.id.equals(journeyId))).write(
      JourneysCompanion(
        endTime: Value(DateTime.now()),
        totalDistance: Value(distance),
        status: const Value('COMPLETED_UNSYNCED'), // Mark for Sync Worker
      ),
    );
  }

  Future<JourneyBreadcrumb?> getLatestBreadcrumb(String journeyId) {
    return (select(journeyBreadcrumbs)
          ..where((t) => t.journeyId.equals(journeyId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.recordedAt, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<Journey?> getActiveJourney() {
    return (select(journeys)
          ..where((t) => t.status.equals('ACTIVE'))
          ..limit(1))
        .getSingleOrNull();
  }

  // 4. SYNC HELPER (For the worker later)
  Future<List<Journey>> getUnsyncedJourneys() {
    return (select(
      journeys,
    )..where((tbl) => tbl.status.equals('COMPLETED_UNSYNCED'))).get();
  }

  // sync section
  // Insert into Outbox
  Future<void> enqueueOp(JourneyOpsQueueCompanion op) async {
    await into(journeyOpsQueue).insert(op);
  }

  // Get Pending Ops
  Future<List<JourneyOpsQueueData>> getPendingOps() {
    return (select(
      journeyOpsQueue,
    )..orderBy([(t) => OrderingTerm(expression: t.createdAt)])).get();
  }

  Future<double> getLastDistanceForJourney(String journeyId) async {
    final crumb =
        await (select(journeyBreadcrumbs)
              ..where((t) => t.journeyId.equals(journeyId))
              ..orderBy([
                (t) => OrderingTerm(
                  expression: t.recordedAt,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();

    return crumb?.totalDistance ?? 0.0;
  }

  // Delete Acked Ops
  Future<void> deleteOps(List<String> opIds) async {
    await (delete(journeyOpsQueue)..where((tbl) => tbl.opId.isIn(opIds))).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'salesman_core.sqlite'));
    return NativeDatabase(file, logStatements: true);
  });
}
