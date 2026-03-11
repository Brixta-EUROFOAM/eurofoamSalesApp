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
        eventAction: ForegroundTaskEventAction.repeat(1000), // Fire every 1 second
        autoRunOnBoot: false,
        allowWakeLock: true,
      ),
    );
  }

  static Future<void> start({
    required String title,
    required String subtitle,
    required int checkInTimestampMs,
  }) async {
    if (await FlutterForegroundTask.isRunningService) {
      return;
    }

    // Save the exact check-in time to the background isolate
    await FlutterForegroundTask.saveData(key: 'checkInTimeMs', value: checkInTimestampMs);

    await FlutterForegroundTask.startService(
      serviceId: 102, // Different ID than your GPS journey (101)
      notificationTitle: title,
      notificationText: subtitle,
      callback: startDvrTimerTaskCallback,
    );
  }

  static Future<void> stop() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }
}