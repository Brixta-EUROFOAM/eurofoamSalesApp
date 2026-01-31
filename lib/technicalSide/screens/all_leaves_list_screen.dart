// lib/technicalSide/screens/all_leaves_list_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/models/leave_application_model.dart';
import 'package:salesmanapp/technicalSide/screens/forms/create_leave_appl_form.dart';

class AllLeavesListScreen extends StatefulWidget {
  final int userId;

  const AllLeavesListScreen({super.key, required this.userId});

  @override
  State<AllLeavesListScreen> createState() => _AllLeavesListScreenState();
}

class _AllLeavesListScreenState extends State<AllLeavesListScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<LeaveApplication>> _leavesFuture;

  // --- Theme Colors matching other screens ---
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
      _leavesFuture = _apiService.fetchLeaveApplicationsForUser(
        widget.userId,
        limit: 100, // Fetch enough history
      );
    });
  }

  Future<void> _navigateToCreateForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateLeaveApplicationForm(userId: widget.userId),
      ),
    );

    // If leave was applied successfully, refresh the list
    if (result == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Leave applied successfully"),
            backgroundColor: Colors.green,
          ),
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
          // ✅ UPDATED: Clear "Apply Leave" button instead of just a + icon
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: TextButton.icon(
              onPressed: _navigateToCreateForm,
              style: TextButton.styleFrom(
                backgroundColor: _cardNavy,
                foregroundColor: const Color.fromARGB(255, 255, 255, 255), // Navy text/icon
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                "Apply Leave",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<LeaveApplication>>(
        future: _leavesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A)));
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final leaves = snapshot.data ?? [];

          if (leaves.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy_rounded, size: 60, color: _textGrey.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  const Text("No leave history found", style: TextStyle(color: _textGrey)),
                  const SizedBox(height: 24),
                  // Optional: Add a button here for empty state too
                  ElevatedButton.icon(
                    onPressed: _navigateToCreateForm,
                    icon: const Icon(Icons.add),
                    label: const Text("Apply First Leave"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                    ),
                  )
                ],
              ),
            );
          }

          // Sort by createdAt (descending). Falls back to startDate if createdAt is null.
          leaves.sort((a, b) {
            final dateA = a.createdAt ?? a.startDate;
            final dateB = b.createdAt ?? b.startDate;
            return dateB.compareTo(dateA);
          });

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
    Color statusColor;
    Color statusBg;
    IconData statusIcon;

    switch (leave.status.toUpperCase()) {
      case 'APPROVED':
        statusColor = Colors.green;
        statusBg = Colors.green.shade50;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'REJECTED':
        statusColor = Colors.red;
        statusBg = Colors.red.shade50;
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = Colors.orange;
        statusBg = Colors.orange.shade50;
        statusIcon = Icons.hourglass_empty;
    }

    final dateRange = "${DateFormat('dd MMM').format(leave.startDate)} - ${DateFormat('dd MMM yyyy').format(leave.endDate)}";
    
    // Handle potentially null createdAt for display
    final createdDate = leave.createdAt != null 
        ? DateFormat('dd MMM').format(leave.createdAt!) 
        : '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showLeaveDetails(leave, statusColor),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: _surfaceWhite,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Status Strip
              Container(
                width: 6,
                height: 100, // Fixed height or flexible
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(statusIcon, size: 14, color: statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  leave.status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            createdDate, // Applied on
                            style: TextStyle(fontSize: 11, color: _textGrey.withOpacity(0.7)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        leave.leaveType,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 14, color: _textGrey),
                          const SizedBox(width: 6),
                          Text(
                            dateRange,
                            style: const TextStyle(fontSize: 13, color: _textGrey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.chevron_right, color: _textGrey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLeaveDetails(LeaveApplication leave, Color color) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  leave.leaveType,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textDark),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Text(
                    leave.status.toUpperCase(),
                    style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _detailRow("From", DateFormat('dd MMM yyyy').format(leave.startDate)),
            _detailRow("To", DateFormat('dd MMM yyyy').format(leave.endDate)),
            _detailRow("Reason", leave.reason),
            const Divider(height: 32),
            const Text(
              "ADMIN REMARKS",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textGrey, letterSpacing: 1),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                (leave.adminRemarks != null && leave.adminRemarks!.isNotEmpty)
                    ? leave.adminRemarks!
                    : "No remarks provided.",
                style: const TextStyle(color: _textDark, height: 1.4),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: _textGrey, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: _textDark, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}