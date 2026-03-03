// lib/screens/technical_journey/technical_journey_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_radar/flutter_radar.dart';
import 'package:geocoding/geocoding.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Core & Models
import 'package:salesmanapp/core/feature_flags/technical_flags.dart';
import 'package:salesmanapp/core/app_kernel.dart';
import 'package:salesmanapp/models/employee_model.dart';
import 'package:salesmanapp/models/pjp_model.dart';
import 'package:salesmanapp/api/api_service.dart';

// Features
import 'package:salesmanapp/features/mapselectionpjp/map_selection_controller.dart';
// import 'package:salesmanapp/features/mapselectionpjp/map_selection_result.dart';
import 'package:salesmanapp/features/unplanned_journey/unplanned_journey_result.dart';
import 'package:salesmanapp/features/journeytracking/journey_tracking_controller.dart';
import 'package:salesmanapp/features/journeytracking/journey_tracking_result.dart';
import 'package:salesmanapp/features/launchgooglemapsJourneyscreen/googlemaps_controller.dart';
import 'package:salesmanapp/features/JourneyModeController/journey_mode_result.dart';
import 'package:salesmanapp/features/JourneyModeController/journey_mode_controller.dart';
import 'package:salesmanapp/features/journeylocation/journeylocation_controller.dart';
import 'package:salesmanapp/features/journeyMapstyle/journeyMapstyle_controller.dart';
import 'package:salesmanapp/services/states/journeyStates/journey_screen_state.dart';
import 'package:salesmanapp/database/app_database.dart';

// --- UI OVERLAY ---
import 'package:salesmanapp/technicalSide/screens/journeyUi/journey_overlay_manager.dart';

class TechnicalJourneyScreen extends StatefulWidget {
  final Employee employee;
  final Map<String, dynamic>? initialJourneyData;
  final VoidCallback? onDestinationConsumed;
  final Function(
    Pjp pjp,
    dynamic locationEntity,
    bool isSite,
    DateTime checkInTime,
  )?
  onJourneyCompleted;

  const TechnicalJourneyScreen({
    super.key,
    required this.employee,
    this.initialJourneyData,
    this.onDestinationConsumed,
    this.onJourneyCompleted,
  });

  @override
  State<TechnicalJourneyScreen> createState() => _TechnicalJourneyScreenState();
}

class _TechnicalJourneyScreenState extends State<TechnicalJourneyScreen> {
  late final TechnicalFlags flags;
  final Completer<MapLibreMapController> _controllerCompleter = Completer();
  late Future<String> _styleFuture;
  late final MapSelectionController _mapSelectionController = AppKernel.instance
      .feature<MapSelectionController>();
  final _searchController = TextEditingController();

  bool _isSearching = false;
  String? _currentGeoTrackingDbId;
  double _totalDistanceTravelled = 0.0;
  LatLng? _lastRecordedLocation;

  final _journeyStartMachine = JourneyStartStateMachine();

  // 🚀 O(1) REBUILDS
  final ValueNotifier<String> _distanceDisplay = ValueNotifier<String>(
    "Initializing...",
  );

  final _destinationController = TextEditingController();
  late JourneyMode _journeyMode;
  bool _isSelectionMode = false;
  final _mapInitMachine = MapInitStateMachine();
  final String? _stadiaApiKey = dotenv.env['STADIA_API_KEY'];
  final String? _radarApiKey = dotenv.env['RADAR_API_KEY'];
  Pjp? _backupPlannedPjp;
  LatLng? _backupDestination;

  // Journey State
  bool _isJourneyActive = false;
  bool _hasArrived = false;

  // 🚀 NATIVE TRACKING STATE (From File 1)
  bool _isMapTrackingUser = true;

