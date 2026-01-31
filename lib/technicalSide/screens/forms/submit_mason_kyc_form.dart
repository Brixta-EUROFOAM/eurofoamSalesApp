import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/technicalSide/models/mason_pc_model.dart';
import 'package:image_picker/image_picker.dart';

class SubmitMasonKycForm extends StatefulWidget {
  final Mason? mason; // 👈 Made Nullable: Null = New Mason Mode
  final String tsoId;
  const SubmitMasonKycForm({super.key, this.mason, required this.tsoId});

  @override
  State<SubmitMasonKycForm> createState() => _SubmitMasonKycFormState();
}

class _SubmitMasonKycFormState extends State<SubmitMasonKycForm> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();
  bool _isSubmitting = false;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  // Text Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController(); // 👈 Added Phone Controller
  final _aadhaarController = TextEditingController();
  final _panController = TextEditingController();

  // Document URLs (Stored after upload)
  String? _aadhaarFrontUrl;
  String? _aadhaarBackUrl;
  String? _panUrl;

  @override
  void initState() {
    super.initState();
    // ✅ Logic: Only pre-fill if editing an existing mason
    if (widget.mason != null) {
      _nameController.text = widget.mason!.name;
      _phoneController.text = widget.mason!.phoneNumber; 
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _aadhaarController.dispose();
    _panController.dispose();
    super.dispose();
  }

  // --- 📸 IMAGE HANDLING ---
  void _captureAndUpload(String docType) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF0F172A)),
              title: const Text("Take Photo"),
              onTap: () async {
                Navigator.pop(ctx);
                final String? path = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const _InternalKycCamera(),
                  ),
                );
                if (path != null) _processUpload(File(path), docType);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Color(0xFF0F172A),
              ),
              title: const Text("Choose from Gallery"),
              onTap: () async {
                Navigator.pop(ctx);
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (image != null) _processUpload(File(image.path), docType);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processUpload(File file, String docType) async {
    setState(() => _isUploading = true);

    try {
      final url = await _api.uploadImageToR2(file);

      setState(() {
        if (docType == 'aadhaarFront') _aadhaarFrontUrl = url;
        if (docType == 'aadhaarBack') _aadhaarBackUrl = url;
        if (docType == 'pan') _panUrl = url;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Image uploaded successfully!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Upload Failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // --- 🚀 SUBMIT LOGIC (UPDATED) ---
  Future<void> _submitKyc() async {
    if (!_formKey.currentState!.validate()) return;

    if (_aadhaarFrontUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Aadhaar Front Image is required"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String masonId;

      // 🟢 1. LOGIC: NEW vs EXISTING
      if (widget.mason == null) {
        // A. Create New Placeholder Mason First (This gets us the ID)
        final newId = await _api.createMasonPlaceholder(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          tsoId: widget.tsoId,
        );
        
        if (newId == null) throw Exception("Failed to create new mason record");
        masonId = newId;
      } else {
        // B. Use Existing Mason ID
        masonId = widget.mason!.id;
      }

      // 🟢 2. SUBMIT KYC (Payload construction remains the same)
      final payload = {
        "masonId": masonId,
        "name": _nameController.text.trim(),
        "aadhaarNumber": _aadhaarController.text.trim(),
        "panNumber": _panController.text.trim(),
        "remark": "KYC Submitted by TSO via App",
        "documents": {
          if (_aadhaarFrontUrl != null) "aadhaarFrontUrl": _aadhaarFrontUrl,
          if (_aadhaarBackUrl != null) "aadhaarBackUrl": _aadhaarBackUrl,
          if (_panUrl != null) "panUrl": _panUrl,
        },
      };

      final response = await _api.submitMasonKyc(payload);

      // On Success, just show snackbar and close (NO QR DIALOG)
      if (response['success'] == true) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("KYC Approved & Credentials Generated!"),
            backgroundColor: Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pop(context, true); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // --- UI WIDGETS ---
  Widget _buildDocPicker(String label, String? url, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: _isUploading ? null : onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: url != null ? Colors.green : Colors.grey[300]!,
                ),
                image: url != null
                    ? DecorationImage(
                        image: NetworkImage(url),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: url == null
                  ? Center(
                      child: Icon(
                        Icons.add_a_photo_rounded,
                        color: Colors.grey[400],
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine mode
    final bool isCreating = widget.mason == null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          isCreating ? "Onboard New Mason" : "Complete KYC", // 👈 Dynamic Title
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. PERSONAL INFO ---
              const Text(
                "Identity Details",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration("Mason Full Name", Icons.person),
                validator: (v) => v!.trim().isEmpty ? "Name is required" : null,
              ),
              const SizedBox(height: 12),

              // 🟢 PHONE FIELD (Editable only if Creating)
              TextFormField(
                controller: _phoneController,
                readOnly: !isCreating, 
                keyboardType: TextInputType.phone,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  // If existing, grey out text to show it's locked
                  color: isCreating ? Colors.black : Colors.grey, 
                ),
                decoration: _inputDecoration("Phone Number", Icons.phone).copyWith(
                  fillColor: isCreating ? Colors.white : Colors.grey[100],
                ),
                validator: (v) => v!.trim().length < 10 ? "Valid phone required" : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _aadhaarController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(
                  "Aadhaar Number",
                  Icons.credit_card,
                ),
                validator: (v) => v!.trim().isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 12),

              // TextFormField(
              //   controller: _panController,
              //   textCapitalization: TextCapitalization.characters,
              //   decoration: _inputDecoration("PAN Number", Icons.badge),
              // ),
              const SizedBox(height: 32),

              // --- 2. DOCUMENTS ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Documents",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (_isUploading)
                    const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  _buildDocPicker(
                    "Aadhaar Front",
                    _aadhaarFrontUrl,
                    () => _captureAndUpload('aadhaarFront'),
                  ),
                  const SizedBox(width: 12),
                  _buildDocPicker(
                    "Aadhaar Back",
                    _aadhaarBackUrl,
                    () => _captureAndUpload('aadhaarBack'),
                  ),
                  const SizedBox(width: 12),
                  // _buildDocPicker("PAN Card", _panUrl, () => _captureAndUpload('pan')),
                ],
              ),

              const SizedBox(height: 40),

              // --- 3. SUBMIT BUTTON ---
              ElevatedButton(
                onPressed: (_isSubmitting || _isUploading) ? null : _submitKyc,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        isCreating ? "CREATE & APPROVE" : "APPROVE & GENERATE ID", // 👈 Dynamic Text
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey[600]),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 🟢 INTERNAL CAMERA WIDGET (Unchanged)
// -----------------------------------------------------------------------------
class _InternalKycCamera extends StatefulWidget {
  const _InternalKycCamera();
  @override
  State<_InternalKycCamera> createState() => _InternalKycCameraState();
}

class _InternalKycCameraState extends State<_InternalKycCamera> {
  CameraController? _controller;
  Future<void>? _initFuture;
  List<CameraDescription> _cameras = [];
  int _idx = 0;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) _initCamera(_cameras[0]);
    } catch (e) {
      debugPrint("Cam error: $e");
    }
  }

  Future<void> _initCamera(CameraDescription desc) async {
    if (_controller != null) await _controller!.dispose();
    _controller = CameraController(
      desc,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    setState(() {
      _initFuture = _controller!.initialize();
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              _controller != null) {
            return Stack(
              children: [
                Center(child: CameraPreview(_controller!)),
                SafeArea(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 30),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 30,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          InkWell(
                            onTap: () async {
                              final img = await _controller!.takePicture();
                              if(mounted) Navigator.pop(context, img.path);
                            },
                            child: Container(
                              height: 70,
                              width: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                color: Colors.white24,
                              ),
                            ),
                          ),
                          if (_cameras.length > 1)
                            IconButton(
                              icon: const Icon(
                                Icons.flip_camera_ios,
                                color: Colors.white,
                                size: 30,
                              ),
                              onPressed: () {
                                _idx = (_idx + 1) % _cameras.length;
                                _initCamera(_cameras[_idx]);
                              },
                            )
                          else
                            const SizedBox(width: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        },
      ),
    );
  }
}