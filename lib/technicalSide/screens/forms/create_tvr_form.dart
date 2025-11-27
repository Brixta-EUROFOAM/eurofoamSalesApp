// lib/screens/forms/create_tvr.dart
import 'dart:io';
import 'dart:ui';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/technicalSide/models/technical_visit_report_model.dart';
import 'package:salesmanapp/models/employee_model.dart';
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

  // --- Form Controllers (Existing) ---
  final _siteNameConcernedPersonController = TextEditingController();
  final _phoneNoController = TextEditingController();
  final _emailIdController = TextEditingController();
  final _clientsRemarksController = TextEditingController();
  final _salespersonRemarksController = TextEditingController();
  final _siteVisitBrandInUseController = TextEditingController();
  // _siteVisitStageController removed in favor of dropdown
  final _conversionFromBrandController = TextEditingController();
  final _conversionQuantityValueController = TextEditingController();
  final _associatedPartyNameController = TextEditingController();
  final _influencerTypeController = TextEditingController();
  final _serviceTypeController = TextEditingController();
  final _qualityComplaintController = TextEditingController();
  final _promotionalActivityController = TextEditingController();
  final _channelPartnerVisitController = TextEditingController();

  // --- Form Controllers (NEW) ---
  final _whatsappNoController = TextEditingController();
  final _siteAddressController = TextEditingController();
  final _marketNameController = TextEditingController();
  final _purposeOfVisitController = TextEditingController();
  final _constAreaSqFtController = TextEditingController();
  final _currentBrandPriceController = TextEditingController();
  final _siteStockController = TextEditingController();
  final _estRequirementController = TextEditingController();
  final _supplyingDealerNameController = TextEditingController();
  final _nearbyDealerNameController = TextEditingController();
  final _serviceDescController = TextEditingController();
  final _dhalaiVerificationCodeController = TextEditingController();
  final _isVerificationStatusController = TextEditingController();
  final _influencerNameController = TextEditingController();
  final _influencerPhoneController = TextEditingController();
  final _influencerProductivityController = TextEditingController();

  // --- State Management ---
  bool _isSubmitting = false;
  bool _isUploadingImage = false;
  
  // Dropdowns
  String? _selectedVisitType;
  String? _selectedVisitCategory;
  String? _selectedCustomerType;
  String? _selectedConversionType;
  String? _selectedConversionUnit;
  String? _selectedStage; // NEW: State for Construction Stage

  // Booleans (Switches)
  bool _isConverted = false;
  bool _isTechService = false;
  bool _isSchemeEnrolled = false;

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
    // Dispose Existing
    _siteNameConcernedPersonController.dispose();
    _phoneNoController.dispose();
    _emailIdController.dispose();
    _clientsRemarksController.dispose();
    _salespersonRemarksController.dispose();
    _siteVisitBrandInUseController.dispose();
    // _siteVisitStageController.dispose();
    _conversionFromBrandController.dispose();
    _conversionQuantityValueController.dispose();
    _associatedPartyNameController.dispose();
    _influencerTypeController.dispose();
    _serviceTypeController.dispose();
    _qualityComplaintController.dispose();
    _promotionalActivityController.dispose();
    _channelPartnerVisitController.dispose();
    
    // Dispose New
    _whatsappNoController.dispose();
    _siteAddressController.dispose();
    _marketNameController.dispose();
    _purposeOfVisitController.dispose();
    _constAreaSqFtController.dispose();
    _currentBrandPriceController.dispose();
    _siteStockController.dispose();
    _estRequirementController.dispose();
    _supplyingDealerNameController.dispose();
    _nearbyDealerNameController.dispose();
    _serviceDescController.dispose();
    _dhalaiVerificationCodeController.dispose();
    _isVerificationStatusController.dispose();
    _influencerNameController.dispose();
    _influencerPhoneController.dispose();
    _influencerProductivityController.dispose();
    
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
        // Core
        userId: int.parse(widget.employee.id),
        reportDate: _checkInTime!,
        visitType: _selectedVisitType!,
        
        // Contact & Loc
        siteNameConcernedPerson: _siteNameConcernedPersonController.text,
        phoneNo: _phoneNoController.text,
        whatsappNo: _whatsappNoController.text.isNotEmpty ? _whatsappNoController.text : null,
        emailId: _emailIdController.text.isNotEmpty ? _emailIdController.text : null,
        siteAddress: _siteAddressController.text.isNotEmpty ? _siteAddressController.text : null,
        marketName: _marketNameController.text.isNotEmpty ? _marketNameController.text : null,
        latitude: _capturedLocation?.latitude,
        longitude: _capturedLocation?.longitude,

        // Visit Specifics
        visitCategory: _selectedVisitCategory,
        customerType: _selectedCustomerType,
        purposeOfVisit: _purposeOfVisitController.text.isNotEmpty ? _purposeOfVisitController.text : null,

        // Construction & Stock
        constAreaSqFt: _constAreaSqFtController.text.isNotEmpty ? int.tryParse(_constAreaSqFtController.text) : null,
        siteVisitBrandInUse: _siteVisitBrandInUseController.text.split(',').map((e) => e.trim()).where((s) => s.isNotEmpty).toList(),
        siteVisitStage: _selectedStage, // Using Dropdown value
        currentBrandPrice: _currentBrandPriceController.text.isNotEmpty ? double.tryParse(_currentBrandPriceController.text) : null,
        siteStock: _siteStockController.text.isNotEmpty ? double.tryParse(_siteStockController.text) : null,
        estRequirement: _estRequirementController.text.isNotEmpty ? double.tryParse(_estRequirementController.text) : null,

        // Dealers
        supplyingDealerName: _supplyingDealerNameController.text.isNotEmpty ? _supplyingDealerNameController.text : null,
        nearbyDealerName: _nearbyDealerNameController.text.isNotEmpty ? _nearbyDealerNameController.text : null,
        associatedPartyName: _associatedPartyNameController.text.isNotEmpty ? _associatedPartyNameController.text : null,
        channelPartnerVisit: _channelPartnerVisitController.text.isNotEmpty ? _channelPartnerVisitController.text : null,

        // Conversion
        isConverted: _isConverted,
        conversionType: _isConverted ? _selectedConversionType : null,
        conversionFromBrand: _conversionFromBrandController.text.isNotEmpty ? _conversionFromBrandController.text : null,
        conversionQuantityValue: _conversionQuantityValueController.text.isNotEmpty ? double.tryParse(_conversionQuantityValueController.text) : null,
        conversionQuantityUnit: _isConverted ? _selectedConversionUnit : null, 

        // Technical Service
        isTechService: _isTechService,
        serviceDesc: _isTechService && _serviceDescController.text.isNotEmpty ? _serviceDescController.text : null,
        serviceType: _serviceTypeController.text.isNotEmpty ? _serviceTypeController.text : null,
        dhalaiVerificationCode: _dhalaiVerificationCodeController.text.isNotEmpty ? _dhalaiVerificationCodeController.text : null,
        isVerificationStatus: _isVerificationStatusController.text.isNotEmpty ? _isVerificationStatusController.text : null,
        qualityComplaint: _qualityComplaintController.text.isNotEmpty ? _qualityComplaintController.text : null,

        // Influencer
        influencerName: _influencerNameController.text.isNotEmpty ? _influencerNameController.text : null,
        influencerPhone: _influencerPhoneController.text.isNotEmpty ? _influencerPhoneController.text : null,
        isSchemeEnrolled: _isSchemeEnrolled,
        influencerProductivity: _influencerProductivityController.text.isNotEmpty ? _influencerProductivityController.text : null,
        influencerType: _influencerTypeController.text.split(',').map((e) => e.trim()).where((s) => s.isNotEmpty).toList(),

        // Remarks & Meta
        clientsRemarks: _clientsRemarksController.text,
        salespersonRemarks: finalSalespersonRemarks,
        promotionalActivity: _promotionalActivityController.text.isNotEmpty ? _promotionalActivityController.text : null,
        
        checkInTime: _checkInTime!,
        checkOutTime: checkOutTime,
        inTimeImageUrl: _inTimeImageUrl,
        outTimeImageUrl: outTimeImageUrl,
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
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(color: _textDark, fontWeight: FontWeight.w600, fontSize: 13, fontFamily: 'Roboto'), 
            children: [
              if (isRequired) const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
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

  Widget _buildFintechDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(color: _textDark, fontWeight: FontWeight.w600, fontSize: 13, fontFamily: 'Roboto'),
            children: [
              if (isRequired) const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          dropdownColor: Colors.white,
          style: const TextStyle(color: _textDark, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            filled: true,
            fillColor: _inputFill,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          items: items.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
          onChanged: onChanged,
          validator: isRequired ? (v) => v == null ? 'Required' : null : null,
        ),
      ],
    );
  }

  Widget _buildFintechSwitch({
    required String label,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: value ? _accentGreen.withOpacity(0.5) : Colors.transparent),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: _textDark, fontWeight: FontWeight.w600, fontSize: 14)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: _accentGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: _textGrey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54, // Dimmed background
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

                    // --- Step 1: Check-In Details ---
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
                    
                    // --- Step 2: Full Form ---
                    if (_checkInTime != null) ...[
                      // Check-in Summary Card
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

                      // --- 1. VISIT META ---
                      _buildFintechDropdown(
                        label: 'Visit Type', 
                        value: _selectedVisitType, 
                        items: ['Site Visit', 'Conversion', 'Influencer Meet', 'Service', 'Complaint', 'Promotional', 'Partner Visit'],
                        onChanged: (v) => setState(() => _selectedVisitType = v)
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFintechDropdown(
                              label: 'Visit Category', 
                              value: _selectedVisitCategory, 
                              isRequired: false,
                              items: ['New Site', 'Followup Site'],
                              onChanged: (v) => setState(() => _selectedVisitCategory = v)
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildFintechDropdown(
                              label: 'Customer Type', 
                              value: _selectedCustomerType, 
                              isRequired: false,
                              items: ['IHB', 'Contractor', 'Builder', 'Government'],
                              onChanged: (v) => setState(() => _selectedCustomerType = v)
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildFintechInput(controller: _purposeOfVisitController, label: 'Purpose of Visit', isRequired: false),

                      // --- 2. EXTENDED CONTACT INFO ---
                      _buildSectionHeader("CONTACT DETAILS"),
                      _buildFintechInput(controller: _whatsappNoController, label: 'WhatsApp Number', keyboardType: TextInputType.phone, isRequired: false),
                      const SizedBox(height: 16),
                      _buildFintechInput(controller: _emailIdController, label: 'Email ID', isRequired: false, keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 16),
                      _buildFintechInput(controller: _siteAddressController, label: 'Site Address', isRequired: false, maxLines: 2),
                      const SizedBox(height: 16),
                      _buildFintechInput(controller: _marketNameController, label: 'Market / Depo Name', isRequired: false),

                      // --- 3. CONSTRUCTION DETAILS ---
                      _buildSectionHeader("CONSTRUCTION & SITE INFO"),
                      Row(
                        children: [
                          Expanded(child: _buildFintechInput(controller: _constAreaSqFtController, label: 'Const. Area (Sq.Ft)', keyboardType: TextInputType.number, isRequired: false)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildFintechDropdown(
                              label: 'Stage', 
                              value: _selectedStage, 
                              isRequired: false,
                              items: ['Foundation', 'Plinth', 'Column / Lintel', 'Slab Casting', 'Plastering / Finishing', 'Flooring'],
                              onChanged: (v) => setState(() => _selectedStage = v)
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildFintechInput(controller: _siteVisitBrandInUseController, label: 'Brands in Use', hint: 'Brand A, Brand B', validator: (v) => v!.isEmpty ? 'Required' : null),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildFintechInput(controller: _currentBrandPriceController, label: 'Current Price', keyboardType: TextInputType.number, isRequired: false)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildFintechInput(controller: _siteStockController, label: 'Site Stock', keyboardType: TextInputType.number, isRequired: false)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildFintechInput(controller: _estRequirementController, label: 'Est. Requirement', keyboardType: TextInputType.number, isRequired: false),

                      // --- 4. DEALER INFO ---
                      _buildSectionHeader("DEALER INFORMATION"),
                      // Updated to Multi-line with format hint
                      _buildFintechInput(
                        controller: _supplyingDealerNameController, 
                        label: 'Supplying Dealers & Brands', 
                        hint: 'e.g. Gupta Traders (Star, Dalmia), Sharma Hardware (Ultratech)',
                        maxLines: 2,
                        isRequired: false
                      ),
                      const SizedBox(height: 16),
                      _buildFintechInput(controller: _nearbyDealerNameController, label: 'Nearby Best Dealer', isRequired: false),
                      const SizedBox(height: 16),
                      _buildFintechInput(controller: _associatedPartyNameController, label: 'Associated Party Name', isRequired: false),
                      const SizedBox(height: 16),
                      _buildFintechInput(controller: _channelPartnerVisitController, label: 'Partner Visit Details', isRequired: false),

                      // --- 5. CONVERSION DATA ---
                      _buildSectionHeader("CONVERSION"),
                      _buildFintechSwitch(label: "Is Converted?", value: _isConverted, onChanged: (v) => setState(() => _isConverted = v)),
                      if (_isConverted) ...[
                        const SizedBox(height: 12),
                        _buildFintechDropdown(
                          label: 'Conversion Type',
                          value: _selectedConversionType,
                          items: ['New', 'Retention'],
                          onChanged: (v) => setState(() => _selectedConversionType = v),
                        ),
                        const SizedBox(height: 16),
                        _buildFintechInput(controller: _conversionFromBrandController, label: 'Converted From (Brand)', isRequired: true),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(flex: 2, child: _buildFintechInput(controller: _conversionQuantityValueController, label: 'Qty', isRequired: true, keyboardType: TextInputType.number)),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1, 
                              child: _buildFintechDropdown(
                                label: 'Unit', 
                                value: _selectedConversionUnit, 
                                items: ['Bags', 'MT'], 
                                onChanged: (v) => setState(() => _selectedConversionUnit = v),
                                isRequired: true
                              )
                            ),
                          ],
                        ),
                      ],

                      // --- 6. TECHNICAL SERVICES ---
                      _buildSectionHeader("TECHNICAL SERVICES"),
                      _buildFintechSwitch(label: "Technical Service Provided?", value: _isTechService, onChanged: (v) => setState(() => _isTechService = v)),
                      if (_isTechService) ...[
                        const SizedBox(height: 12),
                        _buildFintechInput(controller: _serviceTypeController, label: 'Service Type', isRequired: true, hint: 'e.g. Slump Test'),
                        const SizedBox(height: 16),
                        _buildFintechInput(controller: _serviceDescController, label: 'Service Description', isRequired: false, maxLines: 2),
                        // const SizedBox(height: 16),
                        // _buildFintechInput(controller: _dhalaiVerificationCodeController, label: 'Dhalai Code', isRequired: false),
                        // const SizedBox(height: 16),
                        // _buildFintechInput(controller: _isVerificationStatusController, label: 'Verification Status', isRequired: false),
                      ],
                      const SizedBox(height: 16),
                      _buildFintechInput(controller: _qualityComplaintController, label: 'Quality Complaint Details', isRequired: false),

                      // --- 7. INFLUENCER INFO ---
                      _buildSectionHeader("INFLUENCER / MASON"),
                      _buildFintechInput(controller: _influencerTypeController, label: 'Influencer Type', hint: 'e.g., Mason, Contractor', validator: (v) => v!.isEmpty ? 'Required' : null),
                      const SizedBox(height: 16),
                      _buildFintechInput(controller: _influencerNameController, label: 'Influencer Name', isRequired: false),
                      const SizedBox(height: 16),
                      _buildFintechInput(controller: _influencerPhoneController, label: 'Influencer Phone', keyboardType: TextInputType.phone, isRequired: false),
                      const SizedBox(height: 16),
                      _buildFintechSwitch(label: "Enrolled in Scheme?", value: _isSchemeEnrolled, onChanged: (v) => setState(() => _isSchemeEnrolled = v)),
                      const SizedBox(height: 16),
                      _buildFintechInput(controller: _influencerProductivityController, label: 'Productivity (Bags)', isRequired: false),

                      // --- 8. REMARKS & CLOSING ---
                      _buildSectionHeader("REMARKS"),
                      _buildFintechInput(controller: _clientsRemarksController, label: "Client's Remarks", maxLines: 2, validator: (v) => v!.isEmpty ? 'Required' : null),
                      const SizedBox(height: 16),
                      _buildFintechInput(controller: _salespersonRemarksController, label: 'Salesperson Remarks', maxLines: 2, validator: (v) => v!.isEmpty ? 'Required' : null),
                      const SizedBox(height: 16),
                      _buildFintechInput(controller: _promotionalActivityController, label: 'Promotional Activity', isRequired: false),
                      
                      const SizedBox(height: 32),
                      
                      // Submit Button
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