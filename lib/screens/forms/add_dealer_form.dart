// lib/screens/forms/add_dealer_form.dart

// --- (All imports needed for this form) ---
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async'; // <-- Import for Timer (debounce)
import 'package:geolocator/geolocator.dart';
import 'package:flutter_radar/flutter_radar.dart'; 
import '../../models/employee_model.dart';
import '../../models/dealer_model.dart';
import '../../api/api_service.dart';

// --- (Class is public: "AddDealerForm") ---
class AddDealerForm extends StatefulWidget {
  final Employee employee;
  const AddDealerForm({super.key, required this.employee});

  @override
  // --- (State class is private, but attached to the public widget) ---
  State<AddDealerForm> createState() => _AddDealerFormState();
}

class _AddDealerFormState extends State<AddDealerForm> {
  // Form and State Management
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  bool _isSubmitting = false;
  bool _isLoadingDealers = true;
  bool _isFetchingLocation = false;

  // Location Data
  Position? _currentPosition;

  // Data for Dropdowns and Switches
  String? _selectedType; // This is the 'type' field
  bool _isSubDealer = false;
  List<Dealer> _parentDealers = [];
  Dealer? _selectedParentDealer;

  // --- (All Form Controllers) ---
  final _nameController = TextEditingController();
  final _regionController = TextEditingController();
  final _areaController = TextEditingController();
  final _phoneNoController = TextEditingController();
  final _addressController = TextEditingController();
  final _pinCodeController = TextEditingController();
  final _totalPotentialController = TextEditingController();
  final _bestPotentialController = TextEditingController();
  final _brandSellingController = TextEditingController();
  final _feedbacksController = TextEditingController();
  final _remarksController = TextEditingController();
  final _whatsappNoController = TextEditingController();
  final _emailIdController = TextEditingController();
  final _businessTypeController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _anniversaryDateController = TextEditingController();
  DateTime? _selectedDateOfBirth;
  DateTime? _selectedAnniversaryDate;
  final _gstinNoController = TextEditingController();
  final _panNoController = TextEditingController();
  final _tradeLicNoController = TextEditingController();
  final _aadharNoController = TextEditingController();
  final _godownSizeSqFtController = TextEditingController();
  final _godownCapacityMTBagsController = TextEditingController();
  final _godownAddressLineController = TextEditingController();
  final _godownLandMarkController = TextEditingController();
  final _godownDistrictController = TextEditingController();
  final _godownAreaController = TextEditingController();
  final _godownRegionController = TextEditingController();
  final _godownPinCodeController = TextEditingController();
  final _resAddressLineController = TextEditingController();
  final _resLandMarkController = TextEditingController();
  final _resDistrictController = TextEditingController();
  final _resAreaController = TextEditingController();
  final _resRegionController = TextEditingController();
  final _resPinCodeController = TextEditingController();
  final _bankAccountNameController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankBranchAddressController = TextEditingController();
  final _bankAccountNumberController = TextEditingController();
  final _bankIfscCodeController = TextEditingController();
  final _brandNameController = TextEditingController();
  final _monthlySaleMTController = TextEditingController();
  final _noOfDealersController = TextEditingController();
  final _areaCoveredController = TextEditingController();
  final _projectedMonthlySalesBestCementMTController = TextEditingController();
  final _noOfEmployeesInSalesController = TextEditingController();
  final _declarationNameController = TextEditingController();
  final _declarationPlaceController = TextEditingController();
  final _declarationDateController = TextEditingController();
  DateTime? _selectedDeclarationDate;
  final _radiusController = TextEditingController(text: '25');
  final _tradeLicencePicUrlController = TextEditingController();
  final _shopPicUrlController = TextEditingController();
  final _dealerPicUrlController = TextEditingController();
  final _blankChequePicUrlController = TextEditingController();
  final _partnershipDeedPicUrlController = TextEditingController();

  // --- (NEW State Variables for Photon Autocomplete) ---
  Timer? _godownDebounce;
  Timer? _resDebounce;
  List<dynamic> _godownSuggestions = [];
  List<dynamic> _resSuggestions = [];
  bool _isSearchingGodown = false;
  bool _isSearchingRes = false;
  final FocusNode _godownFocusNode = FocusNode();
  final FocusNode _resFocusNode = FocusNode();


  @override
  void initState() {
    super.initState();
    _fetchParentDealers();
    
    // --- (NEW) Add focus listeners to hide suggestion lists
    _godownFocusNode.addListener(_onGodownFocusChange);
    _resFocusNode.addListener(_onResFocusChange);
  }

