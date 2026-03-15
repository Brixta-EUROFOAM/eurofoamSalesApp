import 'dart:io';
import 'dart:convert';
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

// --- 🚀 NEW: EXACT DRIZZLE REPLICA FOR DVR ---
class LocalDailyVisitReports extends Table {
  TextColumn get id => text()(); // UUID
  IntColumn get userId => integer()();
  TextColumn get dealerId => text().nullable()();
  TextColumn get subDealerId => text().nullable()();
  DateTimeColumn get reportDate => dateTime().nullable()();
  TextColumn get dealerType => text().nullable()();
  TextColumn get location => text().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  TextColumn get visitType => text().nullable()();
  RealColumn get dealerTotalPotential => real().nullable()();
  RealColumn get dealerBestPotential => real().nullable()();
  TextColumn get brandSelling => text().nullable()(); // JSON array string
  TextColumn get contactPerson => text().nullable()();
  TextColumn get contactPersonPhoneNo => text().nullable()();
  RealColumn get todayOrderMt => real().nullable()();
  RealColumn get todayCollectionRupees => real().nullable()();
  RealColumn get overdueAmount => real().nullable()();
  TextColumn get feedbacks => text().nullable()();
  TextColumn get solutionBySalesperson => text().nullable()();
  TextColumn get anyRemarks => text().nullable()();

  DateTimeColumn get checkInTime => dateTime().nullable()();
  DateTimeColumn get checkOutTime => dateTime().nullable()();
  TextColumn get timeSpentinLoc => text().nullable()();
  TextColumn get inTimeImageUrl => text().nullable()(); // Local path initially
  TextColumn get outTimeImageUrl => text().nullable()(); // Local path initially
  TextColumn get pjpId => text().nullable()();
  TextColumn get dailyTaskId => text().nullable()();

  TextColumn get customerType => text().nullable()();
  TextColumn get partyType => text().nullable()();
  TextColumn get nameOfParty => text().nullable()();
  TextColumn get contactNoOfParty => text().nullable()();
  DateTimeColumn get expectedActivationDate => dateTime().nullable()();
  RealColumn get currentDealerOutstandingAmt => real().nullable()();

  // 🚀 IDEMPOTENCY KEY TO PREVENT DOUBLE-SUBMITS
  TextColumn get idempotencyKey => text().nullable()();

  // Offline specific fields
  TextColumn get syncStatus =>
      text().withDefault(const Constant('PENDING'))(); // PENDING, SYNCED

  @override
  Set<Column> get primaryKey => {id};
}

// --- 🚀 NEW: THE UNIVERSAL OFFLINE OUTBOX QUEUE ---
class SyncQueue extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get entityType => text()(); // 'DVR', 'TVR', 'ORDER'
  TextColumn get payload => text()(); // The JSON body for the API
  TextColumn get localFiles =>
      text().nullable()(); // JSON list of local file paths to upload first
  TextColumn get status => text().withDefault(
    const Constant('PENDING'),
  )(); // PENDING, PROCESSING, FAILED
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// --- 🚀 NEW: LOCAL DEALERS CACHE FOR OFFLINE SEARCH ---
// --- 🚀 NEW: EXACT DRIZZLE REPLICA FOR LOCAL DEALERS ---
class LocalDealers extends Table {
  TextColumn get id => text()();
  IntColumn get userId => integer().nullable()();
  TextColumn get type => text().withDefault(const Constant('Dealer'))();
  TextColumn get parentDealerId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get region => text().withDefault(const Constant(''))();
  TextColumn get area => text().withDefault(const Constant(''))();
  TextColumn get phoneNo => text().withDefault(const Constant(''))();
  TextColumn get address => text().withDefault(const Constant(''))();
  TextColumn get pinCode => text().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  DateTimeColumn get dateOfBirth => dateTime().nullable()();
  DateTimeColumn get anniversaryDate => dateTime().nullable()();
  RealColumn get totalPotential => real().withDefault(const Constant(0.0))();
  RealColumn get bestPotential => real().withDefault(const Constant(0.0))();
  TextColumn get brandSelling => text().nullable()(); // JSON Array
  TextColumn get feedbacks => text().withDefault(const Constant(''))();
  TextColumn get remarks => text().nullable()();

