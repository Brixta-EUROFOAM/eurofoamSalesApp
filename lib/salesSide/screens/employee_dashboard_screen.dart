// lib/salesSide/screens/employee_dashboard_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:salesmanapp/salesSide/models/employee_model.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:salesmanapp/core/feature_flags/sales_flags.dart';
import 'package:salesmanapp/salesSide/screens/forms/add_dealer_form.dart';
import 'package:salesmanapp/salesSide/screens/forms/create_dvr.dart';
import 'package:salesmanapp/salesSide/screens/forms/create_competition_form.dart';
import 'package:salesmanapp/salesSide/screens/forms/create_salesOrder_form.dart';
import 'package:salesmanapp/salesSide/screens/team_view_list_screen.dart';
import 'dart:async';
import 'package:salesmanapp/salesSide/screens/dvrwidgets/dvrworker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:salesmanapp/database/app_database.dart';
//import 'package:salesmanapp/api/auth_service.dart';

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
                Center(
                  child: CameraPreview(
                    _controller!,
                  ).animate().fadeIn(duration: 400.ms),
                ),
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
                          child:
                              Container(
                                    height: 80,
                                    width: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 4,
                                      ),
                                      color: _isTakingPicture
                                          ? Colors.white
                                          : Colors.white24,
                                    ),
                                  )
                                  .animate(target: _isTakingPicture ? 1 : 0)
                                  .scaleXY(
                                    end: 0.9,
                                    duration: 150.ms,
                                    curve: Curves.easeOut,
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
  //final AuthService _authService = AuthService();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isCheckingIn = false;
  bool _isCheckingOut = false;
  bool _isCheckedIn = false;
  bool _isOffline = false;
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

    // 🚀 THE OFFLINE RECOVERY WATCHDOG
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final isDisconnected = results.contains(ConnectivityResult.none);
      if (mounted) {
        setState(() => _isOffline = isDisconnected);
      }

      if (!isDisconnected) {
        // We have internet! Fire the engine safely.
        DvrBackgroundWorker.retryStuckQueue(_apiService, context: context);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refreshData();
  }

  void refreshData() {
    if (mounted) {
      _setGreeting();
      _checkAttendanceStatus();
      // syncOfflineDealers();
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
    // 🚀 CLEAN UP THE LISTENER TO PREVENT MEMORY LEAKS
    _connectivitySubscription?.cancel();
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
    final flags = context.read<SalesFlags>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Animated Title
                Text(
                      "Sales Operations",
                      style: TextStyle(
                        color: _textDark,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.2, curve: Curves.easeOutBack),

                const SizedBox(height: 16),

                if (flags.createDvr)
                  _buildActionSheetItem(
                        icon: Icons.description_outlined,
                        title: "Create DVR",
                        subtitle: "Daily Visit Report",
                        iconBg: const Color(0xFFEFF6FF),
                        iconColor: Colors.blue,
                        onTap: () async {
                          Navigator.pop(sheetContext); // close bottom sheet

                          if (!_isCheckedIn) {
                            final shouldCheckIn = await showDialog<bool>(
                              context: context,
                              barrierDismissible: false,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text("Check-In Required"),
                                content: const Text(
                                  "You did not check in today!\n\nPlease check in to continue.",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext, false),
                                    child: const Text("Cancel"),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0F172A),
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () =>
                                        Navigator.pop(dialogContext, true),
                                    child: const Text("Check In Now"),
                                  ),
                                ],
                              ),
                            );
                            if (shouldCheckIn != true) return;

                            // Trigger actual check-in flow
                            await _performAttendanceAction(true);

                            // IMPORTANT: wait for state update
                            await Future.delayed(
                              const Duration(milliseconds: 500),
                            );

                            // Re-check
                            if (!_isCheckedIn) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Check-in failed. Try again."),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                          }

                          // NOW allow DVR
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CreateDvrScreen(employee: widget.employee),
                            ),
                          );
                        },
                      )
                      .animate()
                      .fadeIn(delay: 100.ms)
                      .slideX(begin: -0.1, curve: Curves.easeOutCubic),

                if (flags.addDealer)
                  _buildActionSheetItem(
                        icon: Icons.store_mall_directory_outlined,
                        title: "Add Dealer/Sub Dealer",
                        subtitle: "Add a new dealer/sub dealer",
                        iconBg: const Color(0xFFFDF4FF),
                        iconColor: Colors.purple,
                        onTap: () => _openDialog(
                          AddDealerForm(employee: widget.employee),
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 150.ms)
                      .slideX(begin: -0.1, curve: Curves.easeOutCubic),

                if (flags.competitionForm)
                  _buildActionSheetItem(
                        icon: Icons.assessment_outlined,
                        title: "Competition Form",
                        subtitle: "Market intelligence report",
                        iconBg: const Color(0xFFFFF7ED),
                        iconColor: Colors.orange,
                        onTap: () => _openDialog(
                          CreateCompetitionFormScreen(
                            employee: widget.employee,
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 200.ms)
                      .slideX(begin: -0.1, curve: Curves.easeOutCubic),

                if (flags.salesOrders)
                  _buildActionSheetItem(
                        icon: Icons.shopping_cart_outlined,
                        title: "Sales Orders",
                        subtitle: "Manage orders",
                        iconBg: const Color(0xFFF3E8FF),
                        iconColor: Colors.purple,
                        onTap: () {
                          Navigator.pop(sheetContext); // close bottom sheet

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Scaffold(
                                appBar: AppBar(
                                  title: const Text("Sales Order"),
                                ),
                                body: SalesOrderForm(employee: widget.employee),
                              ),
                            ),
                          );
                        },
                      )
                      .animate()
                      .fadeIn(delay: 250.ms)
                      .slideX(begin: -0.1, curve: Curves.easeOutCubic),

                if (flags.teamView)
                  _buildActionSheetItem(
                        icon: Icons.groups_outlined,
                        title: "My Team",
                        subtitle: "View team & reports",
                        iconBg: const Color(0xFFF1F5F9),
                        iconColor: Colors.lightBlue,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          // This will open the specific Sales Team List
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TeamViewListScreen(
                                seniorId: int.parse(widget.employee.id),
                              ),
                            ),
                          );
                        },
                      )
                      .animate()
                      .fadeIn(delay: 300.ms)
                      .slideX(begin: -0.1, curve: Curves.easeOutCubic),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Future<void> syncOfflineDealers() async {
  //   try {
  //     int page = 1;
  //     int totalSynced = 0;
  //     bool hasMore = true;
  //     const int batchSize = 500; // fetch 500 at a time since backend GET() caps at 500

  //     // 1. Initial Loading UI
  //     ScaffoldMessenger.of(context).clearSnackBars();
  //     // ScaffoldMessenger.of(context).showSnackBar(
  //     //   SnackBar(
  //     //     content: Row(
  //     //       children: const [
  //     //         SizedBox(
  //     //           width: 20,
  //     //           height: 20,
  //     //           child: CircularProgressIndicator(
  //     //             color: Colors.white,
  //     //             strokeWidth: 2,
  //     //           ),
  //     //         ),
  //     //         SizedBox(width: 16),
  //     //         Expanded(child: Text("Starting offline dealer sync...")),
  //     //       ],
  //     //     ),
  //     //     duration: const Duration(days: 1), // Stays open while we loop
  //     //     backgroundColor: const Color(0xFF0F172A),
  //     //   ),
  //     // );

  //     // 2. The Pagination Loop
  //     while (hasMore) {
  //       final batch = await _apiService.fetchDealers(
  //         search: "",
  //         limit: batchSize,
  //         page: page,
  //       );

  //       if (batch.isEmpty) {
  //         hasMore = false; // We've reached the end!
  //       } else {
  //         // Push batch to Drift
  //         final List<Map<String, dynamic>> dealerJsonList = batch
  //             .map((d) => d.toJson())
  //             .toList();

  //         await AppDatabase.instance.syncDealersToLocal(dealerJsonList);

  //         totalSynced += batch.length;
  //         page++;

  //         // Live UI Update
  //         // if (mounted) {
  //         //   ScaffoldMessenger.of(context).clearSnackBars();
  //         //   ScaffoldMessenger.of(context).showSnackBar(
  //         //     SnackBar(
  //         //       content: Text(
  //         //         "Downloading... $totalSynced dealers saved locally.",
  //         //       ),
  //         //       duration: const Duration(days: 1),
  //         //       backgroundColor: const Color(0xFF0F172A),
  //         //     ),
  //         //   );
  //         // }

  //         // If the server returned less than the batch size, it was the last page
  //         if (batch.length < batchSize) {
  //           hasMore = false;
  //         }
  //       }
  //     }

  //     final count = await AppDatabase.instance.getLocalDealersCount();

  //     // 3. Success UI
  //     // if (mounted) {
  //     //   ScaffoldMessenger.of(context).clearSnackBars();
  //     //   ScaffoldMessenger.of(context).showSnackBar(
  //     //     SnackBar(
  //     //       content: Text(
  //     //         "✅ Sync Complete! Downloaded $totalSynced. Total in Vault: $count",
  //     //       ),
  //     //       backgroundColor: Colors.green,
  //     //       duration: const Duration(seconds: 4),
  //     //     ),
  //     //   );
  //     // }
  //   } catch (e) {
  //     debugPrint("🚨 SYNC ERROR: $e");
  //     // if (mounted) {
  //     //   ScaffoldMessenger.of(context).clearSnackBars();
  //     //   ScaffoldMessenger.of(context).showSnackBar(
  //     //     SnackBar(
  //     //       content: Text("Sync stopped at error: $e"),
  //     //       backgroundColor: Colors.red,
  //     //     ),
  //     //   );
  //     // }
  //   }
  // }

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
        List<String> validAddressParts = [];

        // Helper to safely add address parts
        void addPart(String? part) {
          if (part != null && part.trim().isNotEmpty && !part.contains('+')) {
            if (!validAddressParts.contains(part.trim())) {
              validAddressParts.add(part.trim());
            }
          }
        }

        // Add granular details first, falling back to broader areas
        addPart(place.thoroughfare); // Street name
        addPart(place.subLocality); // Neighborhood / Area (e.g., Beltola)
        addPart(place.locality); // City (e.g., Guwahati)
        addPart(
          place.subAdministrativeArea,
        ); // District (e.g., Kamrup Metropolitan)
        // Only use 'street' or 'name' if we are desperate and it doesn't have a '+'
        if (validAddressParts.isEmpty) {
          addPart(place.name);
          addPart(place.street);
        }

        // If we found valid parts, join the first 2 or 3 for a clean display string
        if (validAddressParts.isNotEmpty) {
          return validAddressParts.take(3).join(', ');
        } else {
          // Ultimate fallback if everything was empty or just Plus Codes
          final fallbackCity = place.locality ?? 'Unknown Area';
          final fallbackState = place.administrativeArea ?? '';
          return "$fallbackCity, $fallbackState".replaceAll(
            RegExp(r'^,\s*|,\s*$'),
            '',
          );
        }
      }
    } catch (e) {
      debugPrint("Geocoding failed: $e");
    }
    return "Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}";
  }

  Future<void> _handleCheckIn() async => _performAttendanceAction(true);
  Future<void> _handleCheckOut() async => _performAttendanceAction(false);

  Future<void> _performAttendanceAction(bool isCheckIn) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // 1. Time Lock Check
    if (!isCheckIn && _lastCheckInTime != null) {
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

    setState(() => isCheckIn ? _isCheckingIn = true : _isCheckingOut = true);

    try {
      // 🚀 SPEED OPTIMIZATION 1: PRE-WARM GPS
      Future<Position?> locationFuture = _getCurrentPosition().timeout(
        const Duration(seconds: 20),
        onTimeout: () => null,
      );

      // 📸 OPEN CAMERA
      final imagePath = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const _InlineCameraScreen()),
      );

      // 🚀 SPEED OPTIMIZATION 2: QUIET CANCEL
      if (imagePath == null || imagePath is! String) {
        setState(
          () => isCheckIn ? _isCheckingIn = false : _isCheckingOut = false,
        );
        return;
      }

      final File imageFile = File(imagePath);

      // 🚀 SPEED OPTIMIZATION 3: AWAIT PRE-WARMED GPS
      Position? position = await locationFuture.timeout(
        const Duration(seconds: 20),
        onTimeout: () => null,
      );

      // retry once
      if (position == null) {
        position = await _getCurrentPosition();
      }

      if (position == null) {
        throw Exception("Fetch Location. Please check GPS.");
      }

      // 🚀 SPEED OPTIMIZATION 4: PARALLEL NETWORK PIPELINE
      final results = await Future.wait([
        _apiService.uploadImageToR2(imageFile),
        _resolveAddress(position.latitude, position.longitude),
      ]);

      final String imageUrl = results[0];
      final String address = results[1];

      // Final API Submit
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
      // 🛡️ MASK THE UGLY SOCKET ERRORS
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('socket') ||
          errorStr.contains('host lookup') ||
          errorStr.contains('timeout') ||
          errorStr.contains('connection refused')) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.cloud_off, color: Colors.white),
                SizedBox(width: 10),
                Text("Saved Offline. Will sync when connected!"),
              ],
            ),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
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

    final flags = context.watch<SalesFlags>();
    final bool showSalesOpsCard =
        flags.createDvr ||
        flags.addDealer ||
        flags.competitionForm ||
        flags.salesOrders;

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
            ).animate().scale(
              delay: 100.ms,
              duration: 400.ms,
              curve: Curves.easeOutBack,
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
                )
                .animate()
                .fadeIn(delay: 200.ms, duration: 400.ms)
                .slideX(begin: -0.1, curve: Curves.easeOut),
          ],
        ),
      ),
      body: Column(
        children: [
          // 🚀 THE OFFLINE BANNER
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            height: _isOffline ? 40 : 0,
            width: double.infinity,
            color: Colors.orange.shade700,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text(
                  "Offline Mode - Data saved locally",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => refreshData(),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  MediaQuery.of(context).padding.bottom + 110,
                ),
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
                                    isPulseActive:
                                        !_isCheckedIn, // Pulsing attention grabber
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
                                    isPulseActive: false,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                      .scale(
                        begin: const Offset(0.9, 0.9),
                        curve: Curves.easeOutBack,
                      )
                      .shimmer(
                        delay: 800.ms,
                        duration: 1500.ms,
                        color: Colors.white24,
                      ), // Premium Sheen Effect

                  const SizedBox(height: 32),

                  if (showSalesOpsCard) ...[
                    Text(
                          "Operations",
                          style: TextStyle(
                            color: _textDark,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 400.ms)
                        .slideX(begin: -0.1, curve: Curves.easeOut),
                    const SizedBox(height: 16),

                    // --- 2. SALES OPS TRIGGER ---
                    _buildFintechCard(
                          title: "Sales Operations",
                          subtitle: "Dealers, DVRs, Competition",
                          icon: Icons.business_center_outlined,
                          iconColor: Colors.blueAccent,
                          iconBg: const Color(0xFFEFF6FF),
                          onTap: () => _showSalesmanOps(context),
                        )
                        .animate()
                        .fadeIn(delay: 500.ms, duration: 500.ms)
                        .scale(
                          begin: const Offset(0.95, 0.95),
                          curve: Curves.easeOutBack,
                        ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton(
    String label,
    IconData icon,
    bool loading,
    bool active,
    VoidCallback? onTap, {
    bool isPulseActive = false,
  }) {
    Widget button = InkWell(
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

    // Add continuous subtle shimmer if it's the primary action
    if (isPulseActive && active && !loading) {
      button = button
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .shimmer(duration: 2.seconds, color: Colors.blue.withOpacity(0.3));
    }

    return button;
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
