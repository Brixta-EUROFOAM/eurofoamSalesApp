import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_radar/flutter_radar.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

// --- WIDGETS & THEMES ---
import 'package:salesmanapp/widgets/app_theme.dart';
import 'package:salesmanapp/widgets/theme_provider.dart';

// --- MODELS & SERVICES ---
import 'package:salesmanapp/models/employee_model.dart';
import 'package:salesmanapp/services/notification_service.dart'; 
import 'package:salesmanapp/api/auth_service.dart'; // ✅ Added for Auto-Login check

// --- SCREENS ---
import 'package:salesmanapp/screens/auth/login_screen.dart';
import 'package:salesmanapp/screens/nav_screen.dart';
import 'package:salesmanapp/screens/app_selector_screen.dart';
import 'package:salesmanapp/technicalSide/screens/technical_nav_screen.dart';
import 'package:salesmanapp/technicalSide/screens/forms/approve_mason_bagLift.dart'; // ✅ Added for Notification Route
import 'package:salesmanapp/navigation_key.dart';
import 'package:firebase_core/firebase_core.dart';

// 1. DEFINE GLOBAL KEY


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  debugPrint("Firebase Initialized Successfully.");

  // 2. PASS KEY TO SERVICE
  await NotificationService().init();
  debugPrint("NOTIFICATIONS INITIALIZED.");

  await dotenv.load(fileName: ".env");
  await Hive.initFlutter();
  
  final radarPublishableKey = dotenv.env['RADAR_API_KEY'];
  if (radarPublishableKey != null) {
    await Radar.initialize(radarPublishableKey);
    debugPrint("Radar SDK Initialized Successfully.");
  } else {
    debugPrint("ERROR: RADAR_PUBLISHABLE_KEY not found in .env file.");
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BEST WORK FORCE',
      
      // 3. ✅ ASSIGN THE KEY HERE (Crucial for Notifications)
      navigatorKey: navigatorKey,

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      initialRoute: '/selector',

      routes: {
        '/selector': (context) => const AppSelectorScreen(),
        '/salesforce_login_page': (context) => const LoginScreen(),
      },
      
      onGenerateRoute: (settings) {
        // --- 1. Existing Salesman App ---
        if (settings.name == '/home') {
          final employee = settings.arguments as Employee;
          return MaterialPageRoute(
            builder: (context) => NavScreen(employee: employee),
          );
        }

        // --- 2. Technical App ---
        if (settings.name == '/technical_home') {
          final employee = settings.arguments as Employee;
          return MaterialPageRoute(
            builder: (context) => TechnicalNavScreen(employee: employee),
          );
        }

        // --- 3. ✅ NEW: Notification Route (Bag Lift Approval) ---
        if (settings.name == '/approve_mason_bagLift') {
          // Get the ID sent from the Notification Payload
          final bagLiftId = settings.arguments as String;

          return MaterialPageRoute(
            builder: (context) {
              // We need the 'Employee' object to build the screen.
              // Fetch it securely from storage (Auto-Login).
              return FutureBuilder<Employee?>(
                future: AuthService().tryAutoLogin(), 
                builder: (context, snapshot) {
                  
                  // A. Waiting for storage...
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  // B. User Found! Open Screen + Auto-Dialog
                  if (snapshot.hasData && snapshot.data != null) {
                    return ApproveMasonBagLift(
                      employee: snapshot.data!, 
                      highlightedId: bagLiftId, // <--- Pass ID to auto-open dialog
                    );
                  }

                  // C. No User (Logged out)? Redirect to Login
                  return const LoginScreen(); 
                },
              );
            },
          );
        }

        return null;
      },
    );
  }
}