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
  File? _inTimeImageFile;
  String? _inTimeImageUrl;
  Position? _checkInLocation;

  /// 🎨 FINTECH THEME
  static const Color _surfaceWhite = Colors.white;
  static const Color _textDark = Color(0xFF111827);
  static const Color _textGrey = Color(0xFF6B7280);
  static const Color _cardNavy = Color(0xFF0F172A);
  static const Color _inputFill = Color(0xFFF9FAFB);
  static const Color _accentGreen = Color(0xFF10B981);

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
  /// 📸 INLINE CAMERA CHECK-IN
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
      final imagePath = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DvrCameraScreen()),
      );

      if (imagePath == null) {
        setState(() => _isUploadingImage = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final file = File(imagePath);
      final url = await _apiService.uploadImageToR2(file);

      setState(() {
        _checkInTime = DateTime.now();
        _checkInLocation = position;
        _inTimeImageFile = file;
        _inTimeImageUrl = url;
        _isUploadingImage = false;
      });
    } catch (_) {
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
                      title: const Text("Sub Dealer Visit"),
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
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("CHECK-IN WITH PHOTO"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _cardNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("SUBMIT & CHECK-OUT"),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: _inputFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: text.contains("Select") ? _textGrey : _textDark,
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
/// 🔎 DEALER SEARCH DIALOG
/// ------------------------------------------------------------
class _ServerDealerSearchDialog extends StatefulWidget {
  final ApiService api;

  const _ServerDealerSearchDialog({required this.api});

  @override
  State<_ServerDealerSearchDialog> createState() =>
      _ServerDealerSearchDialogState();
}

class _ServerDealerSearchDialogState
    extends State<_ServerDealerSearchDialog> {
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

    final results =
        await widget.api.fetchDealers(search: query, limit: 20);

    if (mounted) {
      setState(() {
        _dealers = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Select Dealer"),
      content: SizedBox(
        width: double.maxFinite,
        height: 420,
        child: Column(
          children: [
            TextField(onChanged: _onSearchChanged),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _dealers.length,
                      itemBuilder: (context, index) {
                        final dealer = _dealers[index];
                        return ListTile(
                          title: Text(dealer.name),
                          onTap: () => Navigator.pop(context, dealer),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
