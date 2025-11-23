import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_radar/flutter_radar.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:assetarchiverflutter/widgets/app_theme.dart';
import 'package:assetarchiverflutter/widgets/theme_provider.dart';
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:assetarchiverflutter/screens/auth/login_screen.dart';
import 'package:assetarchiverflutter/screens/nav_screen.dart';
import 'package:assetarchiverflutter/technicalSide/screens/technical_nav_screen.dart';
import 'package:assetarchiverflutter/screens/app_selector_screen.dart'; // NEW SELECTOR

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint("Firebase Initialized Successfully.");
  await dotenv.load(fileName: ".env");
  await Hive.initFlutter();
  final radarPublishableKey = dotenv.env['RADAR_API_KEY'];
  if (radarPublishableKey != null) {
    await Radar.initialize(radarPublishableKey);
    debugPrint("Radar SDK Initialized Successfully.");
  } else {
    debugPrint("ERROR: RADAR_PUBLISHABLE_KEY not found in .env file. Tracking will fail.");
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
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      initialRoute: '/selector',

      routes: {
        // The Landing Screen (Choice)
        '/selector': (context) => const AppSelectorScreen(),
        
        // The Login Screen (Shared, behavior changes based on args)
        '/salesforce_login_page': (context) => const LoginScreen(),
      },
      onGenerateRoute: (settings) {

        // 1. Existing Salesman App
        if (settings.name == '/home') {
          final employee = settings.arguments as Employee;
          return MaterialPageRoute(
            builder: (context) {
              return NavScreen(employee: employee);
            },
          );
        }

        // 2. Technical App
        if (settings.name == '/technical_home') {
          final employee = settings.arguments as Employee;
          return MaterialPageRoute(
            builder: (context) => TechnicalNavScreen(employee: employee),
          );
        }

        return null;
      },
    );
  }
}