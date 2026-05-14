// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api/auth_service.dart';
import 'screens/loginScreen.dart';
import 'screens/bottomNavBar.dart';

void main() async {
  // 1. Ensure Flutter bindings are initialized before calling async code
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Lock the app to Portrait orientation (prevents form UI breakage on rotation)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 3. Set Android system navigation bar color to match the app
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // 4. Check Authentication State
  final authService = AuthService();
  final bool isLoggedIn = await authService.isLoggedIn();

  // 5. Run the App
  runApp(SalesApp(initialRouteIsHome: isLoggedIn));
}

class SalesApp extends StatelessWidget {
  final bool initialRouteIsHome;

  const SalesApp({Key? key, required this.initialRouteIsHome}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eurofoam Work Force',
      debugShowCheckedModeBanner: false,
      
      // --- GLOBAL APP THEME ---
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: Colors.grey[50], // Match your screen backgrounds
        
        // Globally style AppBars to match your CardNavy standard
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Color(0xFF0F172A), // cardNavy
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.w900, 
            letterSpacing: 1.0,
            color: Colors.white,
          ),
        ),

        // Elevated Button Global Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),

      // Route directly to Home if token exists, otherwise Login
      home: initialRouteIsHome ? const BottomNavBar() : const LoginScreen(),
    );
  }
}