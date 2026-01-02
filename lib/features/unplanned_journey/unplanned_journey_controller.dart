import 'package:maplibre_gl/maplibre_gl.dart';
import 'unplanned_journey_result.dart';
import 'unplanned_journey_capabilities.dart';

class UnplannedJourneyController {
  final UnplannedJourneyCapabilities caps;

  UnplannedJourneyController({required this.caps});

  UnplannedJourneyResult startWithMapPoint({
    required LatLng destination,
    required String label,
  }) {
    if (!caps.enabled) {
      throw Exception('Unplanned journey disabled');
    }

    return UnplannedJourneyResult(
      displayName: label,
      destination: destination,
      type: UnplannedEntityType.mapPoint,
    );
  }

  UnplannedJourneyResult startWithDealer({
    required String dealerId,
    required String dealerName,
    required LatLng destination,
  }) {
    return UnplannedJourneyResult(
      displayName: dealerName,
      destination: destination,
      type: UnplannedEntityType.dealer,
      dealerId: dealerId,
    );
  }

  UnplannedJourneyResult startWithSite({
    required String siteId,
    required String siteName,
    required LatLng destination,
  }) {
    return UnplannedJourneyResult(
      displayName: siteName,
      destination: destination,
      type: UnplannedEntityType.site,
      siteId: siteId,
    );
  }
}
