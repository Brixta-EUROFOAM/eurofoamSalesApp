import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:salesmanapp/database/app_database.dart';

class JourneyRestoreSnapshot {
  final String journeyId;
  final String? pjpId;
  final int userId;
  final double distance;
  final LatLng? lastPosition;
  final List<LatLng> path;
  final String? displayName;

  JourneyRestoreSnapshot({
    required this.journeyId,
    required this.distance,
    required this.path,
    required this.userId,
    this.pjpId,
    this.lastPosition,
    this.displayName,
  });
}


class JourneyRestoreHelper {
  static Future<JourneyRestoreSnapshot?> getRestorableJourney() async {
    final db = AppDatabase.instance;
    final activeJourney = await db.getActiveJourney();

    if (activeJourney == null) return null;

    // --- DATE CHECK FIX START ---
    // If the active journey is NOT from today, we ignore it.
    final now = DateTime.now();
    final journeyDate = activeJourney.startTime;

    final isToday = journeyDate.year == now.year && 
                    journeyDate.month == now.month && 
                    journeyDate.day == now.day;

    if (!isToday) {
      // It's an old journey. Do not prompt the user to restore.
      return null;
    }
    // --- DATE CHECK FIX END ---

    final crumbs = await db.getBreadcrumbsForJourney(activeJourney.id);

    if (crumbs.isEmpty) {
      return JourneyRestoreSnapshot(
        journeyId: activeJourney.id,
        userId: activeJourney.userId,
        pjpId: activeJourney.pjpId,
        distance: 0,
        path: [],
        lastPosition: null,
        displayName: activeJourney.siteName,
      );
    }

    final last = crumbs.last;

    return JourneyRestoreSnapshot(
      journeyId: activeJourney.id,
      pjpId: activeJourney.pjpId,
      userId: activeJourney.userId,
      distance: last.totalDistance,
      lastPosition: LatLng(last.latitude, last.longitude),
      path: crumbs
          .map((e) => LatLng(e.latitude, e.longitude))
          .toList(),
      displayName: activeJourney.siteName,
    );
  }
}