import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_radar/flutter_radar.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salesmanapp/core/feature_flags/technical_flags.dart';


// --- WIDGETS & THEMES ---
import 'package:salesmanapp/widgets/app_theme.dart';
import 'package:salesmanapp/widgets/theme_provider.dart';

// --- MODELS & SERVICES ---
import 'package:salesmanapp/models/employee_model.dart';
import 'package:salesmanapp/services/notification_service.dart';
import 'package:salesmanapp/api/auth_service.dart';
import 'package:salesmanapp/services/update_service.dart'; // <--- IMPORT YOUR UpdateService

// --- SCREENS ---
import 'package:salesmanapp/screens/auth/login_screen.dart';
import 'package:salesmanapp/screens/nav_screen.dart';
import 'package:salesmanapp/screens/app_selector_screen.dart';
import 'package:salesmanapp/technicalSide/screens/technical_nav_screen.dart';
import 'package:salesmanapp/technicalSide/screens/forms/approve_mason_bagLift.dart';
// Assuming this defines navigatorKey
import 'package:firebase_core/firebase_core.dart';

// 1. DEFINE GLOBAL KEY FOR NAVIGATOR
// We'll use this to get a BuildContext that's always under MaterialApp.
final GlobalKey<NavigatorState> globalNavigatorKey =
    GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  debugPrint("Firebase Initialized Successfully.");

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
  MultiProvider(
    providers: [
      // 🔥 FEATURE FLAGS (control plane)
      Provider<TechnicalFlags>.value(
        value: TechnicalFlags.dev,
      ),

      // 🎨 THEME PROVIDER (already used by MyApp)
      ChangeNotifierProvider<ThemeProvider>(
        create: (_) => ThemeProvider(),
      ),
    ],
    child: const MyApp(),
  ),
);

}
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Future<void> _checkForcedLogout() async {
    final prefs = await SharedPreferences.getInstance();

    final shouldLogout = prefs.getBool('force_logout_on_resume') ?? false;
    if (!shouldLogout) return;

    final message = prefs.getString('force_logout_message');

    // 🔥 Nuke ALL local state (single source of truth)
    await prefs.clear();

    // 🔐 Hard auth cleanup (secure storage, etc.)
    await AuthService().logout();

    // 🧭 Navigate safely to login
    if (globalNavigatorKey.currentState != null) {
      globalNavigatorKey.currentState!.pushNamedAndRemoveUntil(
        '/salesforce_login_page',
        (route) => false,
      );
    }

    // 🗣 Optional user feedback
    if (message != null && globalNavigatorKey.currentContext != null) {
      ScaffoldMessenger.of(globalNavigatorKey.currentContext!).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    }

    debugPrint("🔐 Forced logout executed successfully");
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkForcedLogout();

      if (globalNavigatorKey.currentContext != null) {
        UpdateService.checkVersion(globalNavigatorKey.currentContext!);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      debugPrint("🔄 App resumed — checking forced logout");
      await _checkForcedLogout();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BEST WORK FORCE',

      // 3. ✅ ASSIGN THE GLOBAL NAVIGATOR KEY HERE
      navigatorKey: globalNavigatorKey, // Use the global key

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
                      highlightedId:
                          bagLiftId, // <--- Pass ID to auto-open dialog
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
