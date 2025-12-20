import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // Singleton Pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // 1. INITIALIZE EVERYTHING
  Future<void> init() async {
    // Request Permission (Critical for iOS)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

 if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('⚠️ User granted provisional permission');
    } else {
      print('❌ User declined or has not accepted permission');
    }

    // Setup Local Notifications for Foreground display
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Ensure icon exists
    const InitializationSettings initSettings = 
        InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(initSettings,
      onDidReceiveNotificationResponse: (response) {
        // Handle click when app is open
        print("🔔 Tapped foreground notification: ${response.payload}");
        // Navigate to screen based on payload...
      },
    );

    // Create the Channel (Required for Android 8+)
    await _createChannel();

    // Listen to Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Foreground Message Received: ${message.notification?.title}');
      _showForegroundNotification(message);
    });
    
    // Listen to Background Clicks (When app opens from notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🚀 App Opened from Notification: ${message.data}');
      // Handle navigation logic here (e.g., go to Bag Lift screen)
    });
  }

  // 2. GET THE TOKEN (The Handshake)
  Future<String?> getFcmToken() async {
    String? token = await _messaging.getToken();
    print("🔥 FCM Token: $token");
    return token;
  }
  Future<void> checkAndRequestPermission() async {
    NotificationSettings settings = await _messaging.getNotificationSettings();

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      // If previously denied, standard request won't work. 
      // We must open phone settings.
      print("⚠️ Permission previously denied. Opening settings...");
      await _messaging.requestPermission(); 
      // Note: On some devices, you might need 'permission_handler' package 
      // to openAppSettings() if this doesn't work.
    } else {
       print("✅ Permissions are already active.");
    }
  }

  // Helper: Create Channel
  Future<void> _createChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // Must match AndroidManifest.xml
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Helper: Show Banner
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            icon: '@mipmap/ic_launcher', // Ensure this icon resource exists
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        payload: message.data['referenceId'], // Pass ID for deep linking
      );
    }
  }
}