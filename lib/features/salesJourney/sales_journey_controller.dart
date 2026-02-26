// lib/features/salesJourney/sales_journey_controller.dart

import 'dart:async';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:salesmanapp/features/salesJourney/sales_journey_capabilities.dart';

enum SalesJourneyEvent {
  started,
  stopped,
  arrived,
  error,
}

class SalesJourneyController {
  final SalesJourneyCapabilities _caps;

  SalesJourneyController({
    required SalesJourneyCapabilities caps,
  }) : _caps = caps;

  SalesJourneyCapabilities get caps => _caps;

  // State
  bool isJourneyActive = false;
  String? currentJourneyId;
  double totalDistance = 0.0;

  // Streams for UI (Distance, Path Drawing, Arrival Events)
  final StreamController<double> _distanceController = StreamController<double>.broadcast();
  final StreamController<LatLng> _positionController = StreamController<LatLng>.broadcast();
  final StreamController<SalesJourneyEvent> _eventController = StreamController<SalesJourneyEvent>.broadcast();

  Stream<double> get distanceStream => _distanceController.stream;
  Stream<LatLng> get positionStream => _positionController.stream;
  Stream<SalesJourneyEvent> get eventStream => _eventController.stream;

  // Used by the State Machine to tell the controller we are active
  void setJourneyActive(String journeyId, double initialDistance) {
    isJourneyActive = true;
    currentJourneyId = journeyId;
    totalDistance = initialDistance;
    _distanceController.add(totalDistance);
    _eventController.add(SalesJourneyEvent.started);
  }

  void setJourneyInactive() {
    isJourneyActive = false;
    currentJourneyId = null;
    totalDistance = 0.0;
    _eventController.add(SalesJourneyEvent.stopped);
  }

  // Used by UI or Background Service to trigger an arrival event
  void triggerArrival() {
    if (!isJourneyActive) return;
    _eventController.add(SalesJourneyEvent.arrived);
  }

  // Used by Background Service or Location Stream to push new points
  void feedNewLocation(LatLng position, double updatedDistance) {
    if (!isJourneyActive) return;
    totalDistance = updatedDistance;
    _distanceController.add(totalDistance);
    _positionController.add(position);
  }

  void dispose() {
    _distanceController.close();
    _positionController.close();
    _eventController.close();
  }
}