// lib/screens/forms/add_pjp_form.dart
import 'dart:async'; // For Timer
import 'package:flutter/material.dart';
import 'package:salesmanapp/models/employee_model.dart';
import 'package:salesmanapp/models/pjp_model.dart';
import 'package:salesmanapp/models/dealer_model.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'dart:developer' as dev;

const _log = 'AddPjpForm';

class AddPjpForm extends StatefulWidget {
  final Employee employee;
  final VoidCallback onPjpCreated;
  final ThemeData theme;
  const AddPjpForm({
    super.key,
    required this.employee,
    required this.onPjpCreated,
    required this.theme,
  });
  @override
  State<AddPjpForm> createState() => AddPjpFormState();
}

class AddPjpFormState extends State<AddPjpForm> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  
  Dealer? _selectedDealer;
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  // --- 🎨 FINTECH THEME PALETTE ---
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

  // --- Search Logic ---
  Future<void> _openDealerSearch() async {
    final Dealer? result = await showDialog(
      context: context,
      builder: (context) => _ServerDealerSearchDialog(
        api: _apiService, 
        userId: int.parse(widget.employee.id)
      ),
    );
    if (result != null) {
      setState(() {
        _selectedDealer = result;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedDealer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select a dealer.'),
          backgroundColor: Colors.orange));
      return;
    }
    
    final dealer = _selectedDealer!;
    
    // Basic Geo-validation
    if (dealer.latitude == null || dealer.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('The selected dealer does not have location data saved.'),
          backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isSubmitting = true);
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final String displayName = '${dealer.name}, ${dealer.address}';
      final String visitData = '$displayName|${dealer.latitude}|${dealer.longitude}';

      final newPjp = Pjp(
        id: '',
        planDate: DateTime.now(),
        userId: int.parse(widget.employee.id),
        createdById: int.parse(widget.employee.id),
        status: 'PENDING', 
        verificationStatus: 'PENDING', 
        areaToBeVisited: visitData,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        dealerId: dealer.id,
        dealerName: dealer.name,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _apiService.createPjp(newPjp);

      widget.onPjpCreated();
      navigator.pop();
      scaffoldMessenger.showSnackBar(const SnackBar(
          content: Text('Visit Plan Created!'), backgroundColor: _accentGreen)); // Use theme green
    } catch (e, st) {
      dev.log('CREATE PJP ← ERROR', name: _log, error: e, stackTrace: st);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to create PJP: $e'),
          backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // --- UI Helper ---
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _textGrey, fontWeight: FontWeight.w500),
      prefixIcon: Icon(icon, color: _textGrey, size: 20),
      filled: true,
      fillColor: _inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _cardNavy, width: 1.5),
      ),
    );
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
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const Text(
                'Plan New Visit',
                style: TextStyle(
                  color: _textDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: -0.5,
                )
              ),
              const SizedBox(height: 24),
              
              // --- DEALER SELECTOR (InkWell) ---
              InkWell(
                onTap: _openDealerSearch,
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
                      const Icon(Icons.store, color: _textGrey, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedDealer != null 
                            ? "${_selectedDealer!.name} (${_selectedDealer!.area})" 
                            : "Select Dealer",
                          style: TextStyle(
                            color: _selectedDealer != null ? _textDark : _textGrey,
                            fontWeight: _selectedDealer != null ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.search, color: _textGrey),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Description Input
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: _textDark, fontWeight: FontWeight.w500),
                decoration: _inputDecoration('Description (Optional)', Icons.notes),
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
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: _isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text(
                          'SUBMIT PJP', 
                          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- INTERNAL SEARCH DIALOG (Themed) ---
class _ServerDealerSearchDialog extends StatefulWidget {
  final ApiService api;
  final int userId;
  const _ServerDealerSearchDialog({required this.api, required this.userId});
  @override
  State<_ServerDealerSearchDialog> createState() => _ServerDealerSearchDialogState();
}

class _ServerDealerSearchDialogState extends State<_ServerDealerSearchDialog> {
  List<Dealer> _dealers = [];
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
        // Fetch dealers (can restrict to userId if needed, passing here for safety)
        // Using search parameter
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
    _search(""); // Initial load
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
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
            const Text("Select Dealer", style: TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            TextField(
              autofocus: true,
              style: const TextStyle(color: _textDark),
              decoration: const InputDecoration(
                hintText: "Search dealer...",
                hintStyle: TextStyle(color: _textGrey),
                prefixIcon: Icon(Icons.search, color: _textGrey),
                filled: true,
                fillColor: _inputFill,
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
              ),
              onChanged: _search,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : _dealers.isEmpty 
                  ? const Center(child: Text("No dealers found", style: TextStyle(color: _textGrey)))
                  : ListView.separated(
                      itemCount: _dealers.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      itemBuilder: (ctx, i) => ListTile(
                        title: Text(_dealers[i].name, style: const TextStyle(color: _textDark, fontWeight: FontWeight.w600)),
                        subtitle: Text("${_dealers[i].area} • ${_dealers[i].phoneNo}", style: const TextStyle(color: _textGrey, fontSize: 12)),
                        onTap: () => Navigator.pop(context, _dealers[i]),
                      ),
                    ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: () => Navigator.pop(context, null), child: const Text("CANCEL", style: TextStyle(color: _textGrey))),
            )
          ],
        ),
      ),
    );
  }
}