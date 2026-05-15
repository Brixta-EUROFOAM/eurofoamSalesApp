// lib/screens/homeScreen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/api_service.dart';
import '../models/users_model.dart';
import '../models/attendance_model.dart';
import '../widgets/ReusableFunctions.dart';
import 'forms/create_DVR_form.dart';
import 'forms/add_dealer_form.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();

  UserModel? _currentUser;
  bool _isLoading = true;

  bool _isCheckingIn = false;
  bool _isCheckingOut = false;

  // Attendance State
  bool _hasCheckedInToday = false;
  DateTime? _checkInTime;
  String _currentAddress = "Fetching location...";
  String _greeting = 'Good Morning';

  // --- THEME PALETTE ---
  final Color _bgLight = const Color(0xFFF3F4F6);
  final Color _cardNavy = const Color(0xFF0F172A);
  final Color _textDark = const Color(0xFF111827);
  final Color _textGrey = const Color(0xFF6B7280);
  final Color _surfaceWhite = Colors.white;

  @override
  void initState() {
    super.initState();
    _setGreeting();
    _loadInitialData();
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good Morning';
    } else if (hour < 17) {
      _greeting = 'Good Afternoon';
    } else {
      _greeting = 'Good Evening';
    }
  }

  Future<void> _loadInitialData() async {
    try {
      final storage = const FlutterSecureStorage();
      final userJson = await storage.read(key: 'user_profile');
      if (userJson != null) {
        _currentUser = UserModel.fromJson(jsonDecode(userJson));
      }

      final history = await _apiService.getAttendanceHistory();
      if (history.isNotEmpty) {
        final latestRecord = history.first;

        // --- DAILY RESET GUARD ---
        // Ensure the record is actually from TODAY before marking as checked in
        final isRecordFromToday =
            latestRecord.inTimeTimestamp != null &&
            DateUtils.isSameDay(latestRecord.inTimeTimestamp!, DateTime.now());

        if (isRecordFromToday) {
          if (mounted) {
            setState(() {
              _hasCheckedInToday = latestRecord.outTimeTimestamp == null;
              _checkInTime = latestRecord.inTimeTimestamp;
              if (latestRecord.locationName != null) {
                _currentAddress = latestRecord.locationName!;
              }
            });
          }
        } else {
          // It's a new day! Ensure they appear as NOT checked in.
          if (mounted) {
            setState(() {
              _hasCheckedInToday = false;
              _checkInTime = null;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading initial data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCheckIn() async {
    setState(() => _isCheckingIn = true);
    await _processAttendance(isCheckIn: true);
  }

  Future<void> _handleCheckOut() async {
    // --- 60 MINUTE GAP ENFORCEMENT ---
    if (_checkInTime != null) {
      final difference = DateTime.now().difference(_checkInTime!);
      if (difference.inMinutes < 60) {
        final minutesLeft = 60 - difference.inMinutes;

        // Show a warning and stop the checkout process
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Too early to check out! Wait $minutesLeft more minute(s).",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.orange.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }
    // ---------------------------------

    setState(() => _isCheckingOut = true);
    await _processAttendance(isCheckIn: false);
  }

  Future<void> _processAttendance({required bool isCheckIn}) async {
    try {
      // 1. Get Location & Address
      final locationResult =
          await ReusableFunctions.getCurrentLocationAndAddress();

      // 2. Open Camera for Selfie
      final photo = await ReusableFunctions.captureImage();
      if (photo == null) {
        _showErrorSnackBar('Attendance cancelled: Photo required.');
        return;
      }

      // 3. Upload Photo
      String imageUrl;
      try {
        imageUrl = await _apiService.uploadPhoto(File(photo.path));
      } catch (e) {
        _showErrorSnackBar('Photo upload failed. Please try again.');
        return;
      }

      // 4. Build Model
      final attendanceRecord = AttendanceModel(
        id: "0",
        userId: _currentUser?.id ?? 0,
        attendanceDate: DateTime.now(),
        locationName: locationResult.address,

        // Image Booleans
        inTimeImageCaptured: isCheckIn,
        outTimeImageCaptured: !isCheckIn,

        inTimeImageUrl: isCheckIn ? imageUrl : null,
        outTimeImageUrl: !isCheckIn ? imageUrl : null,

        inTimeLatitude: isCheckIn ? locationResult.latitude : 0.0,
        inTimeLongitude: isCheckIn ? locationResult.longitude : 0.0,
        outTimeLatitude: !isCheckIn ? locationResult.latitude : 0.0,
        outTimeLongitude: !isCheckIn ? locationResult.longitude : 0.0,

        inTimeTimestamp: isCheckIn
            ? DateTime.now()
            : (_checkInTime ?? DateTime.now()),
        outTimeTimestamp: !isCheckIn ? DateTime.now() : null,
      );

      // 5. Submit to API
      bool success;
      if (isCheckIn) {
        success = await _apiService.markAttendanceIn(attendanceRecord);
      } else {
        success = await _apiService.markAttendanceOut(attendanceRecord);
      }

      if (success) {
        setState(() {
          if (isCheckIn) {
            _hasCheckedInToday = true;
            _checkInTime = DateTime.now();
            _currentAddress = locationResult.address;
          } else {
            _hasCheckedInToday = false;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCheckIn
                  ? 'Checked In Successfully!'
                  : 'Checked Out Successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showErrorSnackBar('Failed to mark attendance on server.');
      }
    } catch (e) {
      _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingIn = false;
          _isCheckingOut = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _bgLight,
        body: Center(child: CircularProgressIndicator(color: _cardNavy)),
      );
    }

    final String displayName = _currentUser?.username ?? 'Salesman';
    final String initial = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : 'S';

    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: _bgLight,
        elevation: 0,
        automaticallyImplyLeading:
            false, // Ensures no back button or hamburger menu
        toolbarHeight: 70,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: Text(
                initial,
                style: TextStyle(color: _cardNavy, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting,
                    style: TextStyle(
                      color: _textGrey,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    displayName,
                    style: TextStyle(
                      color: _textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).padding.bottom + 20,
          ),
          children: [
            // --- HERO ATTENDANCE CARD ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _cardNavy,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _cardNavy.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Attendance Status",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        DateFormat('MMM d, yyyy').format(DateTime.now()),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _hasCheckedInToday ? "Checked In" : "Ready to Start?",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.white.withOpacity(0.7),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _hasCheckedInToday && _checkInTime != null
                              ? "Since ${DateFormat('hh:mm a').format(_checkInTime!)} • $_currentAddress"
                              : 'Location: $_currentAddress',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: _buildGlassButton(
                          label: "CHECK IN",
                          icon: Icons.login,
                          loading: _isCheckingIn,
                          active: !_hasCheckedInToday,
                          onTap: _hasCheckedInToday ? null : _handleCheckIn,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildGlassButton(
                          label: "CHECK OUT",
                          icon: Icons.logout,
                          loading: _isCheckingOut,
                          active: _hasCheckedInToday,
                          onTap: !_hasCheckedInToday ? null : _handleCheckOut,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            Text(
              "Quick Actions",
              style: TextStyle(
                color: _textDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // --- SALES OPS CARDS ---
            _buildFintechCard(
              title: "Create DVR",
              subtitle: "Submit your Daily Visit Report",
              icon: Icons.assignment_add,
              iconColor: Colors.blueAccent,
              iconBg: const Color(0xFFEFF6FF),
              onTap: () {
                // This routes directly to the DVR form
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddDvrFormScreen()),
                );
              },
            ),

            const SizedBox(height: 14),
            _buildFintechCard(
              title: "Add Dealer",
              subtitle: "Register a new dealer/business",
              icon: Icons.storefront,
              iconColor: Colors.indigo,
              iconBg: const Color(0xFFEEF2FF),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddDealerForm()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required String label,
    required IconData icon,
    required bool loading,
    required bool active,
    required VoidCallback? onTap,
  }) {
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
            ? Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: active ? _cardNavy : Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: active ? _cardNavy : Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: active ? _cardNavy : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFintechCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surfaceWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: _textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: _textGrey, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
