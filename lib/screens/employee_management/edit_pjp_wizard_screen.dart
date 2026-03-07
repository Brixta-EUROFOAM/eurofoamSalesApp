// lib/screens/employee_management/edit_pjp_wizard_screen.dart // for seniors
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/models/daily_task_model.dart';
import 'package:salesmanapp/models/team_members_model.dart';
import 'package:salesmanapp/models/dealer_model.dart';

class EditPjpWizardScreen extends StatefulWidget {
  final TeamMember employee;
  final String batchId;

  const EditPjpWizardScreen({
    super.key,
    required this.employee,
    required this.batchId,
  });

  @override
  State<EditPjpWizardScreen> createState() => _EditPjpWizardScreenState();
}

class _EditPjpWizardScreenState extends State<EditPjpWizardScreen> {
  final ApiService _api = ApiService();

  bool _loading = true;
  bool _saving = false;

  final Map<DateTime, List<DailyTask>> _grouped = {};
  final Map<String, Map<String, dynamic>> _editedVisits = {};

  final List<String> _zones = [
    'Kamrup',
    'Central Assam',
    'Upper Assam',
    'Lower Assam',
    'Kamrup TSO',
    'Meghalaya',
    'Barak Valley',
    'Mizoram',
    'Manipur',
    'Nagaland',
    'North Bank',
    'Non Trade',
    'Tripura',
  ];

  final List<String> _objectives = [
    'Order Related',
    'Payment Collection',
    'Any Support',
    'Prospect',
    'Meetings',
    'Promotional Activity',
  ];

  final List<String> _types = [
    'Important Parties',
    'Prospect',
    'Sub Dealer',
    'Open Visit',
    'Other Visit',
  ];

  final List<String> _weeks = ['week1', 'week2', 'week3', 'week4'];

  @override
  void initState() {
    super.initState();
    _loadBatch();
  }

  Future<void> _loadBatch() async {
    final tasks = await _api.fetchDailyTasksForUser(widget.employee.id);

    final batchTasks = tasks
        .where((t) => t.pjpBatchId == widget.batchId)
        .toList();

    for (var t in batchTasks) {
      final d = DateTime(t.taskDate.year, t.taskDate.month, t.taskDate.day);
      _grouped.putIfAbsent(d, () => []).add(t);
    }

    setState(() => _loading = false);
  }

