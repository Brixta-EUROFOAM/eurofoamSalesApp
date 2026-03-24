// lib/screens/nav_screen.dart
import 'dart:ui';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart'; // 🚀 Premium Animations

import 'package:salesmanapp/salesSide/models/employee_model.dart';
import 'package:salesmanapp/salesSide/models/pjp_model.dart';
import 'package:salesmanapp/salesSide/models/dealer_model.dart';

import 'package:salesmanapp/salesSide/screens/employee_dashboard_screen.dart';
import 'package:salesmanapp/salesSide/screens/employee_profile_screen.dart';
import 'package:salesmanapp/salesSide/screens/employee_pjp_screen.dart';
import 'package:salesmanapp/salesSide/screens/employee_journey_screen.dart';
import 'package:salesmanapp/salesSide/screens/forms/create_dvr.dart';

// --- NavProvider ---
class NavProvider with ChangeNotifier {
  int _selectedIndex = 0;
  Map<String, dynamic>? _journeyData;

  int get selectedIndex => _selectedIndex;
  Map<String, dynamic>? get journeyData => _journeyData;

  void changePage(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  // ✅ Saves the entire journey map and navigates to Journey tab (now Index 2)
  void startJourney(Map<String, dynamic> data) {
    _journeyData = data;
    _selectedIndex = 2; // Updated index for Journey
    notifyListeners();
  }

  void clearJourneyData() {
    _journeyData = null;
    notifyListeners();
  }

  void refreshDashboard() {
    debugPrint("Refreshing Dashboard...");
  }

  void refreshPjpList() {
    debugPrint("Refreshing PJP List...");
  }
}

class NavScreen extends StatefulWidget {
  final Employee employee;
  const NavScreen({super.key, required this.employee});

  @override
  State<NavScreen> createState() => _NavScreenState();
}

class _NavScreenState extends State<NavScreen> {
  late final NavProvider _navProvider;

  // Keys to access state of children for refreshing
  final GlobalKey<EmployeeDashboardScreenState> _dashboardKey =
      GlobalKey<EmployeeDashboardScreenState>();
  final GlobalKey<EmployeePJPScreenState> _pjpKey =
      GlobalKey<EmployeePJPScreenState>();

  // --- 🎨 FINTECH THEME PALETTE ---
  static const Color _bgLight = Color(0xFFF3F4F6);
  static const Color _cardNavy = Color(0xFF0F172A);
  static const Color _textGrey = Color(0xFF9CA3AF);

  @override
  void initState() {
    super.initState();
    _navProvider = NavProvider();
  }

  @override
  void dispose() {
    _navProvider.dispose();
    super.dispose();
  }

  // --- 🚀 PROPER ROUTING FIX (No Black Screens) ---
  void _showCreateDvrDialogFromJourney(
    BuildContext context,
    Employee employee,
    Pjp pjp,
    Dealer dealer,
    DateTime checkInTime,
  ) {
    dev.log(
      'Auto-opening DVR for PJP ${pjp.id} at $checkInTime',
      name: 'NavScreen',
    );
    
    // 🔥 Pushed as a full screen route.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateDvrScreen(
          employee: employee,
          pjp: pjp,
          dealer: dealer,
          initialCheckInTime: checkInTime,
          onReturnToDashboard: () {
            // Uses local provider instance ($O(1)$ lookup, bypasses context tree errors)
            _navProvider.changePage(0);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _navProvider,
      child: Consumer<NavProvider>(
        builder: (context, provider, child) {
          final pages = <Widget>[
            EmployeeDashboardScreen(
              key: _dashboardKey,
              employee: widget.employee,
            ),
            EmployeePJPScreen(
              key: _pjpKey,
              employee: widget.employee,
              onStartJourney: provider.startJourney,
              onPjpCreated: () {
                _dashboardKey.currentState?.refreshData();
                provider.refreshDashboard();
              },
            ),
            EmployeeJourneyScreen(
              initialJourneyData: provider.journeyData,
              employee: widget.employee,
              onDestinationConsumed: provider.clearJourneyData,
              onJourneyCompleted:
                  (Pjp pjp, Dealer dealer, DateTime checkInTime) {
                    _showCreateDvrDialogFromJourney(
                      context,
                      widget.employee,
                      pjp,
                      dealer,
                      checkInTime,
                    );
                  },
            ),
            EmployeeProfileScreen(employee: widget.employee),
          ];

          return Scaffold(
            backgroundColor: _bgLight,
            // Use Stack so the custom nav bar floats beautifully over the UI
            body: Stack(
              children: [
                IndexedStack(index: provider.selectedIndex, children: pages),

                // Floating Premium Nav Bar
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildPremiumNavBar(provider),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // =========================================================================
  // 💎 PREMIUM CUSTOM EXPANDING BOTTOM NAV ($O(1)$ Complexity)
  // =========================================================================
  Widget _buildPremiumNavBar(NavProvider provider) {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 32),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: _cardNavy.withOpacity(0.12),
            blurRadius: 30,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavItem(provider, index: 0, icon: Icons.grid_view_rounded, label: "Home"),
          _buildNavItem(provider, index: 1, icon: Icons.event_note_rounded, label: "Visits"),
          _buildNavItem(provider, index: 2, icon: Icons.near_me_rounded, label: "Journey"),
          _buildNavItem(provider, index: 3, icon: Icons.person_rounded, label: "Profile"),
        ],
      ),
    ).animate().slideY(begin: 1.5, duration: 600.ms, curve: Curves.easeOutBack).fadeIn();
  }

  Widget _buildNavItem(NavProvider provider, {required int index, required IconData icon, required String label}) {
    final bool isSelected = provider.selectedIndex == index;

    return GestureDetector(
      onTap: () {
        if (index == 0) _dashboardKey.currentState?.refreshData();
        if (index == 1) _pjpKey.currentState?.refreshPjpList();
        provider.changePage(index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? _cardNavy : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
              child: Icon(
                icon,
                key: ValueKey(isSelected),
                size: 24,
                color: isSelected ? Colors.white : _textGrey.withOpacity(0.7),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1, curve: Curves.easeOut),
            ]
          ],
        ),
      ),
    );
  }
}