  // Prisma Parity
  TextColumn get dealerDevelopmentStatus => text().nullable()();
  TextColumn get dealerDevelopmentObstacle => text().nullable()();
  RealColumn get salesGrowthPercentage => real().nullable()();
  IntColumn get noOfPJP => integer().nullable()();

  // Verification & IDs
  TextColumn get verificationStatus =>
      text().withDefault(const Constant('PENDING'))();
  TextColumn get whatsappNo => text().nullable()();
  TextColumn get emailId => text().nullable()();
  TextColumn get businessType => text().nullable()();
  TextColumn get nameOfFirm => text().nullable()();
  TextColumn get underSalesPromoterName => text().nullable()();
  TextColumn get gstinNo => text().nullable()();
  TextColumn get panNo => text().nullable()();
  TextColumn get tradeLicNo => text().nullable()();
  TextColumn get aadharNo => text().nullable()();

  // Godown
  IntColumn get godownSizeSqFt => integer().nullable()();
  TextColumn get godownCapacityMTBags => text().nullable()();
  TextColumn get godownAddressLine => text().nullable()();
  TextColumn get godownLandMark => text().nullable()();
  TextColumn get godownDistrict => text().nullable()();
  TextColumn get godownArea => text().nullable()();
  TextColumn get godownRegion => text().nullable()();
  TextColumn get godownPinCode => text().nullable()();

  // Residential
  TextColumn get residentialAddressLine => text().nullable()();
  TextColumn get residentialLandMark => text().nullable()();
  TextColumn get residentialDistrict => text().nullable()();
  TextColumn get residentialArea => text().nullable()();
  TextColumn get residentialRegion => text().nullable()();
  TextColumn get residentialPinCode => text().nullable()();

  // Bank
  TextColumn get bankAccountName => text().nullable()();
  TextColumn get bankName => text().nullable()();
  TextColumn get bankBranchAddress => text().nullable()();
  TextColumn get bankAccountNumber => text().nullable()();
  TextColumn get bankIfscCode => text().nullable()();

  // Sales & promoter
  TextColumn get brandName => text().nullable()();
  RealColumn get monthlySaleMT => real().nullable()();
  IntColumn get noOfDealers => integer().nullable()();
  TextColumn get areaCovered => text().nullable()();
  RealColumn get projectedMonthlySalesBestCementMT => real().nullable()();
  IntColumn get noOfEmployeesInSales => integer().nullable()();

  // Declaration
  TextColumn get declarationName => text().nullable()();
  TextColumn get declarationPlace => text().nullable()();
  DateTimeColumn get declarationDate => dateTime().nullable()();

  // Document URLs
  TextColumn get tradeLicencePicUrl => text().nullable()();
  TextColumn get shopPicUrl => text().nullable()();
  TextColumn get dealerPicUrl => text().nullable()();
  TextColumn get blankChequePicUrl => text().nullable()();
  TextColumn get partnershipDeedPicUrl => text().nullable()();

  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Journeys,
    JourneyBreadcrumbs,
    JourneyOpsQueue,
    LocalDailyVisitReports,
    SyncQueue,
    LocalDealers, // 👈 Ensures the table is generated!
  ],
)
class AppDatabase extends _$AppDatabase {
  static final AppDatabase _instance = AppDatabase();
  static AppDatabase get instance => _instance;

  AppDatabase() : super(_openConnection());

  // 🔄 BUMP VERSION HERE
  @override
  int get schemaVersion => 7;

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
        if (from < 5) {
          await m.createTable(localDailyVisitReports);
          await m.createTable(syncQueue);
        }
        // 🚀 NEW: VERSION 6 MIGRATION
        if (from < 6) {
          await m.createTable(localDealers);
        }
        if (from < 7) {
          await m.deleteTable(localDealers.actualTableName);
          await m.createTable(localDealers);
        }
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 🚀 DEALER OFFLINE SEARCH ENGINE (NEW)
  // ---------------------------------------------------------------------------