  StreamSubscription? _distanceSub;
  StreamSubscription? _posSub;
  StreamSubscription? _eventSub;
  Pjp? _currentPjp;
  bool _isSiteVisit = true;
  LatLng? _currentUserLocation;
  LatLng? _destinationLocation;
  final List<LatLng> _routeTaken = [];
  final _journeyStopMachine = JourneyStopStateMachine();
  bool _isRouteLineLayerAdded = false;
  DateTime _lastPolylineUpdate = DateTime.fromMillisecondsSinceEpoch(0);

  // 🚀 BATTERY SAVER: Throttle Polyline Renders
  bool _canUpdatePolyline() {
    final now = DateTime.now();
    if (now.difference(_lastPolylineUpdate).inMilliseconds < 500) {
      return false;
    }
    _lastPolylineUpdate = now;
    return true;
  }

  bool _restoreChecked = false;

  static const _initialCameraPosition = CameraPosition(
    target: LatLng(26.1445, 91.7362),
    zoom: 12,
  );

  // Theme
  final Color _bgLight = const Color(0xFFF3F4F6);
  final Color _cardNavy = const Color(0xFF0F172A);
  final Color _textGrey = const Color(0xFF6B7280);
  final Color _dangerRed = const Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    flags = context.read<TechnicalFlags>();

    _mapInitMachine.addListener(() {
      if (!mounted) return;
      if (_isJourneyActive) return;
      final state = _mapInitMachine.value;

      if (state is MapInitProcessing) {
        _distanceDisplay.value = state.statusMessage;
      } else if (state is MapInitReady) {
        _distanceDisplay.value = state.displayMessage;
        if (state.finalUserLocation != null) {
          setState(() {
            _currentUserLocation = state.finalUserLocation;
          });
        }
      }
    });

    _journeyStartMachine.addListener(() {
      final state = _journeyStartMachine.value;
      if (!mounted) return;
      if (state is JourneyStartProcessing) {
        _distanceDisplay.value = state.message;
      } else if (state is JourneyStartFailure) {
        _showError(state.error);
        setState(() => _isJourneyActive = false);
      } else if (state is JourneyStartSuccess) {
        _handleJourneyStartSuccess(state);
      }
    });

