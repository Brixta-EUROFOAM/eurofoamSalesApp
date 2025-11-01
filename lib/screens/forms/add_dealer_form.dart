// lib/screens/forms/add_dealer_form.dart

// --- (All imports needed for this form) ---
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
// Note: Make sure this import matches your pubspec.yaml
import 'package:flutter_radar/flutter_radar.dart'; 

// --- (Use '..' to go up one directory from 'forms' to 'models'/'services') ---
import '../../models/employee_model.dart';
import '../../models/dealer_model.dart';
import '../../api/api_service.dart';

// --- (Class is public: "AddDealerForm") ---
class AddDealerForm extends StatefulWidget {
  final Employee employee;
  const AddDealerForm({Key? key, required this.employee}) : super(key: key);

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

  // --- (Controllers for old fields) ---
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

  // --- (NEW Controllers for all new fields) ---

  // Primary Details
  final _whatsappNoController = TextEditingController();
  final _emailIdController = TextEditingController();
  final _businessTypeController = TextEditingController(); // The *new* field
  final _dateOfBirthController = TextEditingController();
  final _anniversaryDateController = TextEditingController();
  DateTime? _selectedDateOfBirth;
  DateTime? _selectedAnniversaryDate;

  // Identification
  final _gstinNoController = TextEditingController();
  final _panNoController = TextEditingController();
  final _tradeLicNoController = TextEditingController();
  final _aadharNoController = TextEditingController();

  // Godown
  final _godownSizeSqFtController = TextEditingController();
  final _godownCapacityMTBagsController = TextEditingController();
  final _godownAddressLineController = TextEditingController();
  final _godownLandMarkController = TextEditingController();
  final _godownDistrictController = TextEditingController();
  final _godownAreaController = TextEditingController();
  final _godownRegionController = TextEditingController();
  final _godownPinCodeController = TextEditingController();

  // Residential
  final _resAddressLineController = TextEditingController();
  final _resLandMarkController = TextEditingController();
  final _resDistrictController = TextEditingController();
  final _resAreaController = TextEditingController();
  final _resRegionController = TextEditingController();
  final _resPinCodeController = TextEditingController();

  // Bank
  final _bankAccountNameController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankBranchAddressController = TextEditingController();
  final _bankAccountNumberController = TextEditingController();
  final _bankIfscCodeController = TextEditingController();

  // Sales & Promoter
  final _brandNameController = TextEditingController();
  final _monthlySaleMTController = TextEditingController();
  final _noOfDealersController = TextEditingController();
  final _areaCoveredController = TextEditingController();
  final _projectedMonthlySalesBestCementMTController = TextEditingController();
  final _noOfEmployeesInSalesController = TextEditingController();

  // Declaration
  final _declarationNameController = TextEditingController();
  final _declarationPlaceController = TextEditingController();
  final _declarationDateController = TextEditingController();
  DateTime? _selectedDeclarationDate;

  // Geofence
  final _radiusController = TextEditingController(text: '25'); // Default 25m

  // Document URLs
  final _tradeLicencePicUrlController = TextEditingController();
  final _shopPicUrlController = TextEditingController();
  final _dealerPicUrlController = TextEditingController();
  final _blankChequePicUrlController = TextEditingController();
  final _partnershipDeedPicUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchParentDealers();
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

