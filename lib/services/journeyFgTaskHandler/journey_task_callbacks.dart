import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'journey_task_handler.dart';

@pragma('vm:entry-point')
void startJourneyTaskCallback() {
  FlutterForegroundTask.setTaskHandler(JourneyTaskHandler());
}
