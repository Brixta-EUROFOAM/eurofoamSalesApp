// lib/screens/forms/create_tvr.dart
import 'dart:io';
import 'dart:ui';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:assetarchiverflutter/technicalSide/models/technical_visit_report_model.dart';
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class CreateTvrScreen extends StatefulWidget {
  final Employee employee;
  const CreateTvrScreen({super.key, required this.employee});

  @override
  State<CreateTvrScreen> createState() => _CreateTvrScreenState();
}

class _CreateTvrScreenState extends State<CreateTvrScreen> {
  // Keys & Services
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _imagePicker = ImagePicker();

  // Form Controllers
  final _siteNameConcernedPersonController = TextEditingController();
  final _phoneNoController = TextEditingController();
  final _emailIdController = TextEditingController();
  final _clientsRemarksController = TextEditingController();
  final _salespersonRemarksController = TextEditingController();
  final _siteVisitBrandInUseController = TextEditingController();
  final _siteVisitStageController = TextEditingController();
  final _conversionFromBrandController = TextEditingController();
  final _conversionQuantityValueController = TextEditingController();
  final _conversionQuantityUnitController = TextEditingController();
  final _associatedPartyNameController = TextEditingController();
  final _influencerTypeController = TextEditingController();
  final _serviceTypeController = TextEditingController();
  final _qualityComplaintController = TextEditingController();
  final _promotionalActivityController = TextEditingController();
  final _channelPartnerVisitController = TextEditingController();

  // State Management
  bool _isSubmitting = false;
  bool _isUploadingImage = false;
  String? _selectedVisitType;

  // Workflow Data Holders
  DateTime? _checkInTime;
  File? _inTimeImageFile;
  String? _inTimeImageUrl;
  Position? _capturedLocation;

  // --- FINTECH THEME PALETTE ---
  static const Color _surfaceWhite  = Colors.white;
  static const Color _cardNavy      = Color(0xFF0F172A); // Deep Navy
  static const Color _textDark      = Color(0xFF111827); // Navy/Black
  static const Color _textGrey      = Color(0xFF6B7280); // Subtitle Grey
  static const Color _inputFill     = Color(0xFFF9FAFB); // Very light grey
  static const Color _accentGreen   = Color(0xFF10B981); 
  static const Color _accentOrange  = Color(0xFFF59E0B);

  @override
  void dispose() {
    _siteNameConcernedPersonController.dispose();
    _phoneNoController.dispose();
    _emailIdController.dispose();
    _clientsRemarksController.dispose();
    _salespersonRemarksController.dispose();
    _siteVisitBrandInUseController.dispose();
    _siteVisitStageController.dispose();
    _conversionFromBrandController.dispose();
    _conversionQuantityValueController.dispose();
    _conversionQuantityUnitController.dispose();
    _associatedPartyNameController.dispose();
    _influencerTypeController.dispose();
    _serviceTypeController.dispose();
    _qualityComplaintController.dispose();
    _promotionalActivityController.dispose();
    _channelPartnerVisitController.dispose();
    super.dispose();
  }

  // --- Core Logic ---

