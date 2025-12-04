// lib/technicalSide/screens/bulk_technical_pjp_wizard_screen.dart
import 'package:flutter/material.dart';
import 'package:salesmanapp/models/employee_model.dart';
import 'package:salesmanapp/technicalSide/models/sites_model.dart';
import 'package:salesmanapp/models/dealer_model.dart'; // Import Dealer Model
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
  DateTime _focusedDay = DateTime.now();

  // Selection Mode
  String _selectionMode = 'Sites'; // 'Sites' or 'Dealers'

  // Master pools
  Set<TechnicalSite> _selectedSitePool = {};
  Set<Dealer> _selectedDealerPool = {};

  late Future<List<TechnicalSite>> _sitesFuture;
  late Future<List<Dealer>> _dealersFuture;
  
  List<TechnicalSite> _allSites = [];
  List<Dealer> _allDealers = [];

  // --- FINTECH THEME PALETTE ---
  static const Color _bgLight       = Color(0xFFF3F4F6); 
  static const Color _surfaceWhite  = Colors.white;
  static const Color _cardNavy      = Color(0xFF0F172A); 
  static const Color _textDark      = Color(0xFF111827); 
  static const Color _textGrey      = Color(0xFF6B7280); 
  static const Color _accentGreen   = Color(0xFF10B981); 

  @override
  void initState() {
    super.initState();
    final uid = int.parse(widget.employee.id);
    _sitesFuture = _loadSites(uid);
    _dealersFuture = _loadDealers(uid);
  }

  Future<List<TechnicalSite>> _loadSites(int uid) async {
    try {
      final sites = await _apiService.fetchTechnicalSites(userId: uid, limit: 500);
      if (mounted) setState(() => _allSites = sites);
      return sites;
    } catch (e) {
      dev.log("Error loading sites: $e");
      return [];
    }
  }

  Future<List<Dealer>> _loadDealers(int uid) async {
    try {
      final dealers = await _apiService.fetchDealers(userId: uid, limit: 500);
      if (mounted) setState(() => _allDealers = dealers);
      return dealers;
    } catch (e) {
      dev.log("Error loading dealers: $e");
      return [];
    }
  }

  Future<void> _generateAndSubmitSmartPlan() async {
    setState(() => _isSubmitting = true);
    //final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // --- 1. VALIDATION ---
    const int minVisitsPerDay = 8;

    if (_selectedDates.isEmpty) {
      _showSnack('Please select at least one date.', Colors.orange);
      setState(() => _isSubmitting = false);
      return;
    }

    final int totalItems = _selectedSitePool.length + _selectedDealerPool.length;

    if (totalItems < minVisitsPerDay) {
      _showSnack('Select at least $minVisitsPerDay total visits (Sites + Dealers).', Colors.orange);
      setState(() => _isSubmitting = false);
      return;
    }

    try {
      final sortedDates = _selectedDates.toList()..sort();
      final DateTime baseDate = sortedDates.first;
      int totalCreated = 0;

      // --- 2. SUBMIT SITES (If selected) ---
      if (_selectedSitePool.isNotEmpty) {
        final List<TechnicalSite> sitePool = _selectedSitePool.toList();
        // Simple geo-sort
        sitePool.sort((a, b) => (a.area ?? '').compareTo(b.area ?? ''));
        
        final List<String> allSiteIds = sitePool.map((s) => s.id!).toList();
        
        final response = await _apiService.createBulkPjp(
          userId: int.parse(widget.employee.id),
          createdById: int.parse(widget.employee.id),
          siteIds: allSiteIds,
          dealerIds: null,     
          baseDate: baseDate,
          batchSizePerDay: minVisitsPerDay,
          areaToBeVisited: "Monthly Technical Site Plan",
          status: 'PENDING',
          description: "Bulk Site Plan",
        );
        totalCreated += (response['totalRowsCreated'] as int? ?? 0);
      }

      // --- 3. SUBMIT DEALERS (If selected) ---
      if (_selectedDealerPool.isNotEmpty) {
        final List<Dealer> dealerPool = _selectedDealerPool.toList();
        dealerPool.sort((a, b) => (a.area).compareTo(b.area));
        
        final List<String> allDealerIds = dealerPool.map((d) => d.id!).toList();

        final response = await _apiService.createBulkPjp(
          userId: int.parse(widget.employee.id),
          createdById: int.parse(widget.employee.id),
          siteIds: null,
          dealerIds: allDealerIds,     
          baseDate: baseDate,
          batchSizePerDay: minVisitsPerDay,
          areaToBeVisited: "Monthly Technical Dealer Plan",
          status: 'PENDING',
          description: "Bulk Dealer Plan",
        );
        totalCreated += (response['totalRowsCreated'] as int? ?? 0);
      }

      _showSnack('Technical Plan submitted! $totalCreated visits created.', _accentGreen);
      widget.onPjpCreated();
      navigator.pop();

    } catch (e) {
      _showSnack('Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, Color color) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: _bgLight,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textGrey, size: 20), onPressed: () => Navigator.pop(context)),
        title: Text(_currentStep == 0 ? 'Select Dates' : 'Select Visits', style: const TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: _cardNavy), canvasColor: _bgLight),
        child: Stepper(
          type: StepperType.horizontal,
          elevation: 0,
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep == 0) {
              if (_selectedDates.isEmpty) {
                _showSnack('Please select dates.', Colors.orange);
                return;
              }
              setState(() => _currentStep = 1);
            } else {
              _generateAndSubmitSmartPlan();
            }
          },
          onStepCancel: () {
            if (_currentStep == 1) setState(() => _currentStep = 0);
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
                            style: ElevatedButton.styleFrom(backgroundColor: _cardNavy, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            child: Text(_currentStep == 0 ? 'NEXT STEP' : 'GENERATE PLAN', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                          ),
                        ),
                        if (_currentStep == 1) ...[
                          const SizedBox(width: 16),
                          TextButton(onPressed: details.onStepCancel, child: const Text('BACK', style: TextStyle(color: _textGrey, fontWeight: FontWeight.bold))),
                        ],
                      ],
                    ),
            );
          },
          steps: [
            Step(title: const Text('Schedule'), isActive: _currentStep == 0, state: _currentStep > 0 ? StepState.complete : StepState.indexed, content: _buildCalendarStep()),
            Step(title: const Text('Selection'), isActive: _currentStep == 1, state: _currentStep > 1 ? StepState.complete : StepState.indexed, content: _buildMixedSelectionStep()),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarStep() {
    return Container(
      decoration: BoxDecoration(color: _surfaceWhite, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))]),
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
                if (_selectedDates.contains(selectedDayUtc)) _selectedDates.remove(selectedDayUtc);
                else _selectedDates.add(selectedDayUtc);
              });
            },
            headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true, titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark), leftChevronIcon: Icon(Icons.chevron_left, color: _textGrey), rightChevronIcon: Icon(Icons.chevron_right, color: _textGrey)),
            calendarStyle: CalendarStyle(selectedDecoration: const BoxDecoration(color: _cardNavy, shape: BoxShape.circle), todayDecoration: BoxDecoration(color: _cardNavy.withOpacity(0.4), shape: BoxShape.circle), defaultTextStyle: const TextStyle(color: _textDark), weekendTextStyle: const TextStyle(color: _textDark), outsideTextStyle: const TextStyle(color: Color(0xFFD1D5DB))),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [const Icon(Icons.calendar_today, size: 16, color: _textGrey), const SizedBox(width: 8), Text('${_selectedDates.length} days selected', style: const TextStyle(color: _textDark, fontWeight: FontWeight.bold))],
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 2: Mixed Selection ---
  Widget _buildMixedSelectionStep() {
    final int totalSites = _selectedSitePool.length;
    final int totalDealers = _selectedDealerPool.length;
    final int grandTotal = totalSites + totalDealers;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode Toggle
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(4),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(color: _surfaceWhite, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
          child: Row(
            children: [
              _buildSegmentButton('Sites', 'Sites'),
              _buildSegmentButton('Dealers', 'Dealers'),
            ],
          ),
        ),

        // Display List based on Mode
        if (_selectionMode == 'Sites')
          _buildSitesList(totalSites)
        else
          _buildDealersList(totalDealers),

        const SizedBox(height: 20),
        
        // Grand Total Indicator
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(color: _cardNavy.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Visits Selected:", style: TextStyle(color: _textDark, fontWeight: FontWeight.bold)),
              Text("$grandTotal", style: const TextStyle(color: _cardNavy, fontWeight: FontWeight.w900, fontSize: 16)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildSegmentButton(String label, String value) {
    final isSelected = _selectionMode == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectionMode = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? _cardNavy : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(label, style: TextStyle(color: isSelected ? Colors.white : _textGrey, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
      ),
    );
  }

  // --- SITES LOGIC ---
  Widget _buildSitesList(int count) {
    return FutureBuilder<List<TechnicalSite>>(
      future: _sitesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: _cardNavy));
        if (_allSites.isEmpty) return const Center(child: Text("No sites available.", style: TextStyle(color: _textGrey)));
        
        return Container(
          decoration: BoxDecoration(color: _surfaceWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.transparent), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            title: const Text('Site Pool', style: TextStyle(fontWeight: FontWeight.bold, color: _textDark)),
            subtitle: Text('$count sites selected', style: const TextStyle(color: _textGrey)),
            trailing: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _bgLight, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.edit_rounded, color: _cardNavy, size: 20)),
            onTap: () async {
              final updated = await showDialog<Set<TechnicalSite>>(context: context, builder: (_) => _SiteSelectionDialog(sites: _allSites, initialSelection: _selectedSitePool));
              if (updated != null) setState(() => _selectedSitePool = updated);
            },
          ),
        );
      },
    );
  }

  // --- DEALERS LOGIC ---
  Widget _buildDealersList(int count) {
    return FutureBuilder<List<Dealer>>(
      future: _dealersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: _cardNavy));
        if (_allDealers.isEmpty) return const Center(child: Text("No dealers available.", style: TextStyle(color: _textGrey)));
        
        return Container(
          decoration: BoxDecoration(color: _surfaceWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.transparent), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            title: const Text('Dealer Pool', style: TextStyle(fontWeight: FontWeight.bold, color: _textDark)),
            subtitle: Text('$count dealers selected', style: const TextStyle(color: _textGrey)),
            trailing: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _bgLight, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.edit_rounded, color: _cardNavy, size: 20)),
            onTap: () async {
              final updated = await showDialog<Set<Dealer>>(context: context, builder: (_) => _DealerSelectionDialog(dealers: _allDealers, initialSelection: _selectedDealerPool));
              if (updated != null) setState(() => _selectedDealerPool = updated);
            },
          ),
        );
      },
    );
  }
}

