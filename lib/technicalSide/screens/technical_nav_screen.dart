// lib/technicalSide/screens/technical_nav_screen.dart
import 'package:flutter/material.dart';
import 'package:assetarchiverflutter/models/employee_model.dart';
// Screens
import 'package:assetarchiverflutter/technicalSide/screens/technical_dashboard_screen.dart';
import 'package:assetarchiverflutter/technicalSide/screens/technical_profile_screen.dart'; // ✅ Import the new Profile

// Forms
import 'package:assetarchiverflutter/technicalSide/screens/forms/create_tvr_form.dart';
import 'package:assetarchiverflutter/screens/forms/create_leave_form.dart';

class TechnicalNavScreen extends StatefulWidget {
  final Employee employee;
  const TechnicalNavScreen({super.key, required this.employee});

  @override
  State<TechnicalNavScreen> createState() => _TechnicalNavScreenState();
}

class _TechnicalNavScreenState extends State<TechnicalNavScreen> {
  int _selectedIndex = 0;

  // Define the pages for the Technical User
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      // 0: Home (Dashboard)
      TechnicalDashboardScreen(employee: widget.employee),
      
      
      
      
      // 2: Sites (Placeholder)
      const _TechnicalPlaceholderScreen(title: "Technical Sites", icon: Icons.apartment),
      
      // 3: Journey (Placeholder)
      const _TechnicalPlaceholderScreen(title: "Technical Journey", icon: Icons.map),
      
      // 4: Profile (✅ Technical Version)
      TechnicalProfileScreen(employee: widget.employee), 
    ];
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  // --- DRAWER ACTIONS ---
  void _showCreateTvrForm() {
    Navigator.pop(context); // Close drawer first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CreateTvrScreen(employee: widget.employee),
    );
  }

  void _showApplyLeaveForm() {
    Navigator.pop(context); // Close drawer first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CreateLeaveFormScreen(employee: widget.employee),
    );
  }

  @override
  Widget build(BuildContext context) {
    //final theme = Theme.of(context);
    
    // --- SALESMAN THEME COLORS ---
    const primaryColor = Color(0xFF0D47A1); // Deep Blue
    const secondaryColor = Color(0xFFFFA000); // Amber/Orange

    return Scaffold(
      // --- 1. THE SIDE DRAWER ---
      drawer: Drawer(
        child: Container(
          color: const Color.fromARGB(255, 27, 114, 219),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  color: primaryColor, 
                ),
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
                        color: secondaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    )
                  ],
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    widget.employee.firstName?.substring(0, 1).toUpperCase() ?? "T",
                    style: const TextStyle(fontSize: 32, color: primaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              
              // --- Technical Forms ---
              _buildDrawerItem(Icons.assignment_add, "CREATE TVR", _showCreateTvrForm, primaryColor),
              _buildDrawerItem(Icons.add_location_alt, "REGISTER SITE", () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Site Registration - Coming Soon")));
              }, primaryColor),
              
              const Divider(),
              
              // --- Shared/Admin Forms ---
              _buildDrawerItem(Icons.event_note, "APPLY FOR LEAVE", _showApplyLeaveForm, primaryColor),
              _buildDrawerItem(Icons.task_alt, "DAILY TASKS", () {
                 Navigator.pop(context);
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Daily Tasks - Coming Soon")));
              }, primaryColor),
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
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, -2))
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor: const Color.fromARGB(255, 27, 114, 219), 
          indicatorColor: secondaryColor.withOpacity(0.4), 
          height: 65,
          elevation: 0,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_filled),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.place_rounded),
              label: 'PJP',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              label: 'Journey',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  ListTile _buildDrawerItem(IconData icon, String title, VoidCallback onTap, Color iconColor) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      onTap: onTap,
    );
  }
}

// --- Simple Placeholder for PJP, Sales, Journey ---
class _TechnicalPlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  const _TechnicalPlaceholderScreen({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0D47A1); 

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: primaryColor,
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
            Text("Technical Side: $title", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 8),
            const Text("Feature under construction", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}