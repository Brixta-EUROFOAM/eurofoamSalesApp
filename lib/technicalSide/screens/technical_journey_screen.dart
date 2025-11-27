import 'dart:async';
import 'dart:convert';

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
  final Function(Pjp pjp, TechnicalSite site, DateTime checkInTime)? onJourneyCompleted;

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

  String _distanceDisplay = "Select a site to start";
  final _destinationController = TextEditingController();

  final String? _stadiaApiKey = dotenv.env['STADIA_API_KEY'];
  final String? _radarApiKey = dotenv.env['RADAR_API_KEY'];

  final ApiService _apiService = ApiService();

  bool _isJourneyActive = false;
  double _totalDistanceTravelled = 0.0;
  Position? _lastRecordedPosition;

  String? _currentJourneyId;
  Pjp? _currentPjp;
  TechnicalSite? _currentSite; 
  String? _currentPjpId;
  LatLng? _currentUserLocation;
  LatLng? _destinationLocation;

  final List<LatLng> _routeTaken = [];

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isNearDestinationNotified = false;

  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _radarArrivalCheckTimer;

  static const _initialCameraPosition = CameraPosition(
    target: LatLng(26.1445, 91.7362), 
    zoom: 12,
  );

  // --- FINTECH THEME PALETTE ---
  final Color _bgLight       = const Color(0xFFF3F4F6); // Corporate Light Grey
  final Color _cardNavy      = const Color(0xFF0F172A); // Deep Navy (Hero Card)
  final Color _textDark      = const Color(0xFF111827); // Almost Black
  final Color _textGrey      = const Color(0xFF6B7280); // Subtitles
  final Color _surfaceWhite  = Colors.white;
  final Color _dangerRed     = const Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    Radar.setUserId(widget.employee.id);
    Radar.setDescription(widget.employee.displayName);
    _setupRadarListeners();
    _styleFuture = _readStyle();
    _initializeFirstTime();
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
      _stopJourney();
    }
    super.dispose();
  }

  Future<void> _launchGoogleMapsNavigation() async {
    if (_destinationLocation == null) {
      _showError("Destination not set.");
      return;
    }
    final lat = _destinationLocation!.latitude;
    final lng = _destinationLocation!.longitude;
    final url = Uri.parse('google.navigation:q=$lat,$lng');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      _showError("Could not open Google Maps. Is it installed?");
    }
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showNearArrivalNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'near_arrival_channel', 'Near Arrival Notifications',
        channelDescription: 'Notifies when you are close to your destination',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true);
    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(
        0,
        'Approaching Site',
        'You are about to reach ${_destinationController.text}.',
        platformDetails);
  }

  Future<void> _showTrackingNotification() async {
    const int trackingNotificationId = 1;
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'tracking_channel',
      'Tracking Notifications',
      channelDescription:
          'Shows when your location is being tracked for a journey.',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
    );
    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(
        trackingNotificationId,
        'Technical Journey Active',
        'Your route to the site is being tracked.',
        platformDetails);
  }

  Future<void> _cancelTrackingNotification() async {
    const int trackingNotificationId = 1;
    await flutterLocalNotificationsPlugin.cancel(trackingNotificationId);
  }

  Future<void> _initializeFirstTime() async {
    await _determinePositionAndMoveCamera();
    _startLocationStream();

    if (widget.initialJourneyData != null) {
      _processNewJourneyData(widget.initialJourneyData!);
    }
  }

  void _startLocationStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 1,
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen(_onPositionUpdate, onError: (e) {
      debugPrint("Error in location stream: $e");
    });
  }

  void _onPositionUpdate(Position position) {
    _currentUserLocation = LatLng(position.latitude, position.longitude);

    if (mounted) {
      _drawUserLocationPointer(_currentUserLocation!);
    }

    if (!_isJourneyActive) {
      return;
    }

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
      final double distanceToDestination = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        _destinationLocation!.latitude,
        _destinationLocation!.longitude,
      );
      if (distanceToDestination < 500) {
        _showNearArrivalNotification();
        _isNearDestinationNotified = true;
      }
    }

    if (mounted) {
      setState(() {
        final distanceKm = _totalDistanceTravelled / 1000.0;
        _distanceDisplay = "${distanceKm.toStringAsFixed(2)} km";
      });
    }
  }

  void _processNewJourneyData(Map<String, dynamic> journeyData) async {
    final Pjp? pjp = journeyData['pjp'] as Pjp?;
    final TechnicalSite? site = journeyData['site'] as TechnicalSite?;
    final LatLng? destination = journeyData['destination'] as LatLng?;
    final String? displayName = journeyData['displayName'] as String?;

    if (destination == null || displayName == null || pjp == null || site == null) {
      _showError('Invalid journey data. Missing Site or PJP.');
      return;
    }

    _currentPjpId = pjp.id;
    _currentPjp = pjp;
    _currentSite = site; 

    _routeTaken.clear();

    final controller = await _controllerCompleter.future;
    try {
      await controller.removeLayer('route-taken-line');
      await controller.removeSource('route-taken-source');
    } catch (_) {}

    if (mounted) {
      setState(() {
        _destinationLocation = destination;
        _destinationController.text = displayName;
      });
    }

    await _getDirectionsAndDrawRoute();
    widget.onDestinationConsumed?.call();
  }

  void _setupRadarListeners() {
    Radar.onEvents((result) {
      if (!_isJourneyActive || _currentPjpId == null) return;
      final events = result['events'] as List<dynamic>?;
      if (events == null) return;
      final arrivalEvent = events.firstWhere(
        (event) =>
            event['type'] == 'user.entered_geofence' &&
            event['geofence'] != null &&
            event['geofence']['externalId'] == _currentPjpId,
        orElse: () => null,
      );
      if (arrivalEvent != null) {
        _showDestinationArrivalNotification();
      }
    });
  }

  void _performRadarArrivalCheck() async {
    if (!_isJourneyActive) {
      _radarArrivalCheckTimer?.cancel();
      return;
    }
    try {
      await Radar.trackOnce();
    } catch (e) {
      debugPrint("Error calling Radar.trackOnce: $e");
    }
  }

  void _startJourney() async {
    if (_isJourneyActive || _destinationLocation == null) return;

    _isNearDestinationNotified = false;
    _routeTaken.clear();

    try {
      Position initialPosition =
          await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _lastRecordedPosition = initialPosition;
      _routeTaken
          .add(LatLng(initialPosition.latitude, initialPosition.longitude));
    } catch (e) {
      _showError("Could not get initial location: $e");
      return;
    }

    _currentJourneyId =
        'JRN-TECH-${widget.employee.id}-${DateTime.now().millisecondsSinceEpoch}';

    try {
      _showTrackingNotification();

      setState(() {
        _isJourneyActive = true;
        _totalDistanceTravelled = 0.0;
        _distanceDisplay = "0.00 km";
      });
      _showError("Journey Tracking Started!");

      _radarArrivalCheckTimer?.cancel();
      _radarArrivalCheckTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _performRadarArrivalCheck(),
      );
    } catch (e) {
      _showError("Failed to start journey.");
    }
  }

  void _stopJourney() async {
    _radarArrivalCheckTimer?.cancel();
    _cancelTrackingNotification();

    if (!_isJourneyActive) return;

    final DateTime checkInTime = DateTime.now();

    if (_lastRecordedPosition != null && _currentJourneyId != null) {
      final finalTrackingPoint = GeoTrackingPoint(
        userId: int.parse(widget.employee.id),
        journeyId: _currentJourneyId!,
        latitude: _lastRecordedPosition!.latitude,
        longitude: _lastRecordedPosition!.longitude,
        totalDistanceTravelled: _totalDistanceTravelled,
        isActive: false,
        locationType: 'FINAL_STOP_SUMMARY',
      );
      _apiService.sendGeoTrackingPoint(finalTrackingPoint);
    }

    if (_currentPjpId != null) {
      try {
        await _apiService.updatePjp(_currentPjpId!, {'status': 'COMPLETED'});
      } catch (e) {
        debugPrint("❌ Failed to update PJP status to completed: $e");
      }
    }

    final finalDistanceKm = _totalDistanceTravelled / 1000.0;
    if (mounted) {
      setState(() {
        _isJourneyActive = false;
        _currentJourneyId = null;
        _currentPjpId = null;
        _distanceDisplay = "Journey Complete (${finalDistanceKm.toStringAsFixed(2)} km)";
      });
    }
    _showError(
        "Journey Ended. Total distance: ${finalDistanceKm.toStringAsFixed(2)} km.");

    if (widget.onJourneyCompleted != null &&
        _currentPjp != null &&
        _currentSite != null) {
      widget.onJourneyCompleted!(_currentPjp!, _currentSite!, checkInTime);
    }

    _currentPjp = null;
    _currentSite = null;
  }

  void _showDestinationArrivalNotification() {
    if (!mounted || !_isJourneyActive) return;
    _stopJourney();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('SITE REACHED', style: TextStyle(color: _textDark, fontWeight: FontWeight.bold)),
        content: Text('You have arrived. Please complete the technical visit report.', 
          style: TextStyle(color: _textGrey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('START REPORT', style: TextStyle(color: _cardNavy, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Future<void> _determinePositionAndMoveCamera() async {
    setState(() => _distanceDisplay = "Checking permissions...");
    try {
      String? status = await Radar.getPermissionsStatus();
      if (status == 'DENIED' || status == 'NOT_DETERMINED') {
        status = await Radar.requestPermissions(true);
      }
      if (status != 'GRANTED_BACKGROUND' && status != 'GRANTED_FOREGROUND') {
        setState(() => _distanceDisplay = 'Location permissions denied');
        _showError('Background location permissions are required for tracking.');
        return;
      }
      setState(() => _distanceDisplay = "Fetching location...");
      Position position = await Geolocator.getCurrentPosition();
      _currentUserLocation = LatLng(position.latitude, position.longitude);

      if (mounted) setState(() => _distanceDisplay = "My Current Location");

      final controller = await _controllerCompleter.future;
      await controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: _currentUserLocation!, zoom: 15.0),
      ));
      _drawUserLocationPointer(_currentUserLocation!);
    } catch (e) {
      if (mounted) {
        setState(() => _distanceDisplay = "Failed to get location");
      }
      _showError("Error getting location: $e");
    }
  }

  Future<void> _drawUserLocationPointer(LatLng point) async {
    final controller = await _controllerCompleter.future;
    try {
      await controller.removeLayer('user-location-circle-outer');
      await controller.removeLayer('user-location-circle-inner');
      await controller.removeSource('user-location-source');
    } catch (_) {}
    await controller.addSource(
        'user-location-source',
        GeojsonSourceProperties(data: {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': {},
              'geometry': {
                'type': 'Point',
                'coordinates': [point.longitude, point.latitude]
              }
            }
          ]
        }));
    await controller.addCircleLayer(
        'user-location-source',
        'user-location-circle-outer',
        const CircleLayerProperties(
            circleColor: '#FFFFFF', circleRadius: 12.0, circleOpacity: 0.9));
    await controller.addCircleLayer(
        'user-location-source',
        'user-location-circle-inner',
        const CircleLayerProperties(
            circleColor: '#0B4AA8', circleRadius: 8.0, circleOpacity: 1.0));
  }

  Future<void> _updateTravelledPolyline() async {
    if (_routeTaken.length < 2) return;
    final controller = await _controllerCompleter.future;
    try {
      await controller.removeLayer('route-taken-line');
      await controller.removeSource('route-taken-source');
    } catch (_) {}
    await controller.addSource(
        'route-taken-source',
        GeojsonSourceProperties(data: {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': {},
              'geometry': {
                'type': 'LineString',
                'coordinates':
                    _routeTaken.map((p) => [p.longitude, p.latitude]).toList()
              }
            }
          ]
        }));
    await controller.addLineLayer(
        'route-taken-source',
        'route-taken-line',
        const LineLayerProperties(
            lineColor: '#EF4444',
            lineWidth: 6.0,
            lineOpacity: 0.6,
            lineCap: 'round',
            lineJoin: 'round'));
  }

  Future<void> _handleDestinationSubmit(String destinationAddress) async {
    if (_radarApiKey == null) return;
    if (_currentUserLocation == null) {
      _showError("Current location not available.");
      return;
    }
    final autocompleteUrl = Uri.parse(
        'https://api.radar.io/v1/autocomplete?query=$destinationAddress&near=${_currentUserLocation!.latitude},${_currentUserLocation!.longitude}');
    try {
      final response =
          await http.get(autocompleteUrl, headers: {'Authorization': _radarApiKey});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['addresses'] != null && data['addresses'].isNotEmpty) {
          final lat = data['addresses'][0]['latitude'];
          final lon = data['addresses'][0]['longitude'];
          if (mounted) setState(() => _destinationLocation = LatLng(lat, lon));
          _getDirectionsAndDrawRoute();
        } else {
          _showError("Could not find location.");
        }
      } else {
        throw Exception('Failed to geocode address');
      }
    } catch (e) {
      _showError("Error finding destination.");
    }
  }

  Future<void> _getDirectionsAndDrawRoute() async {
    if (_currentUserLocation == null || _destinationLocation == null) return;
    final locations =
        '${_currentUserLocation!.latitude},${_currentUserLocation!.longitude}|${_destinationLocation!.latitude},${_destinationLocation!.longitude}';
    final url = Uri.parse(
        'https://api.radar.io/v1/route/directions?locations=$locations&mode=car&units=metric&geometry=polyline5');
    try {
      final response =
          await http.get(url, headers: {'Authorization': _radarApiKey!});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final polylineString = data['routes'][0]['geometry']['polyline'];
        final polyline = PolylineCodec.decode(polylineString);
        final routePoints = polyline
            .map((p) => LatLng(p[0].toDouble(), p[1].toDouble()))
            .toList();
        final controller = await _controllerCompleter.future;
        try {
          await controller.removeLayer('route-line');
          await controller.removeSource('route-source');
        } catch (_) {}
        await controller.addSource(
            'route-source',
            GeojsonSourceProperties(data: {
              'type': 'FeatureCollection',
              'features': [
                {
                  'type': 'Feature',
                  'properties': {},
                  'geometry': {
                    'type': 'LineString',
                    'coordinates': routePoints
                        .map((p) => [p.longitude, p.latitude])
                        .toList()
                  }
                }
              ]
            }));
        await controller.addLineLayer(
            'route-source',
            'route-line',
            const LineLayerProperties(
                lineColor: '#0B4AA8',
                lineWidth: 5.0,
                lineOpacity: 0.8,
                lineCap: 'round',
                lineJoin: 'round'));
      } else {
        throw Exception('Failed to load directions');
      }
    } catch (e) {
      _showError("Error fetching route.");
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
    debugPrint(message);
  }

  Future<String> _readStyle() async {
    if (_stadiaApiKey == null) throw Exception("Stadia Maps API key not found.");
    return jsonEncode({
      "version": 8,
      "sources": {
        "stadia": {
          "type": "raster",
          "tiles": [
            "https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}@2x.png?api_key=$_stadiaApiKey"
          ],
          "tileSize": 256
        }
      },
      "layers": [
        {
          "id": "stadia-layer",
          "source": "stadia",
          "type": "raster",
          "minzoom": 0,
          "maxzoom": 22
        }
      ]
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool canStartJourney =
        _destinationLocation != null && !_isJourneyActive;

    return Stack(
      children: [
        // 1. MAP LAYER
        SizedBox.expand(
          child: FutureBuilder<String>(
            future: _styleFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: _cardNavy));
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return Container(
                  color: _bgLight,
                  child: Center(
                    child: Text('Map Error: ${snapshot.error}',
                        style: TextStyle(color: _textGrey)),
                  ),
                );
              }
              return MapLibreMap(
                styleString: snapshot.data!,
                initialCameraPosition: _initialCameraPosition,
                onMapCreated: (controller) {
                  if (!_controllerCompleter.isCompleted) {
                    _controllerCompleter.complete(controller);
                  }
                },
              );
            },
          ),
        ),

        // 2. RECENTER BUTTON (Styled White Floating Button)
        Positioned(
          top: 50,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
              ]
            ),
            child: IconButton(
              icon: Icon(Icons.my_location, color: _cardNavy),
              onPressed: () => _determinePositionAndMoveCamera(),
            ),
          ),
        ),

        // 3. DRAGGABLE SHEET (COMMAND CENTER UI)
        DraggableScrollableSheet(
          initialChildSize: 0.32,
          minChildSize: 0.32,
          maxChildSize: 0.5,
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: _surfaceWhite, // Pure White Sheet
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30.0),
                  topRight: Radius.circular(30.0),
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 15.0,
                    color: Colors.black.withOpacity(0.1),
                    offset: const Offset(0, -5)
                  )
                ],
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24.0),
                children: [
                  // Handle
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

                  // Content
                  _isJourneyActive
                      ? _buildActiveJourneyPanel(context)
                      : _buildIdleJourneyPanel(context),

                  const SizedBox(height: 24),
                  
                  // Slider
                  _StartJourneySlider(
                    isJourneyActive: _isJourneyActive,
                    onSlideAction:
                        _isJourneyActive ? _stopJourney : _startJourney,
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

  // --- IDLE STATE (Light Theme) ---
  Widget _buildIdleJourneyPanel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.route, color: _textGrey, size: 20),
            const SizedBox(width: 8),
            Text(
              "TECHNICAL VISIT PLAN",
              style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: _textGrey,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: _bgLight, // Light grey input
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Center(
            child: TextField(
              controller: _destinationController,
              readOnly: widget.initialJourneyData != null,
              onSubmitted: _handleDestinationSubmit, 
              style: TextStyle(color: _textDark, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: _textGrey),
                hintText: "Select a site from Visits",
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- ACTIVE STATE (Hero Card Style) ---
  Widget _buildActiveJourneyPanel(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _cardNavy, // Deep Navy Card
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _cardNavy.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Distance
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "DISTANCE TRAVELLED",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _distanceDisplay,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Navigation Action
              InkWell(
                onTap: _launchGoogleMapsNavigation,
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.near_me_rounded, color: Colors.white, size: 28),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Destination readout
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
                  letterSpacing: 0.5,
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
  final VoidCallback onSlideAction;
  final bool canStart;
  final Color cardNavy;
  final Color dangerRed;

  const _StartJourneySlider({
    required this.isJourneyActive,
    required this.onSlideAction,
    required this.canStart,
    required this.cardNavy,
    required this.dangerRed,
  });

  @override
  Widget build(BuildContext context) {
    final String slideText =
        isJourneyActive ? 'SLIDE TO END VISIT' : 'SLIDE TO START';
    
    final Color outerColor = isJourneyActive ? dangerRed : cardNavy;
    
    final Icon sliderIcon = isJourneyActive 
        ? Icon(Icons.stop_rounded, color: dangerRed) 
        : Icon(Icons.arrow_forward_rounded, color: cardNavy);
        
    final bool isEnabled = canStart || isJourneyActive;

    return SlideAction(
      onSubmit: isEnabled
          ? () {
              onSlideAction();
              return null;
            }
          : () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Please select a site PJP before starting.'),
                backgroundColor: Colors.orange,
              ));
              return null;
            },
      innerColor: Colors.white,
      outerColor: isEnabled ? outerColor : Colors.grey[300],
      sliderButtonIcon: sliderIcon,
      text: isEnabled ? slideText : 'SELECT SITE TO START',
      enabled: isEnabled,
      textStyle: TextStyle(
        color: isEnabled ? (isJourneyActive ? Colors.white : Colors.white) : Colors.grey[500],
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