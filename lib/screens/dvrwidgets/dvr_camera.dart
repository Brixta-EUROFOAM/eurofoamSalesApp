// lib/screens/dvrwidgets/dvr_camera.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 🔥 ADDED FOR HAPTICS
import 'package:camera/camera.dart';
import 'package:flutter_animate/flutter_animate.dart'; // 🔥 ADDED FOR ANIMATIONS

class DvrCameraScreen extends StatefulWidget {
  const DvrCameraScreen({super.key});

  @override
  State<DvrCameraScreen> createState() => _DvrCameraScreenState();
}

// 🚀 ADDED WidgetsBindingObserver for Lifecycle Management
class _DvrCameraScreenState extends State<DvrCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeFuture;
  bool _isTakingPicture = false;

  List<CameraDescription> _cameras = [];
  int _selectedCameraIdx = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Register lifecycle observer
    _setupCamera();
  }

  // 🚀 ZERO BATTERY DRAIN: Kills camera if app goes to background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // Free up the camera hardware and memory when minimized
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // Re-initialize when the app is brought back
      _initCamera(cameraController.description);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Clean up observer
    _controller?.dispose(); // 🔥 Release GPU buffers
    super.dispose();
  }

  // ------------------------------------------------------------
  // 🎥 CAMERA SETUP
  // ------------------------------------------------------------
  Future<void> _setupCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      _selectedCameraIdx = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );

      if (_selectedCameraIdx == -1) _selectedCameraIdx = 0;

      _initCamera(_cameras[_selectedCameraIdx]);
    } catch (e) {
      debugPrint("Camera setup error: $e");
    }
  }

  Future<void> _initCamera(CameraDescription description) async {
    await _controller?.dispose();

    _controller = CameraController(
      description,
      ResolutionPreset.medium, // 🚀 RAM SAFE: Medium is perfect for API uploads
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    setState(() {
      _initializeFuture = _controller!.initialize();
    });
  }

  void _toggleCamera() {
    if (_cameras.length < 2) return;
    HapticFeedback.lightImpact(); // Premium feel
    _selectedCameraIdx = (_selectedCameraIdx + 1) % _cameras.length;
    _initCamera(_cameras[_selectedCameraIdx]);
  }

  // ------------------------------------------------------------
  // 📸 TAKE SINGLE PICTURE
  // ------------------------------------------------------------
  Future<void> _takePicture() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isTakingPicture) {
      return;
    }

    try {
      HapticFeedback.heavyImpact(); // Physical shutter feel
      setState(() => _isTakingPicture = true);

      await _controller!.setFlashMode(FlashMode.off);

      final image = await _controller!.takePicture();

      if (!mounted) return;

      /// 🚀 RETURN PATH IMMEDIATELY (O(1) Memory transfer)
      Navigator.pop(context, image.path);
    } catch (e) {
      debugPrint("Capture error: $e");
    } finally {
      if (mounted) setState(() => _isTakingPicture = false);
    }
  }

  // ------------------------------------------------------------
  // 🎨 INLINE CAMERA UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              _controller != null) {
            return Stack(
              fit: StackFit.expand,
              children: [
                // 📸 LIVE PREVIEW (Animated Entrance)
                Center(
                  child: CameraPreview(
                    _controller!,
                  ).animate().fadeIn(duration: 400.ms),
                ),

                // ✨ UI CONTROLS LAYER
                SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      /// TOP BAR (With protective gradient for outdoor visibility)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ).animate().scale(
                              delay: 100.ms,
                              curve: Curves.easeOutBack,
                            ),

                            if (_cameras.length > 1)
                              IconButton(
                                icon: const Icon(
                                  Icons.flip_camera_ios_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                onPressed: _toggleCamera,
                              ).animate().scale(
                                delay: 150.ms,
                                curve: Curves.easeOutBack,
                              ),
                          ],
                        ),
                      ),

                      /// CAPTURE BUTTON (With protective gradient & Shutter Animation)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(bottom: 40, top: 40),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: GestureDetector(
                          onTap: _takePicture,
                          child: Center(
                            child:
                                Container(
                                      height: 80,
                                      width: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 4,
                                        ),
                                        color: _isTakingPicture
                                            ? Colors.white
                                            : Colors.white24,
                                      ),
                                    )
                                    // ✨ 1. Fades in normally when the camera opens
                                    .animate()
                                    .fadeIn(duration: 400.ms)
                                    // ✨ 2. GPU ACCELERATED SHUTTER COMPRESSION (Only triggers on tap)
                                    .animate(target: _isTakingPicture ? 1 : 0)
                                    .scaleXY(
                                      end: 0.85,
                                      duration: 100.ms,
                                      curve: Curves.easeOutCubic,
                                    ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          // ⏳ LOADING STATE
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                const Text(
                      "Initializing Camera...",
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fade(duration: 800.ms),
              ],
            ),
          );
        },
      ),
    );
  }
}
