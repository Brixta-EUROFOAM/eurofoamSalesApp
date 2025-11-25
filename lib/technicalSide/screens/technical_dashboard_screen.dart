// lib/technicalSide/screens/technical_dashboard_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:assetarchiverflutter/technicalSide/screens/forms/create_tvr_form.dart';

class TechnicalDashboardScreen extends StatefulWidget {
  final Employee employee;

  const TechnicalDashboardScreen({
    super.key,
    required this.employee,
  });

  @override
  State<TechnicalDashboardScreen> createState() => _TechnicalDashboardScreenState();
}

class _TechnicalDashboardScreenState extends State<TechnicalDashboardScreen> with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  
  bool _isCheckingIn = false;
  bool _isCheckingOut = false;
  String _greeting = 'Good Morning';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setGreeting();
  }

  // --- Attendance & Location Logic (UNCHANGED) ---
  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {_greeting = 'Good Morning';}
    else if (hour < 17) {_greeting = 'Good Afternoon';}
    else {_greeting = 'Good Evening';};
  }
  
  Future<File?> _captureImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    return image == null ? null : File(image.path);
  }
  
  Future<Position?> _getCurrentPosition() async {
     try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return null;
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
        return null;
      }
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      return null;
    }
  }

  Future<void> _handleCheckIn() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _isCheckingIn = true);
    try {
      final position = await _getCurrentPosition();
      if (position == null) { if(mounted) setState(() => _isCheckingIn = false); return; }
      final imageFile = await _captureImage();
      if (imageFile == null) { if(mounted) setState(() => _isCheckingIn = false); return; }
      
      final imageUrl = await _apiService.uploadImageToR2(imageFile);
      final checkInData = {
        'userId': int.parse(widget.employee.id),
        'attendanceDate': DateTime.now().toIso8601String(),
        'locationName': 'Live Location',
        'inTimeLatitude': position.latitude,
        'inTimeLongitude': position.longitude,
        'inTimeImageUrl': imageUrl,
        'inTimeImageCaptured': true,
      };
      await _apiService.checkIn(checkInData);
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Checked in successfully!'), backgroundColor: Colors.green));
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Check-in failed: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isCheckingIn = false);
    }
  }
  
  Future<void> _handleCheckOut() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _isCheckingOut = true);
    try {
      final position = await _getCurrentPosition();
      if (position == null) { if(mounted) setState(() => _isCheckingOut = false); return; }
      final imageFile = await _captureImage();
      if (imageFile == null) { if(mounted) setState(() => _isCheckingOut = false); return; }
      
      final imageUrl = await _apiService.uploadImageToR2(imageFile);
      final checkOutData = {
        'userId': int.parse(widget.employee.id),
        'attendanceDate': DateTime.now().toIso8601String(),
        'outTimeImageUrl': imageUrl,
        'outTimeImageCaptured': true,
        'outTimeLatitude': position.latitude,
        'outTimeLongitude': position.longitude,
      };
      await _apiService.checkOut(checkOutData);
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Checked out successfully!'), backgroundColor: Colors.blue));
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Check-out failed: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isCheckingOut = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    setState(() { _setGreeting(); });
  }

  @override
@override
  Widget build(BuildContext context) {
    // 1. THEME CONSTANTS
    const scaffoldBg        = Color(0xFF020617);  // Almost-black navy
    const cardGradientStart = Color(0xFF0B4AA8);  // Brand Blue
    const cardGradientEnd   = Color(0xFF111827);  // Dark surface fade
    const secondaryColor    = Color(0xFFFFA000);  // Amber/Orange accent
    const surfaceDark       = Color(0xFF1E293B);  // Card background (Slate 800)

    String userArea = "N/A";
    try { userArea = (widget.employee as dynamic).area ?? "N/A"; } catch (_) {}

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        centerTitle: true,
        // --- 1. NEW MENU BUTTON ---
        // We wrap it in Padding + Container to give it a "physical" button look
        leadingWidth: 64, // Give it a bit more width to breathe
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
          child: InkWell(
            onTap: () => Scaffold.of(context).openDrawer(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: surfaceDark, // Distinct background for the button
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)), // Subtle border
              ),
              child: const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
            ),
          ),
        ),
        // --- 2. NEW TITLE STYLE ---
        title: const Text(
          'DASHBOARD',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900, // Extra bold
            letterSpacing: 1.5,         // Spaced out for readability
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: secondaryColor,
        backgroundColor: surfaceDark,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // 2. GREETING CARD (HERO)
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [cardGradientStart, cardGradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.white.withOpacity(0.15),
                              child: const Icon(Icons.engineering, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _greeting,
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: secondaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Technical',
                            style: TextStyle(
                              color: Colors.black, 
                              fontWeight: FontWeight.w900, 
                              fontSize: 11
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.employee.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white60, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Area: $userArea',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),

            // 3. ATTENDANCE BUTTONS
            Row(
              children: [
                Expanded(
                  child: _buildAttendanceButton(
                    label: 'CHECK IN',
                    icon: Icons.login,
                    isLoading: _isCheckingIn,
                    onTap: _isCheckingIn || _isCheckingOut ? null : _handleCheckIn,
                    bgColor: secondaryColor, 
                    textColor: Colors.black,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAttendanceButton(
                    label: 'CHECK OUT',
                    icon: Icons.logout,
                    isLoading: _isCheckingOut,
                    onTap: _isCheckingIn || _isCheckingOut ? null : _handleCheckOut,
                    bgColor: surfaceDark, 
                    textColor: Colors.white, 
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
            
            // 4. QUICK ACTIONS
            const Text(
              "QUICK ACTIONS",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildActionTile(
              title: "Create Technical Visit Report",
              subtitle: "Log site visit, complaint or conversion",
              icon: Icons.assignment_add,
              iconColor: cardGradientStart, 
              cardColor: surfaceDark,
              onTap: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => CreateTvrScreen(employee: widget.employee),
                );
              },
            ),
          ]
          .animate(interval: 50.ms)
          .fadeIn(duration: 400.ms)
          .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
        ),
      ),
    );
  }

  Widget _buildAttendanceButton({
    required String label,
    required IconData icon,
    required bool isLoading,
    required VoidCallback? onTap,
    required Color bgColor,
    required Color textColor,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          // Border removed for cleaner look in dark mode
          side: BorderSide.none,
        ),
        elevation: 0,
      ),
      child: isLoading 
        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: textColor, strokeWidth: 2))
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            ],
          ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color cardColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2), // Subtle accent bg
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24), // Icon uses brand color
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title, 
                      style: const TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.white // High contrast
                      )
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle, 
                      style: const TextStyle(
                        fontSize: 13, 
                        color: Colors.white54 // Medium contrast
                      )
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white24),
            ],
          ),
        ),
      ),
    );
  }
}