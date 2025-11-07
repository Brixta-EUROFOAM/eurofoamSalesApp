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

const _log = 'EmployeePJPScreen';

/// Uses public `PjpData` from pjp_model.dart (pending + verified)
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
  late Future<PjpData> _pjpDataFuture;

  @override
  void initState() {
    super.initState();
    dev.log('initState: employeeId=${widget.employee.id}', name: _log);
    refreshPjpList();
  }

  void refreshPjpList() {
    final uid = int.tryParse(widget.employee.id);
    dev.log('refreshPjpList() → fetchPendingAndVerifiedPjps(userId=$uid)', name: _log);
    if (mounted) {
      setState(() {
        _pjpDataFuture = _apiService.fetchPendingAndVerifiedPjps(
          userId: uid ?? -1,
        );
      });
    }
  }

  Future<void> _handleRefresh() async {
    final uid = int.tryParse(widget.employee.id);
    dev.log('onRefresh → fetchPendingAndVerifiedPjps(userId=$uid)', name: _log);
    final fut = _apiService.fetchPendingAndVerifiedPjps(userId: uid ?? -1);
    if (mounted) setState(() => _pjpDataFuture = fut);
    await fut;
  }

  void _handlePjpCreation() {
    dev.log('onPjpCreated hook → refresh list', name: _log);
    refreshPjpList();
    widget.onPjpCreated();
  }

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
                  Navigator.of(context).pop();
                  _showAddPjpForm();
                },
              ),
              ListTile(
                leading: Icon(Icons.calendar_month,
                    color: theme.colorScheme.secondary),
                title: Text('Create Bulk Monthly Plan',
                    style: TextStyle(color: theme.colorScheme.onSurface)),
                onTap: () {
                  Navigator.of(context).pop();
                  _showBulkPjpWizard();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddPjpForm() {
    dev.log('Open AddPjpForm', name: _log);
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

  void _showBulkPjpWizard() {
    dev.log('Open BulkPjpWizardScreen', name: _log);
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

      dev.log('Start Journey for PJP id=${pjp.id}', name: _log);
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
    } catch (e, st) {
      dev.log('Failed to start journey', name: _log, error: e, stackTrace: st);
      scaffoldMessenger.showSnackBar(SnackBar(
          content:
              const Text('Failed to start journey: PJP has invalid location data.'),
          backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        FutureBuilder<PjpData>(
          future: _pjpDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return Center(
                  child: CircularProgressIndicator(
                      color: theme.colorScheme.primary));
            }
            if (snapshot.hasError) {
              dev.log('PJP Future error: ${snapshot.error}', name: _log);
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error: ${snapshot.error}',
                      style: TextStyle(color: theme.colorScheme.error)),
                ),
              );
            }

            final pjpData = snapshot.data;
            if (pjpData == null) {
              dev.log('Future completed but data==null', name: _log);
              return Center(
                child: Text('No data received',
                    style: TextStyle(color: theme.colorScheme.error)),
              );
            }

            final pendingPjps = pjpData.pendingPjps;
            final verifiedPjps = pjpData.verifiedPjps;

            if (pendingPjps.isEmpty && verifiedPjps.isEmpty) {
              return RefreshIndicator(
                onRefresh: _handleRefresh,
                child: Stack(
                  children: [
                    ListView(),
                    Center(
                        child: Text('No PJPs found.',
                            style: TextStyle(
                                color: theme.colorScheme.onBackground
                                    .withOpacity(0.7)))),
                  ],
                ),
              );
            }

            final totalItemCount = (pendingPjps.isNotEmpty ? 1 : 0) +
                (verifiedPjps.isNotEmpty ? 1 + verifiedPjps.length : 0);

            dev.log(
              'Building PJP list: pending=${pendingPjps.length}, verified=${verifiedPjps.length}, totalItems=$totalItemCount',
              name: _log,
            );

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
                  // 1) Pending summary card
                  if (pendingPjps.isNotEmpty && index == 0) {
                    return _PendingPjpSummaryCard(count: pendingPjps.length);
                  }

                  // 2) Verified header
                  final verifiedHeaderIndex =
                      (pendingPjps.isNotEmpty ? 1 : 0);
                  if (verifiedPjps.isNotEmpty &&
                      index == verifiedHeaderIndex) {
                    return _PjpSectionHeader(
                        title: 'Verified Visits (${verifiedPjps.length})');
                  }

                  // 3) Verified items
                  if (index -
                          verifiedHeaderIndex -
                          (verifiedPjps.isNotEmpty ? 1 : 0) <
                      verifiedPjps.length) {
                    final pjp = verifiedPjps[index -
                        verifiedHeaderIndex -
                        (verifiedPjps.isNotEmpty ? 1 : 0)];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Slidable(
                        key: ValueKey(pjp.id),
                        startActionPane: ActionPane(
                          motion: const StretchMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (_) => _startJourneyForPjp(pjp),
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              icon: Icons.route,
                              label: 'Start Journey',
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ],
                        ),
                        child: _PjpCard(pjp: pjp, isVerified: true),
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            );
          },
        ),
        Positioned(
          bottom: 120.0,
          right: 16.0,
          child: FloatingActionButton(
            onPressed: _showPjpOptions,
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.onSecondary,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

// --- Card showing a single PJP row ---
class _PjpCard extends StatelessWidget {
  final Pjp pjp;
  final bool isVerified;

  const _PjpCard({required this.pjp, required this.isVerified});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final displayName = pjp.dealerName ?? pjp.areaToBeVisited.split('|').first;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              isVerified ? Icons.check_circle : Icons.pending_actions,
              color: isVerified ? Colors.green : theme.colorScheme.primary,
              size: 30,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                displayName,
                style: textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            if (isVerified)
              Icon(Icons.keyboard_arrow_right,
                  color: theme.colorScheme.onSurface.withOpacity(0.7), size: 30),
          ],
        ),
      ),
    );
  }
}

