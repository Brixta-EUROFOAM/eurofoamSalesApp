// lib/technicalSide/screens/technical_nav_screen.dart
import 'package:flutter/material.dart';
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:assetarchiverflutter/models/pjp_model.dart';
import 'package:assetarchiverflutter/technicalSide/models/sites_model.dart';

// --- Screens ---
import 'package:assetarchiverflutter/technicalSide/screens/technical_dashboard_screen.dart';
import 'package:assetarchiverflutter/technicalSide/screens/technical_profile_screen.dart';
import 'package:assetarchiverflutter/technicalSide/screens/technical_pjp_screen.dart'; 
import 'package:assetarchiverflutter/technicalSide/screens/technical_journey_screen.dart'; 

// --- Forms & Actions ---
import 'package:assetarchiverflutter/technicalSide/screens/forms/create_tvr_form.dart';

class TechnicalNavScreen extends StatefulWidget {
  final Employee employee;
  const TechnicalNavScreen({super.key, required this.employee});

  @override
  State<TechnicalNavScreen> createState() => _TechnicalNavScreenState();
}

class _TechnicalNavScreenState extends State<TechnicalNavScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _journeyData; 

  // --- THEME CONSTANTS (Synced with Dashboard) ---
  static const Color scaffoldBg        = Color(0xFF020617);  // Almost-black navy
  static const Color surfaceDark       = Color(0xFF1E293B);  // Slate 800 (Drawer/Nav BG)
 // Dark surface fade
  static const Color accentYellow      = Color(0xFFFFA000);  // Amber/Orange

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  // --- JOURNEY LOGIC ---
  void _startJourney(Map<String, dynamic> data) {
    setState(() {
      _journeyData = data;
      _selectedIndex = 2; // Switch to Journey Tab
    });
  }

  void _clearJourneyData() {
    setState(() {
      _journeyData = null;
    });
  }

  void _onJourneyCompleted(Pjp pjp, TechnicalSite site, DateTime checkInTime) {
    _clearJourneyData();
    _openDialog(CreateTvrScreen(employee: widget.employee));
  }

  // --- DRAWER NAVIGATION ACTIONS ---
  void _openDialog(Widget screen) {
    if (Scaffold.of(context).isDrawerOpen) Navigator.pop(context); 
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => screen,
    );
  }


  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      TechnicalDashboardScreen(employee: widget.employee), // 0: Home
      TechnicalPjpScreen(employee: widget.employee, onStartJourney: _startJourney), // 1: Visits
      TechnicalJourneyScreen(
        employee: widget.employee,
        initialJourneyData: _journeyData,
        onDestinationConsumed: () {},
        onJourneyCompleted: _onJourneyCompleted,
      ), // 2: Journey
      TechnicalProfileScreen(employee: widget.employee), // 3: Profile
    ];

    return Scaffold(
      backgroundColor: scaffoldBg,
      
      // --- 1. THE SIDE DRAWER (THEMED) ---
      

      // --- 2. MAIN BODY ---
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),

      // --- 3. BOTTOM NAVIGATION BAR (THEMED) ---
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const TextStyle(color: accentYellow, fontWeight: FontWeight.w700, fontSize: 12);
            }
            return const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500, fontSize: 12);
          }),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor: surfaceDark, // Slate 800
          indicatorColor: accentYellow, // High-vis Amber
          height: 70,
          elevation: 0,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.grid_view, color: Colors.white70), // Changed to Grid (Dashboard feel)
              selectedIcon: Icon(Icons.grid_view_rounded, color: Colors.black),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined, color: Colors.white70),
              selectedIcon: Icon(Icons.calendar_month, color: Colors.black),
              label: 'Visits', 
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined, color: Colors.white70),
              selectedIcon: Icon(Icons.map, color: Colors.black),
              label: 'Journey',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline, color: Colors.white70),
              selectedIcon: Icon(Icons.person, color: Colors.black),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}