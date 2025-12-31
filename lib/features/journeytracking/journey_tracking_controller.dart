import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:flutter_radar/flutter_radar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'journey_tracking_capabilities.dart';
import 'journey_tracking_result.dart';

class JourneyTrackingController {
  final JourneyTrackingCapabilities caps;
  final FlutterLocalNotificationsPlugin notifications;

  bool _isActive = false;
  String? _currentPjpId;

  JourneyTrackingController({
    required this.caps,
    required this.notifications,
  });

  /// 🔔 Init notifications
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

  /// ▶ Start journey
  Future<JourneyTrackingResult> startJourney(String pjpId) async {
    if (!caps.enabled) {
      return const JourneyTrackingResult(
        event: JourneyTrackingEvent.error,
        message: 'Journey tracking disabled',
      );
    }

    _isActive = true;
    _currentPjpId = pjpId;

    if (caps.notifications) {
      await _showTrackingNotification();
    }

    if (caps.radarTracking) {
      _setupRadarListeners();
    }

    return const JourneyTrackingResult(event: JourneyTrackingEvent.started);
  }

  /// ⏹ Stop journey
  Future<JourneyTrackingResult> stopJourney() async {
    _isActive = false;
    _currentPjpId = null;
    await notifications.cancel(1);

    return const JourneyTrackingResult(event: JourneyTrackingEvent.stopped);
  }

  /// 📍 Arrival detected
  Future<JourneyTrackingResult> onArrival() async {
    if (!_isActive) {
      return const JourneyTrackingResult(
        event: JourneyTrackingEvent.error,
        message: 'Journey not active',
      );
    }

    await stopJourney();

    return const JourneyTrackingResult(
      event: JourneyTrackingEvent.arrived,
      message: 'You have arrived',
    );
  }

  /// 🧭 Radar listeners
  void _setupRadarListeners() {
    Radar.onEvents((result) {
      if (!_isActive || _currentPjpId == null) return;

      final events = result['events'] as List<dynamic>?;
      if (events == null) return;

      final arrival = events.firstWhere(
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

  /// 📢 Notifications
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

  /// 🗺 External navigation
  Future<void> launchGoogleMaps(LatLng destination) async {
    final url = Uri.parse(
      'google.navigation:q=${destination.latitude},${destination.longitude}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  /// 📍 Permission + location
  Future<LatLng?> getCurrentLocation() async {
    final status = await Radar.getPermissionsStatus();
    if (status != 'GRANTED_FOREGROUND' &&
        status != 'GRANTED_BACKGROUND') {
      return null;
    }

    final pos = await Geolocator.getCurrentPosition();
    return LatLng(pos.latitude, pos.longitude);
  }

  /// 🎨 Map style
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
}
