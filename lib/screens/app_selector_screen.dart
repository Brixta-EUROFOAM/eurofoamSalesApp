// lib/screens/app_selector_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
// import 'package:assetarchiverflutter/widgets/reusableglasscard.dart'; // No longer needed for Fintech look

class AppSelectorScreen extends StatelessWidget {
  const AppSelectorScreen({super.key});

  void _navigateToLogin(BuildContext context, bool isTechnical) {
    Navigator.of(context).pushNamed(
      '/salesforce_login_page',
      arguments: {'isTechnical': isTechnical}, 
    );
  }

  // --- FINTECH THEME PALETTE ---
  static const Color _bgLight   = Color(0xFFF3F4F6); // Corporate Grey
  static const Color _textDark  = Color(0xFF111827); // Navy/Black
  static const Color _textGrey  = Color(0xFF6B7280); // Subtitle Grey
  static const Color _cardNavy  = Color(0xFF0F172A); // Deep Navy

  @override
  Widget build(BuildContext context) {
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

                // --- Option 1: Salesforce ---
                 // _buildPortalCard(
                  //  context,
                   // title: 'SALES FORCE',
                    //subtitle: '(EMP)',
                    //icon: Icons.business_center,
                    //color: Colors.blueAccent,
                    //isTechnical: false,
                  //).animate().slideX(begin: -1, duration: 600.ms, curve: Curves.easeOut),

                  // const SizedBox(height: 24),

                  // --- Option 2: Technical ---
                  _buildPortalCard(
                    context,
                    title: 'TECHNICAL SIDE',
                    subtitle: '(TSE)',
                    icon: Icons.engineering,
                    color: const Color(0xFF0F766E), // Teal for Tech
                    bgColor: const Color(0xFFF0FDF4), // Light Teal BG
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
    Color? bgColor, // Added optional param for light theme bg
    required bool isTechnical,
  }) {
    // Default bg if not provided (handles the commented out code case)
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