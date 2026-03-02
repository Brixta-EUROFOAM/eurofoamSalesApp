// lib/screens/employee_management/employee_journey_screen.dart

import 'dart:async';
import 'dart:developer' as dev;
import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
import 'package:salesmanapp/features/JourneyModeController/journey_mode_result.dart';

class EmployeeJourneyScreen extends StatefulWidget {
  final Employee employee;
  final Map<String, dynamic>? initialJourneyData;
  final VoidCallback? onDestinationConsumed;
  final Function(Pjp pjp, Dealer dealer, DateTime checkInTime)?
  onJourneyCompleted;

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
  bool _isMapTrackingUser = true; // 🚀 Auto-follow toggle

  final _destinationController = TextEditingController();

  JourneyMode _journeyMode = JourneyMode.planned;
  String? _backupTaskId;
  LatLng? _backupDestination;
  String? _backupDealerId;
  Dealer? _backupActiveDealer;

  String? _taskId;
  String? _dealerId;
  int? _verifiedDealerId;
  Dealer? _activeDealer;

  // ---------- THEME ----------
  final Color _bgLight = const Color(0xFFF3F4F6);
  final Color _cardNavy = const Color(0xFF0F172A);
  final Color _dangerRed = const Color(0xFFEF4444);
  final Color _textGrey = const Color(0xFF6B7280);

  // 🚀 ISOLATE DATA RECEIVER (Time Complexity O(1))
  void _onForegroundServiceData(Object data) {
    // 👈 Removed the '?'
    dev.log("⚡ RAW ISOLATE DATA HIT THE UI: $data", name: 'JourneyDebug');

    try {
      double lat = 0.0;
      double lng = 0.0;
      double distance = 0.0;

      if (data is String) {
        final parsedData = jsonDecode(data);
        lat = (parsedData['lat'] as num).toDouble();
        lng = (parsedData['lng'] as num).toDouble();
        distance = (parsedData['distance'] as num).toDouble();
      } else if (data is Map) {
        lat = (data['lat'] as num).toDouble();
        lng = (data['lng'] as num).toDouble();
        distance = (data['distance'] as num).toDouble();
      } else {
        return;
      }

      dev.log(
        "📱 [UI RECEIVER] Caught distance: $distance meters",
        name: 'JourneyDebug',
      );

      _controller.feedNewLocation(LatLng(lat, lng), distance);

      if (_isJourneyActive && mounted) {
        setState(() {
          _distanceDisplay = "${(distance / 1000.0).toStringAsFixed(2)} km";
        });
      }
    } catch (e) {
      dev.log("⚠️ Isolate Data Parsing Error: $e");
    }
  }

