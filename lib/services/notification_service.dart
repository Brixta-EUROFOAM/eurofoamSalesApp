import 'dart:convert'; // ✅ Added for jsonEncode/Decode
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart'; // ✅ Added for GlobalKey & Navigator
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // Singleton Pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // ✅ 1. Add a variable to hold the Navigator Key
  GlobalKey<NavigatorState>? _navigatorKey;

  // ✅ 2. Update init to accept the key
  Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey; // Store it for later

    // Request Permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('🔔 Permission Status: ${settings.authorizationStatus}');

    // Setup Local Notifications
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher'); 
    const InitializationSettings initSettings = 
        InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // ✅ 3. Handle Foreground Tap (Local Notification)
        if (response.payload != null) {
          try {
            // We encoded the whole data map as JSON, now we decode it
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            _handleNavigation(data);
          } catch (e) {
            print("❌ Error parsing notification payload: $e");
          }
        }
      },
    );

    await _createChannel();

    // ✅ 4. Listen to Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Foreground Message: ${message.notification?.title}');
      // We pass the whole message so we can encode the 'data' into the payload
      _showForegroundNotification(message);
    });
    
    // ✅ 5. Listen to Background/Terminated Taps
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🚀 App Opened from Background: ${message.data}');
      _handleNavigation(message.data);
    });
    
    // ✅ 6. Check if App was opened from "Terminated" state
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print('🚀 App Launched from Terminated: ${initialMessage.data}');
      _handleNavigation(initialMessage.data);
    }
  }

  // --- 🧠 THE BRAIN: CENTRAL NAVIGATION LOGIC ---
  void _handleNavigation(Map<String, dynamic> data) {
    // Check if the payload contains our specific type
    final String? type = data['type']; // e.g., "BAG_LIFT"
    final String? id = data['referenceId']; // e.g., UUID

    if (type == 'BAG_LIFT' && id != null) {
      print("🔀 Navigating to Bag Lift Details: $id");
      
      // Use the GlobalKey to navigate without context!
      _navigatorKey?.currentState?.pushNamed(
        '/bag_lift_details', // You must define this route in main.dart
        arguments: id,
      );
    } 
    // Add other types here (e.g. "NEW_PJP", "ORDER_APPROVED")
  }
Future<String?> getFcmToken() async {
    print("🔍 DEBUG: Starting FCM Token generation request...");
    
    try {
      // 1. Request the token
      String? token = await _messaging.getToken();
      
      // 2. Analyze the result
      if (token == null) {
        print("❌ DEBUG: Google replied, but the Token is NULL.");
        print("   -> Check: Does your emulator have Google Play Store installed?");
        print("   -> Check: Is google-services.json present in android/app/?");
      } else {
        print("✅ DEBUG: FCM Token GENERATED successfully!");
        print("   -> Token: ${token.substring(0, 20)}..."); // Print first 20 chars
      }
      
      return token;
      
    } catch (e) {
      // 3. Catch crashes (Network issues, Config issues)
      print("🔥 DEBUG: FCM Token Generation CRASHED.");
      print("   -> Error: $e");
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
        // ✅ IMPORTANT: Encode the DATA into the payload string
        payload: jsonEncode(message.data), 
      );
    }
  }
}