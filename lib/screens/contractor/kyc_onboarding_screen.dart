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
  final bool _useRealKyc = true; // <-- YOUR SWITCH

  final _formKey = GlobalKey<FormState>();

  late Mason _localMason; // The local model we'll build

  // KYC fields
  final _aadhaarController = TextEditingController();
  final _panController = TextEditingController();
  final _voterController = TextEditingController();
  final _remarkController = TextEditingController();

  // --- TSO is OPTIONAL and manually entered as a string placeholder ---
  final TextEditingController _tsoIdController = TextEditingController(); // Manual input for TSO ID

  // file pickers
  File? _aadhaarFrontFile;
  File? _aadhaarBackFile;
  File? _panFile;
  File? _voterFile;

  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _localMason = widget.mason;
  }

  @override
  void dispose() {
    _aadhaarController.dispose();
    _panController.dispose();
    _voterController.dispose();
    _remarkController.dispose();
    _tsoIdController.dispose(); 
    super.dispose();
  }

  // --- Image Pick Functions ---
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
      final XFile? picked =
          await _picker.pickImage(source: source, imageQuality: 80);
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failed to pick image')));
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Upload failed for ${f.path.split('/').last}. Please try again.')),
      );
      throw Exception('Upload failed');
    }
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  // --- MODIFIED SUBMIT FUNCTION ---
  Future<void> _submitKyc() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) {
      _toast('Please fill in all required fields.');
      return;
    }
    
    // --- TSO IS OPTIONAL, NO VALIDATION REQUIRED ---

    setState(() => _isSubmitting = true);

    // --- Bypass Logic ---
    if (!_useRealKyc) {
      try {
        await Future.delayed(const Duration(milliseconds: 1500));
        _toast('DEBUG BYPASS: KYC submitted successfully.');

        // Update local mason to navigate correctly
        final completeMason = _localMason.copyWith(
          kycStatus: 'pending',
          userId: _tsoIdController.text.isNotEmpty ? int.tryParse(_tsoIdController.text) : null,
          kycDocumentName:
              _aadhaarController.text.isNotEmpty ? 'Aadhaar Card' : null,
          kycDocumentIdNum: _aadhaarController.text.trim(),
        );

        if (mounted) {
          // Navigate to home, which will route to pending screen
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/contractor_home',
            (_) => false,
            arguments: completeMason,
          );
        }
      } catch (e) {
        debugPrint('Bypass submit error: $e');
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
      return; // <-- IMPORTANT: Exit function here
    }
    // --- End Bypass Logic ---

    // --- Real Logic (YOUR FLOW) ---
    try {
      // 1) Upload files (if any).
      _toast('Uploading images...');
      final aadhaarFrontUrl = await _uploadIfPresent(_aadhaarFrontFile);
      final aadhaarBackUrl = await _uploadIfPresent(_aadhaarBackFile);
      final panUrl = await _uploadIfPresent(_panFile);
      final voterUrl = await _uploadIfPresent(_voterFile);

      // 2) Build documents object
      final Map<String, String> documents = {};
      if (aadhaarFrontUrl != null) documents['aadhaarFrontUrl'] = aadhaarFrontUrl;
      if (aadhaarBackUrl != null) documents['aadhaarBackUrl'] = aadhaarBackUrl;
      if (panUrl != null) documents['panUrl'] = panUrl;
      if (voterUrl != null) documents['voterUrl'] = voterUrl;

      // 3) (YOUR FLOW) Fill up the local Mason model
      final completeMason = _localMason.copyWith(
        // Use Aadhaar as the primary doc name/id if present
        kycDocumentName:
            _aadhaarController.text.isNotEmpty ? 'Aadhaar Card' : null,
        kycDocumentIdNum: _aadhaarController.text.trim(),
        // --- TSO IS OPTIONAL: Try to parse, otherwise null ---
        userId: _tsoIdController.text.isNotEmpty ? int.tryParse(_tsoIdController.text) : null,
        kycStatus: 'pending', // <-- SET STATUS TO PENDING
      );

      _toast('Submitting details...');
      dev.log('Submitting Complete Mason: ${completeMason.toJson()}',
          name: 'KYC');

      // 4) (YOUR FLOW) Make the TWO API calls in parallel
      final results = await Future.wait([
        // Call 1: POST /api/masons
        // FIX: The payload is copied, and the 'id' is removed for the POST request
        () {
          final payload = completeMason.toJson();
          payload.remove('id'); 
          return _api.createMason(Mason.fromJson(payload)); 
        }(),

        // Call 2: POST /api/kyc-submissions
        _api.submitKyc(
          masonId: completeMason.id!, 
          aadhaarNumber: _aadhaarController.text.trim(),
          panNumber: _panController.text.trim(),
          voterIdNumber: _voterController.text.trim(),
          documents: documents,
          remark: _remarkController.text.trim(),
        ),
      ]);

      // Both calls succeeded. Get the final mason from Call 1
      final createdMason = results[0] as Mason;

      _toast('KYC Submitted! Awaiting approval.');

      // 5) Navigate to the home page (which will show the pending banner)
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/contractor_home',
          (_) => false,
          arguments: createdMason, // Pass the final, complete Mason object
        );
      }
    } catch (e, st) {
      // 6) Handle failure
      dev.log('KYC submit error: $e\n$st', name: 'KYC');
      _toast('Failed to submit KYC: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // --- BUILD METHOD ---
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
              // header
              CircleAvatar(
                  radius: 40,
                  child: Text(
                      _localMason.name.isNotEmpty ? _localMason.name[0] : '?')),
              const SizedBox(height: 8),
              Text(_localMason.name,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(_localMason.phoneNumber,
                  style: Theme.of(context).textTheme.bodyMedium),

              const SizedBox(height: 16),

              // Aadhaar
              TextFormField(
                controller: _aadhaarController,
                decoration: const InputDecoration(
                    labelText: 'Aadhaar Number (optional)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v != null && v.isNotEmpty && v.length > 20)
                    return 'Max 20 chars';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              _fileTile('Aadhaar Front', _aadhaarFrontFile,
                  () => _showPickOptions('aadhaarFront')),
              const SizedBox(height: 8),
              _fileTile('Aadhaar Back', _aadhaarBackFile,
                  () => _showPickOptions('aadhaarBack')),
              const SizedBox(height: 12),

              // PAN
              TextFormField(
                controller: _panController,
                decoration:
                    const InputDecoration(labelText: 'PAN Number (optional)'),
                textCapitalization: TextCapitalization.characters,
                validator: (v) {
                  if (v != null && v.isNotEmpty && v.length > 20)
                    return 'Max 20 chars';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              _fileTile('PAN Document', _panFile, () => _showPickOptions('pan')),
              const SizedBox(height: 12),

              // Voter
              TextFormField(
                controller: _voterController,
                decoration:
                    const InputDecoration(labelText: 'Voter ID (optional)'),
                validator: (v) {
                  if (v != null && v.isNotEmpty && v.length > 20)
                    return 'Max 20 chars';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              _fileTile(
                  'Voter Document', _voterFile, () => _showPickOptions('voter')),
              const SizedBox(height: 12),

              // --- ⬇️ TSO ID (OPTIONAL MANUAL INPUT) ⬇️ ---
              const Divider(),
              const SizedBox(height: 16),
              Text('TSO Agent ID (Optional)',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),

              TextFormField(
                controller: _tsoIdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'TSO User ID (If known)',
                  hintText: 'e.g., 42',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_pin),
                ),
                validator: (v) {
                  if (v != null && v.isNotEmpty && int.tryParse(v) == null) {
                    return 'Must be a number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // --- ⬆️ END TSO ID ⬆️ ---

              // remark
              TextFormField(
                controller: _remarkController,
                decoration:
                    const InputDecoration(labelText: 'Remark (optional)'),
                maxLines: 3,
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitKyc,
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
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