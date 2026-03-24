// lib/technicalSide/screens/forms/add_site_form.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/technicalSide/models/sites_model.dart';
import 'package:salesmanapp/salesSide/models/employee_model.dart';
import 'package:salesmanapp/salesSide/models/dealer_model.dart';
import 'package:salesmanapp/technicalSide/models/mason_pc_model.dart';
import 'package:salesmanapp/widgets/reusable_functions.dart';

class AddSiteForm extends StatefulWidget {
  final Employee employee;
  const AddSiteForm({super.key, required this.employee});

  @override
  State<AddSiteForm> createState() => _AddSiteFormState();
}

class _AddSiteFormState extends State<AddSiteForm> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Controllers
  final _siteNameController = TextEditingController();
  final _concernedPersonController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaController = TextEditingController();

  String? _selectedRegion;
  String? _selectedStage;
  String? _selectedType;
  bool _isFetchingLocation = false;
  bool _isSubmitting = false;
  Position? _currentPosition;

  // --- Association State ---
  final List<Dealer> _selectedDealers = [];
  final List<Mason> _selectedMasons = [];

  final List<String> _stages = [
    'Foundation',
    'Plinth',
    'Lintel',
    'Roofing',
    'Finishing',
  ];
  final List<String> _types = [
    'Residential',
    'Commercial',
    'Government',
    'Industrial',
  ];
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

  // --- 🎨 FINTECH THEME PALETTE ---
  static const Color _bgLight = Color(0xFFF8FAFC); // Slate 50
  static const Color _surfaceWhite = Colors.white;
  static const Color _cardNavy = Color(0xFF0F172A); // Deep Navy
  static const Color _textDark = Color(0xFF1E293B); // Slate 800
  static const Color _textGrey = Color(0xFF64748B); // Slate 500
  static const Color _inputFill = Color(0xFFF1F5F9); // Slate 100
  static const Color _accentGreen = Color(0xFF10B981); // Emerald

  @override
  void initState() {
    super.initState();
    _areaController.text = widget.employee.area ?? '';
    // Auto-select region if it matches
    if (widget.employee.region != null &&
        _regionOptions.contains(widget.employee.region)) {
      _selectedRegion = widget.employee.region;
    }
  }

  @override
  void dispose() {
    _siteNameController.dispose();
    _concernedPersonController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  // --- LOCATION LOGIC ---
  Future<void> _getLocation() async {
    setState(() => _isFetchingLocation = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      Map<String, String> addressDetails = {};
      try {
        addressDetails = await _apiService.reverseGeocodeWithRadar(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      } catch (e) {
        debugPrint("Reverse geocoding failed: $e");
      }

      if (mounted) {
        setState(() {
          _currentPosition = position;
          if (addressDetails['address']?.isNotEmpty == true) {
            _addressController.text = addressDetails['address']!;
          }
          if (addressDetails['area']?.isNotEmpty == true) {
            _areaController.text = addressDetails['area']!;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  // --- SEARCH DIALOG HANDLERS ---
  Future<void> _openDealerSearch() async {
    final result = await openDealerSearch(
      context,
      lat: _currentPosition?.latitude,
      lng: _currentPosition?.longitude,
    );

    if (result != null && !_selectedDealers.any((d) => d.id == result.id)) {
      setState(() => _selectedDealers.add(result));
    }
  }

  Future<void> _openMasonSearch() async {
    final result = await openMasonSearch(context, _apiService);

    if (result != null && !_selectedMasons.any((m) => m.id == result.id)) {
      setState(() => _selectedMasons.add(result));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentPosition == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Location is required")));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final List<String> dealerIds = _selectedDealers
          .map((d) => d.id)
          .whereType<String>()
          .toList();
      final List<String> masonIds = _selectedMasons
          .map((m) => m.id)
          .whereType<String>()
          .toList();

      final site = TechnicalSite(
        siteName: _siteNameController.text,
        concernedPerson: _concernedPersonController.text,
        phoneNo: _phoneController.text,
        address: _addressController.text,
        area: _areaController.text,
        region: _selectedRegion!,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        siteType: _selectedType,
        stageOfConstruction: _selectedStage,
        constructionStartDate: DateTime.now(),
        associatedDealerIds: dealerIds,
        associatedMasonIds: masonIds,
      );

      await _apiService.createTechnicalSite(site);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Site Registered Successfully!"),
            backgroundColor: _accentGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Submission Failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: _bgLight,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _textDark,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Register Site",
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. SITE DETAILS CARD ---
              _buildCard(
                title: "Site Details",
                child: Column(
                  children: [
                    _buildFintechInput(
                      controller: _siteNameController,
                      label: "Site Name",
                      hint: "e.g. Galaxy Apartments",
                      icon: Icons.apartment_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildFintechInput(
                      controller: _concernedPersonController,
                      label: "Concerned Person",
                      hint: "e.g. Mr. Rajesh Kumar",
                      icon: Icons.person_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildFintechInput(
                      controller: _phoneController,
                      label: "Phone Number",
                      hint: "e.g. 9876543210",
                      icon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v!.length < 10 ? "Invalid Phone" : null,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFintechDropdown(
                            value: _selectedType,
                            label: "Type",
                            items: _types,
                            onChanged: (v) => setState(() => _selectedType = v),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFintechDropdown(
                            value: _selectedStage,
                            label: "Stage",
                            items: _stages,
                            onChanged: (v) =>
                                setState(() => _selectedStage = v),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- 2. LOCATION CARD ---
              _buildCard(
                title: "Geo-Tagging",
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _getLocation,
                            icon: _isFetchingLocation
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.my_location_rounded,
                                    size: 18,
                                  ),
                            label: Text(
                              _currentPosition == null
                                  ? "Fetch Location"
                                  : "Update Location",
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _cardNavy,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_currentPosition != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: _accentGreen,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Captured: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}",
                                style: const TextStyle(
                                  color: Color(0xFF15803D),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildFintechInput(
                      controller: _addressController,
                      label: "Address / Landmark",
                      hint: "Enter address...",
                      icon: Icons.map_rounded,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFintechDropdown(
                            value: _selectedRegion,
                            label: "Region",
                            items: _regionOptions,
                            onChanged: (v) =>
                                setState(() => _selectedRegion = v),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFintechInput(
                            controller: _areaController,
                            label: "Area",
                            hint: "City/Town",
                            icon: Icons.location_city_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- 3. ASSOCIATIONS CARD ---
              _buildCard(
                title: "Associations",
                child: Column(
                  children: [
                    _buildAssociationSection(
                      "Dealers",
                      _selectedDealers,
                      _openDealerSearch,
                      (item) => setState(() => _selectedDealers.remove(item)),
                    ),
                    const Divider(height: 32),
                    _buildAssociationSection(
                      "Masons",
                      _selectedMasons,
                      _openMasonSearch,
                      (item) => setState(() => _selectedMasons.remove(item)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // --- SUBMIT BUTTON ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _cardNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "REGISTER SITE",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _textDark,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildFintechInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textGrey,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator ?? (v) => v!.isEmpty ? "Required" : null,
          style: const TextStyle(color: _textDark, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            filled: true,
            fillColor: _inputFill,
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            prefixIcon: Icon(icon, color: _textGrey, size: 20),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
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
    required String? value,
    required String label,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textGrey,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _textGrey),
          decoration: InputDecoration(
            filled: true,
            fillColor: _inputFill,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssociationSection(
    String title,
    List items,
    VoidCallback onAdd,
    Function(dynamic) onDelete,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle_outline, size: 16),
              label: const Text("Add"),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ],
        ),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              "None added",
              style: TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
                fontSize: 13,
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map(
                  (item) => Chip(
                    label: Text(
                      item.name,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: _inputFill,
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () => onDelete(item),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}