  Future<void> syncDealersToLocal(List<dynamic> serverDealers) async {
    await batch((batch) {
      batch.insertAll(
        localDealers,
        serverDealers.map((dynamic item) {
          // Cast safely to Map to ensure we get bracket notation access
          final d = item as Map<String, dynamic>;

          return LocalDealersCompanion.insert(
            // Core Identity
            id: d['id']?.toString() ?? '',
            userId: Value(
              d['userId'] != null ? int.tryParse(d['userId'].toString()) : null,
            ),
            type: Value(d['type']?.toString() ?? 'Dealer'),
            parentDealerId: Value(d['parentDealerId']?.toString()),
            name: d['name']?.toString() ?? 'Unknown',

            // Location & Contact
            region: Value(d['region']?.toString() ?? ''),
            area: Value(d['area']?.toString() ?? ''),
            phoneNo: Value(d['phoneNo']?.toString() ?? ''),
            address: Value(d['address']?.toString() ?? ''),
            pinCode: Value(d['pinCode']?.toString()),
            latitude: Value(double.tryParse(d['latitude']?.toString() ?? '')),
            longitude: Value(double.tryParse(d['longitude']?.toString() ?? '')),

            // Dates
            dateOfBirth: Value(
              d['dateOfBirth'] != null
                  ? DateTime.tryParse(d['dateOfBirth'].toString())
                  : null,
            ),
            anniversaryDate: Value(
              d['anniversaryDate'] != null
                  ? DateTime.tryParse(d['anniversaryDate'].toString())
                  : null,
            ),

            // Business Potential & Status
            totalPotential: Value(
              double.tryParse(d['totalPotential']?.toString() ?? '0.0') ?? 0.0,
            ),
            bestPotential: Value(
              double.tryParse(d['bestPotential']?.toString() ?? '0.0') ?? 0.0,
            ),
            brandSelling: Value(
              d['brandSelling'] != null ? jsonEncode(d['brandSelling']) : null,
            ),
            feedbacks: Value(d['feedbacks']?.toString() ?? ''),
            remarks: Value(d['remarks']?.toString()),

            // Prisma Parity Additions
            dealerDevelopmentStatus: Value(
              d['dealerDevelopmentStatus']?.toString(),
            ),
            dealerDevelopmentObstacle: Value(
              d['dealerDevelopmentObstacle']?.toString(),
            ),
            salesGrowthPercentage: Value(
              double.tryParse(d['salesGrowthPercentage']?.toString() ?? ''),
            ),
            noOfPJP: Value(int.tryParse(d['noOfPJP']?.toString() ?? '')),

            // Verification & IDs
            verificationStatus: Value(
              d['verificationStatus']?.toString() ?? 'PENDING',
            ),
            whatsappNo: Value(d['whatsappNo']?.toString()),
            emailId: Value(d['emailId']?.toString()),
            businessType: Value(d['businessType']?.toString()),
            nameOfFirm: Value(d['nameOfFirm']?.toString()),
            underSalesPromoterName: Value(
              d['underSalesPromoterName']?.toString(),
            ),
            gstinNo: Value(d['gstinNo']?.toString()),
            panNo: Value(d['panNo']?.toString()),
            tradeLicNo: Value(d['tradeLicNo']?.toString()),
            aadharNo: Value(d['aadharNo']?.toString()),

            // Godown Details
            godownSizeSqFt: Value(
              int.tryParse(d['godownSizeSqFt']?.toString() ?? ''),
            ),
            godownCapacityMTBags: Value(d['godownCapacityMTBags']?.toString()),
            godownAddressLine: Value(d['godownAddressLine']?.toString()),
            godownLandMark: Value(d['godownLandMark']?.toString()),
            godownDistrict: Value(d['godownDistrict']?.toString()),
            godownArea: Value(d['godownArea']?.toString()),
            godownRegion: Value(d['godownRegion']?.toString()),
            godownPinCode: Value(d['godownPinCode']?.toString()),

            // Residential Details
            residentialAddressLine: Value(
              d['residentialAddressLine']?.toString(),
            ),
            residentialLandMark: Value(d['residentialLandMark']?.toString()),
            residentialDistrict: Value(d['residentialDistrict']?.toString()),
            residentialArea: Value(d['residentialArea']?.toString()),
            residentialRegion: Value(d['residentialRegion']?.toString()),
            residentialPinCode: Value(d['residentialPinCode']?.toString()),

            // Bank Details
            bankAccountName: Value(d['bankAccountName']?.toString()),
            bankName: Value(d['bankName']?.toString()),
            bankBranchAddress: Value(d['bankBranchAddress']?.toString()),
            bankAccountNumber: Value(d['bankAccountNumber']?.toString()),
            bankIfscCode: Value(d['bankIfscCode']?.toString()),

            // Sales & Promoter
            brandName: Value(d['brandName']?.toString()),
            monthlySaleMT: Value(
              double.tryParse(d['monthlySaleMT']?.toString() ?? ''),
            ),
            noOfDealers: Value(
              int.tryParse(d['noOfDealers']?.toString() ?? ''),
            ),
            areaCovered: Value(d['areaCovered']?.toString()),
            projectedMonthlySalesBestCementMT: Value(
              double.tryParse(
                d['projectedMonthlySalesBestCementMT']?.toString() ?? '',
              ),
            ),
            noOfEmployeesInSales: Value(
              int.tryParse(d['noOfEmployeesInSales']?.toString() ?? ''),
            ),

            // Declaration
            declarationName: Value(d['declarationName']?.toString()),
            declarationPlace: Value(d['declarationPlace']?.toString()),
            declarationDate: Value(
              d['declarationDate'] != null
                  ? DateTime.tryParse(d['declarationDate'].toString())
                  : null,
            ),

            // Document URLs
            tradeLicencePicUrl: Value(d['tradeLicencePicUrl']?.toString()),
            shopPicUrl: Value(d['shopPicUrl']?.toString()),
            dealerPicUrl: Value(d['dealerPicUrl']?.toString()),
            blankChequePicUrl: Value(d['blankChequePicUrl']?.toString()),
            partnershipDeedPicUrl: Value(
              d['partnershipDeedPicUrl']?.toString(),
            ),

            // Timestamps
            createdAt: Value(
              d['createdAt'] != null
                  ? DateTime.tryParse(d['createdAt'].toString())
                  : null,
            ),
            updatedAt: Value(
              d['updatedAt'] != null
                  ? DateTime.tryParse(d['updatedAt'].toString())
                  : null,
            ),
          );
        }),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  // 2. OFFLINE SEARCH (0.005s execution time)
  // 2. OFFLINE SEARCH (Expanded for Names & IDs)
  Future<List<LocalDealer>> searchLocalDealers(String query) {
    if (query.isEmpty) {
      return (select(localDealers)..limit(10000)).get();
    }

    final searchTerm = '%$query%';

    return (select(localDealers)
          ..where(
            (t) =>
                t.name.like(searchTerm) |
                t.nameOfFirm.like(searchTerm) | 
                t.underSalesPromoterName.like(searchTerm,) | 
                t.region.like(searchTerm) |
                t.area.like(searchTerm) |
                t.phoneNo.like(searchTerm) |
                t.pinCode.like(searchTerm) |
                t.address.like(searchTerm) |
                t.gstinNo.like(searchTerm,),
          )
          ..limit(50))
        .get();
  }

  // 🚀 FAST ID MAPPER: Only fetches the IDs, saving massive RAM
  Future<Set<String>> getAllDealerIdsFast() async {
    final query = selectOnly(localDealers)..addColumns([localDealers.id]);
    final results = await query.get();
    return results.map((row) => row.read(localDealers.id)!.toString()).toSet();
  }

  // to check dealer count in local db
  Future<int> getLocalDealersCount() async {
    final countExp = localDealers.id.count();
    final query = selectOnly(localDealers)..addColumns([countExp]);
    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
  }

  Future<List<LocalDealer>> getInitialDealers({int limit = 50}) {
    return (select(localDealers)..limit(limit)).get();
  }

  // ---------------------------------------------------------------------------
  // 🚀 NEW OFFLINE SYNC METHODS (OUTBOX PATTERN)
  // ---------------------------------------------------------------------------

  Future<void> enqueueOfflineTask({
    required String entityType,
    required Map<String, dynamic> payload,
    List<String>? filePaths,
  }) async {
    final uuid = const Uuid().v4();
    await into(syncQueue).insert(
      SyncQueueCompanion.insert(
        id: uuid,
        entityType: entityType,
        payload: jsonEncode(payload),
        localFiles: Value(filePaths != null ? jsonEncode(filePaths) : null),
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<List<SyncQueueData>> getPendingSyncTasks({int limit = 5}) {
    return (select(syncQueue)
          ..where((t) => t.status.equals('PENDING') | t.status.equals('FAILED'))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
          ])
          ..limit(limit))
        .get();
  }

  Future<void> markSyncTaskComplete(String id) async {
    await (delete(syncQueue)..where((t) => t.id.equals(id))).go();
  }

  Future<void> markSyncTaskFailed(String id, int currentRetries) async {
    await (update(syncQueue)..where((t) => t.id.equals(id))).write(
      SyncQueueCompanion(
        status: const Value('FAILED'),
        retryCount: Value(currentRetries + 1),
      ),
    );
  }

  // 🚀 LOCAL HISTORY INSERT (So offline dashboards work immediately)
  Future<void> createLocalDvr(Map<String, dynamic> data) async {
    final idStr = data['id']?.toString() ?? const Uuid().v4();

    await into(localDailyVisitReports).insert(
      LocalDailyVisitReportsCompanion.insert(
        id: idStr,
        userId: int.tryParse(data['userId']?.toString() ?? '0') ?? 0,
        dealerId: Value(data['dealerId'] as String?),
        subDealerId: Value(data['subDealerId'] as String?),
        reportDate: Value(
          data['reportDate'] != null
              ? DateTime.tryParse(data['reportDate'].toString())
              : null,
        ),
        dealerType: Value(data['dealerType'] as String?),
        location: Value(data['location'] as String?),
        latitude: Value(double.tryParse(data['latitude']?.toString() ?? '')),
        longitude: Value(double.tryParse(data['longitude']?.toString() ?? '')),
        visitType: Value(data['visitType'] as String?),
        dealerTotalPotential: Value(
          double.tryParse(data['dealerTotalPotential']?.toString() ?? ''),
        ),
        dealerBestPotential: Value(
          double.tryParse(data['dealerBestPotential']?.toString() ?? ''),
        ),
        brandSelling: Value(
          data['brandSelling'] != null
              ? jsonEncode(data['brandSelling'])
              : null,
        ),
        contactPerson: Value(data['contactPerson'] as String?),
        contactPersonPhoneNo: Value(data['contactPersonPhoneNo'] as String?),
        todayOrderMt: Value(
          double.tryParse(data['todayOrderMt']?.toString() ?? ''),
        ),
        todayCollectionRupees: Value(
          double.tryParse(data['todayCollectionRupees']?.toString() ?? ''),
        ),
        overdueAmount: Value(
          double.tryParse(data['overdueAmount']?.toString() ?? ''),
        ),
        feedbacks: Value(data['feedbacks'] as String?),
        solutionBySalesperson: Value(data['solutionBySalesperson'] as String?),
        anyRemarks: Value(data['anyRemarks'] as String?),
        checkInTime: Value(
          data['checkInTime'] != null
              ? DateTime.tryParse(data['checkInTime'].toString())
              : null,
        ),
        checkOutTime: Value(
          data['checkOutTime'] != null
              ? DateTime.tryParse(data['checkOutTime'].toString())
              : null,
        ),
        inTimeImageUrl: Value(data['inTimeImageUrl'] as String?),
        outTimeImageUrl: Value(data['outTimeImageUrl'] as String?),
        pjpId: Value(data['pjpId'] as String?),
        dailyTaskId: Value(data['dailyTaskId'] as String?),
        customerType: Value(data['customerType'] as String?),
        partyType: Value(data['partyType'] as String?),
        nameOfParty: Value(data['nameOfParty'] as String?),
        contactNoOfParty: Value(data['contactNoOfParty'] as String?),
        expectedActivationDate: Value(
          data['expectedActivationDate'] != null
              ? DateTime.tryParse(data['expectedActivationDate'].toString())
              : null,
        ),
        idempotencyKey: Value(data['idempotencyKey'] as String?),

        syncStatus: const Value('PENDING'),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  // ---------------------------------------------------------------------------
  // EXISTING JOURNEY HELPERS
  // ---------------------------------------------------------------------------

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

  Future<void> insertBreadcrumb(JourneyBreadcrumbsCompanion crumb) async {
    await into(journeyBreadcrumbs).insert(crumb);
  }

  Future<void> stopLocalJourney(String journeyId, double distance) async {
    await (update(journeys)..where((tbl) => tbl.id.equals(journeyId))).write(
      JourneysCompanion(
        endTime: Value(DateTime.now()),
        totalDistance: Value(distance),
        status: const Value('COMPLETED_UNSYNCED'),
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

  Future<List<Journey>> getUnsyncedJourneys() {
    return (select(
      journeys,
    )..where((tbl) => tbl.status.equals('COMPLETED_UNSYNCED'))).get();
  }

  Future<void> enqueueOp(JourneyOpsQueueCompanion op) async {
    await into(journeyOpsQueue).insert(op);
  }

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
