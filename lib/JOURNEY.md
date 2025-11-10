Alright Zaheer, you want the deep dive. Here’s the full-fat, zero-filler technical guide for your Journey Tracker. Pin it next to the code and you won’t have to think twice next month when you forget how it works. Again.

# JOURNEY_TRACKER.md

A definitive, end-to-end manual for `EmployeeJourneyScreen`. Covers architecture, lifecycle, state machine, SDK wiring, platform setup, failure modes, and extension hooks. Includes copy-paste code.

---

## 0) TL;DR

* Live GPS stream via Geolocator (1 m filter, high accuracy).
* MapLibre renders tiles (Stadia), one layer for “planned route,” one for “actual route taken.”
* Destination can be typed or injected (`initialJourneyData`).
* Near arrival: local notification at 500 m.
* Arrival detection: periodic `Radar.trackOnce()` + `Radar.onEvents` catching `user.entered_geofence` where `geofence.externalId == pjpId`.
* When journey ends: post **one** `GeoTrackingPoint` summary to backend; mark PJP `completed`.

---

## 1) Public API (Widget Contract)

```dart
class EmployeeJourneyScreen extends StatefulWidget {
  final Employee employee;                        // required
  final Map<String, dynamic>? initialJourneyData; // optional
  final VoidCallback? onDestinationConsumed;      // optional
}
```

### `initialJourneyData` shape

```dart
{
  'pjpId': String,               // Used to match Radar geofence externalId
  'destination': LatLng,         // LatLng(destLat, destLng)
  'displayName': String,         // UI label for destination field
}
```

### Usage patterns

#### Injected destination (from PJP page)

```dart
Navigator.push(context, MaterialPageRoute(
  builder: (_) => EmployeeJourneyScreen(
    employee: employee,
    initialJourneyData: {
      'pjpId': pjp.id,
      'destination': LatLng(dealer.latitude!, dealer.longitude!),
      'displayName': dealer.name,
    },
  ),
));
```

#### Manual destination entry

```dart
Navigator.push(context, MaterialPageRoute(
  builder: (_) => EmployeeJourneyScreen(employee: employee),
));
// User types address -> Radar autocomplete -> route drawn
```

---

## 2) Architecture

### Modules and roles

* **Map**: MapLibre + Stadia raster tiles.
* **GPS**: Geolocator continuous stream (LocationAccuracy.best, distanceFilter=1).
* **Routing**: Radar Directions API (polyline5) for planned route.
* **Arrival**: Radar SDK events + periodic `trackOnce`.
* **Notifications**: Local notifications:

  * Ongoing “Journey in Progress” (Android foreground style).
  * One-shot “Approaching Destination” at 500 m.
* **Persistence**: Final `GeoTrackingPoint` posted once on stop.
* **PJP**: Mark `completed` on arrival/stop if `_currentPjpId` present.

### Data flows

* UI event → state change → map draw
* GPS stream → `_onPositionUpdate` → blue dot + polyline + distance
* Timer(30s) → `Radar.trackOnce()` → `Radar.onEvents()` → arrival → stop

---

## 3) Lifecycle

1. **initState**

   * Set Radar user identity: `Radar.setUserId(employee.id)`, `Radar.setDescription(employee.displayName)`
   * Register `Radar.onEvents` listener.
   * Load style JSON.
   * `await _determinePositionAndMoveCamera()` → move camera to first fix.
   * `_startLocationStream()` continuous updates.
   * If `initialJourneyData` exists, `_processNewJourneyData`.

2. **didUpdateWidget**

   * If parent passes a new `initialJourneyData`, process it and redraw route.

3. **dispose**

   * Cancel GPS stream and arrival timer.
   * Stop journey if active (flush summary).
   * Dispose controllers.

---

## 4) State Machine

```
IDLE
 ├─ set destination (type or injected) → READY
READY
 ├─ slide start → ACTIVE
ACTIVE
 ├─ GPS stream → accumulate distance + render path + notify near arrival
 ├─ Radar.trackOnce (30s) → onEvents → arrival → STOP
 └─ user slides stop → STOP
STOP
 ├─ post final GeoTrackingPoint
 ├─ update PJP to 'completed' (if _currentPjpId != null)
 └─ reset → IDLE
```

---

## 5) Platform Setup