  Future<void> _handleCheckIn() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fill Site Name and Phone Number first.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _isUploadingImage = true);
    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 70, maxWidth: 1024);
      if (pickedFile == null) {
         if(mounted) setState(() => _isUploadingImage = false);
         return;
      }
      
      final imageFile = File(pickedFile.path);
      if (mounted) setState(() => _inTimeImageFile = imageFile);

      final imageUrl = await _apiService.uploadImageToR2(imageFile);

      if (mounted) {
        setState(() {
          _checkInTime = DateTime.now();
          _inTimeImageUrl = imageUrl;
          _capturedLocation = position; 
        });
        scaffoldMessenger.showSnackBar(const SnackBar(
          content: Text('Checked-In with photo and location successfully.'), backgroundColor: _accentGreen,
        ));
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Check-In Failed: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if(mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _submitTvr() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields.'), backgroundColor: Colors.orange));
      return;
    }
    
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _isSubmitting = true);

    try {
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 70, maxWidth: 1024);
      if (pickedFile == null) {
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Check-out photo is required to submit.'), backgroundColor: Colors.orange));
        setState(() => _isSubmitting = false);
        return;
      }
      final outTimeImageFile = File(pickedFile.path);
      final outTimeImageUrl = await _apiService.uploadImageToR2(outTimeImageFile);
      final checkOutTime = DateTime.now();

      final locationString = "[Site Location: ${_capturedLocation!.latitude}, ${_capturedLocation!.longitude}]";
      final finalSalespersonRemarks = '$locationString\n${_salespersonRemarksController.text}';

      final tvrReport = TechnicalVisitReport(
        userId: int.parse(widget.employee.id),
        reportDate: _checkInTime!,
        visitType: _selectedVisitType!,
        siteNameConcernedPerson: _siteNameConcernedPersonController.text,
        phoneNo: _phoneNoController.text,
        emailId: _emailIdController.text.isNotEmpty ? _emailIdController.text : null,
        clientsRemarks: _clientsRemarksController.text,
        salespersonRemarks: finalSalespersonRemarks,
        checkInTime: _checkInTime!,
        checkOutTime: checkOutTime,
        inTimeImageUrl: _inTimeImageUrl,
        outTimeImageUrl: outTimeImageUrl,
        siteVisitBrandInUse: _siteVisitBrandInUseController.text.split(',').map((e) => e.trim()).where((s) => s.isNotEmpty).toList(),
        influencerType: _influencerTypeController.text.split(',').map((e) => e.trim()).where((s) => s.isNotEmpty).toList(),
        siteVisitStage: _siteVisitStageController.text.isNotEmpty ? _siteVisitStageController.text : null,
        conversionFromBrand: _conversionFromBrandController.text.isNotEmpty ? _conversionFromBrandController.text : null,
        conversionQuantityValue: _conversionQuantityValueController.text.isNotEmpty ? double.tryParse(_conversionQuantityValueController.text) : null,
        conversionQuantityUnit: _conversionQuantityUnitController.text.isNotEmpty ? _conversionQuantityUnitController.text : null,
        associatedPartyName: _associatedPartyNameController.text.isNotEmpty ? _associatedPartyNameController.text : null,
        serviceType: _serviceTypeController.text.isNotEmpty ? _serviceTypeController.text : null,
        qualityComplaint: _qualityComplaintController.text.isNotEmpty ? _qualityComplaintController.text : null,
        promotionalActivity: _promotionalActivityController.text.isNotEmpty ? _promotionalActivityController.text : null,
        channelPartnerVisit: _channelPartnerVisitController.text.isNotEmpty ? _channelPartnerVisitController.text : null,
      );

      await _apiService.createTvr(tvrReport);

      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('TVR submitted successfully!'), backgroundColor: _accentGreen));
      navigator.pop();

    } catch (e) {
      if(mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // --- UI Helper Widgets ---
  Widget _buildFintechInput({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool isRequired = true,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label${isRequired ? ' *' : ''}", 
          style: const TextStyle(color: _textDark, fontWeight: FontWeight.w600, fontSize: 13)
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(color: _textDark, fontWeight: FontWeight.w500),
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: _inputFill,
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54, // Dimmed background for modal feel
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: _surfaceWhite,
                borderRadius: BorderRadius.circular(24.0),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))
                ]
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Technical Visit Report', style: TextStyle(color: _textDark, fontSize: 20, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.close, color: _textGrey),
                          onPressed: () => Navigator.of(context).pop(),
                        )
                      ],
                    ),
                    const Divider(height: 30, color: Color(0xFFF3F4F6)),

                    // --- Step 1: Initial Details & Check-In ---
                    if (_checkInTime == null) ...[
                      _buildFintechInput(controller: _siteNameConcernedPersonController, label: 'Site Name / Concerned Person', validator: (v) => v!.isEmpty ? 'Required' : null),
                      const SizedBox(height: 16),
                      _buildFintechInput(controller: _phoneNoController, label: 'Phone Number', keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Required' : null),
                      const SizedBox(height: 24),
                      
                      ElevatedButton.icon(
                        onPressed: _isUploadingImage ? null : _handleCheckIn,
                        icon: _isUploadingImage ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.camera_alt),
                        label: const Text('CHECK-IN (PHOTO & LOCATION)', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: _accentOrange,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                    
                    // --- Step 2: Full Form (after check-in) ---
                    if (_checkInTime != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4), // Light Green BG
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          children: [
                            _inTimeImageFile != null 
                              ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_inTimeImageFile!, width: 50, height: 50, fit: BoxFit.cover))
                              : const Icon(Icons.check_circle, color: _accentGreen, size: 40),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_siteNameConcernedPersonController.text, style: const TextStyle(color: _textDark, fontWeight: FontWeight.bold)),
                                  Text('Checked-In at ${DateFormat('hh:mm a').format(_checkInTime!)}', style: const TextStyle(color: _textGrey, fontSize: 12)),
                                ],
                              ),
                            ),
                            const Icon(Icons.location_on, color: _accentGreen),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Visit Type Dropdown
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Visit Type *", style: TextStyle(color: _textDark, fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedVisitType,
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: _textDark, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: _inputFill,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                            items: ['Site Visit', 'Conversion', 'Influencer Meet', 'Service', 'Complaint', 'Promotional', 'Partner Visit']
                                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                                .toList(),
                            onChanged: (value) => setState(() => _selectedVisitType = value),
                            validator: (v) => v == null ? 'Required' : null,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      _buildFintechInput(controller: _emailIdController, label: 'Email ID', isRequired: false, keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 16),
                      _buildFintechInput(controller: _clientsRemarksController, label: "Client's Remarks", maxLines: 3, validator: (v) => v!.isEmpty ? 'Required' : null),
                      const SizedBox(height: 16),
                      _buildFintechInput(controller: _salespersonRemarksController, label: 'Salesperson Remarks', maxLines: 3, validator: (v) => v!.isEmpty ? 'Required' : null),
                      const SizedBox(height: 16),
                      _buildFintechInput(controller: _siteVisitBrandInUseController, label: 'Brands in Use', hint: 'Brand A, Brand B', validator: (v) => v!.isEmpty ? 'Required' : null),
                      const SizedBox(height: 16),
                      _buildFintechInput(controller: _influencerTypeController, label: 'Influencer Type', hint: 'e.g., Mason, Contractor', validator: (v) => v!.isEmpty ? 'Required' : null),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Divider(),
                      ),
                      
                      const Text("OPTIONAL DETAILS", style: TextStyle(color: _textGrey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      const SizedBox(height: 16),

                      _buildFintechInput(controller: _siteVisitStageController, label: 'Site Visit Stage', isRequired: false),
                      const SizedBox(height: 16),
                      _buildFintechInput(controller: _conversionFromBrandController, label: 'Conversion from Brand', isRequired: false),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(flex: 2, child: _buildFintechInput(controller: _conversionQuantityValueController, label: 'Conversion Qty', isRequired: false, keyboardType: TextInputType.number)),
                          const SizedBox(width: 12),
                          Expanded(flex: 1, child: _buildFintechInput(controller: _conversionQuantityUnitController, label: 'Unit', isRequired: false, hint: 'e.g. Bags')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildFintechInput(controller: _associatedPartyNameController, label: 'Associated Party Name', isRequired: false),
                      const SizedBox(height: 16),
                      _buildFintechInput(controller: _serviceTypeController, label: 'Service Type', isRequired: false),
                      const SizedBox(height: 16),
                      _buildFintechInput(controller: _qualityComplaintController, label: 'Quality Complaint Details', isRequired: false),
                      const SizedBox(height: 16),
                      _buildFintechInput(controller: _promotionalActivityController, label: 'Promotional Activity', isRequired: false),
                      const SizedBox(height: 16),
                      _buildFintechInput(controller: _channelPartnerVisitController, label: 'Partner Visit Details', isRequired: false),
                      const SizedBox(height: 32),
                      
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitTvr,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: _accentGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('SUBMIT & CHECK-OUT (PHOTO)', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}