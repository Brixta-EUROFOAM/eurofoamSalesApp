// lib/main.dart

import 'package:assetarchiverflutter/api/auth_service.dart';
import 'package:assetarchiverflutter/screens/auth/login_screen.dart';
import 'package:assetarchiverflutter/screens/nav_screen.dart';
import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart'; Font logic nelaage ru..app theme . dart ot ase
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_radar/flutter_radar.dart';
import 'package:hive_flutter/hive_flutter.dart';

// --- NEW IMPORTS ---
import 'package:provider/provider.dart';
import 'package:assetarchiverflutter/widgets/app_theme.dart';
import 'package:assetarchiverflutter/widgets/theme_provider.dart';
// --- END NEW IMPORTS ---

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Hive.initFlutter();

  final radarPublishableKey = dotenv.env['RADAR_API_KEY'];
  if (radarPublishableKey != null) {
    await Radar.initialize(radarPublishableKey);
    debugPrint("✅ Radar SDK Initialized Successfully.");
  } else {
    debugPrint("❌ ERROR: RADAR_PUBLISHABLE_KEY not found in .env file. Tracking will fail.");
  }
  
  final Employee? loggedInEmployee = await AuthService().tryAutoLogin();

  // --- UPDATED: Wrap your app in the ThemeProvider ---
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: MyApp(loggedInEmployee: loggedInEmployee),
    ),
  );
  // --- END UPDATE ---
}

class MyApp extends StatelessWidget {
  final Employee? loggedInEmployee;
  const MyApp({super.key, this.loggedInEmployee});

  @override
  Widget build(BuildContext context) {
    // This line "listens" to the ThemeProvider for changes
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Modern App',

      // --- UPDATED: This is the magic! ---
      // We now provide both themes and let the provider
      // choose which one to show.
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      // --- END UPDATE ---

      // Your existing logic is perfect and remains unchanged
      initialRoute: loggedInEmployee != null ? '/home' : '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          final employee = loggedInEmployee ?? settings.arguments as Employee;
          return MaterialPageRoute(
            builder: (context) {
              return NavScreen(employee: employee);
            },
          );
        }
        return null;
      },
    );
  }
}