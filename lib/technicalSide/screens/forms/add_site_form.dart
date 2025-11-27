// lib/technicalSide/screens/forms/add_site_form.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:assetarchiverflutter/technicalSide/models/sites_model.dart';
import 'package:assetarchiverflutter/models/employee_model.dart';

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
  
  String? _selectedStage;
  String? _selectedType;
  bool _isFetchingLocation = false;
  bool _isSubmitting = false;
  Position? _currentPosition;

  final List<String> _stages = ['Foundation', 'Plinth', 'Lintel', 'Roofing', 'Finishing'];
  final List<String> _types = ['Residential', 'Commercial', 'Government', 'Industrial'];

  // --- FINTECH THEME PALETTE ---
  static const Color _bgLight       = Color(0xFFF3F4F6); 
  static const Color _surfaceWhite  = Colors.white;
  static const Color _cardNavy      = Color(0xFF0F172A); 
  static const Color _textDark      = Color(0xFF111827); 
  static const Color _textGrey      = Color(0xFF6B7280); 
  static const Color _inputFill     = Color(0xFFF9FAFB); 
  static const Color _accentGreen   = Color(0xFF10B981); 

  Future<void> _getLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _addressController.text = "Lat: ${position.latitude.toStringAsFixed(5)}, Lng: ${position.longitude.toStringAsFixed(5)}";
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Location is required")));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final site = TechnicalSite(
        siteName: _siteNameController.text,
        concernedPerson: _concernedPersonController.text,
        phoneNo: _phoneController.text,
        address: _addressController.text,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        siteType: _selectedType,
        stageOfConstruction: _selectedStage,
        area: widget.employee.area, 
        region: widget.employee.region,
        constructionStartDate: DateTime.now(),
      );

      await _apiService.createTechnicalSite(site);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Site Registered Successfully!")));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Submission Failed: $e")));
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textGrey, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Register New Site",
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 0.5,
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
              // --- FORM CARD ---
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _surfaceWhite,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader("Site Details"),
                    const SizedBox(height: 16),
                    
                    _buildFintechInput(
                      controller: _siteNameController,
                      label: "Site Name",
                      hint: "e.g. Galaxy Apartments Block A",
                      icon: Icons.apartment,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildFintechInput(
                      controller: _concernedPersonController,
                      label: "Concerned Person",
                      hint: "e.g. Mr. Rajesh Kumar",
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildFintechInput(
                      controller: _phoneController,
                      label: "Phone Number",
                      hint: "e.g. 9876543210",
                      icon: Icons.phone_android,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v!.length < 10 ? "Invalid Phone" : null,
                    ),
                    
                    const SizedBox(height: 24),
                    const Divider(color: Color(0xFFEEF2FF)),
                    const SizedBox(height: 24),
                    
                    _buildSectionHeader("Classification"),
                    const SizedBox(height: 16),
                    
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
                            onChanged: (v) => setState(() => _selectedStage = v),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- LOCATION CARD ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _surfaceWhite,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                  ],
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
                            const Text(
                              "Geo-Tagging",
                              style: TextStyle(fontWeight: FontWeight.bold, color: _textDark),
                            ),
                          ],
                        ),
                        
                        if (_isFetchingLocation)
                          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        else
                          ElevatedButton.icon(
                            onPressed: _getLocation,
                            icon: const Icon(Icons.my_location, size: 16),
                            label: Text(_currentPosition == null ? "Fetch" : "Update"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _cardNavy,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      label: "Address / Landmark",
                      hint: "Enter nearby landmark...",
                      icon: Icons.map_outlined,
                      maxLines: 2,
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
                    elevation: 4,
                    shadowColor: _cardNavy.withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSubmitting 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text(
                        "REGISTER SITE",
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0, fontSize: 16),
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
          validator: validator ?? (v) => v!.isEmpty ? "Required" : null,
          style: const TextStyle(color: _textDark, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            filled: true,
            fillColor: _inputFill,
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
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

  // 🟢 UPDATED: Added dropdownColor and style to enforce visibility
  Widget _buildFintechDropdown({
    required String? value,
    required String label,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _textDark, fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          // Ensure dropdown menu background is white
          dropdownColor: _surfaceWhite, 
          // Ensure item text is dark
          style: const TextStyle(color: _textDark, fontWeight: FontWeight.w500, fontSize: 14),
          items: items.map((e) => DropdownMenuItem(
            value: e, 
            child: Text(e, style: const TextStyle(color: _textDark))
          )).toList(),
          onChanged: onChanged,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[400]),
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
          ),
        ),
      ],
    );
  }
}