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
import 'package:shared_preferences/shared_preferences.dart'; // ⚡ ADDED
import 'package:camera/camera.dart'; // CAMERA BY NATIVE DART

// --- FORMS IMPORTS ---
import 'package:salesmanapp/screens/forms/add_dealer_form.dart';
import 'package:salesmanapp/technicalSide/screens/forms/create_tvr_form.dart';
import 'package:salesmanapp/technicalSide/screens/forms/approve_mason_bagLift.dart';
import 'package:salesmanapp/technicalSide/screens/forms/approve_mason_kyc.dart';
import 'package:salesmanapp/technicalSide/screens/forms/approve_mason_rewards.dart';
import 'package:salesmanapp/technicalSide/screens/forms/add_site_form.dart';
import 'package:salesmanapp/technicalSide/screens/all_masons_screen.dart';

// ---------------------------------------------------------------------------
// 🟢 INTERNAL CAMERA SCREEN (Copy to bottom of technical_dashboard_screen.dart)
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

  // ⚡ NEW: Store list of cameras to enable switching
  List<CameraDescription> _cameras = [];
  int _selectedCameraIdx = 0;

  @override
  void initState() {
    super.initState();
    _setupCameras();
  }

  // 1. One-time setup: Get all cameras and find the selfie one
  Future<void> _setupCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      // Find the index of the front camera, or default to 0 (back)
      _selectedCameraIdx = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );

      if (_selectedCameraIdx == -1) _selectedCameraIdx = 0;

      // Initialize the selected camera
      _initCamera(_cameras[_selectedCameraIdx]);
    } catch (e) {
      debugPrint("Camera setup error: $e");
    }
  }

  // 2. Init specific camera (Re-used when flipping)
  Future<void> _initCamera(CameraDescription cameraDescription) async {
    // If a controller exists, dispose it cleanly before creating a new one
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

  // 3. The Flip Logic
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
      // Optional: Turn flash off to avoid crashes on some low-end devices
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
                // 1. Camera Preview
                Center(child: CameraPreview(_controller!)),

                // 2. Controls Overlay
                SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // --- TOP BAR: Close & Flip ---
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Close Button
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 30,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),

                            // Flip Button (Hidden if only 1 camera exists)
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

                      // --- BOTTOM BAR: Shutter Button ---
                      Padding(
                        padding: const EdgeInsets.only(bottom: 30),
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
  final ImagePicker _picker = ImagePicker(); // ⚡ Instantiated once

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

    // 🚀 PROCESS DEATH RECOVERY
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptAttendanceRecovery();
    });
  }

  // 🛡️ RECOVERY LOGIC
  Future<void> _attemptAttendanceRecovery() async {
    if (!Platform.isAndroid) return;

    final LostDataResponse response = await _picker.retrieveLostData();
    if (response.isEmpty || response.file == null) return;

    final File recoveredImage = File(response.file!.path);

    // Check what we were doing before the crash
    final prefs = await SharedPreferences.getInstance();
    final String? pendingAction = prefs.getString('attendance_pending_action');

    if (pendingAction == 'check_in') {
      _toast('Recovering Check-In...');
      _processCheckIn(recoveredImage);
    } else if (pendingAction == 'check_out') {
      _toast('Recovering Check-Out...');
      _processCheckOut(recoveredImage);
    }

    // Clear the flag
    await prefs.remove('attendance_pending_action');
  }

  // Helper to set the flag before opening camera
  // Future<void> _setPendingAction(String action) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setString('attendance_pending_action', action);
  // }

  // Future<void> _clearPendingAction() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.remove('attendance_pending_action');
  // }

  // Simple refresh to update greeting or check status if needed
  void refreshData() {
    if (mounted) {
      setState(() {
        _setGreeting();
      });
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

      if (mounted) {
        setState(() {
          // 1. If checkOutTime exists, they are done for the day
          if (att.checkOutTime != null) {
            _isCheckedIn = false;
            _isDayComplete = true;
          } else {
            // 2. If no checkOutTime, they are currently checked in
            _isCheckedIn = true;
            _isDayComplete = false;
          }
          _lastCheckInTime = att.createdAt;
        });
      }
    } catch (e) {
      if (e.toString().contains("404")) {
        if (mounted) {
          setState(() {
            _isCheckedIn = false;
            _isDayComplete = false; // New day, or no record yet
          });
        }
      }
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

  // Future<File?> _captureImage() async {
  //   // ⚡ KEY: imageQuality 50 to save RAM
  //   final XFile? image = await _picker.pickImage(
  //     source: ImageSource.camera,
  //     imageQuality: 50,
  //   );
  //   return image == null ? null : File(image.path);
  // }

  // ... (Dialogs and Geolocator Helpers remain the same) ...
  Future<bool> _showLocationDisclosureDialog() async {
    return await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.location_on, color: _cardNavy),
                const SizedBox(width: 8),
                const Text("Location Access"),
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
                child: const Text("DENY", style: TextStyle(color: Colors.grey)),
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
          "Location permission is permanently denied. Please enable it in App Settings to mark attendance.",
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
            child: const Text(
              "OPEN SETTINGS",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<Position?> _getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _toast(
        "Location services are disabled. Please enable GPS.",
        isError: true,
      );
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      if (!mounted) return null;
      final bool userAgreed = await _showLocationDisclosureDialog();

      if (!userAgreed) {
        _toast("Location is required for Attendance.", isError: true);
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

  // --- 🟢 CHECK IN FLOW ---

  // 1. Trigger (User Click)
  Future<void> _handleCheckIn() async {
    if (_isDayComplete || _isCheckedIn) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    // 🛑 PRE-FLIGHT CHECK 1: Already Checked In?
    if (_isCheckedIn) {
      _toast("You are already checked in.", isError: true);
      return;
    }

    // 🛑 PRE-FLIGHT CHECK 2: Already Finished Day?
    // We call the API one last time to be absolutely sure before opening camera
    setState(() => _isCheckingIn = true);
    await _checkAttendanceStatus();
    setState(() => _isCheckingIn = false);

    if (_isDayComplete) {
      _toast(
        "You have already completed your attendance for today.",
        isError: true,
      );
      return;
    }

    if (_isCheckedIn) {
      _toast("Syncing: You are already checked in.");
      return;
    }

    // 🟢 1. Open Inline Camera (App stays alive)
    final String? imagePath = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const _InlineCameraScreen()),
    );

    // 2. Handle Cancellation
    if (imagePath == null) return;

    // 3. Process immediately (No need for complicated recovery logic)
    await _processCheckIn(File(imagePath));
  }

  // 2. Processing (Called by Normal Flow OR Recovery Flow)
  Future<void> _processCheckIn(File imageFile) async {
    if (!mounted) return;

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    setState(() => _isCheckingIn = true);

    try {
      debugPrint("⚡ [Parallel] Starting GPS and Upload...");

      final results = await Future.wait([
        _getCurrentPosition().timeout(const Duration(seconds: 10)),
        _apiService.uploadImageToR2(imageFile),
      ]);

      final Position? position = results[0] as Position?;
      final String imageUrl = results[1] as String;

      if (position == null) throw Exception("Location verification failed.");

      final checkInData = {
        'userId': int.parse(widget.employee.id),
        'role': 'TECHNICAL',
        'attendanceDate': DateTime.now().toIso8601String(),
        'locationName': 'Live Location',
        'inTimeLatitude': position.latitude,
        'inTimeLongitude': position.longitude,
        'inTimeImageUrl': imageUrl,
        'inTimeImageCaptured': true,
      };

      final newAtt = await _apiService.checkIn(checkInData);

      if (mounted) {
        setState(() {
          _isCheckedIn = true;
          _isDayComplete = false; // ⚡ ADD THIS LINE: Reset day complete status
          _lastCheckInTime = newAtt.createdAt;
        });
        _toast('Check-in successful!', isError: false);
      }
    } catch (e) {
      debugPrint("🚨 Check-In Error: $e");

      // 🛑 FIXED LOGIC:
      // Don't blindly set true. Check if the server actually thinks we are IN.
      if (e.toString().toLowerCase().contains("already checked in") ||
          e.toString().toLowerCase().contains("exists")) {
        _toast("Syncing status...");

        // 1. Fetch the TRUTH from the server
        await _checkAttendanceStatus();

        // 2. Only say "Checked In" if the server confirms it
        if (_isCheckedIn) {
          _toast("Resumed session: You were already checked in.");
        } else {
          // If _checkAttendanceStatus set it to false, it means the user
          // has already finished their day (Checked In -> Checked Out).
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
  // --- 🔴 CHECK OUT FLOW ---

  // 1. Trigger (User Click)
  Future<void> _handleCheckOut() async {
    if (_isDayComplete || !_isCheckedIn) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    // 🛑 PRE-FLIGHT CHECK 1: Are they even checked in?
    if (!_isCheckedIn) {
      _toast("You cannot check out without checking in first.", isError: true);
      return;
    }

    // 1 hr time lock
    if (_lastCheckInTime != null) {
      final difference = DateTime.now().difference(_lastCheckInTime!);
      if (difference.inMinutes < 60) {
        _toast(
          "Wait ${60 - difference.inMinutes} more minute(s)",
          isError: true,
        );
        return;
      }
    }

    // 🟢 1. Open Inline Camera
    final String? imagePath = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const _InlineCameraScreen()),
    );

    // 2. Handle Cancellation
    if (imagePath == null) return;

    // 3. Process
    await _processCheckOut(File(imagePath));
  }

  // 2. Processing (Called by Normal Flow OR Recovery Flow)
  Future<void> _processCheckOut(File imageFile) async {
    if (!mounted) return;
    setState(() => _isCheckingOut = true);

    try {
      debugPrint("🚀 [OUT] Starting GPS and Upload...");

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

      // ⚡ Await the call so we can catch the error properly
      await _apiService.checkOut(checkOutData);

      if (mounted) {
        setState(() {
          _isCheckedIn = false;
          _isDayComplete = true; // ⚡ ADD THIS LINE: Lock the UI for the day
        });
        _toast('Checked out successfully!', isError: false);
      }
    } catch (e) {
      debugPrint("🚨 Check-Out Error: $e");

      // 🛑 ZOMBIE STATE FIX:
      // If server says "Attendance not found" or "Already checked out",
      // it means the App was wrong to think we were Checked In.
      // We must force the App to 'Checked Out' state.
      if (e.toString().toLowerCase().contains("not found") ||
          e.toString().toLowerCase().contains("no attendance") ||
          e.toString().toLowerCase().contains("already")) {
        if (mounted) {
          setState(() => _isCheckedIn = false);
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
              "Mason Management",
              style: TextStyle(
                color: _textDark,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
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
                  _openFullScreen(AllMasonsScreen(employee: widget.employee));
                },
              ),
          ],
        ),
      ),
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
        toolbarHeight: 70,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[300],
              backgroundImage: const NetworkImage(
                "https://picsum.photos/200/300?grayscale",
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              padding: const EdgeInsets.all(8),
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
                Icons.notifications_none,
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
                    // 1. HERO CARD
                    if (_attendanceEnabled(context))
                      Container(
                        width: double.infinity,
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
                                  Icons.more_horiz,
                                  color: Colors.white54,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _isCheckedIn
                                  ? "You are Checked In"
                                  : "Ready to Start?",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
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
                                // CHECK IN BUTTON
                                Expanded(
                                  child: _buildGlassButton(
                                    label: "CHECK IN",
                                    icon: Icons.arrow_downward,
                                    isLoading: _isCheckingIn,
                                    isActive: !_isCheckedIn,
                                    onTap: () {
                                      if (_isCheckingIn || _isCheckingOut)
                                        return; // Prevent double taps

                                      if (_isCheckedIn) {
                                        _toast(
                                          "You are already checked in.",
                                          isError: true,
                                        );
                                      } else if (_isDayComplete) {
                                        // ⚡ TRAP: Button looks active, but shows warning instead of camera
                                        _toast(
                                          "You have already completed your attendance for today.",
                                          isError: true,
                                        );
                                      } else {
                                        // Normal flow
                                        _handleCheckIn();
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // CHECK OUT BUTTON
                                Expanded(
                                  child: _buildGlassButton(
                                    label: "CHECK OUT",
                                    icon: Icons.arrow_upward,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Categories Of Work",
                          style: TextStyle(
                            color: _textDark,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 3. FINTECH STYLE LIST ITEMS
                    // Mason Operations
                    if (flags.masonManagement)
                      _buildFintechCard(
                        title: "Mason Management",
                        subtitle: "Masons, KYC, Bag Lifts",
                        icon: Icons.handyman_outlined,
                        iconColor: Colors.orange,
                        iconBg: const Color(0xFFFFF7ED),
                        actionText: "4 Actions",
                        onTap: () => _showMasonActions(context),
                      ),

                    const SizedBox(height: 16),

                    // Technical Operations
                    if (flags.technicalOps)
                      _buildFintechCard(
                        title: "Technical Ops",
                        subtitle: "TVR, Site Registration, Add Dealer",
                        icon: Icons.architecture,
                        iconColor: const Color(0xFF0F766E),
                        iconBg: const Color(0xFFECFEFF),
                        actionText: "3 Actions",
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
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
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
                Text(
                  actionText,
                  style: TextStyle(
                    color: iconColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
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
      trailing: Icon(Icons.chevron_right, color: Colors.grey[300]),
    );
  }
}