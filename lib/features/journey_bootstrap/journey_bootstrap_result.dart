import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:salesmanapp/models/pjp_model.dart';

enum JourneyBootstrapMode {
  planned,
  unplanned,
}

class JourneyBootstrapResult {
  final JourneyBootstrapMode mode;
  final Pjp pjp;

  /// Text shown in Journey UI
  final String displayName;

  /// 🗺 Map anchor for planned journeys
  final LatLng? destination;

  /// 🔒 Prevent toggle switching
  final bool lockMode;

  const JourneyBootstrapResult({
    required this.mode,
    required this.pjp,
    required this.displayName,
    required this.destination,
    required this.lockMode,
  });
}
