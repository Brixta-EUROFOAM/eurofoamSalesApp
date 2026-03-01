// lib/services/journeyFgTaskHandler/journey_task_handler.dart

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class JourneyTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _posSub;
  double _totalDistance = 0;
  Position? _lastPos;

  @override
  void onNotificationPressed() {
    // Tapping the notification body brings the user directly back to the app!
    FlutterForegroundTask.launchApp('/');
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // 1️⃣ RECOVERY FIX: Read initial distance using getData
    final initialVal = await FlutterForegroundTask.getData(key: 'initialDistance');
    if (initialVal != null && initialVal is num) {
      _totalDistance = initialVal.toDouble();
    }

    // 2️⃣ INSTANT PULSE: Get current position immediately
    try {
      _lastPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best, // 🚀 UPGRADED to BEST
      );
      if (_lastPos != null) _emitToMain(_lastPos!);
    } catch (e) {
      print("⚠️ Initial GPS lock failed: $e");
    }

    // 3️⃣ START TRACKING (Battery & Accuracy Optimized)
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best, // 🚀 UPGRADED to BEST
        distanceFilter: 5, // Only trigger if moved 5 meters
      ),
    ).listen(
      (pos) {
        // ==========================================
        // 🛡️ THE ENTERPRISE ACCURACY SHIELD 🛡️
        // ==========================================
        
        // 1. Anti-Cheat: Reject Fake GPS apps
        if (pos.isMocked) {
          print("🚨 FAKE GPS DETECTED: Ignoring mocked coordinate.");
          return; 
        }

        //2. Anti-Jitter: Reject bad satellite signals
        //If the GPS is only "guessing" within a 25m radius (like indoors), 
        //DO NOT add it to the distance. Wait for a clear signal.
        if (pos.accuracy > 25.0) {
          print("⚠️ POOR GPS SIGNAL (${pos.accuracy}m): Ignoring coordinate to prevent ghost distance.");
          return;
        }

        // ==========================================

        if (_lastPos != null) {
          final dist = Geolocator.distanceBetween(
            _lastPos!.latitude,
            _lastPos!.longitude,
            pos.latitude,
            pos.longitude,
          );
          
          // Final sanity check: if the distance jump is insanely large (e.g. > 1000m in a few seconds), 
          // it's a device glitch. Cap it.
          if (dist < 1000) {
            _totalDistance += dist;
          }
        }

        _lastPos = pos;
        _emitToMain(pos);
      },
      onError: (e) => print("⚠️ GPS Error in Background: $e"),
    );
  }

  // 🔥 Helper to safely structure data for Isolate boundary
  void _emitToMain(Position pos) {
    FlutterForegroundTask.updateService(
      notificationTitle: "Journey Active",
      notificationText: "Distance: ${(_totalDistance / 1000).toStringAsFixed(2)} km",
    );

    FlutterForegroundTask.sendDataToMain({
      'lat': pos.latitude,
      'lng': pos.longitude,
      'distance': _totalDistance, 
    });
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
  void onRepeatEvent(DateTime timestamp) {
    // Required by TaskHandler
  }
}