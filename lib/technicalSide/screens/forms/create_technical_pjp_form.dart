// lib/technicalSide/screens/forms/create_technical_pjp_form.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:salesmanapp/models/employee_model.dart';
import 'package:salesmanapp/models/pjp_model.dart';
import 'package:salesmanapp/technicalSide/models/sites_model.dart';
import 'package:salesmanapp/models/dealer_model.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'dart:developer' as dev;

class CreateTechnicalPjpForm extends StatefulWidget {
  final Employee employee;
  final VoidCallback onPjpCreated;

  const CreateTechnicalPjpForm({
    super.key,
    required this.employee,
    required this.onPjpCreated,
  });

  @override
  State<CreateTechnicalPjpForm> createState() => _CreateTechnicalPjpFormState();
}

class _CreateTechnicalPjpFormState extends State<CreateTechnicalPjpForm> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  
  // Selection State
  String _visitType = 'Site'; // 'Site' or 'Dealer'
  TechnicalSite? _selectedSite;
  Dealer? _selectedDealer;
  
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  // --- FINTECH THEME PALETTE ---
  static const Color _surfaceWhite  = Colors.white;
  static const Color _cardNavy      = Color(0xFF0F172A); 
  static const Color _textDark      = Color(0xFF111827); 
  static const Color _textGrey      = Color(0xFF6B7280); 
  static const Color _inputFill     = Color(0xFFF9FAFB); 
  static const Color _accentGreen   = Color(0xFF10B981);

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // --- SEARCH HANDLERS ---
  Future<void> _openSiteSearch() async {
    final TechnicalSite? result = await showDialog(
      context: context,
      builder: (_) => _SiteSearchDialog(
        api: _apiService, 
        userId: int.tryParse(widget.employee.id) ?? 0
      ),
    );
    if (result != null) {
      setState(() => _selectedSite = result);
    }
  }

  Future<void> _openDealerSearch() async {
    final Dealer? result = await showDialog(
      context: context,
      builder: (_) => _DealerSearchDialog(api: _apiService),
    );
    if (result != null) {
      setState(() => _selectedDealer = result);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Validation based on type
    if (_visitType == 'Site' && _selectedSite == null) {
      _showSnack('Please select a site.', Colors.orange);
      return;
    }
    if (_visitType == 'Dealer' && _selectedDealer == null) {
      _showSnack('Please select a dealer.', Colors.orange);
      return;
    }

    // Geo Validation
    double lat = 0.0;
    double lng = 0.0;
    String name = "";
    String address = "";
    String? siteId;
    String? dealerId;

    if (_visitType == 'Site') {
      lat = _selectedSite!.latitude;
      lng = _selectedSite!.longitude;
      name = _selectedSite!.siteName;
      address = _selectedSite!.address;
      siteId = _selectedSite!.id;
    } else {
      lat = _selectedDealer!.latitude ?? 0.0;
      lng = _selectedDealer!.longitude ?? 0.0;
      name = _selectedDealer!.name;
      address = _selectedDealer!.address;
      dealerId = _selectedDealer!.id;
    }

    if (lat == 0.0 || lng == 0.0) {
       _showSnack('Selected location has invalid coordinates. Cannot create PJP.', Colors.red);
       return;
    }

    setState(() => _isSubmitting = true);

    try {
      final String displayName = '$name, $address';
      final String visitData = '$displayName|$lat|$lng';

      final newPjp = Pjp(
        id: '',
        planDate: DateTime.now(),
        userId: int.parse(widget.employee.id),
        createdById: int.parse(widget.employee.id),
        status: 'pending',
        verificationStatus: 'PENDING',
        areaToBeVisited: visitData,
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        
        // Pass correct IDs based on type
        siteId: siteId,
        siteName: _visitType == 'Site' ? name : null,
        dealerId: dealerId, 
        dealerName: _visitType == 'Dealer' ? name : null,
        
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _apiService.createPjp(newPjp);

      widget.onPjpCreated();
      if (mounted) Navigator.pop(context);
      
      _showSnack('Technical Visit Plan Created!', _accentGreen);
    } catch (e) {
      dev.log('Create Tech PJP Error: $e');
      _showSnack('Failed to create plan: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, Color color) {
    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: const BoxDecoration(
          color: _surfaceWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)),
                ),
              ),

             // const Text('Plan Site/Dealer Visit', style: TextStyle(color: _textDark, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
             // const SizedBox(height: 20),

              // --- TYPE TOGGLE (NAVY BLUE STYLE) ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: _inputFill, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    _buildSegmentButton('Site Visit', 'Site'),
                    _buildSegmentButton('Dealer Visit', 'Dealer'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // --- SEARCHABLE SELECTION FIELDS ---
              if (_visitType == 'Site')
                _buildSelectionField(
                  label: "Select Site",
                  value: _selectedSite?.siteName,
                  hint: "Search for a site...",
                  icon: Icons.location_city,
                  onTap: _openSiteSearch,
                )
              else
                _buildSelectionField(
                  label: "Select Dealer",
                  value: _selectedDealer?.name,
                  hint: "Search for a dealer...",
                  icon: Icons.store,
                  onTap: _openDealerSearch,
                ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: _textDark, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  labelText: 'Purpose / Remarks (Optional)',
                  prefixIcon: const Icon(Icons.notes, color: _textGrey, size: 20),
                  filled: true,
                  fillColor: _inputFill,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _cardNavy, width: 1.5)),
                ),
                maxLines: 2,
              ),
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _cardNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('CREATE PLAN', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildSegmentButton(String label, String value) {
    final isSelected = _visitType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _visitType = value;
          // Clear selections when switching to avoid confusion
          _selectedSite = null;
          _selectedDealer = null;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? _cardNavy : Colors.transparent, // Navy Blue when selected
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected ? [BoxShadow(color: _cardNavy.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))] : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : _textGrey, // White text when selected
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionField({
    required String label,
    required String? value,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _textGrey, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: _inputFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.transparent),
            ),
            child: Row(
              children: [
                Icon(icon, color: _textGrey, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value ?? hint,
                    style: TextStyle(
                      color: value != null ? _textDark : Colors.grey[400],
                      fontWeight: value != null ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.search, color: _textGrey, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// 🔎 SEARCH DIALOGS 
// ==========================================

class _SiteSearchDialog extends StatefulWidget {
  final ApiService api;
  final int userId;
  const _SiteSearchDialog({required this.api, required this.userId});
  @override
  State<_SiteSearchDialog> createState() => _SiteSearchDialogState();
}

class _SiteSearchDialogState extends State<_SiteSearchDialog> {
  List<TechnicalSite> _allSites = [];
  List<TechnicalSite> _filteredSites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  // Fetch all sites once, then filter locally (better for UX if list < 500 items)
  Future<void> _fetchInitialData() async {
    try {
      final results = await widget.api.fetchTechnicalSites(userId: widget.userId);
      if (mounted) {
        setState(() {
          _allSites = results;
          _filteredSites = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredSites = _allSites.where((site) {
        return site.siteName.toLowerCase().contains(lowerQuery) ||
               (site.area?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _BaseSearchDialog<TechnicalSite>(
      title: "Select Site",
      isLoading: _isLoading,
      results: _filteredSites,
      onSearchChanged: _onSearchChanged,
      itemBuilder: (site) => ListTile(
        title: Text(site.siteName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF111827))),
        subtitle: Text(site.address, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF6B7280))),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.apartment, color: Color(0xFF3B82F6), size: 20),
        ),
        onTap: () => Navigator.pop(context, site),
      ),
    );
  }
}

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
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.store, color: Color(0xFF10B981), size: 20),
        ),
        onTap: () => Navigator.pop(context, dealer),
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
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              ),
              onChanged: onSearchChanged,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A)))
                  : results.isEmpty
                      ? const Center(child: Text("No results found", style: TextStyle(color: hintColor)))
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