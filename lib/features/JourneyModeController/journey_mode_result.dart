enum JourneyMode {
  planned,
  unplanned,
}

class JourneyModeResult {
  final JourneyMode mode;

  const JourneyModeResult({required this.mode});

  bool get isPlanned => mode == JourneyMode.planned;
  bool get isUnplanned => mode == JourneyMode.unplanned;
}
