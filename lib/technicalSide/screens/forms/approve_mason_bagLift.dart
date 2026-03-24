// lib/technicalSide/screens/forms/approve_mason_bagLift.dart

import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/technicalSide/models/mason_baglift_model.dart';
import 'package:salesmanapp/salesSide/models/employee_model.dart';
import 'package:salesmanapp/technicalSide/models/sites_model.dart';
import 'package:salesmanapp/salesSide/models/dealer_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camera/camera.dart';
import 'package:salesmanapp/widgets/reusable_functions.dart';

// ---------------------------------------------------------------------------
// 🟢 INTERNAL CAMERA SCREEN (Copy to bottom of technical_dashboard_screen.dart)
// ---------------------------------------------------------------------------
class _InlineCameraScreen extends StatefulWidget {
  const _InlineCameraScreen();

  @override
  State<_InlineCameraScreen> createState() => _InlineCameraScreenState();
}

class _InlineCameraScreenState extends State<_InlineCameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isTakingPicture = false;

  // ⚡ NEW: Store list of cameras to enable switching
  List<CameraDescription> _cameras = [];
  int _selectedCameraIdx = 0;

  @override
  void initState() {
    super.initState();
    _setupCameras();
  }

  // 1. One-time setup: Get all cameras and find the selfie one
  Future<void> _setupCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      // Find the index of the front camera, or default to 0 (back)
      _selectedCameraIdx = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );

      if (_selectedCameraIdx == -1) _selectedCameraIdx = 0;

      // Initialize the selected camera
      _initCamera(_cameras[_selectedCameraIdx]);
    } catch (e) {
      debugPrint("Camera setup error: $e");
    }
  }

  // 2. Init specific camera (Re-used when flipping)
  Future<void> _initCamera(CameraDescription cameraDescription) async {
    // If a controller exists, dispose it cleanly before creating a new one
    if (_controller != null) {
      await _controller!.dispose();
    }

    _controller = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    setState(() {
      _initializeControllerFuture = _controller!.initialize();
    });
  }

  // 3. The Flip Logic
  void _toggleCamera() {
    if (_cameras.length < 2) return;

    final newIndex = (_selectedCameraIdx + 1) % _cameras.length;
    _selectedCameraIdx = newIndex;
    _initCamera(_cameras[_selectedCameraIdx]);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isTakingPicture) {
      return;
    }

    try {
      setState(() => _isTakingPicture = true);
      // Optional: Turn flash off to avoid crashes on some low-end devices
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
          if (snapshot.connectionState == ConnectionState.done &&
              _controller != null) {
            return Stack(
              children: [
                // 1. Camera Preview
                Center(child: CameraPreview(_controller!)),

                // 2. Controls Overlay
                SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // --- TOP BAR: Close & Flip ---
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Close Button
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 30,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),

                            // Flip Button (Hidden if only 1 camera exists)
                            if (_cameras.length > 1)
                              IconButton(
                                icon: const Icon(
                                  Icons.flip_camera_ios_outlined,
                                  color: Colors.white,
                                  size: 30,
                                ),
                                onPressed: _toggleCamera,
                              ),
                          ],
                        ),
                      ),

                      // --- BOTTOM BAR: Shutter Button ---
                      Padding(
                        padding: const EdgeInsets.only(bottom: 30),
                        child: InkWell(
                          onTap: _takePicture,
                          child: Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              color: _isTakingPicture
                                  ? Colors.white
                                  : Colors.white24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
        },
      ),
    );
  }
}

class ApproveMasonBagLift extends StatefulWidget {
  final Employee employee;
  final String? highlightedId;
  const ApproveMasonBagLift({
    super.key,
    required this.employee,
    this.highlightedId,
  });

  @override
  State<ApproveMasonBagLift> createState() => _ApproveMasonBagLiftState();
}

class _ApproveMasonBagLiftState extends State<ApproveMasonBagLift> {
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();

  late Future<List<MasonBagLift>> _futureLifts;
  bool _isProcessing = false;

  // --- CORE STATE (RAM Management) ---
  File? _recoveredFile;
  String? _reviewingItemId;

  final _bagCountController = TextEditingController();
  final _personNameController = TextEditingController();
  final _personPhoneController = TextEditingController();
  final _memoController = TextEditingController();