### .env

```
STADIA_API_KEY=your_stadia_key
RADAR_API_KEY=your_radar_publishable_key
```

### Android

`AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>

<application ...>
  <!-- Notification icon is referenced in code as @mipmap/launcher_icon -->
</application>
```

Foreground service style notification is simulated via ongoing local notification. If you need a true Foreground Service, wire it using a plugin; otherwise this is acceptable for most use cases.

### iOS

`Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We use your location to navigate and track your routes.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>We need background location to track your route while navigating.</string>
<key>UIBackgroundModes</key>
<array>
  <string>location</string>
</array>
```

---

## 6) Key Functions and Contracts

### Start journey

```dart
void _startJourney() async {
  // Sets initial point, shows ongoing notification,
  // starts periodic Radar arrival checks every 30s,
  // flips _isJourneyActive = true.
}
```

### Stop journey

```dart
void _stopJourney() async {
  // Cancels timer + notification,
  // posts ONE GeoTrackingPoint (summary),
  // marks PJP completed if active,
  // resets state.
}
```

### Arrival detection

* Periodic: `Radar.trackOnce()` with **no arguments**.
* Listener:

```dart
Radar.onEvents((result) {
  if (!_isJourneyActive || _currentPjpId == null) return;
  final events = result['events'] as List<dynamic>?;
  final arrival = events?.firstWhere(
    (e) => e['type'] == 'user.entered_geofence'
       && e['geofence']?['externalId'] == _currentPjpId,
    orElse: () => null,
  );
  if (arrival != null) _showDestinationArrivalNotification();
});
```

Your backend must upsert Radar geofences with `externalId == PJP_ID`.

### GPS stream handler

```dart
void _onPositionUpdate(Position p) {
  _currentUserLocation = LatLng(p.latitude, p.longitude);

  // UI blue dot
  _drawUserLocationPointer(_currentUserLocation!);

  if (!_isJourneyActive) return;

  // Distance accumulation with jitter filter (2 m)
  if (_lastRecordedPosition != null) {
    final move = Geolocator.distanceBetween(
      _lastRecordedPosition!.latitude, _lastRecordedPosition!.longitude,
      p.latitude, p.longitude,
    );
    if (move > 2) {
      _totalDistanceTravelled += move;
      _lastRecordedPosition = p;
      _routeTaken.add(_currentUserLocation!);
      _updateTravelledPolyline();
    }
  } else {
    _lastRecordedPosition = p;
  }

  // Near-arrival local notification at 500 m
  if (_destinationLocation != null && !_isNearDestinationNotified) {
    final d = Geolocator.distanceBetween(
      p.latitude, p.longitude,
      _destinationLocation!.latitude, _destinationLocation!.longitude,
    );
    if (d < 500) {
      _showNearArrivalNotification();
      _isNearDestinationNotified = true;
    }
  }

  // UI label update
  _originController.text = "Distance: ${(_totalDistanceTravelled/1000).toStringAsFixed(2)} km";
}
```

### Planned route drawing (visual only)

* GET Radar directions with geometry `polyline5`.
* Decode with `polyline_codec`.
* Add MapLibre line layer `route-line`.

---

## 7) Backend Contracts

### Final summary point (one-shot on stop)

`POST /api/geotracking`

```json
{
  "userId": 6,
  "journeyId": "JRN-6-1731222333",
  "latitude": 12.9716,
  "longitude": 77.5946,
  "totalDistanceTravelled": 5432.7,
  "isActive": false,
  "locationType": "FINAL_STOP_SUMMARY"
}
```

### PJP completion

`PATCH /api/pjp/:id`

```json
{ "status": "completed" }
```

### Radar geofence (server responsibility)

* Must exist and use `externalId = pjpId`.
* Your existing dealer/PJP endpoints already upsert dealer geofences. For PJP geofences, mirror the same pattern or ensure your PJP’s target dealer geofence externalId is the PJP id if that’s your logic.

---

## 8) Performance & Battery

* `LocationAccuracy.best` + `distanceFilter=1` is accurate and expensive. If battery is a problem:

  * After drawing initial path, drop to `LocationAccuracy.high` and `distanceFilter=5` or `10`.
  * Increase `Radar.trackOnce()` interval to 60–90 seconds.
