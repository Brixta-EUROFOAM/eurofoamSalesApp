import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class JourneyTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _posSub;
  double _totalDistance = 0;
  Position? _lastPos;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // 1️⃣ RECOVERY FIX: Read initial distance using getData
    // The library saves the 'data' map you passed in startService.
    // We retrieve it asynchronously here.
    final initialVal = await FlutterForegroundTask.getData(key: 'initialDistance');
    
    if (initialVal != null && initialVal is num) {
      _totalDistance = initialVal.toDouble();
    }

    // 2️⃣ Start Tracking
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high, 
        distanceFilter: 5,
      ),
    ).listen(
      (pos) {
        if (_lastPos != null) {
          final dist = Geolocator.distanceBetween(
            _lastPos!.latitude,
            _lastPos!.longitude,
            pos.latitude,
            pos.longitude,
          );
          _totalDistance += dist;
        }

        _lastPos = pos;

        // 🔔 UPDATE NOTIFICATION (Silent update if channel is LOW)
        FlutterForegroundTask.updateService(
          notificationTitle: "Journey Active",
          notificationText:
              "Distance: ${(_totalDistance / 1000).toStringAsFixed(2)} km",
        );

        // 📡 Send data back to UI
        FlutterForegroundTask.sendDataToMain({
          'lat': pos.latitude,
          'lng': pos.longitude,
          'distance': _totalDistance, // Sends CUMULATIVE distance
        });
      },
      onError: (e) {
        print("⚠️ GPS Error in Background: $e");
      },
    );
  }

  // Listen for the manual kill signal from the Main UI
  @override
  void onReceiveData(Object data) {
    if (data == 'STOP_GPS') {
      _posSub?.cancel();
      _posSub = null;
      print("🛑 Background GPS stream cancelled explicitly via signal.");
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _posSub?.cancel();
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Required by TaskHandler
  }
}