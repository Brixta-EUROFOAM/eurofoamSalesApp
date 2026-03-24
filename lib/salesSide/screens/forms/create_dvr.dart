// lib/screens/create_dvr_screen.dart

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
// import 'dart:isolate';
// import 'dart:developer' as dev;
// import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:salesmanapp/services/dvrTimerFgTaskHandler/dvr_timer_foreground_service.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/database/app_database.dart';
import 'package:salesmanapp/salesSide/models/daily_visit_report_model.dart';
import 'package:salesmanapp/salesSide/models/dealer_model.dart';
import 'package:salesmanapp/salesSide/models/employee_model.dart';
import 'package:salesmanapp/salesSide/models/pjp_model.dart';
import 'package:salesmanapp/salesSide/screens/dvrwidgets/dvrworker.dart';

import 'package:salesmanapp/salesSide/screens/dvrwidgets/dvr_dealer_form.dart';
import 'package:salesmanapp/salesSide/screens/dvrwidgets/dvr_nontrade_form.dart';
import 'package:salesmanapp/salesSide/screens/dvrwidgets/dvr_camera.dart';
import 'package:salesmanapp/widgets/reusable_functions.dart';

/// 🚀 THE BACKGROUND ISOLATE WORKER (100% Main-Thread Safe)
/// Placed outside the class so the Isolate can access it without closure context bloat.
// Future<List<Dealer>> _parseDealersInBackground(
//   List<Map<String, dynamic>> rawData,
// ) async {
//   return await Isolate.run(() {
//     List<Dealer> parsedDealers = [];
//     for (var d in rawData) {
//       try {
//         // Create a strict copy to PREVENT ConcurrentModificationError
//         Map<String, dynamic> safeMap = Map<String, dynamic>.from(d);

//         d.forEach((key, value) {
//           if (value is int &&
//               (key.toLowerCase().contains('date') ||
//                   key.toLowerCase().contains('time') ||
//                   key == 'createdAt' ||
//                   key == 'updatedAt')) {
//             safeMap[key] = DateTime.fromMillisecondsSinceEpoch(
//               value * 1000,
//             ).toIso8601String();
//           }
//         });

//         if (safeMap['brandSelling'] != null &&
//             safeMap['brandSelling'] is String) {
//           try {
//             safeMap['brandSelling'] = jsonDecode(safeMap['brandSelling']);
//           } catch (_) {
//             safeMap['brandSelling'] = [];
//           }
//         }

//         safeMap['id'] = safeMap['id']?.toString();
//         safeMap['phoneNo'] = safeMap['phoneNo']?.toString();
//         safeMap['type'] = safeMap['type']?.toString() ?? 'Dealer';

//         parsedDealers.add(Dealer.fromJson(safeMap));
//       } catch (e) {
//         // Fails silently for one bad apple, saves the rest of the list
//         dev.log("Isolate parsing skipped a corrupted row: $e");
//       }
//     }
//     return parsedDealers;
//   });
// }

class CreateDvrScreen extends StatefulWidget {
  final Employee employee;
  final Pjp? pjp;
  final Dealer? dealer;
  final DateTime? initialCheckInTime;
  final String? dailyTaskId;
  final VoidCallback? onReturnToDashboard;

  const CreateDvrScreen({
    super.key,
    required this.employee,
    this.pjp,
    this.dailyTaskId,
    this.dealer,
    this.initialCheckInTime,
    this.onReturnToDashboard,
  });

  @override
  State<CreateDvrScreen> createState() => _CreateDvrScreenState();
}

