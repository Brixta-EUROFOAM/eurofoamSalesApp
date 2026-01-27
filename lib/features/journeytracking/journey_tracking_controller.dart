import 'dart:async';
//import 'dart:convert';  // breadcrumbs helper
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

// Project Imports
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/models/pjp_model.dart';
import 'package:salesmanapp/services/journeyFgTaskHandler/journey_foreground_service.dart';
import 'journey_tracking_capabilities.dart';
import 'journey_tracking_result.dart';

import 'package:salesmanapp/database/app_database.dart';
import 'package:drift/drift.dart';

class JourneyTrackingController {
  final JourneyTrackingCapabilities caps;
  final FlutterLocalNotificationsPlugin notifications;
  final ApiService api;

  // ------- Local Db --------
  final AppDatabase _db = AppDatabase.instance;
  String? _currentLocalJourneyId;

  // ────────────────── INTERNAL STATE ──────────────────
  bool _isActive = false;
  // String? _currentPjpId;

  //int? _userId;  // breadcrumbs helper
  double _totalDistance = 0.0;
  Position? _lastPosition;

  StreamSubscription<Position>? _positionSubscription;

  // ────────────────── STREAMS (UI READ-ONLY) ──────────────────
  final _distanceStreamController = StreamController<double>.broadcast();
  final _positionStreamController = StreamController<LatLng>.broadcast();
  final _eventStreamController =
      StreamController<JourneyTrackingEvent>.broadcast();

  Stream<double> get distanceStream => _distanceStreamController.stream;
  Stream<LatLng> get positionStream => _positionStreamController.stream;
  Stream<JourneyTrackingEvent> get eventStream => _eventStreamController.stream;
  bool get isActive => _isActive;

  JourneyTrackingController({
    required this.caps,
    required this.notifications,
    required this.api,
  });

  // ────────────────── INIT ──────────────────
  Future<void> initNotifications() async {
    if (!caps.notifications) return;

    const android = AndroidInitializationSettings('@mipmap/launcher_icon');
    await notifications.initialize(
      const InitializationSettings(
        android: android,
        iOS: DarwinInitializationSettings(),
      ),
    );
  }

  Future<void> _tryUpdatePjpOnline(String pjpId) async {
    try {
      await api.updatePjp(pjpId, {'status': 'IN_PROGRESS'});
    } catch (_) {
      // silent — sync worker will fix it
    }
  }

