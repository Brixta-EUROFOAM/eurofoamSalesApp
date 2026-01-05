// lib/technicalSide/screens/forms/create_tvr_form.dart
import 'dart:io';
import 'dart:async';
import 'dart:convert'; // Added for Object Serialization (RAM Recovery)
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/technicalSide/models/technical_visit_report_model.dart';
import 'package:salesmanapp/models/employee_model.dart';
import 'package:salesmanapp/models/pjp_model.dart';
import 'package:salesmanapp/technicalSide/models/sites_model.dart';
import 'package:salesmanapp/technicalSide/models/mason_pc_model.dart';
import 'package:salesmanapp/models/dealer_model.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camera/camera.dart';


// ---------------------------------------------------------------------------
// 🟢 INTERNAL CAMERA SCREEN (Copy to bottom of technical_dashboard_screen.dart)
// ---------------------------------------------------------------------------
class _InlineCameraScreen extends StatefulWidget {
  const _InlineCameraScreen();

  @override
  State<_InlineCameraScreen> createState() => _InlineCameraScreenState();
}

class _InlineCameraScreenState extends State<_InlineCameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isTakingPicture = false;
  
  // ⚡ NEW: Store list of cameras to enable switching
  List<CameraDescription> _cameras = [];
  int _selectedCameraIdx = 0;

  @override
  void initState() {
    super.initState();
    _setupCameras();
  }

  // 1. One-time setup: Get all cameras and find the selfie one
  Future<void> _setupCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      // Find the index of the front camera, or default to 0 (back)
      _selectedCameraIdx = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front
      );
      
      if (_selectedCameraIdx == -1) _selectedCameraIdx = 0;

      // Initialize the selected camera
      _initCamera(_cameras[_selectedCameraIdx]);
    } catch (e) {
      debugPrint("Camera setup error: $e");
    }
  }

  // 2. Init specific camera (Re-used when flipping)
  Future<void> _initCamera(CameraDescription cameraDescription) async {
    // If a controller exists, dispose it cleanly before creating a new one
    if (_controller != null) {
      await _controller!.dispose();
    }

    _controller = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    setState(() {
      _initializeControllerFuture = _controller!.initialize();
    });
  }

  // 3. The Flip Logic
  void _toggleCamera() {
    if (_cameras.length < 2) return;

    final newIndex = (_selectedCameraIdx + 1) % _cameras.length;
    _selectedCameraIdx = newIndex;
    _initCamera(_cameras[_selectedCameraIdx]);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isTakingPicture) {
      return;
    }

    try {
      setState(() => _isTakingPicture = true);
      // Optional: Turn flash off to avoid crashes on some low-end devices
      await _controller!.setFlashMode(FlashMode.off);

      final image = await _controller!.takePicture();
      
      if (!mounted) return;
      Navigator.pop(context, image.path); 
    } catch (e) {
      debugPrint("Capture error: $e");
    } finally {
      if (mounted) setState(() => _isTakingPicture = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && _controller != null) {
            return Stack(
              children: [
                // 1. Camera Preview
                Center(child: CameraPreview(_controller!)),
                
                // 2. Controls Overlay
                SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // --- TOP BAR: Close & Flip ---
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Close Button
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white, size: 30),
                              onPressed: () => Navigator.pop(context),
                            ),
                            
                            // Flip Button (Hidden if only 1 camera exists)
                            if (_cameras.length > 1)
                              IconButton(
                                icon: const Icon(
                                  Icons.flip_camera_ios_outlined, 
                                  color: Colors.white, 
                                  size: 30
                                ),
                                onPressed: _toggleCamera,
                              ),
                          ],
                        ),
                      ),

                      // --- BOTTOM BAR: Shutter Button ---
                      Padding(
                        padding: const EdgeInsets.only(bottom: 30),
                        child: InkWell(
                          onTap: _takePicture,
                          child: Container(
                            height: 80, 
                            width: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              color: _isTakingPicture ? Colors.white : Colors.white24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
        },
      ),
    );
  }
}

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
  final _imagePicker = ImagePicker();

  // --- CONTROLLERS ---
  final _siteNameConcernedPersonController = TextEditingController();
  final _phoneNoController = TextEditingController();
  final _whatsappNoController = TextEditingController();
  final _associatedPartyNameController = TextEditingController();
  final _salespersonRemarksController = TextEditingController();
  final _conversionQuantityValueController = TextEditingController();
  final _qualityComplaintController = TextEditingController();

  final _siteAddressController = TextEditingController();
  final _marketNameController = TextEditingController();
  final _purposeOfVisitController = TextEditingController();
  final _constAreaSqFtController = TextEditingController();
  final _currentBrandPriceController = TextEditingController();
  final _siteStockController = TextEditingController();
  final _estRequirementController = TextEditingController();
  final _supplyingDealerNameController = TextEditingController();
  final _nearbyDealerNameController = TextEditingController();
  final _serviceDescController = TextEditingController();
  final _dhalaiVerificationCodeController = TextEditingController();

  final _influencerNameController = TextEditingController();
  final _influencerPhoneController = TextEditingController();
  final _influencerProductivityController = TextEditingController();

  // Lat/Long Display Controllers
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  final _areaController = TextEditingController();

  // --- STATE ---
  bool _isSubmitting = false;
  bool _isUploadingImage = false;
  bool _isFetchingLocation = false;

  // Selection
  TechnicalSite? _selectedSite;
  Mason? _selectedMason;
  Dealer? _selectedDealer;

  // Dropdowns
  String? _selectedVisitType = 'Site Visit';
  String? _selectedVisitCategory;

  String? _selectedCustomerType;

  String? _selectedConversionType;
  String? _selectedConversionUnit;
  String? _selectedConversionFromBrand;

  String? _selectedStage;
  String? _selectedSiteVisitType;
  List<String> _selectedBrandsInUse = [];

  String? _selectedServiceType;
  String? _selectedTechActivity;
  String? _selectedInfluencerType;

  // Region Dropdown State
  String? _selectedRegion;

  // Booleans
  bool _isConverted = false;
  bool _isTechService = false;
  bool _isSchemeEnrolled = false;

  // Dealer Specific
  bool _isBagPicked = false;
  DateTime? _supplyDate;

  // Check-In Data & Images
  DateTime? _checkInTime;
  File? _inTimeImageFile;
  String? _inTimeImageUrl;
  Position? _capturedLocation;
  File? _sitePhotoFile;

  // --- DROPDOWN DATA LISTS ---
  // form options
  final List<String> _customerTypeOptions = [
    'IHB/Site',
    'Engineer/Architect',
    'Contractor/Head Mason',
    'Channel Partner(Dealer/Sub-Dealer)',
    'Competitor Channel Partner (Dealer/Sub-Dealer)',
  ];
  //--------------
  final List<String> _stageOptions = [
    'Foundation',
    'Plinth Level',
    'Brick Work',
    'Column Work',
    'Lintel Work',
    'Slab Work',
    'Plaster Work',
  ];
  final List<String> _brandOptions = [
    'Best',
    'Star',
    'Dalmia',
    'Black Tiger',
    'Topcem',
    'Taj',
    'Amrit',
    'Max',
    'Ambuja',
    'ACC',
    'other',
  ];
  final List<String> _serviceTypeOptions = [
    'Slab Supervision',
    'CTV Demo Cube Cast',
    'NDT',
    'Good Construction Practices',
  ];
  final List<String> _techActivityOptions = [
    'Site Visit',
    'IHB Meet',
    'Contractor/Mason Meet',
    'Consumer Awareness Camp',
  ];
  final List<String> _influencerTypeOptions = [
    'Mason',
    'Contractor',
    'Engineer/Architect',
    'Builder',
    'Dealer',
  ];

  // Consolidated Visit Category
  final List<String> _visitCategoryOptions = ['New', 'Follow Up'];

  final List<String> _regionOptions = [
    "All Region",
    "Kamrup",
    "Upper Assam",
    "Lower Assam",
    "Central Assam",
    "Barak Valley",
    "North Bank",
    "Meghalaya",
    "Mizoram",
    "Nagaland",
    "Tripura",
  ];

  // --- THEME ---
  static const Color _surfaceWhite = Colors.white;
  static const Color _cardNavy = Color(0xFF0F172A);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textGrey = Color(0xFF6B7280);
  static const Color _inputFill = Color(0xFFF9FAFB);
  static const Color _accentGreen = Color(0xFF10B981);
  static const Color _accentOrange = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    if (widget.site != null) {
      _onSiteSelected(widget.site!);
    }
    if (widget.initialCheckInTime != null) {
      _checkInTime = widget.initialCheckInTime;
    }
    // Pre-fill region from employee if matches
    if (widget.employee.region != null &&
        _regionOptions.contains(widget.employee.region)) {
      _selectedRegion = widget.employee.region;
    }

    // ⚡ RAM RECOVERY LOGIC
    WidgetsBinding.instance.addPostFrameCallback((_) async {
       await _loadDrafts();
       await _checkLostData();
    });
  }

  // --- 💾 RECOVERY SYSTEM ---
  
  // 1. Save state to disk
  Future<void> _saveDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save Controllers
    await prefs.setString('tvr_party_name', _associatedPartyNameController.text);
    await prefs.setString('tvr_phone', _phoneNoController.text);
    await prefs.setString('tvr_whatsapp', _whatsappNoController.text);
    await prefs.setString('tvr_address', _siteAddressController.text);
    await prefs.setString('tvr_area', _areaController.text);
    await prefs.setString('tvr_remarks', _salespersonRemarksController.text);
    await prefs.setString('tvr_purpose', _purposeOfVisitController.text);
    await prefs.setString('tvr_market', _marketNameController.text);
    await prefs.setString('tvr_const_area', _constAreaSqFtController.text);
    await prefs.setString('tvr_est_req', _estRequirementController.text);
    await prefs.setString('tvr_brand_price', _currentBrandPriceController.text);
    await prefs.setString('tvr_site_stock', _siteStockController.text);
    await prefs.setString('tvr_qty', _conversionQuantityValueController.text);

    // Save Dropdowns & Dates
    if (_selectedCustomerType != null) await prefs.setString('tvr_cust_type', _selectedCustomerType!);
    if (_selectedVisitCategory != null) await prefs.setString('tvr_visit_cat', _selectedVisitCategory!);
    if (_selectedVisitType != null) await prefs.setString('tvr_visit_type', _selectedVisitType!);
    if (_selectedSiteVisitType != null) await prefs.setString('tvr_site_visit_type', _selectedSiteVisitType!);
    if (_selectedRegion != null) await prefs.setString('tvr_region', _selectedRegion!);
    if (_selectedStage != null) await prefs.setString('tvr_stage', _selectedStage!);
    if (_selectedInfluencerType != null) await prefs.setString('tvr_influencer_type', _selectedInfluencerType!);
    if (_selectedServiceType != null) await prefs.setString('tvr_service_type', _selectedServiceType!);
    if (_selectedTechActivity != null) await prefs.setString('tvr_tech_activity', _selectedTechActivity!);
    if (_supplyDate != null) await prefs.setString('tvr_supply_date', _supplyDate!.toIso8601String());

    // Save Objects (JSON) - Crucial for recovery
    if (_selectedSite != null) {
      await prefs.setString('tvr_selected_site_obj', jsonEncode(_selectedSite!.toJson()));
    }
    if (_selectedMason != null) {
      await prefs.setString('tvr_selected_mason_obj', jsonEncode(_selectedMason!.toJson()));
    }
    if (_selectedDealer != null) {
      await prefs.setString('tvr_selected_dealer_obj', jsonEncode(_selectedDealer!.toJson()));
    }

    // Save Lists
    await prefs.setStringList('tvr_brands_in_use', _selectedBrandsInUse);
    
    // Save Booleans
    await prefs.setBool('tvr_is_converted', _isConverted);
    await prefs.setBool('tvr_is_bag_picked', _isBagPicked);
    await prefs.setBool('tvr_is_tech_service', _isTechService);
    await prefs.setBool('tvr_is_scheme_enrolled', _isSchemeEnrolled);
  }

  // 2. Load state from disk
  Future<void> _loadDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Only load if we have data to avoid overwriting init logic
    if (prefs.containsKey('tvr_party_name')) {
      setState(() {
        // Restore Controllers
        _associatedPartyNameController.text = prefs.getString('tvr_party_name') ?? "";
        _phoneNoController.text = prefs.getString('tvr_phone') ?? "";
        _whatsappNoController.text = prefs.getString('tvr_whatsapp') ?? "";
        _siteAddressController.text = prefs.getString('tvr_address') ?? "";
        _areaController.text = prefs.getString('tvr_area') ?? "";
        _salespersonRemarksController.text = prefs.getString('tvr_remarks') ?? "";
        _purposeOfVisitController.text = prefs.getString('tvr_purpose') ?? "";
        _marketNameController.text = prefs.getString('tvr_market') ?? "";
        _constAreaSqFtController.text = prefs.getString('tvr_const_area') ?? "";
        _estRequirementController.text = prefs.getString('tvr_est_req') ?? "";
        _currentBrandPriceController.text = prefs.getString('tvr_brand_price') ?? "";
        _siteStockController.text = prefs.getString('tvr_site_stock') ?? "";
        _conversionQuantityValueController.text = prefs.getString('tvr_qty') ?? "";

        // Restore Dropdowns
        _selectedCustomerType = prefs.getString('tvr_cust_type');
        _selectedVisitCategory = prefs.getString('tvr_visit_cat');
        _selectedVisitType = prefs.getString('tvr_visit_type');
        _selectedSiteVisitType = prefs.getString('tvr_site_visit_type');
        _selectedRegion = prefs.getString('tvr_region');
        _selectedStage = prefs.getString('tvr_stage');
        _selectedInfluencerType = prefs.getString('tvr_influencer_type');
        _selectedServiceType = prefs.getString('tvr_service_type');
        _selectedTechActivity = prefs.getString('tvr_tech_activity');

        if (prefs.containsKey('tvr_supply_date')) {
          _supplyDate = DateTime.tryParse(prefs.getString('tvr_supply_date')!);
        }

        // Restore Objects
        if (prefs.containsKey('tvr_selected_site_obj')) {
          try {
            final json = jsonDecode(prefs.getString('tvr_selected_site_obj')!);
            _selectedSite = TechnicalSite.fromJson(json);
          } catch (e) { debugPrint("Error restoring site: $e"); }
        }
        if (prefs.containsKey('tvr_selected_mason_obj')) {
          try {
            final json = jsonDecode(prefs.getString('tvr_selected_mason_obj')!);
            _selectedMason = Mason.fromJson(json);
          } catch (e) { debugPrint("Error restoring mason: $e"); }
        }
        if (prefs.containsKey('tvr_selected_dealer_obj')) {
          try {
             final json = jsonDecode(prefs.getString('tvr_selected_dealer_obj')!);
             _selectedDealer = Dealer.fromJson(json); 
          } catch (e) { debugPrint("Error restoring dealer: $e"); }
        }

        _selectedBrandsInUse = prefs.getStringList('tvr_brands_in_use') ?? [];

        // Restore Booleans
        _isConverted = prefs.getBool('tvr_is_converted') ?? false;
        _isBagPicked = prefs.getBool('tvr_is_bag_picked') ?? false;
        _isTechService = prefs.getBool('tvr_is_tech_service') ?? false;
        _isSchemeEnrolled = prefs.getBool('tvr_is_scheme_enrolled') ?? false;
      });
    }
  }

  // 3. Clear drafts after submit
  Future<void> _clearDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Or remove specific keys
  }

  // 4. Recover Lost Image (The Process Death Fix)
  Future<void> _checkLostData() async {
    final LostDataResponse response = await _imagePicker.retrieveLostData();
    if (response.isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();

    if (response.file != null) {
      final action = prefs.getString('pending_camera_action');

      setState(() {
        if (action == 'check_in') {
          _inTimeImageFile = File(response.file!.path);
          _handleRecoveryCheckIn(); // Auto upload and fetch GPS
        } else if (action == 'site_photo') {
          _sitePhotoFile = File(response.file!.path);
          showSnack("Site photo restored.", backgroundColor: _accentGreen);
        }
      });
      // Clear the flag so we don't process it again
      await prefs.remove('pending_camera_action');
    }
  }

  // Helper for check-in recovery
  Future<void> _handleRecoveryCheckIn() async {
      setState(() => _isUploadingImage = true);
      try {
        if (_inTimeImageFile != null) {
          final imageUrl = await _apiService.uploadImageToR2(_inTimeImageFile!);
          final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
          
          if(mounted) {
            setState(() {
              _inTimeImageUrl = imageUrl;
              _checkInTime = DateTime.now(); // Reset time to now
              _capturedLocation = position;
              _latitudeController.text = position.latitude.toStringAsFixed(6);
              _longitudeController.text = position.longitude.toStringAsFixed(6);
              _isUploadingImage = false;
            });
            showSnack("Check-in Restored Successfully", backgroundColor: _accentGreen);
          }
        }
      } catch(e) {
        if(mounted) setState(() => _isUploadingImage = false);
      }
  }

  @override
  void dispose() {
    _siteNameConcernedPersonController.dispose();
    _phoneNoController.dispose();
    _whatsappNoController.dispose();
    _associatedPartyNameController.dispose();
    _salespersonRemarksController.dispose();
    _conversionQuantityValueController.dispose();
    _qualityComplaintController.dispose();
    _siteAddressController.dispose();
    _marketNameController.dispose();
    _purposeOfVisitController.dispose();
    _constAreaSqFtController.dispose();
    _currentBrandPriceController.dispose();
    _siteStockController.dispose();
    _estRequirementController.dispose();
    _supplyingDealerNameController.dispose();
    _nearbyDealerNameController.dispose();
    _serviceDescController.dispose();
    _dhalaiVerificationCodeController.dispose();
    _influencerNameController.dispose();
    _influencerPhoneController.dispose();
    _influencerProductivityController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  void _onSiteSelected(TechnicalSite site) {
    setState(() {
      _selectedSite = site;
      _siteNameConcernedPersonController.text = site.concernedPerson;
      _phoneNoController.text = site.phoneNo;
      _siteAddressController.text = site.address;
      _areaController.text = site.area ?? '';
      if (site.region != null && _regionOptions.contains(site.region)) {
        _selectedRegion = site.region;
      }
      if (site.stageOfConstruction != null &&
          _stageOptions.contains(site.stageOfConstruction)) {
        _selectedStage = site.stageOfConstruction;
      }
    });
    _saveDrafts();
  }

  void _onMasonSelected(Mason mason) {
    setState(() {
      _selectedMason = mason;
      _influencerNameController.text = mason.name;
      _influencerPhoneController.text = mason.phoneNumber;
    });
    _saveDrafts();
  }

  void _onDealerSelected(Dealer dealer) {
    setState(() {
      _selectedDealer = dealer;
      // Auto-fill form fields
      _associatedPartyNameController.text = dealer.name;
      _phoneNoController.text = dealer.phoneNo;
      _siteAddressController.text = dealer.address;
      _areaController.text = dealer.area;
      if (_regionOptions.contains(dealer.region)) {
        _selectedRegion = dealer.region;
      }
    });
    _saveDrafts();
  }

  // --- 🛑 PLAY STORE COMPLIANT LOCATION LOGIC ---
  Future<Position?> _ensureLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Check GPS
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      showSnack(
        "Location services are disabled. Please enable GPS.",
        backgroundColor: Colors.red,
      );
      return null;
    }

    // 2. Check Permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // 3. SHOW PROMINENT DISCLOSURE (Crucial for Play Store)
      if (!mounted) return null;
      final bool userAgreed = await _showLocationDisclosureDialog();

      if (!userAgreed) {
        showSnack(
          "Location is required to verify Site Visit.",
          backgroundColor: Colors.orange,
        );
        return null;
      }

      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        showSnack("Location permission denied.", backgroundColor: Colors.red);
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) _showSettingsDialog();
      return null;
    }

    // 4. Get Position
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint("Location Error: $e");
      return null;
    }
  }

  // --- 📢 DISCLOSURE DIALOG ---
  Future<bool> _showLocationDisclosureDialog() async {
    return await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.location_on, color: _cardNavy),
                SizedBox(width: 8),
                Text("Location Required"),
              ],
            ),
            content: const Text(
              "To verify this technical visit, this app collects location data to ensure you are physically present at the site.\n\n"
              "This data is collected only when you tap 'Fetch Location' or 'Check-In'.",
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

  // --- ⚙️ SETTINGS DIALOG ---
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Permission Required"),
        content: const Text(
          "Location permission is permanently denied. Please enable it in Settings to submit TVRs.",
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

  // --- Fetch Location & Address ---
  Future<void> _fetchLocationAndAddress() async {
    setState(() => _isFetchingLocation = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // 1. Get Location SAFELY (Play Store Compliant)
    // This calls the helper method that handles Disclosure & Permissions
    final Position? position = await _ensureLocationPermission();

    // If null, permission was denied or GPS is off. Stop here.
    if (position == null) {
      setState(() => _isFetchingLocation = false);
      return;
    }

    try {
      // 2. Reverse Geocoding
      Map<String, String> addressDetails = {};
      try {
        addressDetails = await _apiService.reverseGeocodeWithRadar(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      } catch (e) {
        debugPrint("Geocoding error: $e");
      }

      // 3. Update UI
      if (mounted) {
        setState(() {
          _capturedLocation = position;
          _latitudeController.text = position.latitude.toStringAsFixed(6);
          _longitudeController.text = position.longitude.toStringAsFixed(6);

          if (addressDetails['address']?.isNotEmpty == true) {
            _siteAddressController.text = addressDetails['address']!;
          }
          if (addressDetails['area']?.isNotEmpty == true) {
            _areaController.text = addressDetails['area']!;
          }
          if (addressDetails['region'] != null &&
              _regionOptions.contains(addressDetails['region'])) {
            _selectedRegion = addressDetails['region'];
          }
        });
        
        // Save fetched data to disk
        _saveDrafts();

        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text("Location & Address Updated"),
            backgroundColor: _accentGreen,
            duration: Duration(milliseconds: 1000),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text("Location Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  // --- SEARCH DIALOGS ---
  Future<void> _openSiteSearch() async {
    final TechnicalSite? result = await showDialog(
      context: context,
      builder: (context) => _ServerSiteSearchDialog(
        api: _apiService,
        userId: int.parse(widget.employee.id),
      ),
    );
    if (result != null) _onSiteSelected(result);
  }

  Future<void> _openMasonSearch() async {
    final Mason? result = await showDialog(
      context: context,
      builder: (context) => _ServerMasonSearchDialog(api: _apiService),
    );
    if (result != null) _onMasonSelected(result);
  }

  Future<void> _openDealerSearch() async {
    final Dealer? result = await showDialog(
      context: context,
      builder: (context) => _ServerDealerSearchDialog(api: _apiService),
    );
    if (result != null) _onDealerSelected(result);
  }

  Future<void> _handleCheckIn() async {
    await _saveDrafts();

    // 🟢 Use the Internal Camera Class
    final String? imagePath = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const _InlineCameraScreen()),
    );

    if (imagePath == null) return; // User cancelled

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _isUploadingImage = true);

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final imageFile = File(imagePath);
      if (mounted) setState(() => _inTimeImageFile = imageFile);

      final imageUrl = await _apiService.uploadImageToR2(imageFile);

      if (mounted) {
        setState(() {
          _checkInTime = DateTime.now();
          _inTimeImageUrl = imageUrl;
          _capturedLocation = position;
          _latitudeController.text = position.latitude.toStringAsFixed(6);
          _longitudeController.text = position.longitude.toStringAsFixed(6);
        });

        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Checked-In successfully.'),
            backgroundColor: _accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Check-In Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _pickSitePhoto() async {
    await _saveDrafts();

    // 🟢 Use the Internal Camera Class
    final String? imagePath = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const _InlineCameraScreen()),
    );

    if (imagePath != null) {
      setState(() => _sitePhotoFile = File(imagePath));
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _cardNavy, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: _textDark, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: _cardNavy, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _supplyDate) {
      setState(() {
        _supplyDate = picked;
      });
      _saveDrafts();
    }
  }

  void showSnack(
    String message, {
    Color backgroundColor = Colors.orange,
    int durationSeconds = 3,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: durationSeconds),
      ),
    );
  }

  Future<void> _submitTvr() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedCustomerType == 'IHB/Site' && _selectedSite == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a Site.')));
      return;
    }

    if (_checkInTime == null || _capturedLocation == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Check-in is required.')));
      return;
    }

    final now = DateTime.now();
    final difference = now.difference(_checkInTime!);
    const minMinutes = 1;

    if (difference.inMinutes < minMinutes) {
      final remaining = minMinutes - difference.inMinutes;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Minimum $minMinutes mins required. Wait $remaining minute(s).",
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // // --- Geofence (for IHB/Site visits) ---
    // if (_selectedCustomerType == 'IHB/Site' &&
    //     _selectedSite != null &&
    //     _selectedSite!.latitude != 0.0 &&
    //     _selectedSite!.longitude != 0.0) {
    //   double distanceInMeters = Geolocator.distanceBetween(
    //     _capturedLocation!.latitude,
    //     _capturedLocation!.longitude,
    //     _selectedSite!.latitude,
    //     _selectedSite!.longitude,
    //   );
    //   double distanceInKm = distanceInMeters / 1000;
    //   if (distanceInMeters > 50) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(
    //         content: Text(
    //           "Geofence Error: You are ${distanceInKm.toStringAsFixed(2)}km away.",
    //         ),
    //         backgroundColor: Colors.red,
    //       ),
    //     );
    //     return;
    //   }
    // }

    // // --- Geofence (For Dealer) ---
    // if (_selectedCustomerType != null &&
    //     _selectedCustomerType!.contains("Dealer") &&
    //     _selectedDealer != null &&
    //     (_selectedDealer!.latitude != 0.0 ||
    //         _selectedDealer!.longitude != 0.0)) {
    //   double distanceInMeters = Geolocator.distanceBetween(
    //     _capturedLocation!.latitude,
    //     _capturedLocation!.longitude,
    //     _selectedDealer!.latitude ?? 0.0,
    //     _selectedDealer!.longitude ?? 0.0,
    //   );
    //   double distanceInKm = distanceInMeters / 1000;
    //   if (distanceInMeters > 50) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(
    //         content: Text(
    //           "Geofence Error (Dealer): You are ${distanceInKm.toStringAsFixed(2)}km away.",
    //         ),
    //         backgroundColor: Colors.red,
    //       ),
    //     );
    //     return;
    //   }
    // }

    // Dealer Specific Validation
    if (_selectedCustomerType != null &&
        _selectedCustomerType!.contains("Dealer")) {
      // Mandatory Brand Selection
      if (_selectedBrandsInUse.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one Brand Selling/In Use.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (_isBagPicked) {
        if (_conversionQuantityValueController.text.isEmpty) {
          showSnack('Enter Quantity');
          return;
        }
        if (_selectedConversionUnit == null) {
          showSnack('Select Unit');
          return;
        }
        if (_currentBrandPriceController.text.isEmpty) {
          showSnack('Enter Rate per Bag');
          return;
        }
        if (_supplyDate == null) {
          showSnack('Select Supply Date');
          return;
        }
      }
    }

    final String timeSpentStr =
        '${difference.inHours}h ${difference.inMinutes.remainder(60)}m';

    setState(() => _isSubmitting = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
     // 🟢 REPLACED CHECKOUT CAMERA LOGIC
      String? outTimeImageUrl;
      
      // Navigate to our internal camera screen to keep app alive
      final String? pickedOutPath = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const _InlineCameraScreen()),
      );

      if (pickedOutPath != null) {
        outTimeImageUrl = await _apiService.uploadImageToR2(File(pickedOutPath));
      }

      String? sitePhotoUrl;
      if (_sitePhotoFile != null) {
        sitePhotoUrl = await _apiService.uploadImageToR2(_sitePhotoFile!);
      }

      // Handle Dealer Logic
      String finalRemarks = _salespersonRemarksController.text;
      String finalSiteName = _siteNameConcernedPersonController.text;

      if (_selectedCustomerType != null &&
          _selectedCustomerType!.contains("Dealer")) {
        // Map Dealer Name to Site Name (Mandatory DB field)
        finalSiteName = _associatedPartyNameController.text;

        if (_isConverted && _isBagPicked) {
          final dateStr = _supplyDate != null
              ? DateFormat('yyyy-MM-dd').format(_supplyDate!)
              : 'N/A';
          finalRemarks += " [Bag Picked: YES, Supply Date: $dateStr]";
        }
      }

      final tvrReport = TechnicalVisitReport(
        userId: int.parse(widget.employee.id),
        reportDate: DateTime.now(),
        visitType: _selectedVisitType!,
        siteId: _selectedSite?.id,
        masonId: _selectedMason?.id,
        pjpId: widget.pjp?.id,

        siteNameConcernedPerson: finalSiteName,
        phoneNo: _phoneNoController.text,
        whatsappNo: _whatsappNoController.text.isNotEmpty
            ? _whatsappNoController.text
            : null,
        associatedPartyName: _associatedPartyNameController.text.isNotEmpty
            ? _associatedPartyNameController.text
            : null,

        emailId: null,
        siteAddress: _siteAddressController.text.isNotEmpty
            ? _siteAddressController.text
            : null,
        marketName: _marketNameController.text.isNotEmpty
            ? _marketNameController.text
            : null,
        region: _selectedRegion,
        area: _areaController.text.isNotEmpty ? _areaController.text : null,
        latitude: _capturedLocation?.latitude,
        longitude: _capturedLocation?.longitude,

        visitCategory: _selectedVisitCategory,
        customerType: _selectedCustomerType,
        purposeOfVisit: _purposeOfVisitController.text.isNotEmpty
            ? _purposeOfVisitController.text
            : null,
        siteVisitType: _selectedSiteVisitType,

        siteVisitStage: _selectedStage,
        constAreaSqFt: int.tryParse(_constAreaSqFtController.text),
        siteVisitBrandInUse: _selectedBrandsInUse,
        currentBrandPrice: double.tryParse(_currentBrandPriceController.text),
        siteStock: double.tryParse(_siteStockController.text),
        estRequirement: double.tryParse(_estRequirementController.text),

        supplyingDealerName: _supplyingDealerNameController.text.isNotEmpty
            ? _supplyingDealerNameController.text
            : null,
        nearbyDealerName: _nearbyDealerNameController.text.isNotEmpty
            ? _nearbyDealerNameController.text
            : null,
        channelPartnerVisit: null,

        isConverted: _isConverted,
        conversionType: _isConverted ? _selectedConversionType : null,
        conversionFromBrand: _isConverted ? _selectedConversionFromBrand : null,
        conversionQuantityValue: double.tryParse(
          _conversionQuantityValueController.text,
        ),
        conversionQuantityUnit: _isConverted ? _selectedConversionUnit : null,

        isTechService: _isTechService,
        serviceDesc: _serviceDescController.text.isNotEmpty
            ? _serviceDescController.text
            : null,
        serviceType: _selectedServiceType,
        dhalaiVerificationCode:
            _dhalaiVerificationCodeController.text.isNotEmpty
            ? _dhalaiVerificationCodeController.text
            : null,
        isVerificationStatus: null,
        qualityComplaint: _qualityComplaintController.text.isNotEmpty
            ? _qualityComplaintController.text
            : null,

        influencerName: _influencerNameController.text.isNotEmpty
            ? _influencerNameController.text
            : null,
        influencerPhone: _influencerPhoneController.text.isNotEmpty
            ? _influencerPhoneController.text
            : null,
        isSchemeEnrolled: _isSchemeEnrolled,
        influencerProductivity:
            _influencerProductivityController.text.isNotEmpty
            ? _influencerProductivityController.text
            : null,
        influencerType: _selectedInfluencerType != null
            ? [_selectedInfluencerType!]
            : [],

        clientsRemarks:
            (_selectedCustomerType != null &&
                _selectedCustomerType!.contains("Dealer"))
            ? finalRemarks
            : '',

        salespersonRemarks:
            (_selectedCustomerType != null &&
                _selectedCustomerType!.contains("Dealer"))
            ? ''
            : finalRemarks,
        promotionalActivity: _selectedTechActivity,

        checkInTime: _checkInTime!,
        checkOutTime: now,
        timeSpentinLoc: timeSpentStr,
        inTimeImageUrl: _inTimeImageUrl,
        outTimeImageUrl: outTimeImageUrl,
        sitePhotoUrl: sitePhotoUrl,
      );

      await _apiService.createTvr(tvrReport);
      
      await _clearDrafts(); // CLEAR SAVED DATA ON SUCCESS

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('TVR submitted successfully!'),
          backgroundColor: _accentGreen,
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // --- UI BUILDER ---
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
              color: _surfaceWhite,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Technical Visit Report',
                        style: TextStyle(
                          color: _textDark,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: _textGrey),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: 30, color: Color(0xFFF3F4F6)),

                  if (_checkInTime == null) ...[
                    _buildFintechDropdown(
                      label: 'Type of Customer',
                      value: _selectedCustomerType,
                      items: _customerTypeOptions,
                      onChanged: (v) {
                          setState(() => _selectedCustomerType = v);
                          _saveDrafts();
                      },
                      isRequired: true,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _isUploadingImage ? null : _handleCheckIn,
                      icon: _isUploadingImage
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.camera_alt),
                      label: const Text(
                        'CHECK-IN (PHOTO)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        children: [
                          _inTimeImageFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _inTimeImageFile!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(
                                  Icons.check_circle,
                                  color: _accentGreen,
                                  size: 40,
                                ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedCustomerType ?? "Visit",
                                  style: const TextStyle(
                                    color: _textDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'In: ${DateFormat('hh:mm a').format(_checkInTime!)}',
                                  style: const TextStyle(
                                    color: _textGrey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- FORM SWITCHER ---
                    if (_selectedCustomerType == 'IHB/Site')
                      _buildIHBForm()
                    else if (_selectedCustomerType != null &&
                        _selectedCustomerType!.contains("Dealer"))
                      _buildDealerForm()
                    else
                      _buildInfluencerForm(),

                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitTvr,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- 1. IHB FORM ---
  Widget _buildIHBForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: _openSiteSearch,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: _inputFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedSite != null
                        ? "${_selectedSite!.siteName} (${_selectedSite!.region})"
                        : "Select Construction Site *",
                    style: TextStyle(
                      color: _selectedSite != null ? _textDark : _textGrey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(Icons.search, color: _textGrey),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildFintechInput(
          controller: _siteNameConcernedPersonController,
          label: 'Concerned Person',
          readOnly: true,
          isRequired: true,
        ),
        const SizedBox(height: 16),
        _buildFintechDropdown(
          label: 'Visit Type',
          value: _selectedVisitType,
          items: ['Site Visit', 'Service', 'Complaint', 'Influencer Meet'],
          onChanged: (v) {
              setState(() => _selectedVisitType = v);
              _saveDrafts();
          },
          isRequired: true,
        ),
        const SizedBox(height: 16),
        _buildFintechDropdown(
          label: 'Site Visit Type',
          value: _selectedSiteVisitType,
          items: ['Planned', 'Unplanned'],
          onChanged: (v) {
              setState(() => _selectedSiteVisitType = v);
              _saveDrafts();
          },
          isRequired: true,
        ),
        const SizedBox(height: 16),
        _buildFintechDropdown(
          label: 'Visit Category',
          value: _selectedVisitCategory,
          items: _visitCategoryOptions,
          onChanged: (v) {
              setState(() => _selectedVisitCategory = v);
              _saveDrafts();
          },
          isRequired: true,
        ),
        const SizedBox(height: 16),
        _buildFintechInput(
          controller: _purposeOfVisitController,
          label: 'Purpose of Visit',
          isRequired: true,
        ),
        //AUTOFILL LATER
        const SizedBox(height: 16),
        _buildFintechInput(
          controller: _associatedPartyNameController,
          label: 'Site Owner Name',
          isRequired: true,
        ),
        const SizedBox(height: 16),
        _buildFintechInput(
          controller: _whatsappNoController,
          label: 'Phone/WhatsApp No.',
          keyboardType: TextInputType.phone,
          isRequired: true,
        ),

        const SizedBox(height: 16),
        _buildLocationFetchSection(),

        _buildSectionHeader("SITE INFO"),
        Row(
          children: [
            Expanded(
              child: _buildFintechDropdown(
                label: 'Region',
                value: _selectedRegion,
                items: _regionOptions,
                onChanged: (v) {
                    setState(() => _selectedRegion = v);
                    _saveDrafts();
                },
                isRequired: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFintechInput(
                controller: _areaController,
                label: 'Area',
                isRequired: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildFintechInput(
          controller: _marketNameController,
          label: 'Market Name',
          isRequired: true,
        ),
        const SizedBox(height: 16),
        _buildFintechInput(
          controller: _siteAddressController,
          label: 'Site Address',
          maxLines: 2,
          isRequired: true,
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: _pickSitePhoto,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: _inputFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.camera_enhance, color: _textGrey),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _sitePhotoFile != null
                        ? "Site Photo Selected"
                        : "Capture Site Progress Photo",
                    style: TextStyle(
                      color: _sitePhotoFile != null ? _textDark : _textGrey,
                    ),
                  ),
                ),
                if (_sitePhotoFile != null)
                  const Icon(Icons.check_circle, color: _accentGreen),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildFintechInput(
                controller: _constAreaSqFtController,
                label: 'Area (SqFt)',
                keyboardType: TextInputType.number,
                isRequired: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFintechDropdown(
                label: 'Stage',
                value: _selectedStage,
                items: _stageOptions,
                onChanged: (v) {
                    setState(() => _selectedStage = v);
                    _saveDrafts();
                },
                isRequired: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildFintechMultiSelect(
          label: 'Brands in Use',
          selectedValues: _selectedBrandsInUse,
          items: _brandOptions,
          onChanged: (list) {
              setState(() => _selectedBrandsInUse = list);
              _saveDrafts();
          },
          isRequired: true,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildFintechInput(
                controller: _currentBrandPriceController,
                label: 'Current Price',
                keyboardType: TextInputType.number,
                isRequired: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFintechInput(
                controller: _siteStockController,
                label: 'Site Stock',
                keyboardType: TextInputType.number,
                isRequired: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildFintechInput(
          controller: _estRequirementController,
          label: 'Est. Requirement',
          keyboardType: TextInputType.number,
          isRequired: true,
        ),
        _buildSectionHeader("DEALER INFO"),
        _buildFintechInput(
          controller: _supplyingDealerNameController,
          label: 'Supplying Dealer',
          isRequired: false,
        ),
        const SizedBox(height: 16),
        _buildFintechInput(
          controller: _nearbyDealerNameController,
          label: 'Nearby Dealer (Best)',
          isRequired: true,
        ),
        _buildSectionHeader("CONVERSION"),
        _buildFintechSwitch(
          label: "Is Converted?",
          value: _isConverted,
          onChanged: (v) {
              setState(() => _isConverted = v);
              _saveDrafts();
          },
        ),
        if (_isConverted) ...[
          const SizedBox(height: 12),
          _buildFintechDropdown(
            label: 'Conversion Type',
            value: _selectedConversionType,
            items: ['New', 'Retention'],
            onChanged: (v) {
               setState(() => _selectedConversionType = v);
               _saveDrafts();
            },
            isRequired: true,
          ),
          const SizedBox(height: 16),
          _buildFintechDropdown(
            label: 'From Brand',
            value: _selectedConversionFromBrand,
            items: _brandOptions,
            onChanged: (v) {
               setState(() => _selectedConversionFromBrand = v);
               _saveDrafts();
            },
            isRequired: true,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFintechInput(
                  controller: _conversionQuantityValueController,
                  label: 'Qty',
                  keyboardType: TextInputType.number,
                  isRequired: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFintechDropdown(
                  label: 'Unit',
                  value: _selectedConversionUnit,
                  items: ['Bags'],
                  onChanged: (v) {
                      setState(() => _selectedConversionUnit = v);
                      _saveDrafts();
                  },
                  isRequired: true,
                ),
              ),
            ],
          ),
        ],
        _buildSectionHeader("TECHNICAL SERVICES"),
        _buildFintechSwitch(
          label: "Tech Service Given?",
          value: _isTechService,
          onChanged: (v) {
              setState(() => _isTechService = v);
              _saveDrafts();
          },
        ),
        if (_isTechService) ...[
          const SizedBox(height: 12),
          _buildFintechDropdown(
            label: 'Service Type',
            value: _selectedServiceType,
            items: _serviceTypeOptions,
            onChanged: (v) {
               setState(() => _selectedServiceType = v);
               _saveDrafts();
            },
            isRequired: true,
          ),
          const SizedBox(height: 16),
          _buildFintechDropdown(
            label: 'Type of Technical Activity',
            value: _selectedTechActivity,
            items: _techActivityOptions,
            onChanged: (v) {
               setState(() => _selectedTechActivity = v);
               _saveDrafts();
            },
            isRequired: false,
          ),
          const SizedBox(height: 16),
          _buildFintechInput(
            controller: _serviceDescController,
            label: 'Description',
            maxLines: 2,
            isRequired: true,
          ),
        ],
        const SizedBox(height: 16),
        _buildFintechInput(
          controller: _qualityComplaintController,
          label: 'Quality Complaint',
          isRequired: false,
        ),
        _buildSectionHeader("INFLUENCER / MASON"),
        InkWell(
          onTap: _openMasonSearch,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: _inputFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.person_search, color: _cardNavy),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedMason != null
                        ? _selectedMason!.name
                        : "Link Registered Mason (Optional)",
                    style: TextStyle(
                      color: _selectedMason != null ? _textDark : _textGrey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildFintechDropdown(
          label: 'Influencer Type',
          value: _selectedInfluencerType,
          items: _influencerTypeOptions,
          onChanged: (v) {
              setState(() => _selectedInfluencerType = v);
              _saveDrafts();
          },
          isRequired: true,
        ),
        const SizedBox(height: 16),
        _buildFintechInput(
          controller: _influencerNameController,
          label: 'Name',
          isRequired: true,
        ),
        const SizedBox(height: 16),
        _buildFintechInput(
          controller: _influencerPhoneController,
          label: 'Phone',
          keyboardType: TextInputType.phone,
          isRequired: true,
        ),
        const SizedBox(height: 16),
        _buildFintechInput(
          controller: _influencerProductivityController,
          label: 'Influencer Productivity',
          isRequired: true,
        ),
        const SizedBox(height: 16),
        _buildFintechSwitch(
          label: "Enrolled in Scheme?",
          value: _isSchemeEnrolled,
          onChanged: (v) {
              setState(() => _isSchemeEnrolled = v);
              _saveDrafts();
          },
        ),
        _buildSectionHeader("REMARKS"),
        _buildFintechInput(
          controller: _salespersonRemarksController,
          label: 'Remarks',
          maxLines: 2,
          isRequired: true,
        ),
      ],
    );
  }

  // 2. DEALER FORM
  Widget _buildDealerForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: _openDealerSearch,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: _inputFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.store, color: _cardNavy),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedDealer != null
                        ? "${_selectedDealer!.name} (${_selectedDealer!.area})"
                        : "Tap to Search Dealer (Optional)",
                    style: TextStyle(
                      color: _selectedDealer != null ? _textDark : _textGrey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(Icons.search, color: _textGrey),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildFintechInput(
          controller: _associatedPartyNameController,
          label: 'Dealer/Sub-Dealer Name',
          isRequired: true,
          readOnly: false, // Auto-filled .. can be edited
        ),
        const SizedBox(height: 16),
        _buildFintechInput(
          controller: _phoneNoController,
          label: 'Phone/WhatsApp No.',
          keyboardType: TextInputType.phone,
          isRequired: true,
          readOnly: false, // Auto-filled .. can be edited
        ),
        const SizedBox(height: 16),

        _buildLocationFetchSection(),
        const SizedBox(height: 16),

        _buildFintechDropdown(
          label: 'Visit Category',
          value: _selectedVisitCategory,
          items: _visitCategoryOptions,
          onChanged: (v) {
              setState(() => _selectedVisitCategory = v);
              _saveDrafts();
          },
          isRequired: true,
        ),
        const SizedBox(height: 16),
        _buildFintechDropdown(
          label: 'Influencer Type',
          value: _selectedInfluencerType,
          items: const ['Dealer', 'Sub-Dealer'],
          onChanged: (v) {
              setState(() => _selectedInfluencerType = v);
              _saveDrafts();
          },
          isRequired: true,
        ),
        _buildSectionHeader("LOCATION & REGION"),
        Row(
          children: [
            Expanded(
              child: _buildFintechDropdown(
                label: 'Region',
                value: _selectedRegion,
                items: _regionOptions,
                onChanged: (v) {
                    setState(() => _selectedRegion = v);
                    _saveDrafts();
                },
                isRequired: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFintechInput(
                controller: _areaController,
                label: 'Area',
                isRequired: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildFintechInput(
          controller: _siteAddressController,
          label: 'Address',
          maxLines: 2,
          isRequired: true,
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: _pickSitePhoto,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: _inputFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.camera_enhance, color: _textGrey),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _sitePhotoFile != null
                        ? "Photo Selected"
                        : "Capture Dealer Photo(optional)",
                    style: TextStyle(
                      color: _sitePhotoFile != null ? _textDark : _textGrey,
                    ),
                  ),
                ),
                if (_sitePhotoFile != null)
                  const Icon(Icons.check_circle, color: _accentGreen),
              ],
            ),
          ),
        ),
        _buildSectionHeader("BUSINESS INFO"),
        _buildFintechInput(
          controller: _influencerProductivityController,
          label: 'Productivity',
          isRequired: true,
        ),
        const SizedBox(height: 16),
        _buildFintechMultiSelect(
          label: 'Brands in Use/Selling',
          selectedValues: _selectedBrandsInUse,
          items: _brandOptions,
          onChanged: (list) {
              setState(() => _selectedBrandsInUse = list);
              _saveDrafts();
          },
          isRequired: true,
        ),

        _buildSectionHeader("CONVERSION"),
        // Directly ask for Bags (Implicitly sets converted status)
        _buildFintechSwitch(
          label: "Is Bag Picked?",
          value: _isBagPicked,
          onChanged: (v) => setState(() {
            _isBagPicked = v;
            _isConverted = v; // Auto-set conversion status
            _saveDrafts();
          }),
        ),

        if (_isBagPicked) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFintechInput(
                  controller: _conversionQuantityValueController,
                  label: 'Qty',
                  keyboardType: TextInputType.number,
                  isRequired: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFintechDropdown(
                  label: 'Unit',
                  value: _selectedConversionUnit,
                  items: ['Bags'],
                  onChanged: (v) {
                      setState(() => _selectedConversionUnit = v);
                      _saveDrafts();
                  },
                  isRequired: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFintechInput(
            controller: _currentBrandPriceController,
            label: 'Rate per Bag',
            keyboardType: TextInputType.number,
            isRequired: true,
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _selectDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: _inputFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: _cardNavy, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    _supplyDate != null
                        ? DateFormat('dd MMM yyyy').format(_supplyDate!)
                        : "Select Date of Supply (of Bags)",
                    style: TextStyle(
                      color: _supplyDate != null ? _textDark : _textGrey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        _buildSectionHeader("REMARKS"),
        _buildFintechInput(
          controller: _salespersonRemarksController,
          label: 'Remarks',
          maxLines: 2,
          isRequired: true,
        ),
      ],
    );
  }

  // 3. INFLUENCER FORM
  Widget _buildInfluencerForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Selection
        InkWell(
          onTap: _openMasonSearch,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: _inputFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.person_search, color: _cardNavy),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedMason != null
                        ? _selectedMason!.name
                        : "Link Registered Profile (Optional)",
                    style: TextStyle(
                      color: _selectedMason != null ? _textDark : _textGrey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildFintechDropdown(
          label: 'Influencer Type',
          value: _selectedInfluencerType,
          items: ['Mason', 'Head Mason', 'Contractor', 'Engineer', 'Architect'],
          onChanged: (v) {
              setState(() => _selectedInfluencerType = v);
              _saveDrafts();
          },
          isRequired: true,
        ),
        const SizedBox(height: 16),
        _buildFintechInput(
          controller: _influencerNameController,
          label: 'Name',
          isRequired: true,
        ),
        const SizedBox(height: 16),
        _buildFintechInput(
          controller: _influencerPhoneController,
          label: 'Phone/WhatsApp',
          keyboardType: TextInputType.phone,
          isRequired: true,
        ),

        const SizedBox(height: 16),
        _buildLocationFetchSection(),

        const SizedBox(height: 16),
        _buildFintechDropdown(
          label: 'Visit Category',
          value: _selectedVisitCategory,
          items: _visitCategoryOptions,
          onChanged: (v) {
              setState(() => _selectedVisitCategory = v);
              _saveDrafts();
          },
          isRequired: true,
        ),
        const SizedBox(height: 16),
        _buildFintechInput(
          controller: _purposeOfVisitController,
          label: 'Purpose of Visit',
          isRequired: true,
        ),

        _buildSectionHeader("DETAILS"),
        Row(
          children: [
            Expanded(
              child: _buildFintechDropdown(
                label: 'Region',
                value: _selectedRegion,
                items: _regionOptions,
                onChanged: (v) {
                    setState(() => _selectedRegion = v);
                    _saveDrafts();
                },
                isRequired: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFintechInput(
                controller: _areaController,
                label: 'Area',
                isRequired: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildFintechInput(
          controller: _siteAddressController,
          label: 'Address',
          maxLines: 2,
          isRequired: true,
        ),
        const SizedBox(height: 16),

        _buildFintechInput(
          controller: _influencerProductivityController,
          label: 'Productivity',
          isRequired: true,
        ),
        const SizedBox(height: 16),
        _buildFintechMultiSelect(
          label: 'Preferred Brands',
          selectedValues: _selectedBrandsInUse,
          items: _brandOptions,
          onChanged: (list) {
              setState(() => _selectedBrandsInUse = list);
              _saveDrafts();
          },
          isRequired: true,
        ),
        const SizedBox(height: 16),
        _buildFintechSwitch(
          label: "Enrolled in Scheme?",
          value: _isSchemeEnrolled,
          onChanged: (v) {
              setState(() => _isSchemeEnrolled = v);
              _saveDrafts();
          },
        ),

        _buildSectionHeader("REMARKS"),
        _buildFintechInput(
          controller: _salespersonRemarksController,
          label: 'Remarks',
          maxLines: 2,
          isRequired: true,
        ),
      ],
    );
  }

  // --- REUSABLE WIDGET: LOCATION FETCH SECTION ---
  Widget _buildLocationFetchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isFetchingLocation ? null : _fetchLocationAndAddress,
            icon: _isFetchingLocation
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            label: const Text("FETCH LOCATION & ADDRESS"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: _cardNavy),
              foregroundColor: _cardNavy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildFintechInput(
                controller: _latitudeController,
                label: "Latitude",
                readOnly: true,
                isRequired: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFintechInput(
                controller: _longitudeController,
                label: "Longitude",
                readOnly: true,
                isRequired: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- WIDGETS ---
  Widget _buildFintechInput({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool isRequired = true,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: _textDark,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              fontFamily: 'Roboto',
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          style: const TextStyle(color: _textDark, fontWeight: FontWeight.w500),
          validator: isRequired ? (v) => v!.isEmpty ? 'Required' : null : null,
          onChanged: (v) => _saveDrafts(), // Auto-save on change
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? Colors.grey[200] : _inputFill,
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _cardNavy, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFintechDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: _textDark,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              fontFamily: 'Roboto',
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          dropdownColor: _surfaceWhite,
          style: const TextStyle(color: _textDark, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            filled: true,
            fillColor: _inputFill,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          items: items
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: onChanged,
          validator: isRequired ? (v) => v == null ? 'Required' : null : null,
        ),
      ],
    );
  }

  Widget _buildFintechMultiSelect({
    required String label,
    required List<String> items,
    required List<String> selectedValues,
    required void Function(List<String>) onChanged,
    bool isRequired = true,
  }) {
    return FormField<List<String>>(
      initialValue: selectedValues,
      validator: isRequired
          ? (value) => (value == null || value.isEmpty) ? 'Required' : null
          : null,
      builder: (FormFieldState<List<String>> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                text: label,
                style: const TextStyle(
                  color: _textDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  fontFamily: 'Roboto',
                ),
                children: [
                  if (isRequired)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final List<String>? result = await showDialog(
                  context: context,
                  builder: (ctx) {
                    List<String> tempSelected = List.from(selectedValues);
                    return StatefulBuilder(
                      builder: (context, setState) {
                        return AlertDialog(
                          backgroundColor: _surfaceWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Text(
                            "Select $label",
                            style: const TextStyle(
                              color: _textDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: items.length,
                              itemBuilder: (ctx, i) {
                                final item = items[i];
                                final isChecked = tempSelected.contains(item);
                                return CheckboxListTile(
                                  value: isChecked,
                                  title: Text(
                                    item,
                                    style: const TextStyle(color: _textDark),
                                  ),
                                  activeColor: _accentGreen,
                                  checkColor: Colors.white,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  onChanged: (checked) {
                                    setState(() {
                                      if (checked == true) {
                                        tempSelected.add(item);
                                      } else {
                                        tempSelected.remove(item);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                "CANCEL",
                                style: TextStyle(color: _textGrey),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  Navigator.pop(context, tempSelected),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accentGreen,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text("OK"),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );

                if (result != null) {
                  onChanged(result);
                  field.didChange(result);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: _inputFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: field.hasError ? Colors.red : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: selectedValues.isEmpty
                          ? Text(
                              "Select Options",
                              style: TextStyle(color: Colors.grey[400]),
                            )
                          : Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: selectedValues
                                  .map(
                                    (e) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE0F2F1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.teal.shade100,
                                        ),
                                      ),
                                      child: Text(
                                        e,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.teal,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: _textGrey),
                  ],
                ),
              ),
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Text(
                  field.errorText ?? '',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFintechSwitch({
    required String label,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: _inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? _accentGreen.withOpacity(0.5) : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _textDark,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: _accentGreen),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 12),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: _textGrey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
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