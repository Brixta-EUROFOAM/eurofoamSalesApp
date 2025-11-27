import 'package:salesmanapp/models/employee_model.dart';
import 'package:salesmanapp/models/pjp_model.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/technicalSide/models/sites_model.dart';
import 'package:salesmanapp/technicalSide/screens/forms/add_technical_pjp_form.dart'; 
import 'package:salesmanapp/technicalSide/screens/bulk_technical_pjp_wizard_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class TechnicalPjpScreen extends StatefulWidget {
  final Employee employee;
  final Function(Map<String, dynamic> journeyData) onStartJourney;

  const TechnicalPjpScreen({
    super.key,
    required this.employee,
    required this.onStartJourney,
  });

  @override
  State<TechnicalPjpScreen> createState() => TechnicalPjpScreenState();
}

// ✅ Made State Public so NavScreen can access refreshPjpList via GlobalKey
class TechnicalPjpScreenState extends State<TechnicalPjpScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Pjp>> _pjpFuture;
  
  // Track selected date
  DateTime _selectedDate = DateTime.now();

  // --- FINTECH THEME PALETTE ---
  final Color _bgLight       = const Color(0xFFF3F4F6); 
  final Color _cardNavy      = const Color(0xFF0F172A); 
  final Color _textDark      = const Color(0xFF111827); 
  final Color _textGrey      = const Color(0xFF6B7280); 
  final Color _surfaceWhite  = Colors.white;
  final Color _accentGreen   = const Color(0xFF10B981); 

  @override
  void initState() {
    super.initState();
    refreshPjpList();
  }

  // ✅ Renamed to public method so parent can call it
  void refreshPjpList() {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    setState(() {
      _pjpFuture = _apiService.fetchPjpsForUser(
        int.parse(widget.employee.id),
        startDate: dateStr,
        endDate: dateStr,
      );
    });
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    refreshPjpList();
  }

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
                    _showSingleCreateForm();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _bgLight, borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.calendar_month, color: _accentGreen),
                  ),
                  title: Text('Bulk Monthly Plan', style: TextStyle(fontWeight: FontWeight.w600, color: _textDark)),
                  subtitle: Text("Auto-schedule multiple sites", style: TextStyle(color: _textGrey)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showBulkWizard();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSingleCreateForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTechnicalPjpForm(
        employee: widget.employee,
        onPjpCreated: refreshPjpList,
      ),
    );
  }

  void _showBulkWizard() {
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => BulkTechnicalPjpWizardScreen(
          employee: widget.employee, 
          onPjpCreated: refreshPjpList
        )
      )
    );
  }

  Future<void> _startJourney(Pjp pjp) async {
    if (pjp.siteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: No Site ID in PJP"), backgroundColor: Colors.redAccent)
      );
      return;
    }

    try {
      final TechnicalSite site = await _apiService.fetchTechnicalSiteById(pjp.siteId!);
      
      final data = {
        'pjp': pjp,
        'site': site,
        'displayName': site.siteName,
        'destination': LatLng(site.latitude, site.longitude),
      };

      widget.onStartJourney(data);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to start journey: $e"), backgroundColor: Colors.redAccent)
      );
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
        centerTitle: false,
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
              onRefresh: () async => refreshPjpList(),
              color: _cardNavy,
              backgroundColor: Colors.white,
              child: FutureBuilder<List<Pjp>>(
                future: _pjpFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: _cardNavy));
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  }

                  // --- ✅ CRITICAL FIX: Filter out COMPLETED PJPs ---
                  final allPjps = snapshot.data!;
                  final pjps = allPjps.where((p) => p.status != 'COMPLETED').toList();

                  if (pjps.isEmpty) {
                    return _buildEmptyState();
                  }
                  // ------------------------------------------------

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 80), 
                    itemCount: pjps.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final pjp = pjps[index];
                      return _buildVisitCard(pjp);
                    },
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
        itemCount: 30, // Show previous 2 days + next 27 days
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

  Widget _buildVisitCard(Pjp pjp) {
    // Check pending vs approved vs In Progress
    final isPending = pjp.status.toUpperCase() == 'PENDING';
    final isInProgress = pjp.status.toUpperCase() == 'IN_PROGRESS';
    
    // Logic for colors
    final statusColor = isPending ? Colors.orange : (isInProgress ? Colors.blue : _accentGreen);
    final statusText = isPending ? "PENDING" : (isInProgress ? "IN PROGRESS" : "APPROVED");

    return Slidable(
      startActionPane: ActionPane(
        motion: const StretchMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _startJourney(pjp),
            backgroundColor: _accentGreen,
            foregroundColor: Colors.white,
            icon: Icons.navigation,
            label: 'START',
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
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
            onTap: () => _startJourney(pjp),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF), 
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.location_city_rounded, color: Color(0xFF2563EB), size: 24),
                  ),
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusText, 
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                          ),
                        ),

                        Text(
                          pjp.siteName ?? pjp.description ?? "Site Visit", 
                          style: TextStyle(
                            color: _textDark, 
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, color: _textGrey, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                pjp.areaToBeVisited.split('|').first, 
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

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _accentGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "START",
                      style: TextStyle(
                        color: _accentGreen, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 11
                      ),
                    ),
                  ),
                ],
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
            style: TextStyle(
              color: _textDark, 
              fontWeight: FontWeight.bold,
              fontSize: 18,
            )
          ),
          const SizedBox(height: 8),
          Text(
            "Select another date above.", 
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