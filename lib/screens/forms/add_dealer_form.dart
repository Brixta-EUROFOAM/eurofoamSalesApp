import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_radar/flutter_radar.dart';
import '../../models/employee_model.dart';
import '../../models/dealer_model.dart';
import '../../api/api_service.dart';

class AddDealerForm extends StatefulWidget {
  final Employee employee;
  const AddDealerForm({super.key, required this.employee});

  @override
  State<AddDealerForm> createState() => _AddDealerFormState();
}

class _AddDealerFormState extends State<AddDealerForm> {
  // --- Form and State Management (Much Simpler) ---
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

  // --- ✅ ONLY ESSENTIAL Controllers ---
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
  final _radiusController = TextEditingController(text: '25'); // Optional Geofence


  @override
  void initState() {
    super.initState();
    _fetchParentDealers();
  }

  @override
  void dispose() {
    // --- ✅ Dispose only essential controllers ---
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
    _radiusController.dispose();
    super.dispose();
  }

  /// Fetches main dealers to act as potential parent dealers.
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

  /// Gets location and auto-fills the *required* address fields.
  Future<void> _fetchLocationAndAddress() async {
    debugPrint("➡️ _fetchLocationAndAddress: STARTING");
    setState(() => _isFetchingLocation = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      debugPrint("➡️ _fetchLocationAndAddress: Checking permissions...");
      String? status = await Radar.getPermissionsStatus();
      if (status == 'DENIED' || status == 'NOT_DETERMINED') {
        status = await Radar.requestPermissions(true);
      }
      if (status != 'GRANTED_BACKGROUND' && status != 'GRANTED_FOREGROUND') {
        throw Exception('Location permissions are required.');
      }
      debugPrint("✅ _fetchLocationAndAddress: Permissions OK.");

      debugPrint("➡️ _fetchLocationAndAddress: Checking if location service is enabled...");
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }
      debugPrint("✅ _fetchLocationAndAddress: Location service is enabled.");

      debugPrint("📡 _fetchLocationAndAddress: Calling Geolocator.getCurrentPosition()...");
      final Position bestPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      debugPrint("📡 _fetchLocationAndAddress: Calling reverseGeocodeWithRadar...");
      final addressDetails = await _apiService.reverseGeocodeWithRadar(
        latitude: bestPosition.latitude,
        longitude: bestPosition.longitude,
      );

      // --- ✅ SIMPLIFIED: Populate ONLY the main address block ---
      if (mounted) {
        debugPrint("➡️ _fetchLocationAndAddress: Updating UI with controllers...");
        setState(() {
          _currentPosition = bestPosition;
          
          _addressController.text = addressDetails['address'] ?? '';
          _regionController.text = addressDetails['region'] ?? '';
          _areaController.text = addressDetails['area'] ?? '';
          _pinCodeController.text = addressDetails['pinCode'] ?? '';
        });
        debugPrint("✅ _fetchLocationAndAddress: UI updated.");
      }
    } catch (e) {
      debugPrint("❌ _fetchLocationAndAddress: ERROR caught: $e");
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
      // --- ✅ SIMPLIFIED: Construct the NEW Dealer object ---
      // Only includes fields that are .notNull() in your schema
      final newDealer = Dealer(
        userId: int.tryParse(widget.employee.id),
        type: _selectedType!,
        parentDealerId: _isSubDealer ? _selectedParentDealer!.id : null,
        name: _nameController.text,
        region: _regionController.text, // From location
        area: _areaController.text, // From location
        phoneNo: _phoneNoController.text,
        address: _addressController.text, // From location
        pinCode: _text(_pinCodeController), // From location
        latitude: _currentPosition!.latitude, // From location
        longitude: _currentPosition!.longitude, // From location
        
        totalPotential: _double(_totalPotentialController) ?? 0.0,
        bestPotential: _double(_bestPotentialController) ?? 0.0,
        brandSelling: _brandSellingController.text
            .split(',')
            .map((e) => e.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        feedbacks: _feedbacksController.text,
        remarks: _text(_remarksController), // Optional
        
        verificationStatus: 'PENDING', // Set default status

        // --- ALL OTHER 50+ FIELDS ARE REMOVED ---
        // The schema will handle them as NULL
      );

      final double? radius = _double(_radiusController);

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

  // --- (Helper functions) ---

  String? _text(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();
  double? _double(TextEditingController c) => double.tryParse(c.text.trim());

  InputDecoration _inputDecoration(String label, {bool readOnly = false, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      fillColor: readOnly ? Colors.white10 : Colors.white.withOpacity(0.05),
      filled: true, 
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white30),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.amber), 
        borderRadius: BorderRadius.circular(12),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.redAccent),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      suffixIcon: suffixIcon,
      suffixIconColor: Colors.amber,
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool readOnly = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: _inputDecoration(label, readOnly: readOnly),
        validator: validator,
      ),
    );
  }

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
                      // --- Location fields (read-only, filled by button) ---
                      _buildTextField(_addressController, 'Address*',
                          readOnly: true),
                      _buildTextField(_regionController, 'Region*',
                          readOnly: true),
                      _buildTextField(_areaController, 'Area*', readOnly: true),
                      _buildTextField(_pinCodeController, 'PIN Code',
                          readOnly: true),

                      // --- Sub-dealer switch ---
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

                      // --- ✅ SIMPLIFIED: Only two sections left ---

                      // --- 1. Primary Details ---
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
                        ],
                      ),

                      // --- 2. Business Vitals ---
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

                      // --- Optional Geofence ---
                      _buildSection(
                        title: 'Geofence (Optional)',
                        initiallyExpanded: false, 
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