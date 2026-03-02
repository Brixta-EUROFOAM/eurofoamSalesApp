// lib/services/journeyFgTaskHandler/journey_foreground_service.dart

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'journey_task_callbacks.dart';

class JourneyForegroundService {
  static Future<void> init() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        // 🚀 CHANGED ID: Forces Android to apply our new premium settings immediately.
        channelId: 'premium_journey_tracking_v2', 
        channelName: 'Active Journey Tracking',
        channelDescription: 'Live distance tracking for your current visit.',
        
        // LOW priority prevents annoying buzzing, but VISIBILITY_PUBLIC puts it on the Lock Screen!
        channelImportance: NotificationChannelImportance.LOW, 
        priority: NotificationPriority.LOW, 
        visibility: NotificationVisibility.VISIBILITY_PUBLIC,
        
        // Adds a "started at" timestamp to the notification
        showWhen: true, 
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true, 
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
    double initialDistance = 0.0, 
  }) async {
    // If it's already running, cleanly update the distance text without flashing the UI
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.updateService(
        notificationTitle: title,
        notificationText: subtitle,
      );
      return;
    }

    // Pass the initial distance into the background isolate
    await FlutterForegroundTask.saveData(key: 'initialDistance', value: initialDistance);

    await FlutterForegroundTask.startService(
      serviceId: 101,
      notificationTitle: title, // e.g., "🎯 Navigating to: Dealer Name"
      notificationText: subtitle, // e.g., "Distance: 1.25 km"
      callback: startJourneyTaskCallback,
      serviceTypes: [ForegroundServiceTypes.location],
    );
  }

  static Future<void> stop() async {
    if (await FlutterForegroundTask.isRunningService) {
      // Gracefully signal the isolate to stop the GPS stream first
      FlutterForegroundTask.sendDataToTask('STOP_GPS');
      await Future.delayed(const Duration(milliseconds: 100));
      // Then kill the service banner
      await FlutterForegroundTask.stopService();
    }
  }

  // 🚀 listen() and unlisten() wrappers DELETED.
  // The UI (employee_journey_screen.dart) now connects directly to FlutterForegroundTask.receivePort!
}