// --- DIALOGS ---

class _SiteSelectionDialog extends StatefulWidget {
  final List<TechnicalSite> sites;
  final Set<TechnicalSite> initialSelection;
  const _SiteSelectionDialog({required this.sites, required this.initialSelection});
  @override
  State<_SiteSelectionDialog> createState() => _SiteSelectionDialogState();
}

class _SiteSelectionDialogState extends State<_SiteSelectionDialog> {
  late Set<TechnicalSite> _selected;
  String _query = '';
  @override
  void initState() { super.initState(); _selected = Set.from(widget.initialSelection); }
  @override
  Widget build(BuildContext context) {
    final filtered = widget.sites.where((s) => s.siteName.toLowerCase().contains(_query.toLowerCase()) || (s.area ?? '').toLowerCase().contains(_query.toLowerCase())).toList();
    return _buildSelectionDialog(
      title: "Select Sites",
      itemCount: filtered.length,
      itemBuilder: (ctx, i) {
        final site = filtered[i];
        final isSel = _selected.contains(site);
        return _buildCheckTile(
          title: site.siteName, subtitle: "${site.area ?? ''} • ${site.stageOfConstruction ?? ''}",
          isSelected: isSel,
          onTap: () => setState(() => isSel ? _selected.remove(site) : _selected.add(site)),
        );
      },
      onSearch: (v) => setState(() => _query = v),
      onSave: () => Navigator.pop(context, _selected),
    );
  }
}

