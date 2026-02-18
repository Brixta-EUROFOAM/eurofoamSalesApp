import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/models/leave_application_model.dart';
import 'package:salesmanapp/screens/forms/create_leave_form.dart';

class AllLeavesListScreen extends StatefulWidget {
  final int userId;
  const AllLeavesListScreen({super.key, required this.userId});

  @override
  State<AllLeavesListScreen> createState() => _AllLeavesListScreenState();
}

class _AllLeavesListScreenState extends State<AllLeavesListScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<LeaveApplication>> _leavesFuture;

  static const Color _bgLight = Color(0xFFF5F5F7);
  static const Color _surfaceWhite = Colors.white;
  static const Color _textDark = Color(0xFF1E293B);
  static const Color _textGrey = Color(0xFF64748B);
  static const Color _cardNavy = Color(0xFF0F172A);

  @override
  void initState() {
    super.initState();
    _loadLeaves();
  }

  void _loadLeaves() {
    setState(() {
      _leavesFuture = _apiService.fetchLeaveApplicationsForUser(widget.userId, limit: 100);
    });
  }

  Future<void> _navigateToCreateForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateLeaveFormScreen(userId: widget.userId),
      ),
    );

    if (result == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Leave applied successfully"), backgroundColor: Colors.green),
        );
      }
      _loadLeaves();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        title: const Text("Leave History"),
        backgroundColor: _surfaceWhite,
        foregroundColor: _textDark,
        elevation: 0,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: TextButton.icon(
              onPressed: _navigateToCreateForm,
              style: TextButton.styleFrom(
                backgroundColor: _cardNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text("Apply Leave", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<LeaveApplication>>(
        future: _leavesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _cardNavy));
          }
          final leaves = snapshot.data ?? [];
          if (leaves.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 48, color: _textGrey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text("No leave history found", style: TextStyle(color: _textGrey)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _navigateToCreateForm,
                    icon: const Icon(Icons.add),
                    label: const Text("Apply Now"),
                    style: ElevatedButton.styleFrom(backgroundColor: _cardNavy, foregroundColor: Colors.white),
                  )
                ],
              ),
            );
          }
          
          leaves.sort((a, b) => b.startDate.compareTo(a.startDate));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: leaves.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _buildLeaveCard(leaves[i]),
          );
        },
      ),
    );
  }

  Widget _buildLeaveCard(LeaveApplication leave) {
    Color color = Colors.orange;
    if (leave.status.toLowerCase() == 'approved') color = Colors.green;
    if (leave.status.toLowerCase() == 'rejected') color = Colors.red;

    final dateRange = "${DateFormat('dd MMM').format(leave.startDate)} - ${DateFormat('dd MMM').format(leave.endDate)}";

    return Container(
      decoration: BoxDecoration(
        color: _surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.calendar_today, color: color, size: 20),
          ),
          title: Text(leave.leaveType, style: const TextStyle(fontWeight: FontWeight.bold, color: _textDark)),
          subtitle: Text(dateRange, style: const TextStyle(color: _textGrey, fontSize: 13)),
          trailing: Container(
             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
             decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
             child: Text(leave.status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  Text("Reason:", style: TextStyle(fontSize: 12, color: _textGrey.withOpacity(0.8), fontWeight: FontWeight.bold)),
                  Text(leave.reason, style: const TextStyle(color: _textDark)),
                  if(leave.adminRemarks != null && leave.adminRemarks!.isNotEmpty) ...[
                     const SizedBox(height: 12),
                     Text("Admin Remarks:", style: TextStyle(fontSize: 12, color: _textGrey.withOpacity(0.8), fontWeight: FontWeight.bold)),
                     Text(leave.adminRemarks!, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
                  ]
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}