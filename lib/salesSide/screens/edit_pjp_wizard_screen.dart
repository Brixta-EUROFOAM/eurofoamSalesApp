// lib/salesSide/screens/edit_pjp_wizard_screen.dart // for seniors
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/salesSide/models/daily_task_model.dart';
import 'package:salesmanapp/salesSide/models/team_members_model.dart';
import 'package:salesmanapp/salesSide/models/dealer_model.dart';
import 'package:salesmanapp/widgets/reusable_functions.dart';

class EditPjpWizardScreen extends StatefulWidget {
  final TeamMember employee;
  final String taskId;

  const EditPjpWizardScreen({
    super.key,
    required this.employee,
    required this.taskId,
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
    _grouped.clear();
    final tasks = await _api.fetchDailyTasksForUser(widget.employee.id);

    final batchTasks = tasks.where((t) => t.id == widget.taskId).toList();

    // SORT BY DATE ASCENDING
    batchTasks.sort((a, b) => a.taskDate.compareTo(b.taskDate));

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

  Future<Dealer?> _openDealerSearch() async {
    return await openDealerSearch(context);
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
          for (var entry
              in _grouped.entries.toList()
                ..sort((a, b) => a.key.compareTo(b.key))) ...[
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
              onTap: () async {
                final dealer = await _openDealerSearch();

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
              },
              child: AbsorbPointer(
                child: TextFormField(
                  key: ValueKey(edit["dealerNameSnapshot"]),
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
              key: ValueKey(edit["dealerMobile"]),
              initialValue: edit["dealerMobile"],
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "Dealer Mobile"),
              onChanged: (v) => edit["dealerMobile"] = v,
            ),

            const SizedBox(height: 12),

            /// AREA
            TextFormField(
              key: ValueKey(edit["area"]),
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
