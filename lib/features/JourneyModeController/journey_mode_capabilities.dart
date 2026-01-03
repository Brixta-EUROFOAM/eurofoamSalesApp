import 'package:salesmanapp/core/feature_flags/technical_flags.dart';

class JourneyModeCapabilities {
  final bool enabled;
  final bool allowUnplanned;

  const JourneyModeCapabilities({
    required this.enabled,
    required this.allowUnplanned,
  });

  factory JourneyModeCapabilities.fromFlags(TechnicalFlags flags) {
    return JourneyModeCapabilities(
      enabled: flags.journey,
      allowUnplanned: flags.unplannedJourney,
    );
  }
}
