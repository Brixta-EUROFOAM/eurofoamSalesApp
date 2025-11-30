// lib/technicalSide/screens/forms/add_site_form.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/technicalSide/models/sites_model.dart';
import 'package:salesmanapp/models/employee_model.dart';
import 'package:salesmanapp/models/dealer_model.dart';
import 'package:salesmanapp/technicalSide/models/mason_pc_model.dart';

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
  
  // --- ✅ NEW: Controllers for Schema Fields ---
  final _areaController = TextEditingController();
  final _regionController = TextEditingController();
  
  String? _selectedStage;
  String? _selectedType;
  bool _isFetchingLocation = false;
  bool _isSubmitting = false;
  
  Position? _currentPosition;

  // --- Association State ---
  final List<Dealer> _selectedDealers = [];
  final List<Mason> _selectedMasons = [];

  final List<String> _stages = ['Foundation', 'Plinth', 'Lintel', 'Roofing', 'Finishing'];
  final List<String> _types = ['Residential', 'Commercial', 'Government', 'Industrial'];

  // --- 🎨 FINTECH THEME PALETTE ---
  static const Color _bgLight       = Color(0xFFF3F4F6); 
  static const Color _surfaceWhite  = Colors.white;
  static const Color _cardNavy      = Color(0xFF0F172A); 
  static const Color _textDark      = Color(0xFF111827); 
  static const Color _textGrey      = Color(0xFF6B7280); 
  static const Color _inputFill     = Color(0xFFF9FAFB); 
  static const Color _accentGreen   = Color(0xFF10B981); 

  @override
  void initState() {
    super.initState();
    // Optional: Pre-fill with employee defaults if you want
    _areaController.text = widget.employee.area ?? '';
    _regionController.text = widget.employee.region ?? '';
  }

  @override
  void dispose() {
    _siteNameController.dispose();
    _concernedPersonController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    _regionController.dispose();
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
      
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      // Reverse Geocode
      Map<String, String> addressDetails = {};
      try {
        addressDetails = await _apiService.reverseGeocodeWithRadar(
          latitude: position.latitude, 
          longitude: position.longitude
        );
      } catch (e) {
        debugPrint("Reverse geocoding failed: $e");
      }

      if (mounted) {
        setState(() {
          _currentPosition = position;
          
          // --- ✅ Auto-fill Address Fields ---
          if (addressDetails['address']?.isNotEmpty == true) {
            _addressController.text = addressDetails['address']!;
          }
          if (addressDetails['area']?.isNotEmpty == true) {
            _areaController.text = addressDetails['area']!;
          }
          if (addressDetails['region']?.isNotEmpty == true) {
            _regionController.text = addressDetails['region']!;
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
    final Dealer? result = await showDialog(
      context: context,
      builder: (_) => _DealerSearchDialog(api: _apiService),
    );
    if (result != null && !_selectedDealers.any((d) => d.id == result.id)) {
      setState(() => _selectedDealers.add(result));
    }
  }

  Future<void> _openMasonSearch() async {
    final Mason? result = await showDialog(
      context: context,
      builder: (_) => _MasonSearchDialog(api: _apiService),
    );
    if (result != null && !_selectedMasons.any((m) => m.id == result.id)) {
      setState(() => _selectedMasons.add(result));
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
        
        // --- ✅ Mapped Fields ---
        address: _addressController.text,
        area: _areaController.text,     // From Controller
        region: _regionController.text, // From Controller
        
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Site Registered Successfully!"), backgroundColor: _accentGreen));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Submission Failed: $e"), backgroundColor: Colors.red));
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
        title: const Text("Register New Site", style: TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 16)),
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
                decoration: _cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader("Site Details"),
                    const SizedBox(height: 16),
                    _buildFintechInput(
                      controller: _siteNameController,
                      label: "Site Name",
                      hint: "e.g. Galaxy Apartments",
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

              // --- LOCATION CARD (UPDATED) ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: _cardDecoration(),
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
                    const SizedBox(height: 16),
                    // --- ✅ NEW: Region and Area Fields ---
                    Row(
                      children: [
                        Expanded(
                          child: _buildFintechInput(
                            controller: _regionController,
                            label: "Region",
                            hint: "State/Region",
                            icon: Icons.public,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFintechInput(
                            controller: _areaController,
                            label: "Area",
                            hint: "City/Area",
                            icon: Icons.share_location,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),

              // --- ASSOCIATIONS CARD ---
              Container(
                padding: const EdgeInsets.all(24),
                decoration: _cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader("Associations"),
                    const SizedBox(height: 16),
                    
                    // --- DEALERS SECTION ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Associated Dealers", style: TextStyle(fontWeight: FontWeight.w600, color: _textDark)),
                        TextButton.icon(
                          onPressed: _openDealerSearch,
                          icon: const Icon(Icons.add_circle_outline, size: 16),
                          label: const Text("Add"),
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        )
                      ],
                    ),
                    if (_selectedDealers.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text("No dealers added", style: TextStyle(color: _textGrey, fontStyle: FontStyle.italic, fontSize: 13)),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedDealers.map((dealer) => Chip(
                          label: Text(dealer.name),
                          labelStyle: const TextStyle(fontSize: 12, color: _textDark),
                          backgroundColor: _bgLight,
                          deleteIcon: const Icon(Icons.close, size: 14, color: _textGrey),
                          onDeleted: () => setState(() => _selectedDealers.remove(dealer)),
                        )).toList(),
                      ),
                    
                    const Divider(height: 32),

                    // --- MASONS SECTION ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Associated Masons", style: TextStyle(fontWeight: FontWeight.w600, color: _textDark)),
                        TextButton.icon(
                          onPressed: _openMasonSearch,
                          icon: const Icon(Icons.add_circle_outline, size: 16),
                          label: const Text("Add"),
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        )
                      ],
                    ),
                    if (_selectedMasons.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text("No masons added", style: TextStyle(color: _textGrey, fontStyle: FontStyle.italic, fontSize: 13)),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedMasons.map((mason) => Chip(
                          label: Text(mason.name),
                          labelStyle: const TextStyle(fontSize: 12, color: _textDark),
                          backgroundColor: _bgLight,
                          deleteIcon: const Icon(Icons.close, size: 14, color: _textGrey),
                          onDeleted: () => setState(() => _selectedMasons.remove(mason)),
                        )).toList(),
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
                    : const Text("REGISTER SITE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0, fontSize: 16)),
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

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: _surfaceWhite,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title.toUpperCase(), style: const TextStyle(color: _textGrey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0));
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
            hintStyle: const TextStyle(color: _textGrey, fontSize: 14),
            prefixIcon: Icon(icon, color: _textGrey, size: 20),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _cardNavy, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
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
        Text(label, style: const TextStyle(color: _textDark, fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          dropdownColor: _surfaceWhite, 
          style: const TextStyle(color: _textDark, fontWeight: FontWeight.w500, fontSize: 14),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: _textDark)))).toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _textGrey),
          decoration: InputDecoration(
            filled: true,
            fillColor: _inputFill,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _cardNavy, width: 1.5)),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 🔎 SERVER-SIDE SEARCH DIALOGS (Included here for completeness)
// ==========================================

class _DealerSearchDialog extends StatefulWidget {
  final ApiService api;
  const _DealerSearchDialog({required this.api});
  @override
  State<_DealerSearchDialog> createState() => _DealerSearchDialogState();
}

class _DealerSearchDialogState extends State<_DealerSearchDialog> {
  List<Dealer> _results = [];
  bool _isLoading = false;
  Timer? _debounce;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    try {
      final results = await widget.api.fetchDealers(search: query, limit: 15);
      if (mounted) setState(() => _results = results);
    } catch (e) {
      debugPrint("Dealer Search Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _BaseSearchDialog<Dealer>(
      title: "Select Dealer",
      isLoading: _isLoading,
      results: _results,
      onSearchChanged: _onSearchChanged,
      itemBuilder: (dealer) => ListTile(
        title: Text(dealer.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF111827))),
        subtitle: Text("${dealer.area} • ${dealer.phoneNo}", style: const TextStyle(color: Color(0xFF6B7280))),
        onTap: () => Navigator.pop(context, dealer),
      ),
    );
  }
}

