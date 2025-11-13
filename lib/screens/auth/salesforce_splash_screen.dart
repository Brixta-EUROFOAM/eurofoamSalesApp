import 'package:assetarchiverflutter/api/auth_service.dart';
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:flutter/material.dart';

// This screen now handles your old 'tryAutoLogin' logic
class SalesforceSplashScreen extends StatefulWidget {
  const SalesforceSplashScreen({super.key});

  @override
  State<SalesforceSplashScreen> createState() => _SalesforceSplashScreenState();
}

class _SalesforceSplashScreenState extends State<SalesforceSplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    // This is the logic we're moving from main.dart
    final Employee? loggedInEmployee = await AuthService().tryAutoLogin();
    if (!mounted) return;

    if (loggedInEmployee != null) {
      // User has a valid token, send them to the correct dashboard
      
      // Role-based redirect
      if (loggedInEmployee.role == 'ADMIN' || loggedInEmployee.role == 'MANAGER') {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/admin', // Your Admin route
          (route) => false, 
          arguments: loggedInEmployee
        );
      } else {
        // Default Salesforce route
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home', // Your existing Salesforce NavScreen
          (route) => false, 
          arguments: loggedInEmployee
        );
      }
    } else {
      // No valid token, send them to the actual email/password login page
      Navigator.of(context).pushReplacementNamed('/salesforce_login_page');
    }
  }

  @override
  Widget build(BuildContext context) {
    // You can customize this, but a simple spinner is fine
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}