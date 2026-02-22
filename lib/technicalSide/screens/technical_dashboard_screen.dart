// lib/technicalSide/screens/technical_dashboard_screen.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:salesmanapp/models/employee_model.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:salesmanapp/core/feature_flags/technical_flags.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camera/camera.dart';
import 'package:geocoding/geocoding.dart';

// --- FORMS IMPORTS ---
import 'package:salesmanapp/screens/forms/add_dealer_form.dart';
import 'package:salesmanapp/technicalSide/screens/forms/create_tvr_form.dart';
import 'package:salesmanapp/technicalSide/screens/forms/approve_mason_bagLift.dart';
import 'package:salesmanapp/technicalSide/screens/forms/approve_mason_kyc.dart';
import 'package:salesmanapp/technicalSide/screens/forms/approve_mason_rewards.dart';
import 'package:salesmanapp/technicalSide/screens/forms/add_site_form.dart';
import 'package:salesmanapp/technicalSide/screens/all_masons_screen.dart';
import 'package:salesmanapp/technicalSide/screens/pending_masons_screen.dart';
import 'package:salesmanapp/technicalSide/screens/forms/tso_meetings_form.dart';

// ---------------------------------------------------------------------------
// 🟢 INTERNAL CAMERA SCREEN
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
    if (_controller != null) {
      await _controller!.dispose();
    }

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
    final newIndex = (_selectedCameraIdx + 1) % _cameras.length;
    _selectedCameraIdx = newIndex;
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
        _isTakingPicture) {
      return;
    }

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
      body: FutureBuilder<void>(
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
                        padding: const EdgeInsets.all(16.0),
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
          } else {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
        },
      ),
    );
  }
}

class TechnicalDashboardScreen extends StatefulWidget {
  final Employee employee;

  const TechnicalDashboardScreen({super.key, required this.employee});

  @override
  State<TechnicalDashboardScreen> createState() =>
      _TechnicalDashboardScreenState();
}

