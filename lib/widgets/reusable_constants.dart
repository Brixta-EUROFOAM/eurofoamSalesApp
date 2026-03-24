// lib/widgets/reusable_constants.dart
import 'package:firebase_remote_config/firebase_remote_config.dart';

class AppKeys {
  static String get radarApiKey =>
      FirebaseRemoteConfig.instance.getString('RADAR_API_KEY');

  static String get stadiaApiKey =>
      FirebaseRemoteConfig.instance.getString('STADIA_API_KEY');
}