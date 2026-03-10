// lib/screens/create_dvr_screen.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 🔥 ADDED FOR HAPTICS
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart'; // 🔥 ADDED FOR PREMIUM ANIMATIONS

import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/models/daily_visit_report_model.dart';
import 'package:salesmanapp/models/dealer_model.dart';
import 'package:salesmanapp/models/employee_model.dart';
import 'package:salesmanapp/models/pjp_model.dart';
import 'package:salesmanapp/technicalSide/utils/dvrworker.dart'; // 🚀 IMPORTED BACKGROUND WORKER

import 'package:salesmanapp/screens/dvrwidgets/dvr_dealer_form.dart';
import 'package:salesmanapp/screens/dvrwidgets/dvr_nontrade_form.dart';
//import 'package:salesmanapp/screens/dvrwidgets/dvr_mis_form.dart'; //MIS form on hold
import 'package:salesmanapp/screens/dvrwidgets/dvr_camera.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;

class CreateDvrScreen extends StatefulWidget {
  final Employee employee;
  final Pjp? pjp;
  final Dealer? dealer;
  final DateTime? initialCheckInTime;

  /// 🔥 NEW: Callback to cleanly handle Dashboard routing
  final VoidCallback? onReturnToDashboard;

  const CreateDvrScreen({
    super.key,
    required this.employee,
    this.pjp,
    this.dealer,
    this.initialCheckInTime,
    this.onReturnToDashboard,
  });

  @override
  State<CreateDvrScreen> createState() => _CreateDvrScreenState();
}