  // ────────────────── START JOURNEY ──────────────────
  Future<JourneyTrackingResult> startJourney({
    required Pjp pjp,
    required int userId,
    required LatLng destination,
    required bool isSite,
    required String journeyId,
    String? siteId,
    String? dealerId,
  }) async {
    if (!caps.enabled) {
      return const JourneyTrackingResult(
        event: JourneyTrackingEvent.error,
        message: 'Journey tracking disabled',
      );
    }

    try {
      Position? initialPos;
      try {
        initialPos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (_) {
        // allow journey to start without initial fix
      }

      _lastPosition = initialPos;
      _totalDistance = 0.0;
      _isActive = true;
      // _currentPjpId = pjp.id;
      _currentLocalJourneyId = journeyId;
      //_userId = userId;   // breadcrumbs helper

      // NON-BLOCKING API CALL
      unawaited(_tryUpdatePjpOnline(pjp.id));

      // 3️⃣ Start live tracking
      _startLivePositionTracking(destination);

      _eventStreamController.add(JourneyTrackingEvent.started);
      return const JourneyTrackingResult(event: JourneyTrackingEvent.started);
    } catch (e) {
      _isActive = false;
      return JourneyTrackingResult(
        event: JourneyTrackingEvent.error,
        message: "GPS Init Failed: $e",
      );
    }
  }

  // ────────────────── STOP JOURNEY ──────────────────
  Future<JourneyTrackingResult> stopJourney() async {
    if (!_isActive) {
      return const JourneyTrackingResult(event: JourneyTrackingEvent.stopped);
    }

    _eventStreamController.add(JourneyTrackingEvent.stopped);
    _cleanup();

    await JourneyForegroundService.stop();

    return const JourneyTrackingResult(event: JourneyTrackingEvent.stopped);
  }

  void _cleanup() {
    _isActive = false;
    // _currentPjpId = null;
    // notifications.cancel(1);
    _positionSubscription?.cancel();
  }

  // ───────────── RESUME TRACKING INCASE OF CRASH ──────────────
  Future<void> resumeJourney({
    required String journeyId,
    required String pjpId,
    required LatLng destination,
    required double initialDistance,
    required LatLng? lastKnownPosition, // 🆕 REQUIRED: The end of the last line
  }) async {
    debugPrint("🔄 Resuming Journey: $journeyId from ${initialDistance}m");

    _isActive = true;
    _currentLocalJourneyId = journeyId;
    // _currentPjpId = pjpId;
    _totalDistance = initialDistance; // RESTORE STATE

    // 🔥 FIX: Reconstruct the last Position object.
    // This ensures the NEXT GPS point calculates distance from HERE,
    // instead of treating the first new point as 0 movement.
    if (lastKnownPosition != null) {
      _lastPosition = Position(
        latitude: lastKnownPosition.latitude,
        longitude: lastKnownPosition.longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }

    // Broadcast immediate update so UI doesn't show 0.00 temporarily
    _distanceStreamController.add(_totalDistance);

    // 1. Re-initialize GPS Stream
    _startLivePositionTracking(destination);

    // 2. Re-initialize Notification (so user knows it's back)
    if (caps.notifications) {
      await _showTrackingNotification();
    }
  }

  // ────────────────── LIVE POSITION + DISTANCE ──────────────────
  void _startLivePositionTracking(LatLng destination) {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: settings).listen((pos) async {
          if (_lastPosition != null) {
            final gap = Geolocator.distanceBetween(
              _lastPosition!.latitude,
              _lastPosition!.longitude,
              pos.latitude,
              pos.longitude,
            );

            // Filter small jitter
            if (gap > 2.0) {
              _totalDistance += gap;
              _distanceStreamController.add(_totalDistance);
            }
          }

          _lastPosition = pos;
          _positionStreamController.add(LatLng(pos.latitude, pos.longitude));

          // Proximity Notification (100m)
          final distToDest = Geolocator.distanceBetween(
            pos.latitude,
            pos.longitude,
            destination.latitude,
            destination.longitude,
          );

          if (distToDest < 100) {
            _showNearArrivalNotification();
          }

          // local db write for tracking journey breadcrumbs
          try {
            await _db.insertBreadcrumb(
              JourneyBreadcrumbsCompanion.insert(
                id: const Uuid().v4(),
                journeyId: _currentLocalJourneyId ?? '',
                latitude: pos.latitude,
                longitude: pos.longitude,
                h3Index: "0", 
                totalDistance: Value(_totalDistance),
                speed: Value(pos.speed),
                heading: Value(pos.heading),
                accuracy: Value(pos.accuracy),
                recordedAt: DateTime.now(),
              ),
            );
          } catch (e) {
            debugPrint("Failed to save breadcrumb: $e");
          }
        });
  }

  // ────────────────── RADAR ──────────────────
  Future<void> onArrival() async {
    _eventStreamController.add(
      JourneyTrackingEvent.arrived,
    ); // Notify UI for Dialog
    await stopJourney();
  }

  // ────────────────── NOTIFICATIONS ──────────────────
  Future<void> _showTrackingNotification() async {
    const android = AndroidNotificationDetails(
      'tracking_channel',
      'Tracking',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
    );

    await notifications.show(
      1,
      'Journey Active',
      'Tracking location...',
      const NotificationDetails(android: android),
    );
  }

  Future<void> _showNearArrivalNotification() async {
    const android = AndroidNotificationDetails(
      'near_arrival_channel',
      'Near Arrival',
      importance: Importance.max,
      priority: Priority.high,
    );

    await notifications.show(
      0,
      'Approaching Destination',
      'You are within 500m.',
      const NotificationDetails(android: android),
    );
  }

  // ────────────────── UTILITIES ──────────────────
  Future<void> launchGoogleMaps(LatLng destination) async {
    final url = Uri.parse(
      'google.navigation:q=${destination.latitude},${destination.longitude}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void dispose() {
    _cleanup();
    _distanceStreamController.close();
    _positionStreamController.close();
    _eventStreamController.close();
  }
}