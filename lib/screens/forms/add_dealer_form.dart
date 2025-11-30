// lib/screens/forms/add_dealer_form.dart
import 'dart:async';
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
  // --- Form and State Management ---
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  bool _isSubmitting = false;
  bool _isFetchingLocation = false;

  // Location Data
  Position? _currentPosition;

  // Data for Dropdowns and Switches
  String? _selectedType;
  bool _isSubDealer = false;
  
  // Parent Dealer Selection
  String? _selectedParentDealerId; 
  final _parentDealerDisplayController = TextEditingController();

  // --- Controllers ---
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

  // --- 🎨 FINTECH THEME PALETTE ---
  static const Color _bgLight       = Color(0xFFF3F4F6); 
  static const Color _surfaceWhite  = Colors.white;
  static const Color _cardNavy      = Color(0xFF0F172A); 
  static const Color _textDark      = Color(0xFF111827); 
  static const Color _textGrey      = Color(0xFF6B7280); 
  static const Color _inputFill     = Color(0xFFF9FAFB); 
  static const Color _accentGreen   = Color(0xFF10B981); 

  @override
  void dispose() {
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
    _parentDealerDisplayController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocationAndAddress() async {
    setState(() => _isFetchingLocation = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // 1. Radar Permissions
      String? status = await Radar.getPermissionsStatus();
      if (status == 'DENIED' || status == 'NOT_DETERMINED') {
        status = await Radar.requestPermissions(true);
      }
      
      // 2. Geolocator Service Check
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled on device.');
      }

      // 3. Get Position
      final Position bestPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // 4. Reverse Geocode (Radar)
      // NOTE: This calls ApiService. Ensure ApiService has the implementation!
      final addressDetails = await _apiService.reverseGeocodeWithRadar(
        latitude: bestPosition.latitude,
        longitude: bestPosition.longitude,
      );

      if (mounted) {
        setState(() {
          _currentPosition = bestPosition;
          _addressController.text = addressDetails['address'] ?? '';
          _regionController.text = addressDetails['region'] ?? '';
          _areaController.text = addressDetails['area'] ?? '';
          _pinCodeController.text = addressDetails['pinCode'] ?? '';
        });
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Location Error: $e'), 
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }
  
  Future<void> _submitForm() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please get location first.'), backgroundColor: Colors.orange));
      return;
    }
    
    if (!_formKey.currentState!.validate()) return;

    if (_isSubDealer && _selectedParentDealerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a parent dealer.'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isSubmitting = true);
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final newDealer = Dealer(
        userId: int.tryParse(widget.employee.id),
        type: _selectedType!,
        parentDealerId: _isSubDealer ? _selectedParentDealerId : null,
        name: _nameController.text,
        region: _regionController.text,
        area: _areaController.text,
        phoneNo: _phoneNoController.text,
        address: _addressController.text,
        pinCode: _text(_pinCodeController),
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        totalPotential: _double(_totalPotentialController) ?? 0.0,
        bestPotential: _double(_bestPotentialController) ?? 0.0,
        brandSelling: _brandSellingController.text.split(',').map((e) => e.trim()).where((s) => s.isNotEmpty).toList(),
        feedbacks: _feedbacksController.text,
        remarks: _text(_remarksController),
        verificationStatus: 'PENDING',
      );

      // Default Radius
      const double radius = 50.0;

      await _apiService.createDealer(newDealer, radius: radius);

      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Dealer created successfully!'), backgroundColor: Colors.green));
      navigator.pop();
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String? _text(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
  double? _double(TextEditingController c) => double.tryParse(c.text.trim());

  // --- UI Helpers ---

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: _textGrey,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
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
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _textDark, fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          validator: validator ?? (v) => v!.isEmpty ? "Required" : null,
          style: const TextStyle(color: _textDark, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? Colors.grey.shade100 : _inputFill,
            hintText: hint,
            hintStyle: const TextStyle(color: _textGrey, fontSize: 14),
            prefixIcon: Icon(icon, color: _textGrey, size: 20),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _cardNavy, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFintechDropdown({
    required String? value,
    required String label,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    String? validatorMsg,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _textDark, fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          dropdownColor: _surfaceWhite,
          style: const TextStyle(color: _textDark, fontWeight: FontWeight.w500, fontSize: 14),
          items: items,
          onChanged: onChanged,
          validator: (val) => (validatorMsg != null && val == null) ? validatorMsg : null,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _textGrey),
          decoration: InputDecoration(
            filled: true,
            fillColor: _inputFill,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _cardNavy, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
          ),
        ),
      ],
    );
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textGrey, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Add New Dealer", style: TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Location Card ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _surfaceWhite,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.location_on, color: Colors.blueAccent, size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Text("Geo-Tagging", style: TextStyle(fontWeight: FontWeight.bold, color: _textDark)),
                            ],
                          ),
                          if (_isFetchingLocation)
                            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _cardNavy))
                          else
                            ElevatedButton.icon(
                              onPressed: _fetchLocationAndAddress,
                              icon: const Icon(Icons.my_location, size: 16),
                              label: Text(_currentPosition == null ? "Fetch" : "Update"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _cardNavy,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle, color: _accentGreen, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                "Captured: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}",
                                style: const TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _buildFintechInput(
                        controller: _addressController,
                        label: "Address",
                        hint: "Fetched automatically...",
                        icon: Icons.map_outlined,
                        readOnly: false,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildFintechInput(controller: _regionController, label: "Region", hint: "Region", icon: Icons.public, readOnly: false)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildFintechInput(controller: _areaController, label: "Area", hint: "Area", icon: Icons.share_location, readOnly: false)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildFintechInput(
                        controller: _pinCodeController,
                        label: "PIN Code",
                        hint: "PIN",
                        icon: Icons.pin_drop,
                        readOnly: false,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // --- Details Card ---
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _surfaceWhite,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader("Dealer Info"),
                      const SizedBox(height: 16),
                      
                      // --- SUB DEALER TOGGLE ---
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: _bgLight, borderRadius: BorderRadius.circular(12)),
                        child: SwitchListTile(
                          title: const Text('Is this a Sub-dealer?', style: TextStyle(color: _textDark, fontWeight: FontWeight.w600, fontSize: 14)),
                          value: _isSubDealer,
                          onChanged: (bool value) {
                            setState(() {
                              _isSubDealer = value;
                              if (!value) {
                                _selectedParentDealerId = null;
                                _parentDealerDisplayController.clear();
                              }
                            });
                          },
                          activeColor: _cardNavy,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      
                      if (_isSubDealer) ...[
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () async {
                            final Dealer? result = await showDialog(
                              context: context,
                              builder: (context) => _ServerDealerSearchDialog(api: _apiService),
                            );

                            if (result != null) {
                              setState(() {
                                _selectedParentDealerId = result.id;
                                _parentDealerDisplayController.text = result.name;
                              });
                            }
                          },
                          child: IgnorePointer(
                            child: _buildFintechInput(
                              controller: _parentDealerDisplayController,
                              label: "Parent Dealer",
                              hint: "Tap to search...",
                              icon: Icons.search,
                              validator: (v) => _selectedParentDealerId == null ? "Please select a parent dealer" : null,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                      _buildFintechInput(
                        controller: _nameController,
                        label: "Dealer/Firm Name",
                        hint: "e.g. A.K. Enterprises",
                        icon: Icons.store,
                      ),
                      
                      const SizedBox(height: 16),
                      _buildFintechDropdown(
                        value: _selectedType,
                        label: "Dealer Type",
                        items: ['Dealer Best', 'Dealer Non Best', 'Sub Dealer Best', 'Sub Dealer Non Best']
                            .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedType = val),
                        validatorMsg: 'Please select a type',
                      ),

                      const SizedBox(height: 16),
                      _buildFintechInput(
                        controller: _phoneNoController,
                        label: "Phone Number",
                        hint: "9876543210",
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // --- Business Vitals Card ---
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _surfaceWhite,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader("Business Vitals"),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildFintechInput(controller: _totalPotentialController, label: "Total Potential", hint: "0.0", icon: Icons.trending_up, keyboardType: TextInputType.number)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildFintechInput(controller: _bestPotentialController, label: "Best Potential", hint: "0.0", icon: Icons.star_border, keyboardType: TextInputType.number)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildFintechInput(
                        controller: _brandSellingController,
                        label: "Brands Selling",
                        hint: "e.g. BrandA, BrandB",
                        icon: Icons.branding_watermark,
                      ),
                      const SizedBox(height: 16),
                      _buildFintechInput(
                        controller: _feedbacksController,
                        label: "Feedback",
                        hint: "Market feedback...",
                        icon: Icons.feedback_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildFintechInput(
                        controller: _remarksController,
                        label: "Remarks (Optional)",
                        hint: "Any other notes...",
                        icon: Icons.note_alt_outlined,
                        validator: (v) => null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                
                // --- Submit Button ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting || _currentPosition == null ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _cardNavy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 4,
                      shadowColor: _cardNavy.withOpacity(0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                    child: _isSubmitting
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('SUBMIT DEALER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.0)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 🔎 SERVER-SIDE DEALER SEARCH DIALOG
// ==========================================

class _ServerDealerSearchDialog extends StatefulWidget {
  final ApiService api;
  const _ServerDealerSearchDialog({required this.api});

  @override
  State<_ServerDealerSearchDialog> createState() => _ServerDealerSearchDialogState();
}

class _ServerDealerSearchDialogState extends State<_ServerDealerSearchDialog> {
  List<Dealer> _dealers = [];
  bool _isLoading = false;
  Timer? _debounce;
  String _lastQuery = "";

  // Theme constants
  static const Color _textDark = Color(0xFF111827);
  static const Color _textGrey = Color(0xFF6B7280);
  static const Color _inputFill = Color(0xFFF9FAFB);

  @override
  void initState() {
    super.initState();
    _performSearch(""); 
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query != _lastQuery) {
        _performSearch(query);
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    _lastQuery = query;
    try {
      final results = await widget.api.fetchDealers(search: query, limit: 20);
      final parentsOnly = results.where((d) => d.parentDealerId == null).toList();

      if (mounted) {
        setState(() {
          _dealers = parentsOnly;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("Select Parent Dealer", style: TextStyle(color: _textDark, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              style: const TextStyle(color: _textDark),
              decoration: InputDecoration(
                hintText: "Search by name, phone...",
                hintStyle: const TextStyle(color: _textGrey),
                prefixIcon: const Icon(Icons.search, color: _textGrey),
                filled: true,
                fillColor: _inputFill,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _dealers.isEmpty
                    ? const Center(child: Text("No parent dealers found", style: TextStyle(color: _textGrey)))
                    : ListView.separated(
                        itemCount: _dealers.length,
                        separatorBuilder: (ctx, i) => const Divider(height: 1, color: Color(0xFFE5E7EB)),
                        itemBuilder: (context, index) {
                          final dealer = _dealers[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(dealer.name, style: const TextStyle(color: _textDark, fontWeight: FontWeight.w600)),
                            subtitle: Text("${dealer.region}, ${dealer.area}", style: const TextStyle(color: _textGrey, fontSize: 12)),
                            onTap: () => Navigator.pop(context, dealer),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, null), child: const Text("CANCEL"))
      ],
    );
  }
}