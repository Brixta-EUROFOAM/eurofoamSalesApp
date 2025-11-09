import 'package:flutter/material.dart';
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:assetarchiverflutter/models/dealer_model.dart';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as dev;

// Unused import 'package:assetarchiverflutter/models/pjp_model.dart'; removed

const _log = 'BulkPjpWizard';

// ==================================
// Bulk PJP Creation Wizard (2 steps)
// ==================================
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

  Set<DateTime> _selectedDates = {};
  DateTime _focusedDay = DateTime.now().add(const Duration(days: 1));
  Map<DateTime, Set<Dealer>> _plan = {};

  late Future<Map<String, List<Dealer>>> _dealersByRegionFuture;
  Map<String, List<Dealer>> _loadedDealersByRegion = {};

  @override
  void initState() {
    super.initState();
    _dealersByRegionFuture = _loadDealers();
  }

  Future<Map<String, List<Dealer>>> _loadDealers() async {
    try {
      dev.log('BulkPjpWizard: Fetching dealers for user ${widget.employee.id}', name: _log);
      final dealers =
          await _apiService.fetchDealers(userId: int.parse(widget.employee.id));
      dev.log('BulkPjpWizard: Found ${dealers.length} dealers.', name: _log);
      _loadedDealersByRegion = _groupDealersByRegion(dealers);
      return _loadedDealersByRegion;
    } catch (e, st) {
      dev.log("Error loading dealers: $e", name: _log, error: e, stackTrace: st);
      throw Exception('Failed to load dealers: $e');
    }
  }

  Map<String, List<Dealer>> _groupDealersByRegion(List<Dealer> dealers) {
    final map = <String, List<Dealer>>{};
    for (var dealer in dealers) {
      // Use 'Unknown Region' as a fallback if region is null/empty
      final region = dealer.region.isNotEmpty ? dealer.region : 'Unknown Region';
      (map[region] ??= []).add(dealer);
    }
    return map;
  }

  Future<void> _submitBulkPlan() async {
    setState(() => _isSubmitting = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    const int minVisitsPerDay = 8;
    bool allDatesValid = true;

    final Set<Dealer> allDealersInPlan = {};
    DateTime? baseDate;

    for (var entry in _plan.entries) {
      final date = entry.key;
      final dealersForDay = entry.value;

      if (dealersForDay.length < minVisitsPerDay) {
        allDatesValid = false;
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
                'Error: ${DateFormat.yMMMd().format(date)} has fewer than $minVisitsPerDay dealers selected.'),
            backgroundColor: Colors.red,
          ),
        );
        break;
      }

      if (baseDate == null || date.isBefore(baseDate)) {
        baseDate = date;
      }
      allDealersInPlan.addAll(dealersForDay);
    }

    if (!allDatesValid) {
      if (mounted) setState(() => _isSubmitting = false);
      return;
    }

    if (baseDate == null || allDealersInPlan.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
            content: Text('No dealers or dates selected.'),
            backgroundColor: Colors.orange),
      );
      if (mounted) setState(() => _isSubmitting = false);
      return;
    }

    try {
      final List<String> dealerIds = allDealersInPlan
          .map((d) => d.id)       
          .whereType<String>() 
          .where((id) => id.isNotEmpty) 
          .toList();

      dev.log(
          'Submitting bulk PJP: ${dealerIds.length} unique dealers, starting from $baseDate',
          name: _log);
      
      // --- ✅ THIS IS THE FIX ---
      // We now save a sensible string for the area and description.
      // The server will use this.
      const String planDescription = "Monthly PJP Plan";
      
      final response = await _apiService.createBulkPjp(
        userId: int.parse(widget.employee.id),
        createdById: int.parse(widget.employee.id),
        dealerIds: dealerIds,
        baseDate: baseDate,
        batchSizePerDay: minVisitsPerDay,
        
        // This is the area/name fallback
        areaToBeVisited: planDescription, // <-- WAS "pending"
        
        // This is the ADMIN APPROVAL status
        status: 'PENDING',
        
        // This is the description
        description: planDescription
      );
      // --- END FIX ---

      final createdCount = response['totalRowsCreated'] ?? 0;
      final skippedCount = response['totalRowsSkipped'] ?? 0;

      scaffoldMessenger.showSnackBar(
        SnackBar(
            content: Text(
                'Bulk PJP submitted! $createdCount created, $skippedCount skipped.'),
            backgroundColor: Colors.green),
      );

      widget.onPjpCreated();
      navigator.pop();
    } catch (e, st) {
      dev.log('Error submitting bulk plan: $e', name: _log, error: e, stackTrace: st);
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content: Text('Error submitting bulk plan: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentStep == 0
            ? 'Step 1: Select Dates'
            : 'Step 2: Assign Dealers'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
      ),
      backgroundColor: theme.colorScheme.background,
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 0) {
            if (_selectedDates.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Please select at least one date.'),
                    backgroundColor: Colors.orange),
              );
              return;
            }
            setState(() => _currentStep = 1);
          } else {
            _submitBulkPlan();
          }
        },
        onStepCancel: () {
          if (_currentStep == 1) {
            setState(() => _currentStep = 0);
          }
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: _isSubmitting
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      ElevatedButton(
                        onPressed: details.onStepContinue,
                        child: Text(_currentStep == 0 ? 'NEXT' : 'SUBMIT PLAN'),
                      ),
                      if (_currentStep == 1)
                        TextButton(
                          onPressed: details.onStepCancel,
                          child: const Text('BACK'),
                        ),
                    ],
                  ),
          );
        },
        steps: [
          _buildStep1Calendar(theme),
          _buildStep2DealerAssignment(theme),
        ],
      ),
    );
  }

  Step _buildStep1Calendar(ThemeData theme) {
    return Step(
      title: const Text('Dates'),
      isActive: _currentStep == 0,
      content: Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 60)),
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate: (day) => _selectedDates.contains(day),
            onDaySelected: (selectedDay, focusedDay) {
              final selectedDayUtc = DateTime.utc(
                  selectedDay.year, selectedDay.month, selectedDay.day);
              setState(() {
                dev.log('Selected: $selectedDayUtc, Focused: $focusedDay', name: _log);
                _focusedDay = focusedDay;
                if (_selectedDates.contains(selectedDayUtc)) {
                  _selectedDates.remove(selectedDayUtc);
                  _plan.remove(selectedDayUtc);
                } else {
                  _selectedDates.add(selectedDayUtc);
                  _plan[selectedDayUtc] = {};
                }
              });
            },
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              disabledTextStyle:
                  TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.3)),
            ),
            enabledDayPredicate: (day) {
              final today = DateTime.now();
              final normalizedToday =
                  DateTime.utc(today.year, today.month, today.day);
              final normalizedDay =
                  DateTime.utc(day.year, day.month, day.day);
              return !normalizedDay.isBefore(normalizedToday);
            },
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: theme.textTheme.titleLarge!,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '${_selectedDates.length} days selected',
              style: theme.textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }

  Step _buildStep2DealerAssignment(ThemeData theme) {
    final sortedDates = _selectedDates.toList()..sort();
    const int minVisits = 8;

    return Step(
      title: const Text('Dealers'),
      isActive: _currentStep == 1,
      content: FutureBuilder<Map<String, List<Dealer>>>(
        future: _dealersByRegionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            dev.log('Error in _buildStep2DealerAssignment: ${snapshot.error}',
                name: _log, error: snapshot.error);
            return Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Text(
                  'Error loading dealers: ${snapshot.error}',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No dealers found for this user.'),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Assign at least $minVisits dealers to each selected date. Tap a date to add dealers.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedDates.length,
                itemBuilder: (context, index) {
                  final date = sortedDates[index];
                  final selectedDealersForDay = _plan[date] ?? {};
                  final count = selectedDealersForDay.length;
                  final bool hasError = count < minVisits;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(
                        DateFormat.yMMMd().format(date),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '$count dealers selected',
                        style: TextStyle(
                          color: hasError ? theme.colorScheme.error : null,
                        ),
                      ),
                      trailing: Icon(
                        hasError
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle,
                        color: hasError ? theme.colorScheme.error : Colors.green,
                      ),
                      onTap: () async {
                        final updatedDealers = await showDialog<Set<Dealer>>(
                          context: context,
                          builder: (_) => _DealerSelectionDialog(
                            theme: theme,
                            dealersByRegion: _loadedDealersByRegion,
                            initialSelection: selectedDealersForDay,
                          ),
                        );

                        if (updatedDealers != null) {
                          setState(() {
                            _plan[date] = updatedDealers;
                          });
                        }
                      },
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

// ================================
// Dealer selection dialog (with search)
// ================================
class _DealerSelectionDialog extends StatefulWidget {
  final ThemeData theme;
  final Map<String, List<Dealer>> dealersByRegion;
  final Set<Dealer> initialSelection;

  const _DealerSelectionDialog({
    required this.theme,
    required this.dealersByRegion,
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
    final regions = widget.dealersByRegion.keys.toList();

    final filteredRegions = regions.where((region) {
      if (_searchQuery.isEmpty) return true;
      if (region.toLowerCase().contains(_searchQuery.toLowerCase())) return true;
      return widget.dealersByRegion[region]!.any(
        (dealer) =>
            dealer.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            dealer.area.toLowerCase().contains(_searchQuery.toLowerCase()),
      );
    }).toList();

    return AlertDialog(
      title: const Text('Select Dealers'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by dealer, region, or area...',
              prefixIcon: Icon(
                Icons.search,
                color: widget.theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: widget.theme.colorScheme.onSurface.withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.5,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filteredRegions.length,
              itemBuilder: (context, index) {
                final region = filteredRegions[index];

                final dealersInRegion = widget.dealersByRegion[region]!.where((dealer) {
                  if (_searchQuery.isEmpty) return true;
                  return dealer.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      dealer.area.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      region.toLowerCase().contains(_searchQuery.toLowerCase());
                }).toList();

                if (dealersInRegion.isEmpty) return const SizedBox.shrink();

                return ExpansionTile(
                  title: Text(
                    region,
                    style: widget.theme.textTheme.titleMedium,
                  ),
                  initiallyExpanded: _searchQuery.isNotEmpty,
                  children: dealersInRegion.map((dealer) {
                    final isSelected = _selectedDealers.contains(dealer);

                    return CheckboxListTile(
                      title: Text(dealer.name),
                      subtitle: Text(dealer.area),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedDealers.add(dealer);
                          } else {
                            _selectedDealers.remove(dealer);
                          }
                        });
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(_selectedDealers);
          },
          child: Text('SAVE (${_selectedDealers.length})'),
        ),
      ],
    );
  }
}