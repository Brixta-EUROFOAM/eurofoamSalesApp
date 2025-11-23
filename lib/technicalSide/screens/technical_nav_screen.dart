// lib/technicalSide/screens/technical_nav_screen.dart
import 'package:flutter/material.dart';
import 'package:assetarchiverflutter/models/employee_model.dart';

import 'package:assetarchiverflutter/technicalSide/screens/technical_dashboard_screen.dart';
import 'package:assetarchiverflutter/technicalSide/screens/technical_profile_screen.dart';

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
  late final List<Widget> _pages;

  // --- THEME COLORS ---
  static const Color darkBackground = Color(0xFF010638); // Deepest Blue
  static const Color primaryBlue = Color(0xFF0D47A1);    // Brand Blue
  static const Color accentYellow = Color(0xFFFFA000);   // Amber/Yellow

  @override
  void initState() {
    super.initState();
    _pages = [
      // 0: Home
      TechnicalDashboardScreen(employee: widget.employee),
      // 1: Sites (Placeholder)
      const _TechnicalPlaceholderScreen(title: "Technical Sites", icon: Icons.apartment),
      // 2: Journey (Placeholder)
      const _TechnicalPlaceholderScreen(title: "Technical Journey", icon: Icons.map),
      // 3: Profile
      TechnicalProfileScreen(employee: widget.employee),
    ];
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  // --- DRAWER NAVIGATION ACTIONS ---

  void _openDialog(Widget screen) {
    Navigator.pop(context); // Close drawer
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => screen,
    );
  }

  void _openFullScreen(Widget screen) {
    Navigator.pop(context); // Close drawer
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- 1. THE SIDE DRAWER ---
      drawer: Drawer(
        child: Container(
          color: darkBackground, // Dark Blue Background
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Drawer Header
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: primaryBlue),
                accountName: Text(
                  widget.employee.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                accountEmail: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.employee.email ?? '',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentYellow,
                        borderRadius: BorderRadius.circular(12),
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
                  backgroundColor: Colors.white,
                  child: Text(
                    widget.employee.firstName?.substring(0, 1).toUpperCase() ?? "T",
                    style: const TextStyle(fontSize: 32, color: primaryBlue, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // --- SECTION 1: SITE & VISITS ---
              _buildSectionHeader("SITE & VISITS"),
              _buildDrawerItem(
                Icons.assignment_add, 
                "CREATE TVR", 
                () => _openDialog(CreateTvrScreen(employee: widget.employee)),
              ),
              _buildDrawerItem(
                Icons.add_location_alt, 
                "REGISTER SITE", 
                // Assuming AddSiteForm uses a full-screen scaffold, push it.
                // If it's small, use _openDialog. It looked full-screen in code.
                () => _openFullScreen(AddSiteForm(employee: widget.employee)),
              ),

              const Divider(color: Colors.white24),

              // --- SECTION 2: APPROVALS ---
              _buildSectionHeader("APPROVALS (TSE)"),
              _buildDrawerItem(
                Icons.verified_user, 
                "APPROVE KYC", 
                () => _openFullScreen(const ApproveMasonKycScreen()),
              ),
              _buildDrawerItem(
                Icons.shopping_bag, 
                "APPROVE BAG LIFTS", 
                () => _openFullScreen(const ApproveMasonBagLift()),
              ),
              _buildDrawerItem(
                Icons.card_giftcard, 
                "APPROVE REWARDS", 
                () => _openFullScreen(const ApproveMasonRewardsScreen()),
              ),

              const Divider(color: Colors.white24),

              // --- SECTION 3: GENERAL ---
              _buildSectionHeader("GENERAL"),
              _buildDrawerItem(
                Icons.event_note, 
                "APPLY FOR LEAVE", 
                () => _openDialog(CreateLeaveFormScreen(employee: widget.employee)),
              ),
              _buildDrawerItem(
                Icons.task_alt, 
                "DAILY TASKS", 
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
      ),

      // --- 2. MAIN BODY ---
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      // --- 3. BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: darkBackground,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, -2))
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor: darkBackground, 
          indicatorColor: accentYellow, 
          height: 65,
          elevation: 0,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_filled, color: Colors.white70),
              selectedIcon: Icon(Icons.home_filled, color: Colors.black),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.apartment, color: Colors.white70),
              selectedIcon: Icon(Icons.apartment, color: Colors.black),
              label: 'Sites',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined, color: Colors.white70),
              selectedIcon: Icon(Icons.map_outlined, color: Colors.black),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white38, 
          fontSize: 11, 
          fontWeight: FontWeight.bold, 
          letterSpacing: 1.2
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: accentYellow, size: 24),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
          letterSpacing: 0.5
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      hoverColor: Colors.white.withOpacity(0.1),
    );
  }
}

// --- Simple Placeholder for Tabs ---
class _TechnicalPlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  const _TechnicalPlaceholderScreen({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "Technical Side: $title", 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54)
            ),
            const SizedBox(height: 8),
            const Text("Feature under construction", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}