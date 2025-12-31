import 'package:salesmanapp/core/feature_flags/technical_flags.dart';

class JourneyLocationCapabilities {
  final bool enabled;

  const JourneyLocationCapabilities({
    required this.enabled,
  });

  factory JourneyLocationCapabilities.fromFlags(
    TechnicalFlags flags,
  ) {
    return JourneyLocationCapabilities(
      enabled: flags.journeyMap || flags.journeyTracking,
    );
  }
}