  @override
  void initState() {
    super.initState();

    _controller = SalesJourneyController(
      caps: SalesJourneyCapabilities.fromFlags(SalesFlags.dev),
    );

    // 🚀 THE ULTIMATE FIX: You MUST initialize the port in v6+ before listening!
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.addTaskDataCallback(_onForegroundServiceData);

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
    // 🚀 THE PROPER FIX: Clean up the official callback
    FlutterForegroundTask.removeTaskDataCallback(_onForegroundServiceData);

    _cancelJourneySubscriptions();
    _controller.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  // =====================================================
  // CORE TRACKING & STREAMS (Accuracy & Complexity Handlers)
  // =====================================================
  void _cancelJourneySubscriptions() {
    _distanceSub?.cancel();
    _posSub?.cancel();
    _eventSub?.cancel();
  }

  void _handleJourneyStartSuccess() async {
    setState(() {
      _isJourneyActive = true;
      _distanceDisplay = "0.00 km";
      _routeTaken.clear();
      _hasArrived = false;
      _isMapTrackingUser = true;
    });

    // 🚀 PREMIUM 3D CAMERA TILT
    try {
      final controller = await _controllerCompleter.future;
      if (_currentUserLocation != null) {
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _currentUserLocation!,
              zoom: 16.5,
              tilt: 45.0,
            ),
          ),
          duration: const Duration(milliseconds: 1200),
        );
      }
    } catch (_) {}

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

    // 👇 REPLACE THIS ENTIRE _posSub BLOCK 👇
    _posSub = _controller.positionStream.listen((latLng) async {
      _currentUserLocation = latLng;
      _routeTaken.add(latLng); // 1. Keep it in RAM for fast UI drawing

      // 2. Draw map line every 5 points
      if (_routeTaken.length % 5 == 0) {
        _updateTravelledPolyline();
      }

      // 🚀 3. THE CRASH-PROOF FIX: Write to SQLite Hard Drive Immediately!
      if (_isJourneyActive && _controller.currentJourneyId != null) {
        try {
          await AppDatabase.instance.insertBreadcrumb(
            JourneyBreadcrumbsCompanion.insert(
              id: const Uuid().v4(),
              journeyId: _controller.currentJourneyId!,
              latitude: latLng.latitude,
              longitude: latLng.longitude,
              h3Index:
                  "pending", // Optional: Update if using Uber's H3 geo-indexing later
              totalDistance: drift.Value(
                _controller.totalDistance,
              ), // Use drift.Value for columns with defaults
              recordedAt: DateTime.now(),
            ),
          );
        } catch (e) {
          dev.log("⚠️ Failed to write breadcrumb to DB: $e");
        }
      }
    });
    // 👆 END OF REPLACEMENT 👇

    _eventSub = _controller.eventStream.listen((event) {
      if (event == SalesJourneyEvent.arrived && !_hasArrived) {
        _hasArrived = true;
        _showArrivalDialog();
      }
    });
  }

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
        _activeDealer = dealer;

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

    if (mounted) setState(() => _distanceDisplay = "Ready to start");
    widget.onDestinationConsumed?.call();
  }

  Future<String> _readStyle() async {
    final style = AppKernel.instance.feature<JourneyMapStyleController>();
    final result = style.loadStyle(dotenv.env['STADIA_API_KEY']!);
    return result.styleJson;
  }

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
        _activeDealer = null;
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
          _activeDealer = _backupActiveDealer;
          _destinationLocation = _backupDestination;
          _destinationController.text = "Planned Task Active";
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
        _activeDealer = result;
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              "Resume journey?",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(
              "You have an active visit to ${snapshot.displayName}. Continue tracking?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  "Discard",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cardNavy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Resume",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ).animate().scale(curve: Curves.easeOutBack, duration: 400.ms),
        ) ??
        false;
  }

  void _handleRestoreSuccess(RestoreSalesJourneySnapshot snapshot) async {
    setState(() {
      _isJourneyActive = true;
      _taskId = snapshot.taskId;
      _journeyMode = JourneyMode.planned;
      _destinationController.text = snapshot.displayName ?? "Resumed Journey";
      _distanceDisplay =
          "${(snapshot.distance / 1000.0).toStringAsFixed(2)} km";
      _isMapTrackingUser = true;

      _currentUserLocation = snapshot.lastPosition;
      _routeTaken.clear();
      _routeTaken.addAll(snapshot.path);
    });

    final controller = await _controllerCompleter.future;

    if (snapshot.path.isNotEmpty) {
      await JourneyMapRenderer.updateTravelledPath(controller, snapshot.path);
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

  Future<void> _handleStart() async {
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

    if (_routeTaken.isNotEmpty) {
      await _updateTravelledPolyline();
    }

    await _journeyStopMachine.dispatch(
      StopSalesJourneyIntent(
        userId: int.parse(widget.employee.id),
        taskId: _taskId ?? "",
        currentJourneyId: _controller.currentJourneyId ?? "",
        totalDistance:
            _controller.totalDistance, // Now accurate thanks to Step 2!
        path: List.from(_routeTaken), // 🚀 THE FIX: Pass the red line data!
        trackingController: _controller,
        onCleanup: _handleJourneyCleanup,
      ),
    );
  }

  void _handleJourneyCleanup() async {
    _cancelJourneySubscriptions();

    if (mounted) {
      final completedDealer = _activeDealer;

      setState(() {
        _isJourneyActive = false;
        _distanceDisplay = "0.00 km";
        _taskId = null;
        _dealerId = null;
        _activeDealer = null;
        _hasArrived = false;
        _routeTaken.clear();
        _journeyMode = JourneyMode.planned;
        _destinationController.clear();
      });

      await _removeRouteLine();
      await _removeDestinationMarker();

      final controller = await _controllerCompleter.future;
      if (_currentUserLocation != null) {
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _currentUserLocation!, zoom: 14.0, tilt: 0),
          ),
          duration: const Duration(seconds: 1),
        );
      }

      showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF10B981),
                  size: 64,
                ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 16),
                const Text(
                  "Journey Completed",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Would you like to fill the Daily Visit Report now?",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Later",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _cardNavy,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreateDvrScreen(
                                employee: widget.employee,
                                dealer: completedDealer,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          "Open DVR",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.location_on, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('Arrived'),
          ],
        ),
        content: const Text('You have arrived at your target location.'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _cardNavy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _handleStop();
            },
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ).animate().scale(curve: Curves.easeOutBack, duration: 400.ms),
    );
  }

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
            duration: const Duration(milliseconds: 800),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _getDirectionsAndDrawRoute() async {
    if (_currentUserLocation == null ||
        _destinationLocation == null ||
        _radarApiKey == null)
      return;
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
      await controller.removeSource('route-source');
    } catch (_) {}
    _isRouteLineLayerAdded = false;
  }

  Future<void> _removeDestinationMarker() async {
    final controller = await _controllerCompleter.future;
    try {
      await controller.removeLayer('dest-layer-inner');
      await controller.removeLayer('dest-layer-outer');
      await controller.removeSource('dest-source');
    } catch (_) {}
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: _dangerRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final salesFlags = context.watch<SalesFlags>();
    final bool isPlanned = _journeyMode == JourneyMode.planned;
    final bool canStartJourney =
        _isJourneyActive || (isPlanned ? _taskId != null : _dealerId != null);

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
                "Journey Tracking Unavailable",
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

                // 🚀 HARDWARE ACCELERATED TRACKING
                myLocationEnabled: true,
                myLocationTrackingMode: _isMapTrackingUser
                    ? MyLocationTrackingMode.tracking
                    : MyLocationTrackingMode.none,
                myLocationRenderMode: MyLocationRenderMode.compass,

                // 🚀 SMART UX: Detects if the user drags the map physically
                onCameraTrackingDismissed: () {
                  if (_isMapTrackingUser && mounted) {
                    setState(() => _isMapTrackingUser = false);
                  }
                },

                onMapCreated: (c) {
                  if (!_controllerCompleter.isCompleted) {
                    _controllerCompleter.complete(c);
                  }
                  if (_isJourneyActive) {
                    if (_destinationLocation != null)
                      _addDestinationMarker(_destinationLocation!);
                    if (_routeTaken.isNotEmpty) _updateTravelledPolyline();
                  }
                },
              ).animate().fadeIn(duration: 800.ms);
            },
          ),
        ),

        // 🚀 SMART RECENTER BUTTON
        Positioned(
          top: 50,
          right: 16,
          child:
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    _isMapTrackingUser
                        ? Icons.my_location
                        : Icons.location_searching,
                    color: _isMapTrackingUser
                        ? Colors.blueAccent
                        : const Color(0xFF6B7280),
                  ),
                  onPressed: () async {
                    setState(() => _isMapTrackingUser = true);
                    if (_currentUserLocation != null) {
                      final controller = await _controllerCompleter.future;
                      controller.animateCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(
                            target: _currentUserLocation!,
                            zoom: 16.5,
                            tilt: _isJourneyActive ? 45 : 0,
                          ),
                        ),
                        duration: const Duration(milliseconds: 600),
                      );
                    }
                  },
                ),
              ).animate().scale(
                delay: 500.ms,
                duration: 400.ms,
                curve: Curves.easeOutBack,
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
                idlePanel:
                    Column(
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
                        )
                        .animate()
                        .slideY(
                          begin: 0.2,
                          duration: 500.ms,
                          curve: Curves.easeOutCubic,
                        )
                        .fadeIn(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 🚀 PREMIUM DESIGN UPGRADE: Interactive Material Card
  Widget _buildIdleJourneyPanel(BuildContext context, bool isPlanned) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _cardNavy.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isPlanned
                    ? Icons.assignment_outlined
                    : Icons.storefront_outlined,
                color: _cardNavy,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPlanned ? "PLANNED TASK" : "UNPLANNED VISIT",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: _cardNavy,
                      fontSize: 13,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    isPlanned
                        ? "Assigned via Sales Plan"
                        : "Ad-hoc Dealer Visit",
                    style: TextStyle(
                      color: _textGrey,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: _toggleJourneyMode,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) =>
                    RotationTransition(turns: anim, child: child),
                child: Icon(
                  Icons.swap_horiz,
                  size: 18,
                  key: ValueKey(isPlanned),
                ),
              ),
              label: Text(isPlanned ? "UNPLANNED" : "PLANNED"),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                backgroundColor: Colors.blueAccent.withOpacity(0.1),
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isPlanned ? null : _openDealerSearch,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isPlanned
                      ? Colors.transparent
                      : Colors.blueAccent.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    isPlanned ? Icons.explore_rounded : Icons.search_rounded,
                    color: _cardNavy,
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _destinationController.text.isEmpty
                          ? (isPlanned
                                ? "Select a Task to Begin"
                                : "Search for a Dealer...")
                          : _destinationController.text,
                      style: TextStyle(
                        color: _destinationController.text.isEmpty
                            ? _textGrey
                            : _cardNavy,
                        fontWeight: _destinationController.text.isEmpty
                            ? FontWeight.w500
                            : FontWeight.w800,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!isPlanned && _destinationController.text.isEmpty)
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.grey,
                      size: 16,
                    ),
                ],
              ),
            ),
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

    Widget sliderWidget = SlideAction(
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
    );

    if (isEnabled && !isJourneyActive) {
      sliderWidget = sliderWidget
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(duration: 2500.ms, color: Colors.blue.withOpacity(0.4));
    }

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
      child: sliderWidget,
    );
  }
}

