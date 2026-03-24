// lib/technicalSide/screens/forms/create_technical_pjp_form.dart
import 'package:flutter/material.dart';
import 'package:salesmanapp/core/app_kernel.dart'; //
import 'package:salesmanapp/features/mapselectionpjp/map_selection_controller.dart';
import 'package:salesmanapp/features/mapselectionpjp/map_selection_result.dart';
import 'package:salesmanapp/salesSide/models/employee_model.dart';
import 'package:salesmanapp/salesSide/models/pjp_model.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:maplibre_gl/maplibre_gl.dart'; // Ensure this is at the top
import 'package:flutter/services.dart';

class CreateTechnicalPjpForm extends StatefulWidget {
  final Employee employee;
  final VoidCallback onPjpCreated;

  const CreateTechnicalPjpForm({
    super.key,
    required this.employee,
    required this.onPjpCreated,
  });

  @override
  State<CreateTechnicalPjpForm> createState() => _CreateTechnicalPjpFormState();
}

class _CreateTechnicalPjpFormState extends State<CreateTechnicalPjpForm> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // --- KERNEL FEATURE ---
  // Accessing the controller via AppKernel as per your architectural example
  late final MapSelectionController _mapController = AppKernel.instance
      .feature<MapSelectionController>();

  // --- STATE ---
  String _visitType = 'Site';
  bool _isSubmitting = false;
  bool _isMapVisible = false;
  bool _isMapEngineReady = false;
  String? _selectedActivityType;
  MapSelectionResult? _pickedLocation; // Stores the LatLng and Address result

  // --- CONTROLLERS ---
  final _descriptionController = TextEditingController();
  final _routeController = TextEditingController();
  final _newSiteVisitsController = TextEditingController(text: '');
  final _followUpVisitsController = TextEditingController(text: '');
  final _dealerVisitsController = TextEditingController(text: '');
  final _influencerVisitsController = TextEditingController(text: '');
  final _bagsController = TextEditingController(text: '');
  final _schemesController = TextEditingController(text: '');
  final _infNameController = TextEditingController();
  final _infPhoneController = TextEditingController();

  // --- THEME ---
  static const Color _surfaceWhite = Colors.white;
  static const Color _cardNavy = Color(0xFF0F172A);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textGrey = Color(0xFF6B7280);
  static const Color _inputFill = Color(0xFFF9FAFB);
  static const Color _accentGreen = Color(0xFF10B981);
  static const Color _accentBlue = Color(0xFF3B82F6);

  @override
  void dispose() {
    _descriptionController.dispose();
    _routeController.dispose();
    _newSiteVisitsController.dispose();
    _followUpVisitsController.dispose();
    _dealerVisitsController.dispose();
    _influencerVisitsController.dispose();
    _bagsController.dispose();
    _schemesController.dispose();
    _infNameController.dispose();
    _infPhoneController.dispose();
    super.dispose();
  }

  void initState() {
    super.initState();
    _warmupEngine();
  }

  Future<void> _warmupEngine() async {
    await Future.delayed(Duration.zero);
    if (mounted) setState(() => _isMapEngineReady = true);
  }

  // --- NEW FEATURE HANDLER ---
  Future<void> _handleMapSelection() async {
    if (!_isMapEngineReady) {
      _showSnack("Initializing map engine...", _accentBlue);
      return;
    }
    FocusScope.of(context).unfocus();

    HapticFeedback.lightImpact(); // Physical feedback makes it feel faster

    setState(() {
      _isMapVisible = true;
    });
  }

  // --- SUBMISSION ---
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Safety check for map selection
    if (_pickedLocation == null) {
      _showSnack('Please select a destination on the map.', Colors.orange);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String primaryName = _visitType == 'Influencer'
          ? _infNameController.text
          : "$_visitType Visit";

      // Using the controller logic to format the "Viable Data" string
      final formattedArea = _mapController.formatPjpArea(
        primaryName,
        _pickedLocation!,
      );

      final newPjp = Pjp(
        id: '',
        planDate: DateTime.now(),
        userId: int.parse(widget.employee.id),
        createdById: int.parse(widget.employee.id),
        status: 'pending',
        verificationStatus: 'PENDING',
        areaToBeVisited: formattedArea, // Now contains lat/lng from map
        route: _routeController.text,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        plannedNewSiteVisits: int.tryParse(_newSiteVisitsController.text) ?? 0,
        plannedFollowUpSiteVisits:
            int.tryParse(_followUpVisitsController.text) ?? 0,
        plannedNewDealerVisits: int.tryParse(_dealerVisitsController.text) ?? 0,
        plannedInfluencerVisits:
            int.tryParse(_influencerVisitsController.text) ?? 0,
        noOfConvertedBags: int.tryParse(_bagsController.text) ?? 0,
        noOfMasonPcSchemes: int.tryParse(_schemesController.text) ?? 0,
        influencerName: _infNameController.text,
        influencerPhone: _infPhoneController.text,
        activityType: _selectedActivityType ?? '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _apiService.createPjp(newPjp);
      widget.onPjpCreated();
      if (mounted) Navigator.pop(context);
      _showSnack('Technical Visit Plan Created!', _accentGreen);
    } catch (e) {
      _showSnack('Failed to create plan: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
@override
  Widget build(BuildContext context) {
    // 1. Fixed Height (90% of screen)
    final double height = MediaQuery.of(context).size.height * 0.9;
    
    // 2. Keyboard height (Used ONLY for the Form Layer padding)
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: height, 
      decoration: const BoxDecoration(
        color: _surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // --- LAYER 1: THE FORM (Standard Scrolling) ---
              Positioned.fill(
                child: Padding(
                  // We manually pad the form so you can scroll to the bottom
                  padding: EdgeInsets.only(bottom: _isMapVisible ? 0 : keyboardHeight),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 40, height: 4,
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          _buildVisitTypeSelector(),
                          const SizedBox(height: 24),
                          _buildMapSelectorInput(
                            label: "Route / Full Address",
                            controller: _routeController,
                            icon: Icons.map_rounded,
                            hint: "Tap to select from map",
                            onTap: _handleMapSelection,
                          ),
                          const Divider(height: 40),
                          _buildSectionHeader("Planned Visit Targets", Icons.ads_click),
                          _buildDynamicMetricGrid(),
                          const Divider(height: 40),
                          _buildSectionHeader("Business Goals", Icons.analytics),
                          _buildBusinessGoalRow(),
                          const SizedBox(height: 24),
                          _buildSimpleInput(
                            label: "Remarks / Purpose",
                            controller: _descriptionController,
                            icon: Icons.notes,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 32),
                          _buildSubmitButton(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // --- LAYER 2: MAP OVERLAY ---
              if (_isMapVisible)
                Positioned.fill(
                  // 🔒 LOCK 1: Scaffold ignores Keyboard resizing
                  // This ensures the Search Bar stays pinned at the top.
                  child: Scaffold(
                    backgroundColor: _surfaceWhite, 
                    resizeToAvoidBottomInset: false, // <--- PREVENTS KEYBOARD SHIFT
                    body: Stack(
                      children: [
                        // 🔓 UNLOCKED: GestureDetector REMOVED.
                        // Your touches will now reach the Map, so you can drag/pan it.
                        _mapController.buildPickerUI(
                          context,
                          initialPos: const LatLng(26.1445, 91.7362),
                          onLocationSelected: (result) {
                            FocusScope.of(context).unfocus();
                            setState(() {
                              _pickedLocation = result;
                              _routeController.text = result.address;
                              _isMapVisible = false;
                            });
                          },
                          onCancel: () {
                            FocusScope.of(context).unfocus();
                            setState(() => _isMapVisible = false);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  // Special UI helper for the Map Selector
Widget _buildMapSelectorInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required VoidCallback onTap,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap, // Native tap handler works perfectly with readOnly

      style: const TextStyle(color: _textDark, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _textGrey),
        prefixIcon: Icon(icon, color: _accentBlue, size: 20),
        suffixIcon: const Icon(
          Icons.location_searching,
          color: _accentBlue,
        ),
        hintText: hint,
        filled: true,
        fillColor: _inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        // Optional: Ensure error states look good
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),
      validator: (v) =>
          v == null || v.isEmpty ? 'Please select location' : null,
    );
  }
  // --- EXISTING UI HELPERS ---
  Widget _buildVisitTypeSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _inputFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildSegmentButton('Site Visit', 'Site'),
          _buildSegmentButton('Dealer Visit', 'Dealer'),
          _buildSegmentButton('Influencer', 'Influencer'),
        ],
      ),
    );
  }

  Widget _buildDynamicMetricGrid() {
    List<Widget> metrics = [];
    if (_visitType == 'Site') {
      metrics.addAll([
        _buildMetricItem("New Sites", _newSiteVisitsController, _accentBlue),
        _buildMetricItem(
          "Follow-up Sites",
          _followUpVisitsController,
          Colors.purple,
        ),
      ]);
    } else if (_visitType == 'Dealer') {
      metrics.add(
        _buildMetricItem("New Dealers", _dealerVisitsController, Colors.orange),
      );
    } else if (_visitType == 'Influencer') {
      metrics.add(
        _buildMetricItem(
          "Influencers",
          _influencerVisitsController,
          Colors.teal,
        ),
      );
    }
    return Wrap(spacing: 12, runSpacing: 12, children: metrics);
  }

  Widget _buildMetricItem(
    String label,
    TextEditingController ctrl,
    Color color,
  ) {
    return Container(
      width: (MediaQuery.of(context).size.width - 60) / 2,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _textDark,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessGoalRow() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricItem("Target Bags", _bagsController, _accentGreen),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricItem(
            "PC Schemes",
            _schemesController,
            Colors.redAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    bool isPhone = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      style: const TextStyle(color: _textDark, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _textGrey),
        prefixIcon: Icon(icon, color: _textGrey, size: 20),
        hintText: hint,
        filled: true,
        fillColor: _inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _cardNavy, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSegmentButton(String label, String value) {
    final isSelected = _visitType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _visitType = value;
          if (value != 'Site') {
            _newSiteVisitsController.clear();
            _followUpVisitsController.clear();
          }
          if (value != 'Dealer') _dealerVisitsController.clear();
          if (value != 'Influencer') _influencerVisitsController.clear();
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? _cardNavy : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : _textGrey,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _cardNavy),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: _cardNavy,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: _cardNavy,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
            : const Text(
                'CREATE PLAN',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
      ),
    );
  }
}
