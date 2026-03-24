// lib/technicalSide/screens/forms/tso_meetings_form.dart

import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/salesSide/models/employee_model.dart';
import 'package:salesmanapp/salesSide/models/dealer_model.dart';
import 'package:salesmanapp/technicalSide/models/tso_meetings_model.dart';

// ---------------------------------------------------------------------------
// INLINE CAMERA MODULE
// ---------------------------------------------------------------------------
class _TsoMeetingCameraScreen extends StatefulWidget {
  const _TsoMeetingCameraScreen();

  @override
  State<_TsoMeetingCameraScreen> createState() => _TsoMeetingCameraScreenState();
}

class _TsoMeetingCameraScreenState extends State<_TsoMeetingCameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIdx = 0;
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    _setupCameras();
  }

  Future<void> _setupCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;
      _selectedCameraIdx = _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
      if (_selectedCameraIdx == -1) _selectedCameraIdx = 0;
      _initCamera(_cameras[_selectedCameraIdx]);
    } catch (e) {
      debugPrint("Camera setup error: $e");
    }
  }

  Future<void> _initCamera(CameraDescription cameraDescription) async {
    if (_controller != null) await _controller!.dispose();
    // ⚡ RAM TIP: Use medium resolution to save memory buffers
    _controller = CameraController(cameraDescription, ResolutionPreset.medium, enableAudio: false);
    setState(() {
      _initializeControllerFuture = _controller!.initialize();
    });
  }

  void _toggleCamera() {
    if (_cameras.length < 2) return;
    _selectedCameraIdx = (_selectedCameraIdx + 1) % _cameras.length;
    _initCamera(_cameras[_selectedCameraIdx]);
  }

  @override
  void dispose() {
    _controller?.dispose(); // ⚡ CRITICAL: Release GPU/Buffer memory
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isTakingPicture) return;
    try {
      setState(() => _isTakingPicture = true);
      await _controller!.setFlashMode(FlashMode.off);
      final image = await _controller!.takePicture();
      if (!mounted) return;
      Navigator.pop(context, image.path);
    } catch (e) {
      debugPrint("Capture error: $e");
    } finally {
      if (mounted) setState(() => _isTakingPicture = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && _controller != null) {
            return Stack(
              children: [
                Center(child: CameraPreview(_controller!)),
                _buildControls(),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        },
      ),
    );
  }

  Widget _buildControls() {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context, '__CANCEL__')),
                if (_cameras.length > 1)
                  IconButton(icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 30), onPressed: _toggleCamera),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: InkWell(
              onTap: _takePicture,
              child: Container(
                height: 70, width: 70,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4), color: Colors.white24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 🟢 TSO MEETING FORM
// ---------------------------------------------------------------------------
class TsoMeetingsForm extends StatefulWidget {
  final Employee employee;
  const TsoMeetingsForm({super.key, required this.employee});

  @override
  State<TsoMeetingsForm> createState() => _TsoMeetingsFormState();
}

class _TsoMeetingsFormState extends State<TsoMeetingsForm> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // --- FINTECH THEME PALETTE ---
  static const Color _bgLight       = Color(0xFFF8FAFC); // Slate 50
  static const Color _surfaceWhite  = Colors.white;
  static const Color _cardNavy      = Color(0xFF0F172A); // Deep Navy
  static const Color _textDark      = Color(0xFF1E293B); // Slate 800
  static const Color _textGrey      = Color(0xFF64748B); // Slate 500
  static const Color _inputFill     = Color(0xFFF1F5F9); // Slate 100
  static const Color _accentGreen   = Color(0xFF10B981); // Emerald
  static const Color _dangerRed     = Color(0xFFEF4444); // Red

  // State Variables
  String? _selectedType;
  DateTime? _selectedDate = DateTime.now();
  File? _imageFile;
  String? _uploadedImageUrl;
  
  Dealer? _selectedDealer;
  String? _selectedAccount;
  bool _billSubmitted = false;

  bool _isUploading = false;
  bool _isSubmitting = false;
  bool _isFetchingLocation = false;

  final List<String> _meetingTypes = [
    'Mason Meet',
    'PC Meet'
  ];

  final List<String> _accountOptions = [
    'JUD',
    'JSB'
  ];

  // Controllers
  final _zoneController = TextEditingController();
  final _marketController = TextEditingController();
  final _dealerAddressController = TextEditingController();
  final _participantsController = TextEditingController();
  final _giftTypeController = TextEditingController();
  final _expensesController = TextEditingController();

  @override
  void dispose() {
    _zoneController.dispose();
    _marketController.dispose();
    _dealerAddressController.dispose();
    _participantsController.dispose();
    _giftTypeController.dispose();
    _expensesController.dispose();
    super.dispose();
  }

  // --- ACTIONS ---

  Future<void> _captureAndUploadImage() async {
    final String? imagePath = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const _TsoMeetingCameraScreen()),
    );

    if (imagePath == null || imagePath == '__CANCEL__') return;

    setState(() {
      _imageFile = File(imagePath);
      _isUploading = true;
    });

    try {
      final url = await _apiService.uploadImageToR2(_imageFile!);
      if (mounted) {
        setState(() {
          _uploadedImageUrl = url;
          _isUploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        _toast("Failed to upload image: $e", isError: true);
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _cardNavy,
              onPrimary: Colors.white,
              onSurface: _textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _getLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _toast("Location permission denied", isError: true);
          return;
        }
      }
      
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      Map<String, String> addressDetails = await _apiService.reverseGeocodeWithRadar(
        latitude: position.latitude, 
        longitude: position.longitude
      );

      if (mounted) {
        setState(() {
          if (addressDetails['address']?.isNotEmpty == true) {
            _dealerAddressController.text = addressDetails['address']!;
          }
          if (addressDetails['region']?.isNotEmpty == true) {
            _zoneController.text = addressDetails['region']!;
          }
        });
        _toast("Location Fetched Successfully");
      }
    } catch (e) {
      if (mounted) {
        _toast("Location fetch failed: $e", isError: true);
      }
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _openDealerSearch() async {
    final Dealer? result = await showDialog(
      context: context,
      builder: (_) => _ServerDealerSearchDialog(api: _apiService),
    );
    if (result != null) {
      setState(() => _selectedDealer = result);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Rule 1: Photo is mandatory
    if (_uploadedImageUrl == null) {
      _toast("Meeting photo is mandatory. Please capture an image.", isError: true);
      return;
    }
    
    if (_selectedType == null) {
      _toast("Please select a Meeting Type", isError: true);
      return;
    }
    
    if (_selectedDate == null) {
      _toast("Please select a Date", isError: true);
      return;
    }

    if (_selectedDealer == null) {
      _toast("Please select a Dealer", isError: true);
      return;
    }

    // Attempt to parse integers / doubles
    int? participants = int.tryParse(_participantsController.text.trim());
    double? expenses = double.tryParse(_expensesController.text.trim());
    int userId = int.tryParse(widget.employee.id.trim()) ?? 0;

    setState(() => _isSubmitting = true);

    try {
      final meeting = TsoMeeting(
        createdByUserId: userId,
        type: _selectedType,
        date: _selectedDate,
        participantsCount: participants,
        zone: _zoneController.text.trim(),
        market: _marketController.text.trim(),
        dealerName: _selectedDealer!.name,
        dealerAddress: _dealerAddressController.text.trim(),
        conductedBy: widget.employee.displayName,
        giftType: _giftTypeController.text.trim(),
        accountJsbJud: _selectedAccount,
        totalExpenses: expenses,
        billSubmitted: _billSubmitted,
        meetImageUrl: _uploadedImageUrl, 
        location: _dealerAddressController.text.trim(), // Fallback mapping for older Zod requirements
      );

      await _apiService.createTsoMeeting(meeting);

      if (mounted) {
        _toast("Meeting logged successfully!");
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _toast("Submission Failed: $e", isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _toast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? _dangerRed : _accentGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- UI WIDGETS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: _bgLight,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Log Meeting Data",
          style: TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ----------------------------------------------------
              // 1. CAMERA MODULE (FIRST ELEMENT) - MANDATORY
              // ----------------------------------------------------
              _buildLabel("Meeting Photo", isMandatory: true),
              const SizedBox(height: 8),
              InkWell(
                onTap: _isUploading ? null : _captureAndUploadImage,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _inputFill,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _imageFile != null ? _accentGreen : Colors.grey.shade300,
                      width: _imageFile != null ? 2 : 1,
                    ),
                    image: _imageFile != null
                        ? DecorationImage(
                            image: FileImage(_imageFile!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _isUploading
                      ? const Center(child: CircularProgressIndicator(color: _cardNavy))
                      : _imageFile == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.camera_alt_rounded, color: _textGrey, size: 40),
                                SizedBox(height: 8),
                                Text(
                                  "TAP TO TAKE PHOTO",
                                  style: TextStyle(
                                    color: _textGrey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : null,
                ),
              ),
              const SizedBox(height: 24),

              // ----------------------------------------------------
              // 2. MEETING DETAILS CARD
              // ----------------------------------------------------
              Container(
                padding: const EdgeInsets.all(24),
                decoration: _cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Meeting Details", style: TextStyle(color: _textDark, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    // Meeting Type
                    _buildLabel("Meeting Type", isMandatory: true),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      items: _meetingTypes.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: _textDark)))).toList(),
                      onChanged: (v) => setState(() => _selectedType = v),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _textGrey),
                      decoration: _inputDecoration("Select Type", Icons.groups_rounded),
                    ),
                    const SizedBox(height: 16),

                    // Date
                    _buildLabel("Date", isMandatory: true),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: _inputDecoration("", Icons.calendar_today_rounded),
                        child: Text(
                          _selectedDate == null ? "Select Date" : DateFormat('dd MMM yyyy').format(_selectedDate!),
                          style: TextStyle(
                            color: _selectedDate == null ? Colors.grey : _textDark,
                            fontWeight: _selectedDate == null ? FontWeight.normal : FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ----------------------------------------------------
              // 3. LOCATION & DEALER CARD
              // ----------------------------------------------------
              Container(
                padding: const EdgeInsets.all(24),
                decoration: _cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Location & Dealer", style: TextStyle(color: _textDark, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    // Location Fetcher
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isFetchingLocation ? null : _getLocation,
                        icon: _isFetchingLocation 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.my_location_rounded),
                        label: const Text("AUTO-FETCH ADDRESS"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: _cardNavy),
                          foregroundColor: _cardNavy,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("Zone", isMandatory: true),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _zoneController,
                                style: const TextStyle(color: _textDark, fontWeight: FontWeight.w500),
                                decoration: _inputDecoration("Zone", Icons.map_rounded),
                                validator: (v) => v!.trim().isEmpty ? "Required" : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("Market", isMandatory: true),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _marketController,
                                style: const TextStyle(color: _textDark, fontWeight: FontWeight.w500),
                                decoration: _inputDecoration("Market name", Icons.storefront_rounded),
                                validator: (v) => v!.trim().isEmpty ? "Required" : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildLabel("Dealer Address", isMandatory: true),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _dealerAddressController,
                      maxLines: 2,
                      style: const TextStyle(color: _textDark, fontWeight: FontWeight.w500),
                      decoration: _inputDecoration("Full address", Icons.location_on_rounded),
                      validator: (v) => v!.trim().isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 16),

                    _buildLabel("Dealer Name", isMandatory: true),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _openDealerSearch,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: _inputFill,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedDealer != null ? _accentGreen : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: _textGrey, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedDealer?.name ?? "Tap to Search Dealer",
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: _selectedDealer != null ? _textDark : Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (_selectedDealer != null)
                              const Icon(Icons.check_circle, color: _accentGreen, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ----------------------------------------------------
              // 4. METRICS & EXPENSES CARD
              // ----------------------------------------------------
              Container(
                padding: const EdgeInsets.all(24),
                decoration: _cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Expenses & Metrics", style: TextStyle(color: _textDark, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("Participants"),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _participantsController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: _textDark, fontWeight: FontWeight.w500),
                                decoration: _inputDecoration("Count", Icons.people_alt_rounded),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("Total Exp. (₹)"),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _expensesController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(color: _textDark, fontWeight: FontWeight.w500),
                                decoration: _inputDecoration("Amount", Icons.account_balance_wallet_rounded),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("Gift Type Given"),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _giftTypeController,
                                style: const TextStyle(color: _textDark, fontWeight: FontWeight.w500),
                                decoration: _inputDecoration("e.g. Diary, Pen", Icons.card_giftcard_rounded),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("Account"),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _selectedAccount,
                                items: _accountOptions.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: _textDark)))).toList(),
                                onChanged: (v) => setState(() => _selectedAccount = v),
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _textGrey),
                                decoration: _inputDecoration("A/C", Icons.account_balance_rounded),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Bill Submitted Toggle
                    // Container(
                    //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    //   decoration: BoxDecoration(
                    //     color: _inputFill,
                    //     borderRadius: BorderRadius.circular(12),
                    //     border: Border.all(
                    //       color: _billSubmitted ? _accentGreen.withOpacity(0.5) : Colors.transparent,
                    //     ),
                    //   ),
                    //   child: Row(
                    //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //     children: [
                    //       const Text(
                    //         "Bill Submitted?",
                    //         style: TextStyle(color: _textDark, fontWeight: FontWeight.w600, fontSize: 14),
                    //       ),
                    //       Switch(
                    //         value: _billSubmitted,
                    //         onChanged: (v) => setState(() => _billSubmitted = v),
                    //         activeColor: _accentGreen,
                    //       ),
                    //     ],
                    //   ),
                    // ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ----------------------------------------------------
              // 5. SUBMIT BUTTON
              // ----------------------------------------------------
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isSubmitting || _isUploading) ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _cardNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("SUBMIT MEETING LOG", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPERS ---

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: _surfaceWhite,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 15,
          offset: const Offset(0, 5),
        )
      ],
    );
  }

  Widget _buildLabel(String text, {bool isMandatory = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: _textDark, fontWeight: FontWeight.w600, fontSize: 13),
        children: [
          if (isMandatory) const TextSpan(text: " *", style: TextStyle(color: _dangerRed)),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      filled: true,
      fillColor: _inputFill,
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      prefixIcon: Icon(icon, color: _textGrey, size: 20),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _cardNavy, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _dangerRed, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _dangerRed, width: 1.5)),
    );
  }
}

// ---------------------------------------------------------------------------
// 🟢 SEARCH DIALOG MODULE
// ---------------------------------------------------------------------------
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
  String _lastQuery = "";

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
      if (query != _lastQuery) {
        _performSearch(query);
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    _lastQuery = query;
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        "Select Dealer",
        style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              style: const TextStyle(color: Color(0xFF111827)),
              decoration: InputDecoration(
                hintText: "Search dealer...",
                hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _dealers.isEmpty
                  ? const Center(
                      child: Text(
                        "No dealers found",
                        style: TextStyle(color: Color(0xFF6B7280)),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _dealers.length,
                      separatorBuilder: (ctx, i) =>
                          const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      itemBuilder: (context, index) {
                        final dealer = _dealers[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            dealer.name,
                            style: const TextStyle(
                              color: Color(0xFF111827),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            dealer.area,
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
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
          onPressed: () => Navigator.pop(context, null),
          child: const Text("CANCEL"),
        ),
      ],
    );
  }
}