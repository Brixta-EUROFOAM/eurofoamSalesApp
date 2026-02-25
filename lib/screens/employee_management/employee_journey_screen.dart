// lib/screens/employee_management/employee_journey_screen.dart

import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

// --- Imports ---
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/database/app_database.dart';
import 'package:salesmanapp/models/employee_model.dart';
import 'package:salesmanapp/models/pjp_model.dart';
import 'package:salesmanapp/models/dealer_model.dart';
import 'package:salesmanapp/features/salesJourney/sales_journey_controller.dart';
import 'package:salesmanapp/features/salesJourney/sales_journey_capabilities.dart';
import 'package:salesmanapp/core/feature_flags/sales_flags.dart';
import 'package:salesmanapp/screens/forms/create_dvr.dart';

// --- Technical Map Style & Tools ---
import 'package:salesmanapp/core/app_kernel.dart';
import 'package:salesmanapp/features/journeyMapstyle/journeyMapstyle_controller.dart';
import 'package:salesmanapp/features/journeylocation/journeylocation_controller.dart'; 
import 'package:salesmanapp/services/states/journeyStates/journey_screen_state.dart';

// --- UI OVERLAY ---
import 'package:salesmanapp/technicalSide/screens/journeyUi/journey_overlay_manager.dart';

// --- SALES STATE MACHINES ---
import 'package:salesmanapp/services/states/journeyStates/sales_journey_screen_state.dart';
import 'package:salesmanapp/features/JourneyModeController/journey_mode_result.dart'; // 🚀 Added

class EmployeeJourneyScreen extends StatefulWidget {
  final Employee employee;
  final Map<String, dynamic>? initialJourneyData;
  final VoidCallback? onDestinationConsumed;
  final Function(Pjp pjp, Dealer dealer, DateTime checkInTime)? onJourneyCompleted;

  const EmployeeJourneyScreen({
    super.key,
    required this.employee,
    this.initialJourneyData,
    this.onDestinationConsumed,
    this.onJourneyCompleted,
  });

  @override
  State<EmployeeJourneyScreen> createState() => _EmployeeJourneyScreenState();
}

class _EmployeeJourneyScreenState extends State<EmployeeJourneyScreen> {
  late SalesJourneyController _controller;
  final Completer<MapLibreMapController> _controllerCompleter = Completer();

  // ---------- STATE MACHINES ----------
  final _journeyStartMachine = SalesJourneyStartStateMachine();
  final _journeyStopMachine = SalesJourneyStopStateMachine();

  // ---------- MAP & TRACKING STATE ----------
  late Future<String> _styleFuture;
  final String? _radarApiKey = dotenv.env['RADAR_API_KEY'];

  StreamSubscription? _distanceSub;
  StreamSubscription? _posSub;
  StreamSubscription? _eventSub;

  bool _restoreChecked = false;
  LatLng? _currentUserLocation;
  LatLng? _destinationLocation;
  final List<LatLng> _routeTaken = [];
  bool _isRouteLineLayerAdded = false;

  static const _initialCameraPosition = CameraPosition(
    target: LatLng(26.1445, 91.7362),
    zoom: 12,
  );

  // ---------- UI STATE ----------
  String _distanceDisplay = "Loading...";
  bool _isJourneyActive = false;
  bool _hasArrived = false;
  final _destinationController = TextEditingController();
  
  // 🚀 Added Journey Mode Logic
  JourneyMode _journeyMode = JourneyMode.planned;
  String? _backupTaskId;
  LatLng? _backupDestination;
  String? _backupDealerId;
  Dealer? _backupActiveDealer; // 🚀 Backup memory cache

  // ---------- DATA ----------
  String? _taskId;
  String? _dealerId;
  int? _verifiedDealerId;
  Dealer? _activeDealer; // 🚀 O(1) Memory Cache for instant navigation

  // ---------- THEME ----------
  final Color _bgLight = const Color(0xFFF3F4F6);
  final Color _cardNavy = const Color(0xFF0F172A);
  final Color _dangerRed = const Color(0xFFEF4444);
  final Color _textGrey = const Color(0xFF6B7280);

