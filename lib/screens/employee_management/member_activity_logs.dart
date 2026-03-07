//lib/screens/employee_management/member_leave_history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/models/team_members_model.dart';
import 'package:salesmanapp/models/leave_application_model.dart';
import 'package:salesmanapp/models/daily_task_model.dart';
import 'package:salesmanapp/screens/employee_management/edit_pjp_wizard_screen.dart';

class MemberActivityLogsScreen extends StatefulWidget {
  final TeamMember member;

  const MemberActivityLogsScreen({super.key, required this.member});

  @override
  State<MemberActivityLogsScreen> createState() =>
      _MemberActivityLogsScreenState();
}

class _MemberActivityLogsScreenState extends State<MemberActivityLogsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  // --- 🎨 PREMIUM THEME PALETTE ---
  static const Color _bgLight = Color(0xFFF8FAFC);
  static const Color _textGrey = Color(0xFF64748B);
  static const Color _cardNavy = Color(0xFF0F172A);
  static const Color _accentBlue = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: _bgLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: _cardNavy),
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.member.fullName,
              style: const TextStyle(
                color: _cardNavy,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              widget.member.role.toUpperCase(),
              style: const TextStyle(
                color: _accentBlue,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _cardNavy,
          unselectedLabelColor: _textGrey,
          indicatorColor: _cardNavy,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: "LEAVES"),
            Tab(text: "PJPs"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _LeaveLogsTab(member: widget.member, apiService: _apiService),
          _PjpLogsTab(member: widget.member, apiService: _apiService),
        ],
      ),
    );
  }
}

/// ----------------------------------------------------------------
/// LEAVE LOGS TAB
/// ----------------------------------------------------------------
class _LeaveLogsTab extends StatefulWidget {
  final TeamMember member;
  final ApiService apiService;

  const _LeaveLogsTab({required this.member, required this.apiService});

  @override
  State<_LeaveLogsTab> createState() => _LeaveLogsTabState();
}

