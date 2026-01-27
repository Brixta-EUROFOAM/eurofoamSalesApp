import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_radar/flutter_radar.dart';
import 'package:geocoding/geocoding.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
// Core & Models
import 'package:salesmanapp/core/feature_flags/technical_flags.dart';
import 'package:salesmanapp/core/app_kernel.dart';
import 'package:salesmanapp/models/employee_model.dart';
import 'package:salesmanapp/models/pjp_model.dart';
import 'package:salesmanapp/api/api_service.dart';
// Features
import 'package:salesmanapp/features/mapselectionpjp/map_selection_controller.dart';
import 'package:salesmanapp/features/mapselectionpjp/map_selection_result.dart';
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


// --- 🚀 NEW UI IMPORTS ---
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
  // UI State
  String _distanceDisplay = "Initializing...";
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
    debugPrint("🚀 [TechnicalJourneyScreen] initState called");
    flags = context.read<TechnicalFlags>();
    _mapInitMachine.addListener(() {
      if (!mounted) return;
      if (_isJourneyActive) return;
      final state = _mapInitMachine.value;
      setState(() {
        if (state is MapInitProcessing) {
          _distanceDisplay = state.statusMessage;
        } else if (state is MapInitReady) {
          _distanceDisplay = state.displayMessage;
          if (state.finalUserLocation != null) {
            _currentUserLocation = state.finalUserLocation;
          }
        }
      });
    });
    _journeyStartMachine.addListener(() {
      final state = _journeyStartMachine.value;
      if (!mounted) return;
      if (state is JourneyStartProcessing) {
        setState(() => _distanceDisplay = state.message);
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
      setState(() {
        _distanceDisplay = "${(dist / 1000.0).toStringAsFixed(2)} km";
      });
    }
  }

  void _onLocationUpdate(LatLng latLng) {
    if (_lastRecordedLocation != null) {
      final dist = Geolocator.distanceBetween(
        _lastRecordedLocation!.latitude,
        _lastRecordedLocation!.longitude,
        latLng.latitude,
        latLng.longitude,
      );
      _totalDistanceTravelled += dist;
    }
    _lastRecordedLocation = latLng;
    _currentUserLocation = latLng;

    _routeTaken.add(latLng);
    _drawUserLocationPointer(latLng);

    if (_canUpdatePolyline()) {
      _updateTravelledPolyline();
    }
  }

  Future<void> _checkActiveSession() async {
    if (_restoreChecked) return;
    _restoreChecked = true;

    final restoreMachine = RestoreJourneyStateMachine();

    // 1. Listen for the Result
    restoreMachine.addListener(() {
      final state = restoreMachine.value;
      if (state is RestoreResumed) {
        _handleRestoreSuccess(state.snapshot);
      }
    });

    // 2. Dispatch Intent with Tools
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
    // 1. Restore UI State
    setState(() {
      _isJourneyActive = true;
      _currentGeoTrackingDbId = snapshot.journeyId;
      _destinationController.text = snapshot.displayName ?? "Resumed Journey";

      // 🔥 FIX: Overwrite "Location Found" immediately
      _distanceDisplay =
          "${(snapshot.distance / 1000.0).toStringAsFixed(2)} km";

      _totalDistanceTravelled = snapshot.distance;
      _currentUserLocation = snapshot.lastPosition;

      // 🔥 FIX: Restore path history
      _routeTaken.clear();
      _routeTaken.addAll(snapshot.path);
      _lastRecordedLocation = snapshot.lastPosition;

      // 🔥 FIX: Ensure UI shows active panel
      _journeyMode = JourneyMode.planned;
    });

    // 2. Restore Map Visuals
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

    // 3. Re-attach Streams (USING THE DEFINED HELPERS)
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
            title: const Text("Resume journey?"),
            content: Text(
              "You were travelling to ${snapshot.displayName}. Continue?",
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

  void _handleJourneyStartSuccess(JourneyStartSuccess state) {
    setState(() {
      _currentPjp = state.pjp;
      _currentGeoTrackingDbId = state.geoTrackingDbId;
      _isJourneyActive = true;
      _distanceDisplay = "0.00 km";
      _routeTaken.clear();
      _hasArrived = false;
      _totalDistanceTravelled = 0.0;
      _lastRecordedLocation = null;
    });

    // 👇 START STREAMS (Moved from the old method)
    final tracking = AppKernel.instance.feature<JourneyTrackingController>();

    _distanceSub = tracking.distanceStream.listen((dist) {
      if (mounted) {
        setState(
          () => _distanceDisplay = "${(dist / 1000.0).toStringAsFixed(2)} km",
        );
      }
    });

    _posSub = tracking.positionStream.listen((latLng) {
      if (_lastRecordedLocation != null) {
        final dist = Geolocator.distanceBetween(
          _lastRecordedLocation!.latitude,
          _lastRecordedLocation!.longitude,
          latLng.latitude,
          latLng.longitude,
        );
        _totalDistanceTravelled += dist;
      }
      _lastRecordedLocation = latLng;
      _currentUserLocation = latLng;

      _routeTaken.add(latLng);
      _drawUserLocationPointer(latLng);
      if (_canUpdatePolyline()) {
        _updateTravelledPolyline();
      }
    });

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

      _destinationController.clear();
      _distanceDisplay = "Select Destination";

      final modeController = AppKernel.instance
          .feature<JourneyModeController>();
      _journeyMode = modeController.defaultMode(hasPjp: false).mode;
      _isSelectionMode = false;

      _routeTaken.clear();
    });

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
    _distanceDisplay = "Loading Map...";
  }

  @override
  void dispose() {
    _cancelJourneySubscriptions();
    _destinationController.dispose();
    _searchController.dispose();
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
        _distanceDisplay = "Calculating Route...";
      });
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
      setState(() => _distanceDisplay = "Ready to start");
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
        _distanceDisplay = "Select Destination";
      });
      await _removeRouteLine();
      await _removeDestinationMarker(); // Remove pointer in unplanned mode initially
    } else {
      if (_backupPlannedPjp != null) {
        setState(() {
          _currentPjp = _backupPlannedPjp;
          _destinationLocation = _backupDestination;
          _destinationController.text = _resolveName(_currentPjp!);
        });
        if (_destinationLocation != null) {
          _addDestinationMarker(_destinationLocation!); // Restore pointer
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
      _distanceDisplay = "Calculating Route...";
    });

    // 🔥 Add pointer for unplanned destination
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
        setState(() {
          _distanceDisplay = "Ready to start";
        });
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
    // 1. Guard Layer (Permissions)
    final hasPermission = await _ensureJourneyPermission();
    if (!hasPermission) return;

    // 2. Validation
    if (_isJourneyActive || _destinationLocation == null) {
      _showError("Cannot start: No destination selected.");
      return;
    }

    // OPTIMISTIC UPDATE: Move UI to Active State Immediately
    // This destroys the green slider and builds the active panel instantly.
    setState(() {
      _isJourneyActive = true;
      _distanceDisplay = "Starting...";
    });

    // 3. Dispatch Intent to the Brain
    _journeyStartMachine.dispatch(
      StartJourneyIntent(
        employee: widget.employee,
        destinationLocation: _destinationLocation,
        destinationName: _destinationController.text,
        isSiteVisit: _isSiteVisit,
        journeyMode: _journeyMode,
        currentPjp: _currentPjp,
        currentUserLocation: _currentUserLocation,
        // Inject dependencies
        trackingController: AppKernel.instance
            .feature<JourneyTrackingController>(),
        apiService: ApiService(),
      ),
    );
  }

  Future<void> _stopJourney() async {
    if (!_isJourneyActive) return;

    // OPTIMISTIC UPDATE: Show feedback immediately
    setState(() {
      _distanceDisplay = "Stopping...";
    });

    // Dispatch the Stop Intent to the Brain
    await _journeyStopMachine.dispatch(
      StopJourneyIntent(
        userId: int.parse(widget.employee.id),
        geoTrackingDbId: _currentGeoTrackingDbId,
        currentUserLocation: _currentUserLocation,
        totalDistanceTravelled: _totalDistanceTravelled,
        // What to do when the logic finishes (Success or Fail)
        onCleanup: () => _handleJourneyCleanup(),
        // Inject Dependencies
        apiService: ApiService(),
        trackingController: AppKernel.instance
            .feature<JourneyTrackingController>(),
      ),
    );
  }

  // ✅ CRASH PROOF FIX: Separate Try/Catch blocks
  Future<void> _removeRouteLine() async {
    if (!_isRouteLineLayerAdded) return;
    final controller = await _controllerCompleter.future;

    // 1. Try remove layer
    try {
      await controller.removeLayer('route-line');
    } catch (_) {}

    // 2. Try remove source INDEPENDENTLY
    try {
      await controller.removeSource('route-source');
    } catch (_) {}

    _isRouteLineLayerAdded = false;
  }

  // ✅ CRASH PROOF FIX: Safe Update Logic
  Future<void> _getDirectionsAndDrawRoute() async {
    // 1. Validate Data
    if (_currentUserLocation == null || _destinationLocation == null) return;
    if (_radarApiKey == null) return;

    // 2. Get Controller
    final controller = await _controllerCompleter.future;

    // 3. Delegate the work to the Renderer (The Hands)
    await JourneyMapRenderer.drawRoute(
      controller: controller,
      start: _currentUserLocation!,
      end: _destinationLocation!,
      apiKey: _radarApiKey,
    );

    // 4. Update UI (Only if you need to trigger a rebuild for other widgets)
    if (mounted) setState(() {});
  }

  Future<bool> _ensureJourneyPermission() async {
    // Delegate to the Guard Layer
    return await JourneyPermissionGuard.ensurePermissions(
      // Callback 1: How do we ask the user for consent?
      onShowDisclosure: () async {
        if (!mounted) return false;
        return await _showJourneyDisclosureDialog();
      },

      // Callback 2: How do we direct them to settings?
      onShowSettings: () {
        if (mounted) _showSettingsDialog();
      },

      // Callback 3: How do we show errors?
      onError: (message) {
        _showError(message);
      },
    );
  }

  Future<bool> _showJourneyDisclosureDialog() async {
    return await JourneyDialogs.showDisclosure(
      context: context,
      primaryColor: _cardNavy, // Or whatever color variable you use
    );
  }

  void _showSettingsDialog() {
    JourneyDialogs.showSettings(context);
  }

  Future<void> _determinePositionAndMoveCamera() async {
    try {
      // 1. Ask LOGIC LAYER to get the location
      //    (It internally handles Permissions, Guard checks, and AppKernel fetching)
      final location = await JourneyLocationLogic.resolveCurrentLocation(
        // Pass your permission wrapper
        onEnsurePermissions: _ensureJourneyPermission,

        // Pass the AppKernel fetcher
        onFetchLocationFromController: () async {
          return await AppKernel.instance
              .feature<JourneyLocationController>()
              .resolveCurrentLocation();
        },
      );

      // 2. If valid location returned, update UI and Map
      if (location != null) {
        _currentUserLocation = location;

        // Update UI Text
        if (mounted && !_isJourneyActive) {
          if (_distanceDisplay.contains("Waiting") ||
              _distanceDisplay.contains("Map")) {
            setState(() => _distanceDisplay = "My Location");
          }
        }

        final controller = await _controllerCompleter.future;

        // Move Camera (only if destination isn't set yet)
        if (_destinationLocation == null) {
          await controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: _currentUserLocation!, zoom: 15.0),
            ),
          );
        }

        // 3. Ask RENDERER LAYER to draw the Blue Dot
        await JourneyMapRenderer.drawUserLocationPointer(
          controller,
          _currentUserLocation!,
        );
      }
    } catch (e) {
      debugPrint("❌ _determinePositionAndMoveCamera Exception: $e");
    }
  }

  Future<void> _fitBounds() async {
    if (_currentUserLocation == null || _destinationLocation == null) return;

    // 1. Get Controller
    final controller = await _controllerCompleter.future;

    // 2. Delegate to Renderer
    await JourneyMapRenderer.fitBounds(
      controller,
      _currentUserLocation!,
      _destinationLocation!,
    );
  }

  Future<void> _addDestinationMarker(LatLng point) async {
    // 1. Get the controller
    final controller = await _controllerCompleter.future;

    // 2. Let the Renderer handle the dirty work
    await JourneyMapRenderer.addDestinationMarker(controller, point);
  }

  // ✅ CRASH PROOF FIX: Separate Try/Catch blocks to prevent Zombie Sources
  Future<void> _removeDestinationMarker() async {
    final controller = await _controllerCompleter.future;

    // 1. Try Remove Inner Layer
    try {
      await controller.removeLayer('dest-layer-inner');
    } catch (_) {}

    // 2. Try Remove Outer Layer
    try {
      await controller.removeLayer('dest-layer-outer');
    } catch (_) {}

    // 3. Try Remove Source INDEPENDENTLY
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
        _distanceDisplay = "Select Destination";
        _journeyMode = defaultMode;
        _isSelectionMode = false;

        _routeTaken.clear();
      });

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
        title: const Text('SITE REACHED'),
        content: const Text('You have arrived at your destination.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleJourneyCleanup();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _drawUserLocationPointer(LatLng point) async {
    // 1. Get Controller
    final controller = await _controllerCompleter.future;

    // 2. Delegate to Renderer
    await JourneyMapRenderer.drawUserLocationPointer(controller, point);
  }

  Future<void> _updateTravelledPolyline() async {
    // 1. Get Controller
    final controller = await _controllerCompleter.future;

    // 2. Delegate to Renderer
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
    setState(() => _distanceDisplay = "Processing...");
    try {
      final controller = await _controllerCompleter.future;
      final target = controller.cameraPosition?.target;
      if (target == null) return;
      final address = await _resolveAddress(target);
      final selection = MapSelectionResult(
        position: target,
        address: address,
        isCancelled: false,
      );
      setState(() {
        _isSelectionMode = false;
        _searchController.clear();
      });
      await _loadUnplannedJourney(
        UnplannedJourneyResult(
          destination: selection.position,
          displayName: selection.address,
          type: UnplannedEntityType.site,
        ),
      );
    } catch (e) {
      setState(() {
        _isSelectionMode = false;
        _distanceDisplay = "Selection Failed";
      });
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
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
        // 1. MAP BACKGROUND (Unchanged)
        SizedBox.expand(
          child: FutureBuilder<String>(
            future: _styleFuture,
            builder: (ctx, snap) {
              if (!snap.hasData) return Container(color: _bgLight);
              return MapLibreMap(
                styleString: snap.data!,
                initialCameraPosition: _initialCameraPosition,
                onMapCreated: (c) {
                  if (!_controllerCompleter.isCompleted)
                    _controllerCompleter.complete(c);
                },
                onStyleLoadedCallback: _onMapStyleLoaded,
                trackCameraPosition: true,
                myLocationEnabled: false,
              );
            },
          ),
        ),

        // 2. SEARCH MODE UI (Unchanged)
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
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 35),
              child: Icon(Icons.location_on, size: 50, color: _cardNavy),
            ),
          ),
          Positioned(
            bottom: 40,
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
          ),
        ],

        // 3. 🚀 THE ZOMATO-STYLE OVERLAY MANAGER
        if (!_isSelectionMode) ...[
          // Recenter Button
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

          // The Manager
          Positioned.fill(
            child: SafeArea(
              child: JourneyOverlayManager(
                isJourneyActive: _isJourneyActive,
                distance: _distanceDisplay,
                
                // INTENT: STOP
                onStop: () async => await _stopJourney(),

                // INTENT: NAVIGATE
                onNavigate: _launchGoogleMapsNavigation,

                // IDLE UI
                idlePanel: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildIdleJourneyPanel(context),
                    const SizedBox(height: 24),
                    _StartJourneySlider(
                      key: ValueKey(_isJourneyActive),
                      isJourneyActive: false, // Always false here (idle mode)
                      onSlideAction: _startJourney,
                      canStart: canStartJourney,
                      cardNavy: _cardNavy,
                      dangerRed: _dangerRed,
                    ),
                  ],
                ),
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
            Icon(
              isPlanned ? Icons.map_outlined : Icons.business,
              color: _textGrey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPlanned ? "PLANNED AREA" : "UNPLANNED VISIT",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1E293B),
                      fontSize: 12,
                      letterSpacing: 1.1,
                    ),
                  ),
                  Text(
                    isPlanned
                        ? "Free roam • Multiple check-ins"
                        : "Flexible destination • Ad-hoc",
                    style: TextStyle(
                      color: _textGrey.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (canSwitch)
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
        // ✨ UPGRADED: Crisper Input Box
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white, // Crisp white
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)), // Subtle border
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
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  isPlanned ? Icons.explore : Icons.location_on_outlined,
                  color: Color(0xFF0F172A),
                ),
                hintText: isPlanned
                    ? "Planned Area"
                    : "Waiting for destination...",
                hintStyle: const TextStyle(color: Color(0xFF64748B)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                suffixIcon: _destinationController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.refresh_rounded, color: _dangerRed),
                        tooltip: "Reset Screen",
                        onPressed: _resetScreenState,
                      )
                    : null,
              ),
            ),
          ),
        ),
        if (!isPlanned)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text("SET DESTINATION"),
              style: OutlinedButton.styleFrom(
                foregroundColor: _cardNavy,
                side: BorderSide(color: _cardNavy),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: () async {
                setState(() {
                  _isSelectionMode = true;
                });
                if (_currentUserLocation != null) {
                  try {
                    final controller = await _controllerCompleter.future;
                    controller.animateCamera(
                      CameraUpdate.newLatLngZoom(_currentUserLocation!, 16),
                    );
                  } catch (_) {}
                }
              },
            ),
          ),
      ],
    );
  }
}

// ✨✨✨ THE UPGRADED 3D START SLIDER ✨✨✨
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
      // 🌟 PERFECTIONAL TOUCH: Floating Shadow
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
        // 🌟 COLORS & STYLE
        innerColor: Colors.white,
        outerColor: isEnabled ? cardNavy : const Color(0xFFF1F5F9),
        sliderButtonIcon: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF0F172A), size: 26),
        text: isEnabled ? 'SLIDE TO START VISIT' : 'SELECT DESTINATION FIRST',
        enabled: isEnabled,
        // 🌟 TYPOGRAPHY
        textStyle: TextStyle(
          color: isEnabled ? Colors.white : const Color(0xFF94A3B8),
          fontSize: 15, // Slightly larger
          fontWeight: FontWeight.w900, // Maximum bold
          letterSpacing: 1.5, // Wider spacing
        ),
        borderRadius: 24, // Matches container
        elevation: 0, // We handled shadow manually above
        height: 76, // Taller and more touch-friendly
        sliderRotate: false,
      ),
    );
  }
}