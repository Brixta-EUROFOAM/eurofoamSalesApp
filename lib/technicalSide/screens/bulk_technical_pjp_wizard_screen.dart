// lib/technicalSide/screens/technical_bulk_wizard.dart
import 'package:flutter/material.dart';
import 'package:salesmanapp/models/employee_model.dart';
import 'package:salesmanapp/technicalSide/models/sites_model.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:developer' as dev;

class BulkTechnicalPjpWizardScreen extends StatefulWidget {
  final Employee employee;
  final VoidCallback onPjpCreated;

  const BulkTechnicalPjpWizardScreen({
    super.key,
    required this.employee,
    required this.onPjpCreated,
  });

  @override
  State<BulkTechnicalPjpWizardScreen> createState() => _BulkTechnicalPjpWizardScreenState();
}

class _BulkTechnicalPjpWizardScreenState extends State<BulkTechnicalPjpWizardScreen> {
  int _currentStep = 0;
  bool _isSubmitting = false;
  final ApiService _apiService = ApiService();

  Set<DateTime> _selectedDates = {};
  DateTime _focusedDay = DateTime.now().add(const Duration(days: 1));

  // Master pool of all selected sites
  Set<TechnicalSite> _selectedSitePool = {};

  late Future<List<TechnicalSite>> _sitesFuture;
  List<TechnicalSite> _allSites = [];

  // --- FINTECH THEME ---
  static const Color _cardNavy = Color(0xFF0F172A);
  
  @override
  void initState() {
    super.initState();
    _sitesFuture = _loadSites();
  }

  Future<List<TechnicalSite>> _loadSites() async {
    try {
      final sites = await _apiService.fetchTechnicalSites(
        userId: int.parse(widget.employee.id),
        limit: 500, // Fetch plenty
      );
      if (mounted) {
        setState(() {
          _allSites = sites;
        });
      }
      return sites;
    } catch (e) {
      dev.log("Error loading sites: $e");
      return [];
    }
  }

  Future<void> _generateAndSubmitSmartPlan() async {
    setState(() => _isSubmitting = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // --- 1. VALIDATION ---
    const int minVisitsPerDay = 9;

    if (_selectedDates.isEmpty) {
      scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('Please select at least one date.'),
        backgroundColor: Colors.orange,
      ));
      if (mounted) setState(() => _isSubmitting = false);
      return;
    }

    final List<TechnicalSite> sitePool = _selectedSitePool.toList();

    if (sitePool.length < minVisitsPerDay) {
      scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('Please select at least $minVisitsPerDay unique sites to create a plan.'),
        backgroundColor: Colors.orange,
      ));
      if (mounted) setState(() => _isSubmitting = false);
      return;
    }

    // --- 2. THE SCHEDULING ALGORITHM ---
    final sortedDates = _selectedDates.toList()..sort();
    
    // Sort pool by area to group visits geographically (simple optimization)
    sitePool.sort((a, b) => (a.area ?? '').compareTo(b.area ?? ''));

    // Track visits
    final Map<String, int> siteVisitCount = { for (var s in sitePool) s.id!: 0 };

    for (final date in sortedDates) {
      // Pick sites with least visits so far
      sitePool.sort((a, b) => siteVisitCount[a.id!]!.compareTo(siteVisitCount[b.id!]!));
      final sitesForThisDay = sitePool.take(minVisitsPerDay);
      for (var site in sitesForThisDay) {
        siteVisitCount[site.id!] = siteVisitCount[site.id!]! + 1;
      }
    }

    // --- 4. SUBMIT TO API ---
    try {
      final List<String> allSiteIds = sitePool.map((s) => s.id!).toList();
      final DateTime baseDate = sortedDates.first;

      const String planDescription = "Monthly Technical Visit Plan";

      final response = await _apiService.createBulkPjp(
        userId: int.parse(widget.employee.id),
        createdById: int.parse(widget.employee.id),
        siteIds: allSiteIds,
        dealerIds: null,     
        baseDate: baseDate,
        batchSizePerDay: minVisitsPerDay,
        areaToBeVisited: planDescription,
        status: 'PENDING',
        description: planDescription,
      );

      final createdCount = response['totalRowsCreated'] ?? 0;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Technical Plan submitted! $createdCount visits created.'),
          backgroundColor: Colors.green,
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
      appBar: AppBar(
        title: Text(_currentStep == 0 ? 'Select Dates' : 'Select Sites'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _cardNavy,
      ),
      body: Stepper(
        type: StepperType.horizontal,
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
            padding: const EdgeInsets.only(top: 24.0),
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
                          ),
                          child: Text(_currentStep == 0 ? 'NEXT' : 'SUBMIT PLAN'),
                        ),
                      ),
                      if (_currentStep == 1) ...[
                        const SizedBox(width: 16),
                        TextButton(
                          onPressed: details.onStepCancel,
                          child: const Text('BACK', style: TextStyle(color: Colors.grey)),
                        ),
                      ],
                    ],
                  ),
          );
        },
        steps: [
          Step(
            title: const Text('Dates'),
            isActive: _currentStep == 0,
            content: TableCalendar(
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
              headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
              calendarStyle: const CalendarStyle(
                selectedDecoration: BoxDecoration(color: _cardNavy, shape: BoxShape.circle),
                todayDecoration: BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
              ),
            ),
          ),
          Step(
            title: const Text('Sites'),
            isActive: _currentStep == 1,
            content: FutureBuilder<List<TechnicalSite>>(
              future: _sitesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_allSites.isEmpty) {
                  return const Text("No sites found.");
                }
                
                return Column(
                  children: [
                    Text("Select at least 8 sites for the plan.", style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 16),
                    Container(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _allSites.length,
                        separatorBuilder: (ctx, i) => const Divider(),
                        itemBuilder: (context, index) {
                          final site = _allSites[index];
                          final isSelected = _selectedSitePool.contains(site);
                          return CheckboxListTile(
                            activeColor: _cardNavy,
                            title: Text(site.siteName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("${site.area} • ${site.stageOfConstruction ?? 'N/A'}"),
                            value: isSelected,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) _selectedSitePool.add(site);
                                else _selectedSitePool.remove(site);
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}