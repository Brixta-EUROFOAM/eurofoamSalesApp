import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/models/daily_visit_report_model.dart';
import 'package:salesmanapp/models/dealer_model.dart';
import 'package:salesmanapp/models/employee_model.dart';
import 'package:salesmanapp/models/pjp_model.dart';

import 'package:salesmanapp/screens/dvrwidgets/dvr_dealer_form.dart';
import 'package:salesmanapp/screens/dvrwidgets/dvr_camera.dart';

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
  final _dealerFormKey = GlobalKey<FormState>();

  final ApiService _apiService = ApiService();

  Map<String, dynamic> _dealerFormData = {};

  bool _isSubmitting = false;
  bool _isUploadingImage = false;

  /// 🔥 NEW FLOW CONTROL
  bool _isSubDealerVisit = false;

  Dealer? _selectedDealer;
  Dealer? _selectedParentDealer;

  DateTime? _checkInTime;
  String? _inTimeImageUrl;
  Position? _checkInLocation;

  /// 🎨 FINTECH THEME
  static const Color _surfaceWhite = Colors.white;
  static const Color _textDark = Color(0xFF111827);
  static const Color _textGrey = Color(0xFF6B7280);
  static const Color _cardNavy = Color(0xFF0F172A);
  static const Color _inputFill = Color(0xFFF9FAFB);
  static const Color _accentGreen = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    if (widget.dealer != null) {
      _selectedDealer = widget.dealer;
    }
  }

  /// ------------------------------------------------
  /// 🔎 DEALER SEARCH
  /// ------------------------------------------------
  Future<void> _openDealerSearch() async {
    final result = await showDialog<Dealer>(
      context: context,
      builder: (context) => _ServerDealerSearchDialog(api: _apiService),
    );

    if (result != null) {
      setState(() => _selectedDealer = result);
    }
  }

  Future<void> _openParentDealerSearch() async {
    final result = await showDialog<Dealer>(
      context: context,
      builder: (context) => _ServerDealerSearchDialog(api: _apiService),
    );

    if (result != null) {
      setState(() => _selectedParentDealer = result);
    }
  }

  /// ------------------------------------------------
  /// 📸 INLINE CAMERA CHECK-IN (O(1) Optimized)
  /// ------------------------------------------------
  Future<void> _handleCheckIn() async {
    if (_selectedDealer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select dealer first")),
      );
      return;
    }

    setState(() => _isUploadingImage = true);

    try {
      // 🚀 SPEED OPTIMIZATION 1: Pre-warm GPS before opening camera
      Future<Position> locationFuture = Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 15));

      // 📸 OPEN CAMERA
      final imagePath = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DvrCameraScreen()),
      );

      // 🚀 SPEED OPTIMIZATION 2: Quiet Cancel
      if (imagePath == null) {
        setState(() => _isUploadingImage = false);
        return;
      }

      final File imageFile = File(imagePath);

      // 🚀 SPEED OPTIMIZATION 3: Parallel Execution
      // Upload image and await GPS concurrently
      final results = await Future.wait([
        locationFuture,
        _apiService.uploadImageToR2(imageFile),
      ]);

      setState(() {
        _checkInTime = DateTime.now();
        _checkInLocation = results[0] as Position; // Extract GPS
        _inTimeImageUrl = results[1] as String;    // Extract Image URL
        _isUploadingImage = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Check-In Error: $e"), backgroundColor: Colors.red),
      );
      setState(() => _isUploadingImage = false);
    }
  }

  /// ------------------------------------------------
  /// 🚀 SUBMIT DVR
  /// ------------------------------------------------
  Future<void> _submitDvr() async {
    if (_checkInTime == null || _checkInLocation == null) return;

    setState(() => _isSubmitting = true);

    try {
      final outImagePath = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DvrCameraScreen()),
      );

      String? outTimeUrl;

      if (outImagePath != null) {
        outTimeUrl = await _apiService.uploadImageToR2(File(outImagePath));
      }

      /// 🔥 DEALER MAPPING BASED ON TOGGLE
      String? finalDealerId;
      String? finalSubDealerId;

      if (_isSubDealerVisit) {
        finalSubDealerId = _selectedDealer?.id;
        finalDealerId = _selectedParentDealer?.id;
      } else {
        finalDealerId = _selectedDealer?.id;
      }

      final dvr = DailyVisitReport(
        userId: int.parse(widget.employee.id),
        reportDate: DateTime.now(),
        dealerId: finalDealerId,
        subDealerId: finalSubDealerId,
        dealerType: _dealerFormData['dealerType'] ?? 'Best',
        location: _selectedDealer?.address ?? "",
        latitude: _checkInLocation!.latitude,
        longitude: _checkInLocation!.longitude,
        visitType: _dealerFormData['visitType'] ?? 'PLANNED',
        dealerTotalPotential:
            double.tryParse("${_dealerFormData['dealerTotalPotential']}") ?? 0,
        dealerBestPotential:
            double.tryParse("${_dealerFormData['dealerBestPotential']}") ?? 0,
        brandSelling:
            (_dealerFormData['brandSelling'] as List<String>?) ?? [],
        contactPerson: _dealerFormData['contactPerson'],
        contactPersonPhoneNo: _dealerFormData['contactPersonPhoneNo'],
        todayOrderMt:
            double.tryParse("${_dealerFormData['todayOrderMt']}") ?? 0,
        todayCollectionRupees:
            double.tryParse("${_dealerFormData['todayCollectionRupees']}") ??
                0,
        feedbacks: "${_dealerFormData['feedbacks'] ?? ""}",
        solutionBySalesperson: _dealerFormData['solutionBySalesperson'],
        anyRemarks: _dealerFormData['anyRemarks'],
        checkInTime: _checkInTime!,
        checkOutTime: DateTime.now(),
        inTimeImageUrl: _inTimeImageUrl,
        outTimeImageUrl: outTimeUrl,
        pjpId: widget.pjp?.id,
      );

      await _apiService.createDvr(dvr);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("DVR Submitted Successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("DVR Error $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to submit DVR"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// ------------------------------------------------
  /// 🎨 UI
  /// ------------------------------------------------
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
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  /// HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Daily Visit Report",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _textDark,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: _textGrey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),

                  const Divider(height: 30),

                  /// STEP 1 — TOGGLE DEALER TYPE
                  if (_checkInTime == null) ...[
                    SwitchListTile(
                      value: _isSubDealerVisit,
                      activeColor: _cardNavy,
                      title: const Text("Sub Dealer Visit", style: TextStyle(fontWeight: FontWeight.w600)),
                      onChanged: (v) {
                        setState(() {
                          _isSubDealerVisit = v;
                          _selectedDealer = null;
                          _selectedParentDealer = null;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    /// DEALER SELECT
                    InkWell(
                      onTap: _openDealerSearch,
                      child: _buildSelector(
                        _selectedDealer?.name ??
                            (_isSubDealerVisit
                                ? "Select Sub Dealer"
                                : "Select Dealer"),
                      ),
                    ),

                    if (_isSubDealerVisit) ...[
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _openParentDealerSearch,
                        child: _buildSelector(
                          _selectedParentDealer?.name ??
                              "Select Parent Dealer",
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    ElevatedButton.icon(
                      onPressed: _isUploadingImage ? null : _handleCheckIn,
                      icon: _isUploadingImage 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.camera_alt),
                      label: Text(_isUploadingImage ? "CHECKING IN..." : "CHECK-IN WITH PHOTO"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _cardNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ]

                  /// STEP 2 — FORM
                  else ...[
                    DvrDealerFormWidget(
                      formKey: _dealerFormKey,
                      onDataChanged: (data) {
                        _dealerFormData = data;
                      },
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitDvr,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("SUBMIT & CHECK-OUT", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
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

  Widget _buildSelector(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: _inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: text.contains("Select") ? _textGrey : _textDark,
                fontWeight: text.contains("Select") ? FontWeight.normal : FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          const Icon(Icons.search, color: _textGrey),
        ],
      ),
    );
  }
}

/// ------------------------------------------------------------
/// 🔎 UPGRADED DEALER SEARCH DIALOG (ZONE DISPLAY)
/// ------------------------------------------------------------
class _ServerDealerSearchDialog extends StatefulWidget {
  final ApiService api;

  const _ServerDealerSearchDialog({required this.api});

  @override
  State<_ServerDealerSearchDialog> createState() => _ServerDealerSearchDialogState();
}

class _ServerDealerSearchDialogState extends State<_ServerDealerSearchDialog> {
  List<Dealer> _dealers = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _performSearch(""); 
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);

    try {
      final results = await widget.api.fetchDealers(search: query, limit: 20);
      if (mounted) {
        setState(() {
          _dealers = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("Select Dealer", style: TextStyle(fontWeight: FontWeight.w900)),
      contentPadding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 0),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(
          children: [
            // Styled Search Box
            TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: "Search by name or zone...",
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A)))
                  : _dealers.isEmpty
                      ? const Center(child: Text("No dealers found.", style: TextStyle(color: Colors.grey)))
                      : ListView.separated(
                          itemCount: _dealers.length,
                          separatorBuilder: (context, index) => Divider(color: Colors.grey.shade200, height: 1),
                          itemBuilder: (context, index) {
                            final dealer = _dealers[index];
                            
                            // 🚀 THE FIX: Safely map 'region' directly from the model without dynamic casting
                            final String displayZone = dealer.region.isNotEmpty 
                                ? dealer.region 
                                : "Unknown Zone";

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFEFF6FF), // Light blue
                                child: Icon(Icons.storefront, color: Colors.blueAccent, size: 20),
                              ),
                              title: Text(
                                dealer.name, 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF111827))
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.orange.shade200)
                                      ),
                                      child: Text(
                                        "Zone: $displayZone",
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        dealer.address ,
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () => Navigator.pop(context, dealer),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}