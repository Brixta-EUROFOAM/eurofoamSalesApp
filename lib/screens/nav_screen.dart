// lib/screens/nav_screen.dart
import 'dart:ui'; 
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:salesmanapp/models/employee_model.dart';
import 'package:salesmanapp/models/pjp_model.dart';
import 'package:salesmanapp/models/dealer_model.dart';

import 'package:salesmanapp/screens/employee_management/employee_dashboard_screen.dart';
import 'package:salesmanapp/screens/employee_management/employee_profile_screen.dart';
import 'package:salesmanapp/screens/employee_management/employee_pjp_screen.dart';
import 'package:salesmanapp/screens/employee_management/employee_journey_screen.dart';
import 'package:salesmanapp/screens/forms/create_dvr.dart';

// --- NavProvider ---
class NavProvider with ChangeNotifier {
  int _selectedIndex = 0;
  Map<String, dynamic>? _journeyData;

  int get selectedIndex => _selectedIndex;
  Map<String, dynamic>? get journeyData => _journeyData;

  void changePage(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  // ✅ Saves the entire journey map and navigates to Journey tab (now Index 2)
  void startJourney(Map<String, dynamic> data) {
    _journeyData = data; 
    _selectedIndex = 2; // Updated index for Journey
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

  // Keys to access state of children for refreshing
  final GlobalKey<EmployeeDashboardScreenState> _dashboardKey = GlobalKey<EmployeeDashboardScreenState>();
  final GlobalKey<EmployeePJPScreenState> _pjpKey = GlobalKey<EmployeePJPScreenState>();

  // --- 🎨 FINTECH THEME PALETTE ---
  static const Color _bgLight   = Color(0xFFF3F4F6); 
  static const Color _cardNavy  = Color(0xFF0F172A); 
  static const Color _textGrey  = Color(0xFF9CA3AF); 

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

  // --- Logic to open DVR upon Journey Completion ---
  void _showCreateDvrDialogFromJourney(
    BuildContext context,
    Employee employee,
    Pjp pjp,
    Dealer dealer,
    DateTime checkInTime,
  ) {
    dev.log('Auto-opening DVR for PJP ${pjp.id} at $checkInTime', name: 'NavScreen');
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: CreateDvrScreen(
          employee: employee,
          pjp: pjp,
          dealer: dealer,
          initialCheckInTime: checkInTime,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _navProvider,
      child: Consumer<NavProvider>(
        builder: (context, provider, child) {
          
          final pages = <Widget>[
            EmployeeDashboardScreen(
              key: _dashboardKey,
              employee: widget.employee,
            ),
            EmployeePJPScreen(
              key: _pjpKey,
              employee: widget.employee,
              onStartJourney: provider.startJourney,
              onPjpCreated: () {
                _dashboardKey.currentState?.refreshData();
                provider.refreshDashboard();
              },
            ),
            EmployeeJourneyScreen(
              initialJourneyData: provider.journeyData,
              employee: widget.employee,
              onDestinationConsumed: provider.clearJourneyData,
              onJourneyCompleted: (Pjp pjp, Dealer dealer, DateTime checkInTime) {
                _showCreateDvrDialogFromJourney(
                  context,
                  widget.employee,
                  pjp,
                  dealer,
                  checkInTime,
                );
              },
            ),
            EmployeeProfileScreen(employee: widget.employee),
          ];

          return Scaffold(
            backgroundColor: _bgLight,
            body: Stack(
              children: [
                IndexedStack(index: provider.selectedIndex, children: pages),
                
                // Floating Nav Bar
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildFloatingNavBar(context, provider),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFloatingNavBar(BuildContext context, NavProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.0),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: _cardNavy,
          unselectedItemColor: _textGrey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today_rounded), label: 'Visits'),
            BottomNavigationBarItem(icon: Icon(Icons.near_me_rounded), label: 'Journey'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
          currentIndex: provider.selectedIndex,
          onTap: (index) {
            if (index == 0) _dashboardKey.currentState?.refreshData();
            if (index == 1) _pjpKey.currentState?.refreshPjpList();
            provider.changePage(index);
          },
        ),
      ),
    );
  }
}