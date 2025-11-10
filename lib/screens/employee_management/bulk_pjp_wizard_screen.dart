import 'package:flutter/material.dart';
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:assetarchiverflutter/models/dealer_model.dart';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:developer' as dev;

// --- ✅ NEW IMPORTS ---
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
// ---

const _log = 'BulkPjpWizard';

// (StatefulWidget class is unchanged)
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

  // Master pool of all selected dealers
  Set<Dealer> _selectedDealerPool = {};

  // --- INITIALIZATION / LOCATION STATE ---
  late Future<Map<String, List<Dealer>>> _dealersByRegionFuture;
  Map<String, List<Dealer>> _loadedDealersByRegion = {};
  String? _currentRegion; // To store the user's current region
  String _loadingMessage = "Loading..."; // To show loading status
  bool _isInitializing = true; // To show a full-screen loader
  // ---

  @override
  void initState() {
    super.initState();
    // Start the full init process
    _dealersByRegionFuture = _loadInitialData();
  }

  // --- COMBINED INITIALIZATION FUNCTION ---
  Future<Map<String, List<Dealer>>> _loadInitialData() async {
    try {
      if (!mounted) return {};
      setState(() {
        _isInitializing = true;
        _loadingMessage = "Getting your location...";
      });

      // 1. Get current region
      _currentRegion = await _getCurrentRegion();
      dev.log('Current Region found: $_currentRegion', name: _log);

      if (!mounted) return {};
      setState(() => _loadingMessage = "Loading all dealers...");

      // 2. Load all dealers
      final dealers =
          await _apiService.fetchDealers(userId: int.parse(widget.employee.id));
      dev.log('BulkPjpWizard: Found ${dealers.length} dealers.', name: _log);

      // 3. Group them
      _loadedDealersByRegion = _groupDealersByRegion(dealers);

      if (!mounted) return {};
      setState(() => _isInitializing = false);
      return _loadedDealersByRegion;
    } catch (e, st) {
      dev.log("Error loading initial data: $e", name: _log, error: e, stackTrace: st);
      if (mounted) {
        setState(() => _isInitializing = false);
      }
      throw Exception('Failed to load initial data: $e');
    }
  }

  // --- FUNCTION TO GET USER'S CURRENT REGION ---
  Future<String?> _getCurrentRegion() async {
    try {
      var status = await Permission.location.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        dev.log('Location permission denied', name: _log);
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);

      final geoData = await _apiService.reverseGeocodeWithRadar(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      return geoData['region']; // Returns 'city' or 'Unknown Region'
    } catch (e) {
      dev.log('Failed to get current region: $e', name: _log);
      return null;
    }
  }

  Map<String, List<Dealer>> _groupDealersByRegion(List<Dealer> dealers) {
    final map = <String, List<Dealer>>{};
    for (var dealer in dealers) {
      final region = dealer.region.isNotEmpty ? dealer.region : 'Unknown Region';
      (map[region] ??= []).add(dealer);
    }
    return map;
  }

  // --- ✅ SMART SCHEDULER ALGORITHM (filters null/empty IDs safely) ---
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

    // Filter the pool for valid IDs before scheduling
    final List<Dealer> dealerPool = _selectedDealerPool
        .where((d) => d.id != null && d.id!.isNotEmpty)
        .toList();

    // Must have at least 8 dealers
    if (dealerPool.length < minVisitsPerDay) {
      scaffoldMessenger.showSnackBar(SnackBar(
        content: Text(
            'Please select at least $minVisitsPerDay unique dealers to create a plan.'),
        backgroundColor: Colors.orange,
      ));
      if (mounted) setState(() => _isSubmitting = false);
      return;
    }

    // --- 2. THE SCHEDULING ALGORITHM ---
    dev.log(
        'Running Smart Scheduler... Dates: ${_selectedDates.length}, Dealers: ${dealerPool.length}',
        name: _log);

    final sortedDates = _selectedDates.toList()..sort();

    // Track how many times each dealer has been assigned
    final Map<String, int> dealerVisitCount = {
      for (var d in dealerPool) d.id!: 0
    };

    // Final plan map (date -> dealers)
    final Map<DateTime, Set<Dealer>> finalPlan = {};

    for (final date in sortedDates) {
      dealerPool.sort((a, b) =>
          dealerVisitCount[a.id!]!.compareTo(dealerVisitCount[b.id!]!));
      final dealersForThisDay = dealerPool.take(minVisitsPerDay);
      finalPlan[date] = dealersForThisDay.toSet();
      for (var dealer in dealersForThisDay) {
        dealerVisitCount[dealer.id!] = dealerVisitCount[dealer.id!]! + 1;
      }
    }

    dev.log('Smart Scheduler complete. Plan generated for ${finalPlan.length} days.',
        name: _log);

    // --- 4. SUBMIT TO API ---
    try {
      final List<String> allDealerIds = dealerPool.map((d) => d.id!).toList();
      final DateTime baseDate = sortedDates.first;

      dev.log(
          'Submitting bulk PJP: ${allDealerIds.length} unique dealers, starting from $baseDate',
          name: _log);

      const String planDescription = "Monthly PJP Plan";

      final response = await _apiService.createBulkPjp(
        userId: int.parse(widget.employee.id),
        createdById: int.parse(widget.employee.id),
        dealerIds: allDealerIds,
        baseDate: baseDate,
        batchSizePerDay: minVisitsPerDay,
        areaToBeVisited: planDescription,
        status: 'PENDING',
        description: planDescription,
      );

      final createdCount = response['totalRowsCreated'] ?? 0;
      final skippedCount = response['totalRowsSkipped'] ?? 0;

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
              'Smart Plan submitted! $createdCount created, $skippedCount skipped.'),
          backgroundColor: Colors.green,
        ),
      );

      widget.onPjpCreated();
      navigator.pop();
    } catch (e, st) {
      dev.log('Error submitting bulk plan: $e',
          name: _log, error: e, stackTrace: st);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error submitting bulk plan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
  // --- END SMART SCHEDULER ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Full screen loader on init
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Bulk PJP Wizard'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(_loadingMessage, style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      );
    }

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
          // Step 2 now calls the Smart Scheduler
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
            selectedDayPredicate: (day) => _selectedDates.contains(
              DateTime.utc(day.year, day.month, day.day),
            ),
            onDaySelected: (selectedDay, focusedDay) {
              final selectedDayUtc = DateTime.utc(
                  selectedDay.year, selectedDay.month, selectedDay.day);
              setState(() {
                dev.log('Selected: $selectedDayUtc, Focused: $focusedDay',
                    name: _log);
                _focusedDay = focusedDay;
                if (_selectedDates.contains(selectedDayUtc)) {
                  _selectedDates.remove(selectedDayUtc);
                } else {
                  _selectedDates.add(selectedDayUtc);
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
              disabledTextStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.3)),
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

  // STEP 2: Dealer Pool builder
  Step _buildStep2DealerAssignment(ThemeData theme) {
    const int minVisits = 8;
    final int totalDealers = _selectedDealerPool.length;
    final bool hasError = totalDealers < minVisits;

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
              Text(
                'Select all dealers you want to include in this month\'s plan. The app will automatically create a balanced schedule for you.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(
                    'Edit Dealer Pool',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '$totalDealers dealers selected',
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
                        initialSelection: _selectedDealerPool, // master pool
                        currentRegion: _currentRegion,
                      ),
                    );

                    if (updatedDealers != null) {
                      setState(() {
                        _selectedDealerPool = updatedDealers; // Save master pool
                      });
                    }
                  },
                ),
              ),
              if (hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Please select at least $minVisits dealers.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.error),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ================================
