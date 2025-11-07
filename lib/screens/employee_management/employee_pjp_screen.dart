import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:assetarchiverflutter/models/pjp_model.dart';
import 'package:assetarchiverflutter/models/dealer_model.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as dev;

// --- ✅ NEW: Helper class to hold both PJP lists ---
class _PjpData {
  final List<Pjp> pendingPjps;
  final List<Pjp> approvedPjps;
  _PjpData({required this.pendingPjps, required this.approvedPjps});
}

class EmployeePJPScreen extends StatefulWidget {
  final Employee employee;
  final Function(Map<String, dynamic> journeyData) onStartJourney;
  final VoidCallback onPjpCreated;

  const EmployeePJPScreen({
    super.key,
    required this.employee,
    required this.onStartJourney,
    required this.onPjpCreated,
  });

  @override
  State<EmployeePJPScreen> createState() => EmployeePJPScreenState();
}

class EmployeePJPScreenState extends State<EmployeePJPScreen> {
  final ApiService _apiService = ApiService();
  // --- ✅ MODIFIED: Future now holds the _PjpData class ---
  late Future<_PjpData> _pjpDataFuture;

  @override
  void initState() {
    super.initState();
    refreshPjpList();
  }

  // --- ✅ MODIFIED: Fetches both pending and approved ---
  void refreshPjpList() {
    if (mounted) {
      setState(() {
        _pjpDataFuture = _fetchAllPjps();
      });
    }
  }

  // --- ✅ NEW: Helper to fetch in parallel ---
  Future<_PjpData> _fetchAllPjps() async {
    try {
      final userId = int.parse(widget.employee.id);
      // Run both API calls at the same time
      final results = await Future.wait([
        _apiService.fetchPjpsForUser(userId, status: 'pending'),
        _apiService.fetchPjpsForUser(userId, status: 'approved'),
      ]);

      // Note: results[0] is pending, results[1] is approved
      return _PjpData(
        pendingPjps: results[0],
        approvedPjps: results[1],
      );
    } catch (e) {
      // If one fails, they all fail.
      debugPrint("Error fetching PJP data: $e");
      rethrow;
    }
  }

  // --- ✅ MODIFIED: Uses new fetch helper ---
  Future<void> _handleRefresh() async {
    final newPjpDataFuture = _fetchAllPjps();
    if (mounted) {
      setState(() {
        _pjpDataFuture = newPjpDataFuture;
      });
    }
    await newPjpDataFuture;
  }

  // This function is called by the wizard OR the old form when it's done.
  void _handlePjpCreation() {
    refreshPjpList();
    widget.onPjpCreated();
  }

