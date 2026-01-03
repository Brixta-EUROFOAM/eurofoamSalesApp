enum JourneyNavigationEvent {
  launched,
  unavailable,
  disabled,
}

class JourneyNavigationResult {
  final JourneyNavigationEvent event;
  final String? message;

  const JourneyNavigationResult({
    required this.event,
    this.message,
  });
}
