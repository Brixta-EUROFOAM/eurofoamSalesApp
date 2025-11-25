import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:assetarchiverflutter/models/pjp_model.dart';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:assetarchiverflutter/technicalSide/models/sites_model.dart';
import 'package:assetarchiverflutter/technicalSide/screens/forms/create_technical_pjp_form.dart';
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
  State<TechnicalPjpScreen> createState() => _TechnicalPjpScreenState();
}

class _TechnicalPjpScreenState extends State<TechnicalPjpScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Pjp>> _pjpFuture;

  // --- FINTECH THEME PALETTE ---
  final Color _bgLight       = const Color(0xFFF3F4F6); // Corporate Light Grey
  final Color _cardNavy      = const Color(0xFF0F172A); // Deep Navy (Accents)
  final Color _textDark      = const Color(0xFF111827); // Almost Black
  final Color _textGrey      = const Color(0xFF6B7280); // Subtitles
  final Color _surfaceWhite  = Colors.white;
  final Color _accentGreen   = const Color(0xFF10B981); // Success/Start

  @override
  void initState() {
    super.initState();
    _refreshPjps();
  }

  void _refreshPjps() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    setState(() {
      _pjpFuture = _apiService.fetchPjpsForUser(
        int.parse(widget.employee.id),
        startDate: today,
        endDate: today,
        status: 'APPROVED', 
      );
    });
  }

  void _showCreatePjpForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateTechnicalPjpForm(
        employee: widget.employee,
        onPjpCreated: _refreshPjps,
      ),
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
    final todayDate = DateFormat('d MMMM, yyyy').format(DateTime.now());
    final todayDay = DateFormat('EEEE').format(DateTime.now());

    return Scaffold(
      backgroundColor: _bgLight,
      
      // --- 1. CLEAN APP BAR ---
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
                "My Visits",
                style: TextStyle(
                  color: _textDark,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                "$todayDay, $todayDate",
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
              onTap: _showCreatePjpForm,
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
                      "Add Visit",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),

      body: RefreshIndicator(
        onRefresh: () async => _refreshPjps(),
        color: _cardNavy,
        backgroundColor: Colors.white,
        child: Column(
          children: [
            const SizedBox(height: 10),
            // --- 2. LIST ---
            Expanded(
              child: FutureBuilder<List<Pjp>>(
                future: _pjpFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: _cardNavy));
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  }

                  final pjps = snapshot.data!;
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildVisitCard(Pjp pjp) {
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
                  // Icon Box
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF), // Light Blue
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.location_city_rounded, color: Color(0xFF2563EB), size: 24),
                  ),
                  const SizedBox(width: 16),
                  
                  // Text Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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

                  // "Start" Button (Visual only, whole card taps)
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
            "You're all clear for today.", 
            style: TextStyle(color: _textGrey, fontSize: 14)
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _showCreatePjpForm,
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