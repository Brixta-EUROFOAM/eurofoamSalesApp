// import 'package:geolocator/geolocator.dart';
// import 'package:h3_flutter/h3_flutter.dart';
// import 'package:salesmanapp/database/app_database.dart'; 
// import 'package:drift/drift.dart';
// import 'package:uuid/uuid.dart';

// class H3JourneyService {
//   late H3 _h3;
//   bool _isLibraryLoaded = false;
  
//   // Resolution 10 = ~66m edge. Perfect for vehicle tracking.
//   final int _resolution = 10; 
  
//   String? _lastH3Index;
  
//   Future<void> _ensureLibraryLoaded() async {
//     if (_isLibraryLoaded) return;
//     _h3 = await const H3Factory().load();
//     _isLibraryLoaded = true;
//   }
  
//   Future<void> onLocationUpdate(Position pos, String journeyId, AppDatabase db) async {
//     try {
//       await _ensureLibraryLoaded();

//       // 🟢 FIX: Use 'latLngToCell' instead of 'geoToH3'
//       final BigInt h3BigInt = _h3.latLngToCell(pos.latitude, pos.longitude, _resolution);
//       final String currentH3 = h3BigInt.toRadixString(16);

//       // 2. NOISE FILTER: Only write to DB if we moved to a new Hexagon
//       if (currentH3 != _lastH3Index) {
        
//         await db.into(db.journeyBreadcrumbs).insert(
//           JourneyBreadcrumbsCompanion.insert(
//             id: const Uuid().v4(),
//             journeyId: journeyId,
//             latitude: pos.latitude,
//             longitude: pos.longitude,
//             h3Index: currentH3,
//             speed: Value(pos.speed),
//             heading: Value(pos.heading),
//             accuracy: Value(pos.accuracy),
//             recordedAt: DateTime.now(),
//           )
//         );
        
//         // print("📍 [H3] New Hexagon: $currentH3");
//         _lastH3Index = currentH3;
//       }
//     } catch (e) {
//       print("🚨 H3 Calculation Error: $e");
//     }
//   }
// }