// 🚀 ADDED WidgetsBindingObserver TO PREVENT CRASHES ON MINIMIZE
class _CreateDvrScreenState extends State<CreateDvrScreen>
    with WidgetsBindingObserver {
  // 🛡️ Tracks if app is minimized
  bool _isAppInForeground = true;

  final _formKey = GlobalKey<FormState>();
  final _dynamicFormKey = GlobalKey<FormState>();
  // 🚀 Added for UI Screenshot Sharing
  final GlobalKey _summaryCardKey = GlobalKey();

  // 🚀 Feature Toggle for Dealer Updates
  final bool _enableDealerUpdateOnSubmit = true;

  final ApiService _apiService = ApiService();

  Map<String, dynamic> _formData = {};

  bool _isSubmitting = false;
  bool _isUploadingImage = false;
  bool _showSummary = false;
  String? _outImagePathLocal;

  /// 🔥 FLOW CONTROL
  String? _selectedCustomerType;
  bool _isSubDealerVisit = false;

  Dealer? _selectedDealer;
  Dealer? _selectedParentDealer;

  DateTime? _checkInTime;
  String? _inTimeImageUrl;
  Position? _checkInLocation;

  /// 🎨 THEME
  static const Color _surfaceWhite = Colors.white;
  static const Color _textDark = Color(0xFF111827);
  static const Color _textGrey = Color(0xFF6B7280);
  static const Color _cardNavy = Color(0xFF0F172A);
  static const Color _inputFill = Color(0xFFF9FAFB);
  static const Color _accentGreen = Color(0xFF10B981);

  final List<String> _customerTypeOptions = [
    'Dealer',
    'NonTrade',
    // 'Ground MIS',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 🚀 START WATCHING LIFECYCLE
    if (widget.dealer != null) {
      _selectedDealer = widget.dealer;
      _selectedCustomerType = 'Dealer';
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 🚀 STOP WATCHING LIFECYCLE
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppInForeground = (state == AppLifecycleState.resumed);
  }

  /// ------------------------------------------------
  /// 🔎 DEALER SEARCH
  /// ------------------------------------------------
  Future<void> _openDealerSearch() async {
    HapticFeedback.selectionClick();
    final result = await showDialog<Dealer>(
      context: context,
      builder: (context) => _ServerDealerSearchDialog(api: _apiService),
    );

    if (result == null) return;
    if (result.id == null) {
      setState(() {
        _selectedDealer = result;
      });
      return;
    }

    try {
      final dealer = await _apiService.fetchDealerById(result.id!);

      if (!mounted) return;

      setState(() {
        _selectedDealer = dealer;
      });
    } catch (e) {
      debugPrint("Dealer fetch failed: $e");

      setState(() {
        _selectedDealer = result;
      });
    }
  }

  Future<void> _openParentDealerSearch() async {
    HapticFeedback.selectionClick();
    final result = await showDialog<Dealer>(
      context: context,
      builder: (context) => _ServerDealerSearchDialog(api: _apiService),
    );

    if (result != null) {
      setState(() => _selectedParentDealer = result);
    }
  }

  /// ------------------------------------------------
  /// 📸 INLINE CAMERA CHECK-IN (Null-Safe Optimized)
  /// ------------------------------------------------
  Future<void> _handleCheckIn() async {
    if (_selectedCustomerType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please select a Customer Type first",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
      return;
    }

    if (_selectedCustomerType == 'Dealer' && _selectedDealer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Select dealer first",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isUploadingImage = true);

    try {
      // 🚀 THE FIX: Smart wrapper to handle Dart's strict null-safety and timeout exceptions gracefully
      Future<Position?> fetchLocationSmartly() async {
        try {
          return await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          ).timeout(const Duration(seconds: 10));
        } on TimeoutException {
          debugPrint("GPS Timeout! Falling back to last known position...");
          return await Geolocator.getLastKnownPosition();
        }
      }

      // Pre-warm the smart GPS fetcher
      Future<Position?> locationFuture = fetchLocationSmartly();

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

      // 🚀 SPEED OPTIMIZATION 3: O(max(T)) Parallel Execution
      final results = await Future.wait([
        locationFuture,
        _apiService.uploadImageToR2(imageFile),
      ]);

      // Extract and check for nulls safely
      final Position? pos = results[0] as Position?;
      if (pos == null) {
        throw Exception(
          "Could not lock GPS location. Ensure location services are ON.",
        );
      }

      // 🛡️ PROTECTED UI UPDATE
      if (mounted && _isAppInForeground) {
        setState(() {
          _checkInTime = DateTime.now();
          _checkInLocation = pos;
          _inTimeImageUrl = results[1] as String;
          _isUploadingImage = false;
        });
      }
    } catch (e) {
      // 🛡️ PROTECTED ERROR HANDLING
      if (mounted && _isAppInForeground) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Check-In Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Map<String, dynamic> _buildDealerPatch(Position location) {
    if (_selectedDealer == null) return {};

    final patch = <String, dynamic>{};

    final totalPotential = double.tryParse(
      "${_formData['dealerTotalPotential']}",
    );

    if (totalPotential != null &&
        totalPotential != _selectedDealer!.totalPotential) {
      patch['totalPotential'] = totalPotential;
    }

    final bestPotential = double.tryParse(
      "${_formData['dealerBestPotential']}",
    );

    if (bestPotential != null &&
        bestPotential != _selectedDealer!.bestPotential) {
      patch['bestPotential'] = bestPotential;
    }

    final phone = _formData['contactPersonPhoneNo'];

    if (phone != null && phone != _selectedDealer!.phoneNo) {
      patch['phoneNo'] = phone;
    }

    if (_formData['brandSelling'] != null &&
        _formData['brandSelling'] != _selectedDealer!.brandSelling) {
      patch['brandSelling'] = _formData['brandSelling'];
    }

    if (_selectedDealer!.latitude != location.latitude) {
      patch['latitude'] = location.latitude;
    }

    if (_selectedDealer!.longitude != location.longitude) {
      patch['longitude'] = location.longitude;
    }

    return patch;
  }

  /// ------------------------------------------------
  /// 🚀 SUBMIT DVR (O(1) BACKGROUND WORKER)
  /// ------------------------------------------------
  Future<void> _submitDvr() async {
    if (_checkInTime == null || _checkInLocation == null) return;

    if (!_dynamicFormKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please fill all required fields",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    HapticFeedback.heavyImpact();
    setState(() => _isSubmitting = true);

    try {
      final outImagePath = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DvrCameraScreen()),
      );

      if (outImagePath == null) {
        setState(() => _isSubmitting = false);
        return;
      }

      _outImagePathLocal = outImagePath;

      /// DEALER MAPPING BASED ON TOGGLE
      String? finalDealerId;
      String? finalSubDealerId;
      String locationAddress = "Location fetched via GPS";

      if (_selectedCustomerType == 'Dealer') {
        if (_isSubDealerVisit) {
          finalSubDealerId = _selectedDealer?.id;
          finalDealerId = _selectedParentDealer?.id;
        } else {
          finalDealerId = _selectedDealer?.id;
        }
        locationAddress = _selectedDealer?.address ?? "Unknown";
      }

      final dvr = DailyVisitReport(
        userId: int.parse(widget.employee.id),
        reportDate: DateTime.now(),
        dealerId: finalDealerId,
        subDealerId: finalSubDealerId,
        customerType: _selectedCustomerType,
        dealerType: _formData['dealerType'] ?? 'Unknown',
        partyType: _formData['partyType'],
        nameOfParty: _formData['nameOfParty'],
        contactNoOfParty: _formData['contactNoOfParty'],
        expectedActivationDate: _formData['expectedActivationDate'],
        location: locationAddress,
        latitude: _checkInLocation!.latitude,
        longitude: _checkInLocation!.longitude,
        visitType: _formData['visitType'] ?? 'PLANNED',
        dealerTotalPotential:
            double.tryParse("${_formData['dealerTotalPotential']}") ?? 0,
        dealerBestPotential:
            double.tryParse("${_formData['dealerBestPotential']}") ?? 0,
        brandSelling: (_formData['brandSelling'] as List<String>?) ?? [],
        contactPerson: _formData['contactPerson'],
        contactPersonPhoneNo: _formData['contactPersonPhoneNo'],
        todayOrderMt: double.tryParse("${_formData['todayOrderMt']}") ?? 0,
        todayCollectionRupees:
            double.tryParse("${_formData['todayCollectionRupees']}") ?? 0,
        feedbacks: "${_formData['feedbacks'] ?? ""}",
        solutionBySalesperson: _formData['solutionBySalesperson'],
        anyRemarks: _formData['anyRemarks'],
        checkInTime: _checkInTime!,
        checkOutTime: DateTime.now(),
        inTimeImageUrl: _inTimeImageUrl,
        outTimeImageUrl:
            null, // 🚀 LEFT NULL! The background worker handles the upload.
        pjpId: widget.pjp?.id,
      );

      // 🚀 FIRE AND FORGET THE DEALER GPS UPDATE (Non-blocking)
      if (_enableDealerUpdateOnSubmit && finalDealerId != null) {
        final patch = _buildDealerPatch(_checkInLocation!);

        if (patch.isNotEmpty) {
          _apiService.updateDealer(finalDealerId, patch);
        }
      }

      // ⚡ O(1) TIME COMPLEXITY: Hand off to the Background Worker instantly!
      await DvrBackgroundWorker.processAndSubmit(
        apiService: _apiService,
        dvrPayload: dvr,
        inTimeFile: null, // Already uploaded during check-in
        outTimeFile: File(outImagePath),
        evidenceFiles: [],
        clearDrafts: true,
      );

      // 🛡️ PROTECTED UI UPDATE: Instantly show success without waiting for uploads!
      if (mounted && _isAppInForeground) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "DVR Queued & Submitted!",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _showSummary = true;
          _isSubmitting = false;
        });
      }
    } catch (e) {
      debugPrint("DVR Error $e");
      if (mounted && _isAppInForeground) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Failed to queue DVR",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// ------------------------------------------------
  /// 🎨 MAIN BUILD METHOD
  /// ------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Daily Visit Report",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
        ),
        backgroundColor: _cardNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: _showSummary
            ? const SizedBox.shrink()
            : const BackButton(color: Colors.white),
      ),
      // 🚀 GPU-ACCELERATED VIEW SWITCHING
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _showSummary
            ? _buildSummaryView(key: const ValueKey('summary'))
            : _buildFormView(key: const ValueKey('form')),
      ),
    );
  }

  /// ------------------------------------------------
  /// 📝 THE FORM VIEW
  /// ------------------------------------------------
  Widget _buildFormView({Key? key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// STEP 1 — CHECK IN CARD
            if (_checkInTime == null) ...[
              Card(
                    elevation: 4,
                    shadowColor: Colors.black.withOpacity(0.1),
                    color: _surfaceWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Select Visit Type *",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _textDark,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _inputFill,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCustomerType,
                                isExpanded: true,
                                hint: const Text(
                                  "Select Customer Type",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _textGrey,
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.expand_more_rounded,
                                  color: _textGrey,
                                ),
                                items: _customerTypeOptions
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(
                                          e,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _selectedCustomerType = v;
                                    _selectedDealer = null;
                                    _selectedParentDealer = null;
                                    _isSubDealerVisit = false;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          if (_selectedCustomerType == 'Dealer') ...[
                            SwitchListTile(
                                  value: _isSubDealerVisit,
                                  activeColor: _cardNavy,
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text(
                                    "Sub Dealer Visit",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: _textDark,
                                    ),
                                  ),
                                  onChanged: (v) {
                                    HapticFeedback.lightImpact();
                                    setState(() {
                                      _isSubDealerVisit = v;
                                      _selectedDealer = null;
                                      _selectedParentDealer = null;
                                    });
                                  },
                                )
                                .animate()
                                .fadeIn(duration: 300.ms)
                                .slideX(begin: 0.05),
                            const SizedBox(height: 16),

                            InkWell(
                                  onTap: _openDealerSearch,
                                  borderRadius: BorderRadius.circular(12),
                                  child: _buildSelector(
                                    _selectedDealer?.name ??
                                        (_isSubDealerVisit
                                            ? "Select Sub Dealer"
                                            : "Select Dealer"),
                                  ),
                                )
                                .animate()
                                .fadeIn(delay: 50.ms, duration: 300.ms)
                                .slideX(begin: 0.05),

                            if (_isSubDealerVisit) ...[
                              const SizedBox(height: 16),
                              InkWell(
                                    onTap: _openParentDealerSearch,
                                    borderRadius: BorderRadius.circular(12),
                                    child: _buildSelector(
                                      _selectedParentDealer?.name ??
                                          "Select Parent Dealer",
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(delay: 100.ms, duration: 300.ms)
                                  .slideX(begin: 0.05),
                            ],
                            const SizedBox(height: 24),
                          ],

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isUploadingImage
                                  ? null
                                  : _handleCheckIn,
                              icon: _isUploadingImage
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : const Icon(Icons.camera_alt_rounded),
                              label: Text(
                                _isUploadingImage
                                    ? "CHECKING IN..."
                                    : "CHECK-IN WITH PHOTO",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _cardNavy,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 8,
                                shadowColor: _cardNavy.withOpacity(0.4),
                              ),
                            ),
                          ).animate().scale(
                            delay: 200.ms,
                            curve: Curves.easeOutBack,
                          ),
                        ],
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.1, curve: Curves.easeOutCubic),
            ]
            /// STEP 2 — FORM DETAILS
            else ...[
              _buildVisitSummary()
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: -0.1),
              const SizedBox(height: 20),

              // 🚀 O(1) HARDWARE ACCELERATED FORM SWAPPING
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: Container(
                  key: ValueKey(_selectedCustomerType ?? 'none'),
                  decoration: BoxDecoration(
                    color: _surfaceWhite,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: _buildDynamicFormSwitcher(),
                ),
              ),

              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitDvr,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentGreen,
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shadowColor: _accentGreen.withOpacity(0.4),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        "SUBMIT & CHECK-OUT",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1.1,
                        ),
                      ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicFormSwitcher() {
    if (_selectedCustomerType == 'NonTrade') {
      return DvrNonTradeFormWidget(
        formKey: _dynamicFormKey,
        onDataChanged: (data) => _formData = data,
      );
    }
    return DvrDealerFormWidget(
      key: ValueKey(_selectedDealer?.id),
      formKey: _dynamicFormKey,
      onDataChanged: (data) => _formData = data,
      initialDealer: _selectedDealer,
    );
  }

  Widget _buildVisitSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _accentGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentGreen.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: _accentGreen.withOpacity(0.2), blurRadius: 8),
              ],
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: _accentGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Checked In",
                  style: TextStyle(
                    color: _cardNavy,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "$_selectedCustomerType Visit Active",
                  style: TextStyle(
                    color: _cardNavy.withOpacity(0.6),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelector(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: _inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: text.contains("Select") ? _textGrey : _textDark,
                fontWeight: text.contains("Select")
                    ? FontWeight.normal
                    : FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
          const Icon(Icons.search_rounded, color: _textGrey),
        ],
      ),
    );
  }

  /// ------------------------------------------------
  /// 🎉 THE SUMMARY & WHATSAPP VIEW
  /// ------------------------------------------------
  Widget _buildSummaryView({Key? key}) {
    return Center(
      key: key,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: RepaintBoundary(
          key: _summaryCardKey,
          child: Card(
            elevation: 8,
            shadowColor: Colors.black.withOpacity(0.1),
            color: _surfaceWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: _accentGreen,
                    size: 80,
                  ).animate().scale(
                    curve: Curves.easeOutBack,
                    duration: 600.ms,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                        "Visit Completed!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: _cardNavy,
                          letterSpacing: -0.5,
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 200.ms)
                      .slideY(begin: 0.2, curve: Curves.easeOut),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(height: 1),
                  ),

                  _buildSummaryRow(
                    "Type",
                    _selectedCustomerType ?? "N/A",
                  ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.05),
                  _buildSummaryRow(
                    "Dealer/Party",
                    _selectedCustomerType == 'Dealer'
                        ? (_selectedDealer?.name ?? "N/A")
                        : (_formData['nameOfParty'] ?? "N/A"),
                  ).animate().fadeIn(delay: 350.ms).slideX(begin: -0.05),
                  if (_selectedCustomerType == 'Dealer') ...[
                    _buildSummaryRow(
                      "Order Given",
                      "${_formData['todayOrderMt'] ?? 0} MT",
                    ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.05),
                    _buildSummaryRow(
                      "Collection",
                      "₹${_formData['todayCollectionRupees'] ?? 0}",
                    ).animate().fadeIn(delay: 450.ms).slideX(begin: -0.05),
                  ],

                  const SizedBox(height: 32),
                  const Text(
                    "Photos Captured",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: _textDark,
                      fontSize: 16,
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildImageTile("Check-In", _inTimeImageUrl)
                            .animate()
                            .scale(delay: 550.ms, curve: Curves.easeOutBack),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child:
                            _buildImageTile(
                              "Check-Out",
                              _outImagePathLocal,
                              isLocal: true,
                            ).animate().scale(
                              delay: 600.ms,
                              curve: Curves.easeOutBack,
                            ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                        onPressed: _shareToWhatsApp,
                        icon: const Icon(
                          Icons.share_rounded,
                          color: Colors.white,
                        ),
                        label: const Text(
                          "SHARE TO WHATSAPP",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 700.ms)
                      .scaleXY(begin: 0.9)
                      .then()
                      .shimmer(duration: 2500.ms, color: Colors.white24)
                      .animate(onPlay: (c) => c.repeat()),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      if (widget.onReturnToDashboard != null) {
                        widget.onReturnToDashboard!();
                      }
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      "RETURN TO DASHBOARD",
                      style: TextStyle(
                        color: _textGrey,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ).animate().fadeIn(delay: 800.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: _textGrey,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: _textDark,
                fontSize: 15,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageTile(
    String label,
    String? pathOrUrl, {
    bool isLocal = false,
  }) {
    if (pathOrUrl == null) return const SizedBox.shrink();
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: isLocal
                ? Image.file(
                    File(pathOrUrl),
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Image.network(
                    pathOrUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _surfaceWhite,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: _cardNavy,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _shareToWhatsApp() async {
    HapticFeedback.heavyImpact();

    final isDealer = _selectedCustomerType == 'Dealer';
    final name = isDealer
        ? (_selectedDealer?.name ?? 'N/A')
        : (_formData['nameOfParty'] ?? 'N/A');
    final type = _formData['visitType'] ?? 'N/A';

    String text = '*DVR Summary Report* 📊\n';
    text += '*Type:* $_selectedCustomerType Visit\n';
    text += '*Name:* $name\n';
    text += '*Visit Objective:* $type\n';
    if (isDealer) {
      text += '*Order:* ${_formData['todayOrderMt'] ?? '0'} MT\n';
      text += '*Collection:* ₹${_formData['todayCollectionRupees'] ?? '0'}\n';
    }
    text +=
        '*Feedback:* ${_formData['feedbacks'] ?? 'None'}\n\n_Generated via Sales App_';

    try {
      // 🚀 GPU-LEVEL SCREENSHOT: Grab the pixels directly from the RepaintBoundary
      RenderRepaintBoundary boundary =
          _summaryCardKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(
        pixelRatio: 3.0,
      ); // 3.0 makes it super crisp and HD
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      // 💾 O(1) SPACE: Save to OS Temp Directory (Auto-deletes later)
      final directory = await getTemporaryDirectory();
      final imagePath =
          '${directory.path}/dvr_summary_${DateTime.now().millisecondsSinceEpoch}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(pngBytes);

      // 🛡️ PROTECT SHARE INVOCATION
      if (mounted && _isAppInForeground) {
        await Share.shareXFiles([XFile(imagePath)], text: text);
      }
    } catch (e) {
      debugPrint("Share error: $e");
      if (mounted && _isAppInForeground) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to capture and share summary.")),
        );
      }
    }
  }
}

/// ------------------------------------------------------------
/// 🔎 DEALER SEARCH DIALOG (Memory Leak Fixed)
/// ------------------------------------------------------------
class _ServerDealerSearchDialog extends StatefulWidget {
  final ApiService api;
  const _ServerDealerSearchDialog({required this.api});
  @override
  State<_ServerDealerSearchDialog> createState() =>
      _ServerDealerSearchDialogState();
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

  // 🚀 CRITICAL FIX: Prevent Memory Leaks
  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _performSearch(query),
    );
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        "Select Dealer",
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: Color(0xFF0F172A),
          fontSize: 20,
          letterSpacing: -0.5,
        ),
      ),
      contentPadding: const EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: 0,
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(
          children: [
            TextField(
              onChanged: _onSearchChanged,
              style: const TextStyle(fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: "Search by name or zone...",
                hintStyle: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Colors.grey,
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0F172A),
                      ),
                    )
                  : _dealers.isEmpty
                  ? const Center(
                      child: Text(
                        "No dealers found.",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _dealers.length,
                      separatorBuilder: (context, index) =>
                          Divider(color: Colors.grey.shade200, height: 1),
                      itemBuilder: (context, index) {
                        final dealer = _dealers[index];

                        // 🚀 MEMORY OPTIMIZED: Replaced the multiple string allocations
                        // from your second snippet with a single, O(1) ternary resolution.
                        // This prevents unnecessary garbage collection spikes while scrolling.
                        final zoneArea = dealer.area.isNotEmpty
                            ? "${dealer.region}, ${dealer.area}"
                            : dealer.region.isNotEmpty
                            ? dealer.region
                            : "Unknown Zone";

                        return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 0,
                              ),
                              // Kept your original premium Container UI look instead of the basic CircleAvatar
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.storefront_rounded,
                                  color: Colors.blueAccent,
                                  size: 22,
                                ),
                              ),
                              title: Text(
                                dealer.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      zoneArea,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF374151),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dealer.address,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6B7280),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () => Navigator.pop(context, dealer),
                            )
                            // 🚀 ANIMATION PRESERVED: Staggered entry animation kept intact
                            .animate()
                            .fadeIn(delay: (index * 30).ms)
                            .slideX(begin: -0.05);
                      },
                    ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.all(16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            "CANCEL",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ).animate().scale(curve: Curves.easeOutBack, duration: 400.ms);
  }
}
