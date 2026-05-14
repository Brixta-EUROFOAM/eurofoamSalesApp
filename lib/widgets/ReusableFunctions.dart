// lib/widgets/ReusableFunctions.dart
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'dart:async';
import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/dealer_model.dart';

/// A simple data class to pass location data around cleanly
class LocationResult {
  final double latitude;
  final double longitude;
  final String address;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class ReusableFunctions {
  static final ImagePicker _imagePicker = ImagePicker();

  /// Captures an image using the device camera.
  /// Defaults to the front-facing camera (useful for attendance/selfies)
  /// and compresses the image to 70% quality to save bandwidth.
  static Future<XFile?> captureImage({
    CameraDevice preferredCameraDevice = CameraDevice.front,
    int imageQuality = 70,
  }) async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: preferredCameraDevice,
        imageQuality: imageQuality,
      );
      return photo;
    } catch (e) {
      print('Error capturing image from camera: $e');
      return null;
    }
  }

  /// Picks an image from the device gallery.
  /// Useful if your DVR forms allow uploading existing photos.
  static Future<XFile?> pickImageFromGallery({int imageQuality = 70}) async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
      );
      return photo;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Centralized Location Fetcher with Aggressive Geocoding
  /// Throws exceptions with user-friendly messages if permissions fail.
  static Future<LocationResult> getCurrentLocationAndAddress() async {
    // 1. Check Permissions & Service Status
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable GPS.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permissions are permanently denied. Please enable in settings.',
      );
    }

    // 2. Fetch High-Accuracy Position
    final Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // 3. Aggressive Reverse Geocoding (Filtering out Plus Codes)
    String finalAddress =
        "Lat: ${position.latitude}, Lng: ${position.longitude}";

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        // List of potential address components in order of granularity
        List<String?> components = [
          place.name,
          place.subLocality,
          place.locality,
          place.subAdministrativeArea,
          place.administrativeArea,
          place.postalCode,
        ];

        // Aggressive Filter: Remove nulls, empties, and Google Plus Codes (which usually contain a '+')
        final validComponents = components.where((c) {
          if (c == null || c.trim().isEmpty) return false;
          // Filter out generic unnamed roads or plus codes (e.g., "5XWQC+4G")
          if (c.contains('+') || c.toLowerCase().contains('unnamed')) {
            return false;
          }
          return true;
        }).toList();

        // Deduplicate values (sometimes name and subLocality are the same)
        final uniqueComponents = validComponents.toSet().toList();

        if (uniqueComponents.isNotEmpty) {
          finalAddress = uniqueComponents.join(', ');
        }
      }
    } catch (e) {
      print("Geocoding failed: $e");
      // Silently fallback to the Lat/Lng string initialized above
    }

    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      address: finalAddress,
    );
  }
}

/// ------------------------------------------------------------
/// PUBLIC HELPERS
/// ------------------------------------------------------------
Future<DealerModel?> openDealerSearch(BuildContext context) {
  return showDialog<DealerModel>(
    context: context,
    builder: (_) => const DealerSearchDialog(),
  );
}

/// ------------------------------------------------------------
/// BASE SEARCH DIALOG (DRY UI)
/// ------------------------------------------------------------
class _BaseSearchDialog<T> extends StatelessWidget {
  final String title;
  final bool isLoading;
  final List<T> items;
  final Function(String) onSearch;
  final Widget Function(T) itemBuilder;

  const _BaseSearchDialog({
    required this.title,
    required this.isLoading,
    required this.items,
    required this.onSearch,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        height: 500,
        width: double.maxFinite,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: onSearch,
              decoration: InputDecoration(
                hintText: "Search name, GST, or location...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : items.isEmpty
                  ? const Center(
                      child: Text(
                        "No results found",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) => itemBuilder(items[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// API-DRIVEN DEALER SEARCH
/// ------------------------------------------------------------
class DealerSearchDialog extends StatefulWidget {
  const DealerSearchDialog({super.key});

  @override
  State<DealerSearchDialog> createState() => _DealerSearchDialogState();
}

class _DealerSearchDialogState extends State<DealerSearchDialog> {
  final ApiService _api = ApiService();
  List<DealerModel> _dealers = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _search(""); // Fetch initial generic list
  }

  void _search(String query) {
    _debounce?.cancel();

    // Debounce avoids spamming your API while the user is typing
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isLoading = true);

      try {
        // You will need to implement a search parameter in your ApiService.getDealers()
        // e.g., await _api.getDealers(searchQuery: query.trim());

        // For now, assuming getDealers() fetches all or takes a query
        final results = await _api.getDealers();

        // If your API doesn't handle the search query yet, filter locally as a fallback:
        final cleanQuery = query.trim().toLowerCase();
        final filteredResults = cleanQuery.isEmpty
            ? results
            : results
                  .where(
                    (d) =>
                        d.dealerPartyName.toLowerCase().contains(cleanQuery) ||
                        (d.zone?.toLowerCase().contains(cleanQuery) ?? false) ||
                        (d.gstNo?.toLowerCase().contains(cleanQuery) ?? false),
                  )
                  .toList();

        if (mounted) {
          setState(() => _dealers = filteredResults);
        }
      } catch (e) {
        debugPrint("Dealer search error: $e");
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _BaseSearchDialog<DealerModel>(
      title: "Select Dealer",
      isLoading: _isLoading,
      items: _dealers,
      onSearch: _search,
      itemBuilder: (dealer) => ListTile(
        title: Text(
          dealer.dealerPartyName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          "${dealer.area ?? 'Unknown Area'}, ${dealer.zone ?? 'Unknown Zone'}",
          style: const TextStyle(color: Colors.grey),
        ),
        onTap: () => Navigator.pop(context, dealer),
      ),
    );
  }
}
