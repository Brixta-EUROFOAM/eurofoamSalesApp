// lib/screens/employee_management/bulk_pjp_wizard_screen.dart
import 'package:flutter/material.dart';
import 'package:salesmanapp/models/employee_model.dart';
import 'package:salesmanapp/models/dealer_model.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:developer' as dev;

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
  int _currentStep = 0;
  bool _isSubmitting = false;
  final ApiService _apiService = ApiService();

  final Set<DateTime> _selectedDates = {};
  DateTime _focusedDay = DateTime.now();

  // Master pool of all selected dealers
  Set<Dealer> _selectedDealerPool = {};

  late Future<List<Dealer>> _dealersFuture;
  List<Dealer> _allDealers = [];

  // --- FINTECH THEME PALETTE ---
  static const Color _bgLight       = Color(0xFFF3F4F6); 
  static const Color _surfaceWhite  = Colors.white;
  static const Color _cardNavy      = Color(0xFF0F172A); 
  static const Color _textDark      = Color(0xFF111827); 
  static const Color _textGrey      = Color(0xFF6B7280); 
  static const Color _accentGreen   = Color(0xFF10B981); 
  static const Color _inputFill     = Color(0xFFF9FAFB);

  @override
  void initState() {
    super.initState();
    _dealersFuture = _loadDealers();
  }

  Future<List<Dealer>> _loadDealers() async {
    try {
      // Fetch plenty of dealers to perform local search/selection
      final dealers = await _apiService.fetchDealers(
        userId: int.parse(widget.employee.id),
        limit: 500, 
      );
      if (mounted) {
        setState(() {
          _allDealers = dealers;
        });
      }
      return dealers;
    } catch (e) {
      dev.log("Error loading dealers: $e");
      return [];
    }
  }

  Future<void> _generateAndSubmitSmartPlan() async {
    setState(() => _isSubmitting = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // --- 1. VALIDATION ---
    const int minVisitsPerDay = 8;

    if (_selectedDates.isEmpty) {
      scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('Please select at least one date.'),
        backgroundColor: Colors.orange,
      ));
      if (mounted) setState(() => _isSubmitting = false);
      return;
    }

    final List<Dealer> dealerPool = _selectedDealerPool.toList();

    if (dealerPool.length < minVisitsPerDay) {
      scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('Please select at least $minVisitsPerDay unique dealers to create a plan.'),
        backgroundColor: Colors.orange,
      ));
      if (mounted) setState(() => _isSubmitting = false);
      return;
    }

    // --- 2. THE SCHEDULING ALGORITHM ---
    final sortedDates = _selectedDates.toList()..sort();
    
    // Sort pool by area to group visits geographically (simple optimization)
    dealerPool.sort((a, b) => (a.area).compareTo(b.area));

    // Track usage count to distribute evenly
    final Map<String, int> dealerVisitCount = { for (var d in dealerPool) d.id!: 0 };

    for (var _ in sortedDates) {
      // Pick dealers with least visits so far
      dealerPool.sort((a, b) => dealerVisitCount[a.id!]!.compareTo(dealerVisitCount[b.id!]!));
      final dealersForThisDay = dealerPool.take(minVisitsPerDay);
      for (var dealer in dealersForThisDay) {
        dealerVisitCount[dealer.id!] = dealerVisitCount[dealer.id!]! + 1;
      }
    }

    // --- 4. SUBMIT TO API ---
    try {
      final List<String> allDealerIds = dealerPool.map((d) => d.id!).toList();
      final DateTime baseDate = sortedDates.first;

      const String planDescription = "Monthly Sales Visit Plan";

      final response = await _apiService.createBulkPjp(
        userId: int.parse(widget.employee.id),
        createdById: int.parse(widget.employee.id),
        dealerIds: allDealerIds, // Pass Dealers
        siteIds: null,           // No Sites
        baseDate: baseDate,
        batchSizePerDay: minVisitsPerDay,
        areaToBeVisited: planDescription,
        status: 'PENDING',
        description: planDescription,
      );

      final createdCount = response['totalRowsCreated'] ?? 0;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Sales Plan submitted! $createdCount visits created.'),
          backgroundColor: _accentGreen,
        ),
      );

      widget.onPjpCreated();
      navigator.pop();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: _bgLight,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textGrey, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _currentStep == 0 ? 'Select Dates' : 'Select Dealers',
          style: const TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _cardNavy),
          canvasColor: _bgLight,
        ),
        child: Stepper(
          type: StepperType.horizontal,
          elevation: 0,
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep == 0) {
              if (_selectedDates.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select dates.'), backgroundColor: Colors.orange),
                );
                return;
              }
              setState(() => _currentStep = 1);
            } else {
              _generateAndSubmitSmartPlan();
            }
          },
          onStepCancel: () {
            if (_currentStep == 1) {
              setState(() => _currentStep = 0);
            }
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 32.0, bottom: 20),
              child: _isSubmitting
                  ? const Center(child: CircularProgressIndicator(color: _cardNavy))
                  : Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: details.onStepContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _cardNavy,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 4,
                              shadowColor: _cardNavy.withOpacity(0.4),
                            ),
                            child: Text(
                              _currentStep == 0 ? 'NEXT STEP' : 'GENERATE PLAN',
                              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)
                            ),
                          ),
                        ),
                        if (_currentStep == 1) ...[
                          const SizedBox(width: 16),
                          TextButton(
                            onPressed: details.onStepCancel,
                            child: const Text('BACK', style: TextStyle(color: _textGrey, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
            );
          },
          steps: [
            Step(
              title: const Text('Schedule'),
              isActive: _currentStep == 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: _buildCalendarStep(),
            ),
            Step(
              title: const Text('Dealers'),
              isActive: _currentStep == 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: _buildDealerSelectionStep(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarStep() {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      padding: const EdgeInsets.only(bottom: 16),
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
              final selectedDayUtc = DateTime.utc(selectedDay.year, selectedDay.month, selectedDay.day);
              setState(() {
                _focusedDay = focusedDay;
                if (_selectedDates.contains(selectedDayUtc)) {
                  _selectedDates.remove(selectedDayUtc);
                } else {
                  _selectedDates.add(selectedDayUtc);
                }
              });
            },
            headerStyle: const HeaderStyle(
              formatButtonVisible: false, 
              titleCentered: true,
              titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark),
              leftChevronIcon: Icon(Icons.chevron_left, color: _textGrey),
              rightChevronIcon: Icon(Icons.chevron_right, color: _textGrey),
            ),
            calendarStyle: CalendarStyle(
              selectedDecoration: const BoxDecoration(color: _cardNavy, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(color: _cardNavy.withOpacity(0.4), shape: BoxShape.circle),
              defaultTextStyle: const TextStyle(color: _textDark),
              weekendTextStyle: const TextStyle(color: _textDark),
              outsideTextStyle: const TextStyle(color: Color(0xFFD1D5DB)),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_today, size: 16, color: _textGrey),
                const SizedBox(width: 8),
                Text('${_selectedDates.length} days selected', style: const TextStyle(color: _textDark, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDealerSelectionStep() {
    const int minVisits = 8;
    final int totalDealers = _selectedDealerPool.length;
    final bool hasError = totalDealers < minVisits;

    return FutureBuilder<List<Dealer>>(
      future: _dealersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40.0),
            child: Center(child: CircularProgressIndicator(color: _cardNavy)),
          );
        }
        if (_allDealers.isEmpty) {
          return const Center(child: Text("No dealers found.", style: TextStyle(color: _textGrey)));
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF), // Light Blue
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF2563EB)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Select at least 8 dealers. The system will distribute them evenly across your selected dates.",
                      style: TextStyle(color: Color(0xFF1E40AF), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            
            // Summary Card (Click to open dialog)
            Container(
              decoration: BoxDecoration(
                color: _surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: hasError ? Colors.red.shade200 : Colors.transparent),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                title: const Text('Dealer Pool', style: TextStyle(fontWeight: FontWeight.bold, color: _textDark)),
                subtitle: Text('$totalDealers dealers selected', style: TextStyle(color: hasError ? Colors.red : _textGrey)),
                trailing: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: _bgLight, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.edit_rounded, color: _cardNavy, size: 20),
                ),
                onTap: () async {
                  final updatedDealers = await showDialog<Set<Dealer>>(
                    context: context,
                    builder: (_) => _DealerSelectionDialog(
                      dealers: _allDealers,
                      initialSelection: _selectedDealerPool,
                    ),
                  );

                  if (updatedDealers != null) {
                    setState(() {
                      _selectedDealerPool = updatedDealers;
                    });
                  }
                },
              ),
            ),
            
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Text('Select at least $minVisits dealers.', style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

// ================================
// Dealer Selection Dialog (Styled)
// ================================
class _DealerSelectionDialog extends StatefulWidget {
  final List<Dealer> dealers;
  final Set<Dealer> initialSelection;

  const _DealerSelectionDialog({
    required this.dealers,
    required this.initialSelection,
  });

  @override
  State<_DealerSelectionDialog> createState() => _DealerSelectionDialogState();
}

class _DealerSelectionDialogState extends State<_DealerSelectionDialog> {
  late Set<Dealer> _selectedDealers;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedDealers = Set.from(widget.initialSelection);
  }

  @override
  Widget build(BuildContext context) {
    // Filter dealers based on search
    final filteredDealers = widget.dealers.where((dealer) {
      if (_searchQuery.isEmpty) return true;
      return dealer.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          dealer.area.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return AlertDialog(
      backgroundColor: _BulkPjpWizardScreenState._surfaceWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Select Dealers', style: TextStyle(color: _BulkPjpWizardScreenState._textDark, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              style: const TextStyle(color: _BulkPjpWizardScreenState._textDark, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Search dealers...',
                hintStyle: const TextStyle(color: _BulkPjpWizardScreenState._textGrey),
                prefixIcon: const Icon(Icons.search, color: _BulkPjpWizardScreenState._textGrey),
                filled: true,
                fillColor: _BulkPjpWizardScreenState._inputFill,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filteredDealers.length,
                itemBuilder: (context, index) {
                  final dealer = filteredDealers[index];
                  final isSelected = _selectedDealers.contains(dealer);
                  
                  return Material(
                    color: isSelected ? _BulkPjpWizardScreenState._cardNavy.withOpacity(0.03) : Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) _selectedDealers.remove(dealer);
                          else _selectedDealers.add(dealer);
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            // Custom Checkbox
                            Container(
                              width: 24, height: 24,
                              decoration: BoxDecoration(
                                color: isSelected ? _BulkPjpWizardScreenState._cardNavy : Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: isSelected ? _BulkPjpWizardScreenState._cardNavy : Colors.grey[300]!, width: 2),
                              ),
                              child: isSelected 
                                ? const Icon(Icons.check, size: 16, color: Colors.white) 
                                : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dealer.name, 
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold, 
                                      color: isSelected ? _BulkPjpWizardScreenState._cardNavy : _BulkPjpWizardScreenState._textDark,
                                      fontSize: 14,
                                    )
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "${dealer.area} • ${dealer.region}", 
                                    style: const TextStyle(color: _BulkPjpWizardScreenState._textGrey, fontSize: 12)
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCEL', style: TextStyle(color: _BulkPjpWizardScreenState._textGrey, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selectedDealers),
          style: ElevatedButton.styleFrom(
            backgroundColor: _BulkPjpWizardScreenState._cardNavy,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text('SAVE (${_selectedDealers.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}