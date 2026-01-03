enum JourneyTrackingEvent {
  started,
  arrived,
  stopped,
  permissionDenied,
  error,
}

class JourneyTrackingResult {
  final JourneyTrackingEvent event;
  final String? message;

  const JourneyTrackingResult({
    required this.event,
    this.message,
  });
}
