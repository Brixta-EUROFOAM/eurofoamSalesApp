import 'dart:convert';
import 'dart:async'; // Required for Timer/Future.delayed
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// ✅ IMPORT THE SHARED KEY (Crucial for reliable navigation)
import 'package:salesmanapp/navigation_key.dart';

class NotificationService {
  // Singleton Pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // ❌ REMOVED local _navigatorKey. We use the imported 'navigatorKey' directly.

  // ✅ UPDATED INIT: No arguments needed anymore
  Future<void> init() async {
    print("🔔 [NotificationService] Initializing with Shared Key...");

    // Request Permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );
    print('🔔 Permission Status: ${settings.authorizationStatus}');

    // Setup Local Notifications
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher'); 
    const InitializationSettings initSettings = 
        InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // 🪤 TRAP 1: FOREGROUND TAP DETECTED
        print("🪤 [Trap 1] Foreground Notification Tapped!");
        print("   -> Raw Payload: ${response.payload}");

        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            _handleNavigation(data);
          } catch (e) {
            print("❌ [Trap 1 Error] JSON Decode Failed: $e");
          }
        } else {
           print("⚠️ [Trap 1 Warning] Payload was null or empty.");
        }
      },
    );

    await _createChannel();

    // 📩 Listen to Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Foreground Message Received: ${message.notification?.title}');
      
      // 🪤 TRAP 2: INSPECT DATA BEFORE SHOWING
      print("🪤 [Trap 2] Foreground Data Content: ${message.data}");
      
      if (message.data.isEmpty) {
        print("⚠️ [Trap 2 Warning] Data is EMPTY! Backend is likely failing to send the 'data' block.");
      }

      _showForegroundNotification(message);
    });
    
    // 🚀 Listen to Background Taps
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("🪤 [Trap 3] Background/Minimised Tap Detected!");
      print("   -> Data: ${message.data}");
      _handleNavigation(message.data);
    });
    
    // 🚀 Check Terminated State Launch (Cold Start Fix)
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print("❄️ App Launched from TERMINATED state. Data: ${initialMessage.data}");
      // Wait 2 seconds for app to build, then navigate
      Future.delayed(const Duration(seconds: 2), () {
        _handleNavigation(initialMessage.data);
      });
    }
  }

  // --- 🧠 CENTRAL NAVIGATION LOGIC ---
  void _handleNavigation(Map<String, dynamic> data) {
    print("--------------------------------------------------");
    print("🪤 [Trap 5] Handling Navigation Logic...");
    
    // Log all keys
    data.forEach((key, value) => print("   -> Key: '$key', Value: '$value'"));

    final String? type = data['type'];
    final String? id = data['referenceId'] ?? data['id'] ?? data['bagLiftId'] ?? data['data'];

    print("   -> Extracted Type: '$type'");
    print("   -> Extracted ID:   '$id'");

    // ✅ USE THE IMPORTED KEY DIRECTLY
    if (navigatorKey.currentState == null) {
      print("🔥 [Trap 5 Critical] Navigator Key State is NULL! Retrying in 1s...");
      
      // 🔄 AUTO-RETRY LOGIC
      Future.delayed(const Duration(seconds: 1), () {
         if (navigatorKey.currentState != null) {
           print("🔄 Retry Success! Navigating now...");
           _handleNavigation(data);
         } else {
           print("❌ Retry Failed. Navigation aborted.");
         }
      });
      return;
    }

    if (type == 'BAG_LIFT' && id != null) {
      print("🔀 [Trap 5 Success] Valid Match! Pushing Route: /approve_mason_bagLift");
      
      // ✅ USE THE IMPORTED KEY
      navigatorKey.currentState?.pushNamed(
        '/approve_mason_bagLift', 
        arguments: id,
      );
    } else {
      print("⚠️ [Trap 5 Fail] Conditions not met.");
      print("   -> Check: Does Type == 'BAG_LIFT'? ${type == 'BAG_LIFT'}");
      print("   -> Check: Is ID not null? ${id != null}");
    }
    print("--------------------------------------------------");
  }

  Future<String?> getFcmToken() async {
    print("🔍 DEBUG: Starting FCM Token generation request...");
    try {
      String? token = await _messaging.getToken();
      if (token == null) {
        print("❌ DEBUG: Token is NULL.");
      } else {
        print("✅ DEBUG: FCM Token: ${token.substring(0, 20)}...");
      }
      return token;
    } catch (e) {
      print("🔥 DEBUG: Token Gen Error: $e");
      return null;
    }
  }

  Future<void> _createChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      playSound: true,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      // 🪤 TRAP 6: Creating Local Notification
      String payloadData = jsonEncode(message.data);
      
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        payload: payloadData, 
      );
    }
  }
}