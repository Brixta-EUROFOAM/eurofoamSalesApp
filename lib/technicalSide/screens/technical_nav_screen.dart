// lib/technicalSide/screens/technical_nav_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart'; 
import 'package:salesmanapp/salesSide/models/employee_model.dart';
import 'package:salesmanapp/salesSide/models/pjp_model.dart';
import 'package:salesmanapp/services/update_service.dart';

// --- Screens ---
import 'package:salesmanapp/technicalSide/screens/technical_dashboard_screen.dart';
import 'package:salesmanapp/technicalSide/screens/technical_profile_screen.dart';
import 'package:salesmanapp/technicalSide/screens/technical_pjp_screen.dart';
import 'package:salesmanapp/technicalSide/screens/technical_journey_screen.dart';
import 'package:salesmanapp/core/feature_flags/technical_flags.dart';

// --- Forms & Actions ---
import 'package:salesmanapp/technicalSide/screens/forms/create_tvr_form.dart';

class TechnicalNavScreen extends StatefulWidget {
  final Employee employee;
  const TechnicalNavScreen({super.key, required this.employee});

  @override
  State<TechnicalNavScreen> createState() => _TechnicalNavScreenState();
}

class _TechnicalNavScreenState extends State<TechnicalNavScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _journeyData;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<TechnicalPjpScreenState> _pjpKey =
      GlobalKey<TechnicalPjpScreenState>();

  // --- 🎨 FINTECH THEME PALETTE ---
  static const Color _bgLight = Color(0xFFF8FAFC);
  static const Color _cardNavy = Color(0xFF0F172A);
  static const Color _textGrey = Color(0xFF9CA3AF);

  @override
  void initState() {
    super.initState();
    UpdateService.checkVersion(userRole: 'TECHNICAL');
  }

  // 🚀 O(1) Tab Switcher (No Heavy Rebuilds)
  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    HapticFeedback.selectionClick(); 
    setState(() => _selectedIndex = index);

    if (index == 1) {
      _pjpKey.currentState?.refreshPjpList();
    }
  }

  // --- JOURNEY LOGIC ---
  void _startJourney(Map<String, dynamic> data) {
    setState(() {
      _journeyData = data;
      _selectedIndex = 2; // 🚀 O(1) Switch to Journey Tab
    });
  }

  // 🚀 RAM SAVER: Frees up memory payload immediately after it's passed to the Map
  void _clearJourneyData() {
    if (_journeyData != null) {
      setState(() {
        _journeyData = null;
      });
    }
  }

  void _onJourneyCompleted(
    Pjp pjp,
    dynamic locationEntity,
    bool isSite,
    DateTime checkInTime,
  ) {
    _clearJourneyData();

    // --- Force PJP Screen to refresh data from API ---
    _pjpKey.currentState?.refreshPjpList();

    _openDialog(
      CreateTvrScreen(
        employee: widget.employee,
        pjp: pjp,
        initialCheckInTime: checkInTime,
      ),
    );
  }

  // --- DRAWER NAVIGATION ACTIONS ---
  void _openDialog(Widget screen) {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          screen.animate().scale(curve: Curves.easeOutBack, duration: 400.ms),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 O(1) FLAG READ: .read() prevents the entire nav shell from rebuilding on unrelated provider changes
    final flags = context.read<TechnicalFlags>();

    // 🚀 STRICT O(1) INDEXING: We use SizedBox.shrink() to maintain absolute index integrity
    // Index 0 = Dashboard, Index 1 = PJP, Index 2 = Journey, Index 3 = Profile
    final List<Widget> pages = [
      flags.dashboard
          ? TechnicalDashboardScreen(employee: widget.employee)
          : const SizedBox.shrink(),
      flags.visits
          ? TechnicalPjpScreen(
              key: _pjpKey,
              employee: widget.employee,
              onStartJourney: _startJourney,
            )
          : const SizedBox.shrink(),
      flags.journey
          ? TechnicalJourneyScreen(
              employee: widget.employee,
              initialJourneyData: _journeyData,
              onDestinationConsumed: _clearJourneyData,
              onJourneyCompleted: _onJourneyCompleted,
            )
          : const SizedBox.shrink(),
      flags.profile
          ? TechnicalProfileScreen(employee: widget.employee)
          : const SizedBox.shrink(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bgLight,
      extendBody: true, // Allows content to scroll behind the floating nav bar

      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: _cardNavy),
              currentAccountPicture:
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(
                      widget.employee.firstName?[0] ?? "U",
                      style: const TextStyle(
                        fontSize: 24,
                        color: _cardNavy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ).animate().scale(
                    delay: 200.ms,
                    duration: 400.ms,
                    curve: Curves.easeOutBack,
                  ),
              accountName: Text(
                widget.employee.displayName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(widget.employee.email ?? "No Email"),
            ),
            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: Colors.redAccent,
              ),
              title: const Text(
                "Log Out",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 3); // Go to Profile
              },
            ),
          ],
        ),
      ),

      // --- MAIN BODY WRAPPED IN STACK FOR FLOATING NAV ---
      body: Stack(
        children: [
          // 🚀 INDEXED STACK: Keeps Map alive in background to save battery and initialization CPU time
          IndexedStack(
            index: _selectedIndex,
            children: pages,
          ).animate().fadeIn(duration: 600.ms, curve: Curves.easeOutCubic),

          // ✨ PREMIUM FLOATING NAVIGATION BAR
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildPremiumNavBar(flags),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 💎 PREMIUM CUSTOM EXPANDING BOTTOM NAV ($O(1)$ Complexity)
  // =========================================================================
  Widget _buildPremiumNavBar(TechnicalFlags flags) {
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
              if (flags.dashboard)
                _buildNavItem(
                  index: 0,
                  icon: Icons.grid_view_rounded,
                  label: "Home",
                ),
              if (flags.visits)
                _buildNavItem(
                  index: 1,
                  icon: Icons.event_note_rounded,
                  label: "Visits",
                ),
              if (flags.journey)
                _buildNavItem(
                  index: 2,
                  icon: Icons.near_me_rounded,
                  label: "Journey",
                ),
              if (flags.profile)
                _buildNavItem(
                  index: 3,
                  icon: Icons.person_rounded,
                  label: "Profile",
                ),
            ],
          ),
        )
        .animate()
        .slideY(begin: 1.5, duration: 600.ms, curve: Curves.easeOutBack)
        .fadeIn();
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
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
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
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
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .slideX(begin: -0.1, curve: Curves.easeOut),
            ],
          ],
        ),
      ),
    );
  }
}