// --- Pending summary pill/card ---
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

// --- Section header ---
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

// =========================
// AddPjpForm (single create)
// =========================
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
    dev.log('AddPjpForm.initState → load dealers for user ${widget.employee.id}', name: _log);
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
      dev.log('Submit blocked: form invalid or dealer null', name: _log);
      return;
    }
    final dealer = _selectedDealer!;
    if (dealer.latitude == null || dealer.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('The selected dealer does not have location data saved.'),
          backgroundColor: Colors.orange));
      dev.log('Submit blocked: dealer lacks lat/lon (dealerId=${dealer.id})', name: _log);
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
        status: 'PENDING', // server expects uppercase
        areaToBeVisited: visitData,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        dealerId: dealer.id,
        dealerName: dealer.name,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Debug payload snapshot
      dev.log(
        'CREATE PJP → payload: {userId=${newPjp.userId}, createdById=${newPjp.createdById}, dealerId=${newPjp.dealerId}, '
        'status=${newPjp.status}, area="${newPjp.areaToBeVisited}", description="${newPjp.description}", '
        'planDate=${newPjp.planDate.toIso8601String()}}',
        name: _log,
      );

      final sw = Stopwatch()..start();
      final created = await _apiService.createPjp(newPjp);
      sw.stop();

      dev.log(
        'CREATE PJP ← success in ${sw.elapsedMilliseconds}ms (id=${created.id}, status=${created.status})',
        name: _log,
      );

      widget.onPjpCreated();
      navigator.pop();
      scaffoldMessenger.showSnackBar(const SnackBar(
          content: Text('PJP Created!'), backgroundColor: Colors.green));
    } catch (e, st) {
      dev.log('CREATE PJP ← ERROR', name: _log, error: e, stackTrace: st);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to create PJP: $e'),
          backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
      (map[dealer.region] ??= []).add(dealer);
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
          .map((d) => d.id!)
          .where((id) => id.isNotEmpty)
          .toList();

      dev.log(
          'Submitting bulk PJP: ${dealerIds.length} unique dealers, starting from $baseDate',
          name: _log);

      final response = await _apiService.createBulkPjp(
        userId: int.parse(widget.employee.id),
        createdById: int.parse(widget.employee.id),
        dealerIds: dealerIds,
        baseDate: baseDate,
        batchSizePerDay: minVisitsPerDay,
        areaToBeVisited: "Monthly PJP Plan",
        status: 'PENDING',
      );

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