  @override
  void dispose() {
    // Dispose all controllers
    _nameController.dispose();
    _regionController.dispose();
    _areaController.dispose();
    _phoneNoController.dispose();
    _addressController.dispose();
    _pinCodeController.dispose();
    _totalPotentialController.dispose();
    _bestPotentialController.dispose();
    _brandSellingController.dispose();
    _feedbacksController.dispose();
    _remarksController.dispose();
    _whatsappNoController.dispose();
    _emailIdController.dispose();
    _businessTypeController.dispose();
    _dateOfBirthController.dispose();
    _anniversaryDateController.dispose();
    _gstinNoController.dispose();
    _panNoController.dispose();
    _tradeLicNoController.dispose();
    _aadharNoController.dispose();
    _godownSizeSqFtController.dispose();
    _godownCapacityMTBagsController.dispose();
    _godownAddressLineController.dispose();
    _godownLandMarkController.dispose();
    _godownDistrictController.dispose();
    _godownAreaController.dispose();
    _godownRegionController.dispose();
    _godownPinCodeController.dispose();
    _resAddressLineController.dispose();
    _resLandMarkController.dispose();
    _resDistrictController.dispose();
    _resAreaController.dispose();
    _resRegionController.dispose();
    _resPinCodeController.dispose();
    _bankAccountNameController.dispose();
    _bankNameController.dispose();
    _bankBranchAddressController.dispose();
    _bankAccountNumberController.dispose();
    _bankIfscCodeController.dispose();
    _brandNameController.dispose();
    _monthlySaleMTController.dispose();
    _noOfDealersController.dispose();
    _areaCoveredController.dispose();
    _projectedMonthlySalesBestCementMTController.dispose();
    _noOfEmployeesInSalesController.dispose();
    _declarationNameController.dispose();
    _declarationPlaceController.dispose();
    _declarationDateController.dispose();
    _radiusController.dispose();
    _tradeLicencePicUrlController.dispose();
    _shopPicUrlController.dispose();
    _dealerPicUrlController.dispose();
    _blankChequePicUrlController.dispose();
    _partnershipDeedPicUrlController.dispose();

    // --- (NEW) Dispose timers and focus nodes
    _godownDebounce?.cancel();
    _resDebounce?.cancel();
    _godownFocusNode.removeListener(_onGodownFocusChange);
    _resFocusNode.removeListener(_onResFocusChange);
    _godownFocusNode.dispose();
    _resFocusNode.dispose();

    super.dispose();
  }

