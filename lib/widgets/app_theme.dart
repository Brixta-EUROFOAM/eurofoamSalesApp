import 'package:flutter/material.dart';

class AppTheme {
  // --- Your Brand Colors ---
  static const Color primaryBlue = Color(0xFF0D47A1); // Blue on light card
  static const Color primaryOrange = Color(0xFFFFA000); // Buttons
  static const Color darkBackground = Color(0xFF010638); // Deep dark blue
  static const Color darkCard = Color(0xFF0B124B); // Dark mode card
  static const Color lightBackground = Color(0xFFF0F4F8); // Light mode off-white
  static const Color lightCard = Colors.white;

  // --- ☀️ LIGHT THEME DATA ---
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: lightBackground,
    
    colorScheme: const ColorScheme.light(
      // --- ✅ CRITIQUE #2: User bubble is now orange in light mode ---
      // This provides good contrast and matches your brand's orange.
      primary: primaryOrange,
      // --- END FIX ---
      secondary: primaryOrange,
      background: lightBackground,
      surface: lightCard,
      // --- ✅ CRITIQUE #2: Text on orange bubble is black ---
      onPrimary: Colors.black, 
      // --- END FIX ---
      onSecondary: Colors.black,
      onBackground: Colors.black,
      onSurface: Colors.black,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: lightBackground,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 22,
        // --- ✅ CRITIQUE #7: Changed from bold to medium ---
        fontWeight: FontWeight.w500,
        // --- END FIX ---
      ),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      color: lightCard,
      // --- ✅ CRITIQUE #9: Consistent 16px corners ---
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryOrange,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      showSelectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryOrange,
        foregroundColor: Colors.black,
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
  );

  // --- 🌙 DARK THEME DATA ---
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: darkBackground,
    
    colorScheme: const ColorScheme.dark(
      // --- ✅ CRITIQUE #2: User bubble is "calmer" blue ---
      // This is a slightly darker, less saturated blue than primaryBlue
      primary: Color(0xFF0A3A8A), 
      // --- END FIX ---
      secondary: primaryOrange,
      background: darkBackground,
      surface: darkCard,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onBackground: Colors.white,
      onSurface: Colors.white,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackground,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 22,
        // --- ✅ CRITIQUE #7: Changed from bold to medium ---
        fontWeight: FontWeight.w500,
        // --- END FIX ---
      ),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      color: darkCard,
      // --- ✅ CRITIQUE #9: Consistent 16px corners ---
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkBackground,
      selectedItemColor: primaryOrange,
      unselectedItemColor: Colors.white54,
      showUnselectedLabels: true,
      showSelectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryOrange,
        foregroundColor: Colors.black,
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
  );
}

