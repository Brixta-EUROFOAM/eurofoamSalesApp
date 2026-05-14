// lib/screens/forms/add_PJP_form.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../api/api_service.dart';
import '../../widgets/ReusableFunctions.dart';

// --- Local Draft Model for Wizard State ---
class PjpDraft {
  int? dealerId;
  String areaToBeVisited; // Either Dealer Name or Manual Area
  String? dealerName; // Kept separately for UI clarity
  TextEditingController descriptionController = TextEditingController();

  PjpDraft({this.dealerId, required this.areaToBeVisited, this.dealerName});
}

class AddPjpFormScreen extends StatefulWidget {
  const AddPjpFormScreen({Key? key}) : super(key: key);

  @override
  State<AddPjpFormScreen> createState() => _AddPjpFormScreenState();
}

class _AddPjpFormScreenState extends State<AddPjpFormScreen> {
  final ApiService _apiService = ApiService();

  int _currentStep = 0;
  bool _isSubmitting = false;

  // State: Dates selected by the user
  final Set<DateTime> _selectedDates = {};

  // State: The drafted plans grouped by Date
  final Map<DateTime, List<PjpDraft>> _plannedVisits = {};

  // For Step 2 PageView
  late PageController _pageController;
  int _plannerPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var lists in _plannedVisits.values) {
      for (var draft in lists) {
        draft.descriptionController.dispose();
      }
    }
    super.dispose();
  }

  // --- LOGIC ---

  void _onDateSelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      final normalizedDate = DateTime(
        selectedDay.year,
        selectedDay.month,
        selectedDay.day,
      );
      if (_selectedDates.contains(normalizedDate)) {
        _selectedDates.remove(normalizedDate);
        _plannedVisits.remove(normalizedDate);
      } else {
        _selectedDates.add(normalizedDate);
        _plannedVisits[normalizedDate] = [];
      }
    });
  }

  void _addVisitToDate(
    DateTime date, {
    int? dealerId,
    required String area,
    String? dealerName,
  }) {
    setState(() {
      _plannedVisits[date]!.add(
        PjpDraft(
          dealerId: dealerId,
          areaToBeVisited: area,
          dealerName: dealerName,
        ),
      );
    });
  }

  Future<void> _submitBulkPjp() async {
    setState(() => _isSubmitting = true);

    // Construct payload
    List<Map<String, dynamic>> bulkPayload = [];

    _plannedVisits.forEach((date, drafts) {
      for (var draft in drafts) {
        bulkPayload.add({
          "planDate": date.toIso8601String(),
          "areaToBeVisited": draft.areaToBeVisited,
          "dealerId": draft.dealerId,
          "description": draft.descriptionController.text.trim(),
          "status": "PENDING", // Enforced Default
        });
      }
    });

    try {
      // NOTE: You need to add this bulk endpoint/method to your api_service.dart
      // e.g., await _apiService.submitBulkJourneyPlans(bulkPayload);

      // Simulating API call for now:
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Journey Plans Submitted!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to trigger refresh
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // --- UI WIDGETS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          _currentStep == 0
              ? "Select Dates"
              : _currentStep == 1
              ? "Plan Visits"
              : "Review Plan",
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress Bar
          LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            backgroundColor: Colors.grey.shade300,
            color: Colors.blueAccent,
            minHeight: 6,
          ),

          Expanded(
            child: _currentStep == 0
                ? _buildStep1DateSelection()
                : _currentStep == 1
                ? _buildStep2DailyPlanner()
                : _buildStep3Review(),
          ),

          // Bottom Navigation Bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentStep--),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "BACK",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentStep == 0 && _selectedDates.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Select at least one date'),
                          ),
                        );
                        return;
                      }
                      if (_currentStep == 2) {
                        _submitBulkPjp();
                      } else {
                        setState(() => _currentStep++);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentStep == 2
                          ? Colors.green
                          : const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _currentStep == 2 ? "SUBMIT PLANS" : "NEXT",
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- STEP 1: CALENDAR ---
  Widget _buildStep1DateSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select the days you want to plan visits for.",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 90)),
              focusedDay: DateTime.now(),
              selectedDayPredicate: (day) => _selectedDates.contains(
                DateTime(day.year, day.month, day.day),
              ),
              onDaySelected: _onDateSelected,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  // --- STEP 2: DAILY PLANNER (PAGE VIEW) ---
  Widget _buildStep2DailyPlanner() {
    final sortedDates = _selectedDates.toList()..sort();

    return Column(
      children: [
        // Date Tabs
        Container(
          height: 60,
          color: Colors.white,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sortedDates.length,
            itemBuilder: (ctx, i) {
              final isSelected = _plannerPageIndex == i;
              return GestureDetector(
                onTap: () => _pageController.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                child: Container(
                  margin: const EdgeInsets.only(right: 12, top: 12, bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF0F172A)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    DateFormat('E, MMM d').format(sortedDates[i]),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Pager for Visits
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _plannerPageIndex = idx),
            itemCount: sortedDates.length,
            itemBuilder: (ctx, idx) {
              final date = sortedDates[idx];
              final drafts = _plannedVisits[date]!;

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // List of Drafted Visits for this day
                  ...drafts.asMap().entries.map((entry) {
                    final visitIdx = entry.key;
                    final draft = entry.value;
                    return _buildDraftVisitCard(date, visitIdx, draft);
                  }),

                  // Add New Visit Button
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _showAddVisitOptions(date),
                    icon: const Icon(Icons.add),
                    label: const Text(
                      "ADD DESTINATION",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      side: const BorderSide(
                        color: Colors.blueAccent,
                        style: BorderStyle.solid,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      foregroundColor: Colors.blueAccent,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn();
  }

  // --- 2-IN-1 OPTION CHOOSER ---
  void _showAddVisitOptions(DateTime date) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Add Destination",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFEFF6FF),
                child: Icon(Icons.storefront, color: Colors.blueAccent),
              ),
              title: const Text(
                "Select Network Dealer",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text("Search via your dealer database"),
              onTap: () async {
                Navigator.pop(context);
                final dealer = await openDealerSearch(context);
                if (dealer != null) {
                  _addVisitToDate(
                    date,
                    dealerId: dealer.id,
                    area: dealer.dealerPartyName,
                    dealerName: dealer.dealerPartyName,
                  );
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFFF7ED),
                child: Icon(Icons.edit_location_alt, color: Colors.orange),
              ),
              title: const Text(
                "Enter Destination Manually",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text("For prospects or non-registered areas"),
              onTap: () {
                Navigator.pop(context);
                _showManualEntryDialog(date);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showManualEntryDialog(DateTime date) {
    final tc = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Manual Destination"),
        content: TextField(
          controller: tc,
          decoration: InputDecoration(
            hintText: "Enter area, site, or prospect name...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (tc.text.trim().isNotEmpty) {
                _addVisitToDate(date, area: tc.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
            ),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftVisitCard(DateTime date, int idx, PjpDraft draft) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      draft.dealerId != null ? Icons.storefront : Icons.place,
                      color: Colors.blueGrey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        draft.areaToBeVisited,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () =>
                    setState(() => _plannedVisits[date]!.removeAt(idx)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: draft.descriptionController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: "Description / Objective for this visit...",
              hintStyle: const TextStyle(fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX();
  }

  // --- STEP 3: REVIEW ---
  Widget _buildStep3Review() {
    int totalVisits = _plannedVisits.values.fold(
      0,
      (sum, list) => sum + list.length,
    );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.blueAccent,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                "Ready to submit $totalVisits visits across ${_selectedDates.length} days.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // FIX: Wrap the sorted list in parentheses before calling .map()
        ...(_selectedDates.toList()..sort()).map((date) {
          final drafts = _plannedVisits[date]!;
          if (drafts.isEmpty) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMMM d').format(date),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                ...drafts.map(
                  (d) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(0xFFF1F5F9),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: Colors.grey,
                      ),
                    ),
                    title: Text(
                      d.areaToBeVisited,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      d.descriptionController.text.isEmpty
                          ? "No description"
                          : d.descriptionController.text,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    ).animate().fadeIn();
  }
}
