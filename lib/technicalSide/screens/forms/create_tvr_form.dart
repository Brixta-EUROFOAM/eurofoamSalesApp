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

  // --- 🎨 PREMIUM THEME PALETTE ---
  final Color _bgLight = const Color(0xFFF8FAFC); // Slate 50
  final Color _cardNavy = const Color(0xFF0F172A); // Deep Navy
  //final Color _textDark = const Color(0xFF1E293B); // Slate 800
  final Color _surfaceWhite = Colors.white;
  final Color _accentGreen = const Color(0xFF10B981); // Emerald

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
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSnack(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.orangeAccent : _accentGreen,
        behavior: SnackBarBehavior.floating,
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
    _controllers.forEach((_, c) => c.dispose());
    super.dispose();
  }

  // --- 💾 RECOVERY SYSTEM ---
  void _onUpdate(String key, dynamic value) {
    setState(() => _values[key] = value);
    _saveDrafts();
  }

  Future<void> _saveDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    _controllers.forEach((key, c) => prefs.setString('tvr_ctrl_$key', c.text));
    prefs.setString('tvr_val_cust_type', _values['selectedCustomerType']);
    prefs.setBool('tvr_val_is_converted', _values['isConverted'] ?? false);
    prefs.setBool('tvr_val_is_bag_picked', _values['isBagPicked'] ?? false);
    if (_values['brandsInUse'] != null) {
      prefs.setStringList('tvr_val_brands', _values['brandsInUse']);
    }
  }

  Future<void> _loadDrafts() async {
    if (_values['selectedSite'] != null)
      _onSiteSelected(_values['selectedSite']);
    if (_values['selectedDealer'] != null)
      _onDealerSelected(_values['selectedDealer']);
    if (_values['selectedMason'] != null)
      _onMasonSelected(_values['selectedMason']);

    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('tvr_ctrl_remarks')) return;

    setState(() {
      _controllers.forEach(
        (key, c) => c.text = prefs.getString('tvr_ctrl_$key') ?? "",
      );
      _values['selectedCustomerType'] = prefs.getString('tvr_val_cust_type');
      _values['isConverted'] = prefs.getBool('tvr_val_is_converted') ?? false;
    });
  }

  // --- 🛑 LOCATION & CAMERA ---
  Future<void> _fetchLocationAndAddress() async {
    _onUpdate('isFetchingLocation', true);
    try {
      final Position? position = await _ensureLocationPermission();
      if (position == null) {
        _onUpdate('isFetchingLocation', false);
        return;
      }
      setState(() {
        _values['capturedLocation'] = position;
        _controllers['latitude']!.text = position.latitude.toStringAsFixed(6);
        _controllers['longitude']!.text = position.longitude.toStringAsFixed(6);
      });

      final addressDetails = await _apiService.reverseGeocodeWithRadar(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      setState(() {
        final String? foundAddress =
            addressDetails['address'] ??
            addressDetails['formattedAddress'] ??
            addressDetails['addressLabel'];
        if (foundAddress != null && foundAddress.isNotEmpty)
          _controllers['siteAddress']!.text = foundAddress;
        if (addressDetails['area'] != null)
          _controllers['area']!.text = addressDetails['area']!;
        if (addressDetails['region'] != null &&
            TvrConstants.regionOptions.contains(addressDetails['region'])) {
          _values['selectedRegion'] = addressDetails['region'];
        }
      });

      _saveDrafts();
      _showSnack("Location Updated", isError: false);
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
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.location_on),
                SizedBox(width: 8),
                Text("Location Access"),
              ],
            ),
            content: const Text(
              "To verify this visit, the app needs your location.\n\n",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("DENY"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cardNavy,
                  foregroundColor: Colors.white,
                ),
                child: const Text("ALLOW"),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<Position?> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError("Please enable GPS to continue.");
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final bool userAccepted = await _showLocationDisclosureDialog();
      if (!userAccepted) {
        _showError("Location permission is required.");
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

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      return await Geolocator.getLastKnownPosition();
    }
  }

  void _showLocationSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Permission Required"),
        content: const Text(
          "Location permission is permanently denied. Enable it in App Settings.",
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
    if (_values['selectedCustomerType'] == null) {
      _showSnack("⚠️ Please select a Customer Type first.");
      return;
    }
    final String? imagePath = await Navigator.push(
      context,
      MaterialPageRoute(builder: (c) => const TvrCameraScreen()),
    );
    if (imagePath == null) return;

    final File imageFile = File(imagePath);
    final DateTime now = DateTime.now();

    setState(() {
      _values['checkInTime'] = now;
      _values['inTimeImageFile'] = imageFile;
      _values['isCheckInProcessing'] = true;
      _values['checkInFailed'] = false;
    });

    _saveDrafts();
    _processCheckInInBackground(imageFile);
  }

  Future<void> _processCheckInInBackground(File imageFile) async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _values['capturedLocation'] = pos;
          _controllers['latitude']!.text = pos.latitude.toStringAsFixed(6);
          _controllers['longitude']!.text = pos.longitude.toStringAsFixed(6);
        });
      }
      final url = await _apiService.uploadImageToR2(imageFile);
      if (mounted) {
        setState(() {
          _values['inTimeImageUrl'] = url;
          _values['isCheckInUploading'] = false;
        });
      }
    } catch (e) {
      debugPrint("Background Check-in Failed: $e");
      if (mounted) {
        setState(() {
          _values['isCheckInUploading'] = false;
          _values['checkInUploadFailed'] = true;
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
    _onUpdate('sitePhotoFile', file);

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
      if (site.latitude != 0.0)
        _controllers['latitude']!.text = site.latitude.toStringAsFixed(6);
      if (site.longitude != 0.0)
        _controllers['longitude']!.text = site.longitude.toStringAsFixed(6);
      if (site.region != null &&
          TvrConstants.regionOptions.contains(site.region))
        _values['selectedRegion'] = site.region;
      if (site.stageOfConstruction != null &&
          TvrConstants.stageOptions.contains(site.stageOfConstruction))
        _values['selectedStage'] = site.stageOfConstruction;
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
      if (dealer.latitude != null)
        _controllers['latitude']!.text = dealer.latitude!.toStringAsFixed(6);
      if (dealer.longitude != null)
        _controllers['longitude']!.text = dealer.longitude!.toStringAsFixed(6);
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
  Future<void> _submitTvr() async {
    if (!_formKey.currentState!.validate()) {
      _showSnack("Please fill in required fields.");
      return;
    }
    if (_values['checkInTime'] == null) {
      _showSnack("Check-in is required");
      return;
    }
    if (!_passesTimeLock()) return;

    // --- MANUAL VALIDATIONS ---
    final String type = _values['selectedCustomerType'] ?? '';
    if (type.isEmpty) {
      _showSnack("Select Customer Type.");
      return;
    }

    if (type == 'IHB/Site') {
      if (_values['selectedVisitType'] == null) {
        _showSnack("Select Visit Type.");
        return;
      }
      if (_values['selectedSiteVisitType'] == null) {
        _showSnack("Select Site Visit Type.");
        return;
      }
      if (_values['selectedVisitCategory'] == null) {
        _showSnack("Select Visit Category.");
        return;
      }
      if (_controllers['partyName']!.text.isEmpty) {
        _showSnack("Site Owner Name required.");
        return;
      }
      if (_controllers['whatsapp']!.text.isEmpty) {
        _showSnack("Phone/WhatsApp required.");
        return;
      }
      if (_values['selectedRegion'] == null) {
        _showSnack("Region required.");
        return;
      }
      if (_controllers['area']!.text.isEmpty) {
        _showSnack("Area required.");
        return;
      }
      if (_controllers['siteAddress']!.text.isEmpty) {
        _showSnack("Address required.");
        return;
      }
      if (_controllers['marketName']!.text.isEmpty) {
        _showSnack("Market Name required.");
        return;
      }
      if (_controllers['constArea']!.text.isEmpty) {
        _showSnack("Construction Area required.");
        return;
      }
      if (_values['selectedStage'] == null) {
        _showSnack("Stage required.");
        return;
      }
      if ((_values['brandsInUse'] ?? []).isEmpty) {
        _showSnack("Select Brand in Use.");
        return;
      }
      if (_controllers['siteStock']!.text.isEmpty) {
        _showSnack("Site Stock required.");
        return;
      }
      if (_controllers['estRequirement']!.text.isEmpty) {
        _showSnack("Estimated Requirement required.");
        return;
      }

      if (_values['isConverted'] == true) {
        if (_values['conversionType'] == null) {
          _showSnack("Select Conversion Type.");
          return;
        }
        if (_values['conversionFromBrand'] == null) {
          _showSnack("Select From Brand.");
          return;
        }
        if (_controllers['qty']!.text.isEmpty) {
          _showSnack("Enter Conversion Qty.");
          return;
        }
        if (_values['selectedUnit'] == null) {
          _showSnack("Select Unit.");
          return;
        }
        if (_controllers['nearbyDealer']!.text.isEmpty) {
          _showSnack("Converted Brand Dealer required.");
          return;
        }
      }
      if (_values['isTechService'] == true &&
          _values['selectedServiceType'] == null) {
        _showSnack("Select Service Type.");
        return;
      }
      if (_values['selectedInfluencerType'] == null) {
        _showSnack("Influencer Type required.");
        return;
      }
      if (_controllers['influencerName']!.text.isEmpty) {
        _showSnack("Influencer Name required.");
        return;
      }
      if (_controllers['influencerPhone']!.text.isEmpty) {
        _showSnack("Influencer Phone required.");
        return;
      }
    }

    if (_controllers['remarks']!.text.isEmpty) {
      _showSnack("Remarks required.");
      return;
    }

    if (type.contains("Dealer")) {
      if (_controllers['partyName']!.text.isEmpty) {
        _showSnack("Dealer Name required.");
        return;
      }
      if (_controllers['phone']!.text.isEmpty) {
        _showSnack("Phone required.");
        return;
      }
      if (_values['selectedVisitCategory'] == null) {
        _showSnack("Visit Category required.");
        return;
      }
      if (_values['selectedInfluencerType'] == null) {
        _showSnack("Influencer Type required.");
        return;
      }
      if (_values['selectedRegion'] == null) {
        _showSnack("Region required.");
        return;
      }
      if (_controllers['area']!.text.isEmpty) {
        _showSnack("Area required.");
        return;
      }
      if (_controllers['siteAddress']!.text.isEmpty) {
        _showSnack("Address required.");
        return;
      }
      if ((_values['brandsInUse'] ?? []).isEmpty) {
        _showSnack("Select Brand.");
        return;
      }
      if (_values['isBagPicked'] == true) {
        if (_controllers['qty']!.text.isEmpty) {
          _showSnack("Qty required.");
          return;
        }
        if (_controllers['rate']!.text.isEmpty) {
          _showSnack("Rate required.");
          return;
        }
        if (_values['supplyDate'] == null) {
          _showSnack("Supply Date required.");
          return;
        }
      }
    }

    if (type.contains("Contractor") || type.contains("Engineer")) {
      if (_values['selectedInfluencerType'] == null) {
        _showSnack("Influencer Type required.");
        return;
      }
      if (_controllers['influencerName']!.text.isEmpty) {
        _showSnack("Name required.");
        return;
      }
      if (_controllers['influencerPhone']!.text.isEmpty) {
        _showSnack("Phone required.");
        return;
      }
      if (_values['selectedRegion'] == null) {
        _showSnack("Region required.");
        return;
      }
      if (_controllers['area']!.text.isEmpty) {
        _showSnack("Area required.");
        return;
      }
      if (_controllers['siteAddress']!.text.isEmpty) {
        _showSnack("Address required.");
        return;
      }
      if (_values['selectedVisitCategory'] == null) {
        _showSnack("Visit Category required.");
        return;
      }
      if ((_values['brandsInUse'] ?? []).isEmpty) {
        _showSnack("Select Brand.");
        return;
      }
    }

    // --- CHECKOUT CAMERA ---
    final String? outPath = await Navigator.push(
      context,
      MaterialPageRoute(builder: (c) => const TvrCameraScreen()),
    );
    if (outPath == null) {
      _showSnack("Checkout photo mandatory.");
      return;
    }

    try {
      setState(() => _values['isSubmitting'] = true);
      final now = DateTime.now();
      final checkIn = _values['checkInTime'] as DateTime;
      final diff = now.difference(checkIn);
      final int uId = int.tryParse(widget.employee.id.toString()) ?? 0;
      final List<String> safeBrands = List<String>.from(
        _values['brandsInUse'] ?? [],
      );
      final List<String> safeInfluencerType =
          _values['selectedInfluencerType'] != null
          ? [_values['selectedInfluencerType'].toString()]
          : <String>[];

      final payload = TechnicalVisitReport(
        userId: uId,
        reportDate: now,
        visitType: _values['selectedVisitType'] ?? 'Non-Site Visit',
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
        siteVisitBrandInUse: safeBrands,
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
        conversionQuantityValue: double.tryParse(
          _controllers['qty']?.text ?? '',
        ),
        conversionQuantityUnit: _values['selectedUnit'],
        isTechService: _values['isTechService'],
        serviceType: _values['selectedServiceType'],
        serviceDesc: _controllers['serviceDesc']?.text,
        influencerName: _controllers['influencerName']?.text,
        influencerPhone: _controllers['influencerPhone']?.text,
        influencerProductivity: _controllers['productivity']?.text,
        isSchemeEnrolled: _values['isSchemeEnrolled'],
        influencerType: safeInfluencerType,
        clientsRemarks: _controllers['remarks']?.text ?? '',
        salespersonRemarks: _controllers['remarks']?.text ?? '',
        checkInTime: checkIn,
        checkOutTime: now,
        timeSpentinLoc: '${diff.inHours}h ${diff.inMinutes.remainder(60)}m',
        inTimeImageUrl: _values['inTimeImageUrl'],
        outTimeImageUrl: null,
        sitePhotoUrl: _values['sitePhotoUrl'],
        pjpId: widget.pjp?.id,
        masonId: _values['selectedMason']?.id,
        siteId: _values['selectedSite']?.id,
        siteVisitType: _values['selectedSiteVisitType'],
      );

      final File? inTimeFile = _values['inTimeImageFile'];
      final File outTimeFile = File(outPath);
      final File? sitePhotoFile = _values['sitePhotoFile'];

      await TvrBackgroundWorker.processAndSubmit(
        apiService: _apiService,
        tvrPayload: payload,
        inTimeFile: inTimeFile,
        outTimeFile: outTimeFile,
        sitePhotoFile: sitePhotoFile,
        clearDrafts: true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.cloud_upload, color: Colors.white),
                SizedBox(width: 10),
                Text("Report Saved! Uploading..."),
              ],
            ),
            backgroundColor: _accentGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _values['isSubmitting'] = false);
        _showError("Failed: $e");
      }
    }
  }

  bool _passesTimeLock() {
    final DateTime checkIn = _values['checkInTime'];
    final Duration diff = DateTime.now().difference(checkIn);
    const int minMinutes = 0;
    if (diff.inMinutes < minMinutes) {
      _showError(
        "Minimum $minMinutes minutes required. Wait ${minMinutes - diff.inMinutes} minute(s).",
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: _bgLight,
        elevation: 0,
        title: const Text(
          'New TVR Report',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _surfaceWhite,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
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
                  _buildFormSwitcher(),
                  const SizedBox(height: 32),
                  _buildSubmitButton(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckInButton() {
    return ElevatedButton.icon(
      onPressed: _values['isUploadingImage'] ? null : _handleCheckIn,
      icon: const Icon(Icons.camera_alt_outlined),
      label: const Text('Start Visit & Check-In'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _cardNavy,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildVisitSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _accentGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: _accentGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Checked In",
                  style: TextStyle(
                    color: _cardNavy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${_values['selectedCustomerType']} Visit Active",
                  style: TextStyle(
                    color: _cardNavy.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectSupplyDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime(2099),
    );
    if (picked != null) _onUpdate('supplyDate', picked);
  }

  Widget _buildFormSwitcher() {
    final type = _values['selectedCustomerType'];
    if (type == 'IHB/Site'){
      return TvrIhbSection(
        controllers: _controllers,
        values: _values,
        onUpdate: _onUpdate,
        onSiteSearch: _openSiteSearch,
        onMasonSearch: _openMasonSearch,
        onLocationFetch: _fetchLocationAndAddress,
        onPickPhoto: _pickSitePhoto,
      );}
    if (type != null && type.contains("Dealer")){
      return TvrDealerSection(
        controllers: _controllers,
        values: _values,
        onUpdate: _onUpdate,
        onDealerSearch: _openDealerSearch,
        onLocationFetch: _fetchLocationAndAddress,
        onPickPhoto: _pickSitePhoto,
        onSelectSupplyDate: _selectSupplyDate,
      );}
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
        const Padding(
          padding: EdgeInsets.only(bottom: 8.0),
          child: Center(
            child: Text(
              "Take Checkout Photo to Submit",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _values['isSubmitting'] ? null : _submitTvr,
          style: ElevatedButton.styleFrom(
            backgroundColor: _accentGreen,
            padding: const EdgeInsets.all(18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
                  'SUBMIT REPORT',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
        ),
      ],
    );
  }

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

// --- SEARCH DIALOGS (Polished) ---
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        height: 500,
        width: double.maxFinite,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Site",
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: "Search...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _sites.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (ctx, i) => ListTile(
                        title: Text(
                          _sites[i].siteName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text("${_sites[i].address}"),
                        onTap: () => Navigator.pop(context, _sites[i]),
                      ),
                    ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text("CLOSE"),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        height: 500,
        width: double.maxFinite,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Mason",
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: "Search...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _masons.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (ctx, i) => ListTile(
                        title: Text(
                          _masons[i].name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(_masons[i].phoneNumber),
                        onTap: () => Navigator.pop(context, _masons[i]),
                      ),
                    ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text("CLOSE"),
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
  void initState() {
    super.initState();
    _search("");
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        height: 500,
        width: double.maxFinite,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Dealer",
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: "Search...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _dealers.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (ctx, i) => ListTile(
                        title: Text(
                          _dealers[i].name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text("${_dealers[i].area}"),
                        onTap: () => Navigator.pop(context, _dealers[i]),
                      ),
                    ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text("CLOSE"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
