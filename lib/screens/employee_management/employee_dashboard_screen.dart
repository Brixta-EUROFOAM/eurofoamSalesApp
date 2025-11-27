// lib/screens/employee_management/employee_dashboard_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:salesmanapp/models/employee_model.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/models/pjp_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart'; // <-- ✅ NEW IMPORT
import 'dart:developer' as dev; // <-- ✅ NEW IMPORT

// --- ✅ NEW: A helper class to hold all our new data ---
class DashboardPjpData {
  final List<Pjp> ongoing;
  final List<Pjp> upcomingToday;
  final List<Pjp> tomorrow;
  DashboardPjpData({
    required this.ongoing,
    required this.upcomingToday,
    required this.tomorrow,
  });
}
// ---

class EmployeeDashboardScreen extends StatefulWidget {
  final Employee employee;

  const EmployeeDashboardScreen({
    super.key,
    required this.employee,
  });

  @override
  State<EmployeeDashboardScreen> createState() => EmployeeDashboardScreenState();
}

class EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  
  // --- ✅ MODIFIED: The future is now for our new data class ---
  late Future<DashboardPjpData> _pjpFuture;
  
  bool _isCheckingIn = false;
  bool _isCheckingOut = false;
  String _greeting = 'Good Morning';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setGreeting();
    refreshData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      refreshData();
    }
  }

  // --- ✅ NEW: Helper to get YYYY-MM-DD string ---
  String _isoDate(DateTime dt) {
    return DateFormat('yyyy-MM-dd').format(dt);
  }

  // --- ✅ NEW: This function fetches all the data you wanted ---
  Future<DashboardPjpData> _fetchDashboardData() async {
    final uid = int.tryParse(widget.employee.id);
    if (uid == null) throw Exception('Invalid Employee ID');

    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    
    final todayString = _isoDate(today);
    final tomorrowString = _isoDate(tomorrow);

    dev.log('Fetching Dashboard Data for $todayString & $tomorrowString', name: 'Dashboard');

    // Fetch all 3 lists in parallel
    final results = await Future.wait([
      // 1. "Going on right now"
      _apiService.fetchPjpsForUser(
        uid,
        status: 'started', 
      ),
      
      // 2. "Coming up today"
      _apiService.fetchPjpsForUser(
        uid,
        status: 'APPROVED', 
        startDate: todayString,
        endDate: todayString,
      ),
      
      // 3. "Tomorrow"
       _apiService.fetchPjpsForUser(
        uid,
        status: 'APPROVED', 
        startDate: tomorrowString,
        endDate: tomorrowString,
      ),
    ]);

    return DashboardPjpData(
      ongoing: results[0],
      upcomingToday: results[1],
      tomorrow: results[2],
    );
  }

  // --- ✅ MODIFIED: These functions now call the new fetch method ---
  void refreshData() {
    if (mounted) {
      setState(() {
        _pjpFuture = _fetchDashboardData();
      });
    }
  }

  Future<void> _handleRefresh() async {
    final newPjpFuture = _fetchDashboardData();
    if (mounted) {
      setState(() {
        _pjpFuture = newPjpFuture;
      });
    }
    await newPjpFuture;
  }
  // ---

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // --- (All other methods like _setGreeting, _captureImage, _handleCheckIn, etc. are UNCHANGED) ---
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
  
  Future<File?> _captureImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 50,
    );
    if (image != null) {
      return File(image.path);
    }
    return null;
  }
  
  Future<Position?> _getCurrentPosition() async {
     try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return null;
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
        return null;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (!mounted) return null;
        if (permission == LocationPermission.denied) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied')));
           return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return null;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.')));
        return null;
      }
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
      }
      return null;
    }
  }

  Future<void> _handleCheckIn() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _isCheckingIn = true);
    try {
      final position = await _getCurrentPosition();
      if (position == null) {
        if(mounted) setState(() => _isCheckingIn = false);
        return;
      }
      final imageFile = await _captureImage();
      if (imageFile == null) {
        if(mounted) setState(() => _isCheckingIn = false);
        return;
      }
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Uploading image...')));
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
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Checked in successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Check-in failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isCheckingIn = false);
    }
  }
  
  Future<void> _handleCheckOut() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _isCheckingOut = true);
    try {
      final position = await _getCurrentPosition();
      if (position == null) {
         if(mounted) setState(() => _isCheckingOut = false);
        return;
      }
      final imageFile = await _captureImage();
      if (imageFile == null) {
        if(mounted) setState(() => _isCheckingOut = false);
        return;
      }
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Uploading image...')));
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
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Checked out successfully!'), backgroundColor: Colors.blue),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Check-out failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isCheckingOut = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: theme.colorScheme.onPrimary,
        backgroundColor: theme.colorScheme.primary,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- (Greeting Card is unchanged) ---
            Card(
              color: theme.brightness == Brightness.light 
                     ? theme.colorScheme.primary
                     : theme.colorScheme.surface, 
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting, 
                      style: textTheme.bodyLarge?.copyWith(
                        color: theme.brightness == Brightness.light
                               ? theme.colorScheme.onPrimary.withOpacity(0.8)
                               : theme.colorScheme.onSurface.withOpacity(0.7)
                      )
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.employee.displayName,
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold, 
                        color: theme.brightness == Brightness.light
                               ? theme.colorScheme.onPrimary
                               : theme.colorScheme.onSurface
                      ),
                      textAlign: TextAlign.start,
                    ),
                    if (widget.employee.companyName != null && widget.employee.companyName!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          widget.employee.companyName!,
                          style: textTheme.bodyMedium?.copyWith(
                            color: theme.brightness == Brightness.light
                               ? theme.colorScheme.onPrimary.withOpacity(0.8)
                               : theme.colorScheme.onSurface.withOpacity(0.7)
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- (Check In/Out buttons are unchanged) ---
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: _isCheckingIn 
                        ? const SizedBox(width: 18, height: 45, child: CircularProgressIndicator(strokeWidth: 2)) 
                        : const Icon(Icons.arrow_forward, size: 50), 
                    label: const Text('Check In'),
                    onPressed: _isCheckingIn || _isCheckingOut ? null : _handleCheckIn,
                  ),
                ),
                const SizedBox(height: 16), 
                SizedBox(
                  width: double.infinity, 
                  child: ElevatedButton.icon(
                    icon: _isCheckingOut 
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) 
                        : const Icon(Icons.arrow_back, size: 50),
                    label: const Text('Check Out'),
                    onPressed: _isCheckingIn || _isCheckingOut ? null : _handleCheckOut,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- ✅ THIS IS THE ENTIRELY NEW, SMART FUTUREBUILDER ---
            FutureBuilder<DashboardPjpData>(
              future: _pjpFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return Card(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0), 
                        child: CircularProgressIndicator(color: theme.colorScheme.primary)
                      ),
                    ),
                  );
                }
                
                if (snapshot.hasError) {
                  return Card(
                    color: theme.colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'Error fetching PJP data: ${snapshot.error}', 
                          style: TextStyle(color: theme.colorScheme.onErrorContainer)
                        )
                      ),
                    ),
                  );
                }

                // We have data!
                final data = snapshot.data!;
                final bool noPjpsFound = data.ongoing.isEmpty && data.upcomingToday.isEmpty && data.tomorrow.isEmpty;

                if (noPjpsFound) {
                  return Card(
                     child: Padding(
                       padding: const EdgeInsets.all(24.0),
                       child: Center(
                        child: Text(
                          'No active PJPs found for today or tomorrow.', 
                          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7))
                        )
                      ),
                     ),
                  );
                }

                // Build the new UI
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 1. "ONGOING" SECTION ---
                    if (data.ongoing.isNotEmpty) ...[
                      Text(
                        "Journey in Progress",
                        style: textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Loop over all ongoing PJPs
                      ...data.ongoing.map((pjp) => 
                        _buildOngoingPjpCard(pjp, theme)
                      ).toList(),
                      const SizedBox(height: 24),
                    ],

                    // --- 2. "UPCOMING TODAY" SECTION ---
                    _buildUpcomingPjpList(
                      data.upcomingToday, 
                      "Upcoming Today",
                      theme,
                    ),

                    // --- 3. "TOMORROW'S PLAN" SECTION ---
                    _buildUpcomingPjpList(
                      data.tomorrow,
                      "Tomorrow's Plan",
                      theme,
                    ),

                  ],
                );
              },
            ),
          ]
              .animate(interval: 100.ms)
              .fadeIn(duration: 500.ms)
              .slideY(begin: 0.3),
        ),
      ),
    );
  }

  // --- ✅ NEW: Helper widget for the "Ongoing" card ---
  Widget _buildOngoingPjpCard(Pjp pjp, ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(Icons.location_on, color: theme.colorScheme.primary, size: 30),
        title: Text(
          pjp.dealerName ?? pjp.description ?? "Ongoing Visit",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimaryContainer,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          "Journey started. Tap Journey tab to view.",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
          ),
        ),
      ),
    );
  }

  // --- ✅ NEW: Helper widget for the "Upcoming" lists ---
  Widget _buildUpcomingPjpList(List<Pjp> pjps, String title, ThemeData theme) {
    if (pjps.isEmpty) return const SizedBox.shrink(); // Don't show if empty

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$title (${pjps.length})",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              // Use a helper to show a few items
              ..._buildPjpListTiles(pjps.take(3).toList(), theme), // Show max 3
              
              if (pjps.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    "+ ${pjps.length - 3} more...",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- ✅ NEW: Helper for the list tiles ---
  List<Widget> _buildPjpListTiles(List<Pjp> pjps, ThemeData theme) {
    return pjps.map((pjp) => Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: Icon(Icons.route, color: theme.colorScheme.onSurface.withOpacity(0.7)),
        title: Text(
          pjp.dealerName ?? pjp.description ?? "Approved Visit",
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          pjp.areaToBeVisited.split('|').first.trim(),
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    )).toList();
  }
}