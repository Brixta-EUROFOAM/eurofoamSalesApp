// lib/technicalSide/screens/forms/create_tvr_form.dart
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salesmanapp/technicalSide/models/technical_visit_report_model.dart';
import 'package:salesmanapp/technicalSide/utils/tvrworker.dart';

// Project Imports
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/models/employee_model.dart';
import 'package:salesmanapp/models/pjp_model.dart';
import 'package:salesmanapp/technicalSide/models/sites_model.dart';
import 'package:salesmanapp/technicalSide/models/mason_pc_model.dart';
import 'package:salesmanapp/models/dealer_model.dart';

// Refactored Components
import '../../utils/tvr_constants.dart';
import '../../tvrwidgets/tvr_form_widgets.dart';
import '../../tvrwidgets/tvr_camera_screen.dart';
import '../../tvrwidgets/tvr_ihb_section.dart';
import '../../tvrwidgets/tvr_dealer_section.dart';
import '../../tvrwidgets/tvr_influencer_section.dart';

class CreateTvrScreen extends StatefulWidget {
  final Employee employee;
  final Pjp? pjp;
  final TechnicalSite? site;
  final DateTime? initialCheckInTime;

  const CreateTvrScreen({
    super.key,
    required this.employee,
    this.pjp,
    this.site,
    this.initialCheckInTime,
  });

  @override
  State<CreateTvrScreen> createState() => _CreateTvrScreenState();
}

