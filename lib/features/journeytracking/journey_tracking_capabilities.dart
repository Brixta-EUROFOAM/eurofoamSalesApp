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
      // Aligned with the flag used for Kernel registration
      enabled: flags.journeyTracking, 
      // Aligned with specific notification flag
      notifications: flags.journeyNotifications, 
      // Radar tracking is part of the journey tracking feature
      radarTracking: flags.journeyTracking, 
    );
  }
}