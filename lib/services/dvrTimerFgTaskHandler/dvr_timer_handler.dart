// lib/services/dvrTimerFgTaskHandler/dvr_timer_handler.dart
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'dart:async';

class DvrTimerHandler extends TaskHandler {
  // 🚀 FIX: Default to NOW instead of 0 to prevent the "1970 glitch"
  int _startTimeMs = DateTime.now().millisecondsSinceEpoch;

  @override
  void onNotificationPressed() {
    // Bring them back to the app
    FlutterForegroundTask.launchApp('/');
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // 1️⃣ Grab the exact check-in time passed from the UI
    final startData = await FlutterForegroundTask.getData<int>(key: 'checkInTimeMs');
    
    if (startData != null) {
      _startTimeMs = startData;
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Calculate exact elapsed time based on the absolute timestamp
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = Duration(milliseconds: now - _startTimeMs);

    // Optimized string formatting
    final hours = elapsed.inHours.toString().padLeft(2, '0');
    final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');

    final timeString = "$hours:$minutes:$seconds";

    // ONLY update the sticky Android/iOS notification to keep the OS happy
    FlutterForegroundTask.updateService(
      notificationTitle: "Visit in Progress ⏱️",
      notificationText: "Duration: $timeString",
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
  
  @override
  void onReceiveData(Object data) {}
}