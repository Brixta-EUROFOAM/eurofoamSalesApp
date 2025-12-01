import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/models/employee_model.dart';
import 'package:salesmanapp/models/geotracking_data_model.dart';
import 'package:salesmanapp/models/pjp_model.dart';
import 'package:salesmanapp/technicalSide/models/sites_model.dart';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_radar/flutter_radar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:polyline_codec/polyline_codec.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';

class TechnicalJourneyScreen extends StatefulWidget {
  final Employee employee;
  final Map<String, dynamic>? initialJourneyData;
  final VoidCallback? onDestinationConsumed;
  final Function(Pjp pjp, TechnicalSite site, DateTime checkInTime)?
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
  final Completer<MapLibreMapController> _controllerCompleter = Completer();
  late Future<String> _styleFuture;

  // UI State
  String _distanceDisplay = "Waiting for PJP...";
  final _destinationController = TextEditingController();

  final String? _stadiaApiKey = dotenv.env['STADIA_API_KEY'];
  final String? _radarApiKey = dotenv.env['RADAR_API_KEY'];
  final ApiService _apiService = ApiService();

  // Journey State
  bool _isJourneyActive = false;
  double _totalDistanceTravelled = 0.0;
  Position? _lastRecordedPosition;
  String? _currentJourneyId;
  String? _currentGeoTrackingDbId;

  // Data Holding State
  Pjp? _currentPjp;
  TechnicalSite? _currentSite;
  String? _currentPjpId;
  LatLng? _currentUserLocation;
  LatLng? _destinationLocation;
  final List<LatLng> _routeTaken = [];

  // ✅ Map State Flags
  bool _isUserLocationLayerAdded = false;
  bool _isRouteLineLayerAdded = false;
  bool _isTravelledLineLayerAdded = false;

  // Notifications & Radar
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isNearDestinationNotified = false;
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _radarArrivalCheckTimer;

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
    _initializeNotifications();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Radar.setUserId(widget.employee.id);
      Radar.setDescription(widget.employee.displayName);
      _setupRadarListeners();

      _determinePositionAndMoveCamera();
      _startLocationStream();

