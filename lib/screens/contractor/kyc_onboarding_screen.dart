// lib/screens/contractor/kyc_onboarding_screen.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import 'package:assetarchiverflutter/models/mason_model.dart';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'kyc_pending_screen.dart'; // <-- ADDED: ensure this file exists

class KycOnboardingScreen extends StatefulWidget {
  final Mason mason;
  const KycOnboardingScreen({super.key, required this.mason});

  @override
  State<KycOnboardingScreen> createState() => _KycOnboardingScreenState();
}

class _KycOnboardingScreenState extends State<KycOnboardingScreen> {
  // --- ⬇️ START NEW BYPASS SWITCH ⬇️ ---
  //
  // Set this to 'true' to run the real R2 uploads and API call.
  // Set this to 'false' to instantly bypass and "mock" a successful submission.
  //
  final bool _useRealKyc = false; // <-- ❄️ YOUR NEW SWITCH ❄️
  //
  // --- ⬆️ END NEW BYPASS SWITCH ⬆️ ---

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  // KYC fields
  final _aadhaarController = TextEditingController();
  final _panController = TextEditingController();
  final _voterController = TextEditingController();
  final _remarkController = TextEditingController();

  // file pickers
  File? _aadhaarFrontFile;
  File? _aadhaarBackFile;
  File? _panFile;
  File? _voterFile;

  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();
  final ApiService _api = ApiService();
  static const String _baseUrl = 'https://myserverbymycoco.onrender.com';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.mason.name);
    _phoneController = TextEditingController(text: widget.mason.phoneNumber);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _aadhaarController.dispose();
    _panController.dispose();
    _voterController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(ImageSource source, String which) async {
    try {
      final XFile? picked = await _picker.pickImage(source: source, imageQuality: 80);
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to pick image')));
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
      // Use your existing ApiService uploader so you don't reinvent signed-URL hell
      final publicUrl = await _api.uploadImageToR2(f);
      return publicUrl;
    } catch (e) {
      debugPrint('Upload failed: $e');
      return null;
    }
  }

  Future<void> _submitKyc() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    if (widget.mason.id == null || widget.mason.id!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Mason ID. Cannot submit KYC.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // --- ⬇️ START BYPASS MODIFICATION ⬇️ ---
    if (!_useRealKyc) {
      try {
        // 1. Simulate a network delay
        await Future.delayed(const Duration(milliseconds: 1500));
        
        // 2. Mock a successful response
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('DEBUG BYPASS: KYC submitted successfully.')),
        );
        
        // 3. --- ✅ THE FIX ---
        // Replace the 'pop' with 'pushReplacement' to go to the pending screen
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const KycPendingScreen()),
          );
        }
      } catch (e) {
        debugPrint('Bypass submit error: $e');
      } finally {
        // This will still run, but the screen will likely be disposed after pushReplacement
        if (mounted) setState(() => _isSubmitting = false);
      }
      return; // <-- IMPORTANT: Exit function here to skip real logic
    }
    // --- ⬆️ END BYPASS MODIFICATION ⬆️ ---

    // --- ⬇️ YOUR REAL LOGIC (Runs only if _useRealKyc is true) ⬇️ ---
    try {
      // 1) Upload files (if any). Uploads happen sequentially to keep things simple.
      final aadhaarFrontUrl = await _uploadIfPresent(_aadhaarFrontFile);
      final aadhaarBackUrl = await _uploadIfPresent(_aadhaarBackFile);
      final panUrl = await _uploadIfPresent(_panFile);
      final voterUrl = await _uploadIfPresent(_voterFile);

      // 2) Build documents object only with keys that exist
      final Map<String, String> documents = {};
      if (aadhaarFrontUrl != null) documents['aadhaarFrontUrl'] = aadhaarFrontUrl;
      if (aadhaarBackUrl != null) documents['aadhaarBackUrl'] = aadhaarBackUrl;
      if (panUrl != null) documents['panUrl'] = panUrl;
      if (voterUrl != null) documents['voterUrl'] = voterUrl;

      // 3) Build request body
      final body = <String, dynamic>{
        'masonId': widget.mason.id,
        'aadhaarNumber': _aadhaarController.text.trim().isEmpty ? null : _aadhaarController.text.trim(),
        'panNumber': _panController.text.trim().isEmpty ? null : _panController.text.trim(),
        'voterIdNumber': _voterController.text.trim().isEmpty ? null : _voterController.text.trim(),
        'documents': documents.isEmpty ? null : documents,
        'remark': _remarkController.text.trim().isEmpty ? null : _remarkController.text.trim(),
      }..removeWhere((k, v) => v == null);

      // 4) POST to your kyc-submissions route
      final url = Uri.parse('$_baseUrl/api/kyc-submissions');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 60));

      final jsonData = jsonDecode(response.body);
      if (response.statusCode == 201 && jsonData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('KYC submitted and pending approval.')),
        );
        // Navigate to pending screen instead of popping the last route
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const KycPendingScreen()),
          );
        }
      } else {
        final err = jsonData['error'] ?? 'Unknown server error';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('KYC failed: $err')));
      }
    } catch (e, st) {
      debugPrint('KYC submit error: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to submit KYC.')));
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
            children: [
              // header
              CircleAvatar(radius: 40, child: Text(widget.mason.name.isNotEmpty ? widget.mason.name[0] : '?')),
              const SizedBox(height: 8),
              Text(widget.mason.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(widget.mason.phoneNumber, style: Theme.of(context).textTheme.bodyMedium),

              const SizedBox(height: 16),

              // Aadhaar
              TextFormField(
                controller: _aadhaarController,
                decoration: const InputDecoration(labelText: 'Aadhaar Number (optional)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v != null && v.isNotEmpty && v.length > 20) return 'Max 20 chars';
                  return null;
                },
              ),
              const SizedBox(height: 8),

              _fileTile('Aadhaar Front', _aadhaarFrontFile, () => _pickFile(ImageSource.gallery, 'aadhaarFront')),
              const SizedBox(height: 8),
              _fileTile('Aadhaar Back', _aadhaarBackFile, () => _pickFile(ImageSource.gallery, 'aadhaarBack')),
              const SizedBox(height: 12),

              // PAN
              TextFormField(
                controller: _panController,
                decoration: const InputDecoration(labelText: 'PAN Number (optional)'),
                textCapitalization: TextCapitalization.characters,
                validator: (v) {
                  if (v != null && v.isNotEmpty && v.length > 20) return 'Max 20 chars';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              _fileTile('PAN Document', _panFile, () => _pickFile(ImageSource.gallery, 'pan')),
              const SizedBox(height: 12),

              // Voter
              TextFormField(
                controller: _voterController,
                decoration: const InputDecoration(labelText: 'Voter ID (optional)'),
                validator: (v) {
                  if (v != null && v.isNotEmpty && v.length > 20) return 'Max 20 chars';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              _fileTile('Voter Document', _voterFile, () => _pickFile(ImageSource.gallery, 'voter')),
              const SizedBox(height: 12),

              // remark
              TextFormField(
                controller: _remarkController,
                decoration: const InputDecoration(labelText: 'Remark (optional)'),
                maxLines: 3,
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitKyc,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: _isSubmitting ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('SUBMIT KYC'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