  // --- ✅ NEW: This shows the choice menu ---
  void _showPjpOptions() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.today, color: theme.colorScheme.primary),
                title: Text('Add Single Visit for Today',
                    style: TextStyle(color: theme.colorScheme.onSurface)),
                onTap: () {
                  Navigator.of(context).pop(); // Close the options
                  _showAddPjpForm(); // Open the old form
                },
              ),
              ListTile(
                leading: Icon(Icons.calendar_month,
                    color: theme.colorScheme.secondary),
                title: Text('Create Bulk Monthly Plan',
                    style: TextStyle(color: theme.colorScheme.onSurface)),
                onTap: () {
                  Navigator.of(context).pop(); // Close the options
                  _showBulkPjpWizard(); // Open the new wizard
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- This is your ORIGINAL function, UNCHANGED ---
  void _showAddPjpForm() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddPjpForm(
        employee: widget.employee,
        onPjpCreated: _handlePjpCreation,
        theme: theme,
      ),
    );
  }

  // --- ✅ NEW: This opens the new full-screen "Bulk PJP Wizard" ---
  void _showBulkPjpWizard() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => BulkPjpWizardScreen(
          employee: widget.employee,
          onPjpCreated: _handlePjpCreation,
        ),
      ),
    );
  }

  Future<void> _startJourneyForPjp(Pjp pjp) async {
    // ... (Your journey logic is unchanged) ...
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final parts = pjp.areaToBeVisited.split('|');
      if (parts.length != 3) {
        throw const FormatException('Invalid PJP data format.');
      }
      final String displayName = parts[0];
      final double? lat = double.tryParse(parts[1]);
      final double? lon = double.tryParse(parts[2]);
      if (lat == null || lon == null) {
        throw const FormatException('Could not parse coordinates from PJP.');
      }
      await _apiService.updatePjp(pjp.id, {'status': 'started'});
      scaffoldMessenger.showSnackBar(const SnackBar(
          content: Text('Journey Planned, redirecting...'),
          backgroundColor: Colors.green));
      refreshPjpList();
      widget.onPjpCreated();
      widget.onStartJourney({
        'pjpId': pjp.id,
        'displayName': displayName,
        'destination': LatLng(lat, lon),
      });
    } catch (e) {
      debugPrint("Failed to start journey: $e");
      scaffoldMessenger.showSnackBar(SnackBar(
          content:
              Text('Failed to start journey: PJP has invalid location data.'),
          backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        // --- ✅ MODIFIED: Now watches the new _PjpData future ---
        FutureBuilder<_PjpData>(
          future: _pjpDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return Center(
                  child: CircularProgressIndicator(
                      color: theme.colorScheme.primary));
            }
            if (snapshot.hasError) {
              // --- ✅ DEBUGGING: Show the actual error ---
              dev.log('PJP Future error: ${snapshot.error}', name: 'EmployeePJPScreen');
              return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Error: ${snapshot.error}',
                        style: TextStyle(color: theme.colorScheme.error)),
                  ));
            }

            // --- ✅ MODIFIED: Handle new data structure ---
            final pjpData = snapshot.data!;
            final pendingPjps = pjpData.pendingPjps;
            final approvedPjps = pjpData.approvedPjps;

            if (pendingPjps.isEmpty && approvedPjps.isEmpty) {
              return RefreshIndicator(
                onRefresh: _handleRefresh,
                child: Stack(
                  children: [
                    ListView(),
                    Center(
                        child: Text('No PJPs found.', // <-- Updated text
                            style: TextStyle(
                                color: theme.colorScheme.onBackground
                                    .withOpacity(0.7)))),
                  ],
                ),
              );
            }

            // --- ✅ NEW: Build a list with sections ---
            // --- ✅ MODIFIED: Your "Surprise UI" logic ---
            // We now have two headers and two lists
            final totalItemCount = (pendingPjps.isNotEmpty ? 1 : 0) +
                (approvedPjps.isNotEmpty ? 1 + approvedPjps.length : 0);
            
            // --- ✅ DEBUGGING: Log counts ---
            dev.log('Building PJP list: ${pendingPjps.length} pending, ${approvedPjps.length} approved', name: 'EmployeePJPScreen');


            return RefreshIndicator(
              onRefresh: _handleRefresh,
              color: theme.colorScheme.onPrimary,
              backgroundColor: theme.colorScheme.primary,
              child: ListView.builder(
                padding: EdgeInsets.only(
                    top: kToolbarHeight + MediaQuery.of(context).padding.top,
                    bottom: 80),
                itemCount: totalItemCount,
                itemBuilder: (context, index) {
                  // --- This logic builds the sectioned list ---

                  // --- ✅ 1. Pending Summary Card (Your "Smart UI") ---
                  if (pendingPjps.isNotEmpty && index == 0) {
                    return _PendingPjpSummaryCard(
                        count: pendingPjps.length);
                  }

                  // --- ✅ 2. Approved Header ---
                  final approvedHeaderIndex =
                      (pendingPjps.isNotEmpty ? 1 : 0);
                  if (approvedPjps.isNotEmpty && index == approvedHeaderIndex) {
                    return _PjpSectionHeader(
                        title: 'Approved Visits (${approvedPjps.length})');
                  }

                  // --- ✅ 3. Approved Items (Slidable) ---
                  if (index -
                          approvedHeaderIndex -
                          (approvedPjps.isNotEmpty ? 1 : 0) <
                      approvedPjps.length) {
                    final pjp = approvedPjps[index -
                        approvedHeaderIndex -
                        (approvedPjps.isNotEmpty ? 1 : 0)];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      // Your original Slidable card for pending items
                      child: Slidable(
                        key: ValueKey(pjp.id),
                        startActionPane: ActionPane(
                          motion: const StretchMotion(),
                          children: [
                            SlidableAction(
                              // --- ✅ Only allow starting APPROVED PJPs ---
                              onPressed: (_) => _startJourneyForPjp(pjp),
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              icon: Icons.route,
                              label: 'Start Journey',
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ],
                        ),
                        // --- ✅ Card now shows "approved" style ---
                        child: _PjpCard(pjp: pjp, isApproved: true),
                      ),
                    );
                  }

                  return Container(); // Should not happen
                },
              ),
            );
          },
        ),
        Positioned(
          bottom: 120.0,
          right: 16.0,
          child: FloatingActionButton(
            onPressed: _showPjpOptions, // <-- Now shows the menu
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.onSecondary,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

// --- ✅ MODIFIED: _PjpCard now shows status ---
class _PjpCard extends StatelessWidget {
  final Pjp pjp;
  final bool isApproved; // <-- NEW: To change appearance

  const _PjpCard({required this.pjp, required this.isApproved});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // --- ✅ UPDATED: Show dealer name if available, fallback to area ---
    final displayName = pjp.dealerName ?? pjp.areaToBeVisited.split('|').first;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- ✅ NEW: Show status icon ---
            Icon(
              // --- ✅ Logic changed: show checkmark for approved ---
              isApproved ? Icons.check_circle : Icons.pending_actions,
              color: isApproved ? Colors.green : theme.colorScheme.primary,
              size: 30,
            ),
            const SizedBox(width: 16),
            // --- END NEW ---
            Expanded(
              child: Text(
                displayName,
                style: textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            // --- ✅ MODIFIED: Only show arrow for approved/actionable items ---
            if (isApproved)
              Icon(Icons.keyboard_arrow_right,
                  color: theme.colorScheme.onSurface.withOpacity(0.7), size: 30),
          ],
        ),
      ),
    );
  }
}

