import 'package:salesmanapp/core/feature_flags/sales_flags.dart';

class SalesJourneyCapabilities {
  final bool canStartJourney;
  final bool canStopJourney;
  final bool canViewMap;
  final bool backgroundTrackingEnabled;

  const SalesJourneyCapabilities({
    required this.canStartJourney,
    required this.canStopJourney,
    required this.canViewMap,
    required this.backgroundTrackingEnabled,
  });

  factory SalesJourneyCapabilities.fromFlags(SalesFlags flags) {
    return SalesJourneyCapabilities(
      // Reuse existing journey flags or add specific ones if needed
      canStartJourney: flags.journey,
      canStopJourney: flags.journey,
      canViewMap: flags.journey,
      backgroundTrackingEnabled: flags.journey,
    );
  }

  // Default fallback for development
  factory SalesJourneyCapabilities.enabled() {
    return const SalesJourneyCapabilities(
      canStartJourney: true,
      canStopJourney: true,
      canViewMap: true,
      backgroundTrackingEnabled: true,
    );
  }
}