// ============================================================
// 🔎 UPGRADED DEALER SEARCH DIALOG
// ============================================================
class _ServerDealerSearchDialog extends StatefulWidget {
  final ApiService api;
  const _ServerDealerSearchDialog({required this.api});
  @override
  State<_ServerDealerSearchDialog> createState() =>
      _ServerDealerSearchDialogState();
}

class _ServerDealerSearchDialogState extends State<_ServerDealerSearchDialog> {
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
    try {
      final results = await widget.api.fetchDealers(search: query, limit: 20);
      if (mounted) {
        setState(() {
          _dealers = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        "Select Dealer",
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      contentPadding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 10,
        bottom: 0,
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(
          children: [
            TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: "Search by name or zone...",
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0F172A),
                      ),
                    )
                  : _dealers.isEmpty
                  ? const Center(
                      child: Text(
                        "No dealers found.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _dealers.length,
                      separatorBuilder: (context, index) =>
                          Divider(color: Colors.grey.shade200, height: 1),
                      itemBuilder: (context, index) {
                        final dealer = _dealers[index];
                        final String displayZone = dealer.region.isNotEmpty
                            ? dealer.region
                            : "Unknown Zone";
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 0,
                          ),
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFEFF6FF),
                            child: Icon(
                              Icons.storefront,
                              color: Colors.blueAccent,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            dealer.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF111827),
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.orange.shade200,
                                    ),
                                  ),
                                  child: Text(
                                    "Zone: $displayZone",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    dealer.address,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onTap: () => Navigator.pop(context, dealer),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            "CANCEL",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ).animate().scale(curve: Curves.easeOutBack, duration: 400.ms);
  }
}
