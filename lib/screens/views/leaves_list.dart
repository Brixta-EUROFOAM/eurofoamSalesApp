// lib/screens/views/leaves_list.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../api/api_service.dart';
import '../../models/leaves_model.dart';
import '../forms/add_Leave_form.dart';

class LeavesListScreen extends StatefulWidget {
  const LeavesListScreen({Key? key}) : super(key: key);

  @override
  State<LeavesListScreen> createState() => _LeavesListScreenState();
}

class _LeavesListScreenState extends State<LeavesListScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<LeaveModel>> _leavesFuture;

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

  void _loadLeaves() {
    setState(() {
      _leavesFuture = _apiService.getLeaves();
    });
  }

  Future<void> _handleRefresh() async {
    _loadLeaves();
    await _leavesFuture;
  }

  Future<void> _navigateToCreateForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddLeaveFormScreen()),
    );

    // If the form returns true (success), refresh the list
    if (result == true) {
      _loadLeaves();
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
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: _cardNavy,
        backgroundColor: Colors.white,
        child: FutureBuilder<List<LeaveModel>>(
          future: _leavesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _cardNavy),
              );
            }

            final leaves = snapshot.data ?? [];

            if (leaves.isEmpty) {
              return _buildEmptyState();
            }

            // Backend usually sorts by desc, but sorting locally ensures correct order
            leaves.sort((a, b) => b.startDate.compareTo(a.startDate));

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                100,
              ), // Extra bottom padding for FAB
              itemCount: leaves.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (_, i) => _buildLeaveCard(leaves[i])
                  .animate(delay: (i * 40).ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.1, curve: Curves.easeOut),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateForm,
        backgroundColor: _cardNavy,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          "Apply Leave",
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
        ),
      ).animate().scale(delay: 600.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
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
                "Tap 'Apply Leave' to submit a request.",
                style: TextStyle(color: _textGrey, fontSize: 15),
              ).animate().fadeIn(delay: 300.ms),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveCard(LeaveModel leave) {
    Color color = Colors.orange; // Default Pending
    if (leave.status.toLowerCase() == 'approved') color = Colors.green;
    if (leave.status.toLowerCase() == 'rejected') color = Colors.redAccent;

    final dateRange =
        "${DateFormat('dd MMM').format(leave.startDate)} - ${DateFormat('dd MMM').format(leave.endDate)}";

    return Container(
      decoration: BoxDecoration(
        color: _surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _cardNavy.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.calendar_month_rounded, color: color, size: 24),
          ),
          title: Text(
            leave.leaveType,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: _textDark,
              fontSize: 16,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              dateRange,
              style: const TextStyle(
                color: _textGrey,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              leave.status.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: Colors.grey.shade200, height: 24),
                  const Text(
                    "Reason",
                    style: TextStyle(
                      fontSize: 12,
                      color: _textGrey,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    leave.reason,
                    style: const TextStyle(
                      color: _textDark,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),

                  if (leave.adminRemarks != null &&
                      leave.adminRemarks!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      "Admin Remarks",
                      style: TextStyle(
                        fontSize: 12,
                        color: _textGrey,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        leave.adminRemarks!,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
