// lib/screens/employee_management/employee_pjp_screen.dart
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:assetarchiverflutter/models/pjp_model.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'dart:developer' as dev;
import 'dart:async'; 
import 'package:intl/intl.dart'; 

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
  bool _isDeckExpanded = false;
  Timer? _collapseTimer; 

  // --- ✅ NEW: Track selected date (defaults to Today) ---
  DateTime _selectedDate = DateTime.now();

  String _isoDate(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);

  @override
  void initState() {
    super.initState();
    refreshPjpList();
  }

  @override
  void dispose() {
    _collapseTimer?.cancel(); 
    super.dispose();
  }

  void refreshPjpList() {
    final uid = int.tryParse(widget.employee.id);
    if (uid == null) return;

    // --- ✅ UPDATED: Use selected date ---
    final dateString = _isoDate(_selectedDate);
    dev.log('refreshPjpList() → fetch PJPs for $dateString', name: _log);

    if (mounted) {
      setState(() {
        _currentPjpData = null;
        _pjpDataFuture = _apiService.fetchPendingAndVerifiedPjps(
          userId: uid,
          startDate: dateString,
          endDate: dateString,
        );
      });
    }
  }

  Future<void> _handleRefresh() async {
    refreshPjpList();
    await _pjpDataFuture;
  }

  // --- ✅ NEW: Handle date selection ---
  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    refreshPjpList();
  }

  void _handlePjpCreation() {
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
                title: Text('Add Single Visit', style: TextStyle(color: theme.colorScheme.onSurface)),
                onTap: () {
                  Navigator.of(context).pop();
                  _showAddPjpForm();
                },
              ),
              ListTile(
                leading: Icon(Icons.calendar_month, color: theme.colorScheme.secondary),
                title: Text('Create Bulk Monthly Plan', style: TextStyle(color: theme.colorScheme.onSurface)),
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
    if (pjp.dealerId == null || pjp.dealerId!.isEmpty) {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Error: This PJP is not linked to a dealer.'), backgroundColor: Colors.red));
      return;
    }

    try {
      final dealer = await _apiService.fetchDealerById(pjp.dealerId!);
      if (dealer.latitude == null || dealer.longitude == null) {
        throw const FormatException('Dealer has no location saved.');
      }
      
      final lat = dealer.latitude;
      final lon = dealer.longitude;
      final String displayName = dealer.name.isNotEmpty ? dealer.name : (pjp.dealerName ?? 'Dealer Visit');

      await _apiService.updatePjp(pjp.id, {'status': 'STARTED'});

      if (mounted && _currentPjpData != null) {
        setState(() {
          _currentPjpData!.verifiedPjps.removeWhere((item) => item.id == pjp.id);
        });
      }

      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Journey Started!'), backgroundColor: Colors.green));
      widget.onPjpCreated();

      widget.onStartJourney({
        'pjp': pjp,
        'dealer': dealer,
        'displayName': displayName,
        'destination': LatLng(lat!, lon!),
      });

    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Failed to start journey: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // --- ✅ NEW: Date Selector Widget ---
          _buildDateSelector(theme),
          
          Expanded(
            child: Stack(
              children: [
                FutureBuilder<PjpData>(
                  future: _pjpDataFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && _currentPjpData == null) {
                      return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: theme.colorScheme.error)));
                    }

                    if (snapshot.hasData) {
                      _currentPjpData = snapshot.data;
                    }

                    final pjpData = _currentPjpData ?? PjpData(pendingPjps: [], verifiedPjps: []);
                    final pendingPjps = pjpData.pendingPjps;
                    final verifiedPjps = pjpData.verifiedPjps;

                    if (pendingPjps.isEmpty && verifiedPjps.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: _handleRefresh,
                        child: ListView(
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                            Center(child: Text('No visits planned for this date.', style: TextStyle(color: theme.colorScheme.onBackground.withOpacity(0.5)))),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _handleRefresh,
                      color: theme.colorScheme.onPrimary,
                      backgroundColor: theme.colorScheme.primary,
                      child: ListView(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 120),
                        children: [
                          if (pendingPjps.isNotEmpty) ...[
                            PjpSectionHeader(title: 'PENDING APPROVAL (${pendingPjps.length})'),
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

                          if (verifiedPjps.isNotEmpty) ...[
                            PjpSectionHeader(
                              title: 'VERIFIED VISITS (${verifiedPjps.length})',
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
            ),
          ),
        ],
      ),
    );
  }

  // --- ✅ NEW: Calendar Strip Widget ---
  Widget _buildDateSelector(ThemeData theme) {
    return Container(
      height: 90,
      color: theme.colorScheme.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 30, // 30 days range
        itemBuilder: (context, index) {
          // Start from 2 days ago
          final date = DateTime.now().subtract(const Duration(days: 2)).add(Duration(days: index));
          final isSelected = DateUtils.isSameDay(date, _selectedDate);
          final isToday = DateUtils.isSameDay(date, DateTime.now());
          
          return GestureDetector(
            onTap: () => _onDateSelected(date),
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: isToday && !isSelected 
                    ? Border.all(color: theme.colorScheme.primary.withOpacity(0.3), width: 1)
                    : Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
                boxShadow: isSelected 
                    ? [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date).toUpperCase(), // MON, TUE
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? theme.colorScheme.onPrimary.withOpacity(0.8) : theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d').format(date), // 27, 28
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                    ),
                  ),
                  if (isToday)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isSelected ? theme.colorScheme.secondary : theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedDeck(List<Pjp> verifiedPjps, ThemeData theme) {
    const double cardHeight = 110.0;
    const double collapsedOverlap = 15.0;
    const double expandedSpacing = 115.0;

    final double collapsedHeight = (verifiedPjps.length - 1) * collapsedOverlap + cardHeight;
    final double expandedHeight = (verifiedPjps.length - 1) * expandedSpacing + cardHeight;

    return GestureDetector(
      onTap: () {
        _collapseTimer?.cancel();
        setState(() {
          _isDeckExpanded = !_isDeckExpanded;
        });
        if (_isDeckExpanded) {
          _collapseTimer = Timer(const Duration(seconds: 5), () {
            if (mounted) setState(() => _isDeckExpanded = false);
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
              top: _isDeckExpanded ? (index * expandedSpacing) : (index * collapsedOverlap),
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
                      label: 'Start',
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