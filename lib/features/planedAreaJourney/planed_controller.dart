import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:salesmanapp/salesSide/models/pjp_model.dart';

import 'planed_capabilities.dart';
import 'planed_result.dart';

class PlannedAreaJourneyController {
  final PlannedAreaJourneyCapabilities caps;

  PlannedAreaJourneyController({required this.caps});

  PlannedAreaJourneyResult start(Pjp pjp) {
    if (!caps.enabled) {
      throw Exception('Planned area journey disabled');
    }

    if (pjp.areaToBeVisited.isEmpty) {
      throw Exception('PJP has no area assigned');
    }

    // areaToBeVisited format:
    // Name, Address|lat|lng
    final parts = pjp.areaToBeVisited.split('|');
    if (parts.length < 3) {
      throw Exception('Invalid area format in PJP');
    }

    final displayName = parts[0].trim();
    final lat = double.parse(parts[1]);
    final lng = double.parse(parts[2]);

    return PlannedAreaJourneyResult(
      pjp: pjp,
      displayName: displayName,
      areaCenter: LatLng(lat, lng),
      isPlannedArea: true,
    );
  }
}
