// lib/services/states/journeyStates/sales_journey_screen_state.dart

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/database/app_database.dart';
import 'package:salesmanapp/features/salesJourney/sales_journey_controller.dart';
import 'package:salesmanapp/services/journeyFgTaskHandler/journey_foreground_service.dart';
import 'package:salesmanapp/services/states/taskStates/start_sales_journey.dart';
import 'package:salesmanapp/services/websocket/session_manager.dart';
import 'package:salesmanapp/salesSide/models/daily_task_model.dart'; // 🚀 Added for DailyTask model
import 'package:salesmanapp/features/JourneyModeController/journey_mode_result.dart'; // 🚀 Added for JourneyMode

// ==========================================
// 1. START JOURNEY STATE MACHINE
// ==========================================

abstract class SalesJourneyStartState {}

class SalesJourneyStartIdle extends SalesJourneyStartState {}

class SalesJourneyStartProcessing extends SalesJourneyStartState {
  final String message;
  SalesJourneyStartProcessing(this.message);
}

class SalesJourneyStartSuccess extends SalesJourneyStartState {
  final String currentJourneyId;
  SalesJourneyStartSuccess(this.currentJourneyId);
}

class SalesJourneyStartFailure extends SalesJourneyStartState {
  final String error;
  SalesJourneyStartFailure(this.error);
}

class StartSalesJourneyIntent {
  final int userId;
  final String? taskId; // 🚀 Made Nullable for Unplanned
  final String displayName;
  final String? dealerId;
  final int? verifiedDealerId;
  final JourneyMode journeyMode; // 🚀 Added to know the state
  final LatLng? destinationLocation; // 🚀 Added for tracking
  final SalesJourneyController trackingController;
  final ApiService apiService;

  StartSalesJourneyIntent({
    required this.userId,
    this.taskId,
    required this.displayName,
    this.dealerId,
    this.verifiedDealerId,
    required this.journeyMode,
    this.destinationLocation,
    required this.trackingController,
    required this.apiService,
  });
}

class SalesJourneyStartStateMachine
    extends ValueNotifier<SalesJourneyStartState> {
  SalesJourneyStartStateMachine() : super(SalesJourneyStartIdle());

  Future<void> dispatch(StartSalesJourneyIntent intent) async {
    value = SalesJourneyStartProcessing("Acquiring GPS signal...");

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String workingTaskId = intent.taskId ?? "";

      // 🚀 UNPLANNED LOGIC: Create a dummy Task on the fly
      if (intent.journeyMode == JourneyMode.unplanned &&
          workingTaskId.isEmpty) {
        value = SalesJourneyStartProcessing("Creating Unplanned Task...");

        final newTask = DailyTask(
          id: const Uuid()
              .v4(), // Generate local ID, backend will replace/accept it
          userId: intent.userId,
          dealerId: intent.dealerId,
          dealerNameSnapshot: intent.displayName,
          taskDate: DateTime.now(),
          status: 'In Progress', // Hardcoded active status
          visitType: 'Unplanned',
        );

        final createdTask = await intent.apiService.createDailyTask(newTask);
        // 🚀 FIX: Safely unwrap the nullable ID, falling back to the local UUID if needed
        workingTaskId = createdTask.id ?? newTask.id ?? "";
      }

      if (workingTaskId.isEmpty) {
        throw Exception("Failed to initialize task tracking ID.");
      }

      value = SalesJourneyStartProcessing("Initializing offline tracking...");

      // 1. Execute DB Insertion (Offline First)
      final currentJourneyId = await StartSalesJourneyState().execute(
        userId: intent.userId,
        taskId: workingTaskId, // Use the resolved ID
        displayName: intent.displayName,
        dealerId: intent.dealerId,
        verifiedDealerId: intent.verifiedDealerId,
        startLat: pos.latitude,
        startLng: pos.longitude,
      );

      // 2. Start Foreground Service
      await JourneyForegroundService.start(
        title: intent.displayName,
        subtitle: "Tracking Active",
        initialDistance: 0.0,
      );

      // 3. Inform Controller to setup Streams
      intent.trackingController.setJourneyActive(currentJourneyId, 0.0);

      // 4. Queue API Update for Planned Tasks (If not Unplanned)
      if (intent.journeyMode == JourneyMode.planned) {
        intent.apiService
            .updateDailyTaskStatus(workingTaskId, 'In Progress')
            .catchError((e) {
              if (kDebugMode) {
                print("⚠️ Task Status Update Failed (Queued for Sync): $e");
              }
            });
      }

      value = SalesJourneyStartSuccess(currentJourneyId);
    } catch (e) {
      value = SalesJourneyStartFailure(e.toString());
    }
  }
}

