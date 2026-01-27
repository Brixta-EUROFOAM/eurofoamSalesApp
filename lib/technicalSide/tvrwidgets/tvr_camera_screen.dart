// lib/technicalSide/widgets/tvr_camera_screen.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class TvrCameraScreen extends StatefulWidget {
  const TvrCameraScreen({super.key});

  @override
  State<TvrCameraScreen> createState() => _TvrCameraScreenState();
}

class _TvrCameraScreenState extends State<TvrCameraScreen> {
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