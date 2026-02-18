// lib/services/states/taskStates/start_sales_journey.dart

import 'package:salesmanapp/database/app_database.dart';
import 'package:salesmanapp/models/geotracking_data_model.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

class StartSalesJourneyState {
  final ApiService _api = ApiService();
  final AppDatabase _db = AppDatabase.instance;

  Future<String> execute({
    required int userId,
    required String taskId,
    required String displayName, // Dealer Name
    String? dealerId,
    int? verifiedDealerId,
    double? startLat,
    double? startLng,
  }) async {
    // 1. Generate ID
    // We use a consistent ID format so we can track it easily
    final journeyId = "JRN-TASK-$taskId-${DateTime.now().millisecondsSinceEpoch}";

    // 2. Start LOCAL Journey (Offline First)
    await _db.startLocalJourney(
      userId: userId,
      taskId: taskId,
      dealerId: dealerId,
      verifiedDealerId: verifiedDealerId,
      siteName: displayName,
      pjpId: null, // Explicitly null for Sales Tasks
    );

    // 3. Create Payload for Server (Standard GeoTrackingPoint)
    // The server expects 'journeyId' to link breadcrumbs later
    final startPoint = GeoTrackingPoint(
      userId: userId,
      journeyId: journeyId,
      latitude: startLat ?? 0.0,
      longitude: startLng ?? 0.0,
      locationType: 'JOURNEY_START',
      isActive: true,
      // We overload these fields or ensure backend supports them
      dealerId: dealerId, 
      // verifiedDealerId: verifiedDealerId, // Ensure your GeoTrackingPoint model has this or map it
    );

    // 4. Queue for Sync (Outbox Pattern)
    // We don't await the API call here to ensure UI is snappy and works offline
    await _db.enqueueOp(
      JourneyOpsQueueCompanion.insert(
        opId: const Uuid().v4(),
        journeyId: journeyId,
        userId: userId,
        type: 'START',
        payload: jsonEncode(startPoint.toJson()),
        createdAt: DateTime.now(),
      ),
    );

    // 5. Trigger Background Sync (Fire and Forget)
    // SyncWorker.instance.trigger(); 

    return journeyId;
  }
}