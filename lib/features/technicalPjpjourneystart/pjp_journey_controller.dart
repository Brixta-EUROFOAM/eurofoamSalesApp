import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/models/pjp_model.dart';
import 'package:salesmanapp/models/dealer_model.dart';
import 'package:salesmanapp/technicalSide/models/sites_model.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'pjp_journey_capabilities.dart';
import 'pjp_journey_result.dart';

class PjpJourneyController {
  final ApiService api;
  final PjpJourneyCapabilities caps;

  PjpJourneyController({
    required this.api,
    required this.caps,
  });

  Future<PjpJourneyResult> start(Pjp pjp) async {
    if (!caps.enabled) {
      throw Exception('Journey feature disabled');
    }

    if (pjp.status.toUpperCase() == 'PENDING') {
      throw Exception(
        'Cannot start a Pending plan. Please wait for approval.',
      );
    }

    // --- SITE ---
    if (pjp.siteId != null && pjp.siteId!.isNotEmpty) {
      final TechnicalSite site =
          await api.fetchTechnicalSiteById(pjp.siteId!);

      return PjpJourneyResult(
        isSite: true,
        displayName: site.siteName,
        destination: LatLng(site.latitude, site.longitude),
        entity: site,
      );
    }

    // --- DEALER ---
    if (pjp.dealerId != null && pjp.dealerId!.isNotEmpty) {
      final Dealer dealer =
          await api.fetchDealerById(pjp.dealerId!);

      if (dealer.latitude == null || dealer.longitude == null) {
        throw Exception('Dealer has no location data saved.');
      }

      return PjpJourneyResult(
        isSite: false,
        displayName: dealer.name,
        destination: LatLng(dealer.latitude!, dealer.longitude!),
        entity: dealer,
      );
    }

    throw Exception('Invalid PJP: Missing Site and Dealer');
  }
}
