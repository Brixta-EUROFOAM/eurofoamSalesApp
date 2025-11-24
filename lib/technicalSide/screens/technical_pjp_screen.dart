// lib/technicalSide/screens/technical_pjp_screen.dart
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:assetarchiverflutter/models/pjp_model.dart';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:assetarchiverflutter/technicalSide/models/sites_model.dart';
import 'package:assetarchiverflutter/technicalSide/screens/forms/create_technical_pjp_form.dart';
//import 'package:assetarchiverflutter/widgets/pjp_cards.dart';
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

  @override
  void initState() {
    super.initState();
    _refreshPjps();
  }

  void _refreshPjps() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    setState(() {
      // We want APPROVED visits for today to show in the "Start Journey" list
      _pjpFuture = _apiService.fetchPjpsForUser(
        int.parse(widget.employee.id),
        startDate: today,
        endDate: today,
        status: 'APPROVED', // Only show approved for journey start
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
        const SnackBar(content: Text("Error: No Site ID in PJP"))
      );
      return;
    }

    try {
      // Fetch full site details for coordinates using the API helper we added
      final TechnicalSite site = await _apiService.fetchTechnicalSiteById(pjp.siteId!);
      
      // Prepare data packet
      final data = {
        'pjp': pjp,
        'site': site, // Passing Site object
        'displayName': site.siteName,
        'destination': LatLng(site.latitude, site.longitude),
      };

      // Trigger callback
      widget.onStartJourney(data);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to start journey: $e"))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const darkBg = Color(0xFF010638);
    
    return Scaffold(
      backgroundColor: darkBg,
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePjpForm,
        backgroundColor: const Color(0xFFFFA000),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshPjps(),
        child: FutureBuilder<List<Pjp>>(
          future: _pjpFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text("No Approved Site Visits for Today", 
                  style: TextStyle(color: Colors.white54)
                )
              );
            }

            final pjps = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pjps.length,
              itemBuilder: (context, index) {
                final pjp = pjps[index];
                return Slidable(
                  startActionPane: ActionPane(
                    motion: const StretchMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (_) => _startJourney(pjp),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        icon: Icons.route,
                        label: 'Start',
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ],
                  ),
                  child: Card(
                    color: Colors.white10,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const Icon(Icons.apartment, color: Color(0xFFFFA000)),
                      title: Text(
                        pjp.siteName ?? pjp.description ?? "Site Visit", 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                      ),
                      subtitle: Text(
                        pjp.areaToBeVisited.split('|').first, 
                        style: const TextStyle(color: Colors.white70)
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                      onTap: () => _startJourney(pjp),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}