import 'journey_mode_capabilities.dart';
import 'journey_mode_result.dart';

class JourneyModeController {
  final JourneyModeCapabilities caps;

  JourneyModeController({required this.caps});

  JourneyModeResult defaultMode({required bool hasPjp}) {
    if (!caps.enabled) {
      throw Exception('Journey feature disabled');
    }

    if (hasPjp) {
      return const JourneyModeResult(mode: JourneyMode.planned);
    }

    if (caps.allowUnplanned) {
      return const JourneyModeResult(mode: JourneyMode.unplanned);
    }

    throw Exception('Unplanned journeys not allowed');
  }

  JourneyModeResult switchMode(JourneyMode current) {
    if (!caps.allowUnplanned) {
      return const JourneyModeResult(mode: JourneyMode.planned);
    }

    return JourneyModeResult(
      mode: current == JourneyMode.planned
          ? JourneyMode.unplanned
          : JourneyMode.planned,
    );
  }
}
