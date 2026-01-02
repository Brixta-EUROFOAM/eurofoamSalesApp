import 'package:salesmanapp/core/feature_flags/technical_flags.dart';

class UnplannedJourneyCapabilities {
  final bool enabled;

  const UnplannedJourneyCapabilities({required this.enabled});

  factory UnplannedJourneyCapabilities.fromFlags(TechnicalFlags flags) {
    return UnplannedJourneyCapabilities(
      enabled: flags.journey,
    );
  }
}
