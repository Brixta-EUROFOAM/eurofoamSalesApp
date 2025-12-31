import 'package:salesmanapp/core/feature_flags/technical_flags.dart';

class JourneyNavigationCapabilities {
  final bool enabled;

  const JourneyNavigationCapabilities({
    required this.enabled,
  });

  factory JourneyNavigationCapabilities.fromFlags(
    TechnicalFlags flags,
  ) {
    return JourneyNavigationCapabilities(
      enabled: flags.journeyMap, // or new flag later
    );
  }
}
