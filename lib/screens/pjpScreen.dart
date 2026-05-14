// lib/screens/pjpScreen.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../api/api_service.dart';
import '../models/pjp_model.dart';
import 'forms/add_PJP_form.dart';

class PjpScreen extends StatefulWidget {
  const PjpScreen({Key? key}) : super(key: key);

  @override
  State<PjpScreen> createState() => _PjpScreenState();
}

class _PjpScreenState extends State<PjpScreen> {
  final ApiService _apiService = ApiService();

  List<PjpModel> _allPjps = [];
  bool _isLoading = true;

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchPjps();
  }

  Future<void> _fetchPjps() async {
    setState(() => _isLoading = true);
    try {
      final pjps = await _apiService.getJourneyPlans();
      if (mounted) {
        setState(() {
          _allPjps = pjps;
        });
      }
    } catch (e) {
      debugPrint("Error fetching PJPs: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<PjpModel> _getEventsForDay(DateTime day) {
    return _allPjps.where((pjp) {
      // Removed the null check entirely!
      // Compare ignoring time
      return pjp.planDate.year == day.year &&
          pjp.planDate.month == day.month &&
          pjp.planDate.day == day.day;
    }).toList();
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'COMPLETED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedPjps = _getEventsForDay(_selectedDay);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Journey Plans (PJP)",
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPjpFormScreen()),
          );
          if (result == true) _fetchPjps(); // Refresh if new PJPs were added
        },
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
        label: const Text(
          "Plan Visits",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ).animate().scaleXY(begin: 0.8, curve: Curves.easeOutBack),
      body: Column(
        children: [
          // --- CALENDAR WIDGET ---
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.week,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              eventLoader: _getEventsForDay,
            ),
          ),
          const SizedBox(height: 16),

          // --- PJP LIST ---
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0F172A)),
                  )
                : selectedPjps.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: selectedPjps.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final pjp = selectedPjps[index];
                      return _buildPjpCard(pjp, index);
                    },
                  ),
          ),
        ],
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
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_busy_rounded,
              size: 48,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "No Visits Planned",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Select another date or create a new plan.",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ).animate().fadeIn().slideY(begin: 0.2),
    );
  }

  Widget _buildPjpCard(PjpModel pjp, int index) {
    final statusColor = _getStatusColor(pjp.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pjp.areaToBeVisited,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    if (pjp.visitDealerName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        "Dealer: ${pjp.visitDealerName}",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  pjp.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (pjp.description != null && pjp.description!.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notes_rounded, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pjp.description!,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1);
  }
}
