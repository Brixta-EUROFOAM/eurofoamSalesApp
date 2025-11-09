import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:assetarchiverflutter/models/pjp_model.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'dart:developer' as dev;

// --- ✅ NEW IMPORTS ---
// Import the widgets we moved
import 'package:assetarchiverflutter/widgets/pjp_cards.dart';
// Import the forms we moved
import 'package:assetarchiverflutter/screens/forms/add_pjp_form.dart';
import 'package:assetarchiverflutter/screens/employee_management/bulk_pjp_wizard_screen.dart';
// --- END NEW IMPORTS ---


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
    // Employee.id is a String, but the API needs an int.
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

  // --- This function now just shows the options ---
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

  // --- This function now calls the new form file ---
  void _showAddPjpForm() {
    dev.log('Open AddPjpForm', name: _log);
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddPjpForm( // <-- Now opens the widget from the new file
        employee: widget.employee,
        onPjpCreated: _handlePjpCreation,
        theme: theme,
      ),
    );
  }

  // --- This function now calls the new wizard file ---
  void _showBulkPjpWizard() {
    dev.log('Open BulkPjpWizardScreen', name: _log);
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => BulkPjpWizardScreen( // <-- Opens the new file
          employee: widget.employee,
          onPjpCreated: _handlePjpCreation,
        ),
      ),
    );
  }

  Future<void> _startJourneyForPjp(Pjp pjp) async {
    // This is the logic you wanted: it takes the pre-filled PJP data
    // and sends it to the Journey tracker page.
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      // We parse the destination from the 'areaToBeVisited' string
      final parts = pjp.areaToBeVisited.split('|');
      if (parts.length != 3) {
        throw const FormatException('Invalid PJP data format. Cannot get location.');
      }
      final String displayName = pjp.dealerName ?? parts[0]; // <-- Use new logic
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

      // --- THIS IS THE HANDOFF ---
      // It calls the function in navscreen.dart, which changes the tab
      // and passes the journey data.
      widget.onStartJourney({
        'pjpId': pjp.id,
        'displayName': displayName,
        'destination': LatLng(lat, lon),
      });
      // --- END OF HANDOFF ---

    } catch (e, st) {
      dev.log('Failed to start journey', name: _log, error: e, stackTrace: st);
      scaffoldMessenger.showSnackBar(SnackBar(
          content:
              Text('Failed to start journey: ${e.toString()}'),
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
                    ListView(), // Allows pull-to-refresh on empty screen
                    Center(
                        child: Text('No PJPs found.',
                            style: TextStyle(
                                color: theme.colorScheme.onBackground
                                    .withOpacity(0.7)))),
                  ],
                ),
              );
            }

            // --- ✅ BUG FIX: Build the list with correct logic ---
            List<Widget> listItems = []; // Start with an empty list

            // 1. If there are PENDING items, add a header and the items
            if (pendingPjps.isNotEmpty) {
              listItems.add(
                PjpSectionHeader(title: 'PENDING APPROVAL (${pendingPjps.length})')
              );

              listItems.addAll(pendingPjps.map((pjp) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                // This is the "Pending" card, it is NOT slidable
                // --- ✅ THIS IS THE FIX ---
                child: PendingPjpCard(pjp: pjp), // <-- Use PendingPjpCard
                // --- END FIX ---
              )).toList());
            }


            // 2. If there are VERIFIED items, add a header and the items
            if (verifiedPjps.isNotEmpty) {
              listItems.add(
                PjpSectionHeader(title: 'VERIFIED VISITS (${verifiedPjps.length})')
              );

              listItems.addAll(verifiedPjps.map((pjp) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                // This is the "Verified" card, it IS slidable
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
                  // --- This part was correct ---
                  child: PjpCard(pjp: pjp, isVerified: true),
                ),
              )));
            }
            // --- END OF BUG FIX ---

            return RefreshIndicator(
              onRefresh: _handleRefresh,
              color: theme.colorScheme.onPrimary,
              backgroundColor: theme.colorScheme.primary,
              child: ListView.builder(
                // --- ✅ PADDING FIX: Remove unnecessary top padding ---
                // The AppBar is separate now
                padding: const EdgeInsets.only(
                    top: 8.0, // Just a small top padding
                    bottom: 120), // Padding for the FAB and Nav Bar
                itemCount: listItems.length,
                itemBuilder: (context, index) {
                  return listItems[index];
                },
              ),
            );
          },
        ),
        Positioned(
          // --- ✅ THEME: Made FAB spacing consistent ---
          bottom: 100.0, // Raised slightly to clear floating nav bar
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