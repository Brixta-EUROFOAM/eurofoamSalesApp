// lib/salesSide/screens/bulk_pjp_wizard_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import 'package:table_calendar/table_calendar.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/salesSide/models/daily_task_model.dart';
import 'package:salesmanapp/salesSide/models/employee_model.dart';
import 'package:uuid/uuid.dart';
import 'package:salesmanapp/widgets/reusable_functions.dart';

class BulkPjpWizardScreen extends StatefulWidget {
  final Employee employee;
  final VoidCallback onPjpCreated;

  const BulkPjpWizardScreen({
    super.key,
    required this.employee,
    required this.onPjpCreated,
  });

  @override
  State<BulkPjpWizardScreen> createState() => _BulkPjpWizardScreenState();
}

class _BulkPjpWizardScreenState extends State<BulkPjpWizardScreen> {
  final ApiService _apiService = ApiService();
  final String _batchId = const Uuid().v4();

  int _currentStep = 0;
  int _plannerPageIndex = 0;
  bool _isSubmitting = false;

  // CONSTANTS
  final List<String> _zones = [
    'Kamrup',
    'Central Assam',
    'Upper Assam',
    'Lower Assam',
    'Kamrup TSO',
    'Meghalaya',
    'Barak Valley',
    'Mizoram',
    'Manipur',
    'Nagaland',
    'North Bank',
    'Non Trade',
    'Tripura',
  ];

  final List<String> _objectives = [
    'Order Related',
    'Payment Collection',
    'Any Support',
    'Prospect',
    'Meetings',
    'Promotional Activity',
  ];

  final List<String> _types = [
    'Important Parties',
    'Prospect',
    'Sub Dealer',
    'Open Visit',
    'Other Visit',
  ];

  final List<String> _weeks = ['week1', 'week2', 'week3', 'week4'];

  // DATE STATE
  final Set<DateTime> _selectedDates = {};
  DateTime _focusedDay = DateTime.now();
  List<DateTime> _sortedDates = [];

  // DATE → LIST OF VISITS
  final Map<DateTime, List<Map<String, dynamic>>> _dailyConfigs = {};

  // THEME
  static const Color _cardNavy = Color(0xFF0F172A);
  static const Color _bgLight = Color(0xFFF8FAFC);

  // --------------------------------------------------
  // VISIT MODEL
  // --------------------------------------------------

  Map<String, dynamic> _createEmptyVisit() {
    return {
      'zone': _zones.first,
      'objective': _objectives.first,
      'type': _types.first,
      'week': _weeks.first,
      'area': TextEditingController(),
      'route': TextEditingController(),
      'dealerName': TextEditingController(),
      'dealerMobile': TextEditingController(),
      'requiredVisitCount': TextEditingController(text: '1'),
      'dealerId': null,
      'lat': null, // ADD THIS
      'lng': null, // ADD THIS
    };
  }

  void _initializeDailyConfigs() {
    _sortedDates = _selectedDates.toList()..sort();

    for (var date in _sortedDates) {
      _dailyConfigs.putIfAbsent(date, () => [_createEmptyVisit()]);
    }
  }

  Future<void> _openDealerSearch(Map<String, dynamic> visit) async {
    final dealer = await openDealerSearch(context);

    if (dealer == null) return;

    setState(() {
      visit['dealerId'] = dealer.id;
      visit['dealerName'].text = dealer.name;
      visit['dealerMobile'].text = dealer.phoneNo;
      visit['area'].text = dealer.area;
      visit['lat'] =
          dealer.latitude; // ADD THIS (assuming Dealer model has latitude)
      visit['lng'] = dealer.longitude;
      visit['zone'] = _zones.contains(dealer.region)
          ? dealer.region
          : _zones.first;
    });
  }

  // --------------------------------------------------
  // SUBMIT
  // --------------------------------------------------

