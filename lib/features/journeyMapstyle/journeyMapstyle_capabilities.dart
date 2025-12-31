import 'package:salesmanapp/core/feature_flags/technical_flags.dart';

class JourneyMapStyleCapabilities {
  final bool enabled;

  const JourneyMapStyleCapabilities({required this.enabled});

  factory JourneyMapStyleCapabilities.fromFlags(
    TechnicalFlags flags,
  ) {
    return JourneyMapStyleCapabilities(
      enabled: flags.journeyMap,
    );
  }
}
