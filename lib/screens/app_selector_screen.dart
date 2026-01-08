// lib/screens/app_selector_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salesmanapp/api/auth_service.dart';
import 'package:salesmanapp/models/employee_model.dart';

class AppSelectorScreen extends StatefulWidget {
  const AppSelectorScreen({super.key});

  @override
  State<AppSelectorScreen> createState() => _AppSelectorScreenState();
}

class _AppSelectorScreenState extends State<AppSelectorScreen> {
  final AuthService _authService = AuthService();
  bool _isCheckingAutoLogin = true;

  // --- FINTECH THEME PALETTE ---
  static const Color _bgLight   = Color(0xFFF3F4F6); // Corporate Grey
  static const Color _textDark  = Color(0xFF111827); // Navy/Black
  static const Color _textGrey  = Color(0xFF6B7280); // Subtitle Grey
  static const Color _cardNavy  = Color(0xFF0F172A); // Deep Navy

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

Future<void> _checkAutoLogin() async {
    try {
      final Employee? employee = await _authService.tryAutoLogin();
      
      // If logged out (null), stop loading and show the selector screen
      if (!mounted || employee == null) {
        setState(() => _isCheckingAutoLogin = false);
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      
      // 1. RECOVERY: Get stored mode. If null (Process Death), infer from Role.
      bool? isTechnicalMode = prefs.getBool('is_technical_mode');
      
      // "Self-Healing": If preference is wiped, restore it based on the User Role
      if (isTechnicalMode == null) {
        if (employee.isTechnicalRole) {
           isTechnicalMode = true; 
           await prefs.setBool('is_technical_mode', true);
        } else {
           isTechnicalMode = false;
           await prefs.setBool('is_technical_mode', false);
        }
      }

      // 2. NAVIGATION LOGIC
      if (isTechnicalMode == true) {
         // ✅ INTENDED MODE: TECHNICAL
         
         // SECURITY CHECK: Do they actually have the role?
         if (employee.isTechnicalRole) {
            // Permission Granted -> Go to Tech Home
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/technical_home',
              (route) => false,
              arguments: employee,
            );
         } else {
            // ⛔️ PERMISSION DENIED (Role Mismatch)
            // The app thought we were in Tech mode, but the User Role is Sales.
            // Redirect to Login (Technical Interface) to fix the session.
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/salesforce_login_page', // Matches route defined in main.dart
              (route) => false,
              arguments: {'isTechnical': true}, // Force Tech UI on Login
            );
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Session role mismatch. Please login again."),
                backgroundColor: Colors.red,
              ),
            );
         }
      } else {
         // ✅ INTENDED MODE: SALESMAN
         Navigator.of(context).pushNamedAndRemoveUntil(
            '/home', 
            (route) => false,
            arguments: employee,
         );
      }

    } catch (e) {
      // 🛑 HANDLE OFFLINE / ERRORS
      // If AuthService throws (e.g. SocketException), we catch it here.
      if (mounted) {
         setState(() => _isCheckingAutoLogin = false);
         
         // Optional: Feedback to user
         // ScaffoldMessenger.of(context).showSnackBar(
         //    SnackBar(content: Text("Connection failed. Please try again.")),
         // );
      }
    }
  }

  void _navigateToLogin(BuildContext context, bool isTechnical) {
    Navigator.of(context).pushNamed(
      '/salesforce_login_page', // Matches route defined in main.dart
      arguments: {'isTechnical': isTechnical},
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tiny loading state while we check token
    if (_isCheckingAutoLogin) {
      return const Scaffold(
        backgroundColor: _bgLight,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bgLight,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                
                // --- Logo / Header ---
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ]
                    ),
                    child: const Icon(Icons.token, size: 50, color: _cardNavy), 
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'WELCOME',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    letterSpacing: 3.0,
                    fontWeight: FontWeight.w600,
                    color: _textGrey,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'SELECT PORTAL',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: _textDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 60),

                //Sales Portal
                // _buildPortalCard(
                //   context,
                //   title: 'SALES FORCE',
                //   subtitle: '(EMP)',
                //   icon: Icons.business_center,
                //   color: Colors.blueAccent,
                //   isTechnical: false,
                // ).animate().slideX(begin: -1, duration: 600.ms, curve: Curves.easeOut),

                // const SizedBox(height: 24),

                //Technical Portal
                _buildPortalCard(
                  context,
                  title: 'TECHNICAL SIDE',
                  subtitle: '(TSE)',
                  icon: Icons.engineering,
                  color: const Color(0xFF0F766E),       // Teal for Tech
                  bgColor: const Color(0xFFF0FDF4),     // Light Teal BG
                  isTechnical: true,
                ).animate().slideX(begin: 1, duration: 600.ms, curve: Curves.easeOut, delay: 200.ms),
                  
                const Spacer(),
                  
                const Text(
                  "Secure Enterprise Login",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _textGrey, fontSize: 12),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPortalCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    Color? bgColor,
    required bool isTechnical,
  }) {
    final backgroundColor = bgColor ?? color.withOpacity(0.1);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToLogin(context, isTechnical),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: Colors.white),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _textGrey,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _bgLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_forward_rounded, color: Colors.grey, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
