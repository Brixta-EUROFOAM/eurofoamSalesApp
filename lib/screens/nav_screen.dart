// lib/navscreen.dart
import 'dart:ui'; // We still need this for the dialog's blur
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:assetarchiverflutter/screens/employee_management/employee_dashboard_screen.dart';
import 'package:assetarchiverflutter/screens/employee_management/employee_profile_screen.dart';
import 'package:assetarchiverflutter/screens/employee_management/employee_pjp_screen.dart';
import 'package:assetarchiverflutter/screens/employee_management/employee_journey_screen.dart';
import 'package:assetarchiverflutter/screens/employee_management/employee_salesorder_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:assetarchiverflutter/screens/forms/create_dvr.dart';
import 'package:assetarchiverflutter/screens/forms/create_tvr.dart';
import 'package:assetarchiverflutter/screens/forms/create_leave_form.dart';
import 'package:assetarchiverflutter/screens/forms/create_competition_form.dart';
import 'package:assetarchiverflutter/screens/forms/create_daily_task_form.dart';
import 'package:assetarchiverflutter/screens/forms/add_dealer_form.dart';

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

  // --- These are now handled by GlobalKeys, but are fine to leave ---
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

  // --- ✅ FIX: Add a GlobalKey for the PJP Screen ---
  final GlobalKey<EmployeePJPScreenState> _pjpKey =
      GlobalKey<EmployeePJPScreenState>();
  // --- END FIX ---

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
              key: _dashboardKey, // This key is used for refresh
              employee: widget.employee,
            ),
            EmployeePJPScreen(
              // --- ✅ FIX: Pass the key to the PJP Screen ---
              key: _pjpKey,
              // --- END FIX ---
              employee: widget.employee,
              onStartJourney: provider.startJourney,
              onPjpCreated: () {
                // When a PJP is created, refresh the dashboard too
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
            appBar: AppBar(
              title: Text(pageTitles[provider.selectedIndex]),
            ),
            drawer: _buildDrawer(context, widget.employee),
            body: Stack(
              children: [
                IndexedStack(index: provider.selectedIndex, children: pages),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildFloatingNavBar(context, provider),
                ),
              ],
            ),
            bottomNavigationBar: null, // Handled by the Stack
          );
        },
      ),
    );
  }

  Widget _buildFloatingNavBar(BuildContext context, NavProvider provider) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.checklist_rtl), label: 'PJP'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined), label: 'Sales Order'),
          BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined), label: 'Journey'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: provider.selectedIndex,
        onTap: (index) {
          // --- ✅ FIX: Call refresh methods directly using the keys ---
          if (index == 0) _dashboardKey.currentState?.refreshData();
          if (index == 1) _pjpKey.currentState?.refreshPjpList();
          // --- END FIX ---
          provider.changePage(index);
        },
      ),
    );
  }

  // --- DIALOG FUNCTIONS (WITH UI IMPROVEMENT) ---

  void _showAddDealerDialog(BuildContext context, Employee employee) {
    print(
        '>>> _showAddDealerDialog called in nav_screen.dart. Trying to show AddDealerForm...');
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        // --- ✅ UI FIX: Use theme surface color instead of hardcoded red ---
        backgroundColor: Theme.of(dialogContext).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
        clipBehavior: Clip.antiAlias,
        // --- END UI FIX ---
        child: AddDealerForm(employee: employee),
      ),
    );
  }

  void _showCreateDvrDialog(BuildContext context, Employee employee) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        // --- ✅ UI FIX: Use theme surface color instead of hardcoded red ---
        backgroundColor: Theme.of(dialogContext).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
        clipBehavior: Clip.antiAlias,
        // --- END UI FIX ---
        child: CreateDvrScreen(employee: employee),
      ),
    );
  }

  // --- These forms provide their own background, so transparent is correct ---
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

  // --- (Drawer code remains the same, it's already theme-aware) ---
  Widget _buildDrawer(BuildContext context, Employee employee) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
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
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
            ),
          ),
          _buildDrawerActionItem(context,
              icon: Icons.person_add_alt,
              text: 'ADD DEALER', onTap: () {
            print('>>> ADD DEALER button tapped!');
            Navigator.pop(context);
            _showAddDealerDialog(context, employee);
          }),
          _buildDrawerActionItem(context,
              icon: Icons.description_outlined,
              text: 'CREATE DVR', onTap: () {
            Navigator.pop(context);
            _showCreateDvrDialog(context, employee);
          }),
          _buildDrawerActionItem(context,
              icon: Icons.description, text: 'CREATE TVR', onTap: () {
            Navigator.pop(context);
            _showCreateTvrDialog(context, employee);
          }),
          _buildDrawerActionItem(context,
              icon: Icons.assessment_outlined,
              text: 'COMPETETION FORM', onTap: () {
            Navigator.pop(context);
            _showCompetitionFormDialog(context, employee);
          }),
          _buildDrawerActionItem(context,
              icon: Icons.account_box_sharp,
              text: 'APPLY FOR LEAVE', onTap: () {
            Navigator.pop(context);
            _showApplyForLeaveDialog(context, employee);
          }),
          _buildDrawerActionItem(context,
              icon: Icons.task_alt,
              text: 'CREATE DAILY TASK', onTap: () {
            Navigator.pop(context);
            _showCreateDailyTaskDialog(context, employee);
          }),
        ],
      ),
    );
  }

  Widget _buildDrawerActionItem(
    BuildContext context, {
    required IconData icon,
    required String text,
    VoidCallback? onTap,
  }) {
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