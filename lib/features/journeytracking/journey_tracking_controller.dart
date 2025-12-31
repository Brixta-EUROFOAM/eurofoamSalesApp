import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:flutter_radar/flutter_radar.dart';
import 'package:url_launcher/url_launcher.dart';

// Project
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/models/pjp_model.dart';
import 'package:salesmanapp/models/geotracking_data_model.dart';

import 'journey_tracking_capabilities.dart';
import 'journey_tracking_result.dart';

class JourneyTrackingController {
  final JourneyTrackingCapabilities caps;
  final FlutterLocalNotificationsPlugin notifications;
  final ApiService api;

  // ────────────────── INTERNAL STATE ──────────────────
  bool _isActive = false;
  String? _currentPjpId;
  String? _dbTrackingRecordId;
  double _totalDistance = 0.0;
  Position? _lastPosition;

  StreamSubscription<Position>? _positionSubscription;

  // ────────────────── STREAMS (UI READ-ONLY) ──────────────────
  final _distanceStreamController = StreamController<double>.broadcast();
  final _positionStreamController = StreamController<LatLng>.broadcast();

  Stream<double> get distanceStream => _distanceStreamController.stream;
  Stream<LatLng> get positionStream => _positionStreamController.stream;
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

  // ────────────────── START JOURNEY ──────────────────
  Future<JourneyTrackingResult> startJourney({
    required Pjp pjp,
    required int userId,
    required LatLng destination,
    required bool isSite,
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
      final initialPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _lastPosition = initialPos;
      _totalDistance = 0.0;
      _isActive = true;
      _currentPjpId = pjp.id;

      // 1️⃣ Create backend tracking record
      final startPoint = GeoTrackingPoint(
        userId: userId,
        journeyId: 'JRN-TECH-$userId-${DateTime.now().millisecondsSinceEpoch}',
        latitude: initialPos.latitude,
        longitude: initialPos.longitude,
        destLat: destination.latitude,
        destLng: destination.longitude,
        siteId: isSite ? siteId : null,
        dealerId: !isSite ? dealerId : null,
        locationType: 'JOURNEY_START',
        isActive: true,
      );

      _dbTrackingRecordId = await api.sendGeoTrackingPoint(startPoint);

      // 2️⃣ Mark PJP IN_PROGRESS
      await api.updatePjp(pjp.id, {'status': 'IN_PROGRESS'});

      // 3️⃣ Start live tracking
      _startLivePositionTracking(destination);

      if (caps.notifications) {
        await _showTrackingNotification();
      }

      if (caps.radarTracking) {
        await Radar.startTracking('responsive');
        _setupRadarListeners();
      }

      return const JourneyTrackingResult(
        event: JourneyTrackingEvent.started,
      );
    } catch (e) {
      _isActive = false;
      return JourneyTrackingResult(
        event: JourneyTrackingEvent.error,
        message: e.toString(),
      );
    }
  }

  // ────────────────── STOP JOURNEY ──────────────────
  Future<JourneyTrackingResult> stopJourney() async {
    if (!_isActive) {
      return const JourneyTrackingResult(
        event: JourneyTrackingEvent.stopped,
      );
    }

    final checkOutTime = DateTime.now();

    try {
      if (_dbTrackingRecordId != null && _lastPosition != null) {
        await api.updateGeoTrackingPoint(_dbTrackingRecordId!, {
          'isActive': false,
          'totalDistanceTravelled':
              (_totalDistance / 1000.0).toStringAsFixed(3),
          'latitude': _lastPosition!.latitude,
          'longitude': _lastPosition!.longitude,
          'locationType': 'JOURNEY_END',
          'checkOutTime': checkOutTime.toIso8601String(),
        });
      }

      if (_currentPjpId != null) {
        await api.updatePjp(_currentPjpId!, {'status': 'COMPLETED'});
      }
    } catch (_) {
      // backend failure should NOT block cleanup
    }

    _isActive = false;
    _currentPjpId = null;
    _dbTrackingRecordId = null;

    await notifications.cancel(1);
    await _positionSubscription?.cancel();
    if (caps.radarTracking) await Radar.stopTracking();

    return const JourneyTrackingResult(
      event: JourneyTrackingEvent.stopped,
    );
  }

  // ────────────────── LIVE POSITION + DISTANCE ──────────────────
  void _startLivePositionTracking(LatLng destination) {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: settings).listen(
      (pos) {
        if (_lastPosition != null) {
          final gap = Geolocator.distanceBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            pos.latitude,
            pos.longitude,
          );

          if (gap > 2.0) {
            _totalDistance += gap;
            _distanceStreamController.add(_totalDistance);
          }
        }

        _lastPosition = pos;
        _positionStreamController
            .add(LatLng(pos.latitude, pos.longitude));

        final distToDest = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          destination.latitude,
          destination.longitude,
        );

        if (distToDest < 500) {
          _showNearArrivalNotification();
        }
      },
    );
  }

  // ────────────────── RADAR ──────────────────
  void _setupRadarListeners() {
    Radar.onEvents((result) {
      if (!_isActive || _currentPjpId == null) return;

      final events = result['events'] as List<dynamic>?;
      final arrival = events?.firstWhere(
        (e) =>
            e['type'] == 'user.entered_geofence' &&
            e['geofence']['externalId'] == _currentPjpId,
        orElse: () => null,
      );

      if (arrival != null) {
        onArrival();
      }
    });
  }

  Future<void> onArrival() async {
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

  Future<String> mapStyle(String apiKey) async {
    return jsonEncode({
      "version": 8,
      "sources": {
        "stadia": {
          "type": "raster",
          "tiles": [
            "https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}@2x.png?api_key=$apiKey"
          ],
          "tileSize": 256
        }
      },
      "layers": [
        {
          "id": "stadia-layer",
          "source": "stadia",
          "type": "raster"
        }
      ]
    });
  }

  void dispose() {
    _distanceStreamController.close();
    _positionStreamController.close();
    _positionSubscription?.cancel();
  }
}
