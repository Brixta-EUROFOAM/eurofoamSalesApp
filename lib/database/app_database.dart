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
  
  // 📍 Physics
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  TextColumn get h3Index => text()(); // The Hexagon ID
  
  // 🏎️ Telemetry
  RealColumn get speed => real().nullable()();
  RealColumn get heading => real().nullable()();
  RealColumn get accuracy => real().nullable()();
  DateTimeColumn get recordedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Journeys, JourneyBreadcrumbs])
class AppDatabase extends _$AppDatabase {
  // Singleton pattern for global access
  static final AppDatabase _instance = AppDatabase();
  static AppDatabase get instance => _instance;

  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
  
  // 🚀 HELPERS
  Future<String> createJourney(int userId, String? pjpId, String? siteName) async {
    final id = const Uuid().v4();
    await into(journeys).insert(JourneysCompanion.insert(
      id: id,
      userId: userId,
      pjpId: Value(pjpId),
      siteName: Value(siteName),
      startTime: DateTime.now(),
      status: const Value('ACTIVE'),
    ));
    return id;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'salesman_core.sqlite'));
    return NativeDatabase(file, logStatements: true);
  });
}