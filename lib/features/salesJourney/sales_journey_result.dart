import 'package:salesmanapp/salesSide/models/dealer_model.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Base abstract class for all Sales Journey States
abstract class SalesJourneyResult {
  const SalesJourneyResult();
}

/// 1. Initial/Idle State (Waiting for user input)
class SalesJourneyIdle extends SalesJourneyResult {
  final String message;
  const SalesJourneyIdle({this.message = "Ready to start"});
}

/// 2. Loading State (Starting/Stopping or Fetching Data)
class SalesJourneyLoading extends SalesJourneyResult {
  final String statusMessage;
  const SalesJourneyLoading(this.statusMessage);
}

/// 3. Active Journey State (Tracking is ON)
class SalesJourneyActive extends SalesJourneyResult {
  final String journeyId;
  final String taskId;
  final Dealer currentDealer;
  final double totalDistance;
  final LatLng? lastKnownLocation;
  final List<LatLng> routePoints;

  const SalesJourneyActive({
    required this.journeyId,
    required this.taskId,
    required this.currentDealer,
    this.totalDistance = 0.0,
    this.lastKnownLocation,
    this.routePoints = const [],
  });
}

/// 4. Error State
class SalesJourneyFailure extends SalesJourneyResult {
  final String error;
  final bool isCritical; // If true, maybe block interaction
  const SalesJourneyFailure(this.error, {this.isCritical = false});
}

/// 5. Success/Completed State (Journey Finished)
class SalesJourneyCompleted extends SalesJourneyResult {
  final String journeyId;
  final double finalDistance;
  final DateTime endTime;

  const SalesJourneyCompleted({
    required this.journeyId,
    required this.finalDistance,
    required this.endTime,
  });
}