    // --- (Dispose NEW controllers) ---
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
    setState(() => _isFetchingLocation = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    StreamSubscription<Position>? positionStreamSubscription;

    try {
      // 1. Permissions
      String? status = await Radar.getPermissionsStatus();
      if (status == 'DENIED' || status == 'NOT_DETERMINED') {
        status = await Radar.requestPermissions(true);
      }
      if (status != 'GRANTED_BACKGROUND' && status != 'GRANTED_FOREGROUND') {
        throw Exception('Location permissions are required.');
      }

      // 2. Service Check
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services are disabled.');

      // 3. Listen to stream for 5 seconds
      List<Position> positions = [];
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      );

      positionStreamSubscription =
          Geolocator.getPositionStream(locationSettings: locationSettings)
              .listen((Position position) {
        debugPrint("Received location reading: Accuracy ${position.accuracy}");
        positions.add(position);
      });

      await Future.delayed(const Duration(seconds: 5));
      await positionStreamSubscription.cancel();
      positionStreamSubscription = null;

      if (positions.isEmpty) {
        throw Exception('Failed to get any location readings in 5 seconds.');
      }

      final Position bestPosition = positions.last;
      debugPrint("Using position with accuracy: ${bestPosition.accuracy}");

      // 4. Reverse Geocode
      final addressDetails = await _apiService.reverseGeocodeWithRadar(
        latitude: bestPosition.latitude,
        longitude: bestPosition.longitude,
      );

      // 5. Update UI
      if (mounted) {
        setState(() {
          _currentPosition = bestPosition;
          _addressController.text = addressDetails['address']!;
          _regionController.text = addressDetails['region']!;
          _areaController.text = addressDetails['area']!;
          _pinCodeController.text = addressDetails['pinCode']!;
        });
      }
    } catch (e) {
      if (positionStreamSubscription != null) {
        await positionStreamSubscription.cancel();
      }
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content: Text('Error getting location/address: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isFetchingLocation = false);
      }
    }
  }

  /// Validates and submits the form data to create a new dealer.  
  Future<void> _submitForm() async {
    // --- (UPDATED SUBMIT LOGIC) ---

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
        dateOfBirth: _selectedDateOfBirth,
        anniversaryDate: _selectedAnniversaryDate,
        totalPotential: _double(_totalPotentialController) ?? 0.0,
        bestPotential: _double(_bestPotentialController) ?? 0.0,
        brandSelling: _brandSellingController.text
            .split(',')
            .map((e) => e.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        feedbacks: _feedbacksController.text,
        remarks: _text(_remarksController),

        // NEW FIELDS
        verificationStatus: 'PENDING',
        whatsappNo: _text(_whatsappNoController),
        emailId: _text(_emailIdController),
        businessType: _text(_businessTypeController),
        gstinNo: _text(_gstinNoController),
        panNo: _text(_panNoController),
        tradeLicNo: _text(_tradeLicNoController),
        aadharNo: _text(_aadharNoController),

        // Godown
        godownSizeSqFt: _int(_godownSizeSqFtController),
        godownCapacityMTBags: _text(_godownCapacityMTBagsController),
        godownAddressLine: _text(_godownAddressLineController),
        godownLandMark: _text(_godownLandMarkController),
        godownDistrict: _text(_godownDistrictController),
        godownArea: _text(_godownAreaController),
        godownRegion: _text(_godownRegionController),
        godownPinCode: _text(_godownPinCodeController),

        // Residential
        residentialAddressLine: _text(_resAddressLineController),
        residentialLandMark: _text(_resLandMarkController),
        residentialDistrict: _text(_resDistrictController),
        residentialArea: _text(_resAreaController),
        residentialRegion: _text(_resRegionController),
        residentialPinCode: _text(_resPinCodeController),

        // Bank
        bankAccountName: _text(_bankAccountNameController),
        bankName: _text(_bankNameController),
        bankBranchAddress: _text(_bankBranchAddressController),
        bankAccountNumber: _text(_bankAccountNumberController),
        bankIfscCode: _text(_bankIfscCodeController),

        // Sales & Promoter
        brandName: _text(_brandNameController),
        monthlySaleMT: _double(_monthlySaleMTController),
        noOfDealers: _int(_noOfDealersController),
        areaCovered: _text(_areaCoveredController),
        projectedMonthlySalesBestCementMT:
            _double(_projectedMonthlySalesBestCementMTController),
        noOfEmployeesInSales: _int(_noOfEmployeesInSalesController),

        // Declaration
        declarationName: _text(_declarationNameController),
        declarationPlace: _text(_declarationPlaceController),
        declarationDate: _selectedDeclarationDate,

        // Docs
        tradeLicencePicUrl: _text(_tradeLicencePicUrlController),
        shopPicUrl: _text(_shopPicUrlController),
        dealerPicUrl: _text(_dealerPicUrlController),
        blankChequePicUrl: _text(_blankChequePicUrlController),
        partnershipDeedPicUrl: _text(_partnershipDeedPicUrlController),
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
            dialogBackgroundColor: const Color(0xFF0D47A1),
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

  /// Helper function to create consistent styling for input fields.
  InputDecoration _inputDecoration(String label, {bool readOnly = false}) {
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
    Icon? suffixIcon,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: _inputDecoration(label, readOnly: readOnly).copyWith(
          suffixIcon: suffixIcon,
        ),
        validator: validator,
        onTap: onTap,
      ),
    );
  }

  /// Helper to build a date picker field
  Widget _buildDatePicker(
    TextEditingController controller,
    String label,
    Function(DateTime) onDateSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: _buildTextField(
        controller,
        label,
        readOnly: true,
        suffixIcon: const Icon(Icons.calendar_today),
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
    bool initiallyExpanded = false,
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
                label: const Text('Get Current Location & Address'),
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
                      // --- (Location fields - Unchanged) ---
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
                        title: 'Primary Details',
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
                              decoration: _inputDecoration('Dealer Type'),
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
                          _buildTextField(
                            _businessTypeController,
                            'Business Type (Optional)',
                          ),
                          _buildDatePicker(
                            _dateOfBirthController,
                            'Date of Birth (Optional)',
                            (date) => _selectedDateOfBirth = date,
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
                        title: 'Business Vitals',
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

                      // --- Optional Sections ---
                      _buildSection(
                        title: 'Identification (Optional)',
                        children: [
                          _buildTextField(_gstinNoController, 'GSTIN No.'),
                          _buildTextField(_panNoController, 'PAN No.'),
                          _buildTextField(
                              _tradeLicNoController, 'Trade License No.'),
                          _buildTextField(_aadharNoController, 'Aadhar No.'),
                        ],
                      ),
                      _buildSection(
                        title: 'Godown Details (Optional)',
                        children: [
                          _buildTextField(
                              _godownSizeSqFtController, 'Godown Size (sq. ft.)',
                              keyboardType: TextInputType.number),
                          _buildTextField(_godownCapacityMTBagsController,
                              'Godown Capacity (MT/Bags)'),
                          _buildTextField(
                              _godownAddressLineController, 'Godown Address'),
                          _buildTextField(
                              _godownLandMarkController, 'Godown Landmark'),
                          _buildTextField(
                              _godownDistrictController, 'Godown District'),
                          _buildTextField(_godownAreaController, 'Godown Area'),
                          _buildTextField(
                              _godownRegionController, 'Godown Region'),
                          _buildTextField(
                              _godownPinCodeController, 'Godown PIN Code',
                              keyboardType: TextInputType.number),
                        ],
                      ),
                      _buildSection(
                        title: 'Residential Address (Optional)',
                        children: [
                          _buildTextField(
                              _resAddressLineController, 'Residential Address'),
                          _buildTextField(
                              _resLandMarkController, 'Residential Landmark'),
                          _buildTextField(
                              _resDistrictController, 'Residential District'),
                          _buildTextField(_resAreaController, 'Residential Area'),
                          _buildTextField(
                              _resRegionController, 'Residential Region'),
                          _buildTextField(
                              _resPinCodeController, 'Residential PIN Code',
                              keyboardType: TextInputType.number),
                        ],
                      ),
                      _buildSection(
                        title: 'Bank Details (Optional)',
                        children: [
                          _buildTextField(
                              _bankAccountNameController, 'Bank Account Name'),
                          _buildTextField(_bankNameController, 'Bank Name'),
                          _buildTextField(_bankBranchAddressController,
                              'Bank Branch Address'),
                          _buildTextField(_bankAccountNumberController,
                              'Bank Account Number',
                              keyboardType: TextInputType.number),
                          _buildTextField(
                              _bankIfscCodeController, 'Bank IFSC Code'),
                        ],
                      ),
                      _buildSection(
                        title: 'Sales & Promoter (Optional)',
                        children: [
                          _buildTextField(_brandNameController, 'Brand Name'),
                          _buildTextField(
                              _monthlySaleMTController, 'Monthly Sale (MT)',
                              keyboardType: TextInputType.number),
                          _buildTextField(
                              _noOfDealersController, 'No. of Dealers',
                              keyboardType: TextInputType.number),
                          _buildTextField(
                              _areaCoveredController, 'Area Covered'),
                          _buildTextField(
                              _projectedMonthlySalesBestCementMTController,
                              'Projected Monthly Sales (Best Cement MT)',
                              keyboardType: TextInputType.number),
                          _buildTextField(_noOfEmployeesInSalesController,
                              'No. of Sales Employees',
                              keyboardType: TextInputType.number),
                        ],
                      ),
                      _buildSection(
                        title: 'Declaration (Optional)',
                        children: [
                          _buildTextField(
                              _declarationNameController, 'Declaration Name'),
                          _buildTextField(
                              _declarationPlaceController, 'Declaration Place'),
                          _buildDatePicker(
                            _declarationDateController,
                            'Declaration Date',
                            (date) => _selectedDeclarationDate = date.toUtc(),
                          ),
                        ],
                      ),
                      _buildSection(
                        title: 'Geofence (Optional)',
                        children: [
                          _buildTextField(_radiusController,
                              'Geofence Radius (meters)',
                              keyboardType: TextInputType.number,
                              validator: (v) {
                            if (v == null || v.isEmpty) return null;
                            final r = double.tryParse(v);
                            if (r == null) return 'Must be a number';
                            if (r < 10 || r > 10000)
                              return 'Must be between 10 and 10000';
                            return null;
                          }),
                        ],
                      ),
                      _buildSection(
                        title: 'Document URLs (Optional)',
                        children: [
                          _buildTextField(_tradeLicencePicUrlController,
                              'Trade License Pic URL'),
                          _buildTextField(
                              _shopPicUrlController, 'Shop Pic URL'),
                          _buildTextField(
                              _dealerPicUrlController, 'Dealer Pic URL'),
                          _buildTextField(_blankChequePicUrlController,
                              'Blank Cheque Pic URL'),
                          _buildTextField(_partnershipDeedPicUrlController,
                              'Partnership Deed Pic URL'),
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
