// lib/features/salesJourney/sales_journey_controller.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:salesmanapp/database/app_database.dart';
import 'package:salesmanapp/services/journeyFgTaskHandler/journey_foreground_service.dart';
import 'package:salesmanapp/services/states/taskStates/start_sales_journey.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/features/salesJourney/sales_journey_capabilities.dart';

class SalesJourneyController {
  final ApiService _apiService;
  final SalesJourneyCapabilities _caps;
  final AppDatabase _db = AppDatabase.instance;

  SalesJourneyController({
    required ApiService api,
    required SalesJourneyCapabilities caps,
  }) : _apiService = api,
       _caps = caps;

  // State
  bool isJourneyActive = false;
  String? currentJourneyId;
  double totalDistance = 0.0;

  // Streams for UI
  final StreamController<double> _distanceController =
      StreamController<double>.broadcast();
  Stream<double> get distanceStream => _distanceController.stream;

  // 1. INITIALIZE / RESUME
  Future<void> checkActiveJourney() async {
    final active = await _db.getActiveJourney();

    // Check if we have an active journey that belongs to a Task (Sales side)
    if (active != null && active.taskId != null) {
      // We found a crashed/backgrounded Sales Journey
      isJourneyActive = true;
      currentJourneyId = active.id;
      totalDistance = active.totalDistance;
      _distanceController.add(totalDistance);

      await JourneyForegroundService.start(
        title: active.siteName ?? "Active Journey",
        subtitle: "Resuming Tracking...",
        initialDistance: totalDistance,
      );
    }
  }

  // 2. START
  Future<void> startTaskJourney({
    required int userId,
    required String taskId,
    required String displayName,
    String? dealerId,
    int? verifiedDealerId,
  }) async {
    if (!_caps.canStartJourney) {
      throw Exception("Journey start disabled by configuration");
    }

    final pos = await Geolocator.getCurrentPosition();

    // A. Execute Logic (DB + Queue)
    currentJourneyId = await StartSalesJourneyState().execute(
      userId: userId,
      taskId: taskId,
      displayName: displayName,
      dealerId: dealerId,
      verifiedDealerId: verifiedDealerId,
      startLat: pos.latitude,
      startLng: pos.longitude,
    );

    await JourneyForegroundService.start(
      title: displayName,
      subtitle: "Tracking Active",
      initialDistance: 0.0,
    );

    // C. Update Task Status (Online)
    // Backend expects 'In Progress'
    _apiService.updateDailyTaskStatus(taskId, 'In Progress').catchError((e) {
      if (kDebugMode) {
        print("⚠️ Task Status Update Failed (Offline?): $e");
      }
    });

    isJourneyActive = true;
    totalDistance = 0.0;
    _distanceController.add(0.0);
  }

  // 3. STOP
  Future<void> stopTaskJourney(String taskId) async {
    if (!isJourneyActive || currentJourneyId == null) return;

    // A. Stop Local Journey (Drift)
    await _db.stopLocalJourney(currentJourneyId!, totalDistance);

    // B. Stop Foreground Service
    await JourneyForegroundService.stop();

    // ❌ NO TASK API CALL HERE
    // Task completion handled by EmployeePJPScreen

    isJourneyActive = false;
    currentJourneyId = null;
  }

  void dispose() {
    _distanceController.close();
  }
}
