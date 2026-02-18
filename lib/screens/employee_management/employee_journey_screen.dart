// lib/screens/employee_management/employee_journey_screen.dart

import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

// --- Imports ---
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/models/employee_model.dart';
import 'package:salesmanapp/models/pjp_model.dart';
import 'package:salesmanapp/models/dealer_model.dart';
import 'package:salesmanapp/features/salesJourney/sales_journey_controller.dart';
import 'package:salesmanapp/features/salesJourney/sales_journey_capabilities.dart';
import 'package:salesmanapp/core/feature_flags/technical_flags.dart';

// --- Technical Map Style ---
import 'package:salesmanapp/core/app_kernel.dart';
import 'package:salesmanapp/features/journeyMapstyle/journeyMapstyle_controller.dart';

// --- UI OVERLAY ---
import 'package:salesmanapp/technicalSide/screens/journeyUi/journey_overlay_manager.dart';

class EmployeeJourneyScreen extends StatefulWidget {
  final Employee employee;
  final Map<String, dynamic>? initialJourneyData;
  final VoidCallback? onDestinationConsumed;
  final Function(Pjp pjp, Dealer dealer, DateTime checkInTime)?
  onJourneyCompleted;

  const EmployeeJourneyScreen({
    super.key,
    required this.employee,
    this.initialJourneyData,
    this.onDestinationConsumed,
    this.onJourneyCompleted,
  });

  @override
  State<EmployeeJourneyScreen> createState() => _EmployeeJourneyScreenState();
}

class _EmployeeJourneyScreenState extends State<EmployeeJourneyScreen> {
  late SalesJourneyController _controller;

  final Completer<MapLibreMapController> _controllerCompleter = Completer();

  // ---------- MAP ----------
  late Future<String> _styleFuture;

  static const _initialCameraPosition = CameraPosition(
    target: LatLng(26.1445, 91.7362),
    zoom: 12,
  );

  // ---------- UI STATE ----------
  String _distanceDisplay = "0.00 km";
  bool _isJourneyActive = false;
  final _destinationController = TextEditingController();

  // ---------- DATA ----------
  Dealer? _currentDealer;
  String? _taskId;
  //String? _pjpId;
  String? _dealerId;
  int? _verifiedDealerId;

  // ---------- THEME ----------
  final Color _bgLight = const Color(0xFFF3F4F6);
  final Color _cardNavy = const Color(0xFF0F172A);
  final Color _dangerRed = const Color(0xFFEF4444);

