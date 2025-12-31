import 'package:salesmanapp/core/feature_flags/technical_flags.dart';

class JourneyTrackingCapabilities {
  final bool enabled;
  final bool notifications;
  final bool radarTracking;

  const JourneyTrackingCapabilities({
    required this.enabled,
    required this.notifications,
    required this.radarTracking,
  });

  factory JourneyTrackingCapabilities.fromFlags(TechnicalFlags flags) {
    return JourneyTrackingCapabilities(
      enabled: flags.pjpjourney,
      notifications: flags.pjpjourney,
      radarTracking: flags.pjpjourney,
    );
  }
}
