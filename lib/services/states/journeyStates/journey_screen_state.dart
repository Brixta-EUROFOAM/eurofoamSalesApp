import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:polyline_codec/polyline_codec.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:salesmanapp/database/app_database.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:salesmanapp/features/journeylocation/journeylocation_results.dart';
import 'package:salesmanapp/features/journeytracking/journey_tracking_controller.dart';
import 'package:salesmanapp/features/JourneyModeController/journey_mode_result.dart'; // For JourneyMode enum
import 'package:salesmanapp/salesSide/models/pjp_model.dart';
import 'package:salesmanapp/salesSide/models/employee_model.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/services/websocket/session_manager.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:salesmanapp/services/journeyFgTaskHandler/journey_task_callbacks.dart';

// -----------------------------------------------------------------------------
// 0️⃣ HELPER LAYER: RESTORE SNAPSHOT
// Purpose: Reads the breadcrumbs from DB to create a restore snapshot.
// -----------------------------------------------------------------------------
class JourneyRestoreSnapshot {
  final String journeyId;
  final String? pjpId;
  final int userId;
  final double distance;
  final LatLng? lastPosition;
  final List<LatLng> path;
  final String? displayName;

  JourneyRestoreSnapshot({
    required this.journeyId,
    required this.distance,
    required this.path,
    required this.userId,
    this.pjpId,
    this.lastPosition,
    this.displayName,
  });
}

class JourneyRestoreHelper {
  static Future<JourneyRestoreSnapshot?> getRestorableJourney() async {
    final db = AppDatabase.instance;
    // 1. Check for any journey that is still 'ACTIVE' in the database
    final activeJourney = await db.getActiveJourney();

    if (activeJourney == null) return null;

    // 2. Fetch all the breadcrumbs (The red line history)
    final crumbs = await db.getBreadcrumbsForJourney(activeJourney.id);

    if (crumbs.isEmpty) {
      return JourneyRestoreSnapshot(
        journeyId: activeJourney.id,
        userId: activeJourney.userId,
        pjpId: activeJourney.pjpId,
        distance: 0,
        path: [],
        lastPosition: null,
        displayName: activeJourney.siteName,
      );
    }

    final last = crumbs.last;

    // 3. Package it for the UI
    return JourneyRestoreSnapshot(
      journeyId: activeJourney.id,
      pjpId: activeJourney.pjpId,
      userId: activeJourney.userId,
      distance: last.totalDistance,
      lastPosition: LatLng(last.latitude, last.longitude),
      path: crumbs.map((e) => LatLng(e.latitude, e.longitude)).toList(),
      displayName: activeJourney.siteName,
    );
  }
}

// -----------------------------------------------------------------------------
// 1️⃣ INTENT LAYER (MAP CONFIGURATION)
// Purpose: "The map style just finished loading. Here are the tools to configure it."
// -----------------------------------------------------------------------------
class MapStyleLoadedIntent {
  final bool isMapEnabled;
  final LatLng? destination;
  final LatLng? currentUserLocation;
  final VoidCallback? onDestinationConsumed;

  // Tools (The "How" - passed from the UI/Widget layer)
  final Future<void> Function(LatLng) drawMarker;
  final Future<LatLng?> Function() determinePosition;
  final Future<void> Function(LatLng start, LatLng end) drawRoute;
  final VoidCallback fitBounds;

  MapStyleLoadedIntent({
    required this.isMapEnabled,
    this.destination,
    this.currentUserLocation,
    this.onDestinationConsumed,
    required this.drawMarker,
    required this.determinePosition,
    required this.drawRoute,
    required this.fitBounds,
  });
}

// -----------------------------------------------------------------------------
// RESTORE JOURNEY INTENT
// Purpose: "I want to check for crashes. Here are the tools, you handle the logic."
// -----------------------------------------------------------------------------
class RestoreJourneyIntent {
  // The only decision the UI makes (Ask the user)
  final Future<bool> Function(JourneyRestoreSnapshot) askUser;

  // Dependencies needed for the Logic (Injected from UI)
  final JourneyTrackingController trackingController;
  final AppDatabase db;

  RestoreJourneyIntent({
    required this.askUser,
    required this.trackingController,
    required this.db,
  });
}

// -----------------------------------------------------------------------------
// 2️⃣ STATE LAYER (MAP CONFIGURATION)
// Purpose: "What is the map initialization doing right now?"
// -----------------------------------------------------------------------------
abstract class MapInitState {}

