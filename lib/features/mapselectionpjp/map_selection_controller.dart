import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'map_selection_result.dart';
import 'map_selection_capabilities.dart';

class MapSelectionController {
  final MapSelectionCapabilities caps;

  // 🔥 STADIA RASTER STYLE (Crash-Proof)
  static String get mapStyle {
    final apiKey = dotenv.env['STADIA_API_KEY'] ?? '';
    return '''
    {
      "version": 8,
      "sources": {
        "stadia-raster": {
          "type": "raster",
          "tiles": [
            "https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}.png?api_key=$apiKey"
          ],
          "tileSize": 256,
          "attribution": "&copy; Stadia Maps, &copy; OpenMapTiles &copy; OpenStreetMap contributors"
        }
      },
      "layers": [
        {
          "id": "stadia-raster-layer",
          "type": "raster",
          "source": "stadia-raster",
          "paint": {
            "raster-opacity": 1.0
          }
        }
      ]
    }
    ''';
  }

  MapSelectionController({required this.caps});

  // --- 1. REVERSE GEOCODING HELPER ---
  Future<String> getAddress(LatLng pos) async {
    if (!caps.geocodingEnabled) return "Selected Location";
    try {
      final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (marks.isNotEmpty) {
        final p = marks.first;
        final parts = [p.subLocality, p.locality, p.postalCode]
            .where((e) => e != null && e.isNotEmpty)
            .toSet()
            .join(", ");
        if (parts.isNotEmpty) return parts;
        return p.name ?? "Unknown Location";
      }
    } catch (_) {}
    return "Custom Location";
  }

  // --- 2. FORMAT HELPER ---
  String formatPjpArea(String primaryName, MapSelectionResult result) {
    return '$primaryName, ${result.address}|${result.position.latitude}|${result.position.longitude}';
  }

  // --- 3. FORWARD GEOCODING (SEARCH) ---
  Future<LatLng?> searchLocation(String query) async {
    if (query.trim().isEmpty) return null;
    try {
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1');
      final res = await http.get(uri, headers: {'User-Agent': 'salesmanapp/1.0'});
      
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data.first['lat']);
          final lon = double.parse(data.first['lon']);
          return LatLng(lat, lon);
        }
      }
    } catch (_) {}
    return null;
  }

  // --- 4. INSTANT PICKER UI (For Wizard Stack) ---
  /// Returns the Map UI as a Widget to be used in a Stack (Instant feel)
  Widget buildPickerUI(
    BuildContext context, {
    required LatLng initialPos,
    required Function(MapSelectionResult) onLocationSelected,
    required VoidCallback onCancel,
  }) {
    return _MapPickerScreen(
      initialPos: initialPos,
      caps: caps,
      isOverlay: true,
      onResult: onLocationSelected,
      onBack: onCancel,
    );
  }

  // --- 5. CLASSIC PICKER METHOD (Navigator based) ---
  Future<MapSelectionResult?> showMapPicker(BuildContext context) async {
    if (!caps.enabled) return null;

    Position? currentPos;
    try {
      currentPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
    } catch (_) {}

    if (!context.mounted) return MapSelectionResult.cancelled();

    final result = await Navigator.of(context).push<MapSelectionResult>(
      MaterialPageRoute(
        builder: (_) => _MapPickerScreen(
          initialPos: currentPos != null
              ? LatLng(currentPos.latitude, currentPos.longitude)
              : const LatLng(26.1445, 91.7362),
          caps: caps,
        ),
      ),
    );

    return result ?? MapSelectionResult.cancelled();
  }
}

// --- FULL SCREEN / OVERLAY MAP PICKER ---
class _MapPickerScreen extends StatefulWidget {
  final LatLng initialPos;
  final MapSelectionCapabilities caps;
  
  // New props for Overlay support
  final bool isOverlay;
  final Function(MapSelectionResult)? onResult;
  final VoidCallback? onBack;

  const _MapPickerScreen({
    required this.initialPos, 
    required this.caps,
    this.isOverlay = false,
    this.onResult,
    this.onBack,
  });

  @override
  State<_MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<_MapPickerScreen> {
  late MapLibreMapController mapController;
  late LatLng _currentPos;
  final _searchController = TextEditingController();
  String _address = "Move map to select...";
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _currentPos = widget.initialPos;
    _updateAddress(_currentPos);
  }

  Future<void> _updateAddress(LatLng pos) async {
    if (!widget.caps.geocodingEnabled) return;
    try {
      final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (marks.isNotEmpty) {
        final p = marks.first;
        if (mounted) {
          setState(() => _address = "${p.subLocality ?? p.name}, ${p.locality}");
        }
      }
    } catch (_) {
      if (mounted) setState(() => _address = "Selected Location");
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1');
      final res = await http.get(uri, headers: {'User-Agent': 'salesmanapp/1.0'});
      final List data = jsonDecode(res.body);

      if (data.isNotEmpty) {
        final lat = double.parse(data.first['lat']);
        final lon = double.parse(data.first['lon']);
        final target = LatLng(lat, lon);
        
        await mapController.animateCamera(CameraUpdate.newLatLngZoom(target, 14));
        _currentPos = target;
        _updateAddress(target);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // We use a WillPopScope-like logic or simply Scaffold to handle the UI.
    // If it's an overlay, we might want to wrap it in a Gesture detector to prevent taps leaking through.
    return Scaffold(
      body: Stack(
        children: [
          MapLibreMap(
            styleString: MapSelectionController.mapStyle,
            initialCameraPosition: CameraPosition(target: widget.initialPos, zoom: 13),
            onMapCreated: (c) => mapController = c,
            trackCameraPosition: true,
            onCameraIdle: () {
              if (mapController.cameraPosition != null) {
                _currentPos = mapController.cameraPosition!.target;
                _updateAddress(_currentPos);
              }
            },
          ),
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 35),
              child: Icon(Icons.location_on, size: 48, color: Color(0xFF0F172A)),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: _searchLocation,
                style: const TextStyle(color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: "Search area...",
                  prefixIcon: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      if (widget.isOverlay) {
                        widget.onBack?.call();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  suffixIcon: _isSearching
                      ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))
                      : IconButton(
                          icon: const Icon(Icons.search, color: Color(0xFF0F172A)), 
                          onPressed: () => _searchLocation(_searchController.text)
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text("SELECTED AREA", style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_address, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final res = MapSelectionResult(position: _currentPos, address: _address);
                      if (widget.isOverlay) {
                        widget.onResult?.call(res);
                      } else {
                        Navigator.pop(context, res);
                      }
                    },
                    child: const Text("CONFIRM LOCATION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}