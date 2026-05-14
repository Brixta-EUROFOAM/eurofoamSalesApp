// lib/screens/homeScreen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/auth_service.dart';
import '../api/api_service.dart';
import '../models/users_model.dart';
import '../models/attendance_model.dart';
import '../widgets/ReusableFunctions.dart';
import 'loginScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isCheckingIn = false;

  // Attendance State
  bool _hasCheckedInToday = false;
  DateTime? _checkInTime;
  String _currentAddress = "Fetching location...";

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      // 1. Load User Profile from Secure Storage
      final storage = const FlutterSecureStorage();
      final userJson = await storage.read(key: 'user_profile');
      if (userJson != null) {
        _currentUser = UserModel.fromJson(jsonDecode(userJson));
      }

      // 2. Fetch today's attendance status from API
      final history = await _apiService.getAttendanceHistory();
      if (history.isNotEmpty) {
        // Assuming the first record is today's (The API sorts by desc)
        final todayRecord = history.first;
        setState(() {
          // If they have an inTime but NO outTime, they are currently checked in.
          _hasCheckedInToday = todayRecord.outTimeTimestamp == null;
          _checkInTime = todayRecord.inTimeTimestamp;
        });
      }
    } catch (e) {
      print("Error loading initial data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Handles the complete Check-In / Check-Out flow
  Future<void> _handleAttendanceToggle() async {
    setState(() => _isCheckingIn = true);

    try {
      // 1. Get Location & Address using the centralized utility
      final locationResult =
          await ReusableFunctions.getCurrentLocationAndAddress();

      // 2. Open Camera for Selfie using the centralized utility
      final photo = await ReusableFunctions.captureImage();

      if (photo == null) {
        _showErrorSnackBar('Attendance cancelled: Photo required.');
        setState(() => _isCheckingIn = false);
        return;
      }

      // 3. Upload the photo to get the Supabase Public URL
      String imageUrl;
      try {
        imageUrl = await _apiService.uploadPhoto(File(photo.path));
      } catch (e) {
        _showErrorSnackBar('Photo upload failed. Please try again.');
        setState(() => _isCheckingIn = false);
        return;
      }

      // 4. Build Model & Submit to API
      final attendanceRecord = AttendanceModel(
        id: "0", // Backend will generate for IN, and auto-find active for OUT
        userId: _currentUser?.id ?? 0,
        attendanceDate: DateTime.now(),
        locationName: locationResult.address,

        // Image Booleans
        inTimeImageCaptured: !_hasCheckedInToday,
        outTimeImageCaptured: _hasCheckedInToday,

        // Assign the uploaded URL to the correct field
        inTimeImageUrl: !_hasCheckedInToday ? imageUrl : null,
        outTimeImageUrl: _hasCheckedInToday ? imageUrl : null,

        // GPS Coordinates
        inTimeLatitude: !_hasCheckedInToday ? locationResult.latitude : 0.0,
        inTimeLongitude: !_hasCheckedInToday ? locationResult.longitude : 0.0,
        outTimeLatitude: _hasCheckedInToday ? locationResult.latitude : 0.0,
        outTimeLongitude: _hasCheckedInToday ? locationResult.longitude : 0.0,

        // Timestamps
        inTimeTimestamp: !_hasCheckedInToday
            ? DateTime.now()
            : (_checkInTime ?? DateTime.now()),
        outTimeTimestamp: DateTime.now(),
      );

      // 5. Call the correct API split route
      bool success;
      if (!_hasCheckedInToday) {
        success = await _apiService.markAttendanceIn(attendanceRecord);
      } else {
        success = await _apiService.markAttendanceOut(attendanceRecord);
      }

      if (success) {
        setState(() {
          if (!_hasCheckedInToday) {
            _hasCheckedInToday = true;
            _checkInTime = DateTime.now();
            _currentAddress = locationResult.address;
          } else {
            _hasCheckedInToday = false; // Checked out
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _hasCheckedInToday
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
      // This will safely catch the Permission exceptions thrown from ReusableFunctions
      _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isCheckingIn = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final String dateString = DateFormat(
      'EEEE, MMMM d, yyyy',
    ).format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Salesman Dashboard'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: _buildDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Card
            Text(
              "Welcome back,",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              _currentUser?.username ?? "Salesman",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),

            // Attendance Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Today's Attendance",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          dateString,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),

                    // Status Indicator
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _hasCheckedInToday
                                ? Colors.green.shade50
                                : Colors.orange.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _hasCheckedInToday ? Icons.how_to_reg : Icons.login,
                            color: _hasCheckedInToday
                                ? Colors.green
                                : Colors.orange,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Status: ${_hasCheckedInToday ? 'Checked In' : 'Not Checked In'}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (_hasCheckedInToday && _checkInTime != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    "Since ${DateFormat('hh:mm a').format(_checkInTime!)}\n📍 $_currentAddress",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Main Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _isCheckingIn
                            ? null
                            : _handleAttendanceToggle,
                        icon: _isCheckingIn
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                _hasCheckedInToday
                                    ? Icons.logout
                                    : Icons.camera_alt,
                              ),
                        label: Text(
                          _hasCheckedInToday
                              ? "Check Out"
                              : "Check In with Photo",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _hasCheckedInToday
                              ? Colors.redAccent
                              : Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              "Quick Actions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Grid for quick actions
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildActionCard(
                  "Create DVR",
                  Icons.assignment_add,
                  Colors.blue,
                  () {
                    // Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateDvrScreen()));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    MaterialColor color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color.shade600, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Colors.blueAccent),
            accountName: Text(
              _currentUser?.username ?? 'Salesman',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text(_currentUser?.email ?? ''),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Colors.blueAccent),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Home'),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.assignment),
                  title: const Text('Daily Visit Reports (DVR)'),
                  onTap: () {
                    // Navigate to DVR List/Form
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.map),
                  title: const Text('Permanent Journey Plan (PJP)'),
                  onTap: () {
                    // Navigate to PJP
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.store),
                  title: const Text('Dealers Network'),
                  onTap: () {
                    // Navigate to Dealers
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.event_note),
                  title: const Text('Leave Management'),
                  onTap: () {
                    // Navigate to Leaves
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: _logout,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}