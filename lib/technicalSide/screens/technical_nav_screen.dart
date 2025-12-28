// lib/technicalSide/screens/technical_nav_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salesmanapp/models/employee_model.dart';
import 'package:salesmanapp/models/pjp_model.dart';
//import 'package:salesmanapp/technicalSide/models/sites_model.dart';
//import 'package:salesmanapp/models/dealer_model.dart';

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
  final GlobalKey<TechnicalPjpScreenState> _pjpKey = GlobalKey<TechnicalPjpScreenState>();

  // --- FINTECH THEME PALETTE ---
  static const Color _bgLight        = Color(0xFFF3F4F6); 
  static const Color _navBarBg       = Colors.white;      
  static const Color _cardNavy       = Color(0xFF0F172A); 
  static const Color _textGrey       = Color(0xFF9CA3AF); 

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    
    if (index == 1) {
      _pjpKey.currentState?.refreshPjpList();
    }
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

  void _onJourneyCompleted(Pjp pjp, dynamic locationEntity, bool isSite, DateTime checkInTime) {
    _clearJourneyData();
    
    // --- Force PJP Screen to refresh data from API ---
    // This ensures the completed PJP disappears from the list immediately.
    _pjpKey.currentState?.refreshPjpList();
    
    _openDialog(CreateTvrScreen(employee: widget.employee));
  }

  // --- DRAWER NAVIGATION ACTIONS ---
  void _openDialog(Widget screen) {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context); 
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => screen,
    );
  }

  @override
  Widget build(BuildContext context) {
    final flags = context.read<TechnicalFlags>();
    final List<Widget> pages = [
      if(flags.dashboard)
      TechnicalDashboardScreen(employee: widget.employee), // 0: Home
      
      // --- ✅ Connected the Key here ---
      if(flags.visits)
      TechnicalPjpScreen(
        key: _pjpKey, 
        employee: widget.employee, 
        onStartJourney: _startJourney
      ), // 1: Visits
      if(flags.journey)
      TechnicalJourneyScreen(
        employee: widget.employee,
        initialJourneyData: _journeyData,
        onDestinationConsumed: () {}, // Journey started
        onJourneyCompleted: _onJourneyCompleted, // Journey ended
      ), // 2: Journey
      if(flags.profile)
      TechnicalProfileScreen(employee: widget.employee), // 3: Profile
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bgLight,
      
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
                Navigator.pop(context);
                setState(() => _selectedIndex = 3); // Go to Profile
              },
            )
          ],
        ),
      ),

      // --- MAIN BODY ---
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),

      // --- BOTTOM NAVIGATION BAR ---
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
            indicatorColor: _cardNavy,
            labelTextStyle: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return const TextStyle(color: _cardNavy, fontWeight: FontWeight.bold, fontSize: 12);
              }
              return const TextStyle(color: _textGrey, fontWeight: FontWeight.w500, fontSize: 12);
            }),
            iconTheme: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return const IconThemeData(color: Colors.white);
              }
              return const IconThemeData(color: _textGrey);
            }),
          ),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            height: 70,
            elevation: 0,
            destinations: [
              if(flags.dashboard)
              const NavigationDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view_rounded),
                label: 'Dashboard',
              ),
              if(flags.visits)
              const NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month),
                label: 'Visits', 
              ),
              if(flags.journey)
              const NavigationDestination(
                icon: Icon(Icons.near_me_outlined),
                selectedIcon: Icon(Icons.near_me),
                label: 'Journey',
              ),
              if(flags.profile)
              const NavigationDestination(
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