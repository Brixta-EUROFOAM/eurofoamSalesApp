// lib/services/dvrTimerFgTaskHandler/dvr_timer_foreground_service.dart
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'dvr_timer_callbacks.dart';

class DvrTimerForegroundService {
  static Future<void> init() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'dvr_active_visit_timer_v1',
        channelName: 'Active Dealer Visit',
        channelDescription: 'Tracks how long the salesman stays at a dealer.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        visibility: NotificationVisibility.VISIBILITY_PUBLIC,
        showWhen: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000),
        autoRunOnBoot: false,
        allowWakeLock: true,
      ),
    );
  }

  static Future<void> start({
    required String dvrSessionId, // 🚀 NEW: Link timer to a specific DVR!
    required String title,
    required String subtitle,
    required int checkInTimestampMs,
  }) async {
    final isRunning = await FlutterForegroundTask.isRunningService;
    final currentSession = await FlutterForegroundTask.getData<String>(
      key: 'dvrSessionId',
    );

    if (isRunning && currentSession == dvrSessionId) {
      return; // Already tracking THIS exact form. Do nothing.
    } else if (isRunning) {
      await stop(); // 🚀 ANTI-GLITCH: Kill the old rogue timer before starting the new one!
    }

    // Save the exact check-in time AND the session ID to the background isolate
    await FlutterForegroundTask.saveData(
      key: 'dvrSessionId',
      value: dvrSessionId,
    );
    await FlutterForegroundTask.saveData(
      key: 'checkInTimeMs',
      value: checkInTimestampMs,
    );

    await FlutterForegroundTask.startService(
      serviceId: 102,
      notificationTitle: title,
      notificationText: subtitle,
      callback: startDvrTimerTaskCallback,
    );
  }

  static Future<void> stop() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
    // 🚀 ANTI-GLITCH: Wipe the memory so the next check-in starts totally fresh
    await FlutterForegroundTask.clearAllData();
  }
}
