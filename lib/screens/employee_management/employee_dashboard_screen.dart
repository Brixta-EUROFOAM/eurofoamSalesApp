// lib/screens/employee_management/employee_dashboard_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:salesmanapp/models/employee_model.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

import 'package:salesmanapp/screens/forms/add_dealer_form.dart';
import 'package:salesmanapp/screens/forms/create_dvr.dart';
import 'package:salesmanapp/screens/forms/create_competition_form.dart';
// REMOVED: import 'package:salesmanapp/screens/forms/create_daily_task_form.dart';
// ADDED: Import SalesOrderScreen to navigate to it from Ops
import 'package:salesmanapp/screens/employee_management/employee_salesorder_screen.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  final Employee employee;
  const EmployeeDashboardScreen({super.key, required this.employee});

  @override
  State<EmployeeDashboardScreen> createState() => EmployeeDashboardScreenState();
}

class EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  
  bool _isCheckingIn = false;
  bool _isCheckingOut = false;
  bool _isCheckedIn = false; 
  DateTime? _lastCheckInTime;
  String _greeting = 'Good Morning';

  // --- FINTECH THEME PALETTE ---
  final Color _bgLight       = const Color(0xFFF3F4F6); 
  final Color _cardNavy      = const Color(0xFF0F172A); 
  final Color _textDark      = const Color(0xFF111827); 
  final Color _textGrey      = const Color(0xFF6B7280); 
  final Color _surfaceWhite  = Colors.white;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setGreeting();
    refreshData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refreshData();
  }

  void refreshData() {
    if (mounted) {
      _setGreeting();
      _checkAttendanceStatus(); 
    }
  }

  Future<void> _checkAttendanceStatus() async {
    try {
      final att = await _apiService.fetchTodaysAttendance(int.parse(widget.employee.id), role: 'SALES');
      if (mounted) {
        setState(() {
          _isCheckedIn = att.checkOutTime == null;
          _lastCheckInTime = att.createdAt; 
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isCheckedIn = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) _greeting = 'Good Morning';
    else if (hour < 17) _greeting = 'Good Afternoon';
    else _greeting = 'Good Evening';
  }

  // --- ACTIONS ---

  void _showSalesmanOps(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Sales Operations", style: TextStyle(color: _textDark, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildActionSheetItem(
                  icon: Icons.description_outlined,
                  title: "Create DVR",
                  subtitle: "Daily Visit Report",
                  iconBg: const Color(0xFFEFF6FF),
                  iconColor: Colors.blue,
                  onTap: () => _openDialog(CreateDvrScreen(employee: widget.employee)),
                ),
                _buildActionSheetItem(
                  icon: Icons.store_mall_directory_outlined,
                  title: "Add Dealer",
                  subtitle: "Register new dealer",
                  iconBg: const Color(0xFFF0FDF4),
                  iconColor: Colors.green,
                  onTap: () => _openDialog(AddDealerForm(employee: widget.employee)),
                ),
                _buildActionSheetItem(
                  icon: Icons.assessment_outlined,
                  title: "Competition Form",
                  subtitle: "Market intelligence report",
                  iconBg: const Color(0xFFFFF7ED),
                  iconColor: Colors.orange,
                  onTap: () => _openDialog(CreateCompetitionFormScreen(employee: widget.employee)),
                ),
                // NEW: Sales Order Item (Moved from Bottom Nav)
                _buildActionSheetItem(
                  icon: Icons.shopping_cart_outlined,
                  title: "Sales Orders",
                  subtitle: "Manage orders",
                  iconBg: const Color(0xFFF3E8FF), // Purple-ish background
                  iconColor: Colors.purple,
                  // SalesOrderScreen is a full screen, not a dialog usually, but _openDialog works if it handles it.
                  // Or navigate push. Let's use push for full screen feel.
                  onTap: () {
                    Navigator.pop(context); // Close bottom sheet first
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => SalesOrderScreen(employee: widget.employee))
                    );
                  },
                ),
                // REMOVED: Assign Task (CreateDailyTaskScreen)
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleCheckIn() async => _performAttendanceAction(true);
  Future<void> _handleCheckOut() async => _performAttendanceAction(false);

  Future<void> _performAttendanceAction(bool isCheckIn) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => isCheckIn ? _isCheckingIn = true : _isCheckingOut = true);
    
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
      if (image == null) throw Exception("Photo required");
      
      final pos = await Geolocator.getCurrentPosition();
      final imageUrl = await _apiService.uploadImageToR2(File(image.path));
      
      if (isCheckIn) {
        final data = {
          'userId': int.parse(widget.employee.id),
          'role': 'SALES',
          'attendanceDate': DateTime.now().toIso8601String(),
          'locationName': 'Live Location',
          'inTimeLatitude': pos.latitude,
          'inTimeLongitude': pos.longitude,
          'inTimeImageUrl': imageUrl,
          'inTimeImageCaptured': true,
        };
        final res = await _apiService.checkIn(data);
        if (mounted) setState(() { _isCheckedIn = true; _lastCheckInTime = res.createdAt; });
      } else {
        if (_lastCheckInTime != null && DateTime.now().difference(_lastCheckInTime!).inMinutes < 30) {
           throw Exception("Minimum 30 mins shift required.");
        }
        final data = {
          'userId': int.parse(widget.employee.id),
          'role': 'SALES',
          'attendanceDate': DateTime.now().toIso8601String(),
          'outTimeImageUrl': imageUrl,
          'outTimeImageCaptured': true,
          'outTimeLatitude': pos.latitude,
          'outTimeLongitude': pos.longitude,
        };
        await _apiService.checkOut(data);
        if (mounted) setState(() => _isCheckedIn = false);
      }
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(isCheckIn ? 'Checked In!' : 'Checked Out!'), backgroundColor: Colors.green));
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => isCheckIn ? _isCheckingIn = false : _isCheckingOut = false);
    }
  }

  void _openDialog(Widget page) {
    Navigator.pop(context); // Close bottom sheet
    showDialog(context: context, builder: (_) => Dialog(backgroundColor: Colors.transparent, insetPadding: const EdgeInsets.all(16), child: page));
  }

  @override
  Widget build(BuildContext context) {
    String userArea = "N/A";
    try { userArea = (widget.employee as dynamic).area ?? "N/A"; } catch (_) {}

    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: _bgLight,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 70,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: Text(widget.employee.displayName[0], style: TextStyle(color: _cardNavy, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting, style: TextStyle(color: _textGrey, fontSize: 12, fontWeight: FontWeight.w500)),
                Text(widget.employee.displayName, style: TextStyle(color: _textDark, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => refreshData(),
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            // --- 1. HERO ATTENDANCE CARD ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _cardNavy,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: _cardNavy.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 8))],
                gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text("Attendance Status", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                    const Icon(Icons.access_time, color: Colors.white54, size: 18),
                  ]),
                  const SizedBox(height: 24),
                  Text(_isCheckedIn ? "Checked In" : "Ready to Start?", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Icon(Icons.location_on, color: Colors.white.withOpacity(0.7), size: 14),
                    const SizedBox(width: 4),
                    Text('Area: $userArea', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                  ]),
                  const SizedBox(height: 32),
                  Row(children: [
                    Expanded(child: _buildGlassButton("CHECK IN", Icons.login, _isCheckingIn, !_isCheckedIn, _isCheckedIn ? null : _handleCheckIn)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildGlassButton("CHECK OUT", Icons.logout, _isCheckingOut, _isCheckedIn, !_isCheckedIn ? null : _handleCheckOut)),
                  ]),
                ],
              ),
            ).animate().slideY(begin: 0.1, duration: 400.ms),

            const SizedBox(height: 32),
            Text("Operations", style: TextStyle(color: _textDark, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // --- 2. SALES OPS TRIGGER ---
            _buildFintechCard(
              title: "Sales Operations",
              subtitle: "Dealers, DVRs, Competition",
              icon: Icons.business_center_outlined,
              iconColor: Colors.blueAccent,
              iconBg: const Color(0xFFEFF6FF),
              onTap: () => _showSalesmanOps(context),
            ).animate().slideY(begin: 0.2, duration: 500.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassButton(String label, IconData icon, bool loading, bool active, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: loading 
          ? Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: active ? _cardNavy : Colors.white, strokeWidth: 2)))
          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 18, color: active ? _cardNavy : Colors.white),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: active ? _cardNavy : Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ]),
      ),
    );
  }

  Widget _buildFintechCard({required String title, required String subtitle, required IconData icon, required Color iconColor, required Color iconBg, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _surfaceWhite, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))]),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: iconColor, size: 26)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: _textDark, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: _textGrey, fontSize: 13)),
          ])),
          // CHANGED: Replaced Icon with Text "Open"
          const Text(
            "Open",
            style: TextStyle(
              color: Colors.blue, // Blue text
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildActionSheetItem({required IconData icon, required String title, required String subtitle, required Color iconBg, required Color iconColor, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      onTap: onTap,
      leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: iconColor, size: 24)),
      title: Text(title, style: TextStyle(color: _textDark, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(color: _textGrey, fontSize: 12)),
    );
  }
}