import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:salesmanapp/models/pjp_model.dart';
import 'journey_bootstrap_result.dart';

class JourneyBootstrapController {
  JourneyBootstrapResult startPlanned(Pjp pjp) {
    return JourneyBootstrapResult(
      mode: JourneyBootstrapMode.planned,
      pjp: pjp,

      // UI
      displayName: _resolveDisplayName(pjp),

      // 🗺 Planned journeys MUST provide a map anchor
      destination: _deriveAreaCenter(pjp.areaToBeVisited),

      // 🔒 Planned journeys cannot switch mode
      lockMode: true,
    );
  }

  String _resolveDisplayName(Pjp pjp) {
    try {
      return pjp.areaToBeVisited.split('|').first.trim();
    } catch (_) {
      return pjp.areaToBeVisited;
    }
  }

  /// ⚠️ TEMP logic — replace later with Radar / geocoding
LatLng? _deriveAreaCenter(String area) {
    // 1. Try to parse "Name|Lat|Lng" format
    if (area.contains('|')) {
      try {
        final parts = area.split('|');
        if (parts.length >= 3) {
          final lat = double.parse(parts[1]);
          final lng = double.parse(parts[2]);
          return LatLng(lat, lng);
        }
      } catch (e) {
        // Fallthrough on error
      }
    }

    // 2. If it's just a name (Legacy PJP), we can't map it easily.
    // Return null or a default, but at least we tried.
    return null; // Or keep your default: const LatLng(26.1445, 91.7362);
  }
}