  TechnicalSite? _selectedSite;
  Dealer? _selectedDealer;

  // --- FINTECH THEME PALETTE ---
  static const Color _bgLight = Color(0xFFF3F4F6);
  static const Color _surfaceWhite = Colors.white;
  static const Color _textDark = Color(0xFF111827);
  static const Color _textGrey = Color(0xFF6B7280);
  static const Color _cardNavy = Color(0xFF0F172A);
  static const Color _accentGreen = Color(0xFF10B981);
  static const Color _dangerRed = Color(0xFFEF4444);
  static const Color _infoBlue = Color(0xFF3B82F6);
  static const Color _inputFill = Color(0xFFF9FAFB);

  @override
  void initState() {
    super.initState();
    _loadData();

    // ⚡ RAM RECOVERY: Run after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadDrafts();
      // Only check lost data if we have a reviewing ID saved from a previous session
      if (_reviewingItemId != null && _reviewingItemId!.isNotEmpty) {
        await _checkLostData();
      }
    });
  }

  // --- RECOVERY LOGIC ---
  Future<void> _saveDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bag_lift_review_id', _reviewingItemId ?? "");
    await prefs.setString('bag_lift_count', _bagCountController.text);
    await prefs.setString('bag_lift_memo', _memoController.text);
    await prefs.setString('bag_lift_p_name', _personNameController.text);
    await prefs.setString('bag_lift_p_phone', _personPhoneController.text);

    if (_selectedSite != null) {
      await prefs.setString('bag_lift_site_id', _selectedSite!.id!);
      await prefs.setString('bag_lift_site_name', _selectedSite!.siteName);
    }
    if (_selectedDealer != null) {
      await prefs.setString('bag_lift_dealer_id', _selectedDealer!.id!);
      await prefs.setString('bag_lift_dealer_name', _selectedDealer!.name);
    }
  }

  Future<void> _loadDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('bag_lift_review_id') ?? "";

    if (savedId.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _reviewingItemId = savedId;
        _bagCountController.text = prefs.getString('bag_lift_count') ?? "";
        _memoController.text = prefs.getString('bag_lift_memo') ?? "";
        _personNameController.text = prefs.getString('bag_lift_p_name') ?? "";
        _personPhoneController.text = prefs.getString('bag_lift_p_phone') ?? "";

        final sId = prefs.getString('bag_lift_site_id');
        final sName = prefs.getString('bag_lift_site_name');
        if (sId != null && sName != null) {
          _selectedSite = TechnicalSite(
            id: sId,
            siteName: sName,
            address: "",
            concernedPerson: "",
            phoneNo: "",
            latitude: 0.0,
            longitude: 0.0,
          );
        }

        final dId = prefs.getString('bag_lift_dealer_id');
        final dName = prefs.getString('bag_lift_dealer_name');
        if (dId != null && dName != null) {
          _selectedDealer = Dealer(
            id: dId,
            name: dName,
            area: "",
            type: "",
            region: "",
            phoneNo: "",
            address: "",
            totalPotential: 0.0,
            bestPotential: 0.0,
            brandSelling: [],
            feedbacks: "",
          );
        }
      });
    }
  }

  Future<void> _clearDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = [
      'bag_lift_review_id',
      'bag_lift_count',
      'bag_lift_memo',
      'bag_lift_p_name',
      'bag_lift_p_phone',
      'bag_lift_site_id',
      'bag_lift_dealer_id',
    ];
    for (var key in keys) await prefs.remove(key);

    if (mounted) {
      setState(() {
        _reviewingItemId = null;
        _recoveredFile = null;
        _selectedSite = null;
        _selectedDealer = null;
        _bagCountController.clear();
        _memoController.clear();
        _personNameController.clear();
        _personPhoneController.clear();
      });
    }
  }

  // 📸 FIXED: Robust Lost Data Retrieval
  Future<void> _checkLostData() async {
    if (!Platform.isAndroid) return;

    try {
      final LostDataResponse response = await _picker.retrieveLostData();

      if (response.isEmpty || response.file == null) return;

      if (_reviewingItemId != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Restoring camera image..."),
              backgroundColor: _infoBlue,
            ),
          );
        }

        setState(() => _recoveredFile = File(response.file!.path));

        // Wait for list to be ready before finding item to re-open dialog
        final list = await _futureLifts;
        try {
          final target = list.firstWhere((item) => item.id == _reviewingItemId);
          if (mounted) _showVerificationDialog(target);
        } catch (e) {
          debugPrint("Recovery failed: Item no longer in list");
        }
      }
    } catch (e) {
      debugPrint("Lost Data Error: $e");
    }
  }

  void _loadData() async {
    final rawId = widget.employee.id.trim();
    final userId = int.tryParse(rawId);

    if (userId != null) {
      setState(() {
        _futureLifts = _api.fetchPendingBagLifts(userId: userId);
      });

      if (widget.highlightedId != null) {
        try {
          final list = await _futureLifts;
          final targetItem = list.firstWhere(
            (item) => item.id == widget.highlightedId,
          );
          if (mounted) {
            Future.microtask(() => _showVerificationDialog(targetItem));
          }
        } catch (e) {
          debugPrint("Auto-Open Failed: $e");
        }
      }
    } else {
      setState(() => _futureLifts = Future.value([]));
    }
  }

  // --- Helper for Input Styling ---
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: _inputFill,
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _cardNavy, width: 1),
      ),
    );
  }

  Widget _buildLabel(String text, {bool isMandatory = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 12,
          color: _textDark,
          fontWeight: FontWeight.w600,
        ),
        children: [
          if (isMandatory)
            const TextSpan(
              text: " *",
              style: TextStyle(color: _dangerRed),
            ),
        ],
      ),
    );
  }

  // --- Search Dialogs ---
  Future<TechnicalSite?> _showServerSearchSiteDialog() async {
    final userId = int.tryParse(widget.employee.id);
    if (userId == null) return null;

    return await openSiteSearch(context, _api, userId);
  }

  Future<Dealer?> _showServerSearchDealerDialog() async {
    return await openDealerSearch(context);
  }

  void _showVerificationDialog(MasonBagLift item) {
    // 🛡️ CRITICAL FIX: Stale Draft Protection
    // If we are opening a NEW item that doesn't match the one in RAM/Disk,
    // we must clear the old data so the new dialog is fresh.
    if (_reviewingItemId != null && _reviewingItemId != item.id) {
      _recoveredFile = null;
      _bagCountController.clear();
      _personNameController.clear();
      _personPhoneController.clear();
      _memoController.clear();
      _selectedSite = null;
      _selectedDealer = null;
    }

    _reviewingItemId = item.id;

    if (_bagCountController.text.isEmpty) {
      _bagCountController.text = item.bagCount.toString();
    }
    _saveDrafts();

    // Local Logic State
    bool _isValidatingRules = false;
    File? _siteImageFile =
        _recoveredFile; // Initialize with recovered file if exists
    String? _uploadedSiteImageUrl;
    bool _isUploadingImage = false;
    bool _needsAutoUpload =
        _recoveredFile != null; // Flag to trigger upload for recovered file

    final int? validApproverId = int.tryParse(widget.employee.id);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          // 1. Helper Function to Upload
          Future<void> _handleUpload(File file) async {
            setStateDialog(() => _isUploadingImage = true);
            try {
              final url = await _api.uploadImageToR2(file);
              if (mounted) {
                setStateDialog(() {
                  _uploadedSiteImageUrl = url;
                  _isUploadingImage = false;
                });
              }
            } catch (e) {
              if (mounted) {
                setStateDialog(() => _isUploadingImage = false);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
              }
            }
          }

          // 2. Auto-Upload Trigger for Recovered File
          // We use the local flag `_needsAutoUpload` which was initialized from parent state
          if (_needsAutoUpload && _siteImageFile != null) {
            _needsAutoUpload = false; // Run only once
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _handleUpload(_siteImageFile!);
            });
          }

          bool isFormUnlocked = _siteImageFile != null;

          Future<void> _pickNewImage() async {
            try {
              // 🟢 REPLACED: Use Inline Camera instead of ImagePicker
              final String? imagePath = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const _InlineCameraScreen(),
                ),
              );

              // If user cancelled
              if (imagePath == null) return;

              // Update State
              setStateDialog(() {
                _siteImageFile = File(imagePath);
              });

              // Upload immediately
              await _handleUpload(File(imagePath));
              _saveDrafts();
            } catch (e) {
              debugPrint("Camera error: $e");
            }
          }

          return AlertDialog(
            backgroundColor: _surfaceWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              "Review & Verify",
              style: TextStyle(fontWeight: FontWeight.bold, color: _textDark),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("Verification Photo (Site)", isMandatory: true),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _isUploadingImage ? null : _pickNewImage,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _inputFill,
                        border: Border.all(
                          color: isFormUnlocked
                              ? _accentGreen
                              : Colors.grey.shade300,
                          width: isFormUnlocked ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        image: _siteImageFile != null
                            ? DecorationImage(
                                image: FileImage(_siteImageFile!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _isUploadingImage
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: _cardNavy,
                              ),
                            )
                          : _siteImageFile == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.camera_alt_rounded,
                                  color: _cardNavy,
                                  size: 40,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "TAP TO TAKE PHOTO",
                                  style: TextStyle(
                                    color: _cardNavy,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),

                  const Divider(height: 32),

                  Opacity(
                    opacity: isFormUnlocked ? 1.0 : 0.5,
                    child: AbsorbPointer(
                      absorbing: !isFormUnlocked,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Verified Bag Count", isMandatory: true),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _bagCountController,
                            onChanged: (val) => _saveDrafts(),
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Color(0xFF111827)),
                            decoration: _inputDecoration("Enter actual count"),
                          ),
                          const SizedBox(height: 16),

                          _buildLabel("Select Dealer", isMandatory: true),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final res = await _showServerSearchDealerDialog();
                              if (res != null) {
                                setStateDialog(() => _selectedDealer = res);
                                _selectedDealer = res; // Sync Parent
                                _saveDrafts();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: _inputFill,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _selectedDealer?.name ??
                                          "Tap to Search Dealer...",
                                      style: TextStyle(
                                        color: _selectedDealer != null
                                            ? _textDark
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.search,
                                    color: _textDark,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildLabel("Link to Site", isMandatory: true),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final result =
                                  await _showServerSearchSiteDialog();
                              if (result != null) {
                                setStateDialog(() {
                                  _selectedSite = result;
                                  _personNameController.text =
                                      result.concernedPerson;
                                  _personPhoneController.text = result.phoneNo;
                                });
                                _saveDrafts();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: _inputFill,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _selectedSite?.siteName ??
                                          "Tap to Search Site...",
                                      style: TextStyle(
                                        color: _selectedSite != null
                                            ? _textDark
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.search,
                                    color: _textDark,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildLabel("Site Key Person Details"),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _personNameController,
                                  onChanged: (val) => _saveDrafts(),
                                  style: const TextStyle(
                                    color: Color(0xFF111827),
                                  ),
                                  decoration: _inputDecoration("Name"),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _personPhoneController,
                                  onChanged: (val) => _saveDrafts(),
                                  style: const TextStyle(
                                    color: Color(0xFF111827),
                                  ),
                                  decoration: _inputDecoration("Phone"),
                                  keyboardType: TextInputType.phone,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          _buildLabel("Remarks / Reason"),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _memoController,
                            onChanged: (val) => _saveDrafts(),
                            style: const TextStyle(color: Color(0xFF111827)),
                            decoration: _inputDecoration("Enter notes..."),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "CANCEL",
                  style: TextStyle(
                    color: _textGrey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (validApproverId == null) return;
                  Navigator.pop(context);
                  _handleBackgroundApproval(
                    id: item.id,
                    status: 'rejected',
                    approverId: validApproverId,
                  );
                },
                child: const Text(
                  "REJECT",
                  style: TextStyle(
                    color: _dangerRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: (_isUploadingImage || _isValidatingRules)
                    ? null
                    : () async {
                        if (_selectedSite == null ||
                            _selectedDealer == null ||
                            validApproverId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Error: Site and Dealer are mandatory.",
                              ),
                              backgroundColor: _dangerRed,
                            ),
                          );
                          return;
                        }

                        // Final check if upload didn't happen yet (e.g. quick click)
                        if (_uploadedSiteImageUrl == null &&
                            _siteImageFile != null) {
                          await _handleUpload(_siteImageFile!);
                          if (_uploadedSiteImageUrl == null)
                            return; // Fail safe
                        }

                        setStateDialog(() => _isValidatingRules = true);
                        try {
                          final stats = await _api.getMasonBagStats(
                            masonId: item.masonId,
                            siteId: _selectedSite!.id!,
                          );
                          final int overallBags =
                              int.tryParse(stats['overall'].toString()) ?? 0;
                          final int siteBags =
                              int.tryParse(stats['site'].toString()) ?? 0;

                          if (overallBags > 800 && siteBags > 600) {
                            setStateDialog(() => _isValidatingRules = false);
                            if (!mounted) return;
                            _showBlockDialog(overallBags, siteBags);
                            return;
                          }

                          Navigator.pop(context);

                          _handleBackgroundApproval(
                            id: item.id,
                            status: 'approved',
                            approverId: validApproverId,
                            imageUrl: _uploadedSiteImageUrl,
                          );
                        } catch (e) {
                          setStateDialog(() => _isValidatingRules = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Validation Error: $e"),
                              backgroundColor: _dangerRed,
                            ),
                          );
                        }
                      },
                child: (_isValidatingRules || _isUploadingImage)
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "VERIFY & APPROVE",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showBlockDialog(int overall, int site) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.block_flipped, color: Color(0xFFEF4444)),
            SizedBox(width: 12),
            Text(
              "Approval Blocked",
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Cannot Auto-Approve based on current history rules:",
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            _buildBlockDetail("Mason History", overall, 800),
            const SizedBox(height: 8),
            _buildBlockDetail("Site History", site, 600),
            const SizedBox(height: 16),
            const Text(
              "Please contact your Admin for manual approval.",
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "OK",
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockDetail(String label, int current, int limit) {
    return Row(
      children: [
        const Icon(Icons.circle, size: 6, color: Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
        Text(
          "$current (Needs less than $limit)",
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Future<void> _handleBackgroundApproval({
    required String id,
    required String status,
    int? bagCount,
    String? siteId,
    String? dealerId,
    required int approverId,
    String? imageUrl,
  }) async {
    setState(() => _isProcessing = true);
    try {
      await _api.updateBagLiftStatus(
        id,
        status,
        bagCount: bagCount,
        siteId: siteId,
        dealerId: dealerId,
        siteKeyPersonName: _personNameController.text,
        siteKeyPersonPhone: _personPhoneController.text,
        memo: _memoController.text,
        verificationSiteImageUrl: imageUrl,
        approvedBy: approverId,
        approvedAt: DateTime.now().toIso8601String(),
      );

      await _clearDrafts(); // Wipe disk only on success
      _loadData();
      _toast("Successfully Approved");
    } catch (e) {
      _toast("Error: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _toast(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? _dangerRed : _accentGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: _bgLight,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _textGrey,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Pending Bag Lifts",
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _textDark),
            onPressed: _loadData,
          ),
        ],
      ),
      body: FutureBuilder<List<MasonBagLift>>(
        future: _futureLifts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _cardNavy),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: _dangerRed),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      size: 40,
                      color: _textGrey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No pending bag lifts",
                    style: TextStyle(
                      color: _textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "You're all caught up!",
                    style: TextStyle(color: _textGrey),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _buildBagLiftCard(snapshot.data![index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildBagLiftCard(MasonBagLift item) {
    final dateStr = item.createdAt.toLocal().toString().split('.')[0];

    return Container(
      decoration: BoxDecoration(
        color: _surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFFFF7ED),
                  child: const Icon(Icons.shopping_bag, color: Colors.orange),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.masonName ?? "Unknown Mason",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _textDark,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: const TextStyle(color: _textGrey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${item.bagCount} Bags",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _infoBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),

          if (item.imageUrl != null)
            GestureDetector(
              onTap: () => _showFullImage(item.imageUrl!),
              child: Container(
                height: 180,
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[100],
                  image: DecorationImage(
                    image: NetworkImage(item.imageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit_note, color: Colors.white),
                label: const Text(
                  "REVIEW & VERIFY",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cardNavy,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isProcessing
                    ? null
                    : () => _showVerificationDialog(item),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImage(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const CloseButton(),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InteractiveViewer(child: Image.network(url)),
            ),
          ],
        ),
      ),
    );
  }
}
