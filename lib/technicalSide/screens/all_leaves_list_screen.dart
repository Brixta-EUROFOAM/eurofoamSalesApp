// lib/technicalSide/screens/all_leaves_list_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart'; // 🔥 ADDED FOR PREMIUM ANIMATIONS
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

  // 🚀 O(1) STATE MANAGEMENT: Replaced FutureBuilder for flat memory retention
  List<LeaveApplication> _leaves = [];
  bool _isLoading = true;

  // --- 🎨 PREMIUM THEME PALETTE ---
  static const Color _bgLight = Color(0xFFF8FAFC);
  static const Color _surfaceWhite = Colors.white;
  static const Color _textDark = Color(0xFF1E293B);
  static const Color _textGrey = Color(0xFF64748B);
  static const Color _cardNavy = Color(0xFF0F172A);

  @override
  void initState() {
    super.initState();
    _loadLeaves();
  }

  // 🚀 O(N log N) SORTED EXACTLY ONCE: Prevents CPU thrashing on UI rebuilds
  Future<void> _loadLeaves() async {
    try {
      final data = await _apiService.fetchLeaveApplicationsForUser(
        widget.userId,
        limit: 100,
      );

      // Sort once in the background, NOT in the build method
      data.sort((a, b) {
        final dateA = a.createdAt ?? a.startDate;
        final dateB = b.createdAt ?? b.startDate;
        return dateB.compareTo(dateA);
      });

      if (mounted) {
        setState(() {
          _leaves = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load leaves: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => _isLoading = true);
    await _loadLeaves();
  }

  Future<void> _navigateToCreateForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateLeaveApplicationForm(userId: widget.userId),
      ),
    );

    if (result == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Leave applied successfully",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
      _handleRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        title:
            const Text(
                  "Leave History",
                  style: TextStyle(
                    color: _cardNavy,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                )
                .animate()
                .fadeIn(duration: 400.ms)
                .slideX(begin: -0.1, curve: Curves.easeOut),
        backgroundColor: _bgLight,
        iconTheme: const IconThemeData(color: _cardNavy),
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 70,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child:
                  InkWell(
                        onTap: _navigateToCreateForm,
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: _cardNavy,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: _cardNavy.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                "Apply",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .animate()
                      .scale(delay: 200.ms, curve: Curves.easeOutBack)
                      // ✨ Breathing pulse to subtly draw attention
                      .then()
                      .shimmer(duration: 2500.ms, color: Colors.white24)
                      .animate(onPlay: (c) => c.repeat()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: _cardNavy,
        backgroundColor: Colors.white,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _cardNavy))
            : _leaves.isEmpty
            ? _buildEmptyState()
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                itemCount: _leaves.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (_, index) {
                  // ✨ STAGGERED LIST ANIMATION
                  return _buildLeaveCard(_leaves[index])
                      .animate(delay: (index * 40).ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.1, curve: Curves.easeOut);
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _cardNavy.withOpacity(0.06),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.event_busy_rounded,
                  size: 48,
                  color: _textGrey.withOpacity(0.5),
                ),
              ).animate().scale(
                delay: 100.ms,
                curve: Curves.easeOutBack,
                duration: 600.ms,
              ),
              const SizedBox(height: 32),
              const Text(
                    "No Leave History",
                    style: TextStyle(
                      color: _textDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 200.ms)
                  .slideY(begin: 0.5, curve: Curves.easeOutCubic),
              const SizedBox(height: 8),
              const Text(
                "You haven't applied for any leaves yet.",
                style: TextStyle(color: _textGrey, fontSize: 15),
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                    onPressed: _navigateToCreateForm,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text("Apply First Leave"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _cardNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      elevation: 8,
                      shadowColor: _cardNavy.withOpacity(0.4),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 400.ms)
                  .scale(curve: Curves.easeOutBack),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveCard(LeaveApplication leave) {
    Color statusColor;
    IconData statusIcon;

    switch (leave.status.toUpperCase()) {
      case 'APPROVED':
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'REJECTED':
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_top_rounded;
    }

    final dateRange =
        "${DateFormat('dd MMM').format(leave.startDate)} - ${DateFormat('dd MMM yyyy').format(leave.endDate)}";
    final createdDate = leave.createdAt != null
        ? DateFormat('dd MMM').format(leave.createdAt!)
        : '';

    return Container(
      decoration: BoxDecoration(
        color: _surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _cardNavy.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: _cardNavy.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLeaveDetails(leave, statusColor),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ✨ SQUIRCLE AVATAR
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 26),
                ),
                const SizedBox(width: 16),

                // ✨ LEAVE DETAILS
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              leave.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: statusColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Text(
                            createdDate,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _textGrey.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        leave.leaveType,
                        style: const TextStyle(
                          color: _textDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: _textGrey,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              dateRange,
                              style: const TextStyle(
                                color: _textGrey,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 36,
                  width: 36,
                  decoration: const BoxDecoration(
                    color: _bgLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: _cardNavy,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLeaveDetails(LeaveApplication leave, Color color) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    leave.leaveType,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: _textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Text(
                    leave.status.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: color,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _detailRow(
              Icons.flight_takeoff_rounded,
              "From",
              DateFormat('dd MMM yyyy').format(leave.startDate),
            ),
            const SizedBox(height: 16),
            _detailRow(
              Icons.flight_land_rounded,
              "To",
              DateFormat('dd MMM yyyy').format(leave.endDate),
            ),
            const SizedBox(height: 16),
            _detailRow(Icons.subject_rounded, "Reason", leave.reason),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Divider(height: 1),
            ),
            const Text(
              "ADMIN REMARKS",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: _textGrey,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                (leave.adminRemarks != null && leave.adminRemarks!.isNotEmpty)
                    ? leave.adminRemarks!
                    : "No remarks provided.",
                style: const TextStyle(
                  color: _textDark,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _textGrey, size: 20),
        const SizedBox(width: 12),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(
              color: _textGrey,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: _textDark,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}
