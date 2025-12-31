import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_radar/flutter_radar.dart';

import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:polyline_codec/polyline_codec.dart';
import 'package:slide_to_act/slide_to_act.dart';

import 'package:provider/provider.dart';

// Core & Models
import 'package:salesmanapp/core/feature_flags/technical_flags.dart';
import 'package:salesmanapp/core/app_kernel.dart';
import 'package:salesmanapp/models/employee_model.dart';
import 'package:salesmanapp/models/pjp_model.dart';
import 'package:salesmanapp/technicalSide/models/sites_model.dart';
import 'package:salesmanapp/models/dealer_model.dart';

// Features
import 'package:salesmanapp/features/journeytracking/journey_tracking_controller.dart';
import 'package:salesmanapp/features/journeytracking/journey_tracking_result.dart';
import 'package:salesmanapp/features/launchgooglemapsJourneyscreen/googlemaps_controller.dart';

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
  )? onJourneyCompleted;

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

  // UI State
  String _distanceDisplay = "Waiting for PJP...";
  final _destinationController = TextEditingController();

  final String? _stadiaApiKey = dotenv.env['STADIA_API_KEY'];
  final String? _radarApiKey = dotenv.env['RADAR_API_KEY'];

  // Journey State
  bool _isJourneyActive = false;
  
  // Stream Subscriptions for source-of-truth tracking
  StreamSubscription? _distanceSub;
  StreamSubscription? _posSub;
  StreamSubscription? _eventSub;

  // Data Holding State
  Pjp? _currentPjp;
  TechnicalSite? _currentSite;
  Dealer? _currentDealer;
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
    flags = context.read<TechnicalFlags>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Radar.setUserId(widget.employee.id);
      Radar.setDescription(widget.employee.displayName);

      // 🔔 Initialize Notifications via Controller
      if (flags.journeyNotifications) {
        try {
          final tracking = AppKernel.instance.feature<JourneyTrackingController>();
          await tracking.initNotifications();
        } catch (_) {}
      }

      // 🗺 Map bootstrap
      if (flags.journeyMap) {
        _determinePositionAndMoveCamera();
      }

      // ▶ Consume incoming journey data
      if (widget.initialJourneyData != null && flags.journeyStartStop) {
        _processNewJourneyData(widget.initialJourneyData!);
      }
    });

    if (flags.journeyMap) {
      _styleFuture = _readStyle();
    }
  }

  @override
  void dispose() {
    _cancelJourneySubscriptions();
    _destinationController.dispose();
    super.dispose();
  }

  void _cancelJourneySubscriptions() {
    _distanceSub?.cancel();
    _posSub?.cancel();
    _eventSub?.cancel();
  }

  // --- Start Journey Logic ---
  Future<void> _startJourney() async {
    if (_isJourneyActive || _destinationLocation == null || _currentPjp == null) {
      _showError("Cannot start: Data not loaded.");
      return;
    }

    try {
      final tracking = AppKernel.instance.feature<JourneyTrackingController>();

      final result = await tracking.startJourney(
        pjp: _currentPjp!,
        userId: int.parse(widget.employee.id),
        destination: _destinationLocation!,
        isSite: _isSiteVisit,
        siteId: _currentSite?.id,
        dealerId: _currentDealer?.id,
      );

      if (result.event == JourneyTrackingEvent.error) {
        _showError(result.message ?? 'Journey start failed');
        return;
      }

      setState(() {
        _isJourneyActive = true;
        _distanceDisplay = "0.00 km";
        _routeTaken.clear();
      });

      // 🔗 Listen to distance updates (Source of Truth)
      _distanceSub = tracking.distanceStream.listen((dist) {
        if (mounted) {
          setState(() => _distanceDisplay = "${(dist / 1000.0).toStringAsFixed(2)} km");
        }
      });

      // 🔗 Listen to position updates for the Map Polyline
      _posSub = tracking.positionStream.listen((latLng) {
        _currentUserLocation = latLng;
        _routeTaken.add(latLng);
        _drawUserLocationPointer(latLng);
        _updateTravelledPolyline();
      });

      // 🔗 Listen for Controller Events (like Arrival)
      _eventSub = tracking.eventStream.listen((event) {
        if (event == JourneyTrackingEvent.arrived) {
          _showArrivalDialog();
        }
      });

    } catch (e) {
      _showError("Failed to start journey: $e");
    }
  }

  // --- Stop Journey Logic ---
  Future<void> _stopJourney() async {
    if (!_isJourneyActive) return;

    try {
      final tracking = AppKernel.instance.feature<JourneyTrackingController>();
      await tracking.stopJourney();
    } catch (_) {}

    _handleJourneyCleanup();
  }

  void _handleJourneyCleanup() {
    _cancelJourneySubscriptions();
    final checkInTime = DateTime.now();

    if (widget.onJourneyCompleted != null && _currentPjp != null) {
      final entity = _isSiteVisit ? _currentSite : _currentDealer;
      if (entity != null) {
        widget.onJourneyCompleted!(
          _currentPjp!,
          entity,
          _isSiteVisit,
          checkInTime,
        );
      }
    }

    if (mounted) {
      setState(() {
        _isJourneyActive = false;
        _currentPjp = null;
        _currentSite = null;
        _currentDealer = null;
        _destinationLocation = null;
        _distanceDisplay = "Visit Completed";
        _routeTaken.clear();
      });
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
          )
        ],
      ),
    );
  }

  // --- Helper Methods ---
  void _processNewJourneyData(Map<String, dynamic> journeyData) async {
    final Pjp? pjp = journeyData['pjp'] as Pjp?;
    final LatLng? destination = journeyData['destination'] as LatLng?;
    final String? displayName = journeyData['displayName'] as String?;
    final bool isSite = journeyData['isSite'] ?? true;

    final TechnicalSite? site = journeyData['site'] as TechnicalSite?;
    final Dealer? dealer = journeyData['dealer'] as Dealer?;

    _currentPjp = pjp;
    _isSiteVisit = isSite;
    _destinationLocation = destination;
    _currentSite = isSite ? site : null;
    _currentDealer = !isSite ? dealer : null;

    if (mounted) {
      setState(() {
        _destinationController.text = displayName ?? "";
        _distanceDisplay = "Ready to start";
      });
    }

    _routeTaken.clear();
    final controller = await _controllerCompleter.future;
    try {
      await controller.removeLayer('route-line');
      await controller.removeSource('route-source');
    } catch (_) {}

    await _getDirectionsAndDrawRoute();
    widget.onDestinationConsumed?.call();
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
      try { await controller.setGeoJsonSource('user-loc-s', data); } catch (_) {}
    } else {
      try {
        await controller.addSource('user-loc-s', GeojsonSourceProperties(data: data));
        await controller.addCircleLayer('user-loc-s', 'user-loc-c-o', const CircleLayerProperties(circleColor: '#FFFFFF', circleRadius: 12.0));
        await controller.addCircleLayer('user-loc-s', 'user-loc-c-i', const CircleLayerProperties(circleColor: '#0B4AA8', circleRadius: 8.0));
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
            'coordinates': _routeTaken.map((p) => [p.longitude, p.latitude]).toList(),
          },
        },
      ],
    };

    if (_isTravelledLineLayerAdded) {
      await controller.setGeoJsonSource('rt-source', data);
    } else {
      try {
        await controller.addSource('rt-source', GeojsonSourceProperties(data: data));
        await controller.addLineLayer('rt-source', 'rt-line', const LineLayerProperties(lineColor: '#EF4444', lineWidth: 6.0));
        _isTravelledLineLayerAdded = true;
      } catch (_) {}
    }
  }

  Future<void> _getDirectionsAndDrawRoute() async {
    if (_currentUserLocation == null || _destinationLocation == null) return;
    final locations = '${_currentUserLocation!.latitude},${_currentUserLocation!.longitude}|${_destinationLocation!.latitude},${_destinationLocation!.longitude}';
    final url = Uri.parse('https://api.radar.io/v1/route/directions?locations=$locations&mode=car&units=metric&geometry=polyline5');
    try {
      final response = await http.get(url, headers: {'Authorization': _radarApiKey!});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final polyline = PolylineCodec.decode(data['routes'][0]['geometry']['polyline']);
        final routePoints = polyline.map((p) => LatLng(p[0].toDouble(), p[1].toDouble())).toList();
        final controller = await _controllerCompleter.future;
        final geoJson = {
          'type': 'FeatureCollection',
          'features': [
            {'type': 'Feature', 'properties': {}, 'geometry': {'type': 'LineString', 'coordinates': routePoints.map((p) => [p.longitude, p.latitude]).toList()}}
          ],
        };
        if (_isRouteLineLayerAdded) {
          await controller.setGeoJsonSource('route-source', geoJson);
        } else {
          await controller.addSource('route-source', GeojsonSourceProperties(data: geoJson));
          await controller.addLineLayer('route-source', 'route-line', const LineLayerProperties(lineColor: '#0B4AA8', lineWidth: 5.0, lineOpacity: 0.8));
          _isRouteLineLayerAdded = true;
        }
      }
    } catch (_) {}
  }

  Future<void> _determinePositionAndMoveCamera() async {
    try {
      final location = AppKernel.instance.feature<JourneyLocationController>();
      final result = await location.resolveCurrentLocation();

      if (result.event == JourneyLocationEvent.granted && result.location != null) {
        _currentUserLocation = result.location;
        if (mounted && !_isJourneyActive) setState(() => _distanceDisplay = "My Location");
        final controller = await _controllerCompleter.future;
        await controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: _currentUserLocation!, zoom: 15.0)));
        _drawUserLocationPointer(_currentUserLocation!);
      }
    } catch (_) {}
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
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final bool hasData = _currentSite != null || _currentDealer != null;
    final bool canStartJourney = _destinationLocation != null && !_isJourneyActive && hasData;

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
                  if (!_controllerCompleter.isCompleted) _controllerCompleter.complete(c);
                },
              );
            },
          ),
        ),
        Positioned(
          top: 50,
          right: 16,
          child: Container(
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: IconButton(icon: Icon(Icons.my_location, color: _cardNavy), onPressed: _determinePositionAndMoveCamera),
          ),
        ),
        DraggableScrollableSheet(
          initialChildSize: 0.32, minChildSize: 0.32, maxChildSize: 0.5,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(color: _surfaceWhite, borderRadius: const BorderRadius.vertical(top: Radius.circular(30.0))),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24.0),
                children: [
                  Center(child: Container(width: 40, height: 5, margin: const EdgeInsets.only(bottom: 24.0), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)))),
                  _isJourneyActive ? _buildActiveJourneyPanel(context) : _buildIdleJourneyPanel(context),
                  const SizedBox(height: 24),
                  _StartJourneySlider(
                    key: ValueKey(_isJourneyActive),
                    isJourneyActive: _isJourneyActive,
                    onSlideAction: _isJourneyActive ? _stopJourney : _startJourney,
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
            Text("SELECTED ${_isSiteVisit ? 'SITE' : 'DEALER'}", style: TextStyle(fontWeight: FontWeight.w900, color: _textGrey, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 56, padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(color: _bgLight, borderRadius: BorderRadius.circular(16)),
          child: Center(
            child: TextField(
              controller: _destinationController,
              readOnly: true,
              style: TextStyle(color: _textDark, fontWeight: FontWeight.w600),
              decoration: InputDecoration(prefixIcon: Icon(Icons.lock_outline, color: _textGrey), hintText: "Waiting for PJP...", border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
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
          decoration: BoxDecoration(color: _cardNavy, borderRadius: BorderRadius.circular(24)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("DISTANCE", style: TextStyle(color: Colors.white60, fontSize: 10)),
                    const SizedBox(height: 8),
                    Text(_distanceDisplay, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              InkWell(
                onTap: _launchGoogleMapsNavigation,
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white12, shape: BoxShape.circle),
                  child: const Icon(Icons.near_me_rounded, color: Colors.white, size: 28),
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
              child: Text(_destinationController.text.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: _textDark, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
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

  const _StartJourneySlider({super.key, required this.isJourneyActive, required this.onSlideAction, required this.canStart, required this.cardNavy, required this.dangerRed});

  @override
  Widget build(BuildContext context) {
    final String slideText = isJourneyActive ? 'SLIDE TO END VISIT' : 'SLIDE TO START';
    final Color outerColor = isJourneyActive ? dangerRed : cardNavy;
    final Icon sliderIcon = isJourneyActive ? Icon(Icons.stop_rounded, color: dangerRed) : Icon(Icons.arrow_forward_rounded, color: cardNavy);
    final bool isEnabled = canStart || isJourneyActive;

    return SlideAction(
      onSubmit: isEnabled ? () async { await onSlideAction(); return null; } : null,
      innerColor: Colors.white,
      outerColor: isEnabled ? outerColor : Colors.grey[300],
      sliderButtonIcon: sliderIcon,
      text: isEnabled ? slideText : 'LOADING DATA...',
      enabled: isEnabled,
      textStyle: TextStyle(color: isEnabled ? Colors.white : Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.0),
      borderRadius: 20, elevation: 0, height: 64,
    );
  }
}