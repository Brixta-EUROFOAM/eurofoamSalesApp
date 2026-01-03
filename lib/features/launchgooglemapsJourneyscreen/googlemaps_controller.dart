import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:salesmanapp/features/launchgooglemapsJourneyscreen/googlemaps_capabilities.dart';
import 'package:salesmanapp/features/launchgooglemapsJourneyscreen/googlemaps_results.dart';

class JourneyNavigationController {
  final JourneyNavigationCapabilities caps;

  JourneyNavigationController({
    required this.caps,
  });

  Future<JourneyNavigationResult> launchGoogleMaps(
    LatLng destination,
  ) async {
    if (!caps.enabled) {
      return const JourneyNavigationResult(
        event: JourneyNavigationEvent.disabled,
        message: 'Navigation disabled',
      );
    }

    final url = Uri.parse(
      'google.navigation:q=${destination.latitude},${destination.longitude}',
    );

    if (!await canLaunchUrl(url)) {
      return const JourneyNavigationResult(
        event: JourneyNavigationEvent.unavailable,
        message: 'Google Maps not available',
      );
    }

    await launchUrl(url);

    return const JourneyNavigationResult(
      event: JourneyNavigationEvent.launched,
    );
  }
}
