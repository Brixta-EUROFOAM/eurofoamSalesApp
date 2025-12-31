import 'package:salesmanapp/core/feature_flags/technical_flags.dart';

class PjpJourneyCapabilities {
  final bool enabled;

  const PjpJourneyCapabilities({required this.enabled});

  factory PjpJourneyCapabilities.fromFlags(TechnicalFlags flags) {
    return PjpJourneyCapabilities(
      enabled: flags.pjpjourney,
    );
  }
}
