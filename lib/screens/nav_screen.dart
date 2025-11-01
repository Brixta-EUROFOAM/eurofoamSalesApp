// lib/navscreen.dart
import 'dart:ui'; // We still need this for the dialog's blur
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:assetarchiverflutter/screens/employee_management/employee_dashboard_screen.dart';
import 'package:assetarchiverflutter/screens/employee_management/employee_profile_screen.dart';
import 'package:assetarchiverflutter/screens/employee_management/employee_pjp_screen.dart';
import 'package:assetarchiverflutter/screens/employee_management/employee_journey_screen.dart';
import 'package:assetarchiverflutter/screens/employee_management/employee_salesorder_screen.dart';
// import 'package:assetarchiverflutter/widgets/reusableglasscard.dart'; // <-- 1. REMOVED
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:assetarchiverflutter/screens/forms/create_dvr.dart';
import 'package:assetarchiverflutter/screens/forms/create_tvr.dart';
import 'package:assetarchiverflutter/screens/forms/create_leave_form.dart';
import 'package:assetarchiverflutter/screens/forms/create_competition_form.dart';
import 'package:assetarchiverflutter/screens/forms/create_daily_task_form.dart';
import 'package:assetarchiverflutter/screens/forms/add_dealer_form.dart';
// No theme provider import is needed here

// --- (NavProvider class remains exactly the same) ---
class NavProvider with ChangeNotifier {
  int _selectedIndex = 0;
  Map<String, dynamic>? _journeyData;

  int get selectedIndex => _selectedIndex;
  Map<String, dynamic>? get journeyData => _journeyData;

