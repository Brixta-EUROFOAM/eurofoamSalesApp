// lib/screens/employee_management/bulk_pjp_wizard_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import 'package:table_calendar/table_calendar.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/models/daily_task_model.dart';
import 'package:salesmanapp/models/employee_model.dart';
import 'package:salesmanapp/models/dealer_model.dart';
import 'package:uuid/uuid.dart';

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
    };
  }

  void _initializeDailyConfigs() {
    _sortedDates = _selectedDates.toList()..sort();

    for (var date in _sortedDates) {
      _dailyConfigs.putIfAbsent(date, () => [_createEmptyVisit()]);
    }
  }

  Future<void> _openDealerSearch(Map<String, dynamic> visit) async {
    final dealer = await showDialog<Dealer>(
      context: context,
      builder: (_) => _ServerDealerSearchDialog(api: _apiService),
    );

    if (dealer == null) return;

    setState(() {
      visit['dealerName'].text = dealer.name;
      visit['dealerMobile'].text = dealer.phoneNo;
      visit['area'].text = dealer.area;
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
            zone: visit['zone'],
            area: visit['area'].text,
            route: visit['route'].text,
            dealerNameSnapshot: visit['dealerName'].text,
            dealerMobile: visit['dealerMobile'].text,
            objective: visit['objective'],
            visitType: visit['type'],
            week: visit['week'],
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
          onStepContinue: () {
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

            GestureDetector(
              onTap: () => _openDealerSearch(visit),
              child: AbsorbPointer(
                child: _buildTextField(
                  "Dealer Name (Search)",
                  visit['dealerName'],
                ),
              ),
            ),
            _buildTextField("Dealer Mobile", visit['dealerMobile']),
            _buildTextField("Area", visit['area']),
            _buildTextField("Route", visit['route']),

            _buildDropdown(
              "Zone",
              visit['zone'],
              _zones,
              (v) => setState(() => visit['zone'] = v),
            ),

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

            _buildTextField("Required Visits", visit['requiredVisitCount']),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // INPUTS
  // --------------------------------------------------

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
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
}

/// ------------------------------------------------------------
/// 🔎 DEALER SEARCH DIALOG (Memory Leak Fixed)
/// ------------------------------------------------------------
class _ServerDealerSearchDialog extends StatefulWidget {
  final ApiService api;
  const _ServerDealerSearchDialog({required this.api});
  @override
  State<_ServerDealerSearchDialog> createState() =>
      _ServerDealerSearchDialogState();
}

class _ServerDealerSearchDialogState extends State<_ServerDealerSearchDialog> {
  List<Dealer> _dealers = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _performSearch("");
  }

  // 🚀 CRITICAL FIX: Prevent Memory Leaks
  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _performSearch(query),
    );
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    try {
      final results = await widget.api.fetchDealers(search: query, limit: 20);
      if (mounted) {
        setState(() {
          _dealers = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        "Select Dealer",
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: Color(0xFF0F172A),
          fontSize: 20,
          letterSpacing: -0.5,
        ),
      ),
      contentPadding: const EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: 0,
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(
          children: [
            TextField(
              onChanged: _onSearchChanged,
              style: const TextStyle(fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: "Search by name or zone...",
                hintStyle: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Colors.grey,
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0F172A),
                      ),
                    )
                  : _dealers.isEmpty
                  ? const Center(
                      child: Text(
                        "No dealers found.",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _dealers.length,
                      separatorBuilder: (context, index) =>
                          Divider(color: Colors.grey.shade200, height: 1),
                      itemBuilder: (context, index) {
                        final dealer = _dealers[index];

                        // 🚀 MEMORY OPTIMIZED: Replaced the multiple string allocations
                        // from your second snippet with a single, O(1) ternary resolution.
                        // This prevents unnecessary garbage collection spikes while scrolling.
                        final zoneArea = dealer.area.isNotEmpty
                            ? "${dealer.region}, ${dealer.area}"
                            : dealer.region.isNotEmpty
                            ? dealer.region
                            : "Unknown Zone";

                        return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 0,
                              ),
                              // Kept your original premium Container UI look instead of the basic CircleAvatar
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.storefront_rounded,
                                  color: Colors.blueAccent,
                                  size: 22,
                                ),
                              ),
                              title: Text(
                                dealer.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      zoneArea,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF374151),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dealer.address,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6B7280),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () => Navigator.pop(context, dealer),
                            )
                            // 🚀 ANIMATION PRESERVED: Staggered entry animation kept intact
                            .animate()
                            .fadeIn(delay: (index * 30).ms)
                            .slideX(begin: -0.05);
                      },
                    ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.all(16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            "CANCEL",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ).animate().scale(curve: Curves.easeOutBack, duration: 400.ms);
  }
}
