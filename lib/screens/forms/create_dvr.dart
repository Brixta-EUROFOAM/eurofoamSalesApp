// lib/screens/forms/create_dvr.dart
import 'dart:io';
import 'dart:ui';
import 'dart:developer' as dev;

import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:assetarchiverflutter/models/daily_visit_report_model.dart';
import 'package:assetarchiverflutter/models/dealer_model.dart';
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _log = 'CreateDvrScreen';
const _calibratedDealersKey = 'calibrated_dealers';

class CreateDvrScreen extends StatefulWidget {
  final Employee employee;
  const CreateDvrScreen({super.key, required this.employee});

  @override
  State<CreateDvrScreen> createState() => _CreateDvrScreenState();
}

class _CreateDvrScreenState extends State<CreateDvrScreen> {
  // Keys & Services
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _imagePicker = ImagePicker();

  // Form Controllers
  final _dealerTotalPotentialController = TextEditingController();
  final _dealerBestPotentialController = TextEditingController();
  final _brandSellingController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _contactPersonPhoneNoController = TextEditingController();
  final _todayOrderMtController = TextEditingController();
  final _todayCollectionRupeesController = TextEditingController();
  final _overdueAmountController = TextEditingController();
  final _feedbacksController = TextEditingController();
  final _solutionBySalespersonController = TextEditingController();
  final _anyRemarksController = TextEditingController();

  // State Management Variables
  bool _isSubmitting = false;
  bool _isLoadingDealers = true;
  bool _isUploadingImage = false;