    final modeController = AppKernel.instance.feature<JourneyModeController>();
    if (widget.initialJourneyData != null) {
      _processInitialDataSynchronously(widget.initialJourneyData!);
    } else {
      _journeyMode = modeController.defaultMode(hasPjp: false).mode;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Radar.setUserId(widget.employee.id);
      Radar.setDescription(widget.employee.displayName);
      if (flags.journeyNotifications) {
        try {
          await AppKernel.instance
              .feature<JourneyTrackingController>()
              .initNotifications();
        } catch (_) {}
      }
      _checkActiveSession();
    });

    if (flags.journeyMap) {
      _styleFuture = _readStyle();
    }
  }

  void _onDistanceUpdate(double dist) {
    if (mounted) {
      _distanceDisplay.value = "${(dist / 1000.0).toStringAsFixed(2)} km";
    }
  }

  // 🚀 HARDWARE ACCELERATED & FILTERED DISTANCE
  void _onLocationUpdate(LatLng latLng) {
    if (_lastRecordedLocation != null) {
      final dist = Geolocator.distanceBetween(
        _lastRecordedLocation!.latitude,
        _lastRecordedLocation!.longitude,
        latLng.latitude,
        latLng.longitude,
      );

      // 🚀 GPS JITTER FILTER: Ignore tiny jumps < 0.5 meters to save cycles
      if (dist > 0.5) {
        _totalDistanceTravelled += dist;
      }
    }

    _lastRecordedLocation = latLng;
    _currentUserLocation = latLng;
    _routeTaken.add(latLng);

    // 🚀 BYPASSED: Manual Dart rendering removed! The map draws the blue dot natively at 60fps!
    // _drawUserLocationPointer(latLng);

    if (_canUpdatePolyline()) {
      _updateTravelledPolyline();
    }
  }

  Future<void> _checkActiveSession() async {
    if (_restoreChecked) return;
    _restoreChecked = true;

    final restoreMachine = RestoreJourneyStateMachine();

    restoreMachine.addListener(() {
      final state = restoreMachine.value;
      if (state is RestoreResumed) {
        _handleRestoreSuccess(state.snapshot);
      }
    });

    await restoreMachine.dispatch(
      RestoreJourneyIntent(
        askUser: _askUserToResume,
        trackingController: AppKernel.instance
            .feature<JourneyTrackingController>(),
        db: AppDatabase.instance,
      ),
    );
  }

  void _handleRestoreSuccess(JourneyRestoreSnapshot snapshot) async {
    setState(() {
      _isJourneyActive = true;
      _currentGeoTrackingDbId = snapshot.journeyId;
      _destinationController.text = snapshot.displayName ?? "Resumed Journey";
      _totalDistanceTravelled = snapshot.distance;
      _currentUserLocation = snapshot.lastPosition;
      _routeTaken.clear();
      _routeTaken.addAll(snapshot.path);
      _lastRecordedLocation = snapshot.lastPosition;
      _journeyMode = JourneyMode.planned;
      _isMapTrackingUser = true; // 🚀 Restore tracking
    });

    _distanceDisplay.value =
        "${(snapshot.distance / 1000.0).toStringAsFixed(2)} km";

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

    final tracking = AppKernel.instance.feature<JourneyTrackingController>();

    _distanceSub = tracking.distanceStream.listen(_onDistanceUpdate);
    _posSub = tracking.positionStream.listen(_onLocationUpdate);

    _eventSub = tracking.eventStream.listen((event) {
      if (event == JourneyTrackingEvent.arrived && !_hasArrived) {
        _hasArrived = true;
        _showArrivalDialog();
      }
    });
  }

  Future<bool> _askUserToResume(JourneyRestoreSnapshot snapshot) async {
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
              "You were travelling to ${snapshot.displayName}. Continue?",
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

  void _handleJourneyStartSuccess(JourneyStartSuccess state) {
    setState(() {
      _currentPjp = state.pjp;
      _currentGeoTrackingDbId = state.geoTrackingDbId;
      _isJourneyActive = true;
      _routeTaken.clear();
      _hasArrived = false;
      _totalDistanceTravelled = 0.0;
      _lastRecordedLocation = null;
      _isMapTrackingUser = true; // 🚀 Start tracking instantly
    });

    _distanceDisplay.value = "0.00 km";

    final tracking = AppKernel.instance.feature<JourneyTrackingController>();

    _distanceSub = tracking.distanceStream.listen(_onDistanceUpdate);
    _posSub = tracking.positionStream.listen(_onLocationUpdate);

    _eventSub = tracking.eventStream.listen((event) {
      if (event == JourneyTrackingEvent.arrived && !_hasArrived) {
        _hasArrived = true;
        _showArrivalDialog();
      }
    });
  }

  void _resetScreenState() async {
    setState(() {
      _isJourneyActive = false;
      _currentPjp = null;
      _destinationLocation = null;
      _backupPlannedPjp = null;
      _backupDestination = null;
      _currentGeoTrackingDbId = null;
      _totalDistanceTravelled = 0.0;
      _lastRecordedLocation = null;
      _hasArrived = false;
      _isMapTrackingUser = true;

      _destinationController.clear();

      final modeController = AppKernel.instance
          .feature<JourneyModeController>();
      _journeyMode = modeController.defaultMode(hasPjp: false).mode;
      _isSelectionMode = false;

      _routeTaken.clear();
    });

    _distanceDisplay.value = "Select Destination";

    await _removeRouteLine();
    await _removeDestinationMarker();
    await _determinePositionAndMoveCamera();
  }

  @override
  void didUpdateWidget(TechnicalJourneyScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialJourneyData != null &&
        widget.initialJourneyData != oldWidget.initialJourneyData) {
      _processNewJourneyData(widget.initialJourneyData!);
      widget.onDestinationConsumed?.call();
    }
  }

  void _processInitialDataSynchronously(Map<String, dynamic> data) {
    _journeyMode = JourneyMode.planned;
    _currentPjp = data['pjp'];
    _destinationLocation = data['destination'];
    _destinationController.text = data['displayName'] ?? "";
    _isSiteVisit = data['isSite'] ?? true;
    _distanceDisplay.value = "Loading Map...";
  }

  @override
  void dispose() {
    _cancelJourneySubscriptions();
    _destinationController.dispose();
    _searchController.dispose();
    _distanceDisplay.dispose();
    super.dispose();
  }

  void _onMapStyleLoaded() {
    final intent = MapStyleLoadedIntent(
      isMapEnabled: flags.journeyMap,
      destination: _destinationLocation,
      currentUserLocation: _currentUserLocation,
      onDestinationConsumed: widget.onDestinationConsumed,
      drawMarker: (pos) => _addDestinationMarker(pos),
      determinePosition: () async {
        await _determinePositionAndMoveCamera();
        return _currentUserLocation;
      },
      drawRoute: (start, end) => _getDirectionsAndDrawRoute(),
      fitBounds: () => _fitBounds(),
    );
    _mapInitMachine.dispatch(intent);
  }

  void _processNewJourneyData(Map<String, dynamic> journeyData) async {
    final Pjp? pjp = journeyData['pjp'] as Pjp?;
    final LatLng? destination = journeyData['destination'] as LatLng?;
    final String? displayName = journeyData['displayName'] as String?;
    final bool isSite = journeyData['isSite'] ?? true;

    if (mounted) {
      setState(() {
        _journeyMode = JourneyMode.planned;
        _currentPjp = pjp;
        _isSiteVisit = isSite;
        _destinationLocation = destination;
        _destinationController.text = displayName ?? "";
      });
      _distanceDisplay.value = "Calculating Route...";
    }

    _routeTaken.clear();
    await _removeRouteLine();
    if (destination != null) {
      _addDestinationMarker(destination);
    }
    if (_currentUserLocation == null) {
      await _determinePositionAndMoveCamera();
    }
    if (_destinationLocation != null && _currentUserLocation != null) {
      await _getDirectionsAndDrawRoute();
      _fitBounds();
    }
    if (mounted) {
      _distanceDisplay.value = "Ready to start";
    }
  }

  void _toggleJourneyMode() async {
    final modeController = AppKernel.instance.feature<JourneyModeController>();

    setState(() {
      _journeyMode = modeController.switchMode(_journeyMode).mode;
    });

    if (_journeyMode == JourneyMode.unplanned) {
      if (_currentPjp != null) {
        _backupPlannedPjp = _currentPjp;
        _backupDestination = _destinationLocation;
      }
      setState(() {
        _currentPjp = null;
        _destinationLocation = null;
        _destinationController.text = "";
      });
      _distanceDisplay.value = "Select Destination";
      await _removeRouteLine();
      await _removeDestinationMarker();
    } else {
      if (_backupPlannedPjp != null) {
        setState(() {
          _currentPjp = _backupPlannedPjp;
          _destinationLocation = _backupDestination;
          _destinationController.text = _resolveName(_currentPjp!);
        });
        if (_destinationLocation != null) {
          _addDestinationMarker(_destinationLocation!);
          _getDirectionsAndDrawRoute();
        }
      }
    }
  }

  Future<void> _loadUnplannedJourney(UnplannedJourneyResult result) async {
    setState(() {
      _journeyMode = JourneyMode.unplanned;
      _destinationLocation = result.destination;
      _destinationController.text = result.displayName;
      _isSiteVisit = result.type == UnplannedEntityType.site;
      _currentPjp = null;
    });

    _distanceDisplay.value = "Calculating Route...";
    await _addDestinationMarker(result.destination);

    try {
      if (_currentUserLocation == null) {
        await _determinePositionAndMoveCamera();
      }

      if (_currentUserLocation != null) {
        if (_radarApiKey != null) {
          await _getDirectionsAndDrawRoute();
        }
        _fitBounds();
      }
    } catch (_) {
    } finally {
      if (mounted) {
        _distanceDisplay.value = "Ready to start";
      }
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isSearching = true);
    final LatLng? result = await _mapSelectionController.searchLocation(query);
    if (result != null) {
      final controller = await _controllerCompleter.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(result, 16));
    } else {
      _showError("Location not found");
    }
    if (mounted) setState(() => _isSearching = false);
  }

  Future<void> _startJourney() async {
    final hasPermission = await _ensureJourneyPermission();
    if (!hasPermission) return;

    if (_isJourneyActive || _destinationLocation == null) {
      _showError("Cannot start: No destination selected.");
      return;
    }

    setState(() {
      _isJourneyActive = true;
    });
    _distanceDisplay.value = "Starting...";

    _journeyStartMachine.dispatch(
      StartJourneyIntent(
        employee: widget.employee,
        destinationLocation: _destinationLocation,
        destinationName: _destinationController.text,
        isSiteVisit: _isSiteVisit,
        journeyMode: _journeyMode,
        currentPjp: _currentPjp,
        currentUserLocation: _currentUserLocation,
        trackingController: AppKernel.instance
            .feature<JourneyTrackingController>(),
        apiService: ApiService(),
      ),
    );
  }

  Future<void> _stopJourney() async {
    if (!_isJourneyActive) return;

    _distanceDisplay.value = "Stopping...";

    await _journeyStopMachine.dispatch(
      StopJourneyIntent(
        userId: int.parse(widget.employee.id),
        geoTrackingDbId: _currentGeoTrackingDbId,
        currentUserLocation: _currentUserLocation,
        totalDistanceTravelled: _totalDistanceTravelled,
        onCleanup: () => _handleJourneyCleanup(),
        apiService: ApiService(),
        trackingController: AppKernel.instance
            .feature<JourneyTrackingController>(),
      ),
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

  Future<void> _getDirectionsAndDrawRoute() async {
    if (_currentUserLocation == null || _destinationLocation == null) return;
    if (_radarApiKey == null) return;

    final controller = await _controllerCompleter.future;

    await JourneyMapRenderer.drawRoute(
      controller: controller,
      start: _currentUserLocation!,
      end: _destinationLocation!,
      apiKey: _radarApiKey,
    );
  }

  Future<bool> _ensureJourneyPermission() async {
    return await JourneyPermissionGuard.ensurePermissions(
      onShowDisclosure: () async {
        if (!mounted) return false;
        return await _showJourneyDisclosureDialog();
      },
      onShowSettings: () {
        if (mounted) _showSettingsDialog();
      },
      onError: (message) {
        _showError(message);
      },
    );
  }

  Future<bool> _showJourneyDisclosureDialog() async {
    return await JourneyDialogs.showDisclosure(
      context: context,
      primaryColor: _cardNavy,
    );
  }

  void _showSettingsDialog() {
    JourneyDialogs.showSettings(context);
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

        if (mounted && !_isJourneyActive) {
          if (_distanceDisplay.value.contains("Waiting") ||
              _distanceDisplay.value.contains("Map")) {
            _distanceDisplay.value = "My Location";
          }
        }

        final controller = await _controllerCompleter.future;

        if (_destinationLocation == null) {
          await controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: _currentUserLocation!, zoom: 15.0),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("❌ _determinePositionAndMoveCamera Exception: $e");
    }
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

  Future<void> _addDestinationMarker(LatLng point) async {
    final controller = await _controllerCompleter.future;
    await JourneyMapRenderer.addDestinationMarker(controller, point);
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

  void _handleJourneyCleanup() async {
    _cancelJourneySubscriptions();
    final checkInTime = DateTime.now();

    if (widget.onJourneyCompleted != null && _currentPjp != null) {
      widget.onJourneyCompleted!(
        _currentPjp!,
        _currentPjp,
        _isSiteVisit,
        checkInTime,
      );
    }

    if (mounted) {
      final modeController = AppKernel.instance
          .feature<JourneyModeController>();
      final defaultMode = modeController.defaultMode(hasPjp: false).mode;

      setState(() {
        _isJourneyActive = false;
        _currentPjp = null;
        _destinationLocation = null;
        _backupPlannedPjp = null;
        _backupDestination = null;
        _currentGeoTrackingDbId = null;
        _totalDistanceTravelled = 0.0;
        _lastRecordedLocation = null;
        _hasArrived = false;

        _destinationController.clear();
        _journeyMode = defaultMode;
        _isSelectionMode = false;

        _routeTaken.clear();
      });

      _distanceDisplay.value = "Select Destination";

      await _removeRouteLine();
      await _removeDestinationMarker();
      await _determinePositionAndMoveCamera();
    }
  }

  String _resolveName(Pjp pjp) {
    try {
      if (pjp.areaToBeVisited.contains('|')) {
        return pjp.areaToBeVisited.split('|').first;
      }
      return pjp.areaToBeVisited;
    } catch (_) {
      return "Planned Visit";
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
            Text('SITE REACHED'),
          ],
        ),
        content: const Text('You have arrived at your destination.'),
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
              _handleJourneyCleanup();
            },
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ).animate().scale(curve: Curves.easeOutBack, duration: 400.ms),
    );
  }

  Future<void> _updateTravelledPolyline() async {
    final controller = await _controllerCompleter.future;
    await JourneyMapRenderer.updateTravelledPath(controller, _routeTaken);
  }

  Future<String> _resolveAddress(LatLng pos) async {
    try {
      final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (marks.isNotEmpty) {
        final p = marks.first;
        return "${p.subLocality ?? p.name}, ${p.locality}";
      }
    } catch (_) {}
    return "Selected Location";
  }

  Future<void> _confirmSelection() async {
    // 1. Instant feedback
    _distanceDisplay.value = "Processing...";

    try {
      final controller = await _controllerCompleter.future;
      final LatLng? target = controller.cameraPosition?.target;

      // 2. Prevent the silent failure!
      if (target == null) {
        _distanceDisplay.value = "Select Destination";
        _showError(
          "Map center not detected. Please move the map slightly and try again.",
        );
        return;
      }

      // 3. 🚀 PERCEIVED PERFORMANCE: Close the search UI immediately
      // BEFORE making the network call to reverse-geocode. Makes the app feel 10x faster.
      setState(() {
        _isSelectionMode = false;
        _searchController.clear();
      });

      // 4. 🚀 BATTERY/TIME EFFICIENCY: Wrap the geocoder in a timeout.
      // If the user has a spotty 4G connection, we don't want the app hanging forever.
      final String address = await _resolveAddress(target).timeout(
        const Duration(seconds: 4),
        onTimeout: () => "Selected Location", // Fallback if API takes too long
      );

      // 5. Load the journey
      await _loadUnplannedJourney(
        UnplannedJourneyResult(
          destination: target,
          displayName: address,
          type: UnplannedEntityType.site,
        ),
      );
    } catch (e) {
      debugPrint("Confirm Selection Error: $e");
      // Safety net: Revert UI if the entire process crashes
      if (mounted) {
        setState(() => _isSelectionMode = true);
      }
      _distanceDisplay.value = "Selection Failed";
      _showError("Failed to confirm location. Please try again.");
    }
  }

  Future<String> _readStyle() async {
    final style = AppKernel.instance.feature<JourneyMapStyleController>();
    final result = style.loadStyle(_stadiaApiKey!);
    return result.styleJson;
  }

  void _launchGoogleMapsNavigation() async {
    if (_destinationLocation == null) return;
    try {
      final nav = AppKernel.instance.feature<JourneyNavigationController>();
      await nav.launchGoogleMaps(_destinationLocation!);
    } catch (e) {
      debugPrint("Navigation Launch Error: $e");
      _showError("Could not launch Google Maps");
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: _dangerRed),
      );
    }
  }

  void _cancelJourneySubscriptions() {
    _distanceSub?.cancel();
    _posSub?.cancel();
    _eventSub?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final bool canStartJourney =
        !_isJourneyActive &&
        (_journeyMode == JourneyMode.planned ||
            (_journeyMode == JourneyMode.unplanned &&
                _destinationLocation != null));

    return Stack(
      children: [
        // 1. MAP BACKGROUND
        SizedBox.expand(
          child: FutureBuilder<String>(
            future: _styleFuture,
            builder: (ctx, snap) {
              if (!snap.hasData) return Container(color: _bgLight);
              return MapLibreMap(
                styleString: snap.data!,
                initialCameraPosition: _initialCameraPosition,
                trackCameraPosition: true,

                // 🚀 HARDWARE ACCELERATED 60FPS POINTER ANIMATION (Restored from File 1)
                myLocationEnabled: true,
                myLocationTrackingMode: _isMapTrackingUser
                    ? MyLocationTrackingMode.tracking
                    : MyLocationTrackingMode.none,
                myLocationRenderMode: MyLocationRenderMode.compass,
                onCameraTrackingDismissed: () {
                  if (_isMapTrackingUser && mounted) {
                    setState(() => _isMapTrackingUser = false);
                  }
                },

                onMapCreated: (c) {
                  if (!_controllerCompleter.isCompleted) {
                    _controllerCompleter.complete(c);
                  }
                },
                onStyleLoadedCallback: _onMapStyleLoaded,
              ).animate().fadeIn(duration: 800.ms);
            },
          ),
        ),

        // 2. SEARCH MODE UI
        if (_isSelectionMode) ...[
          Positioned(
                top: 50,
                left: 16,
                right: 16,
                child: Card(
                  elevation: 4,
                  shadowColor: Colors.black.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _performSearch,
                    decoration: InputDecoration(
                      hintText: "Search area (e.g., Guwahati)",
                      hintStyle: const TextStyle(color: Color(0xFF64748B)),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFF0F172A),
                        ),
                        onPressed: () {
                          setState(() {
                            _isSelectionMode = false;
                            _searchController.clear();
                          });
                        },
                      ),
                      suffixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              icon: const Icon(
                                Icons.search,
                                color: Color(0xFF0F172A),
                              ),
                              onPressed: () =>
                                  _performSearch(_searchController.text),
                            ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              )
              .animate()
              .slideY(begin: -0.2, duration: 400.ms, curve: Curves.easeOutCubic)
              .fadeIn(),

          Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 35),
                  child: Icon(Icons.location_on, size: 50, color: _cardNavy),
                ),
              )
              .animate()
              .moveY(
                begin: -40,
                end: 0,
                duration: 800.ms,
                curve: Curves.bounceOut,
              )
              .fadeIn(duration: 400.ms),

          Positioned(
                bottom: 120,
                left: 20,
                right: 20,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _cardNavy,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                  ),
                  onPressed: _confirmSelection,
                  child: const Text(
                    "CONFIRM THIS LOCATION",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              )
              .animate()
              .slideY(begin: 0.2, duration: 400.ms, curve: Curves.easeOutCubic)
              .fadeIn(),
        ],

        // 3. 🚀 THE ZOMATO-STYLE OVERLAY MANAGER
        if (!_isSelectionMode) ...[
          // Recenter Button
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
                    // 🚀 Restored Toggle State
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
                      } else {
                        await _determinePositionAndMoveCamera();
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
              child: ValueListenableBuilder<String>(
                valueListenable: _distanceDisplay,
                builder: (context, distanceText, child) {
                  return JourneyOverlayManager(
                    isJourneyActive: _isJourneyActive,
                    distance: distanceText,
                    onStop: () async => await _stopJourney(),
                    onNavigate: _launchGoogleMapsNavigation,
                    idlePanel:
                        Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildIdleJourneyPanel(context),
                                const SizedBox(height: 24),
                                _StartJourneySlider(
                                  key: ValueKey(_isJourneyActive),
                                  isJourneyActive: false,
                                  onSlideAction: _startJourney,
                                  canStart: canStartJourney,
                                  cardNavy: _cardNavy,
                                  dangerRed: _dangerRed,
                                ),
                                const SizedBox(height: 90),
                              ],
                            )
                            .animate()
                            .slideY(
                              begin: 0.2,
                              duration: 500.ms,
                              curve: Curves.easeOutCubic,
                            )
                            .fadeIn(),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildIdleJourneyPanel(BuildContext context) {
    final modeController = AppKernel.instance.feature<JourneyModeController>();
    final bool canSwitch = modeController.caps.allowUnplanned;
    final bool isPlanned = _journeyMode == JourneyMode.planned;

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
                isPlanned ? Icons.map_outlined : Icons.business,
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
                    isPlanned ? "PLANNED AREA" : "UNPLANNED VISIT",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: _cardNavy,
                      fontSize: 13,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    isPlanned
                        ? "Free roam • Multiple check-ins"
                        : "Flexible destination • Ad-hoc",
                    style: TextStyle(
                      color: _textGrey,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (canSwitch)
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
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 4),
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
          child: Center(
            child: TextField(
              controller: _destinationController,
              readOnly: true,
              // 🚀 NEW: Make the entire text box clickable in Unplanned mode
              onTap: !isPlanned && _destinationController.text.isEmpty
                  ? () async {
                      setState(() {
                        _isSelectionMode = true;
                      });
                      if (_currentUserLocation != null) {
                        try {
                          final controller = await _controllerCompleter.future;
                          controller.animateCamera(
                            CameraUpdate.newLatLngZoom(
                              _currentUserLocation!,
                              16,
                            ),
                          );
                        } catch (_) {}
                      }
                    }
                  : null,
              style: TextStyle(
                color: _destinationController.text.isEmpty
                    ? _textGrey
                    : _cardNavy,
                fontWeight: _destinationController.text.isEmpty
                    ? FontWeight.w500
                    : FontWeight.w800,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  isPlanned ? Icons.explore_rounded : Icons.search_rounded,
                  color: _cardNavy,
                  size: 24,
                ),
                // 🚀 NEW: Updated the hint text to be more actionable
                hintText: isPlanned
                    ? "Planned Area"
                    : "Tap to set destination...",
                hintStyle: const TextStyle(color: Color(0xFF64748B)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                // 🚀 NEW: Replaces the old bottom button with an embedded "SET" button
                suffixIcon: _destinationController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.refresh_rounded, color: _dangerRed),
                        tooltip: "Reset Screen",
                        onPressed: _resetScreenState,
                      )
                    : (!isPlanned
                          ? Padding(
                              padding: const EdgeInsets.only(
                                right: 8.0,
                                top: 10.0,
                                bottom: 10.0,
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _cardNavy,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () async {
                                  setState(() {
                                    _isSelectionMode = true;
                                  });
                                  if (_currentUserLocation != null) {
                                    try {
                                      final controller =
                                          await _controllerCompleter.future;
                                      controller.animateCamera(
                                        CameraUpdate.newLatLngZoom(
                                          _currentUserLocation!,
                                          16,
                                        ),
                                      );
                                    } catch (_) {}
                                  }
                                },
                                child: const Text(
                                  "SET",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            )
                          : null),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

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