class _LeaveLogsTabState extends State<_LeaveLogsTab> {
  late Future<List<LeaveApplication>> _leaveFuture;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _refreshLeaves();
  }

  void _refreshLeaves() {
    setState(() {
      _leaveFuture = widget.apiService.fetchLeaveApplicationsForUser(
        widget.member.id,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: FutureBuilder<List<LeaveApplication>>(
            future: _leaveFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF0F172A)),
                );
              }

              var list = snapshot.data ?? [];
              if (_selectedFilter != 'All') {
                list = list.where((l) => l.status == _selectedFilter).toList();
              }

              if (list.isEmpty) return _buildEmptyState();

              return RefreshIndicator(
                onRefresh: () async => _refreshLeaves(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) =>
                      _buildLeaveCard(list[index], index),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    final filters = ['All', 'Pending', 'Approved', 'Rejected'];
    return Container(
      height: 60,
      padding: const EdgeInsets.only(left: 20, top: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isSelected = _selectedFilter == filters[i];
          return ChoiceChip(
            label: Text(filters[i]),
            selected: isSelected,
            onSelected: (val) => setState(() => _selectedFilter = filters[i]),
            selectedColor: Color(0xFF0F172A),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Color(0xFF64748B),
              fontWeight: FontWeight.bold,
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeaveCard(LeaveApplication leave, int index) {
    final dateRange =
        "${DateFormat('dd MMM').format(leave.startDate)} - ${DateFormat('dd MMM').format(leave.endDate)}";
    final Color statusColor = _getStatusColor(leave.status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statusBadge(leave.status, statusColor),
              Text(
                dateRange,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            leave.leaveType,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            leave.reason,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          if (leave.status == 'Pending') ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleAction(leave, 'Rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "REJECT",
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleAction(leave, 'Approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "APPROVE",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (leave.adminRemarks != null) ...[
            const Divider(height: 32),
            Row(
              children: [
                const Icon(
                  Icons.comment_bank_outlined,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Remarks: ${leave.adminRemarks}",
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideY(begin: 0.1);
  }

  void _handleAction(LeaveApplication leave, String status) async {
    final TextEditingController remarkCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Confirm $status"),
        content: TextField(
          controller: remarkCtrl,
          decoration: const InputDecoration(
            hintText: "Enter remarks (optional)",
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await widget.apiService.updateLeaveStatus(
                  leaveId: leave.id!,
                  status: status,
                  adminRemarks: remarkCtrl.text,
                );
                Navigator.pop(context);
                _refreshLeaves();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Leave $status successfully")),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("Action failed")));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'Approved' ? Colors.green : Colors.red,
            ),
            child: const Text("CONFIRM", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 64,
            color: Color(0xFF64748B).withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          const Text(
            "No leave history found",
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// ----------------------------------------------------------------
/// PJP(DailyTasks) LOGS TAB
/// ----------------------------------------------------------------
class _PjpLogsTab extends StatefulWidget {
  final TeamMember member;
  final ApiService apiService;

  const _PjpLogsTab({required this.member, required this.apiService});

  @override
  State<_PjpLogsTab> createState() => _PjpLogsTabState();
}

class _PjpLogsTabState extends State<_PjpLogsTab> {
  late Future<List<DailyTask>> _pjpFuture;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _refreshPjps();
  }

  void _refreshPjps() {
    setState(() {
      _pjpFuture = widget.apiService.fetchDailyTasksForUser(widget.member.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: FutureBuilder<List<DailyTask>>(
            future: _pjpFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF0F172A)),
                );
              }

              var list = snapshot.data ?? [];
              if (_selectedFilter != 'All') {
                list = list
                    .where(
                      (t) =>
                          t.status.toLowerCase() ==
                          _selectedFilter.toLowerCase(),
                    )
                    .toList();
              }

              if (list.isEmpty) return _buildEmptyState();

              return RefreshIndicator(
                onRefresh: () async => _refreshPjps(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) =>
                      _buildPjpCard(list[index], index),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    final filters = ['All', 'Pending', 'Approved', 'Completed'];
    return Container(
      height: 60,
      padding: const EdgeInsets.only(left: 20, top: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isSelected = _selectedFilter == filters[i];
          return ChoiceChip(
            label: Text(filters[i]),
            selected: isSelected,
            onSelected: (val) => setState(() => _selectedFilter = filters[i]),
            selectedColor: const Color(0xFF0F172A),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF64748B),
              fontWeight: FontWeight.bold,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPjpCard(DailyTask task, int index) {
    final dateStr = DateFormat('dd MMM yyyy').format(task.taskDate);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statusBadge(task.status),
              Text(
                dateStr,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            task.dealerNameSnapshot ?? "New Site/Prospect",
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          _infoRow(
            Icons.map_outlined,
            "${task.area}, ${task.zone} (Week ${task.week})",
          ),
          _infoRow(Icons.route_outlined, "Route: ${task.route ?? 'N/A'}"),
          _infoRow(
            Icons.track_changes_outlined,
            "Objective: ${task.objective}",
          ),
          _infoRow(
            Icons.category_outlined,
            "Type: ${task.visitType} (${task.requiredVisitCount} visits)",
          ),

          if (task.status.toLowerCase() == 'pending') ...[
            const Divider(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _openEditPlan(task),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.indigoAccent,
                      side: const BorderSide(color: Colors.indigo),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "EDIT PLAN",
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleApprove(task),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "APPROVE PJP",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideY(begin: 0.1);
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _handleApprove(DailyTask task) async {
    try {
      await widget.apiService.updateDailyTask(task.id!, {'status': 'Approved'});
      _refreshPjps();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("PJP Approved")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to approve PJP")));
    }
  }

  void _openEditPlan(DailyTask task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditPjpWizardScreen(
          employee: widget.member,
          taskId: task.id!,
        ),
      ),
    ).then((_) => _refreshPjps());
  }

  Widget _statusBadge(String status) {
    Color color = Colors.orange;

    if (status.toLowerCase() == 'pending') color = Colors.orange;
    if (status.toLowerCase() == 'approved') color = Colors.blue;
    if (status.toLowerCase() == 'completed') color = Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map_outlined,
            size: 64,
            color: const Color(0xFF64748B).withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          const Text(
            "No PJPs found for this period",
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}