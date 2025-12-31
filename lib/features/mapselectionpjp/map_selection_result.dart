import 'package:maplibre_gl/maplibre_gl.dart';

class MapSelectionResult {
  final LatLng position;
  final String address;
  final bool isCancelled;

  const MapSelectionResult({
    required this.position,
    required this.address,
    this.isCancelled = false,
  });

  factory MapSelectionResult.cancelled() {
    return const MapSelectionResult(
      position: LatLng(0, 0),
      address: '',
      isCancelled: true,
    );
  }
}