  // Data Holders for the Workflow
  List<Dealer> _allDealers = [];
  Dealer? _selectedDealer;
  String? _selectedVisitType;
  DateTime? _checkInTime;
  File? _inTimeImageFile;
  String? _inTimeImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchDealersForDropdown();
  }

  @override
  void dispose() {
    _dealerTotalPotentialController.dispose();
    _dealerBestPotentialController.dispose();
    _brandSellingController.dispose();
    _contactPersonController.dispose();
    _contactPersonPhoneNoController.dispose();
    _todayOrderMtController.dispose();
    _todayCollectionRupeesController.dispose();
    _overdueAmountController.dispose();
    _feedbacksController.dispose();
    _solutionBySalespersonController.dispose();
    _anyRemarksController.dispose();
    super.dispose();
  }

  // --- Data Fetching ---
  Future<void> _fetchDealersForDropdown() async {
    try {
      final dealers = await _apiService.fetchDealers(
        userId: int.tryParse(widget.employee.id),
      );
      if (mounted) {
        setState(() {
          _allDealers = dealers;
          _isLoadingDealers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load dealers: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoadingDealers = false);
      }
    }
  }

  // --- SharedPreferences helpers (one-time calibration memory) ---
  Future<bool> _isDealerCalibrated(String dealerId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_calibratedDealersKey) ?? [];
    return list.contains(dealerId);
  }

  Future<void> _markDealerAsCalibrated(String dealerId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_calibratedDealersKey) ?? [];
    if (!list.contains(dealerId)) {
      list.add(dealerId);
      await prefs.setStringList(_calibratedDealersKey, list);
      dev.log('Dealer $dealerId marked as calibrated.', name: _log);
    }
  }

  // --- Location helper with permissions & timeouts ---
  Future<Position?> _getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return null;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied.')),
          );
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission permanently denied.'),
          ),
        );
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
      return null;
    }
  }

  // --- Simple camera helper for checkout step ---
  Future<File?> _captureImage() async {
    final x = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1024,
    );
    return x == null ? null : File(x.path);
  }

  // --- Workflow Logic ---
  void _onDealerSelected(Dealer? dealer) {
    if (dealer == null) return;
    setState(() {
      _selectedDealer = dealer;
      _dealerTotalPotentialController.text = dealer.totalPotential.toString();
      _dealerBestPotentialController.text = dealer.bestPotential.toString();
      _brandSellingController.text = dealer.brandSelling.join(', ');
      _contactPersonController.text = dealer.name;
      _contactPersonPhoneNoController.text = dealer.phoneNo;
    });
  }

  Future<void> _handleCheckIn() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _isUploadingImage = true);
    try {
      // Take photo
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1024,
      );
      if (pickedFile == null) {
        if (mounted) setState(() => _isUploadingImage = false);
        return;
      }
      final imageFile = File(pickedFile.path);
      if (mounted) setState(() => _inTimeImageFile = imageFile);

      // Upload
      final imageUrl = await _apiService.uploadImageToR2(imageFile);

      // Set state
      if (mounted) {
        setState(() {
          _checkInTime = DateTime.now();
          _inTimeImageUrl = imageUrl;
        });
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Checked-In successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Check-In Failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  // --- ✅ THIS IS THE FULLY UPGRADED SUBMIT FUNCTION ---
  // --- ✅ FINAL: Submit DVR aligned to your model ---
  Future<void> _submitDvr() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final String dealerId = _selectedDealer!.id!;

    try {
      // 1) Accurate location for submission + calibration
      final Position? currentPosition = await _getCurrentPosition();
      if (currentPosition == null) {
        throw Exception('Could not get your current location.');
      }

      // 2) One-time geofence calibration memory
      bool isAlreadyCalibrated = await _isDealerCalibrated(dealerId);

      // Coordinates to use for distance check
      double dealerLat;
      double dealerLon;

      if (!isAlreadyCalibrated) {
        // First-time calibration
        dev.log(
          'First time DVR for $dealerId. Calibrating geofence...',
          name: _log,
        );
        try {
          final newLat = currentPosition.latitude;
          final newLon = currentPosition.longitude;
          const newRadius = 25.0;

          await _apiService.updateDealerGeofence(
            dealerId: dealerId,
            latitude: newLat,
            longitude: newLon,
            radius: newRadius,
          );

          await _markDealerAsCalibrated(dealerId);

          // Use new calibrated coordinates for distance check
          dealerLat = newLat;
          dealerLon = newLon;

          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Dealer location calibrated!'),
              backgroundColor: Colors.blue,
            ),
          );
          dev.log(
            'Geofence for $dealerId calibrated successfully.',
            name: _log,
          );
        } catch (e) {
          // Calibration failed: fallback to existing dealer coords
          dev.log(
            'WARNING: Geofence calibration failed. Using old coordinates for distance check.',
            name: _log,
            error: e,
          );
          if (_selectedDealer!.latitude == null ||
              _selectedDealer!.longitude == null) {
            throw Exception(
              'Dealer location is missing. Cannot verify distance.',
            );
          }
          dealerLat = _selectedDealer!.latitude!;
          dealerLon = _selectedDealer!.longitude!;
        }
      } else {
        // Already calibrated: use stored dealer coords
        dev.log(
          'Dealer $dealerId is already calibrated. Skipping.',
          name: _log,
        );
        if (_selectedDealer!.latitude == null ||
            _selectedDealer!.longitude == null) {
          throw Exception(
            'Dealer location is missing. Cannot verify distance.',
          );
        }
        dealerLat = _selectedDealer!.latitude!;
        dealerLon = _selectedDealer!.longitude!;
      }

      // 3) Verify distance within 200 m
      final double distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        dealerLat,
        dealerLon,
      );
      if (distance > 200) {
        throw Exception(
          'You are too far from the dealer (${distance.toStringAsFixed(0)}m) to submit this report.',
        );
      }

      // 4) Capture + upload check-out photo
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please take a check-out photo.')),
      );
      final imageFile = await _captureImage();
      if (imageFile == null) {
        throw Exception('Check-out photo cancelled.');
      }

      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Uploading check-out photo...')),
      );
      final outTimeImageUrl = await _apiService.uploadImageToR2(imageFile);

      // 5) Build and submit DVR (aligned to your model)
      final dvr = DailyVisitReport(
        userId: int.parse(widget.employee.id),
        reportDate: DateTime.now(),
        dealerType: _selectedDealer!.type,
        dealerName: _selectedDealer!.name,
        location: _selectedDealer!.address,
        latitude: currentPosition.latitude,
        longitude: currentPosition.longitude,
        visitType: 'PLANNED', // wire to dropdown if needed
        dealerTotalPotential: _selectedDealer!.totalPotential,
        dealerBestPotential: _selectedDealer!.bestPotential,
        brandSelling: _selectedDealer!.brandSelling,
        todayOrderMt: double.tryParse(_todayOrderMtController.text) ?? 0.0,
        todayCollectionRupees:
            double.tryParse(_todayCollectionRupeesController.text) ?? 0.0,
        feedbacks: _feedbacksController.text,
        anyRemarks: _anyRemarksController.text.isEmpty
            ? null
            : _anyRemarksController.text,
        checkInTime: _checkInTime!, // from your check-in step
        checkOutTime: DateTime.now(),
        inTimeImageUrl: _inTimeImageUrl!, // from your check-in upload
        outTimeImageUrl: outTimeImageUrl,
      );

      await _apiService.createDvr(dvr);

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('DVR Submitted Successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      navigator.pop();
    } catch (e) {
      dev.log('DVR Submission failed: $e', name: _log, error: e);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('DVR Submission failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // --- UI Helper Widgets ---
  InputDecoration _inputDecoration(
    String label, {
    bool isRequired = true,
    bool readOnly = false,
  }) {
    return InputDecoration(
      labelText: '$label${isRequired ? '*' : ''}',
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: readOnly ? Colors.white10 : Colors.transparent,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white30),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // For the "floating" effect
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.0),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF020a67).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(24.0),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Daily Visit Report',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white24, height: 30),

                        // Step 1: Dealer Selection and Check-in
                        if (_checkInTime == null) ...[
                          _isLoadingDealers
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : DropdownButtonFormField<Dealer>(
                                  initialValue: _selectedDealer,
                                  isExpanded: true,
                                  hint: const Text(
                                    'Select Dealer/Sub-dealer*',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  dropdownColor: const Color(0xFF0D47A1),
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _inputDecoration(
                                    'Dealer/Sub-dealer',
                                  ),
                                  items: _allDealers
                                      .map(
                                        (dealer) => DropdownMenuItem(
                                          value: dealer,
                                          child: Text(
                                            dealer.name,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: _onDealerSelected,
                                  validator: (v) => v == null
                                      ? 'Please select a dealer'
                                      : null,
                                ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed:
                                _selectedDealer == null || _isUploadingImage
                                ? null
                                : _handleCheckIn,
                            icon: _isUploadingImage
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.camera_alt),
                            label: const Text('CHECK-IN WITH PHOTO'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                            ),
                          ),
                        ],

                        // Step 2: Fill form and submit
                        if (_checkInTime != null) ...[
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundImage: _inTimeImageFile != null
                                  ? FileImage(_inTimeImageFile!)
                                  : null,
                              child: _inTimeImageFile == null
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    )
                                  : null,
                            ),
                            title: Text(
                              _selectedDealer?.name ?? 'Dealer',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Checked-In at ${DateFormat('hh:mm a').format(_checkInTime!)}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            trailing: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 32,
                            ),
                          ),
                          const Divider(color: Colors.white24, height: 30),

                          DropdownButtonFormField<String>(
                            initialValue: _selectedVisitType,
                            dropdownColor: const Color(0xFF0D47A1),
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Visit Type'),
                            items:
                                [
                                      'Routine',
                                      'Follow-up',
                                      'Complaint',
                                      'New Lead',
                                    ]
                                    .map(
                                      (type) => DropdownMenuItem(
                                        value: type,
                                        child: Text(type),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) =>
                                setState(() => _selectedVisitType = value),
                            validator: (v) =>
                                v == null ? 'Please select a visit type' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _dealerTotalPotentialController,
                            readOnly: true,
                            style: const TextStyle(color: Colors.white70),
                            decoration: _inputDecoration(
                              'Dealer Total Potential',
                              readOnly: true,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _dealerBestPotentialController,
                            readOnly: true,
                            style: const TextStyle(color: Colors.white70),
                            decoration: _inputDecoration(
                              'Dealer Best Potential',
                              readOnly: true,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _brandSellingController,
                            readOnly: true,
                            style: const TextStyle(color: Colors.white70),
                            decoration: _inputDecoration(
                              'Brands Selling',
                              readOnly: true,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _contactPersonController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration(
                              'Contact Person',
                              isRequired: false,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _contactPersonPhoneNoController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration(
                              'Contact Phone',
                              isRequired: false,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _todayOrderMtController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Today\'s Order (MT)'),
                            validator: (v) =>
                                v!.isEmpty ? 'Field is required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _todayCollectionRupeesController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration(
                              'Today\'s Collection (₹)',
                            ),
                            validator: (v) =>
                                v!.isEmpty ? 'Field is required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _overdueAmountController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration(
                              'Overdue Amount (₹)',
                              isRequired: false,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _feedbacksController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Feedbacks'),
                            maxLines: 3,
                            validator: (v) =>
                                v!.isEmpty ? 'Feedback is required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _solutionBySalespersonController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration(
                              'Solution by Salesperson',
                              isRequired: false,
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _anyRemarksController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration(
                              'Any Other Remarks',
                              isRequired: false,
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 24),

                          ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitDvr,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: _isSubmitting
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'SUBMIT & CHECK-OUT WITH PHOTO',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
