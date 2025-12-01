// lib/screens/employee_management/bulk_pjp_wizard_screen.dart
import 'package:flutter/material.dart';
import 'package:salesmanapp/models/employee_model.dart';
import 'package:salesmanapp/models/dealer_model.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:developer' as dev;

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

const _log = 'BulkPjpWizard';

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
  String? _currentRegion; 
  String _loadingMessage = "Loading..."; 
  bool _isInitializing = true; 

  // --- 🎨 FINTECH THEME PALETTE ---
  static const Color _bgLight       = Color(0xFFF3F4F6); 
  static const Color _surfaceWhite  = Colors.white;
  static const Color _cardNavy      = Color(0xFF0F172A); 
  static const Color _textDark      = Color(0xFF111827); 
  static const Color _textGrey      = Color(0xFF6B7280); 
  static const Color _accentGreen   = Color(0xFF10B981); 
  static const Color _accentOrange  = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _dealersByRegionFuture = _loadInitialData();
  }

  Future<Map<String, List<Dealer>>> _loadInitialData() async {
    try {
      if (!mounted) return {};
      setState(() {
        _isInitializing = true;
        _loadingMessage = "Getting your location...";
      });

      _currentRegion = await _getCurrentRegion();
      dev.log('Current Region found: $_currentRegion', name: _log);

      if (!mounted) return {};
      setState(() => _loadingMessage = "Loading all dealers...");

      final dealers = await _apiService.fetchDealers(userId: int.parse(widget.employee.id));
      dev.log('BulkPjpWizard: Found ${dealers.length} dealers.', name: _log);

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

  Future<String?> _getCurrentRegion() async {
    try {
      var status = await Permission.location.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        dev.log('Location permission denied', name: _log);
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      final geoData = await _apiService.reverseGeocodeWithRadar(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      return geoData['region']; 
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

  Future<void> _generateAndSubmitSmartPlan() async {
    setState(() => _isSubmitting = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    const int minVisitsPerDay = 8;

    if (_selectedDates.isEmpty) {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Please select at least one date.'), backgroundColor: Colors.orange));
      if (mounted) setState(() => _isSubmitting = false);
      return;
    }

    final List<Dealer> dealerPool = _selectedDealerPool.where((d) => d.id != null && d.id!.isNotEmpty).toList();

    if (dealerPool.length < minVisitsPerDay) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Please select at least $minVisitsPerDay unique dealers to create a plan.'), backgroundColor: Colors.orange));
      if (mounted) setState(() => _isSubmitting = false);
      return;
    }

    dev.log('Running Smart Scheduler... Dates: ${_selectedDates.length}, Dealers: ${dealerPool.length}', name: _log);

    final sortedDates = _selectedDates.toList()..sort();
    
    // Track usage count
    final Map<String, int> dealerVisitCount = { for (var d in dealerPool) d.id!: 0 };

    for (final date in sortedDates) {
      dealerPool.sort((a, b) => dealerVisitCount[a.id!]!.compareTo(dealerVisitCount[b.id!]!));
      final dealersForThisDay = dealerPool.take(minVisitsPerDay);
      for (var dealer in dealersForThisDay) {
        dealerVisitCount[dealer.id!] = dealerVisitCount[dealer.id!]! + 1;
      }
    }

    try {
      final List<String> allDealerIds = dealerPool.map((d) => d.id!).toList();
      final DateTime baseDate = sortedDates.first;
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

      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Smart Plan submitted! $createdCount created, $skippedCount skipped.'), backgroundColor: _accentGreen));
      widget.onPjpCreated();
      navigator.pop();
    } catch (e, st) {
      dev.log('Error submitting bulk plan: $e', name: _log, error: e, stackTrace: st);
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error submitting bulk plan: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: _bgLight,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: _cardNavy),
              const SizedBox(height: 24),
              Text(_loadingMessage, style: const TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: _bgLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textGrey, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _currentStep == 0 ? 'Step 1: Select Dates' : 'Step 2: Assign Dealers',
          style: const TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _cardNavy), // Tint for stepper
        ),
        child: Stepper(
          type: StepperType.horizontal,
          currentStep: _currentStep,
          elevation: 0,
          onStepContinue: () {
            if (_currentStep == 0) {
              if (_selectedDates.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one date.'), backgroundColor: Colors.orange));
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
              padding: const EdgeInsets.only(top: 32.0),
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
                              elevation: 0,
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
            _buildStep1Calendar(),
            _buildStep2DealerAssignment(),
          ],
        ),
      ),
    );
  }

  Step _buildStep1Calendar() {
    return Step(
      title: const Text('Dates', style: TextStyle(fontSize: 12)),
      isActive: _currentStep == 0,
      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      content: Container(
        decoration: BoxDecoration(
          color: _surfaceWhite,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          children: [
            TableCalendar(
              focusedDay: _focusedDay,
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 60)),
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) => _selectedDates.contains(DateTime.utc(day.year, day.month, day.day)),
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
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(color: _cardNavy, shape: BoxShape.circle),
                todayDecoration: BoxDecoration(color: _cardNavy.withOpacity(0.4), shape: BoxShape.circle),
                defaultTextStyle: const TextStyle(color: _textDark),
                weekendTextStyle: const TextStyle(color: _textDark),
              ),
              headerStyle: const HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('${_selectedDates.length} days selected', style: const TextStyle(color: _textGrey, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Step _buildStep2DealerAssignment() {
    const int minVisits = 8;
    final int totalDealers = _selectedDealerPool.length;
    final bool hasError = totalDealers < minVisits;

    return Step(
      title: const Text('Dealers', style: TextStyle(fontSize: 12)),
      isActive: _currentStep == 1,
      content: FutureBuilder<Map<String, List<Dealer>>>(
        future: _dealersByRegionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _cardNavy));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Text('No dealers found.', style: TextStyle(color: _textGrey));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select the dealers for this plan. Our algorithm will auto-schedule them.',
                style: TextStyle(color: _textGrey, fontSize: 14),
              ),
              const SizedBox(height: 24),
              
              // Summary Card
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
                  trailing: Icon(Icons.edit_rounded, color: _cardNavy),
                  onTap: () async {
                    final updatedDealers = await showDialog<Set<Dealer>>(
                      context: context,
                      builder: (_) => _DealerSelectionDialog(
                        dealersByRegion: _loadedDealersByRegion,
                        initialSelection: _selectedDealerPool, 
                        currentRegion: _currentRegion,
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
      ),
    );
  }
}

// ================================
// Dealer Selection Dialog (Styled)
// ================================
class _DealerSelectionDialog extends StatefulWidget {
  final Map<String, List<Dealer>> dealersByRegion;
  final Set<Dealer> initialSelection;
  final String? currentRegion;

  const _DealerSelectionDialog({
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
    final allRegions = widget.dealersByRegion.keys.toList();
    final List<String> sortedRegions = [];

    if (widget.currentRegion != null && allRegions.contains(widget.currentRegion)) {
      sortedRegions.add(widget.currentRegion!);
    }
    final otherRegions = allRegions.where((r) => r != widget.currentRegion).toList()..sort();
    sortedRegions.addAll(otherRegions);

    final filteredRegions = sortedRegions.where((region) {
      if (_searchQuery.isEmpty) return true;
      if (region.toLowerCase().contains(_searchQuery.toLowerCase())) return true;
      return widget.dealersByRegion[region]!.any(
        (dealer) => dealer.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            dealer.area.toLowerCase().contains(_searchQuery.toLowerCase()),
      );
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
              decoration: InputDecoration(
                hintText: 'Search dealer or region...',
                hintStyle: const TextStyle(color: _BulkPjpWizardScreenState._textGrey),
                prefixIcon: const Icon(Icons.search, color: _BulkPjpWizardScreenState._textGrey),
                filled: true,
                fillColor: _BulkPjpWizardScreenState._bgLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filteredRegions.length,
                itemBuilder: (context, index) {
                  final region = filteredRegions[index];
                  final isCurrentRegion = region == widget.currentRegion;
                  final dealersInRegion = widget.dealersByRegion[region]!.where((dealer) {
                    if (_searchQuery.isEmpty) return true;
                    return dealer.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        dealer.area.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        region.toLowerCase().contains(_searchQuery.toLowerCase());
                  }).toList();

                  if (dealersInRegion.isEmpty) return const SizedBox.shrink();

                  return Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      title: Text(
                        region,
                        style: TextStyle(
                          color: isCurrentRegion ? _BulkPjpWizardScreenState._cardNavy : _BulkPjpWizardScreenState._textDark,
                          fontWeight: isCurrentRegion ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      leading: Icon(
                        isCurrentRegion ? Icons.my_location : Icons.location_city,
                        color: isCurrentRegion ? _BulkPjpWizardScreenState._accentOrange : _BulkPjpWizardScreenState._textGrey,
                      ),
                      initiallyExpanded: isCurrentRegion && _searchQuery.isEmpty,
                      children: dealersInRegion.map((dealer) {
                        final isSelected = _selectedDealers.contains(dealer);
                        return CheckboxListTile(
                          activeColor: _BulkPjpWizardScreenState._cardNavy,
                          title: Text(dealer.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: Text(dealer.area, style: const TextStyle(fontSize: 12, color: _BulkPjpWizardScreenState._textGrey)),
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) _selectedDealers.add(dealer);
                              else _selectedDealers.remove(dealer);
                            });
                          },
                        );
                      }).toList(),
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
          child: const Text('CANCEL', style: TextStyle(color: _BulkPjpWizardScreenState._textGrey)),
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