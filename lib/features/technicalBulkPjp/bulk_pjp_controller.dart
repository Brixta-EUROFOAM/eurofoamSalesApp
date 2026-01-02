import 'package:salesmanapp/api/api_service.dart';
import 'bulk_pjp_capabilities.dart';
import 'bulk_pjp_results.dart';

class BulkPjpController {
  final ApiService api;
  final BulkPjpCapabilities caps;

  BulkPjpController({required this.api, required this.caps});

  Future<BulkPjpResult> submitBulkPlan({
    required int userId,
    required List<DateTime> selectedDates,
    required List<String> siteIds,
    required List<String> dealerIds,
    required Map<String, int> metrics,
    String? description,
  }) async {
    if (!caps.enabled) {
      throw Exception('Bulk PJP creation is currently disabled.');
    }

    final sortedDates = selectedDates..sort();

    try {
      final response = await api.createBulkPjp(
        userId: userId,
        createdById: userId,
        siteIds: siteIds.isNotEmpty ? siteIds : null,
        dealerIds: dealerIds.isNotEmpty ? dealerIds : null,
        baseDate: sortedDates.first,
        batchSizePerDay: 8, 
        areaToBeVisited: "Bulk Technical Plan",
        description: description,
        plannedNewSiteVisits: metrics['newSites'] ?? 0,
        plannedFollowUpSiteVisits: metrics['followUp'] ?? 0,
        plannedNewDealerVisits: metrics['newDealers'] ?? 0,
        plannedInfluencerVisits: metrics['influencers'] ?? 0,
        noOfConvertedBags: metrics['bags'] ?? 0,
        noOfMasonPcSchemes: metrics['schemes'] ?? 0,
      );

      // Explicitly return the Result object to fix your "Map" error
      return BulkPjpResult(
        success: true,
        message: 'Bulk Technical Plan generated!',
        totalVisitsCreated: response['totalRowsCreated'] ?? 0,
      );
    } catch (e) {
      return BulkPjpResult(success: false, message: e.toString());
    }
  }
}