  Future<void> _submitBatch() async {
    setState(() => _isSubmitting = true);

    try {
      List<Future> futures = [];

      for (var date in _sortedDates) {
        final visits = _dailyConfigs[date]!;

        for (var visit in visits) {
          final task = DailyTask(
            userId: int.parse(widget.employee.id),
            pjpBatchId: _batchId,
            taskDate: date,
            status: "PENDING",
            dealerId: visit['dealerId'],
            zone: visit['zone'],
            area: visit['area'].text,
            route: visit['route'].text,
            dealerNameSnapshot: visit['dealerName'].text,
            dealerMobile: visit['dealerMobile'].text,
            objective: visit['objective'],
            visitType: visit['type'],
            week: visit['week'],
            latitude: visit['lat'], // ADD THIS
            longitude: visit['lng'], // ADD THIS
            requiredVisitCount: int.tryParse(visit['requiredVisitCount'].text),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          futures.add(_apiService.createDailyTask(task));
        }
      }

      await Future.wait(futures);

      widget.onPjpCreated();

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // --------------------------------------------------
  // UI
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Weekly Plan Wizard",
          style: TextStyle(fontWeight: FontWeight.bold, color: _cardNavy),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _cardNavy),
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Colors.white,
          colorScheme: const ColorScheme.light(
            primary: _cardNavy,
            onPrimary: Colors.white,
          ),
        ),
        child: Stepper(
          elevation: 0,
          type: StepperType.horizontal,
          currentStep: _currentStep,
          onStepContinue: _isSubmitting
              ? null
              : () {
                  if (_currentStep == 0) {
                    if (_selectedDates.isEmpty) return;

                    setState(() {
                      _initializeDailyConfigs();
                      _currentStep++;
                    });
                  } else {
                    _submitBatch();
                  }
                },
          onStepCancel: () => _currentStep > 0
              ? setState(() => _currentStep--)
              : Navigator.pop(context),
          steps: [
            Step(
              title: const Text("Select Dates"),
              isActive: _currentStep >= 0,
              content: _buildCalendarStep(),
            ),
            Step(
              title: const Text("Plan Visits"),
              isActive: _currentStep >= 1,
              content: _buildPlannerStep(),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // CALENDAR
  // --------------------------------------------------

  Widget _buildCalendarStep() {
    return TableCalendar(
      focusedDay: _focusedDay,
      firstDay: DateTime.now(),
      lastDay: DateTime.now().add(const Duration(days: 60)),

      headerStyle: const HeaderStyle(
        formatButtonVisible: false, // This hides the "2 weeks" button
        titleCentered:
            true, // Optional: Centers "March 2026" since the button is gone
      ),

      selectedDayPredicate: (day) =>
          _selectedDates.contains(DateTime.utc(day.year, day.month, day.day)),
      onDaySelected: (selectedDay, focusedDay) {
        final dayUtc = DateTime.utc(
          selectedDay.year,
          selectedDay.month,
          selectedDay.day,
        );

        setState(() {
          _focusedDay = focusedDay;

          if (_selectedDates.contains(dayUtc)) {
            _selectedDates.remove(dayUtc);
          } else {
            _selectedDates.add(dayUtc);
          }
        });
      },
      calendarStyle: const CalendarStyle(
        selectedDecoration: BoxDecoration(
          color: _cardNavy,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  // --------------------------------------------------
  // PLANNER
  // --------------------------------------------------

  Widget _buildPlannerStep() {
    if (_sortedDates.isEmpty) return const SizedBox.shrink();

    final date = _sortedDates[_plannerPageIndex];
    final visits = _dailyConfigs[date]!;

    return Column(
      children: [
        Text(
          DateFormat('EEEE, MMM d').format(date),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _cardNavy,
          ),
        ),
        const SizedBox(height: 20),

        ...visits.asMap().entries.map((entry) {
          return _buildVisitCard(date, entry.key, entry.value);
        }),

        const SizedBox(height: 12),

        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              visits.add(_createEmptyVisit());
            });
          },
          icon: const Icon(Icons.add),
          label: const Text("Add Visit"),
        ),

        const SizedBox(height: 24),

        _buildPaginationControls(),
      ],
    );
  }

  // --------------------------------------------------
  // VISIT CARD
  // --------------------------------------------------

  Widget _buildVisitCard(DateTime date, int index, Map<String, dynamic> visit) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Visit ${index + 1}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      _dailyConfigs[date]!.removeAt(index);
                    });
                  },
                ),
              ],
            ),

            _buildDropdown(
              "Zone",
              visit['zone'],
              _zones,
              (v) => setState(() => visit['zone'] = v),
            ),

            GestureDetector(
              onTap: () => _showDestinationSelector(visit),
              child: AbsorbPointer(
                child: _buildTextField(
                  "Select Destination",
                  visit['dealerName'],
                ),
              ),
            ),

            _buildTextField("Dealer Mobile", visit['dealerMobile'], keyboardType: TextInputType.phone),
            _buildTextField("Area", visit['area']),
            _buildTextField("Route", visit['route']),
            _buildTextField("Required Visits", visit['requiredVisitCount']),

            _buildDropdown(
              "Objective",
              visit['objective'],
              _objectives,
              (v) => setState(() => visit['objective'] = v),
            ),

            _buildDropdown(
              "Visit Type",
              visit['type'],
              _types,
              (v) => setState(() => visit['type'] = v),
            ),

            _buildDropdown(
              "Week",
              visit['week'],
              _weeks,
              (v) => setState(() => visit['week'] = v),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // INPUTS
  // --------------------------------------------------

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: _bgLight,
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: "",
        ),
        items: items
            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  // --------------------------------------------------
  // DATE PAGINATION
  // --------------------------------------------------

  Widget _buildPaginationControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: _plannerPageIndex > 0
              ? () => setState(() => _plannerPageIndex--)
              : null,
          icon: const Icon(Icons.arrow_back_ios),
        ),
        Text(
          "Day ${_plannerPageIndex + 1} of ${_sortedDates.length}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        IconButton(
          onPressed: _plannerPageIndex < _sortedDates.length - 1
              ? () => setState(() => _plannerPageIndex++)
              : null,
          icon: const Icon(Icons.arrow_forward_ios),
        ),
      ],
    );
  }

  void _showDestinationSelector(Map<String, dynamic> visit) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Select Destination",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),

              const SizedBox(height: 24),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cardNavy,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.storefront, color: Colors.white),
                label: const Text(
                  "Select Dealer",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _openDealerSearch(visit);
                },
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  side: const BorderSide(color: _cardNavy, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.location_on_outlined, color: _cardNavy),
                label: const Text(
                  "Enter Destination Manually",
                  style: TextStyle(
                    color: _cardNavy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _openManualDestinationDialog(visit);
                },
              ),
            ],
          ),
        ),
      ).animate().scale(curve: Curves.easeOutBack, duration: 400.ms),
    );
  }

  void _openManualDestinationDialog(Map<String, dynamic> visit) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Enter Destination"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Type..."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                visit['dealerId'] = null;
                visit['dealerName'].text = controller.text;

                // clear dealer specific fields
                visit['dealerMobile'].text = "";
                visit['lat'] = null;
                visit['lng'] = null;
              });

              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}