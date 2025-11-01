import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  // We'll use "system" as the default
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  // We add this to load the user's preference when the app starts
  ThemeProvider() {
    _loadThemeMode();
  }

  // Gets the saved preference
  void _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString('themeMode') ?? 'system';
    
    if (themeString == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeString == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  // This is the function your Profile screen buttons will call
  void setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return; // No change
    
    _themeMode = mode;
    notifyListeners(); // Update the UI immediately

    // Save the user's choice
    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.light) {
      prefs.setString('themeMode', 'light');
    } else if (mode == ThemeMode.dark) {
      prefs.setString('themeMode', 'dark');
    } else {
      prefs.setString('themeMode', 'system');
    }
  }
}