  void changePage(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  void startJourney(Map<String, dynamic> data) {
    _journeyData = data;
    _selectedIndex = 3;
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
  final GlobalKey<EmployeeDashboardScreenState> _dashboardKey =
      GlobalKey<EmployeeDashboardScreenState>();

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

  @override
  Widget build(BuildContext context) {
    // --- 2. REMOVED all the 'isDarkMode' and 'glassColor' logic ---

    return ChangeNotifierProvider.value(
      value: _navProvider,
      child: Consumer<NavProvider>(
        builder: (context, provider, child) {
          final pageTitles = [
            'Home',
            'PJP',
            'Sales Order',
            'Journey',
            'Profile',
          ];

          final pages = <Widget>[
            EmployeeDashboardScreen(
              key: _dashboardKey,
              employee: widget.employee,
            ),
            EmployeePJPScreen(
              employee: widget.employee,
              onStartJourney: provider.startJourney,
              onPjpCreated: () {
                _dashboardKey.currentState?.refreshData();
                provider.refreshDashboard();
              },
            ),
            SalesOrderScreen(employee: widget.employee),
            EmployeeJourneyScreen(
              initialJourneyData: provider.journeyData,
              employee: widget.employee,
              onDestinationConsumed: provider.clearJourneyData,
            ),
            EmployeeProfileScreen(employee: widget.employee),
          ];

          return Scaffold(
            // --- 3. This is now a standard, theme-aware AppBar ---
            // It will get its color/style from app_theme.dart
            appBar: AppBar(
              title: Text(pageTitles[provider.selectedIndex]),
            ),
            
            // --- 4. The drawer is now standard ---
            drawer: _buildDrawer(context, widget.employee),
            
            // --- ✅ THEME FIX: Rebuilt the Scaffold Body ---
            // This Stack is how we make the nav bar float
            body: Stack(
              children: [
                IndexedStack(index: provider.selectedIndex, children: pages),
                
                // This is the floating nav bar
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildFloatingNavBar(context, provider),
                ),
              ],
            ),
            // We set this to null because it's now part of the body Stack
            bottomNavigationBar: null,
            // --- END FIX ---
          );
        },
      ),
    );
  }

  // --- ✅ NEW: Floating, Rounded Nav Bar ---
  // This widget creates the "floating" bar from your screenshot
  Widget _buildFloatingNavBar(BuildContext context, NavProvider provider) {
    final theme = Theme.of(context);
    
    return Card(
      // This margin makes it "float"
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 24), 
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0), // Rounded corners
      ),
      clipBehavior: Clip.antiAlias, // This cuts the corners
      child: BottomNavigationBar(
        // We make the bar transparent so the Card's color (from the theme) shows
        backgroundColor: Colors.transparent,
        elevation: 0, 
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.checklist_rtl), label: 'PJP'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Sales Order'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Journey'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: provider.selectedIndex,
        onTap: (index) {
          if (index == 0) provider.refreshDashboard();
          if (index == 1) provider.refreshPjpList();
          provider.changePage(index);
        },
        // All styling (colors, labels) now comes from app_theme.dart
        // (including the `show...Labels: true` fix we just made)
      ),
    );
  }
  // --- END NEW ---

  // --- (All dialog functions remain the same) ---
  void _showAddDealerDialog(BuildContext context, Employee employee) {
    print('>>> _showAddDealerDialog called in nav_screen.dart. Trying to show AddDealerForm...');
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color.fromARGB(184, 193, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
        child: AddDealerForm(employee: employee),
      ),
    );
  }
   void _showCreateDvrDialog(BuildContext context, Employee employee) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color.fromARGB(0, 140, 6, 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
        child: CreateDvrScreen(employee: employee),
      ),
    );
  }

  void _showCreateTvrDialog(BuildContext context, Employee employee) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: CreateTvrScreen(employee: employee),
      ),
    );
  }

  void _showApplyForLeaveDialog(BuildContext context, Employee employee) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: CreateLeaveFormScreen(employee: employee),
      ),
    );
  }

  void _showCompetitionFormDialog(BuildContext context, Employee employee) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: CreateCompetitionFormScreen(employee: employee),
      ),
    );
  }

  void _showCreateDailyTaskDialog(BuildContext context, Employee employee) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: CreateDailyTaskScreen(employee: employee),
      ),
    );
  }


  // --- ✅ NEW: Prettier, Themed Drawer ---
  // This replaces your old _buildGlassDrawer with a standard,
  // professional-looking UserAccountsDrawerHeader.
  Widget _buildDrawer(BuildContext context, Employee employee) {
    // Get all text styles directly from the theme
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Drawer(
      // The background color is now controlled by your theme
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // This is a much cleaner, standard header that matches your screenshot
          UserAccountsDrawerHeader(
            accountName: Text(
              employee.displayName,
              style: textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(
              employee.email ?? '',
              style: textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimary.withOpacity(0.8),
              ),
            ),
            // This pulls the blue from your "Good Morning" card
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
            ),
            // You can add a CircleAvatar here if you have a user image
            // currentAccountPicture: CircleAvatar(
            //   backgroundColor: theme.colorScheme.background,
            //   child: Text(
            //     "RH", // You'd getInitials() here
            //     style: TextStyle(color: theme.colorScheme.primary),
            //   ),
            // ),
          ),
          _buildDrawerActionItem(
              context,
              icon: Icons.person_add_alt,
              text: 'ADD DEALER',
              onTap: () {
                 print('>>> ADD DEALER button tapped!');
                 Navigator.pop(context);
                 _showAddDealerDialog(context, employee);
              }
            ),
            _buildDrawerActionItem(
              context,
              icon: Icons.description_outlined,
              text: 'CREATE DVR',
              onTap: () {
                Navigator.pop(context);
                // --- ✅ BUG FIX: Removed stray print statement ---
                _showCreateDvrDialog(context, employee);
              }
            ),
            _buildDrawerActionItem(
              context,
              icon: Icons.description,
              text: 'CREATE TVR',
               onTap: () {
                Navigator.pop(context);
                _showCreateTvrDialog(context, employee);
              }
            ),
            _buildDrawerActionItem(
              context,
              icon: Icons.assessment_outlined,
              text: 'COMPETETION FORM',
              onTap: () {
                Navigator.pop(context);
                _showCompetitionFormDialog(context, employee);
              }
            ),
            _buildDrawerActionItem(
              context,
              icon: Icons.account_box_sharp,
              text: 'APPLY FOR LEAVE',
              onTap: () {
                Navigator.pop(context);
                _showApplyForLeaveDialog(context, employee);
              }
            ),
            _buildDrawerActionItem(
              context,
              icon: Icons.task_alt,
              text: 'CREATE DAILY TASK',
              onTap: () {
                Navigator.pop(context);
                _showCreateDailyTaskDialog(context, employee);
              }
            ),
        ],
      ),
    );
  }

  // --- This widget is now fully theme-aware ---
  Widget _buildDrawerActionItem(
    BuildContext context, {
    required IconData icon,
    required String text,
    VoidCallback? onTap,
  }) {
    // Get colors directly from the theme
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.onSurface.withOpacity(0.7);
    final textColor = theme.colorScheme.onSurface;

    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(text, style: TextStyle(color: textColor)),
      onTap: onTap,
    );
  }
}