// Dealer selection dialog (location-aware sorting)
// ================================
class _DealerSelectionDialog extends StatefulWidget {
  final ThemeData theme;
  final Map<String, List<Dealer>> dealersByRegion;
  final Set<Dealer> initialSelection;
  final String? currentRegion;

  const _DealerSelectionDialog({
    required this.theme,
    required this.dealersByRegion,
    required this.initialSelection,
    this.currentRegion,
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
    // Sort regions to put current region first
    final allRegions = widget.dealersByRegion.keys.toList();
    final List<String> sortedRegions = [];

    if (widget.currentRegion != null &&
        allRegions.contains(widget.currentRegion)) {
      sortedRegions.add(widget.currentRegion!);
    }

    final otherRegions =
        allRegions.where((r) => r != widget.currentRegion).toList()..sort();
    sortedRegions.addAll(otherRegions);

    // Filter the sorted list based on search
    final filteredRegions = sortedRegions.where((region) {
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
                final isCurrentRegion = region == widget.currentRegion;

                final dealersInRegion =
                    widget.dealersByRegion[region]!.where((dealer) {
                  if (_searchQuery.isEmpty) return true;
                  return dealer.name
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()) ||
                      dealer.area
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()) ||
                      region
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase());
                }).toList();

                if (dealersInRegion.isEmpty) return const SizedBox.shrink();

                return ExpansionTile(
                  title: Text(
                    region,
                    style: widget.theme.textTheme.titleMedium?.copyWith(
                      color: isCurrentRegion
                          ? widget.theme.colorScheme.primary
                          : null,
                      fontWeight: isCurrentRegion
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  leading: isCurrentRegion
                      ? Icon(Icons.my_location,
                          color: widget.theme.colorScheme.primary)
                      : Icon(Icons.location_city,
                          color:
                              widget.theme.colorScheme.onSurface.withOpacity(0.6)),
                  initiallyExpanded: isCurrentRegion && _searchQuery.isEmpty,
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