// --- ✅ NEW: Your "Smart UI Element" ---
class _PendingPjpSummaryCard extends StatelessWidget {
  final int count;
  const _PendingPjpSummaryCard({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Row(
          children: [
            Icon(Icons.hourglass_top,
                color: theme.colorScheme.onSecondaryContainer),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                '$count visits are pending approval',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// --- ✅ NEW: Header Widget ---
class _PjpSectionHeader extends StatelessWidget {
  final String title;
  const _PjpSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 24.0, 16.0, 8.0),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// --- (AddPjpForm and AddPjpFormState are UNCHANGED) ---
// This is your original code, preserved as requested.
class AddPjpForm extends StatefulWidget {
  final Employee employee;
  final VoidCallback onPjpCreated;
  final ThemeData theme;
  const AddPjpForm({
    super.key,
    required this.employee,
    required this.onPjpCreated,
    required this.theme,
  });
  @override
  State<AddPjpForm> createState() => AddPjpFormState();
}

class AddPjpFormState extends State<AddPjpForm> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  Dealer? _selectedDealer;
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  late Future<List<Dealer>> _dealersFuture;
  @override
  void initState() {
    super.initState();
    _dealersFuture =
        _apiService.fetchDealers(userId: int.parse(widget.employee.id));
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _selectedDealer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select a dealer.'),
          backgroundColor: Colors.orange));
      return;
    }
    final dealer = _selectedDealer!;
    if (dealer.latitude == null || dealer.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('The selected dealer does not have location data saved.'),
          backgroundColor: Colors.orange));
      return;
    }
    setState(() => _isSubmitting = true);
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final String displayName = '${dealer.name}, ${dealer.address}';
      final String visitData =
          '$displayName|${dealer.latitude}|${dealer.longitude}';
      final newPjp = Pjp(
        id: '',
        planDate: DateTime.now(),
        userId: int.parse(widget.employee.id),
        createdById: int.parse(widget.employee.id),
        status: 'pending',
        areaToBeVisited: visitData,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        // --- ✅ UPDATED: Send dealerId ---
        dealerId: dealer.id,
        dealerName: dealer.name,
        // ---
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _apiService.createPjp(newPjp);

      widget.onPjpCreated();
      navigator.pop();
      scaffoldMessenger.showSnackBar(const SnackBar(
          content: Text('PJP Created!'), backgroundColor: Colors.green));
    } catch (e) {
      debugPrint('--- FAILED TO CREATE PJP ---\nError: $e');
      scaffoldMessenger.showSnackBar(SnackBar(
          content: Text('Failed to create PJP: $e'),
          backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (Your build method is unchanged) ...
    final theme = widget.theme;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create New PJP',
                  style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              FutureBuilder<List<Dealer>>(
                future: _dealersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text('Error loading dealers: ${snapshot.error}',
                        style: TextStyle(color: theme.colorScheme.error));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Text('No dealers found for this user.',
                        style: TextStyle(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.7)));
                  }
                  return DropdownButtonFormField<Dealer>(
                    hint: Text('Select a Dealer',
                        style: TextStyle(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.7))),
                    isExpanded: true,
                    dropdownColor: theme.colorScheme.surface,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    items: snapshot.data!
                        .map((dealer) => DropdownMenuItem(
                            value: dealer,
                            child: Text(
                              dealer.name,
                              overflow: TextOverflow.ellipsis,
                            )))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedDealer = value),
                    validator: (value) =>
                        value == null ? 'Please select a dealer' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  labelStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.7)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: theme.colorScheme.onSurface.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: theme.elevatedButtonTheme.style?.copyWith(
                    minimumSize: MaterialStateProperty.all(
                        const Size(double.infinity, 50))),
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('SUBMIT PJP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- ✨ NEW WIDGET: The Bulk PJP Creation Wizard ---

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

  // --- State for the wizard ---
  Set<DateTime> _selectedDates = {};
  
  // --- ✅ FIX 2: "Time Traveler" Bug ---
  // Start the focusedDay on TOMORROW, not today, because
  // firstDay is set to tomorrow.
  DateTime _focusedDay = DateTime.now().add(const Duration(days: 1));
  // --- END FIX 2 ---

  Map<DateTime, Set<Dealer>> _plan = {};

  // --- ✅ NEW: State for real data ---
  late Future<Map<String, List<Dealer>>> _dealersByRegionFuture;
  Map<String, List<Dealer>> _loadedDealersByRegion = {}; // Cache for dialog

  @override
  void initState() {
    super.initState();
    // --- ✅ NEW: Call the real data loader ---
    _dealersByRegionFuture = _loadDealers();
  }

  // --- ✅ NEW: This fetches REAL dealer data ---
  Future<Map<String, List<Dealer>>> _loadDealers() async {
    try {
      // --- ✅ DEBUGGING: Log the API call ---
      dev.log('BulkPjpWizard: Fetching dealers for user ${widget.employee.id}', name: 'EmployeePJPScreen');
      final dealers =
          await _apiService.fetchDealers(userId: int.parse(widget.employee.id));
      dev.log('BulkPjpWizard: Found ${dealers.length} dealers.', name: 'EmployeePJPScreen');
      _loadedDealersByRegion = _groupDealersByRegion(dealers); // Cache the result
      return _loadedDealersByRegion;
    } catch (e) {
      dev.log("Error loading dealers: $e", name: 'EmployeePJPScreen', error: e);
      // Re-throw to be caught by FutureBuilder
      throw Exception('Failed to load dealers: $e');
    }
  }

  Map<String, List<Dealer>> _groupDealersByRegion(List<Dealer> dealers) {
    Map<String, List<Dealer>> map = {};
    for (var dealer in dealers) {
      (map[dealer.region] ??= []).add(dealer);
    }
    return map;
  }

  // --- ✅ NEW: Logic for Submitting ---
  Future<void> _submitBulkPlan() async {
    setState(() => _isSubmitting = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // --- Business Logic Check (Your 8-visit rule) ---
    const int minVisitsPerDay = 8; // <-- YOUR 8-VISIT RULE
    bool allDatesValid = true;
    
    // --- ✅ Collect ALL unique dealers ---
    final Set<Dealer> allDealersInPlan = {};
    DateTime? baseDate; // Find the earliest date

    for (var entry in _plan.entries) {
      final date = entry.key;
      final dealersForDay = entry.value;

      // 1. Check 8-visit rule
      if (dealersForDay.length < minVisitsPerDay) {
        allDatesValid = false;
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
                'Error: ${DateFormat.yMMMd().format(date)} has fewer than $minVisitsPerDay dealers selected.'),
            backgroundColor: Colors.red,
          ),
        );
        break; // Stop on first error
      }
      
      // 2. Find the earliest date
      if (baseDate == null || date.isBefore(baseDate)) {
        baseDate = date;
      }
      
      // 3. Add dealers to the master set
      allDealersInPlan.addAll(dealersForDay);
    }

