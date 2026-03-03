// lib/technicalSide/screens/all_pjp_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart'; // 🔥 ADDED FOR PREMIUM ANIMATIONS
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/models/pjp_model.dart';

class UserPjpListScreen extends StatefulWidget {
  final int userId;

  const UserPjpListScreen({super.key, required this.userId});

  @override
  State<UserPjpListScreen> createState() => _UserPjpListScreenState();
}

class _UserPjpListScreenState extends State<UserPjpListScreen> {
  final ApiService _apiService = ApiService();

  // 🚀 O(1) TAB SWITCHING: Pre-bucketed lists
  List<Pjp> _activePjps = [];
  List<Pjp> _completedPjps = [];

  bool _isLoading = true;
  bool _showCompleted = false; // False = Active, True = Completed

  // --- 🎨 PREMIUM THEME PALETTE ---
  final Color _bgLight = const Color(0xFFF8FAFC);
  final Color _cardNavy = const Color(0xFF0F172A);
  final Color _textDark = const Color(0xFF1E293B);
  final Color _textGrey = const Color(0xFF64748B);
  final Color _surfaceWhite = Colors.white;
  final Color _accentGreen = const Color(0xFF10B981);
  final Color _accentBlue = const Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
    _loadPjps();
  }

  // 🚀 O(N) FETCH & SORT EXACTLY ONCE
  Future<void> _loadPjps() async {
    try {
      final data = await _apiService.fetchPjpsForUser(widget.userId);

      final active = <Pjp>[];
      final completed = <Pjp>[];

      for (var p in data) {
        if (p.status.trim().toLowerCase() == 'completed') {
          completed.add(p);
        } else {
          active.add(p);
        }
      }

      if (mounted) {
        setState(() {
          _activePjps = active;
          _completedPjps = completed;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load plans: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => _isLoading = true);
    await _loadPjps();
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 O(1) Pointer assignment based on tab state
    final currentList = _showCompleted ? _completedPjps : _activePjps;

    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: _bgLight,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: _cardNavy),
        toolbarHeight: 70,
        title:
            Text(
                  "Journey Plans",
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
      ),
      body: Column(
        children: [
          _buildCustomTabBar()
              .animate()
              .fadeIn(delay: 100.ms)
              .slideY(begin: -0.2),
          const SizedBox(height: 12),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: _cardNavy,
              backgroundColor: Colors.white,
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: _cardNavy))
                  : currentList.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                      itemCount: currentList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (_, index) {
                        // ✨ STAGGERED LIST ANIMATION
                        return _buildCard(currentList[index])
                            .animate(
                              key: ValueKey('${currentList[index].id}_$index'),
                              delay: (index * 40).ms,
                            )
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.1, curve: Curves.easeOut);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _cardNavy.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTabSegment("In Progress", !_showCompleted),
          _buildTabSegment("Completed", _showCompleted),
        ],
      ),
    );
  }

  Widget _buildTabSegment(String title, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if ((title == "Completed" && !_showCompleted) ||
              (title == "In Progress" && _showCompleted)) {
            HapticFeedback.selectionClick();
            setState(() => _showCompleted = !_showCompleted);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? _cardNavy : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _cardNavy.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : _textGrey,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(), // Allows pull-to-refresh even when empty
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
                  Icons.route_outlined,
                  size: 48,
                  color: _textGrey.withOpacity(0.5),
                ),
              ).animate().scale(
                delay: 100.ms,
                curve: Curves.easeOutBack,
                duration: 600.ms,
              ),
              const SizedBox(height: 32),
              Text(
                    "No Plans Found",
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
              Text(
                _showCompleted
                    ? "You haven't completed any plans yet."
                    : "You have no active plans.",
                style: TextStyle(color: _textGrey, fontSize: 15),
              ).animate().fadeIn(delay: 300.ms),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard(Pjp p) {
    final date = DateFormat('dd MMM, yyyy').format(p.planDate);
    final isCompleted = p.status.trim().toLowerCase() == 'completed';
    final isPending = p.status.trim().toLowerCase() == 'pending';

    final statusColor = isCompleted
        ? _accentGreen
        : (isPending ? Colors.orange : _accentBlue);
    final iconData = isCompleted
        ? Icons.check_circle_rounded
        : (isPending ? Icons.pending_actions_rounded : Icons.near_me_rounded);

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
              child: Icon(iconData, color: statusColor, size: 26),
            ),
            const SizedBox(width: 16),

            // ✨ PJP DETAILS
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      p.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Text(
                    p.areaToBeVisited,
                    style: TextStyle(
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
                      Icon(
                        Icons.directions_car_rounded,
                        color: _textGrey,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          p.route?.isNotEmpty == true
                              ? p.route!
                              : 'No specific route',
                          style: TextStyle(
                            color: _textGrey,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: _textGrey,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        date,
                        style: TextStyle(
                          color: _textGrey,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
