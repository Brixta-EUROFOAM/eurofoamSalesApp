// lib/screens/contractor/kyc_onboarding_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:developer' as dev;

import 'package:assetarchiverflutter/models/mason_model.dart';
import 'package:assetarchiverflutter/api/api_service.dart';

class KycOnboardingScreen extends StatefulWidget {
  final Mason mason;
  const KycOnboardingScreen({super.key, required this.mason});

  @override
  State<KycOnboardingScreen> createState() => _KycOnboardingScreenState();
}

class _KycOnboardingScreenState extends State<KycOnboardingScreen> {
  // This switch is still here from your old file
  final bool _useRealKyc = true;

  final _formKey = GlobalKey<FormState>();
  late Mason _localMason;
  final _api = ApiService();

  // --- Form Controllers ---
  final _aadhaarController = TextEditingController();
  final _panController = TextEditingController();
  final _voterController = TextEditingController();
  final _remarkController = TextEditingController();

  // --- TSO Autocomplete State ---
  int? _selectedTsoId; // The ID of the TSO we select
  late Future<List<TsoUser>> _tsoListFuture;

  File? _aadhaarFrontFile;
  File? _aadhaarBackFile;
  File? _panFile;
  File? _voterFile;

  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _localMason = widget.mason;

    // --- ✅ NEW: Listen to TSO search field ---
    _tsoListFuture = _api.searchTso("");
    // ---
  }

  @override
  void dispose() {
    _aadhaarController.dispose();
    _panController.dispose();
    _voterController.dispose();
    _remarkController.dispose();

    super.dispose();
  }

  // --- (Image picking functions are unchanged) ---
  Future<void> _showPickOptions(String which) async {
    FocusScope.of(context).unfocus();
    await showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickFile(ImageSource.camera, which);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickFile(ImageSource.gallery, which);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickFile(ImageSource source, String which) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (picked == null) return;
      setState(() {
        final file = File(picked.path);
        switch (which) {
          case 'aadhaarFront':
            _aadhaarFrontFile = file;
            break;
          case 'aadhaarBack':
            _aadhaarBackFile = file;
            break;
          case 'pan':
            _panFile = file;
            break;
          case 'voter':
            _voterFile = file;
            break;
        }
      });
    } catch (e) {
      debugPrint('Pick file error: $e');
      _toast('Failed to pick image');
    }
  }

  Widget _fileTile(String label, File? f, VoidCallback onPick) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        if (f != null) ...[
          SizedBox(
            width: 56,
            height: 56,
            child: Image.file(f, fit: BoxFit.cover),
          ),
          const SizedBox(width: 8),
        ],
        ElevatedButton(
          onPressed: onPick,
          child: Text(f == null ? 'Pick' : 'Replace'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
        ),
      ],
    );
  }

  Future<String?> _uploadIfPresent(File? f) async {
    if (f == null) return null;
    try {
      final publicUrl = await _api.uploadImageToR2(f);
      return publicUrl;
    } catch (e) {
      debugPrint('Upload failed: $e');
      _toast('Upload failed for ${f.path.split('/').last}. Please try again.');
      throw Exception('Upload failed');
    }
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }
  // --- (End of unchanged image functions) ---

  // --- ✅ NEW: THE CORRECT SEQUENTIAL SUBMIT LOGIC ---
  Future<void> _submitKyc() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) {
      _toast('Please fix the errors in the required fields.');
      return;
    }

    // --- 1. Check if at least one doc number OR one image is present ---
    final bool hasDocNumber =
        _aadhaarController.text.isNotEmpty ||
        _panController.text.isNotEmpty ||
        _voterController.text.isNotEmpty;

    final bool hasDocImage =
        _aadhaarFrontFile != null || _panFile != null || _voterFile != null;

    if (!hasDocNumber && !hasDocImage) {
      _toast('Please provide at least one document (ID number or image).');
      return;
    }

    setState(() => _isSubmitting = true);

    // --- Bypass Logic (Updated to use new TSO ID) ---
    if (!_useRealKyc) {
      try {
        await Future.delayed(const Duration(milliseconds: 1500));
        _toast('DEBUG BYPASS: KYC submitted successfully.');

        final completeMason = _localMason.copyWith(
          kycStatus: 'pending',
          userId: _selectedTsoId, // Use selected ID
          kycDocumentName: _aadhaarController.text.isNotEmpty
              ? 'Aadhaar Card'
              : null,
          kycDocumentIdNum: _aadhaarController.text.trim(),
        );

        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/contractor_nav', // <-- Go to the Nav Shell
            (_) => false,
            arguments: completeMason,
          );
        }
      } catch (e) {
        debugPrint('Bypass submit error: $e');
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
      return;
    }
    // --- End Bypass Logic ---

    // --- 2. REAL SEQUENTIAL API LOGIC ---
    try {
      _toast('Uploading images...');
      // Step 2a: Upload all images in parallel
      final [
        aadhaarFrontUrl,
        aadhaarBackUrl,
        panUrl,
        voterUrl,
      ] = await Future.wait([
        _uploadIfPresent(_aadhaarFrontFile),
        _uploadIfPresent(_aadhaarBackFile),
        _uploadIfPresent(_panFile),
        _uploadIfPresent(_voterFile),
      ]);

      // Step 2b: Collect image URLs
      final Map<String, String> documents = {};
      if (aadhaarFrontUrl != null)
        documents['aadhaarFrontUrl'] = aadhaarFrontUrl;
      if (aadhaarBackUrl != null) documents['aadhaarBackUrl'] = aadhaarBackUrl;
      if (panUrl != null) documents['panUrl'] = panUrl;
      if (voterUrl != null) documents['voterUrl'] = voterUrl;

      // Step 2c: Prepare the payload to UPDATE the mason
      // This is correct because the Mason is created during login.
      _toast('Updating profile...');
      final masonUpdatePayload = <String, dynamic>{
        'kycStatus': 'pending', // Set status to pending
        'userId': _selectedTsoId, // Assign the selected TSO ID
        'kycDocumentName': _aadhaarController.text.isNotEmpty
            ? 'Aadhaar Card'
            : null,
        'kycDocumentIdNum': _aadhaarController.text.trim().isEmpty
            ? null
            : _aadhaarController.text.trim(),
      };

      // This is the first call: UPDATE the Mason record
      final updatedMason = await _api.updateMason(
        _localMason.id!, // Use the ID of the mason passed into the widget
        masonUpdatePayload,
      );

      // Step 2d: Prepare the payload for the KYC submission task
      _toast('Submitting for review...');

      // This is the second call: CREATE the review task
      await _api.submitKyc(
        masonId: _localMason.id!, // Use the same mason ID
        aadhaarNumber: _aadhaarController.text.trim(),
        panNumber: _panController.text.trim(),
        voterIdNumber: _voterController.text.trim(),
        documents: documents,
        remark: _remarkController.text.trim(),
      );

      _toast('KYC Submitted! Awaiting approval.');

      if (mounted) {
        // Navigate to the Nav Shell, which will now show the 'pending' screen
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/contractor_nav',
          (_) => false,
          arguments: updatedMason, // Pass the *updated* mason object
        );
      }
    } catch (e, st) {
      dev.log('KYC submit error: $e\n$st', name: 'KYC');
      _toast('Failed to submit KYC: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KYC Submission'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- (Header is unchanged) ---
              CircleAvatar(
                radius: 40,
                child: Text(
                  _localMason.name.isNotEmpty ? _localMason.name[0] : '?',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _localMason.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _localMason.phoneNumber,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

              // --- (Document fields are unchanged) ---
              TextFormField(
                controller: _aadhaarController,
                decoration: const InputDecoration(
                  labelText: 'Aadhaar Number (optional)',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v != null && v.isNotEmpty && v.length > 20) {
                    return 'Max 20 chars';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              _fileTile(
                'Aadhaar Front',
                _aadhaarFrontFile,
                () => _showPickOptions('aadhaarFront'),
              ),
              const SizedBox(height: 8),
              _fileTile(
                'Aadhaar Back',
                _aadhaarBackFile,
                () => _showPickOptions('aadhaarBack'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _panController,
                decoration: const InputDecoration(
                  labelText: 'PAN Number (optional)',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (v) {
                  if (v != null && v.isNotEmpty && v.length > 20) {
                    return 'Max 20 chars';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              _fileTile(
                'PAN Document',
                _panFile,
                () => _showPickOptions('pan'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _voterController,
                decoration: const InputDecoration(
                  labelText: 'Voter ID (optional)',
                ),
                validator: (v) {
                  if (v != null && v.isNotEmpty && v.length > 20) {
                    return 'Max 20 chars';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              _fileTile(
                'Voter Document',
                _voterFile,
                () => _showPickOptions('voter'),
              ),
              const SizedBox(height: 12),

              // --- ✅ NEW: TSO AGENT ID (UPGRADED to Dropdown) ---
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'TSO Agent ID (Optional)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),

              FutureBuilder<List<TsoUser>>(
                future: _tsoListFuture,
                builder: (context, snapshot) {
                  // Loading state
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  // Error state
                  if (snapshot.hasError || !snapshot.hasData) {
                    return TextFormField(
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Could not load TSOs',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.error_outline,
                          color: Colors.red,
                        ),
                      ),
                    );
                  }

                  // Success state
                  final tsoList = snapshot.data!;

                  return DropdownButtonFormField<int>(
                    value: _selectedTsoId,
                    hint: const Text('Select TSO (If known)'),
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_pin),
                    ),
                    // Allow clearing the selection
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text(
                          'None',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                      ...tsoList.map((TsoUser tso) {
                        return DropdownMenuItem<int>(
                          value: tso.id,
                          child: Text(tso.name),
                        );
                      }),
                    ],
                    onChanged: (int? newValue) {
                      setState(() {
                        _selectedTsoId = newValue;
                      });
                    },
                    validator: (v) {
                      // No validation needed for an optional field
                      return null;
                    },
                  );
                },
              ),

              // --- ✅ END OF TSO UPGRADE ---
              const SizedBox(height: 24),
              TextFormField(
                controller: _remarkController,
                decoration: const InputDecoration(
                  labelText: 'Remark (optional)',
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitKyc,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('SUBMIT KYC'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
