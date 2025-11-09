// lib/screens/employee_management/employee_pjp_screen.dart

import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:assetarchiverflutter/models/pjp_model.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'dart:developer' as dev;

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
        _currentPjpData = null;
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
    
    // --- ✅ THIS IS THE FIX ---
    // 1. Added curly braces for the 'if' block.
    // 2. Changed '=>' (returns a Set) to '() { ... }' (a function block).
    if (mounted) {
      setState(() { 
        _currentPjpData = null; 
        _pjpDataFuture = fut;
      });
    }
    // --- END FIX ---
    
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


  Future<void> _startJourneyForPjp(Pjp pjp) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
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
        throw FormatException('Dealer "${dealer.name}" has no location saved.');
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

      widget.onStartJourney({
        'pjpId': pjp.id,
        'displayName': displayName,
        'destination': LatLng(lat!, lon!),
      });

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
                _currentPjpData == null) {
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

            List<Widget> listItems = []; 

            if (pendingPjps.isNotEmpty) {
              listItems.add(
                PjpSectionHeader(title: 'PENDING APPROVAL (${pendingPjps.length})')
              );
              listItems.addAll(pendingPjps.map((pjp) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: PendingPjpCard(pjp: pjp),
              )).toList());
            }

            if (verifiedPjps.isNotEmpty) {
              listItems.add(
                PjpSectionHeader(title: 'VERIFIED VISITS (${verifiedPjps.length})')
              );
              listItems.addAll(verifiedPjps.map((pjp) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                  child: PjpCard(pjp: pjp, isVerified: true),
                ),
              )));
            }

            return RefreshIndicator(
              onRefresh: _handleRefresh,
              color: theme.colorScheme.onPrimary,
              backgroundColor: theme.colorScheme.primary,
              child: ListView.builder(
                padding: const EdgeInsets.only(
                    top: 8.0,
                    bottom: 120),
                itemCount: listItems.length,
                itemBuilder: (context, index) {
                  return listItems[index];
                },
              ),
            );
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
}