class _DealerSelectionDialog extends StatefulWidget {
  final List<Dealer> dealers;
  final Set<Dealer> initialSelection;
  const _DealerSelectionDialog({required this.dealers, required this.initialSelection});
  @override
  State<_DealerSelectionDialog> createState() => _DealerSelectionDialogState();
}

class _DealerSelectionDialogState extends State<_DealerSelectionDialog> {
  late Set<Dealer> _selected;
  String _query = '';
  @override
  void initState() { super.initState(); _selected = Set.from(widget.initialSelection); }
  @override
  Widget build(BuildContext context) {
    final filtered = widget.dealers.where((d) => d.name.toLowerCase().contains(_query.toLowerCase()) || d.area.toLowerCase().contains(_query.toLowerCase())).toList();
    return _buildSelectionDialog(
      title: "Select Dealers",
      itemCount: filtered.length,
      itemBuilder: (ctx, i) {
        final dealer = filtered[i];
        final isSel = _selected.contains(dealer);
        return _buildCheckTile(
          title: dealer.name, subtitle: "${dealer.area} • ${dealer.region}",
          isSelected: isSel,
          onTap: () => setState(() => isSel ? _selected.remove(dealer) : _selected.add(dealer)),
        );
      },
      onSearch: (v) => setState(() => _query = v),
      onSave: () => Navigator.pop(context, _selected),
    );
  }
}

// --- SHARED UI HELPERS FOR DIALOGS ---
Widget _buildSelectionDialog({required String title, required int itemCount, required Widget Function(BuildContext, int) itemBuilder, required Function(String) onSearch, required VoidCallback onSave}) {
  return AlertDialog(
    backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: Text(title, style: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold)),
    content: SizedBox(
      width: double.maxFinite, height: 400,
      child: Column(children: [
        TextField(
          style: const TextStyle(color: Color(0xFF111827)),
          decoration: const InputDecoration(hintText: 'Search...', prefixIcon: Icon(Icons.search), filled: true, fillColor: Color(0xFFF9FAFB), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none)),
          onChanged: onSearch,
        ),
        const SizedBox(height: 12),
        Expanded(child: ListView.builder(itemCount: itemCount, itemBuilder: itemBuilder)),
      ]),
    ),
    actions: [
      TextButton(onPressed: onSave, child: const Text("SAVE", style: TextStyle(fontWeight: FontWeight.bold))),
    ],
  );
}

Widget _buildCheckTile({required String title, required String subtitle, required bool isSelected, required VoidCallback onTap}) {
  return ListTile(
    onTap: onTap,
    leading: Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: isSelected ? const Color(0xFF0F172A) : Colors.grey[400]),
    title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF111827))),
    subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
    tileColor: isSelected ? const Color(0xFF0F172A).withOpacity(0.05) : null,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );
}