class MapInitIdle extends MapInitState {}

class MapInitDisabled extends MapInitState {}

class MapInitProcessing extends MapInitState {
  final String statusMessage;
  MapInitProcessing(this.statusMessage);
}

class MapInitReady extends MapInitState {
  final String displayMessage;
  final LatLng? finalUserLocation;

  MapInitReady({required this.displayMessage, this.finalUserLocation});
}

// -----------------------------------------------------------------------------
// 3️⃣ BRAIN (MAP STATE MACHINE)
// Purpose: Orchestrates the flow. No UI widgets here. Just logic.
// -----------------------------------------------------------------------------
class MapInitStateMachine extends ValueNotifier<MapInitState> {
  MapInitStateMachine() : super(MapInitIdle());

  /// 4️⃣ DISPATCH LAYER
  Future<void> dispatch(MapStyleLoadedIntent intent) async {
    if (!intent.isMapEnabled) {
      value = MapInitDisabled();
      return;
    }
    await _handleMapConfiguration(intent);
  }

  /// 5️⃣ BUSINESS LOGIC CORE
  Future<void> _handleMapConfiguration(MapStyleLoadedIntent intent) async {
    value = MapInitProcessing("Configuring Map...");

    try {
      // Step 1: Draw Destination Pointer immediately
      if (intent.destination != null) {
        await intent.drawMarker(intent.destination!);
      }

      // Step 2: Locate User
      value = MapInitProcessing("Locating User...");
      final userLocation = await intent.determinePosition();

      // Step 3: Route Calculation
      if (intent.destination != null && userLocation != null) {
        value = MapInitProcessing("Calculating Route...");

        await Future.delayed(const Duration(milliseconds: 100));
        await intent.drawRoute(userLocation, intent.destination!);
        intent.fitBounds();

        value = MapInitReady(
          displayMessage: "Ready to start",
          finalUserLocation: userLocation,
        );
      } else {
        value = MapInitReady(
          displayMessage: "Location Found",
          finalUserLocation: userLocation,
        );
      }

      intent.onDestinationConsumed?.call();
    } catch (e) {
      debugPrint("⚠️ Map Init Machine Warning: $e");
      value = MapInitReady(displayMessage: "Map Ready");
    }
  }
}

// -----------------------------------------------------------------------------
// RESTORE STATE MACHINE
// Purpose: Handles logic internally. Emits "Resumed" state with data for UI.
// -----------------------------------------------------------------------------
abstract class RestoreJourneyState {}

class RestoreIdle extends RestoreJourneyState {}

class RestoreChecking extends RestoreJourneyState {}

// SUCCESS STATE: Holds the snapshot so UI can rebuild itself
class RestoreResumed extends RestoreJourneyState {
  final JourneyRestoreSnapshot snapshot;
  RestoreResumed(this.snapshot);
}

class RestoreDiscarded extends RestoreJourneyState {}

class RestoreJourneyStateMachine extends ValueNotifier<RestoreJourneyState> {
  RestoreJourneyStateMachine() : super(RestoreIdle());

  Future<void> dispatch(RestoreJourneyIntent intent) async {
    value = RestoreChecking();

    // 1. Logic: Check Database
    final snapshot = await JourneyRestoreHelper.getRestorableJourney();
    if (snapshot == null) {
      value = RestoreIdle();
      return;
    }

    // 2. Logic: Ask User (Delegated to UI implementation)
    final bool shouldResume = await intent.askUser(snapshot);

    if (shouldResume) {
      // 3a. RESUME LOGIC (Executed HERE, not in UI)
      try {
        // Resume the Controller (This ensures breadcrumbs are written to the OLD journey ID)
        await intent.trackingController.resumeJourney(
          journeyId: snapshot.journeyId,
          pjpId: snapshot.pjpId ?? 'N/A',
          destination: snapshot.lastPosition ?? const LatLng(0, 0),
          initialDistance: snapshot.distance,
          lastKnownPosition: snapshot.lastPosition,
        );

        // Start Foreground Notification with restored distance
        await JourneyForegroundNotification.start(
          title: "Journey Resumed",
          subtitle: snapshot.displayName ?? "Tracking...",
          initialDistance: snapshot.distance,
        );

        // Notify UI to rebuild
        value = RestoreResumed(snapshot);
      } catch (e) {
        debugPrint("Resume Failed: $e");
        value = RestoreIdle();
      }
    } else {
      // 3b. DISCARD LOGIC (Executed HERE, not in UI)
      await JourneyLocalLogic.stopJourneyLocal(
        db: intent.db,
        journeyId: snapshot.journeyId,
        totalDistance: snapshot.distance,
        userId: snapshot.userId,
      );
      value = RestoreDiscarded();
    }
  }
}

