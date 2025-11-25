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
import 'package:assetarchiverflutter/technicalSide/screens/forms/add_site_form.dart';
import 'package:assetarchiverflutter/technicalSide/screens/forms/approve_mason_kyc.dart';
import 'package:assetarchiverflutter/technicalSide/screens/forms/approve_mason_bagLift.dart';
import 'package:assetarchiverflutter/technicalSide/screens/forms/approve_mason_rewards.dart';
import 'package:assetarchiverflutter/screens/forms/create_leave_form.dart';

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
  static const Color cardGradientStart = Color(0xFF0B4AA8);  // Brand Blue
  static const Color cardGradientEnd   = Color(0xFF111827);  // Dark surface fade
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

  void _openFullScreen(Widget screen) {
    Navigator.pop(context); 
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
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
      drawer: Drawer(
        backgroundColor: surfaceDark, // Matches the new dark theme
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Drawer Header with Gradient
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [cardGradientStart, cardGradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              accountName: Text(
                widget.employee.displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              accountEmail: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.employee.email ?? '',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentYellow,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "TECHNICAL LEAD",
                      style: TextStyle(
                        color: Colors.black, 
                        fontWeight: FontWeight.w900, 
                        fontSize: 10
                      ),
                    ),
                  )
                ],
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.9),
                child: Text(
                  widget.employee.firstName?.substring(0, 1).toUpperCase() ?? "T",
                  style: const TextStyle(fontSize: 32, color: cardGradientStart, fontWeight: FontWeight.w900),
                ),
              ),
            ),

            // --- SECTION 1: SITE & VISITS ---
            _buildSectionHeader("SITE & VISITS"),
            _buildDrawerItem(
              Icons.assignment_add, 
              "Create TVR", 
              () {
                Navigator.pop(context);
                showDialog(
                  context: context, 
                  builder: (_) => CreateTvrScreen(employee: widget.employee)
                );
              },
            ),
            _buildDrawerItem(
              Icons.add_location_alt, 
              "Register Site", 
              () => _openFullScreen(AddSiteForm(employee: widget.employee)),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Divider(color: Colors.white.withOpacity(0.1)),
            ),

            // --- SECTION 2: APPROVALS ---
            _buildSectionHeader("APPROVALS (TSE)"),
            _buildDrawerItem(
              Icons.verified_user_outlined, 
              "Approve KYC", 
              () => _openFullScreen(ApproveMasonKycScreen(employee: widget.employee)),
            ),
            _buildDrawerItem(
              Icons.shopping_bag_outlined, 
              "Approve Bag Lifts", 
              () => _openFullScreen(ApproveMasonBagLift(employee: widget.employee)),
            ),
            _buildDrawerItem(
              Icons.card_giftcard, 
              "Approve Rewards", 
              () => _openFullScreen(const ApproveMasonRewardsScreen()),
            ),

             Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Divider(color: Colors.white.withOpacity(0.1)),
            ),

            // --- SECTION 3: GENERAL ---
            _buildSectionHeader("GENERAL"),
            _buildDrawerItem(
              Icons.event_note, 
              "Apply for Leave", 
              () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => CreateLeaveFormScreen(employee: widget.employee)
                );
              },
            ),
            _buildDrawerItem(
              Icons.task_alt, 
              "Daily Tasks", 
              () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Daily Tasks - Coming Soon"))
                );
              },
            ),
          ],
        ),
      ),

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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white38, // Muted text for headers
          fontSize: 11, 
          fontWeight: FontWeight.w900, // Extra bold
          letterSpacing: 1.5
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: accentYellow, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      visualDensity: VisualDensity.compact, // Make items slightly tighter
      hoverColor: Colors.white.withOpacity(0.05),
    );
  }
}