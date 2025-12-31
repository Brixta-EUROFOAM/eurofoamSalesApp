import 'dart:convert';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:salesmanapp/navigation_key.dart';

/// ===============================================================
/// 🔥 BACKGROUND HANDLER (DO NOT MOVE / DO NOT INLINE)
/// ===============================================================
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  debugPrint("🔔 [FCM BG] Message ID: ${message.messageId}");
  debugPrint("🔔 [FCM BG] Data: ${message.data}");

  if (message.data['action'] == 'logout') {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('force_logout_on_resume', true);
    await prefs.setString(
      'force_logout_message',
      message.data['message'] ??
          'You were signed out because your account was used on another device.',
    );

    // 🧹 Clear session crumbs
    await prefs.remove('jwt_token');
    await prefs.remove('user_id');
    await prefs.remove('is_technical_mode');

    debugPrint("🔐 [FCM BG] Logout flag set successfully");
  }
}

/// ===============================================================
/// 📢 NOTIFICATION SERVICE (Singleton)
/// ===============================================================
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// ===============================================================
  /// 🚀 INIT
  /// ===============================================================
  Future<void> init() async {
    debugPrint("🔔 [NotificationService] Init start");

    // 🔑 REQUIRED: background handler registration
    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );

    // Permissions
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint("🔔 Permission: ${settings.authorizationStatus}");

    // Local notifications init
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint("🪤 [Trap 1] Foreground tap");
        if (response.payload == null || response.payload!.isEmpty) return;

        final data = jsonDecode(response.payload!);
        _handleIncomingData(data);
      },
    );

    await _createChannel();

    /// ===========================================================
    /// 📩 FOREGROUND MESSAGE
    /// ===========================================================
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("📩 Foreground message received");
      debugPrint("   Data: ${message.data}");

      if (_handleLogoutSignal(message.data)) return;

      _showForegroundNotification(message);
    });

    /// ===========================================================
    /// 📩 BACKGROUND TAP
    /// ===========================================================
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("🪤 [Trap 3] Background tap");
      _handleIncomingData(message.data);
    });

    /// ===========================================================
    /// ❄️ TERMINATED / COLD START
    /// ===========================================================
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint("❄️ Cold start message detected");
      Future.delayed(const Duration(seconds: 2), () {
        _handleIncomingData(initialMessage.data);
      });
    }
  }

  /// ===============================================================
  /// 🔐 LOGOUT SIGNAL HANDLER (shared logic)
  /// ===============================================================
  bool _handleLogoutSignal(Map<String, dynamic> data) {
    if (data['action'] != 'logout') return false;

    debugPrint("🚨 Logout signal received (FG/BG)");

    SharedPreferences.getInstance().then((prefs) async {
      await prefs.setBool('force_logout_on_resume', true);
      await prefs.setString(
        'force_logout_message',
        data['message'] ??
            'You were signed out because your account was used on another device.',
      );

      await prefs.remove('jwt_token');
      await prefs.remove('user_id');
      await prefs.remove('is_technical_mode');
    });

    return true; // ⛔ STOP navigation
  }

  /// ===============================================================
  /// 🧠 CENTRAL DATA ROUTER
  /// ===============================================================
  void _handleIncomingData(Map<String, dynamic> data) {
    debugPrint("--------------------------------------------------");
    debugPrint("🪤 Handling incoming data");
    data.forEach((k, v) => debugPrint("   $k : $v"));

    if (_handleLogoutSignal(data)) {
      debugPrint("🔐 Logout handled — navigation aborted");
      return;
    }

    final type = data['type'];
    final id =
        data['referenceId'] ?? data['id'] ?? data['bagLiftId'] ?? data['data'];

    if (navigatorKey.currentState == null) {
      debugPrint("🔥 Navigator null — retrying");
      Future.delayed(const Duration(seconds: 1), () {
        if (navigatorKey.currentState != null) {
          _handleIncomingData(data);
        }
      });
      return;
    }

    if (type == 'BAG_LIFT' && id != null) {
      navigatorKey.currentState!.pushNamed(
        '/approve_mason_bagLift',
        arguments: id,
      );
    }

    debugPrint("--------------------------------------------------");
  }

  /// ===============================================================
  /// 🔔 FOREGROUND NOTIFICATION
  /// ===============================================================
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification == null || android == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// ===============================================================
  /// 🔧 CHANNEL
  /// ===============================================================
  Future<void> _createChannel() async {
    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// ===============================================================
  /// 🪪 TOKEN
  /// ===============================================================
  Future<String?> getFcmToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint("✅ FCM Token: ${token?.substring(0, 20)}...");
      return token;
    } catch (e) {
      debugPrint("🔥 Token error: $e");
      return null;
    }
  }
}
