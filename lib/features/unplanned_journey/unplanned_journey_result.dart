import 'package:maplibre_gl/maplibre_gl.dart';

enum UnplannedEntityType {
  site,
  dealer,
  mason,
  mapPoint,
}

class UnplannedJourneyResult {
  final String displayName;
  final LatLng destination;
  final UnplannedEntityType type;

  /// Optional IDs (only one may exist)
  final String? siteId;
  final String? dealerId;
  final String? masonId;

  const UnplannedJourneyResult({
    required this.displayName,
    required this.destination,
    required this.type,
    this.siteId,
    this.dealerId,
    this.masonId,
  });
}
