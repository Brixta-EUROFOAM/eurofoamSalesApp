// lib/screens/employee_management/employee_pjp_screen.dart
import 'package:salesmanapp/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/models/pjp_model.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'dart:developer' as dev;
import 'dart:async'; 
import 'package:intl/intl.dart'; 
import 'package:salesmanapp/screens/forms/add_pjp_form.dart';
import 'package:salesmanapp/screens/employee_management/bulk_pjp_wizard_screen.dart';

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
  
  late Future<List<Pjp>> _pjpFuture;

  DateTime _selectedDate = DateTime.now();

  // --- FINTECH THEME PALETTE ---
  final Color _bgLight       = const Color(0xFFF3F4F6); 
  final Color _cardNavy      = const Color(0xFF0F172A); 
  final Color _textDark      = const Color(0xFF111827); 
  final Color _textGrey      = const Color(0xFF6B7280); 
  final Color _surfaceWhite  = Colors.white;
  final Color _accentGreen   = const Color(0xFF10B981); 
  final Color _pendingOrange = const Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _pjpFuture = Future.value([]);
    refreshPjpList();
  }

  String _isoDate(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);

  void refreshPjpList() {
    final uid = int.tryParse(widget.employee.id);
    if (uid == null) return;

    final dateString = _isoDate(_selectedDate);
    dev.log('refreshPjpList() → fetch ALL PJPs for $dateString', name: _log);

    if (mounted) {
      setState(() {
        _pjpFuture = _apiService.fetchPjpsForUser(
          uid,
          startDate: dateString,
          endDate: dateString,
        );
      });
    }
  }

  Future<void> _handleRefresh() async {
    refreshPjpList();
    await _pjpFuture;
  }

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

  // --- ACTION SHEET ---
  void _showCreateOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Wrap(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 8),
                  child: Text("Plan Visit", style: TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _bgLight, borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.add_location_alt, color: _cardNavy),
                  ),
                  title: Text('Add Single Visit', style: TextStyle(fontWeight: FontWeight.w600, color: _textDark)),
                  subtitle: Text("For specific date", style: TextStyle(color: _textGrey)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showAddPjpForm();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _bgLight, borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.calendar_month, color: _accentGreen),
                  ),
                  title: Text('Bulk Monthly Plan', style: TextStyle(fontWeight: FontWeight.w600, color: _textDark)),
                  subtitle: Text("Auto-schedule multiple dealers", style: TextStyle(color: _textGrey)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showBulkPjpWizard();
                  },
                ),
              ],
            ),
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

    // --- ✅ 1. BLOCK PENDING PLANS ---
    final isVerified = (pjp.verificationStatus ?? 'PENDING').toUpperCase() == 'APPROVED' || 
                       (pjp.verificationStatus ?? 'PENDING').toUpperCase() == 'VERIFIED';
    
    if (!isVerified) {
       scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Cannot start. This plan is waiting for approval.'), 
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        )
      );
      return;
    }
    // ----------------------------------

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
    final displayDate = DateFormat('d MMMM, yyyy').format(_selectedDate);
    final displayDay = DateFormat('EEEE').format(_selectedDate);
    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());

    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: _bgLight,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 70,
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isToday ? "My Visits (Today)" : "Visits",
                style: TextStyle(
                  color: _textDark,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                "$displayDay, $displayDate",
                style: TextStyle(
                  color: _textGrey,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: InkWell(
              onTap: _showCreateOptions,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _cardNavy,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: _cardNavy.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                  ]
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 18),
                    SizedBox(width: 4),
                    Text(
                      "Plan Visit",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),

      body: Column(
        children: [
          _buildDateSelector(),
          const SizedBox(height: 10),
          
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: _cardNavy,
              backgroundColor: Colors.white,
              child: FutureBuilder<List<Pjp>>(
                future: _pjpFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: _cardNavy));
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                  }

                  final allPjps = snapshot.data ?? [];
                  
                  // Filter Active
                  final activePjps = allPjps.where((p) => p.status != 'COMPLETED').toList();

                  // Pending Approval
                  final pendingPjps = activePjps.where((p) {
                    final vStatus = (p.verificationStatus ?? 'PENDING').toUpperCase();
                    return vStatus == 'PENDING';
                  }).toList();

                  // Verified / Approved
                  final verifiedPjps = activePjps.where((p) {
                     final vStatus = (p.verificationStatus ?? 'PENDING').toUpperCase();
                     return vStatus == 'APPROVED' || vStatus == 'VERIFIED';
                  }).toList();

                  if (pendingPjps.isEmpty && verifiedPjps.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                    children: [
                      // 1. Pending Section
                      if (pendingPjps.isNotEmpty) ...[
                        _buildSectionHeader('PENDING APPROVAL (${pendingPjps.length})'),
                        ...pendingPjps.map((pjp) => _buildFintechVisitCard(pjp, isVerified: false)).toList(),
                        const SizedBox(height: 24),
                      ],

                      // 2. Verified Section
                      if (verifiedPjps.isNotEmpty) ...[
                        _buildSectionHeader('VERIFIED VISITS (${verifiedPjps.length})'),
                        ...verifiedPjps.map((pjp) => _buildFintechVisitCard(pjp, isVerified: true)).toList(),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      height: 90,
      color: _bgLight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 30, // 30 days
        itemBuilder: (context, index) {
          final date = DateTime.now().subtract(const Duration(days: 2)).add(Duration(days: index));
          final isSelected = DateUtils.isSameDay(date, _selectedDate);
          final isToday = DateUtils.isSameDay(date, DateTime.now());
          
          return GestureDetector(
            onTap: () => _onDateSelected(date),
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? _cardNavy : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: isToday && !isSelected 
                    ? Border.all(color: _cardNavy.withOpacity(0.3), width: 1)
                    : null,
                boxShadow: isSelected 
                    ? [BoxShadow(color: _cardNavy.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]
                    : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date).toUpperCase(), 
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white.withOpacity(0.7) : _textGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d').format(date), 
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : _textDark,
                    ),
                  ),
                  if (isToday)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isSelected ? _accentGreen : _cardNavy,
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Text(
        title, 
        style: TextStyle(color: _textGrey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)
      ),
    );
  }

  // --- ✅ NEW: Updated Logic to match TechnicalPjpScreen ---
  Widget _buildFintechVisitCard(Pjp pjp, {required bool isVerified}) {
    // 1. Status Logic
    final bool isInProgress = pjp.status.toUpperCase() == 'IN_PROGRESS' || pjp.status.toUpperCase() == 'STARTED';
    
    final Color statusColor = isVerified 
        ? (isInProgress ? Colors.blue : _accentGreen)
        : _pendingOrange;
        
    final String statusText = isVerified 
        ? (isInProgress ? "IN PROGRESS" : "APPROVED")
        : "WAITING APPROVAL";
    
    // 2. Name Resolution Logic
    String displayName = "Unknown Visit";
    String displayType = "General Visit";

    if (pjp.dealerName != null && pjp.dealerName!.isNotEmpty) {
      displayName = pjp.dealerName!;
      displayType = "Dealer Visit";
    } else if (pjp.siteName != null && pjp.siteName!.isNotEmpty) {
      displayName = pjp.siteName!;
      displayType = "Site Visit";
    } else if (pjp.description != null && pjp.description!.isNotEmpty) {
      displayName = pjp.description!;
      displayType = "Remark";
    } else {
      // ✅ Fallback: Extract from "Name, Address|Lat|Lng"
      try {
        final rawInfo = pjp.areaToBeVisited.split('|').first; 
        if (rawInfo.isNotEmpty) {
          // Heuristic: Text before first comma is likely the Name
          if (rawInfo.contains(',')) {
            displayName = rawInfo.split(',').first.trim();
          } else {
            displayName = rawInfo;
          }
          displayType = "Scheduled Visit";
        }
      } catch (e) {
        // Keep defaults
      }
    }

    // 3. Address Resolution
    String displayAddress = "";
    try {
      displayAddress = pjp.areaToBeVisited.split('|').first;
    } catch (_) {}


    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Slidable(
        enabled: isVerified, // Disable swipe if pending
        startActionPane: ActionPane(
          motion: const StretchMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => _startJourneyForPjp(pjp),
              backgroundColor: _accentGreen,
              foregroundColor: Colors.white,
              icon: Icons.navigation,
              label: 'START',
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: _surfaceWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
               BoxShadow(
                color: Colors.grey.withOpacity(0.08), 
                blurRadius: 15, 
                offset: const Offset(0, 5)
              )
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              // Block tap if pending
              onTap: () => _startJourneyForPjp(pjp),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1), 
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        isVerified ? Icons.store : Icons.hourglass_top_rounded, 
                        color: statusColor, 
                        size: 24
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 6, height: 6,
                                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                statusText, 
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          
                          // ✅ Bold Title
                          Text(
                            displayName, 
                            style: TextStyle(
                              color: _textDark, 
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          // ✅ Subtitle Type (Grey)
                          Text(
                            displayType, 
                            style: TextStyle(color: _textGrey, fontSize: 12, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          const SizedBox(height: 4),
                          
                          // Address
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, color: _textGrey, size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  displayAddress,
                                  style: TextStyle(color: _textGrey, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // --- ✅ START BUTTON (Grey if Pending) ---
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isVerified 
                            ? _accentGreen.withOpacity(0.1) // Green BG
                            : Colors.grey.withOpacity(0.15), // Grey BG
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isVerified ? "START" : "WAIT",
                        style: TextStyle(
                          color: isVerified ? _accentGreen : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
              ]
            ),
            child: Icon(Icons.calendar_today_rounded, size: 40, color: _textGrey.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          Text(
            "No Visits Planned", 
            style: TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 18)
          ),
          const SizedBox(height: 8),
          Text(
            "Select another date above or create a plan.", 
            style: TextStyle(color: _textGrey, fontSize: 14)
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _showCreateOptions, 
            icon: const Icon(Icons.add),
            label: const Text("Create Plan"),
            style: OutlinedButton.styleFrom(
              foregroundColor: _cardNavy,
              side: BorderSide(color: _cardNavy),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}