class _TechnicalDashboardScreenState extends State<TechnicalDashboardScreen>
    with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  bool _attendanceEnabled(BuildContext context) {
    final flags = context.read<TechnicalFlags>();
    return flags.attendance;
  }

  bool _isCheckingIn = false;
  bool _isCheckingOut = false;
  bool _isCheckedIn = false;
  bool _isDayComplete = false;

  DateTime? _lastCheckInTime;
  String _greeting = 'Good Morning';

  // --- 🎨 PREMIUM THEME PALETTE ---
  final Color _bgLight = const Color(0xFFF8FAFC); // Slate 50
  final Color _cardNavy = const Color(0xFF0F172A); // Deep Navy
  final Color _textDark = const Color(0xFF1E293B); // Slate 800
  final Color _textGrey = const Color(0xFF64748B); // Slate 500
  final Color _surfaceWhite = Colors.white;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setGreeting();
    refreshData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptAttendanceRecovery();
    });
  }

  Future<void> _attemptAttendanceRecovery() async {
    if (!Platform.isAndroid) return;
    final LostDataResponse response = await _picker.retrieveLostData();
    if (response.isEmpty || response.file == null) return;

    final File recoveredImage = File(response.file!.path);
    final prefs = await SharedPreferences.getInstance();
    final String? pendingAction = prefs.getString('attendance_pending_action');

    if (pendingAction == 'check_in') {
      _toast('Recovering Check-In...');
      _processCheckIn(recoveredImage);
    } else if (pendingAction == 'check_out') {
      _toast('Recovering Check-Out...');
      _processCheckOut(recoveredImage);
    }
    await prefs.remove('attendance_pending_action');
  }

  void refreshData() {
    if (!mounted) return;
    _setGreeting();
    // If day is already completed, do NOT touch attendance state
    if (!_isDayComplete) {
      _checkAttendanceStatus();
    }
  }

  void _toast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _checkAttendanceStatus() async {
    try {
      final att = await _apiService.fetchTodaysAttendance(
        int.parse(widget.employee.id),
        role: 'TECHNICAL',
      );

      final today = DateTime.now();
      final attDate = att.attendanceDate;

      final isSameDay =
          attDate.year == today.year &&
          attDate.month == today.month &&
          attDate.day == today.day;

      if (!mounted) return;

      setState(() {
        if (!isSameDay) {
          // OLD RECORD → treat as fresh day
          _isCheckedIn = false;
          _isDayComplete = false;
          _lastCheckInTime = null;
        } else if (att.checkOutTime != null) {
          // Today completed
          _isCheckedIn = false;
          _isDayComplete = true;
          _lastCheckInTime = null;
        } else {
          // Today active
          _isCheckedIn = true;
          _isDayComplete = false;
          _lastCheckInTime = att.createdAt;
        }
      });
    } catch (e) {
      // No attendance today (404)
      if (!mounted) return;
      setState(() {
        _isCheckedIn = false;
        _isDayComplete = false;
        _lastCheckInTime = null;
      });
    }
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

  Future<bool> _showLocationDisclosureDialog() async {
    return await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.location_on),
                SizedBox(width: 8),
                Text("Location Access"),
              ],
            ),
            content: const Text(
              "To mark your attendance accurately, this app collects location data "
              "to verify you are at the designated work area.\n\n"
              "This data is collected only when you tap 'Check In' or 'Check Out'.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("DENY"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _cardNavy),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "ACCEPT",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Permission Required"),
        content: const Text(
          "Location permission is permanently denied. Enable it in settings.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Geolocator.openAppSettings();
            },
            child: const Text("SETTINGS"),
          ),
        ],
      ),
    );
  }

  Future<Position?> _getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _toast("Location services are disabled.", isError: true);
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      if (!mounted) return null;
      final bool userAgreed = await _showLocationDisclosureDialog();
      if (!userAgreed) {
        _toast("Location is required.", isError: true);
        return null;
      }
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _toast("Location permission denied.", isError: true);
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) _showSettingsDialog();
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint("Error getting position: $e");
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
    } catch (e) {
      debugPrint("Geocoding failed: $e");
    }
    return "Lat: $lat, Lng: $lng";
  }

  Future<void> _handleCheckIn() async {
    if (_isDayComplete) {
      _toast("Attendance for today is already completed.", isError: true);
      return;
    }
    if (_isCheckedIn) {
      _toast("You are already checked in.", isError: true);
      return;
    }

    final String? imagePath = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const _InlineCameraScreen()),
    );

    if (imagePath == null) return;
    await _processCheckIn(File(imagePath));
  }

  Future<void> _processCheckIn(File imageFile) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    setState(() => _isCheckingIn = true);

    try {
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

      final checkInData = {
        'userId': int.parse(widget.employee.id),
        'role': 'TECHNICAL',
        'attendanceDate': DateTime.now().toIso8601String(),
        'locationName': address,
        'inTimeLatitude': position.latitude,
        'inTimeLongitude': position.longitude,
        'inTimeImageUrl': imageUrl,
        'inTimeImageCaptured': true,
      };

      final newAtt = await _apiService.checkIn(checkInData);

      if (mounted) {
        setState(() {
          _isCheckedIn = true;
          _isDayComplete = false;
          _lastCheckInTime = newAtt.createdAt;
        });
        _toast('Check-in successful!', isError: false);
      }
    } catch (e) {
      debugPrint("🚨 Check-In Error: $e");
      final errorStr = e.toString().toLowerCase();

      if (errorStr.contains("already checked in") ||
          errorStr.contains("exists")) {
        _toast("Syncing status...");
        await _checkAttendanceStatus(); // Force sync state from server

        if (mounted && _isDayComplete) {
          _toast(
            "You have already completed your attendance for today.",
            isError: true,
          );
        }
      } else {
        _toast('Failed: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isCheckingIn = false);
    }
  }

  Future<void> _handleCheckOut() async {
    if (_isDayComplete || !_isCheckedIn) return;

    // Guard against checking out too early
    if (_lastCheckInTime != null) {
      final difference = DateTime.now().difference(_lastCheckInTime!);
      if (difference.inMinutes < 0) {
        _toast(
          "Wait ${0 - difference.inMinutes} more minute(s)",
          isError: true,
        );
        return;
      }
    }

    final String? imagePath = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const _InlineCameraScreen()),
    );

    if (imagePath == null) return;
    await _processCheckOut(File(imagePath));
  }

  Future<void> _processCheckOut(File imageFile) async {
    if (!mounted) return;
    setState(() => _isCheckingOut = true);

    try {
      final results = await Future.wait([
        _getCurrentPosition().timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException("GPS signal too weak."),
        ),
        _apiService.uploadImageToR2(imageFile),
      ]);

      final Position? position = results[0] as Position?;
      final String imageUrl = results[1] as String;

      if (position == null) throw Exception("GPS returned null.");

      final checkOutData = {
        'userId': int.parse(widget.employee.id),
        'role': 'TECHNICAL',
        'attendanceDate': DateTime.now().toIso8601String(),
        'outTimeImageUrl': imageUrl,
        'outTimeImageCaptured': true,
        'outTimeLatitude': position.latitude,
        'outTimeLongitude': position.longitude,
      };

      await _apiService.checkOut(checkOutData);

      if (mounted) {
        setState(() {
          _isCheckedIn = false; // Back to "Ready to Start" UI
          _isDayComplete = true; // Lock the buttons
        });
        _toast('Checked out successfully!', isError: false);
      }
    } catch (e) {
      debugPrint("🚨 Check-Out Error: $e");
      final errorStr = e.toString().toLowerCase();

      if (errorStr.contains("not found") ||
          errorStr.contains("no attendance") ||
          errorStr.contains("already")) {
        if (mounted) {
          setState(() {
            _isCheckedIn = false;
            _isDayComplete =
                true; // Lock state even on "already checked out" error
          });
        }
        _toast("Syncing: You are already checked out.");
      } else {
        _toast('Check-out failed: $e', isError: true);
      }
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
    refreshData();
  }

  void _openFullScreen(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  void _showMasonActions(BuildContext context) {
    final flags = context.read<TechnicalFlags>();
    if (!flags.masonManagement) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          maxChildSize: 0.9,
          minChildSize: 0.35,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Mason Management",
                    style: TextStyle(
                      color: _textDark,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildActionSheetItem(
                    icon: Icons.person_add_alt_1_rounded,
                    title: "Pending Registrations",
                    subtitle: "Verify new masons & generate IDs",
                    iconBg: const Color(0xFFE0F2FE),
                    iconColor: const Color(0xFF0284C7),
                    onTap: () {
                      Navigator.pop(context);
                      _openFullScreen(
                        PendingMasonsScreen(employee: widget.employee),
                      );
                    },
                  ),

                  if (flags.approveBagLift)
                    _buildActionSheetItem(
                      icon: Icons.shopping_bag_outlined,
                      title: "Approve Bag Lift",
                      subtitle: "Verify pending cement bag lifts",
                      iconBg: const Color(0xFFFFF7ED),
                      iconColor: Colors.orange,
                      onTap: () {
                        Navigator.pop(context);
                        _openFullScreen(
                          ApproveMasonBagLift(employee: widget.employee),
                        );
                      },
                    ),

                  if (flags.approveKyc)
                    _buildActionSheetItem(
                      icon: Icons.verified_user_outlined,
                      title: "Approve KYC",
                      subtitle: "Review pending Mason identities",
                      iconBg: const Color(0xFFEFF6FF),
                      iconColor: Colors.blue,
                      onTap: () {
                        Navigator.pop(context);
                        _openFullScreen(
                          ApproveMasonKycScreen(employee: widget.employee),
                        );
                      },
                    ),

                  if (flags.approveRewards)
                    _buildActionSheetItem(
                      icon: Icons.card_giftcard,
                      title: "Approve Rewards",
                      subtitle: "Process gift redemption requests",
                      iconBg: const Color(0xFFFAF5FF),
                      iconColor: Colors.purple,
                      onTap: () {
                        Navigator.pop(context);
                        _openFullScreen(
                          ApproveMasonRewardsScreen(employee: widget.employee),
                        );
                      },
                    ),

                  if (flags.myMasons)
                    _buildActionSheetItem(
                      icon: Icons.groups_rounded,
                      title: "My Masons List",
                      subtitle: "View all linked masons & history",
                      iconBg: const Color(0xFFF0FDF4),
                      iconColor: Colors.teal,
                      onTap: () {
                        Navigator.pop(context);
                        _openFullScreen(
                          AllMasonsScreen(employee: widget.employee),
                        );
                      },
                    ),

                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showTechnicalActions(BuildContext context) {
    final flags = context.read<TechnicalFlags>();
    if (!flags.technicalOps) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Technical Operations",
              style: TextStyle(
                color: _textDark,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (flags.createTvr)
              _buildActionSheetItem(
                icon: Icons.assignment_add,
                title: "Create TVR",
                subtitle: "Technical Visit Report Form",
                iconBg: const Color(0xFFF0FDF4),
                iconColor: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) =>
                        CreateTvrScreen(employee: widget.employee),
                  );
                },
              ),
            if (flags.registerSite)
              _buildActionSheetItem(
                icon: Icons.add_location_alt,
                title: "Register Site",
                subtitle: "Add a new construction site",
                iconBg: const Color(0xFFECFEFF),
                iconColor: Colors.cyan,
                onTap: () {
                  Navigator.pop(context);
                  _openFullScreen(AddSiteForm(employee: widget.employee));
                },
              ),
            if (flags.addDealerSubDealer)
              _buildActionSheetItem(
                icon: Icons.store_mall_directory_outlined,
                title: "Add Dealer/Sub Dealer",
                subtitle: "Add a new dealer/sub dealer",
                iconBg: const Color(0xFFFDF4FF),
                iconColor: Colors.purple,
                onTap: () {
                  Navigator.pop(context);
                  _openFullScreen(AddDealerForm(employee: widget.employee));
                },
              ),
            if (flags.logTsoMeeting)
              _buildActionSheetItem(
                icon: Icons.handshake_rounded,
                title: "Log Meetings",
                subtitle: "Record meeting details and expenses",
                iconBg: const Color(0xFFEEF2FF),
                iconColor: const Color(0xFF4F46E5),
                onTap: () {
                  Navigator.pop(context);
                  _openFullScreen(TsoMeetingsForm(employee: widget.employee));
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String userArea = "N/A";
    final flags = context.watch<TechnicalFlags>();
    try {
      userArea = (widget.employee as dynamic).area ?? "N/A";
    } catch (_) {}

    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: _bgLight,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _cardNavy, width: 2),
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[300],
                backgroundImage: const NetworkImage(
                  "https://picsum.photos/200/300?grayscale",
                ),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting,
                  style: TextStyle(
                    color: _textGrey,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  widget.employee.displayName,
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children:
              [
                    // 1. HERO ATTENDANCE CARD
                    if (_attendanceEnabled(context))
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: _cardNavy,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: _cardNavy.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
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
                              children: [],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _isCheckedIn
                                  ? "You are Checked In"
                                  : "Ready to Start?",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  color: Colors.white.withOpacity(0.7),
                                  size: 16,
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
                                    label: "CHECK IN",
                                    icon: Icons.login_rounded,
                                    isLoading: _isCheckingIn,
                                    isActive: !_isCheckedIn,
                                    onTap: () {
                                      if (_isCheckingIn || _isCheckingOut)
                                        return;
                                      if (_isCheckedIn) {
                                        _toast(
                                          "You are already checked in.",
                                          isError: true,
                                        );
                                      } else if (_isDayComplete) {
                                        _toast(
                                          "You have already completed your attendance for today.",
                                          isError: true,
                                        );
                                      } else {
                                        _handleCheckIn();
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildGlassButton(
                                    label: "CHECK OUT",
                                    icon: Icons.logout_rounded,
                                    isLoading: _isCheckingOut,
                                    isActive: _isCheckedIn && !_isDayComplete,
                                    onTap:
                                        (!_isCheckedIn ||
                                            _isDayComplete ||
                                            _isCheckingIn ||
                                            _isCheckingOut)
                                        ? null
                                        : _handleCheckOut,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 32),

                    // 2. OPERATIONS HEADER
                    Text(
                      "Operations",
                      style: TextStyle(
                        color: _textDark,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. MASON MANAGEMENT
                    if (flags.masonManagement)
                      _buildFintechCard(
                        title: "Mason Management",
                        subtitle: "Masons, KYC, Bag Lifts",
                        icon: Icons.handyman_rounded,
                        iconColor: Colors.orange,
                        iconBg: const Color(0xFFFFF7ED),
                        actionText: "Manage",
                        onTap: () => _showMasonActions(context),
                      ),

                    const SizedBox(height: 16),

                    // 4. TECHNICAL OPS
                    if (flags.technicalOps)
                      _buildFintechCard(
                        title: "Technical Ops",
                        subtitle: "TVR, Site Registration, Add Dealer",
                        icon: Icons.architecture_rounded,
                        iconColor: const Color(0xFF0F766E),
                        iconBg: const Color(0xFFECFEFF),
                        actionText: "Open",
                        onTap: () => _showTechnicalActions(context),
                      ),
                  ]
                  .animate(interval: 50.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
        ),
      ),
    );
  }

  // --- CUSTOM WIDGETS ---

  Widget _buildGlassButton({
    required String label,
    required IconData icon,
    required bool isLoading,
    required bool isActive,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? Colors.white : Colors.white.withOpacity(0.2),
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: isLoading
              ? Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: isActive ? _cardNavy : Colors.white,
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
                      color: isActive ? _cardNavy : Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: isActive ? _cardNavy : Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
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
    required String actionText,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _cardNavy.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: _cardNavy.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: _textDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _bgLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Text(
                        actionText,
                        style: TextStyle(
                          color: iconColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: iconColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
        style: TextStyle(
          color: _textDark,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: _textGrey, fontSize: 13),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: _textGrey),
      onTap: onTap,
    );
  }
}