// -----------------------------------------------------------------------------
// 4️⃣ RENDERER LAYER (THE HANDS)
// Purpose: Handles the dirty MapLibre API calls so the UI doesn't have to.
// -----------------------------------------------------------------------------
class JourneyMapRenderer {
  static Future<void> addDestinationMarker(
    MapLibreMapController controller,
    LatLng point,
  ) async {
    try {
      const sourceId = 'dest-source';
      final geoJson = {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'geometry': {
              'type': 'Point',
              'coordinates': [point.longitude, point.latitude],
            },
            'properties': {},
          },
        ],
      };

      bool sourceExists = true;
      try {
        await controller.setGeoJsonSource(sourceId, geoJson);
      } catch (_) {
        sourceExists = false;
      }

      if (!sourceExists) {
        await controller.addSource(
          sourceId,
          GeojsonSourceProperties(data: geoJson),
        );
        await controller.addCircleLayer(
          sourceId,
          'dest-layer-outer',
          const CircleLayerProperties(
            circleColor: '#FFFFFF',
            circleRadius: 10,
            circleStrokeWidth: 2,
            circleStrokeColor: '#0F172A',
          ),
        );
        await controller.addCircleLayer(
          sourceId,
          'dest-layer-inner',
          const CircleLayerProperties(circleColor: '#EF4444', circleRadius: 6),
        );
      }
    } catch (e) {
      debugPrint("Error updating destination marker: $e");
    }
  }

  static Future<void> drawRoute({
    required MapLibreMapController controller,
    required LatLng start,
    required LatLng end,
    required String apiKey,
  }) async {
    try {
      final startStr = '${start.latitude},${start.longitude}';
      final endStr = '${end.latitude},${end.longitude}';

      final uri = Uri.parse(
        'https://api.radar.io/v1/route/directions?locations=$startStr|$endStr&mode=car&units=metric&geometry=polyline5',
      );

      final response = await http.get(uri, headers: {'Authorization': apiKey});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final geometry = data['routes'][0]['geometry']['polyline'];
          final points = PolylineCodec.decode(geometry);
          final coordinates = points.map((p) => [p[1], p[0]]).toList();

          final geoJson = {
            'type': 'FeatureCollection',
            'features': [
              {
                'type': 'Feature',
                'geometry': {'type': 'LineString', 'coordinates': coordinates},
                'properties': {},
              },
            ],
          };

          const sourceId = 'route-source';
          const layerId = 'route-line';

          bool updatedSuccessfully = false;
          try {
            await controller.setGeoJsonSource(sourceId, geoJson);
            updatedSuccessfully = true;
          } catch (_) {
            updatedSuccessfully = false;
          }

          if (!updatedSuccessfully) {
            try {
              await controller.removeLayer(layerId);
            } catch (_) {}
            try {
              await controller.removeSource(sourceId);
            } catch (_) {}

            await controller.addSource(
              sourceId,
              GeojsonSourceProperties(data: geoJson),
            );
            await controller.addLineLayer(
              sourceId,
              layerId,
              const LineLayerProperties(
                lineColor: '#0B4AA8',
                lineWidth: 5.0,
                lineOpacity: 0.8,
                lineCap: 'round',
                lineJoin: 'round',
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("❌ Renderer Error (drawRoute): $e");
    }
  }

  static Future<void> updateTravelledPath(
    MapLibreMapController controller,
    List<LatLng> path,
  ) async {
    if (path.length < 2) return;

    try {
      final coordinates = path.map((p) => [p.longitude, p.latitude]).toList();

      final geoJson = {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'properties': {},
            'geometry': {'type': 'LineString', 'coordinates': coordinates},
          },
        ],
      };

      const sourceId = 'rt-source';
      const layerId = 'rt-line';
      bool updatedSuccessfully = false;

      try {
        await controller.setGeoJsonSource(sourceId, geoJson);
        updatedSuccessfully = true;
      } catch (_) {
        updatedSuccessfully = false;
      }

      if (!updatedSuccessfully) {
        try {
          await controller.removeLayer(layerId);
        } catch (_) {}
        try {
          await controller.removeSource(sourceId);
        } catch (_) {}

        await controller.addSource(
          sourceId,
          GeojsonSourceProperties(data: geoJson),
        );

        await controller.addLineLayer(
          sourceId,
          layerId,
          const LineLayerProperties(
            lineColor: '#EF4444',
            lineWidth: 6.0,
            lineOpacity: 0.9,
            lineCap: 'round',
            lineJoin: 'round',
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Renderer Error (updateTravelledPath): $e");
    }
  }

  static Future<void> fitBounds(
    MapLibreMapController controller,
    LatLng start,
    LatLng end,
  ) async {
    try {
      final bounds = LatLngBounds(
        southwest: LatLng(
          start.latitude < end.latitude ? start.latitude : end.latitude,
          start.longitude < end.longitude ? start.longitude : end.longitude,
        ),
        northeast: LatLng(
          start.latitude > end.latitude ? start.latitude : end.latitude,
          start.longitude > end.longitude ? start.longitude : end.longitude,
        ),
      );

      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          bounds,
          left: 80,
          top: 80,
          right: 80,
          bottom: 80,
        ),
      );
    } catch (_) {}
  }

  static Future<void> drawUserLocationPointer(
    MapLibreMapController controller,
    LatLng point,
  ) async {
    try {
      final data = {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'properties': {},
            'geometry': {
              'type': 'Point',
              'coordinates': [point.longitude, point.latitude],
            },
          },
        ],
      };

      const sourceId = 'user-loc-s';
      bool updatedSuccessfully = false;

      // 1. Try Update
      try {
        await controller.setGeoJsonSource(sourceId, data);
        updatedSuccessfully = true;
      } catch (_) {
        updatedSuccessfully = false;
      }

      // 2. Add New if update failed
      if (!updatedSuccessfully) {
        await controller.addSource(
          sourceId,
          GeojsonSourceProperties(data: data),
        );
        // Outer White Circle
        await controller.addCircleLayer(
          sourceId,
          'user-loc-c-o',
          const CircleLayerProperties(
            circleColor: '#FFFFFF',
            circleRadius: 12.0,
          ),
        );
        // Inner Blue Dot
        await controller.addCircleLayer(
          sourceId,
          'user-loc-c-i',
          const CircleLayerProperties(
            circleColor: '#0B4AA8',
            circleRadius: 8.0,
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Renderer Error (drawUserLocationPointer): $e");
    }
  }
}

// -----------------------------------------------------------------------------
// 5️⃣ GUARD LAYER (THE SECURITY)
// Purpose: Handles Permissions & Geolocator Logic independently from UI.
// -----------------------------------------------------------------------------
class JourneyPermissionGuard {
  static Future<bool> ensurePermissions({
    required Future<bool> Function() onShowDisclosure,
    required VoidCallback onShowSettings,
    required Function(String) onError,
  }) async {
    bool serviceEnabled;
    LocationPermission permission;

    //  NOTIFICATION PERMISSION (MANDATORY but NON-BLOCKING)
    if (Platform.isAndroid) {
      final notifStatus = await Permission.notification.status;

      if (!notifStatus.isGranted) {
        final granted = await Permission.notification.request();
        if (!granted.isGranted) {
          debugPrint(
            "⚠️ Notification permission denied — background tracking may be limited.",
          );
        }
      }
    }

    // 1. Check Service
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      onError("Location services are disabled. Please enable GPS.");
      return false;
    }

    // 2. Check Permission Status
    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      final bool userAgreed = await onShowDisclosure();

      if (!userAgreed) {
        onError("Location is required to track your journey.");
        return false;
      }

      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        onError("Location permission denied.");
        return false;
      }
    }

    // 3. Handle Permanent Denial
    if (permission == LocationPermission.deniedForever) {
      onShowSettings();
      return false;
    }

    if (permission == LocationPermission.whileInUse) {
      return true;
    }

    return true;
  }
}

