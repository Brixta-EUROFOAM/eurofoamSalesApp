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

    // 🔥 UPDATED: Robust Style Definition to prevent "Text-Font" Crashes
    return JourneyMapStyleResult(
      styleJson: jsonEncode({
        "version": 8,
        "name": "Technical Journey Dark",
        
        // 1. CRITICAL: Valid Font Source to prevent renderer crash
        "glyphs": "https://fonts.openmaptiles.org/{fontstack}/{range}.pbf",
        
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
          // 2. SAFETY: Background layer ensures map is never "Shut Off" (Black/Transparent)
          {
            "id": "background",
            "type": "background",
            "paint": {
              "background-color": "#0F172A"
            }
          },
          // 3. TILES: The actual map tiles
          {
            "id": "stadia-layer",
            "source": "stadia",
            "type": "raster",
            "minzoom": 0,
            "maxzoom": 22,
            "paint": {
              "raster-opacity": 1.0,
              "raster-fade-duration": 100
            }
          }
        ]
      }),
    );
  }
}