// ==========================================
// 2. STOP JOURNEY STATE MACHINE (Unchanged)
// ==========================================
class StopSalesJourneyIntent {
  final int userId;
  final String taskId;
  final String currentJourneyId;
  final double totalDistance;
  final VoidCallback onCleanup;
  final List<LatLng> path;
  final SalesJourneyController trackingController;

  StopSalesJourneyIntent({
    required this.userId,
    required this.taskId,
    required this.currentJourneyId,
    required this.totalDistance,
    required this.onCleanup,
    required this.path,
    required this.trackingController,
  });
}

class SalesJourneyStopStateMachine {
  Future<void> dispatch(StopSalesJourneyIntent intent) async {
    try {
      final db = AppDatabase.instance;
      final double distanceInKm = intent.totalDistance / 1000.0;

      await db.stopLocalJourney(intent.currentJourneyId, distanceInKm);

      final stopPayload = {
        'appRole': 'SALES',
        'status': 'COMPLETED',
        'totalDistance': distanceInKm,
        'endedAt': DateTime.now().toIso8601String(),
        'path': intent.path
            .map((p) => {'lat': p.latitude, 'lng': p.longitude})
            .toList(),
      };

      await db.enqueueOp(
        JourneyOpsQueueCompanion.insert(
          opId: const Uuid().v4(),
          journeyId: intent.currentJourneyId,
          userId: intent.userId,
          type: 'STOP',
          payload: jsonEncode(stopPayload), // Sent to local DB!
          createdAt: DateTime.now(),
        ),
      );

      await JourneyForegroundService.stop();
      intent.trackingController.setJourneyInactive();
      intent.onCleanup();

      await SessionManager.instance.startSession(intent.userId);
      SessionManager.instance.triggerSync();
    } catch (e) {
      if (kDebugMode) print("Stop failed: $e");
      intent.onCleanup();
    }
  }
}

// ==========================================
// 3. RESTORE JOURNEY STATE MACHINE (Unchanged)
// ==========================================
class RestoreSalesJourneySnapshot {
  final String journeyId;
  final String taskId;
  final String? displayName;
  final double distance;
  final List<LatLng> path;
  final LatLng? lastPosition;

  RestoreSalesJourneySnapshot({
    required this.journeyId,
    required this.taskId,
    this.displayName,
    required this.distance,
    required this.path,
    this.lastPosition,
  });
}

abstract class RestoreSalesState {}

class RestoreSalesIdle extends RestoreSalesState {}

class RestoreSalesResumed extends RestoreSalesState {
  final RestoreSalesJourneySnapshot snapshot;
  RestoreSalesResumed(this.snapshot);
}

class RestoreSalesJourneyIntent {
  final AppDatabase db;
  final SalesJourneyController trackingController;
  final Future<bool> Function(RestoreSalesJourneySnapshot) askUser;

  RestoreSalesJourneyIntent({
    required this.db,
    required this.trackingController,
    required this.askUser,
  });
}

class RestoreSalesJourneyStateMachine extends ValueNotifier<RestoreSalesState> {
  RestoreSalesJourneyStateMachine() : super(RestoreSalesIdle());

  Future<void> dispatch(RestoreSalesJourneyIntent intent) async {
    try {
      final active = await intent.db.getActiveJourney();

      if (active != null && active.taskId != null) {
        final rawPositions = await intent.db.getBreadcrumbsForJourney(
          active.id,
        );
        final path = rawPositions
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList();
        LatLng? lastPos = path.isNotEmpty ? path.last : null;

        final snapshot = RestoreSalesJourneySnapshot(
          journeyId: active.id,
          taskId: active.taskId!,
          displayName: active.siteName ?? "Active Visit",
          distance: active.totalDistance,
          path: path,
          lastPosition: lastPos,
        );

        final shouldResume = await intent.askUser(snapshot);

        if (shouldResume) {
          intent.trackingController.setJourneyActive(
            active.id,
            active.totalDistance,
          );
          await JourneyForegroundService.start(
            title: snapshot.displayName ?? "Active Journey",
            subtitle: "Resuming Tracking...",
            initialDistance: snapshot.distance,
          );
          value = RestoreSalesResumed(snapshot);
        } else {
          await intent.db.stopLocalJourney(active.id, active.totalDistance);
        }
      }
    } catch (e) {
      if (kDebugMode) print("Restore Check Failed: $e");
    }
  }
}
