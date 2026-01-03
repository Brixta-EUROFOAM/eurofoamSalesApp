import 'package:salesmanapp/core/feature_flags/technical_flags.dart';

class PlannedAreaJourneyCapabilities {
  final bool enabled;

  const PlannedAreaJourneyCapabilities({required this.enabled});

  factory PlannedAreaJourneyCapabilities.fromFlags(
    TechnicalFlags flags,
  ) {
    return PlannedAreaJourneyCapabilities(
      enabled: flags.pjpjourney,
    );
  }
}
