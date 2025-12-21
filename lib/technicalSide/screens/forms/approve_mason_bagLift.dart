// lib/technicalSide/screens/forms/approve_mason_bagLift.dart

import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/technicalSide/models/mason_baglift_model.dart';
import 'package:salesmanapp/models/employee_model.dart';
import 'package:salesmanapp/technicalSide/models/sites_model.dart';
import 'package:salesmanapp/models/dealer_model.dart';

class ApproveMasonBagLift extends StatefulWidget {
  final Employee employee;
  final String? highlightedId;
  const ApproveMasonBagLift({super.key, required this.employee, this.highlightedId,});

  @override
  State<ApproveMasonBagLift> createState() => _ApproveMasonBagLiftState();
}

class _ApproveMasonBagLiftState extends State<ApproveMasonBagLift> {
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();

  late Future<List<MasonBagLift>> _futureLifts;
  bool _isProcessing = false;

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
  }

// 1. Change 'void' to 'Future<void>' or just 'void' marked 'async'
// Inside _ApproveMasonBagLiftState class...

  void _loadData() async { 
    final rawId = widget.employee.id.trim();
    final userId = int.tryParse(rawId);

    if (userId != null) {
      // 1. Start loading the list
      setState(() {
        _futureLifts = _api.fetchPendingBagLifts(userId: userId);
      });

      // 2. CHECK IF WE HAVE A NOTIFICATION ID
      if (widget.highlightedId != null) {
        print("🪤 [Auto-Open] Notification ID received: '${widget.highlightedId}'");

        try {
          // A. Wait for the API List
          final list = await _futureLifts;
          print("🪤 [Auto-Open] List loaded. Items count: ${list.length}");

          // B. Debug: Print all IDs in the list to check for matches
          for (var item in list) {
            print("   -> List Item ID: '${item.id}'"); 
          }

          // C. Try to find the match
          final targetItem = list.firstWhere(
            (item) => item.id == widget.highlightedId,
            orElse: () => throw Exception("ID matches nothing in the list"),
          );

          print("🪤 [Auto-Open] ✅ MATCH FOUND! Opening dialog...");

          // D. Wait for UI to be ready
          if (!mounted) return;
          
          // E. OPEN THE DIALOG
          // We wrap it in a microtask to ensure the BuildContext is stable
          Future.microtask(() {
             _showVerificationDialog(targetItem);
          });

        } catch (e) {
          print("🪤 [Auto-Open] ❌ FAILURE: $e");
          
          // Show a visual error so you know it failed
          if(mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text("Could not open Notification Item: $e"), backgroundColor: Colors.red),
             );
          }
        }
      }
    } else {
      // Error handling for invalid User ID
      setState(() {
        _futureLifts = Future.value([]);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: Invalid User ID"), backgroundColor: Colors.red),
        );
      }
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

  // --- Helper for Labels ---
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
    return await showDialog<TechnicalSite>(
      context: context,
      builder: (context) => _ServerSiteSearchDialog(api: _api),
    );
  }

  Future<Dealer?> _showServerSearchDealerDialog() async {
    return await showDialog<Dealer>(
      context: context,
      builder: (context) => _ServerDealerSearchDialog(api: _api),
    );
  }

  // --- 📸 Verification Dialog ---
  void _showVerificationDialog(MasonBagLift item) {
    final bagCountController = TextEditingController(
      text: item.bagCount.toString(),
    );

    // Controllers for Manual Entry Fields
    final personNameController = TextEditingController();
    final personPhoneController = TextEditingController();
    final memoController = TextEditingController();

    TechnicalSite? selectedSite;
    Dealer? selectedDealer;

    File? _siteImageFile;
    String? _uploadedSiteImageUrl;
    bool _isUploadingImage = false;

    // We attempt to parse the string ID to an int here.
    final int? validApproverId = int.tryParse(widget.employee.id);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          Future<void> _pickAndUploadImage() async {
            try {
              final XFile? picked = await _picker.pickImage(
                source: ImageSource.camera,
                imageQuality: 60,
              );
              if (picked == null) return;

              setStateDialog(() {
                _siteImageFile = File(picked.path);
                _isUploadingImage = true;
              });

              final url = await _api.uploadImageToR2(_siteImageFile!);

              setStateDialog(() {
                _uploadedSiteImageUrl = url;
                _isUploadingImage = false;
              });
            } catch (e) {
              setStateDialog(() => _isUploadingImage = false);
              debugPrint("Image upload error: $e");
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
                  // 1. Correct Bag Count
                  _buildLabel("Verified Bag Count", isMandatory: true),
                  const SizedBox(height: 8),
                  TextField(
                    controller: bagCountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: _textDark),
                    decoration: _inputDecoration("Enter actual count"),
                  ),
                  const SizedBox(height: 16),

                  // 2. Dealer Selection (Searchable)
                  _buildLabel("Select Dealer", isMandatory: true),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final result = await _showServerSearchDealerDialog();
                      if (result != null) {
                        setStateDialog(() => selectedDealer = result);
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
                        border: Border.all(
                          color: selectedDealer == null
                              ? Colors.transparent
                              : _cardNavy.withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              selectedDealer?.name ?? "Tap to Search Dealer...",
                              style: TextStyle(
                                color: selectedDealer != null
                                    ? _textDark
                                    : Colors.grey,
                                fontWeight: selectedDealer != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.search, color: _textDark, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Link to Site (Searchable)
                  _buildLabel("Link to Site", isMandatory: true),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final result = await _showServerSearchSiteDialog();
                      if (result != null) {
                        setStateDialog(() {
                          selectedSite = result;
                          // AUTO-FILL Logic: If site has data, fill the manual fields
                          personNameController.text = result.concernedPerson;
                          personPhoneController.text = result.phoneNo;
                        });
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
                        border: Border.all(
                          color: selectedSite == null
                              ? Colors.transparent
                              : _cardNavy.withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              selectedSite?.siteName ?? "Tap to Search Site...",
                              style: TextStyle(
                                color: selectedSite != null
                                    ? _textDark
                                    : Colors.grey,
                                fontWeight: selectedSite != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.search, color: _textDark, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Key Person Details (Editable)
                  _buildLabel("Site Key Person Details"),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: personNameController,
                          style: const TextStyle(color: _textDark),
                          decoration: _inputDecoration("Name"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: personPhoneController,
                          style: const TextStyle(color: _textDark),
                          decoration: _inputDecoration("Phone"),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 5. Verification Photo
                  _buildLabel("Verification Photo (Site)"),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _isUploadingImage ? null : _pickAndUploadImage,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _inputFill,
                        border: Border.all(color: Colors.grey.shade300),
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
                                  color: _textGrey,
                                  size: 32,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Tap to Take Photo",
                                  style: TextStyle(
                                    color: _textGrey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                  if (_uploadedSiteImageUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: _accentGreen,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "Photo Uploaded",
                            style: TextStyle(
                              fontSize: 11,
                              color: _accentGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // 6. Remarks
                  _buildLabel("Remarks / Rejection Reason"),
                  const SizedBox(height: 8),
                  TextField(
                    controller: memoController,
                    style: const TextStyle(color: _textDark),
                    decoration: _inputDecoration("Enter notes..."),
                    maxLines: 2,
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
                  // 1. Validate ID before rejecting
                  if (validApproverId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Error: Invalid User ID ('${widget.employee.id}'). Cannot reject.",
                        ),
                        backgroundColor: _dangerRed,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context);

                  _updateStatus(
                    item.id,
                    'rejected',
                    memo: memoController.text,
                    approvedBy: validApproverId,
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
                onPressed: _isUploadingImage
                    ? null
                    : () {
                        // VALIDATION
                        if (selectedSite == null || selectedDealer == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Error: Site and Dealer are mandatory.",
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        if (validApproverId == null) {
                          // STOP HERE if ID is invalid
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Error: Your User ID ('${widget.employee.id}') is not a valid number. Cannot approve.",
                              ),
                              backgroundColor: _dangerRed,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                          return;
                        }

                        Navigator.pop(context);

                        // CALL API WITH ALL NEW FIELDS
                        _updateStatus(
                          item.id,
                          'approved',
                          bagCount: int.tryParse(bagCountController.text),
                          siteId: selectedSite?.id,
                          dealerId: selectedDealer?.id,
                          keyPersonName: personNameController.text,
                          keyPersonPhone: personPhoneController.text,
                          memo: memoController.text,
                          verificationSiteImageUrl: _uploadedSiteImageUrl,
                          approvedBy: validApproverId,
                        );
                      },
                child: const Text(
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

  Future<void> _updateStatus(
    String id,
    String status, {
    int? bagCount,
    String? siteId,
    String? dealerId,
    String? keyPersonName,
    String? keyPersonPhone,
    String? memo,
    String? verificationSiteImageUrl,
    required int approvedBy, // Made required
  }) async {
    setState(() => _isProcessing = true);
    try {
      await _api.updateBagLiftStatus(
        id,
        status,
        bagCount: bagCount,
        siteId: siteId,
        dealerId: dealerId,
        siteKeyPersonName: keyPersonName,
        siteKeyPersonPhone: keyPersonPhone,
        memo: memo,
        verificationSiteImageUrl: verificationSiteImageUrl,
        approvedBy: approvedBy,
        approvedAt: DateTime.now().toIso8601String(), // Send Current Time
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lift $status successfully"),
            backgroundColor: status == 'approved' ? _accentGreen : _dangerRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: _dangerRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
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

class _ServerSiteSearchDialog extends StatefulWidget {
  final ApiService api;
  const _ServerSiteSearchDialog({required this.api});

  @override
  State<_ServerSiteSearchDialog> createState() =>
      _ServerSiteSearchDialogState();
}

class _ServerSiteSearchDialogState extends State<_ServerSiteSearchDialog> {
  List<TechnicalSite> _sites = [];
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
      final results = await widget.api.fetchTechnicalSites(
        search: query,
        limit: 20,
      );
      if (mounted) {
        setState(() {
          _sites = results;
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
        "Select Site",
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
                hintText: "Search site...",
                hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
                filled: true,
                fillColor: Color(0xFFF9FAFB),
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
                  : _sites.isEmpty
                  ? const Center(
                      child: Text(
                        "No sites found",
                        style: TextStyle(color: Color(0xFF6B7280)),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _sites.length,
                      separatorBuilder: (ctx, i) =>
                          const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      itemBuilder: (context, index) {
                        final site = _sites[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            site.siteName,
                            style: const TextStyle(
                              color: Color(0xFF111827),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            site.address,
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                            ),
                          ),
                          onTap: () => Navigator.pop(context, site),
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
                fillColor: Color(0xFFF9FAFB),
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
