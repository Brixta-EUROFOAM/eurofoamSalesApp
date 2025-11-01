// lib/screens/employee_management/employee_dashboard_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
// import 'package:assetarchiverflutter/widgets/reusableglasscard.dart'; // <-- REMOVED
import 'package:flutter_animate/flutter_animate.dart';
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:assetarchiverflutter/models/pjp_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

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
  // --- (All your logic is unchanged) ---
  final ApiService _apiService = ApiService();
  late Future<List<Pjp>> _pjpFuture;
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

  void refreshData() {
    if (mounted) {
      setState(() {
        _pjpFuture = _apiService.fetchPjpsForUser(
          int.parse(widget.employee.id),
          status: 'pending',
        );
      });
    }
  }

  Future<void> _handleRefresh() async {
    final newPjpFuture = _apiService.fetchPjpsForUser(
      int.parse(widget.employee.id),
      status: 'pending',
    );
    if (mounted) {
      setState(() {
        _pjpFuture = newPjpFuture;
      });
    }
    await newPjpFuture;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
    // ... (Your Check In logic is unchanged) ...
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
    // ... (Your Check Out logic is unchanged) ...
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
            Card(
              color: theme.brightness == Brightness.light 
                     ? theme.colorScheme.primary  // Light mode = Blue card
                     : theme.colorScheme.surface, // Dark mode = Lighter blue card
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
            const SizedBox(height: 24), // Increased spacing

            // --- ✅ THE FIX ---
            // Replaced Row with a Column and removed Expanded
            Column(
              children: [
                SizedBox(
                  width: double.infinity, // Make button full-width
                  child: ElevatedButton.icon(
                    icon: _isCheckingIn 
                        ? const SizedBox(width: 18, height: 45, child: CircularProgressIndicator(strokeWidth: 2)) 
                        // Match the icon from your "idea" screenshot
                        : const Icon(Icons.arrow_forward, size: 50), 
                    label: const Text('Check In'),
                    onPressed: _isCheckingIn || _isCheckingOut ? null : _handleCheckIn,
                  ),
                ),
                const SizedBox(height: 16), // Spacing between buttons
                SizedBox(
                  width: double.infinity, // Make button full-width
                  child: ElevatedButton.icon(
                    icon: _isCheckingOut 
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) 
                        // Match the icon from your "idea" screenshot
                        : const Icon(Icons.arrow_back, size: 50),
                    label: const Text('Check Out'),
                    onPressed: _isCheckingIn || _isCheckingOut ? null : _handleCheckOut,
                  ),
                ),
              ],
            ),
            // --- END FIX ---

            const SizedBox(height: 24),

            FutureBuilder<List<Pjp>>(
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
                          'Error fetching PJPs: ${snapshot.error}', 
                          style: TextStyle(color: theme.colorScheme.onErrorContainer)
                        )
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Card(
                     child: Padding(
                       padding: const EdgeInsets.all(24.0), // More padding
                       child: Center(
                        child: Text(
                          'No active PJPs found.', 
                          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7))
                        )
                      ),
                     ),
                  );
                }

                final pjps = snapshot.data!;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Active & Upcoming PJPs (${pjps.length})",
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold, 
                            color: theme.colorScheme.onSurface
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...pjps.map((pjp) => ListTile(
                              leading: Icon(Icons.route, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                              title: Text(
                                'Plan for: ${pjp.planDate.toLocal().toString().split(' ')[0]}', 
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface, 
                                  fontWeight: FontWeight.bold
                                )
                              ),
                              subtitle: Text(
                                'Status: ${pjp.status}', 
                                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7))
                              ),
                            )),
                      ],
                    ),
                  ),
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
}