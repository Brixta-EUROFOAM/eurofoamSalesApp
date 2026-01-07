import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_radar/flutter_radar.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:polyline_codec/polyline_codec.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:salesmanapp/models/geotracking_data_model.dart';

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
import 'package:salesmanapp/features/journeylocation/journeylocation_results.dart';
import 'package:salesmanapp/features/journeyMapstyle/journeyMapstyle_controller.dart';

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

  // UI State
  String _distanceDisplay = "Initializing...";
  final _destinationController = TextEditingController();
  late JourneyMode _journeyMode;
  bool _isSelectionMode = false;

  final String? _stadiaApiKey = dotenv.env['STADIA_API_KEY'];
  final String? _radarApiKey = dotenv.env['RADAR_API_KEY'];
  Pjp? _backupPlannedPjp;
  LatLng? _backupDestination;

  // Journey State
  bool _isJourneyActive = false;

  // 🔒 Anti-Spam Flag
  bool _hasArrived = false;

  // Stream Subscriptions
  StreamSubscription? _distanceSub;
  StreamSubscription? _posSub;
  StreamSubscription? _eventSub;

  // Data Holding State
  Pjp? _currentPjp;
  bool _isSiteVisit = true;

  LatLng? _currentUserLocation;
  LatLng? _destinationLocation;
  final List<LatLng> _routeTaken = [];

  // Map State Flags
  bool _isUserLocationLayerAdded = false;
  bool _isRouteLineLayerAdded = false;
  bool _isTravelledLineLayerAdded = false;

  static const _initialCameraPosition = CameraPosition(
    target: LatLng(26.1445, 91.7362),
    zoom: 12,
  );

  // Theme
  final Color _bgLight = const Color(0xFFF3F4F6);
  final Color _cardNavy = const Color(0xFF0F172A);
  final Color _textDark = const Color(0xFF111827);
  final Color _textGrey = const Color(0xFF6B7280);
  final Color _surfaceWhite = Colors.white;
  final Color _dangerRed = const Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    debugPrint("🚀 [TechnicalJourneyScreen] initState called");
    flags = context.read<TechnicalFlags>();

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
    });

    if (flags.journeyMap) {
      _styleFuture = _readStyle();
    }
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

  void _onMapStyleLoaded() async {
    if (!flags.journeyMap) return;

    if (_destinationLocation != null) {
      // 🔥 Draw the pointer immediately on load
      _addDestinationMarker(_destinationLocation!);
    }

    await _determinePositionAndMoveCamera();

    if (_destinationLocation != null && _currentUserLocation != null) {
      await Future.delayed(const Duration(milliseconds: 100));
      await _getDirectionsAndDrawRoute();
      _fitBounds();

      if (mounted) setState(() => _distanceDisplay = "Ready to start");
    }

    widget.onDestinationConsumed?.call();
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

    // 🔥 Update the visual pointer when new data comes in
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
    final hasPermission = await _ensureJourneyPermission();
    if (!hasPermission) return;

    if (_isJourneyActive || _destinationLocation == null) {
      _showError("Cannot start: No destination selected.");
      return;
    }

    setState(() {
      _distanceDisplay = "Initializing...";
      _totalDistanceTravelled = 0.0;
      _lastRecordedLocation = null;
      _hasArrived = false;
    });

    try {
      final tracking = AppKernel.instance.feature<JourneyTrackingController>();
      final api = ApiService();

      if (_currentPjp == null && _journeyMode == JourneyMode.unplanned) {
        final employeeId = int.parse(widget.employee.id);
        final newPjp = Pjp(
          id: '',
          planDate: DateTime.now(),
          userId: employeeId,
          createdById: employeeId,
          status: 'APPROVED',
          verificationStatus: 'VERIFIED',
          areaToBeVisited:
              "${_destinationController.text}|${_destinationLocation!.latitude}|${_destinationLocation!.longitude}",
          route: _destinationController.text,
          description: "Unplanned / Ad-hoc Visit",
          plannedNewSiteVisits: 0,
          plannedFollowUpSiteVisits: 0,
          plannedNewDealerVisits: 0,
          plannedInfluencerVisits: 0,
          noOfConvertedBags: 0,
          noOfMasonPcSchemes: 0,
          activityType: 'Unplanned',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _currentPjp = await api.createPjp(newPjp);
      }

      if (_currentPjp == null) throw Exception("Failed to initialize visit");

      final startPoint = GeoTrackingPoint(
        userId: int.parse(widget.employee.id),
        journeyId:
            'JRN-${widget.employee.id}-${DateTime.now().millisecondsSinceEpoch}',
        latitude: _currentUserLocation?.latitude ?? 0.0,
        longitude: _currentUserLocation?.longitude ?? 0.0,
        destLat: _destinationLocation?.latitude,
        destLng: _destinationLocation?.longitude,
        siteId: _isSiteVisit ? _currentPjp?.siteId : null,
        dealerId: !_isSiteVisit ? _currentPjp?.dealerId : null,
        isActive: true,
        locationType: 'JOURNEY_START',
        totalDistanceTravelled: 0.0,
      );

      _currentGeoTrackingDbId = await api.sendGeoTrackingPoint(startPoint);

      if (_currentPjp?.id != null) {
        await api.updatePjp(_currentPjp!.id, {'status': 'IN_PROGRESS'});
      }

      await tracking.startJourney(
        pjp: _currentPjp!,
        userId: int.parse(widget.employee.id),
        destination: _destinationLocation!,
        isSite: _isSiteVisit,
      );

      setState(() {
        _isJourneyActive = true;
        _distanceDisplay = "0.00 km";
        _routeTaken.clear();
      });

      _distanceSub = tracking.distanceStream.listen((dist) {
        if (mounted)
          setState(
            () => _distanceDisplay = "${(dist / 1000.0).toStringAsFixed(2)} km",
          );
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
        _updateTravelledPolyline();
      });

      _eventSub = tracking.eventStream.listen((event) {
        if (event == JourneyTrackingEvent.arrived && !_hasArrived) {
          _hasArrived = true;
          _showArrivalDialog();
        }
      });
    } catch (e) {
      _showError("Failed to start: $e");
      setState(() => _isJourneyActive = false);
    }
  }

Future<void> _stopJourney() async {
    if (!_isJourneyActive) return;

    final api = ApiService();
    final checkInTime = DateTime.now();

    // 1. Close the GeoTracking Point (Keep this!)
    // This marks the end of THIS SPECIFIC trip/segment in the database.
    if (_currentGeoTrackingDbId != null && _currentUserLocation != null) {
      try {
        final updateData = {
          'isActive': false,
          'totalDistanceTravelled': (_totalDistanceTravelled / 1000.0)
              .toStringAsFixed(3),
          'latitude': _currentUserLocation!.latitude,
          'longitude': _currentUserLocation!.longitude,
          'locationType': 'JOURNEY_END',
          'checkOutTime': checkInTime.toIso8601String(),
        };

        await api.updateGeoTrackingPoint(_currentGeoTrackingDbId!, updateData);
      } catch (e) {
        debugPrint("⚠️ Failed to patch journey end: $e");
      }
    }

    // 🔴 CHANGE: Don't mark PJP as COMPLETED here. 
    // We want to allow multiple visits/journeys for the same PJP.
    /* if (_currentPjp?.id != null) {
      try {
        await api.updatePjp(_currentPjp!.id, {'status': 'COMPLETED'});
      } catch (_) {}
    } 
    */

    // 2. Stop local tracking service (Keep this!)
    try {
      final tracking = AppKernel.instance.feature<JourneyTrackingController>();
      await tracking.stopJourney();
    } catch (_) {}

    // 3. Reset UI
    _handleJourneyCleanup();
  }

  Future<void> _removeRouteLine() async {
    if (!_isRouteLineLayerAdded) return;
    final controller = await _controllerCompleter.future;
    try {
      await controller.removeLayer('route-line');
      await controller.removeSource('route-source');
      _isRouteLineLayerAdded = false;
    } catch (_) {}
  }

  Future<void> _getDirectionsAndDrawRoute() async {
    if (_currentUserLocation == null || _destinationLocation == null) return;
    if (_radarApiKey == null) return;

    try {
      final start =
          '${_currentUserLocation!.latitude},${_currentUserLocation!.longitude}';
      final end =
          '${_destinationLocation!.latitude},${_destinationLocation!.longitude}';
      final uri = Uri.parse(
        'https://api.radar.io/v1/route/directions?locations=$start|$end&mode=car&units=metric&geometry=polyline5',
      );

      final response = await http.get(
        uri,
        headers: {'Authorization': _radarApiKey},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final geometry = data['routes'][0]['geometry']['polyline'];
          final points = PolylineCodec.decode(geometry);
          final coordinates = points.map((p) => [p[1], p[0]]).toList();

          final geoJson = {
            'type': 'FeatureCollection',
            'features': [
              {
                'type': 'Feature',
                'geometry': {'type': 'LineString', 'coordinates': coordinates},
                'properties': {},
              },
            ],
          };

          final controller = await _controllerCompleter.future;

          if (_isRouteLineLayerAdded) {
            try {
              await controller.removeLayer('route-line');
              await controller.removeSource('route-source');
            } catch (_) {}
            _isRouteLineLayerAdded = false;
          }

          await controller.addSource(
            'route-source',
            GeojsonSourceProperties(data: geoJson),
          );
          await controller.addLineLayer(
            'route-source',
            'route-line',
            const LineLayerProperties(
              lineColor: '#0B4AA8',
              lineWidth: 5.0,
              lineOpacity: 0.8,
              lineCap: 'round',
              lineJoin: 'round',
            ),
          );
          _isRouteLineLayerAdded = true;
        }
      }
    } catch (e) {
      debugPrint("❌ Route Exception: $e");
    } finally {
      if (mounted) setState(() {});
    }
  }

  Future<bool> _ensureJourneyPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError("Location services are disabled. Please enable GPS.");
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      if (!mounted) return false;
      final bool userAgreed = await _showJourneyDisclosureDialog();

      if (!userAgreed) {
        _showError("Location is required to track your journey.");
        return false;
      }

      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError("Location permission denied.");
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) _showSettingsDialog();
      return false;
    }

    return true;
  }

  Future<bool> _showJourneyDisclosureDialog() async {
    return await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.map, color: _cardNavy),
                const SizedBox(width: 8),
                const Expanded(child: Text("Allow Location Permissions")),
              ],
            ),
            content: const Text(
              "This app collects location data to enable [Salesman Route Tracking] "
              "and [Distance Calculation] even when the app is closed or not in use.",
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
          "Journey tracking requires location permission. Please enable it in Settings.",
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
            child: const Text("OPEN SETTINGS"),
          ),
        ],
      ),
    );
  }

  Future<void> _determinePositionAndMoveCamera() async {
    try {
      final hasPermission = await _ensureJourneyPermission();
      if (!hasPermission) return;

      final location = AppKernel.instance.feature<JourneyLocationController>();
      final result = await location.resolveCurrentLocation();

      if (result.event == JourneyLocationEvent.granted &&
          result.location != null) {
        _currentUserLocation = result.location;

        if (mounted && !_isJourneyActive) {
          if (_distanceDisplay.contains("Waiting") ||
              _distanceDisplay.contains("Map")) {
            setState(() => _distanceDisplay = "My Location");
          }
        }

        if (_destinationLocation == null) {
          final controller = await _controllerCompleter.future;
          await controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: _currentUserLocation!, zoom: 15.0),
            ),
          );
        }
        _drawUserLocationPointer(_currentUserLocation!);
      }
    } catch (e) {
      debugPrint("❌ _determinePositionAndMoveCamera Exception: $e");
    }
  }

  Future<void> _fitBounds() async {
    try {
      final controller = await _controllerCompleter.future;
      final bounds = LatLngBounds(
        southwest: LatLng(
          _currentUserLocation!.latitude < _destinationLocation!.latitude
              ? _currentUserLocation!.latitude
              : _destinationLocation!.latitude,
          _currentUserLocation!.longitude < _destinationLocation!.longitude
              ? _currentUserLocation!.longitude
              : _destinationLocation!.longitude,
        ),
        northeast: LatLng(
          _currentUserLocation!.latitude > _destinationLocation!.latitude
              ? _currentUserLocation!.latitude
              : _destinationLocation!.latitude,
          _currentUserLocation!.longitude > _destinationLocation!.longitude
              ? _currentUserLocation!.longitude
              : _destinationLocation!.longitude,
        ),
      );
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          bounds,
          left: 80,
          top: 80,
          right: 80,
          bottom: 80,
        ),
      );
    } catch (_) {}
  }

  // 🔥 UPDATED: POINTER VISUALS (Red/White Target)
  Future<void> _addDestinationMarker(LatLng point) async {
    try {
      final controller = await _controllerCompleter.future;

      // Cleanup first
      try {
        await controller.removeLayer('dest-layer-inner');
        await controller.removeLayer('dest-layer-outer');
        await controller.removeSource('dest-source');
      } catch (_) {}

      await controller.addSource(
        'dest-source',
        GeojsonSourceProperties(
          data: {
            'type': 'FeatureCollection',
            'features': [
              {
                'type': 'Feature',
                'geometry': {
                  'type': 'Point',
                  'coordinates': [point.longitude, point.latitude],
                },
              },
            ],
          },
        ),
      );

      // 1. Outer Ring (White with Navy Stroke)
      await controller.addCircleLayer(
        'dest-source',
        'dest-layer-outer',
        const CircleLayerProperties(
          circleColor: '#FFFFFF',
          circleRadius: 10,
          circleStrokeWidth: 2,
          circleStrokeColor: '#0F172A',
        ),
      );

      // 2. Inner Dot (Red)
      await controller.addCircleLayer(
        'dest-source',
        'dest-layer-inner',
        const CircleLayerProperties(circleColor: '#EF4444', circleRadius: 6),
      );
    } catch (_) {}
  }

  // Helper to remove both layers
  Future<void> _removeDestinationMarker() async {
    final controller = await _controllerCompleter.future;
    try {
      await controller.removeLayer('dest-layer-inner');
      await controller.removeLayer('dest-layer-outer');
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
    final controller = await _controllerCompleter.future;
    final data = {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'properties': {},
          'geometry': {
            'type': 'Point',
            'coordinates': [point.longitude, point.latitude],
          },
        },
      ],
    };

    if (_isUserLocationLayerAdded) {
      try {
        await controller.setGeoJsonSource('user-loc-s', data);
      } catch (_) {}
    } else {
      try {
        await controller.addSource(
          'user-loc-s',
          GeojsonSourceProperties(data: data),
        );
        await controller.addCircleLayer(
          'user-loc-s',
          'user-loc-c-o',
          const CircleLayerProperties(
            circleColor: '#FFFFFF',
            circleRadius: 12.0,
          ),
        );
        await controller.addCircleLayer(
          'user-loc-s',
          'user-loc-c-i',
          const CircleLayerProperties(
            circleColor: '#0B4AA8',
            circleRadius: 8.0,
          ),
        );
        _isUserLocationLayerAdded = true;
      } catch (_) {}
    }
  }

  Future<void> _updateTravelledPolyline() async {
    if (_routeTaken.length < 2) return;
    final controller = await _controllerCompleter.future;
    final data = {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'properties': {},
          'geometry': {
            'type': 'LineString',
            'coordinates': _routeTaken
                .map((p) => [p.longitude, p.latitude])
                .toList(),
          },
        },
      ],
    };

    if (_isTravelledLineLayerAdded) {
      await controller.setGeoJsonSource('rt-source', data);
    } else {
      try {
        await controller.addSource(
          'rt-source',
          GeojsonSourceProperties(data: data),
        );
        await controller.addLineLayer(
          'rt-source',
          'rt-line',
          const LineLayerProperties(lineColor: '#EF4444', lineWidth: 6.0),
        );
        _isTravelledLineLayerAdded = true;
      } catch (_) {}
    }
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
    } catch (_) {}
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
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
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
                          icon: const Icon(Icons.search, color: Color(0xFF0F172A)),
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
        if (!_isSelectionMode) ...[
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
          DraggableScrollableSheet(
            initialChildSize: 0.32,
            minChildSize: 0.32,
            maxChildSize: 0.5,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: _surfaceWhite,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30.0),
                  ),
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24.0),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 24.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    _isJourneyActive
                        ? _buildActiveJourneyPanel(context)
                        : _buildIdleJourneyPanel(context),
                    const SizedBox(height: 24),
                    _StartJourneySlider(
                      key: ValueKey(_isJourneyActive),
                      isJourneyActive: _isJourneyActive,
                      onSlideAction: _isJourneyActive
                          ? _stopJourney
                          : _startJourney,
                      canStart: canStartJourney,
                      cardNavy: _cardNavy,
                      dangerRed: _dangerRed,
                    ),
                  ],
                ),
              );
            },
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
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: _bgLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: TextField(
              controller: _destinationController,
              readOnly: true,
              style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
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

  Widget _buildActiveJourneyPanel(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _cardNavy,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "DISTANCE",
                      style: TextStyle(color: Colors.white60, fontSize: 10),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _distanceDisplay,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // 🔥 UPDATED: NAVIGATE BUTTON (Google Maps)
              GestureDetector(
                onTap: _launchGoogleMapsNavigation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.directions,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "NAVIGATE",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.flag_rounded, color: _textDark, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _destinationController.text.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
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
    final String slideText = isJourneyActive
        ? 'SLIDE TO END VISIT'
        : 'SLIDE TO START';
    final Color outerColor = isJourneyActive ? dangerRed : cardNavy;
    final Icon sliderIcon = isJourneyActive
        ? Icon(Icons.stop_rounded, color: dangerRed)
        : Icon(Icons.arrow_forward_rounded, color: cardNavy);
    final bool isEnabled = canStart || isJourneyActive;

    return SlideAction(
      onSubmit: isEnabled
          ? () async {
              await onSlideAction();
              return null;
            }
          : null,
      innerColor: Colors.white,
      outerColor: isEnabled ? outerColor : Colors.grey[300],
      sliderButtonIcon: sliderIcon,
      text: isEnabled ? slideText : 'LOADING DATA...',
      enabled: isEnabled,
      textStyle: TextStyle(
        color: isEnabled ? Colors.white : Colors.grey[500],
        fontSize: 14,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.0,
      ),
      borderRadius: 20,
      elevation: 0,
      height: 64,
    );
  }
}
