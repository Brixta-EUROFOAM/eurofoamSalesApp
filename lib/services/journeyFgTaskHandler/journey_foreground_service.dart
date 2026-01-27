import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'journey_task_callbacks.dart';

class JourneyForegroundService {
  static Future<void> init() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        // 1️⃣ CHANGED ID: This forces Android to create a NEW channel with new settings
        channelId: 'journey_tracking_silent_v1', 
        channelName: 'Journey Tracking',
        channelDescription: 'Tracks active journeys',
        
        // 2️⃣ LOW IMPORTANCE: Updates the text silently (No Beep, No Pop-up)
        channelImportance: NotificationChannelImportance.LOW, 
        priority: NotificationPriority.LOW, 
        
        visibility: NotificationVisibility.VISIBILITY_PUBLIC,
        enableVibration: false,
        playSound: false, // Ensure sound is off
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true, // Usually better to show it on iOS
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<void> start({
    required String title,
    required String subtitle,
    double initialDistance = 0.0, // 🆕 Add this parameter
  }) async {
    // If it's already running, just update the text (Prevents restarting/flickering)
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.updateService(
        notificationTitle: title,
        notificationText: subtitle,
      );
      return;
    }

    // ✅ FIX: Save the data explicitly before starting the service
    await FlutterForegroundTask.saveData(key: 'initialDistance', value: initialDistance);

    await FlutterForegroundTask.startService(
      serviceId: 101,
      notificationTitle: title,
      notificationText: subtitle,
      callback: startJourneyTaskCallback,
      serviceTypes: [ForegroundServiceTypes.location],
      // Removed 'data' parameter to fix the error
    );
  }

  static Future<void> stop() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  static void listen(void Function(Object?) onData) {
    FlutterForegroundTask.addTaskDataCallback(onData);
  }

  static void unlisten(void Function(Object?) onData) {
    FlutterForegroundTask.removeTaskDataCallback(onData);
  }
}