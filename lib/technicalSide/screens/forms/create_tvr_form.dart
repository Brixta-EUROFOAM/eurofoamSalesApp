// lib/technicalSide/screens/forms/create_tvr_form.dart
import 'dart:io';
import 'dart:async';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/technicalSide/models/technical_visit_report_model.dart';
import 'package:salesmanapp/models/employee_model.dart';
import 'package:salesmanapp/models/pjp_model.dart';
import 'package:salesmanapp/technicalSide/models/sites_model.dart';
import 'package:salesmanapp/technicalSide/models/mason_pc_model.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class CreateTvrScreen extends StatefulWidget {
  final Employee employee;
  final Pjp? pjp;
  final TechnicalSite? site;
  final DateTime? initialCheckInTime;

  const CreateTvrScreen({
    super.key, 
    required this.employee,
    this.pjp,
    this.site,
    this.initialCheckInTime,
  });

  @override
  State<CreateTvrScreen> createState() => _CreateTvrScreenState();
}

class _CreateTvrScreenState extends State<CreateTvrScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _imagePicker = ImagePicker();

  // --- SELECTION STATE ---
  TechnicalSite? _selectedSite;
  Mason? _selectedMason;

  // --- CONTROLLERS ---
  final _siteNameConcernedPersonController = TextEditingController();
  final _phoneNoController = TextEditingController();
  final _whatsappNoController = TextEditingController(); // ✅ Added to UI
  final _emailIdController = TextEditingController();    // ✅ Added to UI
  
  final _clientsRemarksController = TextEditingController();
  final _salespersonRemarksController = TextEditingController();
  final _siteVisitBrandInUseController = TextEditingController();
  
  final _conversionFromBrandController = TextEditingController();
  final _conversionQuantityValueController = TextEditingController();
  final _associatedPartyNameController = TextEditingController();
  final _influencerTypeController = TextEditingController();
  final _serviceTypeController = TextEditingController();
  final _qualityComplaintController = TextEditingController();
  final _promotionalActivityController = TextEditingController();
  final _channelPartnerVisitController = TextEditingController(); // ✅ Added to UI

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
  final _dhalaiVerificationCodeController = TextEditingController(); // ✅ Added to UI
  final _isVerificationStatusController = TextEditingController();
  final _influencerNameController = TextEditingController();
  final _influencerPhoneController = TextEditingController();
  final _influencerProductivityController = TextEditingController();
  
  // New Region/Area controllers
  final _regionController = TextEditingController();
  final _areaController = TextEditingController();

  // --- STATE ---
  bool _isSubmitting = false;
  bool _isUploadingImage = false;
  
  // Dropdowns
  String? _selectedVisitType = 'Site Visit';
  String? _selectedVisitCategory;
  String? _selectedCustomerType;
  String? _selectedConversionType;
  String? _selectedConversionUnit;
  String? _selectedStage;
  String? _selectedSiteVisitType;

  // Booleans
  bool _isConverted = false;
  bool _isTechService = false;
  bool _isSchemeEnrolled = false;

  // Check-In Data & Images
  DateTime? _checkInTime;
  File? _inTimeImageFile;
  String? _inTimeImageUrl;
  Position? _capturedLocation;
  
  // Site Photo (Progress/Evidence)
  File? _sitePhotoFile; 

  // --- THEME ---
  static const Color _surfaceWhite  = Colors.white;
  static const Color _cardNavy      = Color(0xFF0F172A); 
  static const Color _textDark      = Color(0xFF111827); 
  static const Color _textGrey      = Color(0xFF6B7280); 
  static const Color _inputFill     = Color(0xFFF9FAFB); 
  static const Color _accentGreen   = Color(0xFF10B981); 
  static const Color _accentOrange  = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    if (widget.site != null) {
      _onSiteSelected(widget.site!);
    }
    if (widget.initialCheckInTime != null) {
      _checkInTime = widget.initialCheckInTime;
    }
  }

  @override
  void dispose() {
    _siteNameConcernedPersonController.dispose();
    _phoneNoController.dispose();
    _emailIdController.dispose();
    _whatsappNoController.dispose();
    _clientsRemarksController.dispose();
    _salespersonRemarksController.dispose();
    _siteVisitBrandInUseController.dispose();
    _conversionFromBrandController.dispose();
    _conversionQuantityValueController.dispose();
    _associatedPartyNameController.dispose();
    _influencerTypeController.dispose();
    _serviceTypeController.dispose();
    _qualityComplaintController.dispose();
    _promotionalActivityController.dispose();
    _channelPartnerVisitController.dispose();
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
    _regionController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  void _onSiteSelected(TechnicalSite site) {
    setState(() {
      _selectedSite = site;
      _siteNameConcernedPersonController.text = site.concernedPerson;
      _phoneNoController.text = site.phoneNo;
      _siteAddressController.text = site.address;
      _regionController.text = site.region ?? '';
      _areaController.text = site.area ?? '';
      if(site.stageOfConstruction != null) _selectedStage = site.stageOfConstruction;
    });
  }

  void _onMasonSelected(Mason mason) {
    setState(() {
      _selectedMason = mason;
      _influencerNameController.text = mason.name;
      _influencerPhoneController.text = mason.phoneNumber;
    });
  }

  Future<void> _openSiteSearch() async {
    final TechnicalSite? result = await showDialog(
      context: context,
      builder: (context) => _ServerSiteSearchDialog(api: _apiService, userId: int.parse(widget.employee.id)),
    );
    if (result != null) _onSiteSelected(result);
  }

  Future<void> _openMasonSearch() async {
    final Mason? result = await showDialog(
      context: context,
      builder: (context) => _ServerMasonSearchDialog(api: _apiService),
    );
    if (result != null) _onMasonSelected(result);
  }

  Future<void> _handleCheckIn() async {
    if (_selectedSite == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a site first.')));
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _isUploadingImage = true);
    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 60);
      
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
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Checked-In successfully.'), backgroundColor: _accentGreen));
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Check-In Failed: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if(mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _pickSitePhoto() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 60);
    if (pickedFile != null) {
      setState(() {
        _sitePhotoFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitTvr() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fill all required fields (marked in Red).'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    
    if (_checkInTime == null || _capturedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check-in is required.')));
      return;
    }

    // --- 10 min Time Check Logic ---
    final now = DateTime.now();
    final difference = now.difference(_checkInTime!);
    const minMinutes = 10; 

    if (difference.inMinutes < minMinutes) {
      final remaining = minMinutes - difference.inMinutes;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Minimum 10 mins required. Wait $remaining more minute(s)."),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        )
      );
      return;
    }

    // --- GEOFENCE CHECK (50 Meters) ---
    if (_selectedSite != null) {
        if (_selectedSite!.latitude != 0.0 && _selectedSite!.longitude != 0.0) {
           
           double distanceInMeters = Geolocator.distanceBetween(
              _capturedLocation!.latitude, // From Check-in
              _capturedLocation!.longitude,
              _selectedSite!.latitude,
              _selectedSite!.longitude,
           );

           if (distanceInMeters > 50) {
             ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Geofence Error: You are ${distanceInMeters.toStringAsFixed(0)}m away from the Site. You must be within 50m."),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 5),
                )
              );
              return; // BLOCK SUBMISSION
           }
        }
    }

    final hours = difference.inHours;
    final minutes = difference.inMinutes.remainder(60);
    final String timeSpentStr = '${hours}h ${minutes}m';

    setState(() => _isSubmitting = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // 1. Upload Out Time Image
      final pickedOutFile = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 60);
      String? outTimeImageUrl;
      if (pickedOutFile != null) {
        outTimeImageUrl = await _apiService.uploadImageToR2(File(pickedOutFile.path));
      }

      // 2. Upload Site Photo (If selected)
      String? sitePhotoUrl;
      if (_sitePhotoFile != null) {
        sitePhotoUrl = await _apiService.uploadImageToR2(_sitePhotoFile!);
      }

      // 3. Create Model
      final tvrReport = TechnicalVisitReport(
        userId: int.parse(widget.employee.id),
        reportDate: DateTime.now(),
        visitType: _selectedVisitType!,
        
        // IDs
        siteId: _selectedSite?.id, 
        masonId: _selectedMason?.id, 
        pjpId: widget.pjp?.id, 
        
        // Contact
        siteNameConcernedPerson: _siteNameConcernedPersonController.text,
        phoneNo: _phoneNoController.text,
        whatsappNo: _whatsappNoController.text.isNotEmpty ? _whatsappNoController.text : null,
        emailId: _emailIdController.text.isNotEmpty ? _emailIdController.text : null,
        siteAddress: _siteAddressController.text.isNotEmpty ? _siteAddressController.text : null,
        marketName: _marketNameController.text.isNotEmpty ? _marketNameController.text : null,
        region: _regionController.text.isNotEmpty ? _regionController.text : null, 
        area: _areaController.text.isNotEmpty ? _areaController.text : null, 
        
        latitude: _capturedLocation?.latitude,
        longitude: _capturedLocation?.longitude,

        visitCategory: _selectedVisitCategory,
        customerType: _selectedCustomerType,
        purposeOfVisit: _purposeOfVisitController.text.isNotEmpty ? _purposeOfVisitController.text : null,
        siteVisitType: _selectedSiteVisitType, 

        // Construction
        siteVisitStage: _selectedStage,
        constAreaSqFt: int.tryParse(_constAreaSqFtController.text),
        siteVisitBrandInUse: _siteVisitBrandInUseController.text.split(',').map((e) => e.trim()).where((s) => s.isNotEmpty).toList(),
        currentBrandPrice: double.tryParse(_currentBrandPriceController.text),
        siteStock: double.tryParse(_siteStockController.text),
        estRequirement: double.tryParse(_estRequirementController.text),

        // Dealers
        supplyingDealerName: _supplyingDealerNameController.text.isNotEmpty ? _supplyingDealerNameController.text : null,
        nearbyDealerName: _nearbyDealerNameController.text.isNotEmpty ? _nearbyDealerNameController.text : null,
        associatedPartyName: _associatedPartyNameController.text.isNotEmpty ? _associatedPartyNameController.text : null,
        channelPartnerVisit: _channelPartnerVisitController.text.isNotEmpty ? _channelPartnerVisitController.text : null,

        // Conversion
        isConverted: _isConverted,
        conversionType: _isConverted ? _selectedConversionType : null,
        conversionFromBrand: _conversionFromBrandController.text.isNotEmpty ? _conversionFromBrandController.text : null,
        conversionQuantityValue: double.tryParse(_conversionQuantityValueController.text),
        conversionQuantityUnit: _isConverted ? _selectedConversionUnit : null,

        // Technical
        isTechService: _isTechService,
        serviceDesc: _serviceDescController.text.isNotEmpty ? _serviceDescController.text : null,
        serviceType: _serviceTypeController.text.isNotEmpty ? _serviceTypeController.text : null,
        dhalaiVerificationCode: _dhalaiVerificationCodeController.text.isNotEmpty ? _dhalaiVerificationCodeController.text : null,
        isVerificationStatus: _isVerificationStatusController.text.isNotEmpty ? _isVerificationStatusController.text : null,
        qualityComplaint: _qualityComplaintController.text.isNotEmpty ? _qualityComplaintController.text : null,

        // Mason
        influencerName: _influencerNameController.text.isNotEmpty ? _influencerNameController.text : null,
        influencerPhone: _influencerPhoneController.text.isNotEmpty ? _influencerPhoneController.text : null,
        isSchemeEnrolled: _isSchemeEnrolled,
        influencerProductivity: _influencerProductivityController.text.isNotEmpty ? _influencerProductivityController.text : null,
        influencerType: _influencerTypeController.text.split(',').map((e) => e.trim()).where((s) => s.isNotEmpty).toList(),

        // Remarks
        clientsRemarks: _clientsRemarksController.text,
        salespersonRemarks: _salespersonRemarksController.text,
        promotionalActivity: _promotionalActivityController.text.isNotEmpty ? _promotionalActivityController.text : null,
        
        // Metadata
        checkInTime: _checkInTime!,
        checkOutTime: now,
        timeSpentinLoc: timeSpentStr, 
        inTimeImageUrl: _inTimeImageUrl,
        outTimeImageUrl: outTimeImageUrl,
        sitePhotoUrl: sitePhotoUrl, // ✅ Mapped here
      );

      await _apiService.createTvr(tvrReport);

      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('TVR submitted successfully!'), backgroundColor: _accentGreen));
      if (mounted) Navigator.pop(context);

    } catch (e) {
      if(mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // --- UI WIDGETS ---

  Widget _buildFintechInput({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool isRequired = true,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
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
          readOnly: readOnly,
          style: const TextStyle(color: _textDark, fontWeight: FontWeight.w500),
          validator: isRequired ? (v) => v!.isEmpty ? 'Required' : null : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? Colors.grey[200] : _inputFill,
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
        RichText(text: TextSpan(text: label, style: const TextStyle(color: _textDark, fontWeight: FontWeight.w600, fontSize: 13, fontFamily: 'Roboto'), children: [if (isRequired) const TextSpan(text: ' *', style: TextStyle(color: Colors.red))])),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          dropdownColor: _surfaceWhite,
          style: const TextStyle(color: _textDark, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            filled: true, fillColor: _inputFill,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          items: items.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
          Text(title.toUpperCase(), style: const TextStyle(color: _textGrey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Dialog-like
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _surfaceWhite,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)],
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
                      IconButton(icon: const Icon(Icons.close, color: _textGrey), onPressed: () => Navigator.of(context).pop()),
                    ],
                  ),
                  const Divider(height: 30, color: Color(0xFFF3F4F6)),

                  // --- Step 1: Check-In ---
                  if (_checkInTime == null) ...[
                    // Site Selector
                    InkWell(
                      onTap: _openSiteSearch,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(color: _inputFill, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Expanded(child: Text(_selectedSite != null ? "${_selectedSite!.siteName} (${_selectedSite!.region})" : "Select Construction Site *", style: TextStyle(color: _selectedSite != null ? _textDark : _textGrey, fontWeight: FontWeight.bold))),
                            const Icon(Icons.search, color: _textGrey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFintechInput(controller: _siteNameConcernedPersonController, label: 'Concerned Person', readOnly: true),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _isUploadingImage ? null : _handleCheckIn,
                      icon: _isUploadingImage ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.camera_alt),
                      label: const Text('CHECK-IN (PHOTO)', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: _accentOrange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ] 
                  
                  // --- Step 2: Full Form ---
                  else ...[
                    // Info Banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFBBF7D0))),
                      child: Row(
                        children: [
                          _inTimeImageFile != null ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_inTimeImageFile!, width: 50, height: 50, fit: BoxFit.cover)) : const Icon(Icons.check_circle, color: _accentGreen, size: 40),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(_selectedSite?.siteName ?? "Site Visit", style: const TextStyle(color: _textDark, fontWeight: FontWeight.bold)),
                            Text('In: ${DateFormat('hh:mm a').format(_checkInTime!)}', style: const TextStyle(color: _textGrey, fontSize: 12)),
                          ])),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Visit Info
                    _buildFintechDropdown(label: 'Visit Type', value: _selectedVisitType, items: ['Site Visit', 'Service', 'Complaint', 'Influencer Meet'], onChanged: (v) => setState(() => _selectedVisitType = v)),
                    const SizedBox(height: 16),
                    _buildFintechDropdown(label: 'Site Visit Type', value: _selectedSiteVisitType, items: ['Planned', 'Unplanned'], onChanged: (v) => setState(() => _selectedSiteVisitType = v), isRequired: false),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(child: _buildFintechDropdown(label: 'Visit Category', value: _selectedVisitCategory, items: ['New', 'Follow Up'], onChanged: (v) => setState(() => _selectedVisitCategory = v), isRequired: false)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildFintechDropdown(label: 'Customer Type', value: _selectedCustomerType, items: ['IHB', 'Contractor', 'Builder', 'Engineer', 'Architect'], onChanged: (v) => setState(() => _selectedCustomerType = v), isRequired: false)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildFintechInput(controller: _purposeOfVisitController, label: 'Purpose of Visit', isRequired: false),

                    // Site Info
                    _buildSectionHeader("SITE INFO"),
                    Row(
                      children: [
                        Expanded(child: _buildFintechInput(controller: _regionController, label: 'Region', readOnly: true, isRequired: false)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildFintechInput(controller: _areaController, label: 'Area', readOnly: true, isRequired: false)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildFintechInput(controller: _marketNameController, label: 'Market Name', isRequired: false),
                    const SizedBox(height: 16),
                    _buildFintechInput(controller: _siteAddressController, label: 'Site Address', maxLines: 2, isRequired: false),
                    const SizedBox(height: 16),
                    
                    InkWell(
                      onTap: _pickSitePhoto,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(color: _inputFill, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                        child: Row(
                          children: [
                            Icon(Icons.camera_enhance, color: _textGrey),
                            const SizedBox(width: 12),
                            Expanded(child: Text(_sitePhotoFile != null ? "Site Photo Selected" : "Capture Site Progress Photo", style: TextStyle(color: _sitePhotoFile != null ? _textDark : _textGrey))),
                            if (_sitePhotoFile != null) const Icon(Icons.check_circle, color: _accentGreen),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(child: _buildFintechInput(controller: _constAreaSqFtController, label: 'Area (SqFt)', keyboardType: TextInputType.number, isRequired: false)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildFintechDropdown(label: 'Stage', value: _selectedStage, items: ['Foundation', 'Plinth', 'Roofing', 'Finishing'], onChanged: (v) => setState(() => _selectedStage = v), isRequired: false)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildFintechInput(controller: _siteVisitBrandInUseController, label: 'Brands in Use', hint: 'Brand A, Brand B'),
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

                    // Dealer Info
                    _buildSectionHeader("DEALER INFO"),
                    _buildFintechInput(controller: _supplyingDealerNameController, label: 'Supplying Dealer', isRequired: false),
                    const SizedBox(height: 16),
                    _buildFintechInput(controller: _nearbyDealerNameController, label: 'Nearby Dealer (Best)', isRequired: false),
                    const SizedBox(height: 16),
                    _buildFintechInput(controller: _associatedPartyNameController, label: 'Associated Party Name', isRequired: false),
                    const SizedBox(height: 16),
                    _buildFintechInput(controller: _channelPartnerVisitController, label: 'Channel Partner Visit', isRequired: false),

                    // Conversion
                    _buildSectionHeader("CONVERSION"),
                    _buildFintechSwitch(label: "Is Converted?", value: _isConverted, onChanged: (v) => setState(() => _isConverted = v)),
                    if (_isConverted) ...[
                      const SizedBox(height: 12),
                      _buildFintechDropdown(label: 'Conversion Type', value: _selectedConversionType, items: ['New', 'Retention'], onChanged: (v) => setState(() => _selectedConversionType = v), isRequired: true),
                      const SizedBox(height: 16),
                      _buildFintechInput(controller: _conversionFromBrandController, label: 'From Brand', isRequired: true),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildFintechInput(controller: _conversionQuantityValueController, label: 'Qty', keyboardType: TextInputType.number, isRequired: true)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildFintechDropdown(label: 'Unit', value: _selectedConversionUnit, items: ['Bags', 'MT'], onChanged: (v) => setState(() => _selectedConversionUnit = v), isRequired: true)),
                        ],
                      ),
                    ],

                    // Technical Services
                    _buildSectionHeader("TECHNICAL SERVICES"),
                    _buildFintechSwitch(label: "Tech Service Given?", value: _isTechService, onChanged: (v) => setState(() => _isTechService = v)),
                    if (_isTechService) ...[
                      const SizedBox(height: 12),
                      _buildFintechInput(controller: _serviceTypeController, label: 'Service Type', isRequired: true),
                      const SizedBox(height: 16),
                      _buildFintechInput(controller: _serviceDescController, label: 'Description', maxLines: 2, isRequired: false),
                      const SizedBox(height: 16),
                      //_buildFintechInput(controller: _dhalaiVerificationCodeController, label: 'Dhalai Code', isRequired: false),
                      const SizedBox(height: 16),
                      _buildFintechInput(controller: _isVerificationStatusController, label: 'Verification Status', isRequired: false),
                    ],
                    const SizedBox(height: 16),
                    _buildFintechInput(controller: _qualityComplaintController, label: 'Quality Complaint', isRequired: false),

                    // Mason/Influencer
                    _buildSectionHeader("INFLUENCER / MASON"),
                    InkWell(
                      onTap: _openMasonSearch,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(color: _inputFill, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                        child: Row(
                          children: [
                            Icon(Icons.person_search, color: _cardNavy),
                            const SizedBox(width: 12),
                            Expanded(child: Text(_selectedMason != null ? _selectedMason!.name : "Link Registered Mason (Optional)", style: TextStyle(color: _selectedMason != null ? _textDark : _textGrey, fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFintechInput(controller: _influencerTypeController, label: 'Influencer Type', hint: 'Mason, Contractor, Engineer'),
                    const SizedBox(height: 16),
                    _buildFintechInput(controller: _influencerNameController, label: 'Name', isRequired: false),
                    const SizedBox(height: 16),
                    _buildFintechInput(controller: _influencerPhoneController, label: 'Phone', keyboardType: TextInputType.phone, isRequired: false),
                    const SizedBox(height: 16),
                    _buildFintechInput(controller: _influencerProductivityController, label: 'Influencer Productivity', isRequired: false),
                    const SizedBox(height: 16),
                    _buildFintechSwitch(label: "Enrolled in Scheme?", value: _isSchemeEnrolled, onChanged: (v) => setState(() => _isSchemeEnrolled = v)),
                    
                    // Remarks & Extra Contact Info
                    _buildSectionHeader("REMARKS & EXTRAS"),
                    _buildFintechInput(controller: _whatsappNoController, label: 'Phone/WhatsApp No.', keyboardType: TextInputType.phone, isRequired: false), 
                    const SizedBox(height: 16),
                    _buildFintechInput(controller: _emailIdController, label: 'Email ID', keyboardType: TextInputType.emailAddress, isRequired: false), 
                    const SizedBox(height: 16),
                    _buildFintechInput(controller: _clientsRemarksController, label: "Client's Remarks", maxLines: 2),
                    const SizedBox(height: 16),
                    _buildFintechInput(controller: _salespersonRemarksController, label: 'Salesperson Remarks', maxLines: 2),
                    const SizedBox(height: 16),
                    _buildFintechInput(controller: _promotionalActivityController, label: 'Promotional Activity', isRequired: false),

                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitTvr,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentGreen, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSubmitting 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                        : const Text('SUBMIT & CHECK-OUT', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ServerSiteSearchDialog extends StatefulWidget {
  final ApiService api;
  final int userId;
  const _ServerSiteSearchDialog({required this.api, required this.userId});
  @override
  State<_ServerSiteSearchDialog> createState() => _ServerSiteSearchDialogState();
}

class _ServerSiteSearchDialogState extends State<_ServerSiteSearchDialog> {
  List<TechnicalSite> _sites = [];
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
        final res = await widget.api.fetchTechnicalSites(userId: widget.userId, search: query);
        if (mounted) setState(() => _sites = res);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _search(""); 
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
            const Text("Select Site", style: TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            TextField(
              style: const TextStyle(color: _textDark),
              decoration: const InputDecoration(
                hintText: "Search site...",
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
                : _sites.isEmpty 
                  ? const Center(child: Text("No sites found", style: TextStyle(color: _textGrey)))
                  : ListView.separated(
                      itemCount: _sites.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      itemBuilder: (ctx, i) => ListTile(
                        title: Text(_sites[i].siteName, style: const TextStyle(color: _textDark, fontWeight: FontWeight.w600)),
                        subtitle: Text("${_sites[i].address} • ${_sites[i].concernedPerson}", style: const TextStyle(color: _textGrey, fontSize: 12)),
                        onTap: () => Navigator.pop(context, _sites[i]),
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

class _ServerMasonSearchDialog extends StatefulWidget {
  final ApiService api;
  const _ServerMasonSearchDialog({required this.api});
  @override
  State<_ServerMasonSearchDialog> createState() => _ServerMasonSearchDialogState();
}

class _ServerMasonSearchDialogState extends State<_ServerMasonSearchDialog> {
  List<Mason> _masons = [];
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
        final res = await widget.api.fetchMasons(search: query);
        if (mounted) setState(() => _masons = res);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _search("");
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
            const Text("Select Mason", style: TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            TextField(
              style: const TextStyle(color: _textDark),
              decoration: const InputDecoration(
                hintText: "Search mason...",
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
                : _masons.isEmpty
                  ? const Center(child: Text("No masons found", style: TextStyle(color: _textGrey)))
                  : ListView.separated(
                      itemCount: _masons.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      itemBuilder: (ctx, i) => ListTile(
                        title: Text(_masons[i].name, style: const TextStyle(color: _textDark, fontWeight: FontWeight.w600)),
                        subtitle: Text(_masons[i].phoneNumber, style: const TextStyle(color: _textGrey, fontSize: 12)),
                        onTap: () => Navigator.pop(context, _masons[i]),
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