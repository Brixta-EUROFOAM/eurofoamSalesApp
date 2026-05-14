// lib/screens/forms/add_DVR_form.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Import your models and utilities
import '../../models/dealer_model.dart';
import '../../widgets/ReusableFunctions.dart';
import 'dvrFormComponents/dvr_constants.dart';
import 'dvrFormComponents/dvr_form_widgets.dart';

class AddDvrFormScreen extends StatefulWidget {
  const AddDvrFormScreen({Key? key}) : super(key: key);

  @override
  State<AddDvrFormScreen> createState() => _AddDvrFormScreenState();
}

class _AddDvrFormScreenState extends State<AddDvrFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- Core State Variables ---
  bool _isLoading = false;
  bool _isCapturingCheckIn = false;
  
  // 1. Image & Location (Captured First)
  String? _capturedImagePath;
  LocationResult? _locationResult;
  DateTime? _checkInTime;

  // 2. Dealer Selection
  DealerModel? _selectedDealer;

  // 3. Form Field Controllers & Values
  final TextEditingController _orderQtyController = TextEditingController();
  final TextEditingController _collectionController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();
  
  String? _selectedDealerType;
  List<String> _selectedBrands = [];
  DateTime? _expectedActivationDate;

  @override
  void dispose() {
    _orderQtyController.dispose();
    _collectionController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  // --- ACTIONS ---

  Future<void> _handleInitialCheckIn() async {
    setState(() => _isCapturingCheckIn = true);

    try {
      // 1. Fetch GPS and aggressive reverse-geocoded address
      final location = await ReusableFunctions.getCurrentLocationAndAddress();

      // 2. Open Camera for Selfie / Store Front
      final photo = await ReusableFunctions.captureImage();

      if (photo == null) {
        _showError('Image capture cancelled. Photo is required.');
        return;
      }

      setState(() {
        _locationResult = location;
        _capturedImagePath = photo.path;
        _checkInTime = DateTime.now();
      });

    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isCapturingCheckIn = false);
    }
  }

  Future<void> _handleDealerSearch() async {
    HapticFeedback.selectionClick();
    final dealer = await openDealerSearch(context);
    
    if (dealer != null && mounted) {
      setState(() {
        _selectedDealer = dealer;
        // Auto-fill dealer type if your model supports it, otherwise leave for manual selection
      });
    }
  }

  Future<void> _submitForm() async {
    // 1. Pre-validation checks
    if (_capturedImagePath == null || _locationResult == null) {
      _showError('Please complete the Photo Check-In first.');
      return;
    }
    if (_selectedDealer == null) {
      _showError('Please select a Dealer from the network.');
      return;
    }

    // 2. Form validation
    if (!_formKey.currentState!.validate()) {
      _showError('Please fill in all required fields correctly.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // TODO: Implement your actual API / Local Database save logic here.
      // E.g., await _apiService.uploadImageToR2(File(_capturedImagePath!));
      // await _apiService.submitDvr(payload);

      // Simulating network delay for now
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('DVR Submitted Successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Return to previous screen
      }
    } catch (e) {
      _showError('Failed to submit DVR: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  // --- UI BUILDING ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "New Visit Report",
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0F172A), // _DvrStyle.cardNavy
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- STEP 1: PHOTO & LOCATION CHECK-IN ---
              const DvrFormSectionHeader(title: "1. Security & Location", icon: Icons.security_rounded),
              _buildCheckInCard(),

              // Only show the rest of the form if check-in is complete
              if (_capturedImagePath != null && _locationResult != null) ...[
                
                // --- STEP 2: DEALER SELECTION ---
                const DvrFormSectionHeader(title: "2. Dealer Identity", icon: Icons.storefront_rounded).animate().fadeIn(),
                _buildDealerSelectionCard().animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                // --- STEP 3: VISIT DETAILS ---
                const DvrFormSectionHeader(title: "3. Visit Metrics", icon: Icons.assignment_outlined).animate().fadeIn(delay: 200.ms),
                _buildMetricsCard().animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                const SizedBox(height: 40),

                // --- SUBMIT BUTTON ---
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981), // Accent Green
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                        )
                      : const Text(
                          "SUBMIT REPORT",
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.1),
                        ),
                ).animate().fadeIn(delay: 400.ms).scaleXY(begin: 0.9, curve: Curves.easeOutBack),
                
                const SizedBox(height: 40),
              ]
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildCheckInCard() {
    final bool isCheckedIn = _capturedImagePath != null && _locationResult != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isCheckedIn ? Colors.green.shade200 : Colors.grey.shade200, width: 2),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(20),
      child: isCheckedIn
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Check-In Verified",
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Icon(Icons.check_circle_rounded, color: Colors.green.shade600),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_capturedImagePath!),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Time: ${_checkInTime?.toLocal().toString().split('.')[0] ?? ''}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                            _locationResult!.address,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text("GPS: ${_locationResult!.latitude.toStringAsFixed(4)}, ${_locationResult!.longitude.toStringAsFixed(4)}", style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _handleInitialCheckIn,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text("Retake Photo & Location"),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
                  ),
                )
              ],
            )
          : Column(
              children: [
                const Icon(Icons.camera_alt_outlined, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  "A live photo and GPS location are required to begin this visit report.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isCapturingCheckIn ? null : _handleInitialCheckIn,
                    icon: _isCapturingCheckIn
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.location_on),
                    label: Text(_isCapturingCheckIn ? "LOCATING..." : "START CHECK-IN"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDealerSelectionCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Assigned Dealer",
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _handleDealerSearch,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _selectedDealer == null ? Colors.grey.shade300 : const Color(0xFF0F172A).withOpacity(0.3), width: _selectedDealer == null ? 1 : 1.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedDealer?.dealerPartyName ?? "Tap to search network...",
                          style: TextStyle(
                            color: _selectedDealer == null ? Colors.grey.shade600 : const Color(0xFF1E293B),
                            fontWeight: _selectedDealer == null ? FontWeight.normal : FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        if (_selectedDealer != null) ...[
                          const SizedBox(height: 4),
                          Text("${_selectedDealer!.area ?? ''}, ${_selectedDealer!.zone ?? ''}", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ]
                      ],
                    ),
                  ),
                  const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          DvrDropdownField(
            label: "Dealer Type",
            value: _selectedDealerType,
            items: DvrConstants.dealerTypes,
            onChanged: (val) => setState(() => _selectedDealerType = val),
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: DvrNumberField(
                  controller: _orderQtyController,
                  label: "Today's Order (MT/KG)",
                  isRequired: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DvrNumberField(
                  controller: _collectionController,
                  label: "Collection (₹)",
                  isRequired: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          DvrMultiSelectField(
            label: "Brands Selling",
            items: DvrConstants.brands,
            selectedValues: _selectedBrands,
            onChanged: (vals) => setState(() => _selectedBrands = vals),
          ),
          const SizedBox(height: 20),

          DvrDateField(
            label: "Expected Activation Date",
            selectedDate: _expectedActivationDate,
            isRequired: false, // Optional based on your logic
            onDateSelected: (date) => setState(() => _expectedActivationDate = date),
          ),
          const SizedBox(height: 20),

          DvrInputField(
            controller: _feedbackController,
            label: "Visit Remarks / Feedback",
            isRequired: true,
            maxLines: 4,
          ),
        ],
      ),
    );
  }
}