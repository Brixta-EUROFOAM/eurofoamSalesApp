// lib/screens/employee_management/employee_pjp_screen.dart

import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:assetarchiverflutter/models/pjp_model.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'dart:developer' as dev;
import 'dart:async'; // ✅ Timer for auto-collapse
import 'package:intl/intl.dart'; // ✅ NEW: for YYYY-MM-DD formatting

import 'package:assetarchiverflutter/widgets/pjp_cards.dart';
import 'package:assetarchiverflutter/screens/forms/add_pjp_form.dart';
import 'package:assetarchiverflutter/screens/employee_management/bulk_pjp_wizard_screen.dart';

const _log = 'EmployeePJPScreen';

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

  PjpData? _currentPjpData;

  // --- ✅ NEW: State for animated deck ---
  bool _isDeckExpanded = false;
  Timer? _collapseTimer; // auto-collapse timer
  // ---

  // --- ✅ NEW: Helper to get YYYY-MM-DD string ---
  String _isoDate(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);

  @override
  void initState() {
    super.initState();
    dev.log('initState: employeeId=${widget.employee.id}', name: _log);
    refreshPjpList();
  }

  @override
  void dispose() {
    _collapseTimer?.cancel(); // ✅ prevent timer leaks
    super.dispose();
  }

  void refreshPjpList() {
    final uid = int.tryParse(widget.employee.id);
    if (uid == null) return;

    final todayString = _isoDate(DateTime.now());
    dev.log('refreshPjpList() → fetch PJPs for $todayString (userId=$uid)', name: _log);

    if (mounted) {
      setState(() {
        _currentPjpData = null;
        _pjpDataFuture = _apiService.fetchPendingAndVerifiedPjps(
          userId: uid,
          startDate: todayString,  // ✅ only today
          endDate: todayString,    // ✅ only today
        );
      });
    }
  }

  Future<void> _handleRefresh() async {
    final uid = int.tryParse(widget.employee.id);
    if (uid == null) return;

    final todayString = _isoDate(DateTime.now());
    dev.log('onRefresh → fetch PJPs for $todayString (userId=$uid)', name: _log);

    final fut = _apiService.fetchPendingAndVerifiedPjps(
      userId: uid,
      startDate: todayString,  // ✅ only today
      endDate: todayString,    // ✅ only today
    );

    if (mounted) {
      setState(() {
        _currentPjpData = null;
        _pjpDataFuture = fut;
      });
    }

    await fut;
  }

  void _handlePjpCreation() {
    dev.log('onPjpCreated hook → refresh list', name: _log);
    refreshPjpList();
    widget.onPjpCreated();
  }

  // --- (No changes to _showPjpOptions, _showAddPjpForm, _showBulkPjpWizard) ---
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
  // --- (End no changes) ---

  // --- ✅ UPDATED: pass entire PJP and Dealer to NavProvider via onStartJourney ---
  Future<void> _startJourneyForPjp(Pjp pjp) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // This logic is unchanged
    if (pjp.dealerId == null || pjp.dealerId!.isEmpty) {
      scaffoldMessenger.showSnackBar(SnackBar(
          content: Text('Error: This PJP is not linked to a dealer.'),
          backgroundColor: Colors.red));
      return;
    }

    try {
      dev.log('Start Journey: Fetching dealer details for id=${pjp.dealerId}', name: _log);
      final dealer = await _apiService.fetchDealerById(pjp.dealerId!);

      if (dealer.latitude == null || dealer.longitude == null) {
        throw const FormatException('Dealer has no location saved.');
      }
      
      final lat = dealer.latitude;
      final lon = dealer.longitude;
      final String displayName = dealer.name.isNotEmpty ? dealer.name : (pjp.dealerName ?? 'Dealer Visit');

      dev.log('Start Journey for PJP id=${pjp.id}, Dealer: ${dealer.name}', name: _log);
      
      await _apiService.updatePjp(pjp.id, {'status': 'started'});

      if (mounted && _currentPjpData != null) {
        setState(() {
          _currentPjpData!.verifiedPjps.removeWhere((item) => item.id == pjp.id);
        });
      }

      scaffoldMessenger.showSnackBar(const SnackBar(
          content: Text('Journey Started!'),
          backgroundColor: Colors.green));

      widget.onPjpCreated();

      // --- ✅ THE FIX ---
      // We now pass the entire PJP object and the fetched Dealer object.
      // This is critical for the DVR form auto-fill.
      widget.onStartJourney({
        'pjp': pjp,
        'dealer': dealer,
        'displayName': displayName,
        'destination': LatLng(lat!, lon!),
      });
      // --- END FIX ---

    } catch (e, st) {
      dev.log('Failed to start journey', name: _log, error: e, stackTrace: st);
      scaffoldMessenger.showSnackBar(SnackBar(
          content: Text('Failed to start journey: ${e.toString()}'),
          backgroundColor: Colors.red));
    }
  }

  // --- ✅ REPLACED BUILD WITH NEW WOW-FACTOR UI ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        FutureBuilder<PjpData>(
          future: _pjpDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                _currentPjpData == null) {
              return Center(
                  child:
                      CircularProgressIndicator(color: theme.colorScheme.primary));
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

            if (snapshot.hasData) {
              _currentPjpData = snapshot.data;
            }

            if (_currentPjpData == null) {
              dev.log('Future completed but data==null', name: _log);
              return Center(
                child: Text('No data received',
                    style: TextStyle(color: theme.colorScheme.error)),
              );
            }

            final pjpData = _currentPjpData!;
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

            // --- ✅ NEW: Build UI with Column ---
            return RefreshIndicator(
              onRefresh: _handleRefresh,
              color: theme.colorScheme.onPrimary,
              backgroundColor: theme.colorScheme.primary,
              child: ListView(
                padding: const EdgeInsets.only(top: 8.0, bottom: 120),
                children: [
                  // 1) Pending section as horizontal list
                  if (pendingPjps.isNotEmpty) ...[
                    PjpSectionHeader(
                        title: 'PENDING APPROVAL (${pendingPjps.length})'),
                    SizedBox(
                      height: 110,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: pendingPjps.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: MediaQuery.of(context).size.width * 0.8,
                            margin: const EdgeInsets.only(right: 12.0),
                            child: PendingPjpCard(pjp: pendingPjps[index]),
                          );
                        },
                      ),
                    ),
                  ],

                  // 2) Verified section as animated deck with header controls
                  if (verifiedPjps.isNotEmpty) ...[
                    PjpSectionHeader(
                      title: 'VERIFIED VISITS (${verifiedPjps.length})',
                      // ✅ pass state and collapse callback
                      isExpanded: _isDeckExpanded,
                      onToggle: () {
                        _collapseTimer?.cancel();
                        setState(() => _isDeckExpanded = false);
                      },
                    ),
                    _buildAnimatedDeck(verifiedPjps, theme),
                  ],
                ],
              ),
            );
            // --- END NEW UI ---
          },
        ),
        Positioned(
          bottom: 100.0,
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

  // --- ✅ The "Deck of Cards" Widget with auto-collapse ---
  Widget _buildAnimatedDeck(List<Pjp> verifiedPjps, ThemeData theme) {
    // Card layout props
    const double cardHeight = 110.0;
    const double collapsedOverlap = 15.0;
    const double expandedSpacing = 115.0;

    // Container height animate between collapsed and expanded
    final double collapsedHeight =
        (verifiedPjps.length - 1) * collapsedOverlap + cardHeight;
    final double expandedHeight =
        (verifiedPjps.length - 1) * expandedSpacing + cardHeight;

    return GestureDetector(
      onTap: () {
        // cancel any existing timer
        _collapseTimer?.cancel();

        setState(() {
          _isDeckExpanded = !_isDeckExpanded; // toggle
        });

        // auto-collapse after 5 seconds
        if (_isDeckExpanded) {
          _collapseTimer = Timer(const Duration(seconds: 5), () {
            if (mounted) {
              dev.log('Auto-collapsing deck...', name: _log);
              setState(() => _isDeckExpanded = false);
            }
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        height: _isDeckExpanded ? expandedHeight : collapsedHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Stack(
          children: List.generate(verifiedPjps.length, (index) {
            final pjp = verifiedPjps[index];

            return AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutCubic,
              top: _isDeckExpanded
                  ? (index * expandedSpacing)
                  : (index * collapsedOverlap),
              left: 0,
              right: 0,
              key: ValueKey(pjp.id),
              child: Slidable(
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
                child: PjpCard(pjp: pjp, isVerified: true),
              ),
            );
          }),
        ),
      ),
    );
  }
}