  // =====================================================
  // INIT
  // =====================================================
  @override
  void didUpdateWidget(covariant EmployeeJourneyScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.initialJourneyData != null &&
        widget.initialJourneyData != oldWidget.initialJourneyData) {
      _loadTaskData(widget.initialJourneyData!);
    }
  }

  @override
  void initState() {
    super.initState();

    _controller = SalesJourneyController(
      api: ApiService(),
      caps: SalesJourneyCapabilities.fromFlags(TechnicalFlags.dev),
    );

    _styleFuture = _readStyle();

    _controller.distanceStream.listen((dist) {
      if (mounted) {
        setState(
          () => _distanceDisplay = "${(dist / 1000).toStringAsFixed(2)} km",
        );
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _controller.checkActiveJourney();

      if (_controller.isJourneyActive) {
        setState(() {
          _isJourneyActive = true;
          _distanceDisplay =
              "${(_controller.totalDistance / 1000).toStringAsFixed(2)} km";
          _destinationController.text = "Resuming Journey...";
        });
      }

      if (widget.initialJourneyData != null) {
        _loadTaskData(widget.initialJourneyData!);
      }
    });
  }

  Future<String> _readStyle() async {
    final style = AppKernel.instance.feature<JourneyMapStyleController>();
    final result = style.loadStyle(dotenv.env['STADIA_API_KEY']!);
    return result.styleJson;
  }

  // =====================================================
  // LOAD DATA
  // =====================================================

  void _loadTaskData(Map<String, dynamic> data) async {
    _dealerId = data['dealerId']?.toString();
    _verifiedDealerId = data['verifiedDealerId'];
    _taskId = data['taskId']?.toString();
    //_pjpId = data['pjpId'];

    final String displayName = data['displayName'] ?? "Visit";

    setState(() {
      _destinationController.text = displayName;
    });

    if (_dealerId != null) {
      try {
        final dealer = await ApiService().fetchDealerById(_dealerId!);
        setState(() => _currentDealer = dealer);
      } catch (e) {
        dev.log("Dealer load error: $e");
      }
    }

    widget.onDestinationConsumed?.call();
  }

  // =====================================================
  // JOURNEY ACTIONS
  // =====================================================

  Future<void> _handleStart() async {
    if (_taskId == null) return;

    // --------------------------------------------------
    // 1️⃣ LOCATION PERMISSION (FOREGROUND ONLY)
    // --------------------------------------------------
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission required")),
      );
      return;
    }

    // --------------------------------------------------
    // 2️⃣ OPTIMISTIC UI (INSTANT TRANSITION)
    // --------------------------------------------------
    setState(() {
      _isJourneyActive = true;
      _distanceDisplay = "Starting...";
    });

    // --------------------------------------------------
    // 3️⃣ START CONTROLLER (ASYNC)
    // --------------------------------------------------
    try {
      await _controller.startTaskJourney(
        userId: int.parse(widget.employee.id),
        taskId: _taskId!,
        displayName: _destinationController.text,
        dealerId: _dealerId,
        verifiedDealerId: _verifiedDealerId,
      );

      // --------------------------------------------------
      // 4️⃣ 🔥 CRITICAL: RESET DISPLAY AFTER START
      // --------------------------------------------------
      if (mounted) {
        setState(() {
          _distanceDisplay = "0.00 km";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isJourneyActive = false);
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Start failed: $e")));
    }
  }

  Future<void> _handleStop() async {
    if (!_isJourneyActive) return;

    // --------------------------------------------------
    // 1️⃣ OPTIMISTIC UI UPDATE
    // --------------------------------------------------
    if (mounted) {
      setState(() {
        _distanceDisplay = "Stopping...";
      });
    }

    // --------------------------------------------------
    // 2️⃣ STOP ASYNC (NON-BLOCKING)
    // --------------------------------------------------
    Future(() async {
      try {
        await _controller.stopTaskJourney(_taskId ?? "");

        if (!mounted) return;

        setState(() {
          _isJourneyActive = false;
          _distanceDisplay = "0.00 km";
        });

        // --------------------------------------------------
        // DVR PROMPT (OPTIONAL)
        // --------------------------------------------------
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Journey Completed"),
            content: const Text("Open DVR now?"),
            actions: [
              TextButton(
                child: const Text("Later"),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: const Text("Open DVR"),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      } catch (e) {
        if (mounted) {
          setState(() => _isJourneyActive = true);
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Stop failed: $e")));
      }
    });
  }

  Future<void> _launchNavigation() async {
    if (_currentDealer?.latitude != null && _currentDealer!.latitude != 0.0) {
      final url = Uri.parse(
        'google.navigation:q=${_currentDealer!.latitude},${_currentDealer!.longitude}',
      );
      if (await canLaunchUrl(url)) await launchUrl(url);
    }
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // =====================================================
        // 1️⃣ MAP BACKGROUND (TECHNICAL SIDE IDENTICAL)
        // =====================================================
        SizedBox.expand(
          child: FutureBuilder<String>(
            future: _styleFuture,
            builder: (ctx, snap) {
              if (!snap.hasData) {
                return Container(color: _bgLight);
              }

              return MapLibreMap(
                styleString: snap.data!,
                initialCameraPosition: _initialCameraPosition,
                onMapCreated: (c) {
                  if (!_controllerCompleter.isCompleted) {
                    _controllerCompleter.complete(c);
                  }
                },
                trackCameraPosition: true,
                myLocationEnabled: false,
              );
            },
          ),
        ),

        // =====================================================
        // 2️⃣ TOP CONTROL BUTTON (IMPORTANT FOR LAYOUT)
        // =====================================================
        Positioned(
          top: 50,
          right: 16,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.my_location, color: _cardNavy),
              onPressed: () {},
            ),
          ),
        ),

        // =====================================================
        // 3️⃣ OVERLAY MANAGER (IDENTICAL TO TECH SIDE)
        // =====================================================
        Positioned.fill(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 72,
              ),
              child: JourneyOverlayManager(
                isJourneyActive: _isJourneyActive,
                distance: _distanceDisplay,
                onStop: () async => await _handleStop(),
                onNavigate: _launchNavigation,

                idlePanel: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _IdleJourneyPanel(
                      destinationName: _destinationController.text,
                    ),
                    const SizedBox(height: 24),
                    _StartJourneySlider(
                      key: ValueKey(_isJourneyActive),
                      isJourneyActive: false,
                      onSlideAction: _handleStart,
                      canStart: _taskId != null,
                      cardNavy: _cardNavy,
                      dangerRed: _dangerRed,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =====================================================
// IDLE PANEL
// =====================================================

class _IdleJourneyPanel extends StatelessWidget {
  final String destinationName;

  const _IdleJourneyPanel({required this.destinationName});

  @override
  Widget build(BuildContext context) {
    const Color cardNavy = Color(0xFF0F172A);
    const Color textGrey = Color(0xFF6B7280);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cardNavy.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: cardNavy,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                destinationName.isEmpty
                    ? "Waiting for selection..."
                    : destinationName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: cardNavy,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: const [
              Icon(Icons.info_outline_rounded, color: textGrey, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Slide below to start tracking.",
                  style: TextStyle(
                    color: textGrey,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =====================================================
// SLIDER (IDENTICAL STYLE)
// =====================================================

class _StartJourneySlider extends StatelessWidget {
  final bool isJourneyActive;
  final Future<void> Function() onSlideAction;
  final bool canStart;
  final Color cardNavy;
  final Color dangerRed;

  const _StartJourneySlider({
    super.key,
    required this.isJourneyActive,
    required this.onSlideAction,
    required this.canStart,
    required this.cardNavy,
    required this.dangerRed,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = canStart || isJourneyActive;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isEnabled ? cardNavy : Colors.grey).withOpacity(0.35),
            blurRadius: 25,
            spreadRadius: -2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SlideAction(
        onSubmit: isEnabled
            ? () async {
                await onSlideAction();
                return null;
              }
            : null,
        innerColor: Colors.white,
        outerColor: isEnabled ? cardNavy : const Color(0xFFF1F5F9),
        sliderButtonIcon: const Icon(
          Icons.arrow_forward_rounded,
          color: Color(0xFF0F172A),
          size: 26,
        ),
        text: isEnabled ? 'SLIDE TO START VISIT' : 'SELECT TASK FIRST',
        enabled: isEnabled,
        textStyle: TextStyle(
          color: isEnabled ? Colors.white : const Color(0xFF94A3B8),
          fontSize: 15,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
        borderRadius: 24,
        elevation: 0,
        height: 76,
        sliderRotate: false,
      ),
    );
  }
}
