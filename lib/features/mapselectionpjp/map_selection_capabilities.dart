import 'package:salesmanapp/core/feature_flags/technical_flags.dart';

class MapSelectionCapabilities {
  final bool enabled;
  final bool geocodingEnabled;
  final bool areaSearchEnabled; // 🔥 Overpass gate

  const MapSelectionCapabilities({
    required this.enabled,
    required this.geocodingEnabled,
    required this.areaSearchEnabled,
  });

  factory MapSelectionCapabilities.fromFlags(TechnicalFlags flags) {
    return MapSelectionCapabilities(
      enabled: flags.journeyMap,
      geocodingEnabled: flags.journeyTracking,
      areaSearchEnabled: flags.journeyMap, // or its own flag later
    );
  }
}
