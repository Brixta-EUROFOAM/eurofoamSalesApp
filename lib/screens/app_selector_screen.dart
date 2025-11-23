// lib/screens/app_selector_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:assetarchiverflutter/widgets/reusableglasscard.dart'; 

class AppSelectorScreen extends StatelessWidget {
  const AppSelectorScreen({super.key});

  void _navigateToLogin(BuildContext context, bool isTechnical) {
    Navigator.of(context).pushNamed(
      '/salesforce_login_page',
      arguments: {'isTechnical': isTechnical}, 
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF000000), Color(0xFF0D47A1)], // Black to Deep Blue
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  // --- Logo / Header ---
                  const Icon(Icons.token, size: 60, color: Colors.white), // Placeholder logo
                  const SizedBox(height: 20),
                  const Text(
                    'WELCOME',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      letterSpacing: 4.0,
                      color: Colors.white70,
                    ),
                  ),
                  const Text(
                    'SELECT PORTAL',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 60),

                  // --- Option 1: Salesforce ---
                  _buildPortalCard(
                    context,
                    title: 'SALES FORCE',
                    subtitle: '(EMP)',
                    icon: Icons.business_center,
                    color: Colors.blueAccent,
                    isTechnical: false,
                  ).animate().slideX(begin: -1, duration: 600.ms, curve: Curves.easeOut),

                  const SizedBox(height: 24),

                  // --- Option 2: Technical ---
                  _buildPortalCard(
                    context,
                    title: 'TECHNICAL SIDE',
                    subtitle: '(TSE)',
                    icon: Icons.engineering,
                    color: Colors.tealAccent, 
                    isTechnical: true,
                  ).animate().slideX(begin: 1, duration: 600.ms, curve: Curves.easeOut, delay: 200.ms),
                  
                  const Spacer(),
                ],
              ),
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
    required bool isTechnical,
  }) {
    return LiquidGlassCard(
      onPressed: () => _navigateToLogin(context, isTechnical),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.5), width: 2),
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.3), size: 18),
        ],
      ),
    );
  }
}