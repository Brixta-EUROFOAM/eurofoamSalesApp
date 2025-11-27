// lib/technicalSide/screens/technical_nav_screen.dart
import 'package:flutter/material.dart';
import 'package:salesmanapp/models/employee_model.dart';
import 'package:salesmanapp/models/pjp_model.dart';
import 'package:salesmanapp/technicalSide/models/sites_model.dart';

// --- Screens ---
import 'package:salesmanapp/technicalSide/screens/technical_dashboard_screen.dart';
import 'package:salesmanapp/technicalSide/screens/technical_profile_screen.dart';
import 'package:salesmanapp/technicalSide/screens/technical_pjp_screen.dart'; 
import 'package:salesmanapp/technicalSide/screens/technical_journey_screen.dart'; 

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

  // --- FINTECH THEME PALETTE ---
  static const Color _bgLight        = Color(0xFFF3F4F6); // Corporate Grey
  static const Color _navBarBg       = Colors.white;      // White Nav Bar
  static const Color _cardNavy       = Color(0xFF0F172A); // Active Indicator
  static const Color _textGrey       = Color(0xFF9CA3AF); // Inactive Icons

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
      backgroundColor: _bgLight,
      
      // --- 1. THE SIDE DRAWER (Added to match theme) ---
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: _cardNavy),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  widget.employee.firstName?[0] ?? "U",
                  style: const TextStyle(fontSize: 24, color: _cardNavy, fontWeight: FontWeight.bold),
                ),
              ),
              accountName: Text(widget.employee.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: Text(widget.employee.email ?? "No Email"),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Log Out", style: TextStyle(color: Colors.red)),
              onTap: () {
                // Add logout logic here or navigate to profile to logout
                Navigator.pop(context);
                setState(() => _selectedIndex = 3); // Go to Profile
              },
            )
          ],
        ),
      ),

      // --- 2. MAIN BODY ---
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),

      // --- 3. BOTTOM NAVIGATION BAR (Redesigned) ---
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _navBarBg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            // Active Indicator (Pill shape)
            indicatorColor: _cardNavy,
            
            // Text Styles
            labelTextStyle: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return const TextStyle(color: _cardNavy, fontWeight: FontWeight.bold, fontSize: 12);
              }
              return const TextStyle(color: _textGrey, fontWeight: FontWeight.w500, fontSize: 12);
            }),

            // Icon Colors
            iconTheme: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return const IconThemeData(color: Colors.white); // White icon on Navy pill
              }
              return const IconThemeData(color: _textGrey); // Grey icon otherwise
            }),
          ),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white, // Removes Material 3 tint
            height: 70,
            elevation: 0,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view_rounded),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month),
                label: 'Visits', 
              ),
              NavigationDestination(
                icon: Icon(Icons.near_me_outlined),
                selectedIcon: Icon(Icons.near_me),
                label: 'Journey',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}