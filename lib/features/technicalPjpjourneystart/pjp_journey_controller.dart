import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/salesSide/models/pjp_model.dart';
import 'package:salesmanapp/salesSide/models/dealer_model.dart';
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

    // 1. --- SITE (Existing Logic) ---
    if (pjp.siteId != null && pjp.siteId!.isNotEmpty) {
      final TechnicalSite site = await api.fetchTechnicalSiteById(pjp.siteId!);
      return PjpJourneyResult(
        isSite: true,
        displayName: site.siteName,
        destination: LatLng(site.latitude, site.longitude),
        entity: site,
      );
    }

    // 2. --- DEALER (Existing Logic) ---
    if (pjp.dealerId != null && pjp.dealerId!.isNotEmpty) {
      final Dealer dealer = await api.fetchDealerById(pjp.dealerId!);
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

    // 3. --- MAP / PLANNED AREA (New Logic) ---
    // Handles PJPs created via the "Plan Visit" map picker
    // Format expected: "Area Name, Address|Latitude|Longitude"
    if (pjp.areaToBeVisited.contains('|')) {
      try {
        final parts = pjp.areaToBeVisited.split('|');
        if (parts.length >= 3) {
          final name = parts[0].trim();
          final lat = double.parse(parts[1]);
          final lng = double.parse(parts[2]);

          return PjpJourneyResult(
            isSite: false, // Treated as a generic visit
            displayName: name,
            destination: LatLng(lat, lng),
            entity: pjp, // Pass the PJP itself as the entity
          );
        }
      } catch (e) {
        // Fallthrough if parsing fails
        print("Error parsing PJP area: $e");
      }
    }

    // 4. --- FALLBACK ---
    // If we can't determine location, we can't start the journey.
    throw Exception('Invalid PJP: Missing Location Data (Site, Dealer, or Map Coordinates)');
  }
}