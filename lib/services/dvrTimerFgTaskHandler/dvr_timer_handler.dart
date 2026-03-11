// lib/services/dvrTimerFgTaskHandler/dvr_timer_handler.dart
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'dart:async';

class DvrTimerHandler extends TaskHandler {
  int _startTimeMs = 0;

  @override
  void onNotificationPressed() {
    // Bring them back to the DVR screen!
    FlutterForegroundTask.launchApp('/');
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // 1️⃣ Grab the check-in time passed from the UI
    final startData = await FlutterForegroundTask.getData(key: 'checkInTimeMs');
    if (startData != null && startData is int) {
      _startTimeMs = startData;
    } else {
      _startTimeMs = DateTime.now().millisecondsSinceEpoch;
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Calculate exact elapsed time
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = Duration(milliseconds: now - _startTimeMs);

    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = twoDigits(elapsed.inHours);
    final minutes = twoDigits(elapsed.inMinutes.remainder(60));
    final seconds = twoDigits(elapsed.inSeconds.remainder(60));

    final timeString = "$hours:$minutes:$seconds";

    // ONLY update the sticky Android notification to keep the app alive
    FlutterForegroundTask.updateService(
      notificationTitle: "Visit in Progress ⏱️",
      notificationText: "Duration: $timeString",
    );

    // ❌ REMOVE THIS LINE to save massive CPU overhead:
    // FlutterForegroundTask.sendDataToMain(timeString);
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
  @override
  void onReceiveData(Object data) {}
}
