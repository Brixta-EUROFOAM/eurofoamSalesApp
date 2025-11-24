// lib/screens/forms/create_techpjp_form.dart
import 'package:flutter/material.dart';
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:assetarchiverflutter/models/pjp_model.dart';
import 'package:assetarchiverflutter/technicalSide/models/sites_model.dart';
import 'package:assetarchiverflutter/api/api_service.dart';
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

  @override
  void initState() {
    super.initState();
    // Fetch sites relevant to this TSE
    _sitesFuture = _apiService.fetchTechnicalSites(userId: int.parse(widget.employee.id));
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _selectedSite == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select a site.'), backgroundColor: Colors.orange));
      return;
    }

    // Sites must have location for journey tracking
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
        
        // ✅ KEY CHANGE: Use siteId instead of dealerId
        siteId: _selectedSite!.id,
        siteName: _selectedSite!.siteName, // Optional, for local UI update if needed immediately
        
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _apiService.createPjp(newPjp);

      widget.onPjpCreated();
      if (mounted) Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Technical Visit Plan Created!'), backgroundColor: Colors.green));
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
    final theme = Theme.of(context);
    
    // Dark theme styling
    const labelColor = Colors.white70;
    const textColor = Colors.white;
    
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: const Color(0xFF020a67).withOpacity(0.95), // Dark Blue background
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
          border: Border.all(color: Colors.white24),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Plan Site Visit',
                  style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              
              // Site Dropdown
              FutureBuilder<List<TechnicalSite>>(
                future: _sitesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text('Error loading sites: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No sites found registered to you.', style: TextStyle(color: Colors.white70));
                  }
                  
                  return DropdownButtonFormField<TechnicalSite>(
                    hint: const Text('Select a Site', style: TextStyle(color: Colors.white54)),
                    dropdownColor: const Color(0xFF0D47A1),
                    style: const TextStyle(color: textColor),
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: "Site",
                      labelStyle: const TextStyle(color: labelColor),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white30),
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                style: const TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Purpose / Remarks (Optional)',
                  labelStyle: const TextStyle(color: labelColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),
              
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA000), // Amber
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black))
                    : const Text('CREATE PLAN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}