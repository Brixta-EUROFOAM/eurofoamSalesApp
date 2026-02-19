// lib/screens/employee_management/employee_dashboard_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:salesmanapp/models/employee_model.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:camera/camera.dart';

import 'package:salesmanapp/screens/forms/add_dealer_form.dart';
import 'package:salesmanapp/screens/forms/create_dvr.dart';
import 'package:salesmanapp/screens/forms/create_competition_form.dart';
import 'package:salesmanapp/screens/employee_management/employee_salesorder_screen.dart';

// ---------------------------------------------------------------------------
// 🟢 INLINE CAMERA (LOCAL COPY - SALES SIDE)
// ---------------------------------------------------------------------------
class _InlineCameraScreen extends StatefulWidget {
  const _InlineCameraScreen();

  @override
  State<_InlineCameraScreen> createState() => _InlineCameraScreenState();
}

class _InlineCameraScreenState extends State<_InlineCameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isTakingPicture = false;

  List<CameraDescription> _cameras = [];
  int _selectedCameraIdx = 0;

  @override
  void initState() {
    super.initState();
    _setupCameras();
  }

  Future<void> _setupCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      _selectedCameraIdx = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );

      if (_selectedCameraIdx == -1) _selectedCameraIdx = 0;

      _initCamera(_cameras[_selectedCameraIdx]);
    } catch (e) {
      debugPrint("Camera setup error: $e");
    }
  }

  Future<void> _initCamera(CameraDescription cameraDescription) async {
    await _controller?.dispose();

    _controller = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    setState(() {
      _initializeControllerFuture = _controller!.initialize();
    });
  }

  void _toggleCamera() {
    if (_cameras.length < 2) return;
    _selectedCameraIdx = (_selectedCameraIdx + 1) % _cameras.length;
    _initCamera(_cameras[_selectedCameraIdx]);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isTakingPicture)
      return;

    try {
      setState(() => _isTakingPicture = true);
      await _controller!.setFlashMode(FlashMode.off);

      final image = await _controller!.takePicture();

      if (!mounted) return;
      Navigator.pop(context, image.path);
    } catch (e) {
      debugPrint("Capture error: $e");
    } finally {
      if (mounted) setState(() => _isTakingPicture = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              _controller != null) {
            return Stack(
              children: [
                Center(child: CameraPreview(_controller!)),
                SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 30,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            if (_cameras.length > 1)
                              IconButton(
                                icon: const Icon(
                                  Icons.flip_camera_ios_outlined,
                                  color: Colors.white,
                                  size: 30,
                                ),
                                onPressed: _toggleCamera,
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: InkWell(
                          onTap: _takePicture,
                          child: Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              color: _isTakingPicture
                                  ? Colors.white
                                  : Colors.white24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        },
      ),
    );
  }
}

class EmployeeDashboardScreen extends StatefulWidget {
  final Employee employee;
  const EmployeeDashboardScreen({super.key, required this.employee});

  @override
  State<EmployeeDashboardScreen> createState() =>
      EmployeeDashboardScreenState();
}

class EmployeeDashboardScreenState extends State<EmployeeDashboardScreen>
    with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();

  bool _isCheckingIn = false;
  bool _isCheckingOut = false;
  bool _isCheckedIn = false;
  DateTime? _lastCheckInTime;
  String _greeting = 'Good Morning';

  // --- FINTECH THEME PALETTE ---
  final Color _bgLight = const Color(0xFFF3F4F6);
  final Color _cardNavy = const Color(0xFF0F172A);
  final Color _textDark = const Color(0xFF111827);
  final Color _textGrey = const Color(0xFF6B7280);
  final Color _surfaceWhite = Colors.white;

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
      final att = await _apiService.fetchTodaysAttendance(
        int.parse(widget.employee.id),
        role: 'SALES',
      );
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
    if (hour < 12) {
      _greeting = 'Good Morning';
    } else if (hour < 17) {
      _greeting = 'Good Afternoon';
    } else {
      _greeting = 'Good Evening';
    }
  }

  // --- ACTIONS ---

  void _showSalesmanOps(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Sales Operations",
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildActionSheetItem(
                  icon: Icons.description_outlined,
                  title: "Create DVR",
                  subtitle: "Daily Visit Report",
                  iconBg: const Color(0xFFEFF6FF),
                  iconColor: Colors.blue,
                  onTap: () =>
                      _openDialog(CreateDvrScreen(employee: widget.employee)),
                ),
                _buildActionSheetItem(
                  icon: Icons.store_mall_directory_outlined,
                  title: "Add Dealer",
                  subtitle: "Register new dealer",
                  iconBg: const Color(0xFFF0FDF4),
                  iconColor: Colors.green,
                  onTap: () =>
                      _openDialog(AddDealerForm(employee: widget.employee)),
                ),
                _buildActionSheetItem(
                  icon: Icons.assessment_outlined,
                  title: "Competition Form",
                  subtitle: "Market intelligence report",
                  iconBg: const Color(0xFFFFF7ED),
                  iconColor: Colors.orange,
                  onTap: () => _openDialog(
                    CreateCompetitionFormScreen(employee: widget.employee),
                  ),
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
                      MaterialPageRoute(
                        builder: (_) =>
                            SalesOrderScreen(employee: widget.employee),
                      ),
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

  Future<Position?> _getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) {
      Geolocator.openAppSettings();
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String> _resolveAddress(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return "${place.street}, ${place.subLocality}, ${place.locality}";
      }
    } catch (_) {}
    return "Lat: $lat, Lng: $lng";
  }

  Future<void> _handleCheckIn() async => _performAttendanceAction(true);
  Future<void> _handleCheckOut() async => _performAttendanceAction(false);

  Future<void> _performAttendanceAction(bool isCheckIn) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => isCheckIn ? _isCheckingIn = true : _isCheckingOut = true);

    try {
      // time lock 60 mins
      if (!isCheckIn) {
        if (_lastCheckInTime != null) {
          final difference = DateTime.now().difference(_lastCheckInTime!);

          if (difference.inMinutes < 60) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(
                  "Wait ${60 - difference.inMinutes} more minute(s) before checkout.",
                ),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        }
      }

      /// 🚀 OPEN OPTIMIZED CAMERA (same as DVR/TVR)
      final imagePath = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const _InlineCameraScreen()),
      );

      if (imagePath == null || imagePath is! String) {
        throw Exception("Photo required");
      }

      final File imageFile = File(imagePath);

      final results = await Future.wait([
        _getCurrentPosition().timeout(const Duration(seconds: 10)),
        _apiService.uploadImageToR2(imageFile),
      ]);

      final Position? position = results[0] as Position?;
      final String imageUrl = results[1] as String;

      if (position == null) throw Exception("Location verification failed.");

      String address = "Live Location";
      try {
        address = await _resolveAddress(position.latitude, position.longitude);
      } catch (_) {}

      if (isCheckIn) {
        final data = {
          'userId': int.parse(widget.employee.id),
          'role': 'SALES',
          'attendanceDate': DateTime.now().toIso8601String(),
          'locationName': address,
          'inTimeLatitude': position.latitude,
          'inTimeLongitude': position.longitude,
          'inTimeImageUrl': imageUrl,
          'inTimeImageCaptured': true,
        };
        final res = await _apiService.checkIn(data);
        if (mounted) {
          setState(() {
            _isCheckedIn = true;
            _lastCheckInTime = res.createdAt;
          });
        }
      } else {
        final data = {
          'userId': int.parse(widget.employee.id),
          'role': 'SALES',
          'attendanceDate': DateTime.now().toIso8601String(),
          'outTimeImageUrl': imageUrl,
          'outTimeImageCaptured': true,
          'outTimeLatitude': position.latitude,
          'outTimeLongitude': position.longitude,
        };
        await _apiService.checkOut(data);
        if (mounted) setState(() => _isCheckedIn = false);
      }
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(isCheckIn ? 'Checked In!' : 'Checked Out!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(
          () => isCheckIn ? _isCheckingIn = false : _isCheckingOut = false,
        );
      }
    }
  }

  void _openDialog(Widget page) {
    Navigator.pop(context); // Close bottom sheet
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: page,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String userArea = "N/A";
    try {
      userArea = (widget.employee as dynamic).area ?? "N/A";
    } catch (_) {}

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
              child: Text(
                widget.employee.displayName[0],
                style: TextStyle(color: _cardNavy, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Column(
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
                  widget.employee.displayName,
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                      const Icon(
                        Icons.access_time,
                        color: Colors.white54,
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isCheckedIn ? "Checked In" : "Ready to Start?",
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
                      Text(
                        'Area: $userArea',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: _buildGlassButton(
                          "CHECK IN",
                          Icons.login,
                          _isCheckingIn,
                          !_isCheckedIn,
                          _isCheckedIn ? null : _handleCheckIn,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildGlassButton(
                          "CHECK OUT",
                          Icons.logout,
                          _isCheckingOut,
                          _isCheckedIn,
                          !_isCheckedIn ? null : _handleCheckOut,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().slideY(begin: 0.1, duration: 400.ms),

            const SizedBox(height: 32),
            Text(
              "Operations",
              style: TextStyle(
                color: _textDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
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

  Widget _buildGlassButton(
    String label,
    IconData icon,
    bool loading,
    bool active,
    VoidCallback? onTap,
  ) {
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
            // CHANGED: Replaced Icon with Text "Open"
            const Text(
              "Open",
              style: TextStyle(
                color: Colors.blue, // Blue text
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionSheetItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(color: _textDark, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: _textGrey, fontSize: 12),
      ),
    );
  }
}
