import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:flutter_radar/flutter_radar.dart';

import 'journeylocation_capabilities.dart';
import 'journeylocation_results.dart';

class JourneyLocationController {
  final JourneyLocationCapabilities caps;

  JourneyLocationController({required this.caps});

  Future<JourneyLocationResult> resolveCurrentLocation() async {
    if (!caps.enabled) {
      return const JourneyLocationResult(
        event: JourneyLocationEvent.denied,
        message: 'Location feature disabled',
      );
    }

    try {
      String? status = await Radar.getPermissionsStatus();
      if (status == 'DENIED' || status == 'NOT_DETERMINED') {
        status = await Radar.requestPermissions(true);
      }

      if (status != 'GRANTED_FOREGROUND' &&
          status != 'GRANTED_BACKGROUND') {
        return const JourneyLocationResult(
          event: JourneyLocationEvent.denied,
          message: 'Permission denied',
        );
      }

      final pos = await Geolocator.getCurrentPosition();
      return JourneyLocationResult(
        event: JourneyLocationEvent.granted,
        location: LatLng(pos.latitude, pos.longitude),
      );
    } catch (e) {
      return JourneyLocationResult(
        event: JourneyLocationEvent.error,
        message: e.toString(),
      );
    }
  }
}
