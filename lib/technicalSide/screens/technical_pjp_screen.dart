// lib/technicalSide/screens/technical_pjp_screen.dart
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

  // --- THEME CONSTANTS ---
  static const Color scaffoldBg     = Color(0xFF020617); // Navy
  static const Color surfaceDark    = Color(0xFF1E293B); // Slate 800
  static const Color accentYellow   = Color(0xFFFFA000); // Amber
  static const Color brandBlue      = Color(0xFF0B4AA8); 
  static const Color successGreen   = Color(0xFF10B981); // Emerald

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
    final todayStr = DateFormat('EEEE, d MMMM').format(DateTime.now()).toUpperCase();

    return Scaffold(
      backgroundColor: scaffoldBg,
      
      // --- 1. APP BAR (Consistent with Dashboard) ---
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
          child: InkWell(
            onTap: () => Scaffold.of(context).openDrawer(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
            ),
          ),
        ),
        title: const Text(
          'MY VISITS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),

      // --- 2. FAB ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePjpForm,
        backgroundColor: accentYellow,
        foregroundColor: Colors.black,
        elevation: 4,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text(
          "ADD VISIT", 
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)
        ),
      ),

      body: RefreshIndicator(
        onRefresh: () async => _refreshPjps(),
        color: accentYellow,
        backgroundColor: surfaceDark,
        child: Column(
          children: [
            // --- 3. DATE BANNER ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              color: surfaceDark.withOpacity(0.5),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.white54, size: 16),
                  const SizedBox(width: 10),
                  Text(
                    todayStr,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            // --- 4. LIST ---
            Expanded(
              child: FutureBuilder<List<Pjp>>(
                future: _pjpFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: accentYellow));
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  }

                  final pjps = snapshot.data!;
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
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
            backgroundColor: successGreen,
            foregroundColor: Colors.white,
            icon: Icons.navigation,
            label: 'START',
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _startJourney(pjp),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon Box
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: brandBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.apartment_rounded, color: brandBlue, size: 26),
                  ),
                  const SizedBox(width: 16),
                  
                  // Text Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pjp.siteName ?? pjp.description ?? "Site Visit", 
                          style: const TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: Colors.white38, size: 12),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                pjp.areaToBeVisited.split('|').first, 
                                style: const TextStyle(color: Colors.white54, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Start Action Chevron/Button
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chevron_right, color: Colors.white54, size: 20),
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
              color: surfaceDark,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_busy, size: 48, color: Colors.white24),
          ),
          const SizedBox(height: 16),
          const Text(
            "NO VISITS PLANNED", 
            style: TextStyle(
              color: Colors.white70, 
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 1.0,
            )
          ),
          const SizedBox(height: 8),
          const Text(
            "Tap + to create a new plan", 
            style: TextStyle(color: Colors.white38, fontSize: 14)
          ),
        ],
      ),
    );
  }
}