      if (widget.initialJourneyData != null) {
        _processNewJourneyData(widget.initialJourneyData!);
      }
    });

    _styleFuture = _readStyle();
  }

  @override
  void didUpdateWidget(covariant TechnicalJourneyScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialJourneyData != oldWidget.initialJourneyData &&
        widget.initialJourneyData != null) {
      _processNewJourneyData(widget.initialJourneyData!);
    }
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _positionStreamSubscription?.cancel();
    _radarArrivalCheckTimer?.cancel();
    if (_isJourneyActive) {
      // If user leaves screen while active, we should probably just stop tracking logic locally
      // but ideally they should slide to stop.
    }
    super.dispose();
  }

  void _processNewJourneyData(Map<String, dynamic> journeyData) async {
    dev.log("🔐 LOCKING IN SITE DATA...", name: 'TechJourney');
    final Pjp? pjp = journeyData['pjp'] as Pjp?;
    final TechnicalSite? site = journeyData['site'] as TechnicalSite?;
    final LatLng? destination = journeyData['destination'] as LatLng?;
    final String? displayName = journeyData['displayName'] as String?;

    if (destination == null ||
        displayName == null ||
        pjp == null ||
        site == null) {
      _showError('Error: Corrupt Site Data.');
      return;
    }

    _currentPjpId = pjp.id;
    _currentPjp = pjp;
    _currentSite = site;
    _destinationLocation = destination;

    if (mounted) {
      setState(() {
        _destinationController.text = displayName;
        _distanceDisplay = "Ready to start";
      });
    }

    _routeTaken.clear();
    _isRouteLineLayerAdded = false;

    final controller = await _controllerCompleter.future;
    try {
      await controller.removeLayer('route-line');
      await controller.removeSource('route-source');
    } catch (_) {}

    await _getDirectionsAndDrawRoute();
    widget.onDestinationConsumed?.call();
  }

  Future<void> _startJourney() async {
    if (_isJourneyActive ||
        _destinationLocation == null ||
        _currentPjp == null) {
      _showError("Cannot start: Site data not loaded.");
      return;
    }

    _isNearDestinationNotified = false;
    _routeTaken.clear();
    _isTravelledLineLayerAdded = false;
    _currentGeoTrackingDbId = null; // Reset DB ID for new journey

    final controller = await _controllerCompleter.future;
    try {
      await controller.removeLayer('rt-line');
      await controller.removeSource('rt-source');
    } catch (_) {}

    try {
      // 1. Get Initial Position
      Position initialPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _lastRecordedPosition = initialPosition;
      _routeTaken.add(
        LatLng(initialPosition.latitude, initialPosition.longitude),
      );

      // 2. Generate Client-Side Journey ID (for local tracking/logs)
      _currentJourneyId =
          'JRN-TECH-${widget.employee.id}-${DateTime.now().millisecondsSinceEpoch}';

      _showTrackingNotification();
      setState(() {
        _isJourneyActive = true;
        _totalDistanceTravelled = 0.0;
        _distanceDisplay = "0.00 km";
      });
      _showError("Journey Tracking Started!");

      final startPoint = GeoTrackingPoint(
        userId: int.parse(widget.employee.id),
        journeyId: _currentJourneyId!,
        latitude: initialPosition.latitude,
        longitude: initialPosition.longitude,
        // Send Destination Coordinates
        destLat: _destinationLocation?.latitude,
        destLng: _destinationLocation?.longitude,
        siteId: _currentSite?.id,
        isActive: true,
        locationType: 'JOURNEY_START',
        //recordedAt: DateTime.now().toIso8601String(),
      );

      // Capture the UUID returned by the server so we can PATCH this exact record later
      _currentGeoTrackingDbId = await _apiService.sendGeoTrackingPoint(
        startPoint,
      );
      dev.log(
        "✅ Journey Started. Server DB ID: $_currentGeoTrackingDbId",
        name: 'TechJourney',
      );

      // 4. Update PJP Status
      if (_currentPjpId != null) {
        await _apiService.updatePjp(_currentPjpId!, {'status': 'IN_PROGRESS'});
      }

      _radarArrivalCheckTimer?.cancel();
      _radarArrivalCheckTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _performRadarArrivalCheck(),
      );
    } catch (e) {
      _showError("Failed to start journey: $e");
      setState(() => _isJourneyActive = false);
    }
  }

  Future<void> _stopJourney() async {
    dev.log("🛑 STOPPING JOURNEY...", name: 'TechJourney');
    _radarArrivalCheckTimer?.cancel();
    _cancelTrackingNotification();

    if (!_isJourneyActive) return;

    final DateTime checkInTime = DateTime.now();

    // --- 1. PATCH: Update the existing Tracking Record ---
    // We strictly update the record we created at the start using _currentGeoTrackingDbId
    if (_currentGeoTrackingDbId != null && _lastRecordedPosition != null) {
      try {
        final updateData = {
          'isActive': false, // Close the journey flag
          'totalDistanceTravelled': _totalDistanceTravelled,
          // Update final position
          'latitude': _lastRecordedPosition!.latitude,
          'longitude': _lastRecordedPosition!.longitude,
          'locationType': 'JOURNEY_END',
          // We can optionally send checkOutTime if your schema supports it
          'checkOutTime': checkInTime.toIso8601String(),
        };

        await _apiService.updateGeoTrackingPoint(
          _currentGeoTrackingDbId!,
          updateData,
        );
        dev.log(
          "✅ GeoTracking PATCHED successfully (Distance: $_totalDistanceTravelled)",
          name: 'TechJourney',
        );
      } catch (e) {
        dev.log("⚠️ GeoTracking PATCH Failed: $e", name: 'TechJourney');
      }
    } else {
      dev.log(
        "⚠️ Skipping PATCH: No DB ID or Position available to update.",
        name: 'TechJourney',
      );
    }

    // --- 2. Update PJP Status ---
    if (_currentPjpId != null) {
      try {
        await _apiService.updatePjp(_currentPjpId!, {'status': 'COMPLETED'});
        dev.log("✅ PJP Marked Completed", name: 'TechJourney');
      } catch (e) {
        dev.log("❌ PJP Update Failed: $e", name: 'TechJourney');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Network Error: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    // --- 3. Proceed to Form ---
    if (widget.onJourneyCompleted != null &&
        _currentPjp != null &&
        _currentSite != null) {
      widget.onJourneyCompleted!(_currentPjp!, _currentSite!, checkInTime);
    }

    // --- 4. Cleanup UI ---
    final controller = await _controllerCompleter.future;
    try {
      await controller.removeLayer('route-line');
      await controller.removeSource('route-source');
      await controller.removeLayer('rt-line');
      await controller.removeSource('rt-source');
    } catch (_) {}

    _isRouteLineLayerAdded = false;
    _isTravelledLineLayerAdded = false;

    if (mounted) {
      setState(() {
        _isJourneyActive = false;
        _currentJourneyId = null;
        _currentPjp = null;
        _currentSite = null;
        _currentPjpId = null;
        _destinationLocation = null;
        //_destinationController.clear();
        _distanceDisplay = "Visit Completed";
        _routeTaken.clear();
        _currentGeoTrackingDbId = null; // Reset ID for safety
      });
    }
  }

  // --- LOCATION LOGIC ---
  void _startLocationStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(_onPositionUpdate, onError: (e) => dev.log("Loc Error: $e"));
  }

  void _onPositionUpdate(Position position) {
    _currentUserLocation = LatLng(position.latitude, position.longitude);
    if (mounted) _drawUserLocationPointer(_currentUserLocation!);

    if (!_isJourneyActive) return;

    if (_lastRecordedPosition != null) {
      final double movement = Geolocator.distanceBetween(
        _lastRecordedPosition!.latitude,
        _lastRecordedPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      if (movement > 2.0) {
        _totalDistanceTravelled += movement;
        _lastRecordedPosition = position;
        _routeTaken.add(_currentUserLocation!);
        _updateTravelledPolyline();
      }
    } else {
      _lastRecordedPosition = position;
    }

    if (_destinationLocation != null && !_isNearDestinationNotified) {
      final double dist = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        _destinationLocation!.latitude,
        _destinationLocation!.longitude,
      );
      if (dist < 500) {
        _showNearArrivalNotification();
        _isNearDestinationNotified = true;
      }
    }

    if (mounted) {
      setState(
        () => _distanceDisplay =
            "${(_totalDistanceTravelled / 1000.0).toStringAsFixed(2)} km",
      );
    }
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
      } catch (e) {
        dev.log("Error updating user location source: $e");
      }
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
      } catch (e) {
        _isUserLocationLayerAdded = true;
      }
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
      } catch (e) {
        _isTravelledLineLayerAdded = true;
      }
    }
  }

  Future<void> _getDirectionsAndDrawRoute() async {
    if (_currentUserLocation == null || _destinationLocation == null) {
      if (_currentUserLocation == null) await _determinePositionAndMoveCamera();
      if (_currentUserLocation == null) return;
    }
    final locations =
        '${_currentUserLocation!.latitude},${_currentUserLocation!.longitude}|${_destinationLocation!.latitude},${_destinationLocation!.longitude}';
    final url = Uri.parse(
      'https://api.radar.io/v1/route/directions?locations=$locations&mode=car&units=metric&geometry=polyline5',
    );
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': _radarApiKey!},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final polyline = PolylineCodec.decode(
          data['routes'][0]['geometry']['polyline'],
        );
        final routePoints = polyline
            .map((p) => LatLng(p[0].toDouble(), p[1].toDouble()))
            .toList();

        final controller = await _controllerCompleter.future;

        final geoJson = {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': {},
              'geometry': {
                'type': 'LineString',
                'coordinates': routePoints
                    .map((p) => [p.longitude, p.latitude])
                    .toList(),
              },
            },
          ],
        };

        if (_isRouteLineLayerAdded) {
          await controller.setGeoJsonSource('route-source', geoJson);
        } else {
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
            ),
          );
          _isRouteLineLayerAdded = true;
        }
      }
    } catch (e) {
      dev.log("Route Error: $e");
    }
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  Future<void> _showNearArrivalNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'near_arrival_channel',
          'Near Arrival',
          importance: Importance.max,
          priority: Priority.high,
        );
    await flutterLocalNotificationsPlugin.show(
      0,
      'Approaching Site',
      'You are close to the site.',
      const NotificationDetails(android: androidDetails),
    );
  }

  Future<void> _showTrackingNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'tracking_channel',
          'Tracking',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
        );
    await flutterLocalNotificationsPlugin.show(
      1,
      'Journey Active',
      'Tracking location...',
      const NotificationDetails(android: androidDetails),
    );
  }

  Future<void> _cancelTrackingNotification() async {
    await flutterLocalNotificationsPlugin.cancel(1);
  }

  void _setupRadarListeners() {
    Radar.onEvents((result) {
      if (!_isJourneyActive || _currentPjpId == null) return;
      final events = result['events'] as List<dynamic>?;
      if (events == null) return;
      final arrivalEvent = events.firstWhere(
        (event) =>
            event['type'] == 'user.entered_geofence' &&
            event['geofence']['externalId'] == _currentPjpId,
        orElse: () => null,
      );
      if (arrivalEvent != null) _showDestinationArrivalNotification();
    });
  }

  void _performRadarArrivalCheck() async {
    if (_isJourneyActive) await Radar.trackOnce();
  }

  void _showDestinationArrivalNotification() {
    if (!mounted || !_isJourneyActive) return;
    _stopJourney();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('SITE REACHED'),
        content: const Text('You have arrived.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _determinePositionAndMoveCamera() async {
    setState(() => _distanceDisplay = "Checking permissions...");
    try {
      String? status = await Radar.getPermissionsStatus();
      if (status == 'DENIED' || status == 'NOT_DETERMINED')
        status = await Radar.requestPermissions(true);
      if (status != 'GRANTED_BACKGROUND' && status != 'GRANTED_FOREGROUND') {
        setState(() => _distanceDisplay = 'Permission Denied');
        return;
      }
      setState(() => _distanceDisplay = "Fetching location...");
      Position position = await Geolocator.getCurrentPosition();
      _currentUserLocation = LatLng(position.latitude, position.longitude);
      if (mounted && !_isJourneyActive)
        setState(() => _distanceDisplay = "My Location");
      final controller = await _controllerCompleter.future;
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentUserLocation!, zoom: 15.0),
        ),
      );
      _drawUserLocationPointer(_currentUserLocation!);
    } catch (e) {
      if (mounted) setState(() => _distanceDisplay = "Loc Error");
    }
  }

  Future<String> _readStyle() async {
    if (_stadiaApiKey == null) throw Exception("API Key Missing");
    return jsonEncode({
      "version": 8,
      "sources": {
        "stadia": {
          "type": "raster",
          "tiles": [
            "https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}@2x.png?api_key=$_stadiaApiKey",
          ],
          "tileSize": 256,
        },
      },
      "layers": [
        {
          "id": "stadia-layer",
          "source": "stadia",
          "type": "raster",
          "minzoom": 0,
          "maxzoom": 22,
        },
      ],
    });
  }

  Future<void> _launchGoogleMapsNavigation() async {
    if (_destinationLocation == null) return;
    final url = Uri.parse(
      'google.navigation:q=${_destinationLocation!.latitude},${_destinationLocation!.longitude}',
    );
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  void _showError(String message) {
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final bool canStartJourney =
        _destinationLocation != null &&
        !_isJourneyActive &&
        _currentSite != null;

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
    );
  }

  Widget _buildIdleJourneyPanel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.business, color: _textGrey, size: 20),
            const SizedBox(width: 8),
            Text(
              "SELECTED SITE",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: _textGrey,
                fontSize: 12,
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
              style: TextStyle(color: _textDark, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.lock_outline, color: _textGrey),
                hintText: "Waiting for PJP...",
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
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
              InkWell(
                onTap: _launchGoogleMapsNavigation,
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.near_me_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
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
      text: isEnabled ? slideText : 'LOADING SITE DATA...',
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