class _CreateDvrScreenState extends State<CreateDvrScreen>
    with WidgetsBindingObserver {
  bool _isAppInForeground = true;

  final _formKey = GlobalKey<FormState>();
  final _dynamicFormKey = GlobalKey<FormState>();
  final GlobalKey _summaryCardKey = GlobalKey();

  final bool _enableDealerUpdateOnSubmit = true;
  String _elapsedTime = "00:00:00";

  final ApiService _apiService = ApiService();
  Map<String, dynamic> _formData = {};

  bool _isSubmitting = false;
  bool _isUploadingImage = false;
  bool _showSummary = false;
  String? _outImagePathLocal;

  String? _selectedCustomerType;
  bool _isSubDealerVisit = false;

  Dealer? _selectedDealer;
  Dealer? _selectedParentDealer;

  DateTime? _checkInTime;
  String? _inImagePathLocal;
  Position? _checkInLocation;

  static const Color _surfaceWhite = Colors.white;
  static const Color _textDark = Color(0xFF111827);
  static const Color _textGrey = Color(0xFF6B7280);
  static const Color _cardNavy = Color(0xFF0F172A);
  static const Color _inputFill = Color(0xFFF9FAFB);
  static const Color _accentGreen = Color(0xFF10B981);

  final List<String> _customerTypeOptions = const ['Dealer', 'NonTrade'];

  // 🚀 REPLACED TICKER WITH EFFICIENT TIMER
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.dealer != null) {
      _selectedDealer = widget.dealer;
      _selectedCustomerType = 'Dealer';
    }

    if (widget.initialCheckInTime != null) {
      _checkInTime = widget.initialCheckInTime;
      _startEfficientClock();
    }
  }

  // 🚀 EFFICIENT CLOCK: Runs 1 time per second instead of 60 times a second
  void _startEfficientClock() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateLiveTimer(),
    );
  }

  void _updateLiveTimer() {
    if (_checkInTime == null || !_isAppInForeground) return;

    final elapsed = DateTime.now().difference(_checkInTime!);

    // Optimized string allocation
    final h = elapsed.inHours.toString().padLeft(2, '0');
    final m = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');

    final newTime = "$h:$m:$s";

    if (_elapsedTime != newTime && mounted) {
      setState(() => _elapsedTime = newTime);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer?.cancel(); // Kill the timer
    DvrTimerForegroundService.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppInForeground = (state == AppLifecycleState.resumed);
    // Timer naturally pauses logic when !_isAppInForeground via the return statement above
  }

  Future<void> _openDealerSearch() async {
    HapticFeedback.selectionClick();

    final result = await openDealerSearch(
      context,
      lat: _checkInLocation?.latitude,
      lng: _checkInLocation?.longitude,
    );

    if (result != null && mounted) {
      setState(() => _selectedDealer = result);
    }
  }

  Future<void> _openParentDealerSearch() async {
    HapticFeedback.selectionClick();

    final result = await openDealerSearch(
      context,
      lat: _checkInLocation?.latitude,
      lng: _checkInLocation?.longitude,
    );

    if (result != null && mounted) {
      setState(() => _selectedParentDealer = result);
    }
  }

  Future<void> _handleCheckIn() async {
    if (_selectedCustomerType == null ||
        (_selectedCustomerType == 'Dealer' && _selectedDealer == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please make necessary selections first",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isUploadingImage = true);

    try {
      final imagePath = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DvrCameraScreen()),
      );
      if (imagePath == null) {
        setState(() => _isUploadingImage = false);
        return;
      }

      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 10));
      } on TimeoutException {
        pos = await Geolocator.getLastKnownPosition();
      }

      if (pos == null) throw Exception("Could not lock GPS location.");

      if (mounted) {
        setState(() {
          _checkInTime = DateTime.now();
          _checkInLocation = pos;
          _inImagePathLocal = imagePath;
          _isUploadingImage = false;
        });

        _startEfficientClock(); // Start battery-friendly clock

        final displayName = _selectedCustomerType == 'Dealer'
            ? (_selectedDealer?.name ?? "Dealer")
            : "Non-Trade Visit";
        final uniqueSessionId = _selectedCustomerType == 'Dealer'
            ? (_selectedDealer?.id ?? "unknown")
            : "nontrade_${_checkInTime!.millisecondsSinceEpoch}";

        DvrTimerForegroundService.start(
          dvrSessionId: uniqueSessionId,
          title: "Visiting: $displayName",
          subtitle: "Duration: 00:00:00",
          checkInTimestampMs: _checkInTime!.millisecondsSinceEpoch,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Map<String, dynamic> _buildDealerPatch(Position location) {
    if (_selectedDealer == null) return {};
    final patch = <String, dynamic>{};

    final tp = double.tryParse("${_formData['dealerTotalPotential']}");
    if (tp != null && tp != _selectedDealer!.totalPotential) {
      patch['totalPotential'] = tp;
    }

    final bp = double.tryParse("${_formData['dealerBestPotential']}");
    if (bp != null && bp != _selectedDealer!.bestPotential) {
      patch['bestPotential'] = bp;
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

  Future<void> _submitDvr() async {
    if (_checkInTime == null || _checkInLocation == null) return;
    if (!_dynamicFormKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all required fields"),
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

      String? finalDealerId;
      String? finalSubDealerId;
      String locationAddress = "Location fetched via GPS";

      if (_selectedCustomerType == 'Dealer') {
        finalSubDealerId = _isSubDealerVisit ? _selectedDealer?.id : null;
        finalDealerId = _isSubDealerVisit
            ? _selectedParentDealer?.id
            : _selectedDealer?.id;
        locationAddress = _selectedDealer?.address ?? "Unknown";
      }

      final dvr = DailyVisitReport(
        idempotencyKey: const Uuid().v4(),
        dailyTaskId: widget.dailyTaskId,
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
        pjpId: widget.pjp?.id,
      );

      if (_enableDealerUpdateOnSubmit && finalDealerId != null) {
        final patch = _buildDealerPatch(_checkInLocation!);
        if (patch.isNotEmpty) {
          AppDatabase.instance.enqueueOfflineTask(
            entityType: 'DEALER_PATCH',
            payload: {'dealerId': finalDealerId, 'patch': patch},
          );
        }
      }

      DvrBackgroundWorker.processAndSubmit(
        apiService: _apiService,
        dvrPayload: dvr,
        inTimeFile: _inImagePathLocal != null ? File(_inImagePathLocal!) : null,
        outTimeFile: File(outImagePath),
        evidenceFiles: [],
        clearDrafts: true,
      );

      try {
        final jsonPayload = dvr.toJson();
        jsonPayload['reportDate'] = dvr.reportDate.toIso8601String();
        jsonPayload['checkInTime'] = dvr.checkInTime.toIso8601String();
        jsonPayload['checkOutTime'] = dvr.checkOutTime?.toIso8601String();
        jsonPayload['expectedActivationDate'] = dvr.expectedActivationDate
            ?.toIso8601String();
        jsonPayload['brandSelling'] = dvr.brandSelling;
        jsonPayload['inTimeImageUrl'] = _inImagePathLocal;
        jsonPayload['outTimeImageUrl'] = _outImagePathLocal;
        await AppDatabase.instance.createLocalDvr(jsonPayload);
      } catch (_) {}

      if (mounted) {
        _clockTimer?.cancel();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Saved Offline & Uploading..."),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _showSummary = true;
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to queue DVR"),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _showSummary
            ? _buildSummaryView(key: const ValueKey('summary'))
            : _buildFormView(key: const ValueKey('form')),
      ),
    );
  }

  Widget _buildFormView({Key? key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_checkInTime == null) ...[
              Card(
                elevation: 4,
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
                        ),
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
                        ),
                        if (_isSubDealerVisit) ...[
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: _openParentDealerSearch,
                            borderRadius: BorderRadius.circular(12),
                            child: _buildSelector(
                              _selectedParentDealer?.name ??
                                  "Select Parent Dealer",
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isUploadingImage ? null : _handleCheckIn,
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
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _cardNavy,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
            ] else ...[
              _buildVisitSummary().animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 20),
              Container(
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
                child: _selectedCustomerType == 'NonTrade'
                    ? DvrNonTradeFormWidget(
                        formKey: _dynamicFormKey,
                        onDataChanged: (data) => _formData = data,
                      )
                    : DvrDealerFormWidget(
                        key: ValueKey(_selectedDealer?.id),
                        formKey: _dynamicFormKey,
                        onDataChanged: (data) => _formData = data,
                        initialDealer: _selectedDealer,
                      ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitDvr,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentGreen,
                  foregroundColor: Colors.white,
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
              ),
              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
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
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _cardNavy,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  _elapsedTime,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFeatures: [ui.FontFeature.tabularFigures()],
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

  Widget _buildSummaryView({Key? key}) {
    return Center(
      key: key,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: RepaintBoundary(
          key: _summaryCardKey,
          child: Card(
            elevation: 8,
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
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(height: 1),
                  ),
                  _buildSummaryRow("Type", _selectedCustomerType ?? "N/A"),
                  _buildSummaryRow(
                    "Dealer/Party",
                    _selectedCustomerType == 'Dealer'
                        ? (_selectedDealer?.name ?? "N/A")
                        : (_formData['nameOfParty'] ?? "N/A"),
                  ),
                  if (_selectedCustomerType == 'Dealer') ...[
                    _buildSummaryRow(
                      "Order Given",
                      "${_formData['todayOrderMt'] ?? 0} MT",
                    ),
                    _buildSummaryRow(
                      "Collection",
                      "₹${_formData['todayCollectionRupees'] ?? 0}",
                    ),
                  ],
                  const SizedBox(height: 32),
                  const Text(
                    "Photos Captured",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: _textDark,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildImageTile(
                          "Check-In",
                          _inImagePathLocal,
                          isLocal: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildImageTile(
                          "Check-Out",
                          _outImagePathLocal,
                          isLocal: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: _shareToWhatsApp,
                    icon: const Icon(Icons.share_rounded, color: Colors.white),
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
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onReturnToDashboard?.call();
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
                  ),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
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
        ClipRRect(
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

    String text =
        '*DVR Summary Report* 📊\n*Type:* $_selectedCustomerType Visit\n*Name:* $name\n*Visit Objective:* $type\n';
    if (isDealer){
      text +=
          '*Order:* ${_formData['todayOrderMt'] ?? '0'} MT\n*Collection:* ₹${_formData['todayCollectionRupees'] ?? '0'}\n';
    text +=
        '*Feedback:* ${_formData['feedbacks'] ?? 'None'}\n\n_Generated via Sales App_';
    }
    try {
      RenderRepaintBoundary boundary =
          _summaryCardKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final imagePath =
          '${directory.path}/dvr_summary_${DateTime.now().millisecondsSinceEpoch}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(pngBytes);

      if (mounted) await Share.shareXFiles([XFile(imagePath)], text: text);
    } catch (e) {
      if (mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to capture and share summary.")),
        );
      }}
  }
}
