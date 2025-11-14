import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:flutter/material.dart';

// Import the dashboard screen to be used as the first tab
import 'admin_dashboard_screen.dart';

class AdminNavScreen extends StatefulWidget {
  final Employee employee;
  const AdminNavScreen({super.key, required this.employee});

  @override
  State<AdminNavScreen> createState() => _AdminNavScreenState();
}

class _AdminNavScreenState extends State<AdminNavScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Define the pages for the bottom navigation
    _pages = [
      // --- TAB 1: The Dashboard you already built ---
      AdminDashboard(employee: widget.employee),

      // --- TAB 2: Placeholder for All Masons ---
      const _PlaceholderScreen(
        title: 'All Masons',
        icon: Icons.groups_outlined,
      ),

      // --- TAB 3: Placeholder for Reports ---
      const _PlaceholderScreen(
        title: 'Reports',
        icon: Icons.bar_chart_outlined,
      ),

      // --- TAB 4: Profile & Logout ---
      _ProfileScreen(employee: widget.employee),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        // --- This makes it beautiful ---
        type: BottomNavigationBarType.fixed, // Good for 4+ items
        backgroundColor: theme.cardColor,
        selectedItemColor: Colors.orange, // Your brand color
        unselectedItemColor: Colors.grey[600],
        selectedFontSize: 12,
        unselectedFontSize: 12,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.pending_actions_outlined),
            activeIcon: Icon(Icons.pending_actions),
            label: 'Pending KYC',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined),
            activeIcon: Icon(Icons.groups),
            label: 'Masons',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// --- A Reusable Placeholder Screen ---
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  const _PlaceholderScreen({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 100, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[400],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- A Simple Profile & Logout Screen ---
class _ProfileScreen extends StatelessWidget {
  final Employee employee;
  const _ProfileScreen({required this.employee});

  void _logout(BuildContext context) {
    // TODO: Call an ApiService.logout() method if it exists
    // For now, just navigate
    Navigator.of(context).pushNamedAndRemoveUntil('/selector', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                child: Text(
                  employee.displayName.isNotEmpty ? employee.displayName[0] : 'A',
                  style: const TextStyle(fontSize: 40),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                employee.displayName,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                employee.email ?? 'No Email',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Text(
                'Role: ${employee.role ?? 'N/A'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _logout(context),
                child: const Text('LOG OUT'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}