// lib/technicalSide/screens/bulk_technical_pjp_wizard_screen.dart
import 'package:flutter/material.dart';
import 'package:salesmanapp/core/app_kernel.dart';
import 'package:salesmanapp/features/mapselectionpjp/map_selection_controller.dart';
import 'package:salesmanapp/features/mapselectionpjp/map_selection_result.dart';
import 'package:salesmanapp/models/employee_model.dart';
import 'package:salesmanapp/models/pjp_model.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class BulkTechnicalPjpWizardScreen extends StatefulWidget {
  final Employee employee;
  final VoidCallback onPjpCreated;

  const BulkTechnicalPjpWizardScreen({
    super.key,
    required this.employee,
    required this.onPjpCreated,
  });

  @override
  State<BulkTechnicalPjpWizardScreen> createState() =>
      _BulkTechnicalPjpWizardScreenState();
}

class _BulkTechnicalPjpWizardScreenState
    extends State<BulkTechnicalPjpWizardScreen> {
  int _currentStep = 0;
  int _plannerPageIndex = 0;
  bool _isSubmitting = false;
  final ApiService _apiService = ApiService();

  // --- KERNEL FEATURE ---
  late final MapSelectionController _mapController = AppKernel.instance
      .feature<MapSelectionController>();

  // --- FINTECH THEME PALETTE ---
  static const Color _surfaceWhite = Colors.white;
  static const Color _bgLight = Color(0xFFF3F4F6);
  static const Color _cardNavy = Color(0xFF0F172A);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textGrey = Color(0xFF6B7280);
  static const Color _accentGreen = Color(0xFF10B981);
  static const Color _accentBlue = Color(0xFF3B82F6);
  static const Color _inputFill = Color(0xFFF9FAFB);

  // Selection State
  Set<DateTime> _selectedDates = {};
  DateTime _focusedDay = DateTime.now();
  List<DateTime> _sortedDates = [];
  final Map<DateTime, Map<String, dynamic>> _dailyConfigs = {};

  @override
  void dispose() {
    for (var config in _dailyConfigs.values) {
      config.values.whereType<TextEditingController>().forEach(
        (c) => c.dispose(),
      );
    }
    super.dispose();
  }

  void _initializeDailyConfigs() {
    _sortedDates = _selectedDates.toList()..sort();
    for (var date in _sortedDates) {
      _dailyConfigs.putIfAbsent(
        date,
        () => {
          'type': 'Site',
          'route': TextEditingController(text: ''),
          'locationResult': null as MapSelectionResult?,
          'infName': TextEditingController(text: ''),
          'infPhone': TextEditingController(text: ''),
          'activityType': null as String?,
          'newSites': TextEditingController(text: ''),
          'followUp': TextEditingController(text: ''),
          'dealers': TextEditingController(text: ''),
          'influencers': TextEditingController(text: ''),
          'bags': TextEditingController(text: ''),
          'schemes': TextEditingController(text: ''),
          'description': TextEditingController(text: ''),
        },
      );
    }
  }

  // --- MAP SELECTION HANDLER ---
  Future<void> _handleMapSelection(DateTime date) async {
    final result = await _mapController.showMapPicker(context);
    if (result != null) {
      setState(() {
        _dailyConfigs[date]!['locationResult'] = result;
        _dailyConfigs[date]!['route'].text = result.address;
      });
    }
  }

  // --- SUBMISSION LOGIC ---
  Future<void> _submitWeeklyPlan() async {
    // Validation: Ensure all days have a route selected
    for (var date in _sortedDates) {
      if (_dailyConfigs[date]!['locationResult'] == null) {
        _showSnack(
          "Please select a route for ${DateFormat('MMM d').format(date)}",
          Colors.orange,
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);
    int successCount = 0;

    try {
      for (var date in _sortedDates) {
        final config = _dailyConfigs[date]!;
        final visitType = config['type'];
        final MapSelectionResult location = config['locationResult'];

        String primaryName = visitType == 'Influencer'
            ? config['infName'].text
            : "$visitType Visit";

        final formattedArea = _mapController.formatPjpArea(
          primaryName,
          location,
        );

        final pjp = Pjp(
          id: '',
          planDate: date,
          userId: int.parse(widget.employee.id),
          createdById: int.parse(widget.employee.id),
          status: 'PENDING',
          verificationStatus: 'PENDING',
          areaToBeVisited: formattedArea,
          route: config['route'].text,
          description: config['description'].text,
          plannedNewSiteVisits: int.tryParse(config['newSites'].text) ?? 0,
          plannedFollowUpSiteVisits: int.tryParse(config['followUp'].text) ?? 0,
          plannedNewDealerVisits: int.tryParse(config['dealers'].text) ?? 0,
          plannedInfluencerVisits:
              int.tryParse(config['influencers'].text) ?? 0,
          noOfConvertedBags: int.tryParse(config['bags'].text) ?? 0,
          noOfMasonPcSchemes: int.tryParse(config['schemes'].text) ?? 0,
          influencerName: config['infName'].text,
          influencerPhone: config['infPhone'].text,
          activityType: config['activityType'] ?? '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _apiService.createPjp(pjp);
        successCount++;
      }

      _showSnack(
        'Successfully created $successCount visit plans!',
        _accentGreen,
      );
      widget.onPjpCreated();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnack('Batch error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceWhite,
      appBar: AppBar(
        backgroundColor: _surfaceWhite,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _cardNavy,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Weekly Visit Planner',
          style: TextStyle(
            color: _cardNavy,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: _surfaceWhite,
          colorScheme: const ColorScheme.light(
            primary: Colors.black,
            onPrimary: Colors.white,
          ),
        ),
        child: Stepper(
          type: StepperType.horizontal,
          elevation: 0,
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep == 0) {
              if (_selectedDates.isEmpty)
                return _showSnack("Please select dates", Colors.orange);
              setState(() {
                _initializeDailyConfigs();
                _currentStep++;
              });
            } else {
              _submitWeeklyPlan();
            }
          },
          onStepCancel: () => _currentStep > 0
              ? setState(() => _currentStep--)
              : Navigator.pop(context),
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: _isSubmitting
                  ? const Center(
                      child: CircularProgressIndicator(color: _cardNavy),
                    )
                  : ElevatedButton(
                      onPressed: details.onStepContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _cardNavy,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _currentStep == 0
                            ? 'NEXT: PLAN TARGETS'
                            : 'GENERATE WEEKLY PLAN',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
            );
          },
          steps: [
            Step(
              title: const Text('Schedule'),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: _buildCalendarStep(),
            ),
            Step(
              title: const Text('Planner'),
              isActive: _currentStep >= 1,
              state: StepState.indexed,
              content: _buildPlannerStep(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarStep() {
    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _bgLight, width: 1.5),
      ),
      child: Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 60)),
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate: (day) => _selectedDates.contains(
              DateTime.utc(day.year, day.month, day.day),
            ),
            onDaySelected: (selectedDay, focusedDay) {
              final dayUtc = DateTime.utc(
                selectedDay.year,
                selectedDay.month,
                selectedDay.day,
              );
              setState(() {
                _focusedDay = focusedDay;
                if (_selectedDates.contains(dayUtc))
                  _selectedDates.remove(dayUtc);
                else
                  _selectedDates.add(dayUtc);
              });
            },
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: _textDark,
                fontSize: 16,
              ),
            ),
            calendarStyle: const CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: _cardNavy,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: _bgLight,
                shape: BoxShape.circle,
              ),
              defaultTextStyle: TextStyle(color: _textDark),
            ),
          ),
          const Divider(color: _bgLight),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: _textGrey,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_selectedDates.length} days selected',
                  style: const TextStyle(
                    color: _textDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlannerStep() {
    if (_sortedDates.isEmpty) return const SizedBox.shrink();

    final date = _sortedDates[_plannerPageIndex];
    final config = _dailyConfigs[date]!;
    final dayStr = DateFormat('EEEE, MMM d').format(date);
    final visitType = config['type'];

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: _surfaceWhite,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _bgLight, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(dayStr),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(color: _bgLight, thickness: 1.5),
                ),
                _buildVisitTypeSelector(date, visitType),
                const SizedBox(height: 24),

                // --- ROUTE SELECTOR FIELD ---
                _buildMapSelectorInput(
                  label: "Route / Destination",
                  controller: config['route'],
                  icon: Icons.map_rounded,
                  onTap: () => _handleMapSelection(date),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(color: _bgLight, thickness: 1.5),
                ),
                _buildSectionHeader("Planned Visit Targets", Icons.ads_click),
                _buildDynamicMetricGrid(config, visitType),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(color: _bgLight, thickness: 1.5),
                ),
                _buildSectionHeader("Business Goals", Icons.analytics),
                _buildBusinessGoalRow(config),

                const SizedBox(height: 20),
                _buildSimpleInput(
                  label: "Remarks / Purpose",
                  controller: config['description'],
                  icon: Icons.notes,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildPaginationControls(),
      ],
    );
  }

  Widget _buildPaginationControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildNavButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: _plannerPageIndex > 0
              ? () => setState(() => _plannerPageIndex--)
              : null,
        ),
        const SizedBox(width: 40),
        Text(
          "${_plannerPageIndex + 1} OF ${_sortedDates.length}",
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: _textDark,
            fontSize: 14,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 40),
        _buildNavButton(
          icon: Icons.arrow_forward_ios_rounded,
          onTap: _plannerPageIndex < _sortedDates.length - 1
              ? () => setState(() => _plannerPageIndex++)
              : null,
        ),
      ],
    );
  }

  Widget _buildMapSelectorInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: IgnorePointer(
        child: TextFormField(
          controller: controller,
          style: const TextStyle(color: _textDark, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: _textGrey, fontSize: 13),
            prefixIcon: Icon(icon, color: _accentBlue, size: 20),
            suffixIcon: const Icon(
              Icons.location_searching,
              color: _accentBlue,
              size: 20,
            ),
            filled: true,
            fillColor: _inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String dayStr) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          dayStr,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: _textDark,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _bgLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "${_plannerPageIndex + 1} / ${_sortedDates.length}",
            style: const TextStyle(
              color: _textGrey,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisitTypeSelector(DateTime date, String currentType) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _inputFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildSegmentButton(date, 'Site Visit', 'Site'),
          _buildSegmentButton(date, 'Dealer Visit', 'Dealer'),
          _buildSegmentButton(date, 'Influencer', 'Influencer'),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(DateTime date, String label, String value) {
    final isSelected = _dailyConfigs[date]!['type'] == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _dailyConfigs[date]!['type'] = value),
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
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicMetricGrid(Map<String, dynamic> config, String type) {
    List<Widget> items = [];
    if (type == 'Site') {
      items.addAll([
        _buildMetricItem("New Sites", config['newSites'], _accentBlue),
        _buildMetricItem("Follow-up Sites", config['followUp'], Colors.purple),
      ]);
    } else if (type == 'Dealer') {
      items.add(
        _buildMetricItem("New Dealers", config['dealers'], Colors.orange),
      );
    } else {
      items.add(
        _buildMetricItem("Influencers", config['influencers'], Colors.teal),
      );
    }
    return Wrap(spacing: 12, runSpacing: 12, children: items);
  }

  Widget _buildMetricItem(
    String label,
    TextEditingController ctrl,
    Color color,
  ) {
    return Container(
      width: (MediaQuery.of(context).size.width - 96) / 2,
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
              fontSize: 10,
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

  Widget _buildBusinessGoalRow(Map<String, dynamic> config) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricItem("Target Bags", config['bags'], _accentGreen),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricItem(
            "PC Schemes",
            config['schemes'],
            Colors.redAccent,
          ),
        ),
      ],
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
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: _textDark, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _textGrey, fontSize: 13),
        prefixIcon: Icon(icon, color: _textGrey, size: 20),
        filled: true,
        fillColor: _inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildNavButton({required IconData icon, VoidCallback? onTap}) {
    final bool isDisabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDisabled
              ? _bgLight.withOpacity(0.5)
              : _cardNavy.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isDisabled ? _textGrey.withOpacity(0.3) : _cardNavy,
          size: 20,
        ),
      ),
    );
  }
}