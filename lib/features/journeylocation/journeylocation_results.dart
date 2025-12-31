import 'package:maplibre_gl/maplibre_gl.dart';
enum JourneyLocationEvent {
  granted,
  denied,
  error,
}

class JourneyLocationResult {
  final JourneyLocationEvent event;
  final LatLng? location;
  final String? message;

  const JourneyLocationResult({
    required this.event,
    this.location,
    this.message,
  });
}
