import 'package:flutter/material.dart';
import 'package:salesmanapp/models/employee_model.dart';
import 'package:salesmanapp/models/pjp_model.dart';
import 'package:salesmanapp/technicalSide/models/sites_model.dart';
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
  
  TechnicalSite? _selectedSite;
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  late Future<List<TechnicalSite>> _sitesFuture;

  // --- FINTECH THEME PALETTE ---
  static const Color _surfaceWhite  = Colors.white;
  static const Color _cardNavy      = Color(0xFF0F172A); // Deep Navy
  static const Color _textDark      = Color(0xFF111827); // Navy/Black
  static const Color _textGrey      = Color(0xFF6B7280); // Subtitle Grey
  static const Color _inputFill     = Color(0xFFF9FAFB); // Very light grey

  @override
  void initState() {
    super.initState();
    _sitesFuture = _apiService.fetchTechnicalSites(userId: int.parse(widget.employee.id));
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _selectedSite == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select a site.'), backgroundColor: Colors.orange));
      return;
    }

    if (_selectedSite!.latitude == 0.0 || _selectedSite!.longitude == 0.0) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Selected site has invalid coordinates. Cannot create PJP.'),
          backgroundColor: Colors.red));
       return;
    }

    setState(() => _isSubmitting = true);

    try {
      final String displayName = '${_selectedSite!.siteName}, ${_selectedSite!.address}';
      final String visitData = '$displayName|${_selectedSite!.latitude}|${_selectedSite!.longitude}';

      final newPjp = Pjp(
        id: '',
        planDate: DateTime.now(),
        userId: int.parse(widget.employee.id),
        createdById: int.parse(widget.employee.id),
        status: 'pending',
        verificationStatus: 'PENDING',
        areaToBeVisited: visitData,
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        siteId: _selectedSite!.id,
        siteName: _selectedSite!.siteName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _apiService.createPjp(newPjp);

      widget.onPjpCreated();
      if (mounted) Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Technical Visit Plan Created!'), backgroundColor: Color(0xFF10B981))); // Success Green
    } catch (e) {
      dev.log('Create Tech PJP Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to create plan: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Styles for inputs
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: _inputFill,
      labelStyle: const TextStyle(color: _textGrey, fontWeight: FontWeight.w500),
      hintStyle: TextStyle(color: Colors.grey[400]),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
    );

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
              // Handle bar
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

              // --- FIX IS HERE: Clean Text widget ---
              const Text(
                'Plan Site Visit',
                style: TextStyle(
                  color: _textDark, 
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                )
              ),
              const SizedBox(height: 24),
              
              // Site Dropdown
              FutureBuilder<List<TechnicalSite>>(
                future: _sitesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: LinearProgressIndicator(color: _cardNavy));
                  }
                  if (snapshot.hasError) {
                    return Text('Error loading sites', style: TextStyle(color: Colors.red[400]));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No sites found registered to you.', style: TextStyle(color: _textGrey));
                  }
                  
                  return DropdownButtonFormField<TechnicalSite>(
                    hint: Text('Select a Site', style: TextStyle(color: Colors.grey[400])),
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: _textDark, fontWeight: FontWeight.w600),
                    isExpanded: true,
                    decoration: inputDecoration.copyWith(
                      labelText: "Select Site",
                      prefixIcon: const Icon(Icons.location_city, color: _textGrey, size: 20),
                    ),
                    items: snapshot.data!.map((site) => DropdownMenuItem(
                      value: site,
                      child: Text("${site.siteName} (${site.area})", overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (value) => setState(() => _selectedSite = value),
                    validator: (value) => value == null ? 'Please select a site' : null,
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              // Description Input
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: _textDark, fontWeight: FontWeight.w500),
                decoration: inputDecoration.copyWith(
                  labelText: 'Purpose / Remarks (Optional)',
                  prefixIcon: const Icon(Icons.notes, color: _textGrey, size: 20),
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
                      : const Text(
                          'CREATE PLAN', 
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