* Debounce UI updates if rebuilds become heavy:

  * Throttle `_updateTravelledPolyline()` to every N meters.
* Layer cleanup matters. Always `removeLayer/removeSource` before re-adding.

---

## 9) Testing Matrix

### Functional

* Start journey without destination → blocked with snackBar.
* Injected destination via `initialJourneyData`.
* Route drawn, user moves → polyline extends.
* Near-arrival notification fires at ~500 m.
* Arrival via Radar event → dialog + auto stop + summary POST + PJP complete.
* Manual stop → same finalization.

### Edge

* No GPS permission → shows error, journey cannot start.
* No Radar API key → routes/arrival won’t work; user can still move and draw path, but arrival won’t auto-detect.
* App backgrounded → stream continues as allowed by OS; arrival checks still run if permitted.
* Network unavailable → route fetch fails gracefully; local tracking still works; summary send best-effort.

---

## 10) Error Handling Playbook

| Symptom                              | Likely Cause                                 | Fix                                                                                                        |
| ------------------------------------ | -------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| `trackOnce: 0 expected, but 1 found` | Passing args to `trackOnce`                  | Call `await Radar.trackOnce();` with no args                                                               |
| No arrival event                     | Geofence not present or wrong `externalId`   | Upsert Radar geofence with `externalId == pjpId`                                                           |
| Map blank                            | Bad Stadia key or network                    | Verify `.env`, inspect style JSON in console                                                               |
| Distance is zero                     | Stream not running or jitter filter too high | Check permissions, reduce `movement > 2` to `> 1` for testing                                              |
| Crash on dispose                     | Forgetting to cancel stream/timer            | Already handled: both are cancelled in `dispose`                                                           |
| “Destination not set” on start       | `_destinationLocation` null                  | Provide `initialJourneyData` or type destination                                                           |
| Arrival never auto-stops             | Timer killed by OS                           | Increase interval, ensure background permission, or force stop on 0-speed dwell detection (see Extensions) |

---

## 11) Extension Hooks

* **Dwell-based auto complete:** if speed < 1 m/s for N minutes within 100 m of destination, stop journey without Radar.
* **Mid-journey breadcrumbs upload:** every 30–60 seconds, POST a light point for near-real-time tracking.
* **Multi-stop routes:** maintain a queue; after arrival, pop next destination and continue.
* **Speed analytics:** compute average moving speed, idle time buckets, top detours.

---

## 12) Security & Privacy

* This implementation only sends a single summary record to your backend when stopping. If you decide to stream, document retention windows and get consent in-app. Don’t ship background tracking without explicit opt-in. You’re building a tool, not a surveillance toy.

---

## 13) Sample: Minimal Host Screen

```dart
class JourneyHost extends StatelessWidget {
  final Employee employee;
  final String pjpId;
  final double destLat;
  final double destLng;
  final String label;

  const JourneyHost({
    super.key,
    required this.employee,
    required this.pjpId,
    required this.destLat,
    required this.destLng,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return EmployeeJourneyScreen(
      employee: employee,
      initialJourneyData: {
        'pjpId': pjpId,
        'destination': LatLng(destLat, destLng),
        'displayName': label,
      },
      onDestinationConsumed: () {
        // e.g. collapse sheet or log analytic
      },
    );
  }
}
```

---

## 14) Radar Setup Checklist

* SDK installed and initialized in app.
* Publishable key in `.env` and supplied in native bridges where required (your code uses `flutter_radar` directly).
* Geofences upserted by server with correct `externalId`.
* App calls `Radar.setUserId()` and `Radar.setDescription()` early.
* `Radar.requestPermissions(true)` called at least once with background true.

---

## 15) Known Limitations

* If the OS suspends the Dart timer or kills background work, periodic `trackOnce()` may lag. For mission-critical arrival, use server-side trip monitoring or native foreground services.
* Using Google Maps intent requires the app installed; otherwise handle fallback.

---

## 16) What to change if you want less battery burn

* `LocationAccuracy.high` instead of `best`.
* `distanceFilter: 5 or 10`.
* Arrival check every 60–90 seconds.
* Skip route drawing if you don’t need the pretty line.

---

That’s the book. Print it, frame it, pretend you always knew this. If you follow this doc, your future self won’t be yelling at your past self at 2 a.m.
