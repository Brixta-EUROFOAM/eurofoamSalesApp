import 'package:maplibre_gl/maplibre_gl.dart';

class PjpJourneyResult {
  final bool isSite;
  final String displayName;
  final LatLng destination;

  /// Either Dealer or TechnicalSite (opaque to UI)
  final Object entity;

  const PjpJourneyResult({
    required this.isSite,
    required this.displayName,
    required this.destination,
    required this.entity,
  });
}