// -----------------------------------------------------------------------------
// 6️⃣ LOGIC LAYER (LOCATION LOGIC)
// Purpose: Resolves current location using Guard + AppKernel.
// -----------------------------------------------------------------------------
class JourneyLocationLogic {
  static Future<LatLng?> resolveCurrentLocation({
    required Future<bool> Function() onEnsurePermissions,
    required Future<JourneyLocationResult> Function()
    onFetchLocationFromController,
  }) async {
    final bool hasPermission = await onEnsurePermissions();
    if (!hasPermission) return null;

    try {
      final result = await onFetchLocationFromController();

      if (result.event == JourneyLocationEvent.granted &&
          result.location != null) {
        return result.location;
      }
    } catch (e) {
      debugPrint("❌ Location Logic Error: $e");
    }

    return null;
  }
}

// -----------------------------------------------------------------------------
// 7️⃣ UI HELPERS (DIALOGS)
// Purpose: Reusable dialogs to keep the main UI file clean.
// -----------------------------------------------------------------------------
class JourneyDialogs {
  /// Shows the mandatory location disclosure dialog.
  static Future<bool> showDisclosure({
    required BuildContext context,
    required Color primaryColor,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.map, color: primaryColor),
                const SizedBox(width: 8),
                const Expanded(child: Text("Allow Location Permissions")),
              ],
            ),
            content: const Text(
              "This app collects location data to enable [Salesman Route Tracking] "
              "and [Distance Calculation] even when the app is closed or not in use.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("DENY", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "ACCEPT",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  //Shows the prompt to open system settings for permissions.
  static void showSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Permission Required"),
        content: const Text(
          "Journey tracking requires location permission. Please enable it in Settings.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Geolocator.openAppSettings();
            },
            child: const Text("OPEN SETTINGS"),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 8️⃣ INTENT LAYER (JOURNEY START)
// Purpose: "I want to start a journey. Here is all the data you need."
// =============================================================================
class StartJourneyIntent {
  final Employee employee;
  final LatLng? destinationLocation;
  final String destinationName;
  final bool isSiteVisit;
  final JourneyMode journeyMode;
  final Pjp? currentPjp;
  final LatLng? currentUserLocation;

  // Tools (Dependencies injected from UI)
  final JourneyTrackingController trackingController;
  final ApiService apiService;

  StartJourneyIntent({
    required this.employee,
    required this.destinationLocation,
    required this.destinationName,
    required this.isSiteVisit,
    required this.journeyMode,
    this.currentPjp,
    this.currentUserLocation,
    required this.trackingController,
    required this.apiService,
  });
}

// =============================================================================
// 9️⃣ STATE LAYER (JOURNEY START)
// Purpose: "What step of the startup process are we in?"
// =============================================================================
abstract class JourneyStartState {}

class JourneyStartIdle extends JourneyStartState {}

class JourneyStartProcessing extends JourneyStartState {
  final String
  message; // e.g. "Creating Unplanned Visit...", "Syncing with Server..."
  JourneyStartProcessing(this.message);
}

class JourneyStartFailure extends JourneyStartState {
  final String error;
  JourneyStartFailure(this.error);
}

class JourneyStartSuccess extends JourneyStartState {
  final Pjp pjp;
  final String? geoTrackingDbId;

  JourneyStartSuccess({required this.pjp, required this.geoTrackingDbId});
}

// =============================================================================
// 🔟 BRAIN (STATE MACHINE - JOURNEY START)
// Purpose: Orchestrates the complex sequence of PJP creation, API calls, and Tracking init.
// =============================================================================
class JourneyStartStateMachine extends ValueNotifier<JourneyStartState> {
  JourneyStartStateMachine() : super(JourneyStartIdle());

  Future<void> dispatch(StartJourneyIntent intent) async {
    // 1. Validation Logic
    if (intent.destinationLocation == null) {
      value = JourneyStartFailure("Cannot start: No destination selected.");
      return;
    }

    try {
      Pjp? workingPjp = intent.currentPjp;

      // 2. Unplanned PJP Creation Logic
      if (workingPjp == null && intent.journeyMode == JourneyMode.unplanned) {
        value = JourneyStartProcessing("Creating Unplanned Visit...");
        workingPjp = await JourneyServerLogic.createUnplannedPjp(
          api: intent.apiService,
          employee: intent.employee,
          destName: intent.destinationName,
          destLoc: intent.destinationLocation!,
        );
      }

      if (workingPjp == null) {
        throw Exception("Failed to initialize visit structure.");
      }

      // 3. START LOCAL JOURNEY (Changed from Server Logic)
      value = JourneyStartProcessing("Starting Local Session...");

      // 🔥 STEP A: Create the ID in the Database
      final localJourneyId = await JourneyLocalLogic.startJourneyLocal(
        db: AppDatabase.instance, // Singleton access
        employee: intent.employee,
        pjp: workingPjp,
        isSiteVisit: intent.isSiteVisit,
        destLoc: intent.destinationLocation,
      );

      // 4. Initialize Controller (Pass the Local ID now)
      value = JourneyStartProcessing("Initializing GPS...");

      // 🔥 STEP B: Hand that ID to the Controller so it knows where to write breadcrumbs
      await intent.trackingController.startJourney(
        userId: int.parse(intent.employee.id),
        journeyId: localJourneyId,
        pjp: workingPjp,
        destination: intent.destinationLocation!,
        isSite: intent.isSiteVisit,
      );

      // 5. Start Foreground Service
      await JourneyForegroundNotification.start(
        title: "Journey in progress",
        subtitle: intent.destinationName,
        initialDistance: 0.0,
      );

      // 6. Success
      value = JourneyStartSuccess(
        pjp: workingPjp,
        geoTrackingDbId: localJourneyId, // Stores local UUID now
      );
    } catch (e) {
      value = JourneyStartFailure(e.toString());
    }
  }
}

// =============================================================================
// INTENT LAYER (JOURNEY STOP)
// Purpose: "I want to stop the journey. Here is the data."
// =============================================================================
class StopJourneyIntent {
  final String? geoTrackingDbId;
  final LatLng? currentUserLocation;
  final double totalDistanceTravelled;
  final VoidCallback onCleanup;
  final int userId;

  // Tools
  final ApiService apiService;
  final JourneyTrackingController trackingController;

  StopJourneyIntent({
    required this.geoTrackingDbId,
    required this.currentUserLocation,
    required this.totalDistanceTravelled,
    required this.onCleanup,
    required this.apiService,
    required this.trackingController,
    required this.userId,
  });
}

// =============================================================================
// STATE LAYER (JOURNEY STOP)
// Purpose: "Are we stopping?"
// =============================================================================
abstract class JourneyStopState {}

class JourneyStopIdle extends JourneyStopState {}

class JourneyStopProcessing extends JourneyStopState {}

class JourneyStopSuccess extends JourneyStopState {}

class JourneyStopFailure extends JourneyStopState {
  final String error;
  JourneyStopFailure(this.error);
}

// =============================================================================
// BRAIN (STATE MACHINE - JOURNEY STOP)
// Purpose: Syncs end data with server, stops GPS, triggers cleanup.
// =============================================================================
class JourneyStopStateMachine extends ValueNotifier<JourneyStopState> {
  JourneyStopStateMachine() : super(JourneyStopIdle());

  Future<void> dispatch(StopJourneyIntent intent) async {
    value = JourneyStopProcessing();

    try {
      // 1. Stop Controller (Stops GPS)
      await intent.trackingController.stopJourney();

      // 2. Finalize in Local DB
      if (intent.geoTrackingDbId != null) {
        await JourneyLocalLogic.stopJourneyLocal(
          db: AppDatabase.instance,
          journeyId: intent.geoTrackingDbId!,
          totalDistance: intent.totalDistanceTravelled,
          userId: intent.userId,
        );
      }

      // 3. Success & Cleanup
      value = JourneyStopSuccess();
      intent.onCleanup();
    } catch (e) {
      debugPrint("⚠️ Journey Stop Warning: $e");
      // Even if server fails, we likely still want to stop the local session
      intent.onCleanup();
      value = JourneyStopFailure(e.toString());
    }
  }
}

// =============================================================================
// 1️⃣1️⃣ LOGIC LAYER (SERVER LOGIC)
// Purpose: Handles the dirty JSON/API work for Journey Start & Stop.
// =============================================================================
class JourneyServerLogic {
  static Future<Pjp?> createUnplannedPjp({
    required ApiService api,
    required Employee employee,
    required String destName,
    required LatLng destLoc,
  }) async {
    final employeeId = int.parse(employee.id);

    final newPjp = Pjp(
      id: '', // Server will assign
      planDate: DateTime.now(),
      userId: employeeId,
      createdById: employeeId,
      status: 'APPROVED',
      verificationStatus: 'VERIFIED',
      areaToBeVisited: "$destName|${destLoc.latitude}|${destLoc.longitude}",
      route: destName,
      description: "Unplanned / Ad-hoc Visit",
      plannedNewSiteVisits: 0,
      plannedFollowUpSiteVisits: 0,
      plannedNewDealerVisits: 0,
      plannedInfluencerVisits: 0,
      noOfConvertedBags: 0,
      noOfMasonPcSchemes: 0,
      activityType: 'Unplanned',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return api.createPjp(newPjp);
  }
}

// =============================================================================
// LOCAL JOURNEY LOGIC
// =============================================================================
class JourneyLocalLogic {
  // REPLACES: notifyServerStart (LOCAL FIRST)
  static Future<String> startJourneyLocal({
    required AppDatabase db,
    required Employee employee,
    required Pjp? pjp,
    required bool isSiteVisit,
    required LatLng? destLoc,
  }) async {
    final int uId = int.parse(employee.id);
    final opId = const Uuid().v4();

    await SessionManager.instance.startSession(uId);

    final String? pjpId = pjp?.id;

    String? siteName;
    if (isSiteVisit && pjp?.siteId != null) {
      siteName = "Site: ${pjp!.siteId}";
    } else if (pjp != null) {
      siteName = pjp.areaToBeVisited;
    }

    final journeyId = await db.startLocalJourney(
      userId: uId,
      pjpId: pjpId,
      siteName: siteName,
    );

    await db.enqueueOp(
      JourneyOpsQueueCompanion.insert(
        opId: opId,
        journeyId: journeyId,
        userId: uId,
        type: 'START',
        payload: jsonEncode({
          'appRole': 'TECHNICAL',
          'siteName': pjp?.areaToBeVisited ?? "Unplanned",
          'destLat': destLoc?.latitude,
          'destLng': destLoc?.longitude,
          'pjpId': pjp?.id,
          'siteId': isSiteVisit ? pjp?.siteId : null,
          'dealerId': !isSiteVisit ? pjp?.dealerId : null,
        }),
        createdAt: DateTime.now(),
      ),
    );

    SessionManager.instance.triggerSync();
    return journeyId;
  }

  // REPLACES: notifyServerStop (LOCAL FIRST)
  static Future<void> stopJourneyLocal({
    required AppDatabase db,
    required String journeyId,
    required double totalDistance, // meters from controller
    required int userId,
  }) async {
    await SessionManager.instance.startSession(userId);

    final double distanceInKm = totalDistance / 1000.0;

    // PATCH local DB (single source of truth)
    await db.stopLocalJourney(journeyId, distanceInKm);

    // PATCH payload for server (idempotent)
    await db.enqueueOp(
      JourneyOpsQueueCompanion.insert(
        opId: const Uuid().v4(),
        journeyId: journeyId,
        userId: userId,
        type: 'STOP', // treated as PATCH on server
        payload: jsonEncode({
          'appRole': 'TECHNICAL',
          'status': 'COMPLETED',
          'totalDistance': distanceInKm,
          'endedAt': DateTime.now().toIso8601String(),
        }),
        createdAt: DateTime.now(),
      ),
    );

    // Trigger Sync
    SessionManager.instance.triggerSync();

    // Stop foreground safely
    await JourneyForegroundNotification.stop();
  }
}

// -----------------------------------------------------------------------------
// 🔔 FOREGROUND NOTIFICATION (INLINE, NO EXTRA FILE)
// -----------------------------------------------------------------------------
class JourneyForegroundNotification {
  static Future<void> start({
    required String title,
    required String subtitle,
    double initialDistance = 0.0, // 🆕 Added parameter
  }) async {
    // If running, just update text
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.updateService(
        notificationTitle: title,
        notificationText: subtitle,
      );
      return;
    }

    // 💾 Save the restored distance so the TaskHandler can read it
    await FlutterForegroundTask.saveData(
      key: 'initialDistance',
      value: initialDistance,
    );

    // Start the service
    await FlutterForegroundTask.startService(
      serviceId: 101,
      notificationTitle: title,
      notificationText: subtitle,
      callback: startJourneyTaskCallback,
      serviceTypes: [ForegroundServiceTypes.location],
    );
  }

  static Future<void> update({
    required String title,
    required String subtitle,
  }) async {
    if (!await FlutterForegroundTask.isRunningService) return;

    await FlutterForegroundTask.updateService(
      notificationTitle: title,
      notificationText: subtitle,
    );
  }

  static Future<void> stop() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }
}
