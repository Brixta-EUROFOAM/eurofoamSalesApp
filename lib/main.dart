// lib/main.dart
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

// Screens
import 'package:assetarchiverflutter/screens/auth/login_screen.dart';
import 'package:assetarchiverflutter/screens/nav_screen.dart';
import 'package:assetarchiverflutter/screens/auth/app_selector_screen.dart';
import 'package:assetarchiverflutter/screens/auth/salesforce_splash_screen.dart';
import 'package:assetarchiverflutter/screens/auth/contractor_login_screen.dart';
import 'package:assetarchiverflutter/screens/contractor/kyc_onboarding_screen.dart';
import 'package:assetarchiverflutter/screens/contractor/contractor_nav_screen.dart';

// Admin
import 'package:assetarchiverflutter/screens/admin/admin_login.dart';
import 'package:assetarchiverflutter/screens/admin/admin_kycdetails.dart';
import 'package:assetarchiverflutter/screens/admin/admin_nav_screen.dart';

// Models & utilities
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:assetarchiverflutter/models/mason_model.dart';

// App tooling
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_radar/flutter_radar.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

// Theme
import 'package:assetarchiverflutter/widgets/app_theme.dart';
import 'package:assetarchiverflutter/widgets/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Activate App Check
  // - Use debug providers in debug builds (kDebugMode)
  // - Use Play Integrity / App Attest in release builds
  //
  // Note: Do NOT ship debug providers in production.
  await FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
  );

  // Env and local storage
  await dotenv.load(fileName: ".env");
  await Hive.initFlutter();

  // Radar (optional)
  final radarPublishableKey = dotenv.env['RADAR_API_KEY'];
  if (radarPublishableKey != null && radarPublishableKey.isNotEmpty) {
    await Radar.initialize(radarPublishableKey);
    debugPrint("✅ Radar SDK Initialized Successfully.");
  } else {
    debugPrint(
      "❌ RADAR_PUBLISHABLE_KEY not found in .env. Tracking will be disabled.",
    );
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(loggedInEmployee: null),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Employee? loggedInEmployee;
  const MyApp({super.key, this.loggedInEmployee});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Modern App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,

      initialRoute: '/selector',

      routes: {
        '/selector': (context) => const AppSelectorScreen(),
        '/salesforce_login': (context) => const SalesforceSplashScreen(),
        '/salesforce_login_page': (context) => const LoginScreen(),
        '/contractor_login': (context) => const ContractorLoginScreen(),
        '/admin_login': (context) => const AdminLoginScreen(),
      },

      onGenerateRoute: (settings) {
        // /home -> existing employee-based app shell
        if (settings.name == '/home') {
          final employee = loggedInEmployee ?? settings.arguments as Employee;
          return MaterialPageRoute(
            builder: (context) {
              return NavScreen(employee: employee);
            },
          );
        }

        // /admin -> admin shell (legacy)
        if (settings.name == '/admin') {
          final employee = loggedInEmployee ?? settings.arguments as Employee;
          return MaterialPageRoute(
            builder: (context) {
              return AdminNavScreen(employee: employee);
            },
          );
        }

        // /admin_dashboard -> admin nav (explicit)
        if (settings.name == '/admin_dashboard') {
          final employee = settings.arguments as Employee;
          return MaterialPageRoute(
            builder: (context) => AdminNavScreen(employee: employee),
          );
        }

        // /kyc_onboarding -> route to KYC onboarding from login flow
        if (settings.name == '/kyc_onboarding') {
          final arguments = settings.arguments;
          Mason mason;
          if (arguments is Mason) {
            mason = arguments;
          } else {
            return MaterialPageRoute(
              builder: (context) => const ContractorLoginScreen(),
            );
          }
          return MaterialPageRoute(
            builder: (context) => KycOnboardingScreen(mason: mason),
          );
        }

        // /contractor_home -> ALWAYS go to contractor nav screen
        if (settings.name == '/contractor_home') {
          final arguments = settings.arguments;
          Mason mason;

          if (arguments is Map<String, dynamic>) {
            mason = Mason.fromJson(arguments);
          } else if (arguments is Mason) {
            mason = arguments;
          } else {
            // Failsafe: if no mason, go back to login
            return MaterialPageRoute(
              builder: (context) => const ContractorLoginScreen(),
            );
          }

          return MaterialPageRoute(
            builder: (context) => ContractorNavScreen(mason: mason),
          );
        }

        // Admin KYC detail route
        if (settings.name == '/admin_kyc_detail') {
          final submission = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => AdminKycDetailScreen(submission: submission),
          );
        }

        // Unknown routes
        return null;
      },
    );
  }
}