    if (!allDatesValid) {
      if (mounted) setState(() => _isSubmitting = false);
      return;
    }

    if (baseDate == null || allDealersInPlan.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('No dealers or dates selected.'), backgroundColor: Colors.orange),
      );
      if (mounted) setState(() => _isSubmitting = false);
      return;
    }

    // --- ✅ REAL SUBMISSION ---
    try {
      // 1. Get the list of dealer IDs
      final List<String> dealerIds = allDealersInPlan.map((d) => d.id!).where((id) => id.isNotEmpty).toList();
      
      // 2. Call the new bulk API
      dev.log('Submitting bulk PJP: ${dealerIds.length} unique dealers, starting from $baseDate', name: 'EmployeePJPScreen');
      final response = await _apiService.createBulkPjp(
        userId: int.parse(widget.employee.id),
        createdById: int.parse(widget.employee.id),
        dealerIds: dealerIds,
        baseDate: baseDate,
        batchSizePerDay: minVisitsPerDay, // Use your 8-visit rule
        areaToBeVisited: "Monthly PJP Plan", // Default value as per server schema
        status: 'PENDING',
      );

      final createdCount = response['totalRowsCreated'] ?? 0;
      final skippedCount = response['totalRowsSkipped'] ?? 0;

      scaffoldMessenger.showSnackBar(
        SnackBar(
            content: Text('Bulk PJP submitted! $createdCount created, $skippedCount skipped.'),
            backgroundColor: Colors.green),
      );
      
      widget.onPjpCreated(); // Refresh the main PJP list
      navigator.pop(); // Close the wizard
      
    } catch (e) {
      dev.log('Error submitting bulk plan: $e', name: 'EmployeePJPScreen', error: e);
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
            // Submit logic
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
            // --- ✅ FIX 2: Set firstDay to TODAY ---
            // This fixes the 'Time Traveler' bug.
            firstDay: DateTime.now(),
            // --- END FIX 2 ---
            lastDay: DateTime.now().add(const Duration(days: 60)),
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate: (day) => _selectedDates.contains(day),
            onDaySelected: (selectedDay, focusedDay) {
              final selectedDayUtc =
                  DateTime.utc(selectedDay.year, selectedDay.month, selectedDay.day);
              setState(() {
                // --- ✅ DEBUGGING: Log date selection ---
                dev.log('Selected: $selectedDayUtc, Focused: $focusedDay', name: 'EmployeePJPScreen');
                _focusedDay = focusedDay;
                if (_selectedDates.contains(selectedDayUtc)) {
                  _selectedDates.remove(selectedDayUtc);
                  _plan.remove(selectedDayUtc); // Remove from plan
                } else {
                  _selectedDates.add(selectedDayUtc);
                  _plan[selectedDayUtc] = {}; // Add an empty set to the plan
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
              // Normalize today to UTC midnight
              final normalizedToday =
                  DateTime.utc(today.year, today.month, today.day);
              // Normalize the day to UTC midnight
              final normalizedDay =
                  DateTime.utc(day.year, day.month, day.day);
              // A day is enabled if it is NOT before today
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

  // --- ✅ MODIFIED: This is the user's pasted code, now updated to use the FutureBuilder ---
  Step _buildStep2DealerAssignment(ThemeData theme) {
    // Sort the selected dates so they appear in order
    final sortedDates = _selectedDates.toList()..sort();

    // --- ✅ UPDATED: Your 8-visit rule ---
    const int minVisits = 8;

    return Step(
      title: const Text('Dealers'),
      isActive: _currentStep == 1,
      // --- ✅ MODIFIED: Wrap content in a FutureBuilder ---
      content: FutureBuilder<Map<String, List<Dealer>>>(
        future: _dealersByRegionFuture, // <-- Use the future
        builder: (context, snapshot) {
          // --- Handle loading state ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          // --- Handle error state ---
          if (snapshot.hasError) {
             // --- ✅ DEBUGGING: Log the dealer fetch error ---
            dev.log('Error in _buildStep2DealerAssignment: ${snapshot.error}', name: 'EmployeePJPScreen', error: snapshot.error);
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

          // --- Handle empty/no data state ---
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // This uses the same check as the user's code `_dealersByRegion.isEmpty`
            // but now it's based on the snapshot.
            return const Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No dealers found for this user.'),
            );
          }

          // --- ✅ SUCCESS: We have data. Build the real UI ---
          // The user's original logic from here down.
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
                        DateFormat.yMMMd().format(
                          date,
                        ), // e.g., "Nov 8, 2025"
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
                        color: hasError
                            ? theme.colorScheme.error
                            : Colors.green,
                      ),
                      onTap: () async {
                        // --- This opens the dealer selection dialog ---
                        final updatedDealers = await showDialog<Set<Dealer>>(
                          context: context,
                          builder: (_) => _DealerSelectionDialog(
                            theme: theme,
                            // --- ✅ Use the cached, loaded dealers ---
                            dealersByRegion: _loadedDealersByRegion,
                            // Pass in the dealers already selected for this date
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

// --- ✨ NEW WIDGET: The Dialog for Selecting Dealers ---
// ... (This widget is UNCHANGED from the previous version) ...
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
  // Use a local Set to manage changes *before* saving
  late Set<Dealer> _selectedDealers;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Copy the initial selection into the local state
    _selectedDealers = Set.from(widget.initialSelection);
  }

  @override
  Widget build(BuildContext context) {
    final regions = widget.dealersByRegion.keys.toList();

    // --- ✅ NEW: Filter regions based on search query ---
    final filteredRegions = regions.where((region) {
      if (_searchQuery.isEmpty) return true; // Show all if no query
      // Check if region name matches
      if (region.toLowerCase().contains(_searchQuery.toLowerCase()))
        return true;
      // Check if any dealer in this region matches
      return widget.dealersByRegion[region]!.any(
        (dealer) =>
            dealer.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            dealer.area.toLowerCase().contains(_searchQuery.toLowerCase()),
      );
    }).toList();

    return AlertDialog(
      title: const Text('Select Dealers'),
      // --- ✅ UPDATED: Use a Column for search + list ---
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
            height:
                MediaQuery.of(context).size.height * 0.5, // Constrain height
            // --- This list shows all dealers grouped by region ---
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filteredRegions.length, // Use filtered list
              itemBuilder: (context, index) {
                final region = filteredRegions[index];

                // --- ✅ NEW: Filter dealers within the region ---
                final dealersInRegion = widget.dealersByRegion[region]!.where((
                  dealer,
                ) {
                  if (_searchQuery.isEmpty) return true;
                  return dealer.name.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      dealer.area.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      region.toLowerCase().contains(_searchQuery.toLowerCase());
                }).toList();

                // If search query hides all dealers, hide the region
                if (dealersInRegion.isEmpty) return const SizedBox.shrink();

                return ExpansionTile(
                  title: Text(
                    region,
                    style: widget.theme.textTheme.titleMedium,
                  ),
                  initiallyExpanded:
                      _searchQuery.isNotEmpty, // Expand if searching
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
            // --- Send the final set of selected dealers back ---
            Navigator.of(context).pop(_selectedDealers);
          },
          child: Text('SAVE (${_selectedDealers.length})'), // Show count
        ),
      ],
    );
  }
}