class _MasonSearchDialog extends StatefulWidget {
  final ApiService api;
  const _MasonSearchDialog({required this.api});
  @override
  State<_MasonSearchDialog> createState() => _MasonSearchDialogState();
}

class _MasonSearchDialogState extends State<_MasonSearchDialog> {
  List<Mason> _results = [];
  bool _isLoading = false;
  Timer? _debounce;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    try {
      final results = await widget.api.fetchMasons(search: query, limit: 15);
      if (mounted) setState(() => _results = results);
    } catch (e) {
      debugPrint("Mason Search Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _BaseSearchDialog<Mason>(
      title: "Select Mason",
      isLoading: _isLoading,
      results: _results,
      onSearchChanged: _onSearchChanged,
      itemBuilder: (mason) => ListTile(
        title: Text(mason.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF111827))),
        subtitle: Text(mason.phoneNumber, style: const TextStyle(color: Color(0xFF6B7280))),
        onTap: () => Navigator.pop(context, mason),
      ),
    );
  }
}

class _BaseSearchDialog<T> extends StatelessWidget {
  final String title;
  final bool isLoading;
  final List<T> results;
  final Function(String) onSearchChanged;
  final Widget Function(T) itemBuilder;

  const _BaseSearchDialog({
    required this.title,
    required this.isLoading,
    required this.results,
    required this.onSearchChanged,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    const bgColor = Colors.white;
    const textColor = Color(0xFF111827);
    const hintColor = Color(0xFF6B7280);
    const inputFill = Color(0xFFF9FAFB);

    return AlertDialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: const TextStyle(color: textColor, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              style: const TextStyle(color: textColor),
              decoration: const InputDecoration(
                hintText: "Type to search...",
                hintStyle: TextStyle(color: hintColor),
                prefixIcon: Icon(Icons.search, color: hintColor),
                filled: true,
                fillColor: inputFill,
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
              ),
              onChanged: onSearchChanged,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A)))
                  : results.isEmpty
                      ? const Center(child: Text("Start typing to search", style: TextStyle(color: hintColor)))
                      : ListView.separated(
                          itemCount: results.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE5E7EB)),
                          itemBuilder: (ctx, i) => itemBuilder(results[i]),
                        ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text("CANCEL", style: TextStyle(color: hintColor)),
        )
      ],
    );
  }
}