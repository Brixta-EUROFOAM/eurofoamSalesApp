// lib/screens/forms/create_dvr.dart

import 'dart:io';
import 'dart:async';
import 'dart:convert'; 
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/models/daily_visit_report_model.dart';
import 'package:salesmanapp/models/dealer_model.dart';
import 'package:salesmanapp/models/employee_model.dart';
import 'package:salesmanapp/models/pjp_model.dart';

class CreateDvrScreen extends StatefulWidget {
  final Employee employee;
  final Pjp? pjp; 
  final Dealer? dealer; 
  final DateTime? initialCheckInTime; 

  const CreateDvrScreen({
    super.key,
    required this.employee,
    this.pjp,
    this.dealer,
    this.initialCheckInTime,
  });

  @override
  State<CreateDvrScreen> createState() => _CreateDvrScreenState();
}

class _CreateDvrScreenState extends State<CreateDvrScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  // --- Controllers ---
  final _contactPersonController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _brandSellingController = TextEditingController();
  final _potentialController = TextEditingController(); 
  final _bestPotentialController = TextEditingController(); 
  final _todayOrderMtController = TextEditingController();
  final _todayCollectionController = TextEditingController();
  final _overdueAmountController = TextEditingController(); 
  final _feedbackController = TextEditingController();
  final _remarksController = TextEditingController();
  final _solutionController = TextEditingController();
  
  // --- State ---
  bool _isSubmitting = false;
  bool _isUploadingImage = false;
  bool _isSubDealerVisit = false; 
  Dealer? _selectedDealer;
  Dealer? _selectedParentDealer; 
  String? _visitType = 'PLANNED'; 
  
  // Check-In Data
  DateTime? _checkInTime;
  String? _inTimeImageUrl;
  File? _inTimeImageFile;
  Position? _checkInLocation;

  // --- 🎨 FINTECH THEME PALETTE ---
  static const Color _surfaceWhite = Colors.white;
  static const Color _textDark = Color(0xFF111827);
  static const Color _textGrey = Color(0xFF6B7280);
  static const Color _cardNavy = Color(0xFF0F172A);
  static const Color _inputFill = Color(0xFFF9FAFB);
  static const Color _accentGreen = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _contactPersonController.dispose();
    _contactPhoneController.dispose();
    _brandSellingController.dispose();
    _potentialController.dispose();
    _bestPotentialController.dispose();
    _todayOrderMtController.dispose();
    _todayCollectionController.dispose();
    _overdueAmountController.dispose(); 
    _feedbackController.dispose();
    _remarksController.dispose();
    _solutionController.dispose();
    super.dispose();
  }

  void _initializeData() {
    if (widget.dealer != null) {
      _onDealerSelected(widget.dealer!);
      setState(() {
        _checkInTime = widget.initialCheckInTime ?? DateTime.now();
        _visitType = 'PLANNED'; 
        if (widget.dealer!.parentDealerId != null) {
           _isSubDealerVisit = true;
        }
      });
    } else {
      setState(() {
        _visitType = 'UNPLANNED';
      });
    }
  }

  void _onDealerSelected(Dealer dealer) {
    setState(() {
      _selectedDealer = dealer;
      
      if (dealer.parentDealerId != null) {
        _isSubDealerVisit = true;
      } else {
        _isSubDealerVisit = false;
        _selectedParentDealer = null;
      }
      
      _contactPersonController.text = dealer.name; 
      _contactPhoneController.text = dealer.phoneNo;
      _brandSellingController.text = dealer.brandSelling.join(", ");
      _potentialController.text = dealer.totalPotential.toString();
      _bestPotentialController.text = dealer.bestPotential.toString();
    });
  }

  Future<void> _openDealerSearch() async {
    final result = await showDialog<Dealer>(
      context: context,
      builder: (context) => _ServerDealerSearchDialog(
        api: _apiService, 
        userId: int.tryParse(widget.employee.id)
      ),
    );

    if (result != null) {
      _onDealerSelected(result);
    }
  }

  Future<void> _openParentDealerSearch() async {
    final result = await showDialog<Dealer>(
      context: context,
      builder: (context) => _ServerDealerSearchDialog(
        api: _apiService, 
        userId: int.tryParse(widget.employee.id) 
      ),
    );

    if (result != null) {
      setState(() {
        _selectedParentDealer = result;
      });
    }
  }

  Future<void> _handleCheckIn() async {
    if (_selectedDealer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a dealer first.")));
      return;
    }

    setState(() => _isUploadingImage = true);
    
    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
      if (image == null) {
        setState(() => _isUploadingImage = false);
        return;
      }
      
      final file = File(image.path);
      final url = await _apiService.uploadImageToR2(file);

      if (mounted) {
        setState(() {
          _checkInTime = DateTime.now();
          _checkInLocation = position;
          _inTimeImageFile = file;
          _inTimeImageUrl = url;
          _isUploadingImage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Check-in failed: $e"), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _submitDvr() async {
    if (!_formKey.currentState!.validate()) return;
    if (_checkInTime == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Check-in is required!")));
       return;
    }
    
    // --- 10 MINUTE CHECK LOGIC ---
    final now = DateTime.now();
    final difference = now.difference(_checkInTime!);
    const minMinutes = 10;
    //const minSeconds = 25;

    if (difference.inMinutes < minMinutes) {
      final remaining = minMinutes - difference.inMinutes;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Minimum 10 mins required at site. Please wait $remaining more minute(s)."),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        )
      );
      return;
    }
    // -------------------------------

    // --- Calculate Time Spent ---
    final hours = difference.inHours;
    final minutes = difference.inMinutes.remainder(60);
    final String timeSpentStr = '${hours}h ${minutes}m';
    // -------------------------------

    if (_selectedDealer?.id == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selected Dealer has invalid ID.")));
       return;
    }

    if (_isSubDealerVisit && _selectedParentDealer == null && _selectedDealer!.parentDealerId == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select the Parent Dealer.")));
       return;
    }

    setState(() => _isSubmitting = true);

    try {
      final XFile? outImage = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
      String? outTimeUrl;
      
      if (outImage != null) {
        outTimeUrl = await _apiService.uploadImageToR2(File(outImage.path));
      }

      final List<String> brandsList = _brandSellingController.text
          .split(',')
          .map((e) => e.trim())
          .where((element) => element.isNotEmpty)
          .toList();

      String? finalDealerId;
      String? finalSubDealerId;
      String finalDealerType;

      if (_isSubDealerVisit) {
         finalSubDealerId = _selectedDealer!.id;
         finalDealerId = _selectedParentDealer?.id ?? _selectedDealer!.parentDealerId;
         finalDealerType = 'Sub Dealer';
         if (finalDealerId == null) throw Exception("Parent Dealer ID missing for Sub-Dealer visit");
      } else {
         finalDealerId = _selectedDealer!.id;
         finalSubDealerId = null;
         finalDealerType = 'Dealer';
      }

      String locationStr = _selectedDealer!.address;
      if (locationStr.length > 490) {
        locationStr = locationStr.substring(0, 490);
      }

      final dvr = DailyVisitReport(
        userId: int.parse(widget.employee.id),
        reportDate: DateTime.now(),
        dealerId: finalDealerId, 
        subDealerId: finalSubDealerId,
        dealerType: finalDealerType,
        location: locationStr,
        latitude: _checkInLocation?.latitude ?? _selectedDealer!.latitude ?? 0.0,
        longitude: _checkInLocation?.longitude ?? _selectedDealer!.longitude ?? 0.0,
        visitType: _visitType!,
        dealerTotalPotential: double.tryParse(_potentialController.text.trim()) ?? 0.0,
        dealerBestPotential: double.tryParse(_bestPotentialController.text.trim()) ?? 0.0,
        brandSelling: brandsList.isEmpty ? ["N/A"] : brandsList,
        contactPerson: _contactPersonController.text.trim(),
        contactPersonPhoneNo: _contactPhoneController.text.trim(),
        todayOrderMt: double.tryParse(_todayOrderMtController.text.trim()) ?? 0.0,
        todayCollectionRupees: double.tryParse(_todayCollectionController.text.trim()) ?? 0.0,
        
        overdueAmount: double.tryParse(_overdueAmountController.text.trim()),
        timeSpentinLoc: timeSpentStr, // Auto calculated

        feedbacks: _feedbackController.text.trim(),
        solutionBySalesperson: _solutionController.text.isNotEmpty ? _solutionController.text.trim() : null,
        anyRemarks: _remarksController.text.isNotEmpty ? _remarksController.text.trim() : null,
        checkInTime: _checkInTime!,
        checkOutTime: now,
        inTimeImageUrl: _inTimeImageUrl,
        outTimeImageUrl: outTimeUrl,
        pjpId: widget.pjp?.id,
      );
      
      debugPrint("Submitting DVR Payload: ${jsonEncode(dvr.toJson())}");

      await _apiService.createDvr(dvr);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("DVR Submitted Successfully!"), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("DVR Submission Error: $e");
      if (mounted) {
        String errorMsg = "Submission Failed: $e";
        if (e.toString().contains("500")) {
           errorMsg = "Server Error (500). Please check data format.";
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.red));
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
          validator: validator ?? (isRequired ? (v) => v!.isEmpty ? 'Required' : null : null),
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
      backgroundColor: Colors.transparent, 
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _surfaceWhite, 
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 10))
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- Header ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Daily Visit Report", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textDark)),
                      IconButton(
                        icon: const Icon(Icons.close, color: _textGrey),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const Divider(height: 30, color: _inputFill),

                  // --- STEP 1: Dealer & Check-In ---
                  if (_checkInTime == null) ...[
                    
                    // Dealer Selector
                    InkWell(
                      onTap: widget.dealer == null ? _openDealerSearch : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          color: _inputFill,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedDealer != null 
                                  ? "${_selectedDealer!.name} (${_selectedDealer!.region})" 
                                  : "Select Dealer / Sub-Dealer *",
                                style: TextStyle(
                                  color: _selectedDealer != null ? _textDark : _textGrey,
                                  fontWeight: _selectedDealer != null ? FontWeight.w600 : FontWeight.normal,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, color: _textGrey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Sub-Dealer Toggle
                    Row(
                      children: [
                        Checkbox(
                          value: _isSubDealerVisit, 
                          activeColor: _cardNavy,
                          onChanged: (val) {
                            setState(() {
                              _isSubDealerVisit = val ?? false;
                              if (!_isSubDealerVisit) _selectedParentDealer = null;
                            });
                          }
                        ),
                        const Text("This is a Sub-Dealer visit", style: TextStyle(color: _textDark, fontSize: 14)),
                      ],
                    ),
                    
                    // Parent Dropdown (Now uses Search Dialog)
                    if (_isSubDealerVisit) 
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: InkWell(
                          onTap: _openParentDealerSearch, 
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              color: _inputFill,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedParentDealer != null 
                                      ? "${_selectedParentDealer!.name} (${_selectedParentDealer!.region})" 
                                      : "Select Parent Dealer *",
                                    style: TextStyle(
                                      color: _selectedParentDealer != null ? _textDark : _textGrey,
                                      fontWeight: _selectedParentDealer != null ? FontWeight.w600 : FontWeight.normal,
                                      fontSize: 15,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.search, color: _textGrey),
                              ],
                            ),
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Visit Type
                    DropdownButtonFormField<String>(
                      value: _visitType,
                      dropdownColor: _surfaceWhite,
                      style: const TextStyle(color: _textDark, fontSize: 15),
                      items: ['PLANNED', 'UNPLANNED', 'EMERGENCY', 'COLLECTION'].map((t) => DropdownMenuItem(
                        value: t, child: Text(t)
                      )).toList(),
                      onChanged: (val) => setState(() => _visitType = val),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: _inputFill,
                        labelText: "Visit Type",
                        labelStyle: const TextStyle(color: _textGrey, fontSize: 13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _cardNavy, width: 1.5)),
                      ),
                    ),

                    const SizedBox(height: 24),

                    ElevatedButton.icon(
                      onPressed: _isUploadingImage ? null : _handleCheckIn,
                      icon: _isUploadingImage 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                        : const Icon(Icons.camera_alt_rounded, color: Colors.white),
                      label: const Text("CHECK-IN WITH PHOTO", style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _cardNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ] 
                  
                  // --- STEP 2: Full Report Form ---
                  else ...[
                    // Info Banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: Row(
                        children: [
                          _inTimeImageFile != null 
                            ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_inTimeImageFile!, width: 50, height: 50, fit: BoxFit.cover))
                            : const Icon(Icons.store, color: Colors.blue, size: 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_selectedDealer?.name ?? "Dealer", style: const TextStyle(fontWeight: FontWeight.bold, color: _textDark)),
                                Text("Checked in: ${DateFormat('hh:mm a').format(_checkInTime!)}", style: const TextStyle(fontSize: 12, color: _textGrey)),
                              ],
                            ),
                          ),
                          const Icon(Icons.check_circle, color: _accentGreen),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    _buildSectionHeader("CONTACT INFO"),
                    Row(
                      children: [
                        Expanded(child: _buildFintechInput(controller: _contactPersonController, label: "Contact Person")),
                        const SizedBox(width: 12),
                        Expanded(child: _buildFintechInput(controller: _contactPhoneController, label: "Phone", keyboardType: TextInputType.phone)),
                      ],
                    ),

                    _buildSectionHeader("BUSINESS DATA"),
                    Row(
                      children: [
                        Expanded(child: _buildFintechInput(controller: _potentialController, label: "Total Potential", keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildFintechInput(controller: _bestPotentialController, label: "Best Potential", keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _buildFintechInput(controller: _brandSellingController, label: "Brands Selling (Comma separated)"),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(child: _buildFintechInput(controller: _todayOrderMtController, label: "Today Order (MT)", keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildFintechInput(controller: _todayCollectionController, label: "Collection (₹)", keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _buildFintechInput(controller: _overdueAmountController, label: "Overdue Amount (₹)", keyboardType: TextInputType.number, isRequired: false),

                    _buildSectionHeader("QUALITATIVE DATA"),
                    _buildFintechInput(controller: _feedbackController, label: "Market Feedback / Issues", maxLines: 2),
                    const SizedBox(height: 12),

                    _buildFintechInput(controller: _solutionController, label: "Solution by Salesperson (Optional)", isRequired: false, maxLines: 2),
                    const SizedBox(height: 12),
                    
                    _buildFintechInput(controller: _remarksController, label: "Competitor Info / Remarks (Optional)", isRequired: false, maxLines: 2),
                    
                    const SizedBox(height: 32),
                    
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitDvr,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text("SUBMIT & CHECK-OUT", style: TextStyle(fontWeight: FontWeight.bold)),
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

// --- Internal Search Dialog ---
class _ServerDealerSearchDialog extends StatefulWidget {
  final ApiService api;
  final int? userId;
  const _ServerDealerSearchDialog({required this.api, this.userId});
  @override
  State<_ServerDealerSearchDialog> createState() => _ServerDealerSearchDialogState();
}

class _ServerDealerSearchDialogState extends State<_ServerDealerSearchDialog> {
  List<Dealer> _dealers = [];
  bool _isLoading = false;
  Timer? _debounce;
  String _lastQuery = "";
  static const Color _textDark = Color(0xFF111827);
  static const Color _textGrey = Color(0xFF6B7280);
  static const Color _inputFill = Color(0xFFF9FAFB);

  @override
  void initState() {
    super.initState();
    _performSearch("");
  }
  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query != _lastQuery) _performSearch(query);
    });
  }
  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    _lastQuery = query;
    try {
      final results = await widget.api.fetchDealers(
        search: query, 
        limit: 20, 
      );
      if (mounted) {
        setState(() { _dealers = results; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("Select Dealer", style: TextStyle(color: _textDark, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              style: const TextStyle(color: _textDark),
              decoration: InputDecoration(
                hintText: "Search dealer...",
                hintStyle: const TextStyle(color: _textGrey),
                prefixIcon: const Icon(Icons.search, color: _textGrey),
                filled: true,
                fillColor: _inputFill,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading ? const Center(child: CircularProgressIndicator()) : _dealers.isEmpty ? const Center(child: Text("No dealers found")) : ListView.separated(
                itemCount: _dealers.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1, color: Color(0xFFE5E7EB)),
                itemBuilder: (context, index) {
                  final dealer = _dealers[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(dealer.name, style: const TextStyle(color: _textDark, fontWeight: FontWeight.w600)),
                    subtitle: Text("${dealer.region}, ${dealer.area}", style: const TextStyle(color: _textGrey, fontSize: 12)),
                    onTap: () => Navigator.pop(context, dealer),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context, null), child: const Text("CANCEL"))],
    );
  }
}