  Future<void> _saveAndApprove() async {
    setState(() => _saving = true);

    try {
      for (var day in _grouped.values) {
        for (var visit in day) {
          final edit = _editedVisits[visit.id]!;

          await _api.updateDailyTask(visit.id!, {
            "dealerNameSnapshot": edit["dealerNameSnapshot"],
            "dealerMobile": edit["dealerMobile"],
            "area": edit["area"],
            "route": edit["route"],
            "objective": edit["objective"],
            "visitType": edit["visitType"],
            "week": edit["week"],
            "zone": edit["zone"],
            "requiredVisitCount": edit["requiredVisitCount"],
            "status": "Approved",
          });
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Plan updated & approved")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => _saving = false);
  }

  Future<void> _openDealerSearch(Map edit) async {
    final dealer = await showDialog<Dealer>(
      context: context,
      builder: (_) => _ServerDealerSearchDialog(api: _api),
    );

    if (dealer == null) return;

    setState(() {
      edit["dealerNameSnapshot"] = dealer.name;
      edit["dealerMobile"] = dealer.phoneNo;
      edit["area"] = dealer.area;

      if (!_zones.contains(dealer.region)) {
        _zones.add(dealer.region);
      }

      edit["zone"] = dealer.region;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Weekly Plan")),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (var entry in _grouped.entries) ...[
            _buildDaySection(entry.key, entry.value),
            const SizedBox(height: 24),
          ],

          const SizedBox(height: 40),

          ElevatedButton(
            onPressed: _saving ? null : _saveAndApprove,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(double.infinity, 56),
            ),
            child: _saving
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    "SAVE & APPROVE PLAN",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySection(DateTime date, List<DailyTask> visits) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat("EEEE, dd MMM").format(date),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),

        const SizedBox(height: 16),

        for (var visit in visits) _visitCard(visit),
      ],
    );
  }

  Widget _visitCard(DailyTask visit) {
    final edit = _editedVisits.putIfAbsent(visit.id!, () {
      return {
        "dealerNameSnapshot": visit.dealerNameSnapshot ?? "",
        "dealerMobile": visit.dealerMobile ?? "",
        "area": visit.area ?? "",
        "route": visit.route ?? "",
        "objective": visit.objective ?? _objectives.first,
        "visitType": visit.visitType ?? _types.first,
        "week": visit.week ?? _weeks.first,
        "zone": visit.zone ?? _zones.first,
        "requiredVisitCount": visit.requiredVisitCount ?? 1,
      };
    });

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// DEALER SEARCH
            GestureDetector(
              onTap: () => _openDealerSearch(edit),
              child: AbsorbPointer(
                child: TextFormField(
                  initialValue: edit["dealerNameSnapshot"],
                  decoration: const InputDecoration(
                    labelText: "Dealer (Search)",
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// MOBILE
            TextFormField(
              initialValue: edit["dealerMobile"],
              decoration: const InputDecoration(labelText: "Dealer Mobile"),
              onChanged: (v) => edit["dealerMobile"] = v,
            ),

            const SizedBox(height: 12),

            /// AREA
            TextFormField(
              initialValue: edit["area"],
              decoration: const InputDecoration(labelText: "Area"),
              onChanged: (v) => edit["area"] = v,
            ),

            const SizedBox(height: 12),

            /// ROUTE
            TextFormField(
              initialValue: edit["route"],
              decoration: const InputDecoration(labelText: "Route"),
              onChanged: (v) => edit["route"] = v,
            ),

            const SizedBox(height: 12),

            /// ZONE
            DropdownButtonFormField<String>(
              value: edit["zone"],
              items: _zones
                  .map((z) => DropdownMenuItem(value: z, child: Text(z)))
                  .toList(),
              onChanged: (v) => edit["zone"] = v,
              decoration: const InputDecoration(labelText: "Zone"),
            ),

            const SizedBox(height: 12),

            /// OBJECTIVE
            DropdownButtonFormField<String>(
              value: edit["objective"],
              items: _objectives
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              onChanged: (v) => edit["objective"] = v,
              decoration: const InputDecoration(labelText: "Objective"),
            ),

            const SizedBox(height: 12),

            /// VISIT TYPE
            DropdownButtonFormField<String>(
              value: edit["visitType"],
              items: _types
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => edit["visitType"] = v,
              decoration: const InputDecoration(labelText: "Visit Type"),
            ),

            const SizedBox(height: 12),

            /// WEEK
            DropdownButtonFormField<String>(
              value: edit["week"],
              items: _weeks
                  .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                  .toList(),
              onChanged: (v) => edit["week"] = v,
              decoration: const InputDecoration(labelText: "Week"),
            ),

            const SizedBox(height: 12),

            /// VISIT COUNT
            TextFormField(
              initialValue: edit["requiredVisitCount"].toString(),
              decoration: const InputDecoration(labelText: "Required Visits"),
              keyboardType: TextInputType.number,
              onChanged: (v) =>
                  edit["requiredVisitCount"] = int.tryParse(v) ?? 1,
            ),
          ],
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// 🔎 DEALER SEARCH DIALOG (Memory Leak Fixed)
/// ------------------------------------------------------------
class _ServerDealerSearchDialog extends StatefulWidget {
  final ApiService api;
  const _ServerDealerSearchDialog({required this.api});
  @override
  State<_ServerDealerSearchDialog> createState() =>
      _ServerDealerSearchDialogState();
}

class _ServerDealerSearchDialogState extends State<_ServerDealerSearchDialog> {
  List<Dealer> _dealers = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _performSearch("");
  }

  // 🚀 CRITICAL FIX: Prevent Memory Leaks
  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _performSearch(query),
    );
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    try {
      final results = await widget.api.fetchDealers(search: query, limit: 20);
      if (mounted) {
        setState(() {
          _dealers = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        "Select Dealer",
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: Color(0xFF0F172A),
          fontSize: 20,
          letterSpacing: -0.5,
        ),
      ),
      contentPadding: const EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: 0,
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(
          children: [
            TextField(
              onChanged: _onSearchChanged,
              style: const TextStyle(fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: "Search by name or zone...",
                hintStyle: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Colors.grey,
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0F172A),
                      ),
                    )
                  : _dealers.isEmpty
                  ? const Center(
                      child: Text(
                        "No dealers found.",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _dealers.length,
                      separatorBuilder: (context, index) =>
                          Divider(color: Colors.grey.shade200, height: 1),
                      itemBuilder: (context, index) {
                        final dealer = _dealers[index];

                        // 🚀 MEMORY OPTIMIZED: Replaced the multiple string allocations
                        // from your second snippet with a single, O(1) ternary resolution.
                        // This prevents unnecessary garbage collection spikes while scrolling.
                        final zoneArea = dealer.area.isNotEmpty
                            ? "${dealer.region}, ${dealer.area}"
                            : dealer.region.isNotEmpty
                            ? dealer.region
                            : "Unknown Zone";

                        return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 0,
                              ),
                              // Kept your original premium Container UI look instead of the basic CircleAvatar
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.storefront_rounded,
                                  color: Colors.blueAccent,
                                  size: 22,
                                ),
                              ),
                              title: Text(
                                dealer.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      zoneArea,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF374151),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dealer.address,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6B7280),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () => Navigator.pop(context, dealer),
                            )
                            // 🚀 ANIMATION PRESERVED: Staggered entry animation kept intact
                            .animate()
                            .fadeIn(delay: (index * 30).ms)
                            .slideX(begin: -0.05);
                      },
                    ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.all(16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            "CANCEL",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ).animate().scale(curve: Curves.easeOutBack, duration: 400.ms);
  }
}
