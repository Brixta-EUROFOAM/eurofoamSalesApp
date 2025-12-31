import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'map_selection_result.dart';
import 'map_selection_capabilities.dart';

class MapSelectionController {
  final MapSelectionCapabilities caps;

  // ✅ FREE, NO KEY, PRODUCTION SAFE
  static const String mapStyle = "https://tiles.openfreemap.org/styles/liberty";

  MapSelectionController({required this.caps});

  Future<MapSelectionResult?> showMapPicker(BuildContext context) async {
    if (!caps.enabled) return null;

    Position? currentPos;
    try {
      currentPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
    } catch (_) {}

    if (!context.mounted) return MapSelectionResult.cancelled();

    final result = await showModalBottomSheet<MapSelectionResult>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SafeArea(
        child: _MapPickerSheet(
          caps: caps,
          initialPos: currentPos != null
              ? LatLng(currentPos.latitude, currentPos.longitude)
              : const LatLng(26.1445, 91.7362),
        ),
      ),
    );

    return result ?? MapSelectionResult.cancelled();
  }

  /// 🔥 OVERPASS — SEARCH INSIDE AREA (radius-based)
  Future<List<LatLng>> searchAmenityNearby({
    required String amenity,
    required LatLng center,
    double radiusMeters = 1000,
  }) async {
    if (!caps.areaSearchEnabled) return [];

    const endpoint = 'https://overpass-api.de/api/interpreter';

    final query =
        '''
[out:json];
(
  node["amenity"="$amenity"]
    (around:$radiusMeters,${center.latitude},${center.longitude});
);
out;
''';

    final res = await http.post(Uri.parse(endpoint), body: {'data': query});

    final json = jsonDecode(res.body);
    final elements = json['elements'] as List<dynamic>;

    return elements.map((e) => LatLng(e['lat'], e['lon'])).toList();
  }

  String formatPjpArea(String primaryName, MapSelectionResult result) {
    return '$primaryName, ${result.address}'
        '|${result.position.latitude}|${result.position.longitude}';
  }
}

class _MapPickerSheet extends StatefulWidget {
  final MapSelectionCapabilities caps;
  final LatLng initialPos;

  const _MapPickerSheet({required this.caps, required this.initialPos});

  @override
  State<_MapPickerSheet> createState() => _MapPickerSheetState();
}

class _MapPickerSheetState extends State<_MapPickerSheet> {
  late MapLibreMapController mapController;
  late LatLng _currentPos;

  final _searchController = TextEditingController();
  String _address = "Searching for area name...";
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _currentPos = widget.initialPos;
  }

Future<void> _searchLocation(String query) async {
  if (query.trim().isEmpty) return;

  setState(() => _isSearching = true);

  try {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?q=${Uri.encodeComponent(query)}'
      '&format=json'
      '&limit=1',
    );

    final res = await http.get(
      uri,
      headers: {
        'User-Agent': 'salesmanapp/1.0', // IMPORTANT
      },
    );

    final List data = jsonDecode(res.body);

    if (data.isEmpty) {
      throw Exception("No results");
    }

    final lat = double.parse(data.first['lat']);
    final lon = double.parse(data.first['lon']);

    final target = LatLng(lat, lon);

    await mapController.animateCamera(
      CameraUpdate.newLatLngZoom(target, 14),
    );

    _updateAddress(target);
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location not found")),
      );
    }
  } finally {
    if (mounted) setState(() => _isSearching = false);
  }
}


  Future<void> _updateAddress(LatLng pos) async {
    if (!widget.caps.geocodingEnabled) return;
    try {
      final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (marks.isNotEmpty) {
        final p = marks.first;
        setState(() {
          _address = "${p.subLocality ?? p.name}, ${p.locality}";
        });
      }
    } catch (_) {
      setState(() => _address = "Selected Location");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onSubmitted: _searchLocation,
              decoration: InputDecoration(
                hintText: "Search area, town, landmark...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () =>
                            _searchLocation(_searchController.text),
                      ),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                MapLibreMap(
                  styleString: MapSelectionController.mapStyle,
                  initialCameraPosition: CameraPosition(
                    target: widget.initialPos,
                    zoom: 13,
                  ),
                  onMapCreated: (c) => mapController = c,
                  onCameraIdle: () {
                    _currentPos = mapController.cameraPosition!.target;
                    _updateAddress(_currentPos);
                  },
                ),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 35),
                    child: Icon(Icons.location_on, size: 48),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 10),
                      ],
                    ),
                    child: Text(
                      _address,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(
                  context,
                  MapSelectionResult(position: _currentPos, address: _address),
                ),
                child: const Text("CONFIRM VISIT AREA"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