class _CreateTvrScreenState extends State<CreateTvrScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  // ⚡ RAM OPTIMIZATION: Map-based state and controller management
  late final Map<String, TextEditingController> _controllers;
  final Map<String, dynamic> _values = {
    'selectedCustomerType': null,
    'selectedVisitType': null,
    'selectedVisitCategory': null,
    'selectedRegion': null,
    'selectedUnit': 'Bags',
    'isConverted': false,
    'isBagPicked': false,
    'isTechService': false,
    'isSubmitting': false,
    'isUploadingImage': false,
    'isFetchingLocation': false,
  };

  @override
  void initState() {
    super.initState();
    _initControllers();

    // Autofill Logic
    if (widget.site != null) _onSiteSelected(widget.site!);
    if (widget.initialCheckInTime != null) {
      _values['checkInTime'] = widget.initialCheckInTime;
      _values['isCheckInProcessing'] = false;
      _values['checkInFailed'] = false;
    }
    if (widget.employee.region != null &&
        TvrConstants.regionOptions.contains(widget.employee.region)) {
      _values['selectedRegion'] = widget.employee.region;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadDrafts();
    });
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSnack(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color.fromARGB(255, 238, 176, 42)
            : TvrConstants.accentGreen,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _initControllers() {
    final keys = [
      'concernedPerson',
      'phone',
      'whatsapp',
      'dealerName',
      'partyName',
      'remarks',
      'qty',
      'rate',
      'siteAddress',
      'marketName',
      'purposeOfVisit',
      'constArea',
      'siteStock',
      'estRequirement',
      'supplyingDealer',
      'nearbyDealer',
      'serviceDesc',
      'influencerName',
      'influencerPhone',
      'productivity',
      'latitude',
      'longitude',
      'area',
    ];
    _controllers = {for (var key in keys) key: TextEditingController()};
  }

  @override
  void dispose() {
    _controllers.forEach((_, c) => c.dispose()); // ⚡ Cleanup RAM
    super.dispose();
  }

  // --- 💾 RECOVERY SYSTEM ---

  void _onUpdate(String key, dynamic value) {
    setState(() => _values[key] = value);
    _saveDrafts();
  }

  Future<void> _saveDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Text Controllers
    _controllers.forEach((key, c) => prefs.setString('tvr_ctrl_$key', c.text));

    // 2. Booleans
    prefs.setBool('tvr_val_is_converted', _values['isConverted'] ?? false);
    prefs.setBool('tvr_val_is_bag_picked', _values['isBagPicked'] ?? false);
    prefs.setBool('tvr_val_is_tech', _values['isTechService'] ?? false);
    prefs.setBool('tvr_val_is_scheme', _values['isSchemeEnrolled'] ?? false);

    // 3. Dropdowns (Crucial - prevents "N/A" on upload)
    final dropdowns = [
      'selectedCustomerType', 'selectedVisitType', 'selectedVisitCategory',
      'selectedRegion', 'selectedUnit', 'selectedStage', 'selectedSiteVisitType',
      'conversionType', 'conversionFromBrand', 'selectedServiceType', 
      'selectedInfluencerType'
    ];
    for (var k in dropdowns) {
      if (_values[k] != null) prefs.setString('tvr_val_$k', _values[k]);
    }

    // 4. Arrays (Brands/InfluencerTypes)
    if (_values['brandsInUse'] != null) {
      prefs.setStringList('tvr_val_brands', (_values['brandsInUse'] as List).cast<String>());
    }

    // 5. Check-In Data (To survive process death)
    if (_values['checkInTime'] != null) {
      prefs.setString('tvr_val_checkin', (_values['checkInTime'] as DateTime).toIso8601String());
    }
    if (_values['inTimeImageUrl'] != null) {
      prefs.setString('tvr_val_in_img_url', _values['inTimeImageUrl']);
    }
    if (_values['sitePhotoUrl'] != null) {
      prefs.setString('tvr_val_site_img_url', _values['sitePhotoUrl']);
    }
  }

  Future<void> _loadDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Restore objects if passed via navigation
    if (_values['selectedSite'] != null) _onSiteSelected(_values['selectedSite']);
    if (_values['selectedDealer'] != null) _onDealerSelected(_values['selectedDealer']);
    if (_values['selectedMason'] != null) _onMasonSelected(_values['selectedMason']);

    // Check if draft exists
    if (!prefs.containsKey('tvr_ctrl_remarks')) return;

    setState(() {
      // 1. Controllers
      _controllers.forEach((key, c) => c.text = prefs.getString('tvr_ctrl_$key') ?? "");

      // 2. Booleans
      _values['isConverted'] = prefs.getBool('tvr_val_is_converted') ?? false;
      _values['isBagPicked'] = prefs.getBool('tvr_val_is_bag_picked') ?? false;
      _values['isTechService'] = prefs.getBool('tvr_val_is_tech') ?? false;
      _values['isSchemeEnrolled'] = prefs.getBool('tvr_val_is_scheme') ?? false;

      // 3. Dropdowns
      final dropdowns = [
        'selectedCustomerType', 'selectedVisitType', 'selectedVisitCategory',
        'selectedRegion', 'selectedUnit', 'selectedStage', 'selectedSiteVisitType',
        'conversionType', 'conversionFromBrand', 'selectedServiceType', 
        'selectedInfluencerType'
      ];
      for (var k in dropdowns) {
        if (prefs.containsKey('tvr_val_$k')) {
          _values[k] = prefs.getString('tvr_val_$k');
        }
      }

      // 4. Arrays
      if (prefs.containsKey('tvr_val_brands')) {
        _values['brandsInUse'] = prefs.getStringList('tvr_val_brands');
      }

      // 5. Check-In & Images
      if (_values['checkInTime'] == null && prefs.containsKey('tvr_val_checkin')) {
        _values['checkInTime'] = DateTime.parse(prefs.getString('tvr_val_checkin')!);
      }
      if (prefs.containsKey('tvr_val_in_img_url')) {
        _values['inTimeImageUrl'] = prefs.getString('tvr_val_in_img_url');
      }
      if (prefs.containsKey('tvr_val_site_img_url')) {
        _values['sitePhotoUrl'] = prefs.getString('tvr_val_site_img_url');
      }
    });
  }

  // Future<void> _clearDrafts() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final allKeys = prefs.getKeys();
  //   for (String key in allKeys) {
  //     if (key.startsWith('tvr_')) await prefs.remove(key);
  //   }
  // }

  // --- 🛑 LOCATION & CAMERA ---

  Future<void> _fetchLocationAndAddress() async {
    _onUpdate('isFetchingLocation', true);

    try {
      final Position? position = await _ensureLocationPermission();
      if (position == null) {
        _onUpdate('isFetchingLocation', false);
        return;
      }
      // ⚡ STEP 1: Update Lat/Long immediately so the user sees something happened
      setState(() {
        _values['capturedLocation'] = position;
        _controllers['latitude']!.text = position.latitude.toStringAsFixed(6);
        _controllers['longitude']!.text = position.longitude.toStringAsFixed(6);
      });

      // ⚡ STEP 2: Fetch Address
      final addressDetails = await _apiService.reverseGeocodeWithRadar(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      setState(() {
        // ⚡ Robust mapping: Try different common keys from geocoding services
        final String? foundAddress =
            addressDetails['address'] ??
            addressDetails['formattedAddress'] ??
            addressDetails['addressLabel'];

        if (foundAddress != null && foundAddress.isNotEmpty) {
          _controllers['siteAddress']!.text = foundAddress;
        }

        if (addressDetails['area'] != null) {
          _controllers['area']!.text = addressDetails['area']!;
        }

        if (addressDetails['region'] != null &&
            TvrConstants.regionOptions.contains(addressDetails['region'])) {
          _values['selectedRegion'] = addressDetails['region'];
        }
      });

      _saveDrafts();
      _showSnack(
        "Location & Address Updated",
        isError: false,
      ); // Green snackbar
    } catch (e) {
      debugPrint("Geocoding Error: $e");
      _showSnack("Location detected, but address fetch failed.");
    } finally {
      _onUpdate('isFetchingLocation', false);
    }
  }

  Future<bool> _showLocationDisclosureDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: const [
                  Icon(Icons.location_on, color: Colors.black87),
                  SizedBox(width: 8),
                  Text(
                    "Location Access Required",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: const Text(
                "To verify this visit, the app needs your location.\n\n",
                style: TextStyle(height: 1.4),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    "DENY",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("ALLOW"),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<Position?> _ensureLocationPermission() async {
    // 1. Check if GPS is ON
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError("Please enable GPS to continue.");
      return null;
    }

    // 2. Check permission state
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // 🔔 SHOW DISCLOSURE FIRST (CRITICAL)
      final bool userAccepted = await _showLocationDisclosureDialog();
      if (!userAccepted) {
        _showError("Location permission is required to verify visit.");
        return null;
      }

      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        _showError("Location permission denied.");
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showLocationSettingsDialog();
      return null;
    }

    // 3. Fetch location
    try {
      // ⚡ ADDED: timeLimit prevents indefinite hanging
      // On Emulators, make sure to "push" a location from Extended Controls
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10), // Stop waiting after 10s
      );
    } catch (e) {
      // If it times out or fails, try to get the last known position as a fallback
      debugPrint("GPS Error");
      return await Geolocator.getLastKnownPosition();
    }
  }

  void _showLocationSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Permission Required"),
        content: const Text(
          "Location permission is permanently denied.\n\n"
          "Please enable it from App Settings to submit the report.",
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

  Future<void> _handleCheckIn() async {
    // 1. UI: Open Camera (Blocking only for user action)
    final String? imagePath = await Navigator.push(
      context,
      MaterialPageRoute(builder: (c) => const TvrCameraScreen()),
    );
    if (imagePath == null) return;

    final File imageFile = File(imagePath);
    final DateTime now = DateTime.now();

    // 2. UI: Update State IMMEDIATELY (Optimistic)
    // The user sees "Check-In Complete" instantly.
    setState(() {
      _values['checkInTime'] = now;
      _values['inTimeImageFile'] = imageFile; // Show local image

      // Flags for the background worker
      _values['isCheckInProcessing'] = true;
      _values['checkInFailed'] = false;
    });

    _saveDrafts();

    // 3. LOGIC: Fire and Forget (Run in background)
    // We do NOT use 'await' here. The UI thread is free to move on.
    _processCheckInInBackground(imageFile);
  }

  Future<void> _processCheckInInBackground(File imageFile) async {
    try {
      // A. Fetch Location (Slow)
      // We use a small timeout so we don't hang forever, but we are in background anyway
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Update location as soon as we have it
      if (mounted) {
        setState(() {
          _values['capturedLocation'] = pos;
          _controllers['latitude']!.text = pos.latitude.toStringAsFixed(6);
          _controllers['longitude']!.text = pos.longitude.toStringAsFixed(6);
        });
      }

      // B. Upload Image (Slow)
      final url = await _apiService.uploadImageToR2(imageFile);

      // C. Success!
      if (mounted) {
        setState(() {
          _values['inTimeImageUrl'] = url;
          _values['isCheckInUploading'] = false;
        });
      }
    } catch (e) {
      debugPrint("Background Check-in Failed (Will retry at submit): $e");
      // D. Silent Failure
      // We don't show an error dialog yet. We just flag it.
      if (mounted) {
        setState(() {
          _values['isCheckInUploading'] = false;
          _values['checkInUploadFailed'] = true; // Mark for retry later
        });
      }
    }
  }

  Future<void> _pickSitePhoto() async {
    final String? imagePath = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TvrCameraScreen()),
    );
    if (imagePath == null) return;

    final file = File(imagePath);

    // 1. Immediately update UI to show "Selected" status
    _onUpdate('sitePhotoFile', file);

    // 2. Upload in background to avoid long waits during final submission
    try {
      final url = await _apiService.uploadImageToR2(file);
      _values['sitePhotoUrl'] = url;
      _saveDrafts();
    } catch (e) {
      _showSnack("Background upload failed, will retry at submission.");
    }
  }

  // --- 🔍 SELECTION HANDLERS ---

  void _onSiteSelected(TechnicalSite site) {
    setState(() {
      _values['selectedSite'] = site;
      _values['selectedSiteName'] = site.siteName;

      _controllers['concernedPerson']!.text = site.concernedPerson;
      _controllers['whatsapp']!.text = site.phoneNo;
      _controllers['phone']!.text = site.phoneNo;
      _controllers['partyName']!.text = site.concernedPerson;

      _controllers['siteAddress']!.text = site.address;
      _controllers['area']!.text = site.area ?? '';

      if (site.latitude != 0.0 && site.latitude != 0.0) {
        _controllers['latitude']!.text = site.latitude.toStringAsFixed(6);
      }
      if (site.longitude != 0.0 && site.longitude != 0.0) {
        _controllers['longitude']!.text = site.longitude.toStringAsFixed(6);
      }

      if (site.region != null &&
          TvrConstants.regionOptions.contains(site.region)) {
        _values['selectedRegion'] = site.region;
      }

      if (site.stageOfConstruction != null &&
          TvrConstants.stageOptions.contains(site.stageOfConstruction)) {
        _values['selectedStage'] = site.stageOfConstruction;
      }
    });

    _saveDrafts();
  }

  void _onDealerSelected(Dealer dealer) {
    setState(() {
      _values['selectedDealer'] = dealer;
      _values['selectedDealerName'] = dealer.name;
      _controllers['partyName']!.text = dealer.name;
      _controllers['phone']!.text = dealer.phoneNo;
      _controllers['siteAddress']!.text = dealer.address;
      _controllers['area']!.text = dealer.area;

      if (dealer.latitude != null && dealer.latitude != 0.0) {
        _controllers['latitude']!.text = dealer.latitude!.toStringAsFixed(6);
      }
      if (dealer.longitude != null && dealer.longitude != 0.0) {
        _controllers['longitude']!.text = dealer.longitude!.toStringAsFixed(6);
      }
      _values['selectedInfluencerType'] = 'Dealer';
    });
    _saveDrafts();
  }

  void _onMasonSelected(Mason mason) {
    setState(() {
      _values['selectedMason'] = mason;
      _values['selectedMasonName'] = mason.name;
      _controllers['influencerName']!.text = mason.name;
      _controllers['influencerPhone']!.text = mason.phoneNumber;
      _values['selectedInfluencerType'] = 'Mason';
    });
    _saveDrafts();
  }

  // --- 🚀 SUBMIT ---

  // <--- Import this!

  Future<void> _submitTvr() async {
    // ---------------------------------------------------------
    // 1. VALIDATION LOGIC (Your strict logic preserved)
    // ---------------------------------------------------------
    if (!_formKey.currentState!.validate()) {
      _showSnack("Please fill in the required fields marked in red.");
      return;
    }
    if (_values['checkInTime'] == null) {
      _showSnack("Check-in is required");
      return;
    }
    if (!_passesTimeLock()) return;

    // MANUAL ENFORCEMENT LOGIC (IHB/Site Checks)
    final String type = _values['selectedCustomerType'] ?? '';
    if (type == 'IHB/Site') {
      if (_values['selectedVisitType'] == null) {
        _showSnack("⚠️ Please select a Visit Type.");
        return;
      }
      if (_values['selectedSiteVisitType'] == null) {
        _showSnack("⚠️ Please select Site Visit Type.");
        return;
      }
      if (_values['selectedVisitCategory'] == null) {
        _showSnack("⚠️ Please select a Visit Category.");
        return;
      }
      if (_controllers['partyName']!.text.trim().isEmpty) {
        _showSnack("⚠️ Site Owner Name is required.");
        return;
      }
      if (_controllers['whatsapp']!.text.trim().isEmpty) {
        _showSnack("⚠️ Phone / WhatsApp No. is required.");
        return;
      }
      if (_values['selectedRegion'] == null) {
        _showSnack("⚠️ Region is required.");
        return;
      }
      if (_controllers['area']!.text.trim().isEmpty) {
        _showSnack("⚠️ Area is required.");
        return;
      }
      if (_controllers['siteAddress']!.text.trim().isEmpty) {
        _showSnack("⚠️ Site Address is required.");
        return;
      }
      if (_controllers['marketName']!.text.trim().isEmpty) {
        _showSnack("⚠️ Market Name is required.");
        return;
      }
      if (_controllers['constArea']!.text.trim().isEmpty) {
        _showSnack("⚠️ Construction Area (SqFt) is required.");
        return;
      }
      if (_values['selectedStage'] == null) {
        _showSnack("⚠️ Construction Stage is required.");
        return;
      }

      final List brands = _values['brandsInUse'] ?? [];
      if (brands.isEmpty) {
        _showSnack("⚠️ Please select at least one Brand in Use.");
        return;
      }

      if (_controllers['siteStock']!.text.trim().isEmpty) {
        _showSnack("⚠️ Site Stock is required.");
        return;
      }
      if (_controllers['estRequirement']!.text.trim().isEmpty) {
        _showSnack("⚠️ Estimated Requirement is required.");
        return;
      }

      if (_values['isConverted'] == true) {
        if (_values['conversionType'] == null) {
          _showSnack("⚠️ Please select Conversion Type.");
          return;
        }
        if (_values['conversionFromBrand'] == null) {
          _showSnack("⚠️ Please select 'From Brand'.");
          return;
        }
        if (_controllers['qty']!.text.trim().isEmpty) {
          _showSnack("⚠️ Please enter Conversion Quantity.");
          return;
        }
        if (_values['selectedUnit'] == null) {
          _showSnack("⚠️ Please select a Unit.");
          return;
        }
        if (_controllers['nearbyDealer']!.text.trim().isEmpty) {
          _showSnack("⚠️ Converted Brand Dealer(Best) is required.");
          return;
        }
      }

      if (_values['isTechService'] == true &&
          _values['selectedServiceType'] == null) {
        _showSnack("⚠️ Please select Service Type.");
        return;
      }

      if (_values['selectedInfluencerType'] == null) {
        _showSnack("⚠️ Influencer Type is required.");
        return;
      }
      if (_controllers['influencerName']!.text.trim().isEmpty) {
        _showSnack("⚠️ Influencer Name is required.");
        return;
      }
      if (_controllers['influencerPhone']!.text.trim().isEmpty) {
        _showSnack("⚠️ Influencer Phone is required.");
        return;
      }
    }

    if (_controllers['remarks']!.text.trim().isEmpty) {
      _showSnack("⚠️ Remarks are required.");
      return;
    }
    if (type.contains("Dealer")) {
      // Basic dealer info
      if (_controllers['partyName']!.text.trim().isEmpty) {
        _showSnack("⚠️ Dealer / Sub-Dealer Name is required.");
        return;
      }

      if (_controllers['phone']!.text.trim().isEmpty) {
        _showSnack("⚠️ Phone / WhatsApp No. is required.");
        return;
      }

      // Visit meta
      if (_values['selectedVisitCategory'] == null) {
        _showSnack("⚠️ Visit Category is required.");
        return;
      }

      if (_values['selectedInfluencerType'] == null) {
        _showSnack("⚠️ Influencer Type is required.");
        return;
      }

      // Location & region
      if (_values['selectedRegion'] == null) {
        _showSnack("⚠️ Region is required.");
        return;
      }

      if (_controllers['area']!.text.trim().isEmpty) {
        _showSnack("⚠️ Area is required.");
        return;
      }

      if (_controllers['siteAddress']!.text.trim().isEmpty) {
        _showSnack("⚠️ Address is required.");
        return;
      }

      // Brands
      final List brands = _values['brandsInUse'] ?? [];
      if (brands.isEmpty) {
        _showSnack("⚠️ Please select at least one Brand in Use / Selling.");
        return;
      }

      // Conversion / Bag picked flow
      if (_values['isBagPicked'] == true) {
        if (_controllers['qty']!.text.trim().isEmpty) {
          _showSnack("⚠️ Quantity is required.");
          return;
        }

        if (_controllers['rate']!.text.trim().isEmpty) {
          _showSnack("⚠️ Rate per Bag is required.");
          return;
        }

        if (_values['supplyDate'] == null) {
          _showSnack("⚠️ Supply Date is mandatory when bags are picked.");
          return;
        }
      }
    }

    if (type.contains("Contractor/Head Mason ") ||
        type.contains("Engineer/Architect")) {
      if (_values['selectedInfluencerType'] == null) {
        _showSnack("⚠️ Influencer Type is required.");
        return;
      }

      if (_controllers['influencerName']!.text.trim().isEmpty) {
        _showSnack("⚠️ Influencer Name is required.");
        return;
      }

      if (_controllers['influencerPhone']!.text.trim().isEmpty) {
        _showSnack("⚠️ Influencer Phone is required.");
        return;
      }

      if (_values['selectedRegion'] == null) {
        _showSnack("⚠️ Region is required.");
        return;
      }

      if (_controllers['area']!.text.trim().isEmpty) {
        _showSnack("⚠️ Area is required.");
        return;
      }

      if (_controllers['siteAddress']!.text.trim().isEmpty) {
        _showSnack("⚠️ Address is required.");
        return;
      }

      if (_values['selectedVisitCategory'] == null) {
        _showSnack("⚠️ Visit Category is required.");
        return;
      }

      final List brands = _values['brandsInUse'] ?? [];
      if (brands.isEmpty) {
        _showSnack("⚠️ Please select at least one Preferred Brand.");
        return;
      }
    }

    // ---------------------------------------------------------
    // 2. CHECKOUT CAMERA (Blocking - User must do this)
    // ---------------------------------------------------------
    // We do NOT start any loaders here. Just open camera.
    final String? outPath = await Navigator.push(
      context,
      MaterialPageRoute(builder: (c) => const TvrCameraScreen()),
    );
    if (outPath == null) return; // User cancelled

    // ---------------------------------------------------------
    // 3. PREPARE DATA (Instant)
    // ---------------------------------------------------------
    final now = DateTime.now();
    final checkIn = _values['checkInTime'] as DateTime;
    final diff = now.difference(checkIn);

    // ⚠️ CRITICAL: We pass whatever we have.
    // If 'inTimeImageUrl' is null because background was slow, WE PASS NULL.
    // The worker will see it's null and upload the file instead.

    final payload = TechnicalVisitReport(
      userId: int.parse(widget.employee.id),
      reportDate: now,
      visitType: _values['selectedVisitType'] ?? 'Site Visit',
      visitCategory: _values['selectedVisitCategory'],
      customerType: _values['selectedCustomerType'],
      purposeOfVisit: _controllers['purposeOfVisit']?.text,
      siteNameConcernedPerson: _controllers['concernedPerson']?.text ?? '',
      phoneNo: _controllers['phone']?.text ?? '',
      whatsappNo: _controllers['whatsapp']?.text,
      siteAddress: _controllers['siteAddress']?.text,
      marketName: _controllers['marketName']?.text,
      region: _values['selectedRegion'],
      area: _controllers['area']?.text,
      latitude: _values['capturedLocation']?.latitude,
      longitude: _values['capturedLocation']?.longitude,
      siteVisitStage: _values['selectedStage'],
      constAreaSqFt: int.tryParse(_controllers['constArea']?.text ?? ''),
      siteVisitBrandInUse: _values['brandsInUse'] ?? [],
      currentBrandPrice: double.tryParse(_controllers['rate']?.text ?? ''),
      siteStock: double.tryParse(_controllers['siteStock']?.text ?? ''),
      estRequirement: double.tryParse(
        _controllers['estRequirement']?.text ?? '',
      ),
      supplyingDealerName: _controllers['supplyingDealer']?.text,
      nearbyDealerName: _controllers['nearbyDealer']?.text,
      associatedPartyName: _controllers['partyName']?.text,
      isConverted: _values['isConverted'],
      conversionType: _values['conversionType'],
      conversionFromBrand: _values['conversionFromBrand'],
      conversionQuantityValue: double.tryParse(_controllers['qty']?.text ?? ''),
      conversionQuantityUnit: _values['selectedUnit'],
      isTechService: _values['isTechService'],
      serviceType: _values['selectedServiceType'],
      serviceDesc: _controllers['serviceDesc']?.text,
      influencerName: _controllers['influencerName']?.text,
      influencerPhone: _controllers['influencerPhone']?.text,
      influencerProductivity: _controllers['productivity']?.text,
      isSchemeEnrolled: _values['isSchemeEnrolled'],
      influencerType: _values['selectedInfluencerType'] != null
          ? [_values['selectedInfluencerType']]
          : [],
      clientsRemarks: _controllers['remarks']?.text ?? '',
      salespersonRemarks: _controllers['remarks']?.text ?? '',
      checkInTime: checkIn,
      checkOutTime: now,
      timeSpentinLoc: '${diff.inHours}h ${diff.inMinutes.remainder(60)}m',

      // PASS DATA FOR WORKER TO RESOLVE
      inTimeImageUrl: _values['inTimeImageUrl'],
      outTimeImageUrl: null, // Worker will upload this
      sitePhotoUrl: _values['sitePhotoUrl'], // Worker will fix if null

      pjpId: widget.pjp?.id,
      masonId: _values['selectedMason']?.id,
      siteId: _values['selectedSite']?.id,
      siteVisitType: _values['selectedSiteVisitType'],
    );

    // Capture Files for the Worker
    final File? inTimeFile = _values['inTimeImageFile'];
    final File outTimeFile = File(outPath);
    final File? sitePhotoFile = _values['sitePhotoFile'];

    // ---------------------------------------------------------
    // 4. HANDOFF & EXIT (Optimistic)
    // ---------------------------------------------------------

    // Fire the independent worker
    TvrBackgroundWorker.processAndSubmit(
      apiService: _apiService,
      tvrPayload: payload,
      inTimeFile: inTimeFile,
      outTimeFile: outTimeFile,
      sitePhotoFile: sitePhotoFile,
      clearDrafts: true,
    );

    // Notify & Close Screen
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.cloud_upload, color: Colors.white),
              SizedBox(width: 10),
              Text("Report Saved! Uploading in background..."),
            ],
          ),
          backgroundColor: TvrConstants.accentGreen,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }

  bool _passesTimeLock() {
    final DateTime checkIn = _values['checkInTime'];
    final Duration diff = DateTime.now().difference(checkIn);

    const int minMinutes = 0;

    if (diff.inMinutes < minMinutes) {
      final remaining = minMinutes - diff.inMinutes;
      _showError(
        "Minimum $minMinutes minutes required. Wait $remaining minute(s).",
      );
      return false;
    }
    return true;
  }

  // bool _passesGeofence() {
  //   final Position pos = _values['capturedLocation'];
  //   final String type = _values['selectedCustomerType'];

  //   const double allowedMeters = 50;

  //   if (type == 'IHB/Site') {
  //     final site = _values['selectedSite'];
  //     if (site?.latitude == null || site?.longitude == null) return true;

  //     final meters = Geolocator.distanceBetween(
  //       pos.latitude,
  //       pos.longitude,
  //       site.latitude,
  //       site.longitude,
  //     );

  //     if (meters > allowedMeters) {
  //       _showError(
  //         "Geofence error: you are ${(meters / 1000).toStringAsFixed(2)} km away from site",
  //       );
  //       return false;
  //     }
  //   }

  //   if (type != null && type.contains("Dealer")) {
  //     final dealer = _values['selectedDealer'];
  //     if (dealer?.latitude == null || dealer?.longitude == null) return true;

  //     final meters = Geolocator.distanceBetween(
  //       pos.latitude,
  //       pos.longitude,
  //       dealer.latitude,
  //       dealer.longitude,
  //     );

  //     if (meters > allowedMeters) {
  //       _showError(
  //         "Geofence error: you are ${(meters / 1000).toStringAsFixed(2)} km away from dealer",
  //       );
  //       return false;
  //     }
  //   }

  //   return true;
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: TvrConstants.surfaceWhite,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildHeader(),
                  const Divider(height: 30),
                  if (_values['checkInTime'] == null) ...[
                    TvrDropdownField(
                      label: 'Type of Customer',
                      value: _values['selectedCustomerType'],
                      items: TvrConstants.customerTypeOptions,
                      onChanged: (v) => _onUpdate('selectedCustomerType', v),
                    ),
                    const SizedBox(height: 24),
                    _buildCheckInButton(),
                  ] else ...[
                    _buildVisitSummary(),
                    const SizedBox(height: 24),
                    _buildFormSwitcher(), // ⚡ Delegated to child widgets
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'TVR Report',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildCheckInButton() {
    return ElevatedButton.icon(
      onPressed: _values['isUploadingImage'] ? null : _handleCheckIn,
      icon: const Icon(Icons.camera_alt),
      label: const Text('CHECK-IN'),
      style: ElevatedButton.styleFrom(
        backgroundColor: TvrConstants.accentOrange,
        padding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildVisitSummary() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text("${_values['selectedCustomerType']} Check-in complete."),
    );
  }

  Future<void> _selectSupplyDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime(2099),
    );

    if (picked != null) {
      _onUpdate('supplyDate', picked);
    }
  }

  Widget _buildFormSwitcher() {
    final type = _values['selectedCustomerType'];

    if (type == 'IHB/Site') {
      return TvrIhbSection(
        controllers: _controllers,
        values: _values,
        onUpdate: _onUpdate,
        onSiteSearch: _openSiteSearch,
        onMasonSearch: _openMasonSearch,
        onLocationFetch: _fetchLocationAndAddress,
        onPickPhoto: _pickSitePhoto,
      );
    }

    if (type != null && type.contains("Dealer")) {
      return TvrDealerSection(
        controllers: _controllers,
        values: _values,
        onUpdate: _onUpdate,
        onDealerSearch: _openDealerSearch,
        onLocationFetch: _fetchLocationAndAddress,
        onPickPhoto: _pickSitePhoto,
        onSelectSupplyDate: _selectSupplyDate,
      );
    }

    // Influencer
    return TvrInfluencerSection(
      controllers: _controllers,
      values: _values,
      onUpdate: _onUpdate,
      onMasonSearch: _openMasonSearch,
      onLocationFetch: _fetchLocationAndAddress,
    );
  }

  Widget _buildSubmitButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- NEW TEXT LABEL ---
        const Padding(
          padding: EdgeInsets.only(bottom: 8.0),
          child: Center(
            child: Text(
              "Submit progress/update photo and Check Out",
              style: TextStyle(
                color: Color(0xFF111827), // Dark text color
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // --- BUTTON ---
        ElevatedButton(
          onPressed: _values['isSubmitting'] ? null : _submitTvr,
          style: ElevatedButton.styleFrom(
            backgroundColor: TvrConstants.accentGreen,
            padding: const EdgeInsets.all(16),
          ),
          child: _values['isSubmitting']
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'SUBMIT & CHECK-OUT',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }

  // --- SEARCH DIALOGS (Keep at bottom) ---
  void _openSiteSearch() async {
    final site = await showDialog<TechnicalSite>(
      context: context,
      builder: (c) => _ServerSiteSearchDialog(
        api: _apiService,
        userId: int.parse(widget.employee.id),
      ),
    );
    if (site != null) _onSiteSelected(site);
  }

  void _openDealerSearch() async {
    final dealer = await showDialog<Dealer>(
      context: context,
      builder: (c) => _ServerDealerSearchDialog(api: _apiService),
    );
    if (dealer != null) _onDealerSelected(dealer);
  }

  void _openMasonSearch() async {
    final mason = await showDialog<Mason>(
      context: context,
      builder: (c) => _ServerMasonSearchDialog(api: _apiService),
    );
    if (mason != null) _onMasonSelected(mason);
  }
}

// --- SEARCH DIALOGS ---
class _ServerSiteSearchDialog extends StatefulWidget {
  final ApiService api;
  final int userId;
  const _ServerSiteSearchDialog({required this.api, required this.userId});
  @override
  State<_ServerSiteSearchDialog> createState() =>
      _ServerSiteSearchDialogState();
}

class _ServerSiteSearchDialogState extends State<_ServerSiteSearchDialog> {
  List<TechnicalSite> _sites = [];
  bool _isLoading = false;
  Timer? _debounce;
  static const Color _textDark = Color(0xFF111827);
  static const Color _textGrey = Color(0xFF6B7280);
  static const Color _inputFill = Color(0xFFF9FAFB);
  void _search(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isLoading = true);
      try {
        final res = await widget.api.fetchTechnicalSites(
          userId: widget.userId,
          search: query,
        );
        if (mounted) setState(() => _sites = res);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _search("");
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        height: 400,
        width: double.maxFinite,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Site",
              style: TextStyle(
                color: _textDark,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              style: const TextStyle(color: _textDark),
              decoration: const InputDecoration(
                hintText: "Search site...",
                hintStyle: TextStyle(color: _textGrey),
                prefixIcon: Icon(Icons.search, color: _textGrey),
                filled: true,
                fillColor: _inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _search,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _sites.isEmpty
                  ? const Center(
                      child: Text(
                        "No sites found",
                        style: TextStyle(color: _textGrey),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _sites.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      itemBuilder: (ctx, i) => ListTile(
                        title: Text(
                          _sites[i].siteName,
                          style: const TextStyle(
                            color: _textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          "${_sites[i].address} • ${_sites[i].concernedPerson}",
                          style: const TextStyle(
                            color: _textGrey,
                            fontSize: 12,
                          ),
                        ),
                        onTap: () => Navigator.pop(context, _sites[i]),
                      ),
                    ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text("CANCEL", style: TextStyle(color: _textGrey)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServerMasonSearchDialog extends StatefulWidget {
  final ApiService api;
  const _ServerMasonSearchDialog({required this.api});
  @override
  State<_ServerMasonSearchDialog> createState() =>
      _ServerMasonSearchDialogState();
}

class _ServerMasonSearchDialogState extends State<_ServerMasonSearchDialog> {
  List<Mason> _masons = [];
  bool _isLoading = false;
  Timer? _debounce;
  static const Color _textDark = Color(0xFF111827);
  static const Color _textGrey = Color(0xFF6B7280);
  static const Color _inputFill = Color(0xFFF9FAFB);
  void _search(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isLoading = true);
      try {
        final res = await widget.api.fetchMasons(search: query);
        if (mounted) setState(() => _masons = res);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _search("");
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        height: 400,
        width: double.maxFinite,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Mason",
              style: TextStyle(
                color: _textDark,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              style: const TextStyle(color: _textDark),
              decoration: const InputDecoration(
                hintText: "Search mason...",
                hintStyle: TextStyle(color: _textGrey),
                prefixIcon: Icon(Icons.search, color: _textGrey),
                filled: true,
                fillColor: _inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _search,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _masons.isEmpty
                  ? const Center(
                      child: Text(
                        "No masons found",
                        style: TextStyle(color: _textGrey),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _masons.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      itemBuilder: (ctx, i) => ListTile(
                        title: Text(
                          _masons[i].name,
                          style: const TextStyle(
                            color: _textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          _masons[i].phoneNumber,
                          style: const TextStyle(
                            color: _textGrey,
                            fontSize: 12,
                          ),
                        ),
                        onTap: () => Navigator.pop(context, _masons[i]),
                      ),
                    ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text("CANCEL", style: TextStyle(color: _textGrey)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
  static const Color _textDark = Color(0xFF111827);
  static const Color _textGrey = Color(0xFF6B7280);
  static const Color _inputFill = Color(0xFFF9FAFB);

  @override
  void initState() {
    super.initState();
    _search("");
  }

  void _search(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isLoading = true);
      try {
        final res = await widget.api.fetchDealers(search: query, limit: 20);
        if (mounted) setState(() => _dealers = res);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        height: 400,
        width: double.maxFinite,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Dealer",
              style: TextStyle(
                color: _textDark,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              style: const TextStyle(color: _textDark),
              decoration: const InputDecoration(
                hintText: "Search dealer...",
                hintStyle: TextStyle(color: _textGrey),
                prefixIcon: Icon(Icons.search, color: _textGrey),
                filled: true,
                fillColor: _inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _search,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _dealers.isEmpty
                  ? const Center(
                      child: Text(
                        "No dealers found",
                        style: TextStyle(color: _textGrey),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _dealers.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      itemBuilder: (ctx, i) => ListTile(
                        title: Text(
                          _dealers[i].name,
                          style: const TextStyle(
                            color: _textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          "${_dealers[i].area} • ${_dealers[i].phoneNo}",
                          style: const TextStyle(
                            color: _textGrey,
                            fontSize: 12,
                          ),
                        ),
                        onTap: () => Navigator.pop(context, _dealers[i]),
                      ),
                    ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text("CANCEL", style: TextStyle(color: _textGrey)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
