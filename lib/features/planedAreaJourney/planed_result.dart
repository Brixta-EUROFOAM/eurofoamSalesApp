import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:salesmanapp/models/pjp_model.dart';

class PlannedAreaJourneyResult {
  final Pjp pjp;
  final String displayName;
  final LatLng areaCenter;

  /// Explicitly tells JourneyScreen:
  /// this is not a pinned site/dealer
  final bool isPlannedArea;

  const PlannedAreaJourneyResult({
    required this.pjp,
    required this.displayName,
    required this.areaCenter,
    required this.isPlannedArea,
  });
}