  // =====================================================
  // INIT
  // =====================================================
  @override
  void initState() {
    super.initState();

    _controller = SalesJourneyController(
      caps: SalesJourneyCapabilities.fromFlags(SalesFlags.dev),
    );

    _styleFuture = _readStyle();

    _journeyStartMachine.addListener(() {
      final state = _journeyStartMachine.value;
      if (!mounted) return;

      if (state is SalesJourneyStartProcessing) {
        setState(() => _distanceDisplay = state.message);
      } else if (state is SalesJourneyStartFailure) {
        _showError(state.error);
        setState(() {
          _isJourneyActive = false;
          _distanceDisplay = "Start Failed";
        });
      } else if (state is SalesJourneyStartSuccess) {
        _handleJourneyStartSuccess();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkActiveSession();

      if (widget.initialJourneyData != null) {
        _loadTaskData(widget.initialJourneyData!);
      } else {
        await _determinePositionAndMoveCamera();
      }
    });
  }

  @override
  void didUpdateWidget(covariant EmployeeJourneyScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialJourneyData != null &&
        widget.initialJourneyData != oldWidget.initialJourneyData) {
      _loadTaskData(widget.initialJourneyData!);
    }
  }

  @override
  void dispose() {
    _cancelJourneySubscriptions();
    _controller.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<String> _readStyle() async {
    final style = AppKernel.instance.feature<JourneyMapStyleController>();
    final result = style.loadStyle(dotenv.env['STADIA_API_KEY']!);
    return result.styleJson;
  }

  // =====================================================
  // 🚀 UNPLANNED MODE TOGGLE
  // =====================================================
  void _toggleJourneyMode() async {
    setState(() {
      _journeyMode = _journeyMode == JourneyMode.planned 
          ? JourneyMode.unplanned 
          : JourneyMode.planned;
    });

    if (_journeyMode == JourneyMode.unplanned) {
      if (_taskId != null) {
        _backupTaskId = _taskId;
        _backupDestination = _destinationLocation;
        _backupDealerId = _dealerId;
        _backupActiveDealer = _activeDealer;
      }
      setState(() {
        _taskId = null;
        _dealerId = null;
        _activeDealer = null; // Clear cache
        _destinationLocation = null;
        _destinationController.text = "";
        _distanceDisplay = "Select Destination";
      });
      await _removeRouteLine();
      await _removeDestinationMarker();
    } else {
      if (_backupTaskId != null) {
        setState(() {
          _taskId = _backupTaskId;
          _dealerId = _backupDealerId;
          _activeDealer = _backupActiveDealer; // Restore cache
          _destinationLocation = _backupDestination;
          _destinationController.text = "Planned Task Active"; // Fallback name
        });
        if (_destinationLocation != null) {
          _addDestinationMarker(_destinationLocation!);
          _getDirectionsAndDrawRoute();
        }
      }
    }
  }

  Future<void> _openDealerSearch() async {
    final result = await showDialog<Dealer>(
      context: context,
      builder: (context) => _ServerDealerSearchDialog(api: ApiService()),
    );

    if (result != null) {
      setState(() {
        _dealerId = result.id;
        _activeDealer = result; // 🚀 CACHE IN MEMORY
        _destinationController.text = result.name;
        _distanceDisplay = "Calculating Route...";
      });

      if (result.latitude != null && result.longitude != null) {
        _destinationLocation = LatLng(result.latitude!, result.longitude!);
        await _addDestinationMarker(_destinationLocation!);
        
        if (_currentUserLocation == null) {
          await _determinePositionAndMoveCamera();
        }
        
        if (_currentUserLocation != null) {
          await _getDirectionsAndDrawRoute();
          await _fitBounds();
        }
      } else {
        _showError("Selected dealer has no GPS coordinates.");
      }

      setState(() => _distanceDisplay = "Ready to start");
    }
  }

  // =====================================================
  // RESTORE & START HOOKS
  // =====================================================

  Future<void> _checkActiveSession() async {
    if (_restoreChecked) return;
    _restoreChecked = true;

    final restoreMachine = RestoreSalesJourneyStateMachine();

    restoreMachine.addListener(() {
      final state = restoreMachine.value;
      if (state is RestoreSalesResumed) {
        _handleRestoreSuccess(state.snapshot);
      }
    });

    await restoreMachine.dispatch(
      RestoreSalesJourneyIntent(
        db: AppDatabase.instance,
        trackingController: _controller,
        askUser: _askUserToResume,
      ),
    );
  }

  Future<bool> _askUserToResume(RestoreSalesJourneySnapshot snapshot) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Resume journey?"),
            content: Text(
              "You have an active visit to ${snapshot.displayName}. Continue tracking?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Discard"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Resume"),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _handleRestoreSuccess(RestoreSalesJourneySnapshot snapshot) async {
    setState(() {
      _isJourneyActive = true;
      _taskId = snapshot.taskId;
      _journeyMode = JourneyMode.planned; // Lock UI to active
      _destinationController.text = snapshot.displayName ?? "Resumed Journey";
      _distanceDisplay = "${(snapshot.distance / 1000.0).toStringAsFixed(2)} km";

      _currentUserLocation = snapshot.lastPosition;
      _routeTaken.clear();
      _routeTaken.addAll(snapshot.path);
    });

    final controller = await _controllerCompleter.future;

    if (snapshot.path.isNotEmpty) {
      await JourneyMapRenderer.updateTravelledPath(controller, snapshot.path);
    }
    if (snapshot.lastPosition != null) {
      await JourneyMapRenderer.drawUserLocationPointer(
        controller,
        snapshot.lastPosition!,
      );
    }
    if (snapshot.path.length >= 2) {
      await JourneyMapRenderer.fitBounds(
        controller,
        snapshot.path.first,
        snapshot.path.last,
      );
    }

    _attachStreams();
  }

  void _handleJourneyStartSuccess() {
    setState(() {
      _isJourneyActive = true;
      _distanceDisplay = "0.00 km";
      _routeTaken.clear();
      _hasArrived = false;
    });

    _attachStreams();
  }

  void _attachStreams() {
    _cancelJourneySubscriptions();

    _distanceSub = _controller.distanceStream.listen((dist) {
      if (mounted) {
        setState(
          () => _distanceDisplay = "${(dist / 1000.0).toStringAsFixed(2)} km",
        );
      }
    });

    _posSub = _controller.positionStream.listen((latLng) {
      _currentUserLocation = latLng;
      _routeTaken.add(latLng);

      _drawUserLocationPointer(latLng);
      _updateTravelledPolyline();
    });

    _eventSub = _controller.eventStream.listen((event) {
      if (event == SalesJourneyEvent.arrived && !_hasArrived) {
        _hasArrived = true;
        _showArrivalDialog();
      }
    });
  }

  // =====================================================
  // LOAD DATA & MAP DRAWING
  // =====================================================

  void _loadTaskData(Map<String, dynamic> data) async {
    _dealerId = data['dealerId']?.toString();
    _verifiedDealerId = data['verifiedDealerId'];
    _taskId = data['taskId']?.toString();
    _journeyMode = JourneyMode.planned;

    final String displayName = data['displayName'] ?? "Visit";

    setState(() {
      _destinationController.text = displayName;
      _distanceDisplay = "Calculating Route...";
    });

    await _removeRouteLine();
    await _removeDestinationMarker();
    _routeTaken.clear();

    if (_currentUserLocation == null) {
      await _determinePositionAndMoveCamera();
    }

    if (_dealerId != null) {
      try {
        final dealer = await ApiService().fetchDealerById(_dealerId!);
        _activeDealer = dealer; // 🚀 CACHE IN MEMORY

        if (dealer.latitude != null && dealer.longitude != null) {
          _destinationLocation = LatLng(dealer.latitude!, dealer.longitude!);
          await _addDestinationMarker(_destinationLocation!);

          if (_currentUserLocation != null) {
            await _getDirectionsAndDrawRoute();
            await _fitBounds();
          }
        }
      } catch (e) {
        dev.log("Dealer load error: $e");
      }
    }

    if (mounted) {
      setState(() => _distanceDisplay = "Ready to start");
    }

    widget.onDestinationConsumed?.call();
  }

  // =====================================================
  // JOURNEY ACTIONS
  // =====================================================

  Future<void> _handleStart() async {
    // Validation
    if (_journeyMode == JourneyMode.planned && _taskId == null) {
      _showError("Select a planned task first.");
      return;
    }
    if (_journeyMode == JourneyMode.unplanned && _dealerId == null) {
      _showError("Select a dealer for the unplanned visit.");
      return;
    }

    final hasPermission = await _ensureJourneyPermission();
    if (!hasPermission) return;

    setState(() {
      _isJourneyActive = true;
      _distanceDisplay = "Starting...";
    });

    _journeyStartMachine.dispatch(
      StartSalesJourneyIntent(
        userId: int.parse(widget.employee.id),
        taskId: _taskId, 
        displayName: _destinationController.text,
        dealerId: _dealerId,
        verifiedDealerId: _verifiedDealerId,
        journeyMode: _journeyMode,
        destinationLocation: _destinationLocation,
        trackingController: _controller,
        apiService: ApiService(),
      ),
    );
  }

  Future<void> _handleStop() async {
    if (!_isJourneyActive) return;

    setState(() {
      _distanceDisplay = "Stopping...";
    });

    await _journeyStopMachine.dispatch(
      StopSalesJourneyIntent(
        userId: int.parse(widget.employee.id),
        taskId: _taskId ?? "",
        currentJourneyId: _controller.currentJourneyId ?? "",
        totalDistance: _controller.totalDistance,
        trackingController: _controller,
        onCleanup: _handleJourneyCleanup,
      ),
    );
  }

  void _handleJourneyCleanup() async {
    _cancelJourneySubscriptions();

    if (mounted) {
      // 🚀 1. Capture the CACHED DEALER object before resetting!
      final completedDealer = _activeDealer;

      setState(() {
        _isJourneyActive = false;
        _distanceDisplay = "0.00 km";
        _taskId = null;
        _dealerId = null; 
        _activeDealer = null; // 👈 Clean cache
        _hasArrived = false;
        _routeTaken.clear();
        _journeyMode = JourneyMode.planned; // Reset mode
        _destinationController.clear();
      });

      await _removeRouteLine();
      await _removeDestinationMarker();
      await _determinePositionAndMoveCamera();

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Journey Completed"),
          content: const Text("Would you like to fill the Daily Visit Report now?"),
          actions: [
            TextButton(
              child: const Text("Later", style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _cardNavy),
              child: const Text("Open DVR", style: TextStyle(color: Colors.white)),
              onPressed: () { 
                // 🚀 2. SYNCHRONOUS NAVIGATION! NO MORE 'async/await' DELAY. (O(1) Time Complexity)
                Navigator.pop(context); // Close dialog
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateDvrScreen(
                      employee: widget.employee,
                      dealer: completedDealer, // Pre-filled from memory instantly
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }
  }

  Future<void> _launchNavigation() async {
    if (_destinationLocation != null) {
      final url = Uri.parse(
        'google.navigation:q=${_destinationLocation!.latitude},${_destinationLocation!.longitude}',
      );
      if (await canLaunchUrl(url)) await launchUrl(url);
    }
  }

  void _showArrivalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('DESTINATION REACHED'),
        content: const Text('You have arrived at your target location.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleStop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // MAP RENDERER DELEGATES
  // =====================================================

  Future<bool> _ensureJourneyPermission() async {
    return await JourneyPermissionGuard.ensurePermissions(
      onShowDisclosure: () async {
        if (!mounted) return false;
        return await JourneyDialogs.showDisclosure(
          context: context,
          primaryColor: _cardNavy,
        );
      },
      onShowSettings: () {
        if (mounted) JourneyDialogs.showSettings(context);
      },
      onError: (message) => _showError(message),
    );
  }

  Future<void> _determinePositionAndMoveCamera() async {
    try {
      final location = await JourneyLocationLogic.resolveCurrentLocation(
        onEnsurePermissions: _ensureJourneyPermission,
        onFetchLocationFromController: () async {
          return await AppKernel.instance
              .feature<JourneyLocationController>()
              .resolveCurrentLocation();
        },
      );

      if (location != null) {
        _currentUserLocation = location;
        if (mounted && !_isJourneyActive && _distanceDisplay.contains("Map")) {
          setState(() => _distanceDisplay = "My Location");
        }

        final controller = await _controllerCompleter.future;
        if (_destinationLocation == null) {
          await controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: _currentUserLocation!, zoom: 15.0),
            ),
          );
        }
        await JourneyMapRenderer.drawUserLocationPointer(
          controller,
          _currentUserLocation!,
        );
      }
    } catch (_) {}
  }

  Future<void> _getDirectionsAndDrawRoute() async {
    if (_currentUserLocation == null ||
        _destinationLocation == null ||
        _radarApiKey == null){
      return;}
    final controller = await _controllerCompleter.future;
    await JourneyMapRenderer.drawRoute(
      controller: controller,
      start: _currentUserLocation!,
      end: _destinationLocation!,
      apiKey: _radarApiKey,
    );
    _isRouteLineLayerAdded = true;
  }

  Future<void> _addDestinationMarker(LatLng point) async {
    final controller = await _controllerCompleter.future;
    await JourneyMapRenderer.addDestinationMarker(controller, point);
  }

  Future<void> _drawUserLocationPointer(LatLng point) async {
    final controller = await _controllerCompleter.future;
    await JourneyMapRenderer.drawUserLocationPointer(controller, point);
  }

  Future<void> _updateTravelledPolyline() async {
    final controller = await _controllerCompleter.future;
    await JourneyMapRenderer.updateTravelledPath(controller, _routeTaken);
  }

  Future<void> _fitBounds() async {
    if (_currentUserLocation == null || _destinationLocation == null) return;
    final controller = await _controllerCompleter.future;
    await JourneyMapRenderer.fitBounds(
      controller,
      _currentUserLocation!,
      _destinationLocation!,
    );
  }

  Future<void> _removeRouteLine() async {
    if (!_isRouteLineLayerAdded) return;

    final controller = await _controllerCompleter.future;
    try {
      await controller.removeLayer('route-line');
    } catch (_) {}
    try {
      await controller.removeSource('route-source');
    } catch (_) {}

    _isRouteLineLayerAdded = false;
  }

  Future<void> _removeDestinationMarker() async {
    final controller = await _controllerCompleter.future;
    try {
      await controller.removeLayer('dest-layer-inner');
    } catch (_) {}
    try {
      await controller.removeLayer('dest-layer-outer');
    } catch (_) {}
    try {
      await controller.removeSource('dest-source');
    } catch (_) {}
  }

  void _showError(String message) {
    if (mounted){
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
  }}

  void _cancelJourneySubscriptions() {
    _distanceSub?.cancel();
    _posSub?.cancel();
    _eventSub?.cancel();
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final salesFlags = context.watch<SalesFlags>();
    final bool isPlanned = _journeyMode == JourneyMode.planned;
    final bool canStartJourney = _isJourneyActive || 
        (isPlanned ? _taskId != null : _dealerId != null);

    if (!salesFlags.journey) {
      return Scaffold(
        backgroundColor: _bgLight,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off_rounded, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                "Journey Tracking Unavailabe Right Now",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        SizedBox.expand(
          child: FutureBuilder<String>(
            future: _styleFuture,
            builder: (ctx, snap) {
              if (!snap.hasData) return Container(color: _bgLight);
              return MapLibreMap(
                styleString: snap.data!,
                initialCameraPosition: _initialCameraPosition,
                onMapCreated: (c) {
                  if (!_controllerCompleter.isCompleted){
                    _controllerCompleter.complete(c);}
                  if (_isJourneyActive) {
                    if (_currentUserLocation != null){
                      _drawUserLocationPointer(_currentUserLocation!);}
                    if (_destinationLocation != null){
                      _addDestinationMarker(_destinationLocation!);}
                    if (_routeTaken.isNotEmpty) _updateTravelledPolyline();
                  }
                },
                trackCameraPosition: true,
                myLocationEnabled: false,
              );
            },
          ),
        ),

        Positioned(
          top: 50,
          right: 16,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.my_location, color: _cardNavy),
              onPressed: _determinePositionAndMoveCamera,
            ),
          ),
        ),

        Positioned.fill(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 72,
              ),
              child: JourneyOverlayManager(
                isJourneyActive: _isJourneyActive,
                distance: _distanceDisplay,
                onStop: _handleStop,
                onNavigate: _launchNavigation,
                idlePanel: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildIdleJourneyPanel(context, isPlanned),
                    const SizedBox(height: 24),
                    _StartJourneySlider(
                      key: ValueKey(_isJourneyActive),
                      isJourneyActive: false,
                      onSlideAction: _handleStart,
                      canStart: canStartJourney,
                      cardNavy: _cardNavy,
                      dangerRed: _dangerRed,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIdleJourneyPanel(BuildContext context, bool isPlanned) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              isPlanned ? Icons.assignment_outlined : Icons.storefront_outlined,
              color: _textGrey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPlanned ? "PLANNED TASK" : "UNPLANNED VISIT",
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                      fontSize: 12,
                      letterSpacing: 1.1,
                    ),
                  ),
                  Text(
                    isPlanned
                        ? "Assigned via Sales Plan"
                        : "Ad-hoc Dealer Visit",
                    style: TextStyle(
                      color: _textGrey.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: _toggleJourneyMode,
              icon: const Icon(Icons.swap_horiz, size: 16),
              label: Text(isPlanned ? "UNPLANNED" : "PLANNED"),
              style: TextButton.styleFrom(
                foregroundColor: _cardNavy,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                textStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)), 
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: TextField(
              controller: _destinationController,
              readOnly: true,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  isPlanned ? Icons.explore : Icons.location_on_outlined,
                  color: const Color(0xFF0F172A),
                ),
                hintText: isPlanned
                    ? "Select a Task to Begin"
                    : "Waiting for Dealer selection...",
                hintStyle: const TextStyle(color: Color(0xFF64748B)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),
        if (!isPlanned)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text("SEARCH DEALERS"),
              style: OutlinedButton.styleFrom(
                foregroundColor: _cardNavy,
                side: BorderSide(color: _cardNavy),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: _openDealerSearch,
            ),
          ),
      ],
    );
  }
}

