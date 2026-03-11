// lib/services/dvrTimerFgTaskHandler/dvr_timer_callbacks.dart
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'dvr_timer_handler.dart';

@pragma('vm:entry-point')
void startDvrTimerTaskCallback() {
  FlutterForegroundTask.setTaskHandler(DvrTimerHandler());
}