  /// Fetches main dealers to act as potential parent dealers for sub-dealers.
  Future<void> _fetchParentDealers() async {
    try {
      final allDealers = await _apiService.fetchDealers(
        userId: int.tryParse(widget.employee.id),
      );
      final mainDealers =
          allDealers.where((d) => d.parentDealerId == null).toList();
      if (mounted) {
        setState(() {
          _parentDealers = mainDealers;
          _isLoadingDealers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDealers = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not fetch parent dealers: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  /// Gets the device's current location and uses reverse geocoding to populate address fields.
  Future<void> _fetchLocationAndAddress() async {
    // --- 1. START ---
    debugPrint("➡️ _fetchLocationAndAddress: STARTING");
    setState(() => _isFetchingLocation = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // --- 2. PERMISSIONS ---
      debugPrint("➡️ _fetchLocationAndAddress: Checking permissions...");
      String? status = await Radar.getPermissionsStatus();
      debugPrint("➡️ _fetchLocationAndAddress: Initial permission status: $status");

      if (status == 'DENIED' || status == 'NOT_DETERMINED') {
        debugPrint("➡️ _fetchLocationAndAddress: Requesting permissions...");
        status = await Radar.requestPermissions(true);
        debugPrint("➡️ _fetchLocationAndAddress: New permission status: $status");
      }
      if (status != 'GRANTED_BACKGROUND' && status != 'GRANTED_FOREGROUND') {
        // --- 2a. PERMISSION FAILED ---
        debugPrint("❌ _fetchLocationAndAddress: Permissions not granted.");
        throw Exception('Location permissions are required.');
      }
      debugPrint("✅ _fetchLocationAndAddress: Permissions OK.");

      // --- 3. SERVICE CHECK ---
      debugPrint("➡️ _fetchLocationAndAddress: Checking if location service is enabled...");
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // --- 3a. SERVICE FAILED ---
        debugPrint("❌ _fetchLocationAndAddress: Location services are disabled.");
        throw Exception('Location services are disabled.');
      }
      debugPrint("✅ _fetchLocationAndAddress: Location service is enabled.");

      // --- 4. GET POSITION ---
      debugPrint("📡 _fetchLocationAndAddress: Calling Geolocator.getCurrentPosition() (max 15s)...");
      final Position bestPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15), // <-- More realistic timeout
      );
      debugPrint(
          "✅ _fetchLocationAndAddress: Got position! Lat: ${bestPosition.latitude}, Lon: ${bestPosition.longitude}, Acc: ${bestPosition.accuracy}");

      // --- 5. REVERSE GEOCODE ---
      debugPrint("📡 _fetchLocationAndAddress: Calling reverseGeocodeWithRadar...");
      final addressDetails = await _apiService.reverseGeocodeWithRadar(
        latitude: bestPosition.latitude,
        longitude: bestPosition.longitude,
      );
      debugPrint(
          "✅ _fetchLocationAndAddress: Got address details: ${addressDetails['address']}");

      // --- 6. UPDATE UI ---
      if (mounted) {
        debugPrint("➡️ _fetchLocationAndAddress: Updating UI with controllers...");
        setState(() {
          _currentPosition = bestPosition;
          
          // --- ✅ FIX: POPULATE ALL 3 ADDRESS BLOCKS ---
          final String address = addressDetails['address'] ?? '';
          final String region = addressDetails['region'] ?? '';
          final String area = addressDetails['area'] ?? '';
          final String pinCode = addressDetails['pinCode'] ?? '';
          final String district = addressDetails['district'] ?? '';
          final String landmark = addressDetails['landmark'] ?? '';

          // 1. Main Address
          _addressController.text = address;
          _regionController.text = region;
          _areaController.text = area;
          _pinCodeController.text = pinCode;

          // 2. Godown Address (auto-fill)
          _godownAddressLineController.text = address;
          _godownLandMarkController.text = landmark;
          _godownDistrictController.text = district;
          _godownAreaController.text = area;
          _godownRegionController.text = region;
          _godownPinCodeController.text = pinCode;

          // 3. Residential Address (auto-fill)
          _resAddressLineController.text = address;
          _resLandMarkController.text = landmark;
          _resDistrictController.text = district;
          _resAreaController.text = area;
          _resRegionController.text = region;
          _resPinCodeController.text = pinCode;
        });
        debugPrint("✅ _fetchLocationAndAddress: UI updated.");
      } else {
        debugPrint(
            "⚠️ _fetchLocationAndAddress: Widget was unmounted before UI update.");
      }
    } catch (e) {
      // --- 7. ERROR HANDLER ---
      debugPrint("❌ _fetchLocationAndAddress: ERROR caught: $e");
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content: Text('Error getting location/address: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      // --- 8. FINALLY BLOCK (ALWAYS RUNS) ---
      if (mounted) {
        debugPrint(
            "➡️ _fetchLocationAndAddress: FINALLY block. Setting _isFetchingLocation = false.");
        setState(() => _isFetchingLocation = false);
      } else {
        debugPrint("➡️ _fetchLocationAndAddress: FINALLY block. Widget unmounted.");
      }
    }
  }
  /// Validates and submits the form data to create a new dealer.  
  Future<void> _submitForm() async {
    // Pre-submission checks
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please get the current location first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the errors in the required fields.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isSubDealer && _selectedParentDealer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a parent dealer for the sub-dealer.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      // --- Construct the NEW Dealer object ---
      final newDealer = Dealer(
        // ID, createdAt, updatedAt are null by default from model
        userId: int.tryParse(widget.employee.id),
        type: _selectedType!,
        parentDealerId: _isSubDealer ? _selectedParentDealer!.id : null,
        name: _nameController.text,
        region: _regionController.text, // From location fetch
        area: _areaController.text, // From location fetch
        phoneNo: _phoneNoController.text,
        address: _addressController.text, // From location fetch
        pinCode: _text(_pinCodeController), // From location fetch
        latitude: _currentPosition!.latitude, // From location fetch
        longitude: _currentPosition!.longitude, // From location fetch
        dateOfBirth: _selectedDateOfBirth, // Required
        anniversaryDate: _selectedAnniversaryDate, // Optional
        totalPotential: _double(_totalPotentialController) ?? 0.0,
        bestPotential: _double(_bestPotentialController) ?? 0.0,
        brandSelling: _brandSellingController.text
            .split(',')
            .map((e) => e.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        feedbacks: _feedbacksController.text,
        remarks: _text(_remarksController), // Optional

        // NEW FIELDS
        verificationStatus: 'PENDING',
        whatsappNo: _text(_whatsappNoController), // Optional
        emailId: _text(_emailIdController), // Optional
        businessType: _text(_businessTypeController), // Required
        gstinNo: _text(_gstinNoController), // Required
        panNo: _text(_panNoController), // Required
        tradeLicNo: _text(_tradeLicNoController), // Required
        aadharNo: _text(_aadharNoController), // Required

        // Godown (All Required)
        godownSizeSqFt: _int(_godownSizeSqFtController),
        godownCapacityMTBags: _text(_godownCapacityMTBagsController),
        godownAddressLine: _text(_godownAddressLineController),
        godownLandMark: _text(_godownLandMarkController),
        godownDistrict: _text(_godownDistrictController),
        godownArea: _text(_godownAreaController),
        godownRegion: _text(_godownRegionController),
        godownPinCode: _text(_godownPinCodeController),

        // Residential (All Required)
        residentialAddressLine: _text(_resAddressLineController),
        residentialLandMark: _text(_resLandMarkController),
        residentialDistrict: _text(_resDistrictController),
        residentialArea: _text(_resAreaController),
        residentialRegion: _text(_resRegionController),
        residentialPinCode: _text(_resPinCodeController),

        // Bank (All Required)
        bankAccountName: _text(_bankAccountNameController),
        bankName: _text(_bankNameController),
        bankBranchAddress: _text(_bankBranchAddressController),
        bankAccountNumber: _text(_bankAccountNumberController),
        bankIfscCode: _text(_bankIfscCodeController),

        // Sales & Promoter (All Required)
        brandName: _text(_brandNameController),
        monthlySaleMT: _double(_monthlySaleMTController),
        noOfDealers: _int(_noOfDealersController),
        areaCovered: _text(_areaCoveredController),
        projectedMonthlySalesBestCementMT:
            _double(_projectedMonthlySalesBestCementMTController),
        noOfEmployeesInSales: _int(_noOfEmployeesInSalesController),

        // Declaration (All Required)
        declarationName: _text(_declarationNameController),
        declarationPlace: _text(_declarationPlaceController),
        declarationDate: _selectedDeclarationDate,

        // Docs (All Required)
        tradeLicencePicUrl: _text(_tradeLicencePicUrlController),
        shopPicUrl: _text(_shopPicUrlController),
        dealerPicUrl: _text(_dealerPicUrlController),
        blankChequePicUrl: _text(_blankChequePicUrlController),
        partnershipDeedPicUrl: _text(_partnershipDeedPicUrlController),

        // --- ADDED MISSING FIELDS from your schema (as null) ---
        dealerDevelopmentStatus: null,
        dealerDevelopmentObstacle: null,
        salesGrowthPercentage: null,
        noOfPJP: null,
      );

      // Get optional radius
      final double? radius = _double(_radiusController);

      // --- Send to the UPDATED API method ---
      // This now sends the full dealer object and optional radius
      await _apiService.createDealer(
        newDealer,
        radius: radius,
      );

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Dealer created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      navigator.pop(); // Close the form on success
    } catch (e) {
      debugPrint('--- DEALER CREATION FAILED ---\n$e');
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            'Failed to create dealer: ${e.toString()}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // --- (HELPER FUNCTIONS TO ADD INSIDE YOUR STATE CLASS) ---

  /// Helper to parse form fields (handles empty strings)
  String? _text(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();
  int? _int(TextEditingController c) => int.tryParse(c.text.trim());
  double? _double(TextEditingController c) => double.tryParse(c.text.trim());

  /// Helper for Date Pickers
  Future<void> _selectDate(
    BuildContext context, {
    required TextEditingController controller,
    required Function(DateTime) onDateSelected,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2101),
      // Optional: Match your modal's theme
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.amber,
              onPrimary: Colors.black,
              surface: const Color(0xFF020a67),
              onSurface: Colors.white,
            ),
            // --- THE FIX: Use DialogThemeData, not DialogTheme ---
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF0D47A1),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        onDateSelected(picked);
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // --- (NEW) PHOTON Autocomplete Handlers ---

  void _onGodownFocusChange() {
    // Hide suggestions when the text field loses focus
    if (!_godownFocusNode.hasFocus) {
      setState(() => _godownSuggestions = []);
    }
  }

  void _onResFocusChange() {
    // Hide suggestions when the text field loses focus
    if (!_resFocusNode.hasFocus) {
      setState(() => _resSuggestions = []);
    }
  }

  void _onGodownAddressChanged(String query) {
    if (_godownDebounce?.isActive ?? false) _godownDebounce!.cancel();
    _godownDebounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.length < 3) {
        setState(() {
          _godownSuggestions = [];
          _isSearchingGodown = false;
        });
        return;
      }
      setState(() => _isSearchingGodown = true);
      try {
        final suggestions = await _apiService.searchPhotonAddress(query);
        if (mounted) {
          setState(() {
            _godownSuggestions = suggestions;
            _isSearchingGodown = false;
          });
        }
      } catch (e) {
        debugPrint('Error searching godown address: $e');
        if (mounted) setState(() => _isSearchingGodown = false);
      }
    });
  }

  void _onResAddressChanged(String query) {
    if (_resDebounce?.isActive ?? false) _resDebounce!.cancel();
    _resDebounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.length < 3) {
        setState(() {
          _resSuggestions = [];
          _isSearchingRes = false;
        });
        return;
      }
      setState(() => _isSearchingRes = true);
      try {
        final suggestions = await _apiService.searchPhotonAddress(query);
        if (mounted) {
          setState(() {
            _resSuggestions = suggestions;
            _isSearchingRes = false;
          });
        }
      } catch (e) {
        debugPrint('Error searching residential address: $e');
        if (mounted) setState(() => _isSearchingRes = false);
      }
    });
  }

  void _onGodownSuggestionTapped(dynamic feature) {
    final props = feature['properties'];
    
    // Helper to build a clean address line
    String name = props['name'] ?? '';
    String street = props['street'] ?? '';
    String addressLine = '$name, $street'.replaceAll(RegExp(r'^, |,$'), '').trim();
    if(addressLine.isEmpty) addressLine = '${props['city'] ?? ''}, ${props['state'] ?? ''}'.trim();
    if(addressLine == ',') addressLine = 'Unknown Address';


    setState(() {
      _godownAddressLineController.text = addressLine;
      _godownLandMarkController.text = props['street'] ?? '';
      _godownDistrictController.text = props['county'] ?? props['city'] ?? '';
      _godownAreaController.text = props['city'] ?? props['state'] ?? '';
      _godownRegionController.text = props['state'] ?? '';
      _godownPinCodeController.text = props['postcode'] ?? '';
      _godownSuggestions = [];
    });
    _godownFocusNode.unfocus();
  }
  
  void _onResSuggestionTapped(dynamic feature) {
    final props = feature['properties'];

    String name = props['name'] ?? '';
    String street = props['street'] ?? '';
    String addressLine = '$name, $street'.replaceAll(RegExp(r'^, |,$'), '').trim();
    if(addressLine.isEmpty) addressLine = '${props['city'] ?? ''}, ${props['state'] ?? ''}'.trim();
    if(addressLine == ',') addressLine = 'Unknown Address';

    setState(() {
      _resAddressLineController.text = addressLine;
      _resLandMarkController.text = props['street'] ?? '';
      _resDistrictController.text = props['county'] ?? props['city'] ?? '';
      _resAreaController.text = props['city'] ?? props['state'] ?? '';
      _resRegionController.text = props['state'] ?? '';
      _resPinCodeController.text = props['postcode'] ?? '';
      _resSuggestions = [];
    });
    _resFocusNode.unfocus();
  }


  /// Helper function to create consistent styling for input fields.
  InputDecoration _inputDecoration(String label, {bool readOnly = false, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      fillColor: readOnly ? Colors.white10 : Colors.white.withOpacity(0.05),
      filled: true, // Fill all fields slightly
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white30),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.amber), // Use amber to focus
        borderRadius: BorderRadius.circular(12),
      ),
      // --- ADDED: Error styling for clarity ---
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.redAccent),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      suffixIcon: suffixIcon, // <-- Use the passed suffixIcon
      suffixIconColor: Colors.amber,
    );
  }

  /// Helper to build a standard text field
  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool readOnly = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon, // <-- Changed to Widget
    VoidCallback? onTap,
    FocusNode? focusNode, // <-- Added
    void Function(String)? onChanged, // <-- Added
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: _inputDecoration(label, readOnly: readOnly, suffixIcon: suffixIcon),
        validator: validator,
        onTap: onTap,
        focusNode: focusNode, // <-- Added
        onChanged: onChanged, // <-- Added
      ),
    );
  }

  /// Helper to build a date picker field
  /// --- UPDATED: Now accepts a validator ---
  Widget _buildDatePicker(
    TextEditingController controller,
    String label,
    Function(DateTime) onDateSelected, {
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: _buildTextField(
        controller,
        label,
        readOnly: true,
        suffixIcon: const Icon(Icons.calendar_today),
        validator: validator, // Pass validator through
        onTap: () => _selectDate(
          context,
          controller: controller,
          onDateSelected: onDateSelected,
        ),
      ),
    );
  }

  /// Helper to build a collapsible section
  Widget _buildSection({
    required String title,
    required List<Widget> children,
    bool initiallyExpanded = false, // Default is now false
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(title,
            style:
                const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        iconColor: Colors.amber,
        collapsedIconColor: Colors.white70,
        initiallyExpanded: initiallyExpanded,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- (UPDATED BUILD METHOD) ---
    return ClipRRect(
      borderRadius: BorderRadius.circular(24.0),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(24.0),
        color: const Color(0xFF020a67),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add New Dealer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed:
                    _isFetchingLocation ? null : _fetchLocationAndAddress,
                icon: _isFetchingLocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.my_location),
                label: const Text('Get Current Location & Address*'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- (Location fields - Unchanged but required via logic) ---
                      _buildTextField(_addressController, 'Address*',
                          readOnly: true),
                      _buildTextField(_regionController, 'Region*',
                          readOnly: true),
                      _buildTextField(_areaController, 'Area*', readOnly: true),
                      _buildTextField(_pinCodeController, 'PIN Code',
                          readOnly: true),

                      // --- (Sub-dealer switch - Unchanged) ---
                      SwitchListTile(
                        title: const Text(
                          'Is this a Sub-dealer?',
                          style: TextStyle(color: Colors.white),
                        ),
                        value: _isSubDealer,
                        onChanged: (bool value) {
                          setState(() {
                            _isSubDealer = value;
                            if (!value) _selectedParentDealer = null;
                          });
                        },
                        activeThumbColor: Colors.amber,
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_isSubDealer)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                          child: _isLoadingDealers
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                )
                              : DropdownButtonFormField<Dealer>(
                                  value: _selectedParentDealer,
                                  isExpanded: true,
                                  hint: const Text(
                                    'Select Parent Dealer*',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  dropdownColor: const Color(0xFF0D47A1),
                                  style: const TextStyle(color: Colors.white),
                                  decoration:
                                      _inputDecoration('Parent Dealer'),
                                  items: _parentDealers
                                      .map(
                                        (dealer) => DropdownMenuItem(
                                          value: dealer,
                                          child: Text(
                                            dealer.name,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) =>
                                      setState(() => _selectedParentDealer = value),
                                  validator: (value) =>
                                      _isSubDealer && value == null
                                          ? 'Please select a parent'
                                          : null,
                                ),
                        ),
                      const SizedBox(height: 16),

                      // --- (NEW: Sections for all fields) ---

                      // --- Primary Details ---
                      _buildSection(
                        title: 'Primary Details*',
                        initiallyExpanded: true,
                        children: [
                          _buildTextField(
                            _nameController,
                            'Dealer/Sub-dealer Name*',
                            validator: (v) =>
                                v!.isEmpty ? 'Name is required' : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: DropdownButtonFormField<String>(
                              value: _selectedType,
                              hint: const Text(
                                'Select Dealer Type*',
                                style: TextStyle(color: Colors.white70),
                              ),
                              dropdownColor: const Color(0xFF0D47A1),
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration('Dealer Type*'),
                              items: [
                                'Wholesaler',
                                'Retailer',
                                'Distributor',
                                'Other'
                              ]
                                  .map(
                                    (type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(type),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _selectedType = value),
                              validator: (value) =>
                                  value == null ? 'Please select a type' : null,
                            ),
                          ),
                          _buildTextField(
                            _phoneNoController,
                            'Phone Number*',
                            keyboardType: TextInputType.phone,
                            validator: (v) =>
                                v!.isEmpty ? 'Phone number is required' : null,
                          ),
                          _buildTextField(
                            _whatsappNoController,
                            'WhatsApp Number (Optional)',
                            keyboardType: TextInputType.phone,
                          ),
                          _buildTextField(
                            _emailIdController,
                            'Email (Optional)',
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty) return null;
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          // --- VALIDATOR ADDED ---
                          _buildTextField(
                            _businessTypeController,
                            'Business Type*',
                            validator: (v) =>
                                v!.isEmpty ? 'Business Type is required' : null,
                          ),
                          // --- VALIDATOR ADDED ---
                          _buildDatePicker(
                            _dateOfBirthController,
                            'Date of Birth*',
                            (date) => _selectedDateOfBirth = date,
                            validator: (v) =>
                                v!.isEmpty ? 'Date of Birth is required' : null,
                          ),
                          _buildDatePicker(
                            _anniversaryDateController,
                            'Anniversary Date (Optional)',
                            (date) => _selectedAnniversaryDate = date,
                          ),
                        ],
                      ),

                      // --- Business Vitals ---
                      _buildSection(
                        title: 'Business Vitals*',
                        initiallyExpanded: true,
                        children: [
                          _buildTextField(
                            _totalPotentialController,
                            'Total Potential*',
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty
                                ? 'Total Potential is required'
                                : null,
                          ),
                          _buildTextField(
                            _bestPotentialController,
                            'Best Potential*',
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty
                                ? 'Best Potential is required'
                                : null,
                          ),
                          _buildTextField(
                            _brandSellingController,
                            'Brands (comma-separated)*',
                            validator: (v) => v!.isEmpty
                                ? 'At least one brand is required'
                                : null,
                          ),
                          _buildTextField(
                            _feedbacksController,
                            'Feedbacks*',
                            validator: (v) =>
                                v!.isEmpty ? 'Feedback is required' : null,
                          ),
                          _buildTextField(
                            _remarksController,
                            'Remarks (Optional)',
                          ),
                        ],
                      ),

                      // --- REQUIRED Sections ---
                      _buildSection(
                        title: 'Identification*',
                        initiallyExpanded: true,
                        children: [
                          _buildTextField(_gstinNoController, 'GSTIN No.*',
                              validator: (v) =>
                                  v!.isEmpty ? 'GSTIN No. is required' : null),
                          _buildTextField(_panNoController, 'PAN No.*',
                              validator: (v) =>
                                  v!.isEmpty ? 'PAN No. is required' : null),
                          _buildTextField(
                              _tradeLicNoController, 'Trade License No.*',
                              validator: (v) => v!.isEmpty
                                  ? 'Trade License No. is required'
                                  : null),
                          _buildTextField(_aadharNoController, 'Aadhar No.*',
                              validator: (v) =>
                                  v!.isEmpty ? 'Aadhar No. is required' : null),
                        ],
                      ),
                      
                      // --- (NEW) GODOWN SECTION with Autocomplete ---
                      _buildSection(
                        title: 'Godown Details*',
                        initiallyExpanded: true,
                        children: [
                          _buildTextField(
                              _godownSizeSqFtController, 'Godown Size (sq. ft.)*',
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty
                                  ? 'Godown Size is required'
                                  : null),
                          _buildTextField(_godownCapacityMTBagsController,
                              'Godown Capacity (MT/Bags)*',
                              validator: (v) => v!.isEmpty
                                  ? 'Godown Capacity is required'
                                  : null),
                          
                          // --- Autocomplete Text Field ---
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _godownAddressLineController,
                                  focusNode: _godownFocusNode,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _inputDecoration(
                                    'Godown Address* (Type to search...)',
                                    suffixIcon: _isSearchingGodown
                                      ? const SizedBox(height: 20, width: 20, child: Padding(
                                          padding: EdgeInsets.all(14.0), // Adjust padding
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                                        ))
                                      : null,
                                  ),
                                  onChanged: _onGodownAddressChanged,
                                  validator: (v) => v!.isEmpty
                                    ? 'Godown Address is required'
                                    : null,
                                ),
                                if (_isSearchingGodown && _godownSuggestions.isEmpty)
                                  const LinearProgressIndicator(backgroundColor: Colors.amber),
                                // --- Suggestion List ---
                                if (_godownSuggestions.isNotEmpty)
                                  Container(
                                    height: 150,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: ListView.builder(
                                      itemCount: _godownSuggestions.length,
                                      itemBuilder: (context, index) {
                                        final suggestion = _godownSuggestions[index];
                                        final props = suggestion['properties'];
                                        final title = props['name'] ?? props['street'] ?? 'Unknown';
                                        final subtitle = '${props['city'] ?? ''}, ${props['state'] ?? ''} ${props['postcode'] ?? ''}'.trim();
                                        
                                        return ListTile(
                                          leading: const Icon(Icons.location_on_outlined, color: Colors.white70),
                                          title: Text(title, style: const TextStyle(color: Colors.white)),
                                          subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
                                          onTap: () => _onGodownSuggestionTapped(suggestion),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // --- Other Godown Fields ---
                          _buildTextField(
                              _godownLandMarkController, 'Godown Landmark*'),
                          _buildTextField(
                              _godownDistrictController, 'Godown District*'),
                          _buildTextField(_godownAreaController, 'Godown Area*'),
                          _buildTextField(
                              _godownRegionController, 'Godown Region*'),
                          _buildTextField(
                              _godownPinCodeController, 'Godown PIN Code*',
                              keyboardType: TextInputType.number),
                        ],
                      ),
                      
                      // --- (NEW) RESIDENTIAL SECTION with Autocomplete ---
                      _buildSection(
                        title: 'Residential Address*',
                        initiallyExpanded: true,
                        children: [
                          // --- Autocomplete Text Field ---
                           Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _resAddressLineController,
                                  focusNode: _resFocusNode,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _inputDecoration(
                                    'Residential Address* (Type to search...)',
                                    suffixIcon: _isSearchingRes
                                      ? const SizedBox(height: 20, width: 20, child: Padding(
                                          padding: EdgeInsets.all(14.0), // Adjust padding
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                                        ))
                                      : null,
                                  ),
                                  onChanged: _onResAddressChanged,
                                  validator: (v) => v!.isEmpty
                                    ? 'Residential Address is required'
                                    : null,
                                ),
                                if (_isSearchingRes && _resSuggestions.isEmpty)
                                  const LinearProgressIndicator(backgroundColor: Colors.amber),
                                // --- Suggestion List ---
                                if (_resSuggestions.isNotEmpty)
                                  Container(
                                    height: 150,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: ListView.builder(
                                      itemCount: _resSuggestions.length,
                                      itemBuilder: (context, index) {
                                        final suggestion = _resSuggestions[index];
                                        final props = suggestion['properties'];
                                        final title = props['name'] ?? props['street'] ?? 'Unknown';
                                        final subtitle = '${props['city'] ?? ''}, ${props['state'] ?? ''} ${props['postcode'] ?? ''}'.trim();
                                        
                                        return ListTile(
                                          leading: const Icon(Icons.location_on_outlined, color: Colors.white70),
                                          title: Text(title, style: const TextStyle(color: Colors.white)),
                                          subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
                                          onTap: () => _onResSuggestionTapped(suggestion),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // --- Other Residential Fields ---
                          _buildTextField(
                              _resLandMarkController, 'Residential Landmark*'),
                          _buildTextField(
                              _resDistrictController, 'Residential District*'),
                          _buildTextField(
                              _resAreaController, 'Residential Area*'),
                          _buildTextField(
                              _resRegionController, 'Residential Region*'),
                          _buildTextField(
                              _resPinCodeController, 'Residential PIN Code*',
                              keyboardType: TextInputType.number),
                        ],
                      ),

                      _buildSection(
                        title: 'Bank Details*',
                        initiallyExpanded: true,
                        children: [
                          _buildTextField(
                              _bankAccountNameController, 'Bank Account Name*',
                              validator: (v) => v!.isEmpty
                                  ? 'Bank Account Name is required'
                                  : null),
                          _buildTextField(_bankNameController, 'Bank Name*',
                              validator: (v) =>
                                  v!.isEmpty ? 'Bank Name is required' : null),
                          // --- ✅ THE FIX: Corrected 'vB' to 'v' ---
                          _buildTextField(_bankBranchAddressController,
                              'Bank Branch Address*',
                              validator: (v) => v!.isEmpty
                                  ? 'Bank Branch Address is required'
                                  : null),
                          _buildTextField(_bankAccountNumberController,
                              'Bank Account Number*',
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty
                                  ? 'Bank Account Number is required'
                                  : null),
                          _buildTextField(
                              _bankIfscCodeController, 'Bank IFSC Code*',
                              validator: (v) => v!.isEmpty
                                  ? 'Bank IFSC Code is required'
                                  : null),
                        ],
                      ),
                      _buildSection(
                        title: 'Sales & Promoter*',
                        initiallyExpanded: true,
                        children: [
                          _buildTextField(_brandNameController, 'Brand Name*',
                              validator: (v) =>
                                  v!.isEmpty ? 'Brand Name is required' : null),
                          _buildTextField(
                              _monthlySaleMTController, 'Monthly Sale (MT)*',
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty
                                  ? 'Monthly Sale is required'
                                  : null),
                          _buildTextField(
                              _noOfDealersController, 'No. of Dealers*',
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty
                                  ? 'No. of Dealers is required'
                                  : null),
                          _buildTextField(
                              _areaCoveredController, 'Area Covered*',
                              validator: (v) =>
                                  v!.isEmpty ? 'Area Covered is required' : null),
                          _buildTextField(
                              _projectedMonthlySalesBestCementMTController,
                              'Projected Monthly Sales (Best Cement MT)*',
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty
                                  ? 'Projected Sales are required'
                                  : null),
                          _buildTextField(_noOfEmployeesInSalesController,
                              'No. of Sales Employees*',
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty
                                  ? 'No. of Employees is required'
                                  : null),
                        ],
                      ),
                      _buildSection(
                        title: 'Declaration*',
                        initiallyExpanded: true,
                        children: [
                          _buildTextField(
                              _declarationNameController, 'Declaration Name*',
                              validator: (v) => v!.isEmpty
                                  ? 'Declaration Name is required'
                                  : null),
                          _buildTextField(
                              _declarationPlaceController, 'Declaration Place*',
                              validator: (v) => v!.isEmpty
                                  ? 'Declaration Place is required'
                                  : null),
                          _buildDatePicker(
                            _declarationDateController,
                            'Declaration Date*',
                            (date) => _selectedDeclarationDate = date.toUtc(),
                            validator: (v) => v!.isEmpty
                                ? 'Declaration Date is required'
                                : null,
                          ),
                        ],
                      ),
                      _buildSection(
                        title: 'Geofence (Optional)',
                        initiallyExpanded: false, // This one is still optional
                        children: [
                          _buildTextField(_radiusController,
                              'Geofence Radius (meters)',
                              keyboardType: TextInputType.number,
                              validator: (v) {
                            if (v == null || v.isEmpty) return null;
                            final r = double.tryParse(v);
                            if (r == null) return 'Must be a number';
                            if (r < 10 || r > 10000) {
                              return 'Must be between 10 and 10000';
                            }
                            return null;
                          }),
                        ],
                      ),
                      _buildSection(
                        title: 'Document URLs*',
                        initiallyExpanded: true,
                        children: [
                          _buildTextField(_tradeLicencePicUrlController,
                              'Trade License Pic URL*',
                              validator: (v) => v!.isEmpty
                                  ? 'Trade License URL is required'
                                  : null),
                          _buildTextField(
                              _shopPicUrlController, 'Shop Pic URL*',
                              validator: (v) =>
                                  v!.isEmpty ? 'Shop URL is required' : null),
                          _buildTextField(
                              _dealerPicUrlController, 'Dealer Pic URL*',
                              validator: (v) =>
                                  v!.isEmpty ? 'Dealer URL is required' : null),
                          _buildTextField(_blankChequePicUrlController,
                              'Blank Cheque Pic URL*',
                              validator: (v) => v!.isEmpty
                                  ? 'Blank Cheque URL is required'
                                  : null),
                          _buildTextField(_partnershipDeedPicUrlController,
                              'Partnership Deed Pic URL*',
                              validator: (v) => v!.isEmpty
                                  ? 'Partnership Deed URL is required'
                                  : null),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSubmitting || _currentPosition == null
                    ? null
                    : _submitForm,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  // --- UPDATED: Disable button if location is not yet fetched ---
                  disabledBackgroundColor: _currentPosition == null 
                    ? Colors.grey.withOpacity(0.5) 
                    : null,
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('SUBMIT DEALER'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

