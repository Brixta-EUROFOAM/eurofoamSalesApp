import 'dart:convert';
import 'journeyMapstyle_capabilities.dart';
import 'journeyMapstyle_results.dart';

class JourneyMapStyleController {
  final JourneyMapStyleCapabilities caps;

  JourneyMapStyleController({required this.caps});

  JourneyMapStyleResult loadStyle(String apiKey) {
    if (!caps.enabled) {
      throw Exception('Map style disabled');
    }

    return JourneyMapStyleResult(
      styleJson: jsonEncode({
        "version": 8,
        "sources": {
          "stadia": {
            "type": "raster",
            "tiles": [
              "https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}@2x.png?api_key=$apiKey"
            ],
            "tileSize": 256
          }
        },
        "layers": [
          {
            "id": "stadia-layer",
            "source": "stadia",
            "type": "raster",
            "minzoom": 0,
            "maxzoom": 22
          }
        ]
      }),
    );
  }
}