// =====================================================
// SLIDER
// =====================================================

class _StartJourneySlider extends StatelessWidget {
  final bool isJourneyActive;
  final Future<void> Function() onSlideAction;
  final bool canStart;
  final Color cardNavy;
  final Color dangerRed;

  const _StartJourneySlider({
    super.key,
    required this.isJourneyActive,
    required this.onSlideAction,
    required this.canStart,
    required this.cardNavy,
    required this.dangerRed,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = canStart || isJourneyActive;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isEnabled ? cardNavy : Colors.grey).withOpacity(0.35),
            blurRadius: 25,
            spreadRadius: -2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SlideAction(
        onSubmit: isEnabled
            ? () async {
                await onSlideAction();
                return null;
              }
            : null,
        innerColor: Colors.white,
        outerColor: isEnabled ? cardNavy : const Color(0xFFF1F5F9),
        sliderButtonIcon: const Icon(
          Icons.arrow_forward_rounded,
          color: Color(0xFF0F172A),
          size: 26,
        ),
        text: isEnabled ? 'SLIDE TO START VISIT' : 'SELECT DESTINATION FIRST',
        enabled: isEnabled,
        textStyle: TextStyle(
          color: isEnabled ? Colors.white : const Color(0xFF94A3B8),
          fontSize: 15,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
        borderRadius: 24,
        elevation: 0,
        height: 76,
        sliderRotate: false,
      ),
    );
  }
}

// ============================================================
// 🔎 DEALER SEARCH DIALOG (Reusable from DVR)
// ============================================================
class _ServerDealerSearchDialog extends StatefulWidget {
  final ApiService api;

  const _ServerDealerSearchDialog({required this.api});

  @override
  State<_ServerDealerSearchDialog> createState() =>
      _ServerDealerSearchDialogState();
}

class _ServerDealerSearchDialogState
    extends State<_ServerDealerSearchDialog> {
  List<Dealer> _dealers = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _performSearch("");
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);

    final results = await widget.api.fetchDealers(search: query, limit: 20);

    if (mounted) {
      setState(() {
        _dealers = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Select Dealer"),
      content: SizedBox(
        width: double.maxFinite,
        height: 420,
        child: Column(
          children: [
            TextField(onChanged: _onSearchChanged, decoration: const InputDecoration(hintText: "Search name...")),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _dealers.length,
                      itemBuilder: (context, index) {
                        final dealer = _dealers[index];
                        return ListTile(
                          title: Text(dealer.name),
                          subtitle: Text(dealer.address),
                          onTap: () => Navigator.pop(context, dealer),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}