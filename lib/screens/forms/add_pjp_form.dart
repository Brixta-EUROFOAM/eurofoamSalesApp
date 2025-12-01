// lib/screens/forms/add_pjp_form.dart
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
  late Future<List<Dealer>> _dealersFuture;

  // --- 🎨 FINTECH THEME PALETTE ---
  static const Color _surfaceWhite  = Colors.white;
  static const Color _cardNavy      = Color(0xFF0F172A); 
  static const Color _textDark      = Color(0xFF111827); 
  static const Color _textGrey      = Color(0xFF6B7280); 
  static const Color _inputFill     = Color(0xFFF9FAFB); 

  @override
  void initState() {
    super.initState();
    dev.log('AddPjpForm.initState → load dealers for user ${widget.employee.id}', name: _log);
    _dealersFuture =
        _apiService.fetchDealers(userId: int.parse(widget.employee.id));
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _selectedDealer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select a dealer.'),
          backgroundColor: Colors.orange));
      return;
    }
    final dealer = _selectedDealer!;
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
          content: Text('Visit Plan Created!'), backgroundColor: Colors.green));
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
              
              // Dealer Dropdown
              FutureBuilder<List<Dealer>>(
                future: _dealersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: LinearProgressIndicator(color: _cardNavy));
                  }
                  if (snapshot.hasError) {
                    return Text('Error loading dealers', style: TextStyle(color: Colors.red[400]));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: _inputFill, borderRadius: BorderRadius.circular(12)),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: _textGrey),
                          SizedBox(width: 12),
                          Expanded(child: Text('No dealers found.', style: TextStyle(color: _textGrey))),
                        ],
                      ),
                    );
                  }
                  
                  return DropdownButtonFormField<Dealer>(
                    hint: const Text('Select a Dealer'),
                    dropdownColor: Colors.white,
                    isExpanded: true,
                    style: const TextStyle(color: _textDark, fontWeight: FontWeight.w600, fontSize: 15),
                    decoration: _inputDecoration("Select Dealer", Icons.store),
                    items: snapshot.data!.map((dealer) => DropdownMenuItem(
                        value: dealer,
                        child: Text(
                          dealer.name,
                          overflow: TextOverflow.ellipsis,
                        )
                    )).toList(),
                    onChanged: (value) => setState(() => _selectedDealer = value),
                    validator: (value) => value == null ? 'Please select a dealer' : null,
                  );
                },
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