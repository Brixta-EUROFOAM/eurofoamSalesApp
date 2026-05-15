// lib/screens/pjpScreen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../api/api_service.dart';
import '../models/pjp_model.dart';
import 'forms/add_PJP_form.dart';

class PjpScreen extends StatefulWidget {
  const PjpScreen({Key? key}) : super(key: key);

  @override
  State<PjpScreen> createState() => _PjpScreenState();
}

class _PjpScreenState extends State<PjpScreen> with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();

  List<PjpModel> _allPjps = [];
  bool _isLoading = true;

  DateTime _selectedDate = DateTime.now();
  late final List<DateTime> _cachedDates;

  // --- 🎨 PREMIUM THEME PALETTE ---
  final Color _bgLight = const Color(0xFFF8FAFC);
  final Color _cardNavy = const Color(0xFF0F172A);
  final Color _textDark = const Color(0xFF1E293B);
  final Color _textGrey = const Color(0xFF64748B);
  final Color _surfaceWhite = Colors.white;
  final Color _accentGreen = const Color(0xFF10B981);
  final Color _accentBlue = const Color(0xFF3B82F6);
  final Color _pendingOrange = const Color(0xFFF59E0B);
  final Color _dangerRed = const Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 🚀 O(1) DATE CACHING: Generate dates for the selector (14 days range)
    final now = DateTime.now();
    _cachedDates = List.generate(
      14,
      (i) => now.subtract(const Duration(days: 3)).add(Duration(days: i)),
    );

    _fetchPjps();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchPjps();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
      return pjp.planDate.year == day.year &&
          pjp.planDate.month == day.month &&
          pjp.planDate.day == day.day;
    }).toList();
  }

  void _onDateSelected(DateTime date) {
    HapticFeedback.selectionClick();
    setState(() => _selectedDate = date);
  }

  Future<void> _openAddPjpWizard() async {
    HapticFeedback.mediumImpact();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddPjpFormScreen()),
    );
    if (result == true) _fetchPjps();
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return _pendingOrange;
      case 'COMPLETED':
        return _accentGreen;
      case 'APPROVED':
        return _accentBlue;
      case 'REJECTED':
        return _dangerRed;
      default:
        return _textGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedPjps = _getEventsForDay(_selectedDate);
    final displayDate = DateFormat('d MMMM, yyyy').format(_selectedDate);
    final displayDay = DateFormat('EEEE').format(_selectedDate);
    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());

    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: _bgLight,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: false,
        toolbarHeight: 80,
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0, top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isToday ? "Today's Plan" : "Journey Plans",
                style: TextStyle(
                  color: _cardNavy,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                ),
              ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, curve: Curves.easeOut),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: _textGrey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "$displayDay, $displayDate",
                    style: TextStyle(
                      color: _textGrey,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideX(begin: -0.1, curve: Curves.easeOut),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0, top: 10),
            child: InkWell(
              onTap: _openAddPjpWizard,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _cardNavy,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: _cardNavy.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_location_alt_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Plan Visits",
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
            .then()
            .shimmer(duration: 2500.ms, color: Colors.white24)
            .animate(onPlay: (c) => c.repeat()),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          _buildDateSelector(),
          const SizedBox(height: 16),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchPjps,
              color: _cardNavy,
              backgroundColor: Colors.white,
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: _cardNavy))
                  : selectedPjps.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                      itemCount: selectedPjps.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (_, index) {
                        final pjp = selectedPjps[index];
                        return _buildPjpCard(pjp, index);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      height: 100,
      color: _bgLight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _cachedDates.length,
        itemBuilder: (context, index) {
          final date = _cachedDates[index];
          final isSelected = DateUtils.isSameDay(date, _selectedDate);
          final isToday = DateUtils.isSameDay(date, DateTime.now());

          return GestureDetector(
            onTap: () => _onDateSelected(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: 64,
              margin: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isSelected ? _cardNavy : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: isToday && !isSelected
                    ? Border.all(
                        color: _cardNavy.withOpacity(0.3),
                        width: 1.5,
                      )
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _cardNavy.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date).toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? Colors.white.withOpacity(0.6)
                          : _textGrey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('d').format(date),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? Colors.white : _textDark,
                    ),
                  ),
                  if (isToday)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isSelected ? _accentGreen : _cardNavy,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: (index * 20).ms).slideX(begin: 0.2, curve: Curves.easeOut);
        },
      ),
    );
  }

  Widget _buildPjpCard(PjpModel pjp, int index) {
    final statusColor = _getStatusColor(pjp.status);
    final isCompleted = pjp.status.toUpperCase() == 'COMPLETED';

    return Container(
      decoration: BoxDecoration(
        color: _surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _cardNavy.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: _cardNavy.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✨ SQUIRCLE AVATAR
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? _accentGreen.withOpacity(0.1)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle_rounded : Icons.location_on_rounded,
                  color: isCompleted ? _accentGreen : _cardNavy,
                  size: 26,
                ),
              ),
              const SizedBox(width: 18),
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
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            pjp.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: statusColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      pjp.areaToBeVisited,
                      style: TextStyle(
                        color: _textDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    if (pjp.visitDealerName != null)
                      Row(
                        children: [
                          Icon(
                            Icons.storefront_rounded,
                            color: _textGrey,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              pjp.visitDealerName!,
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
                  ],
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
                Icon(Icons.notes_rounded, size: 16, color: _textGrey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pjp.description!,
                    style: TextStyle(color: _textGrey, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate(key: ValueKey(pjp.id)).fadeIn(delay: (index * 50).ms).slideY(begin: 0.1, curve: Curves.easeOut);
  }

  Widget _buildEmptyState() {
    return Center(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _cardNavy.withOpacity(0.08),
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
                delay: 200.ms,
                curve: Curves.easeOutBack,
                duration: 600.ms,
              ),
              const SizedBox(height: 32),
              Text(
                "No Visits Planned",
                style: TextStyle(
                  color: _textDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.5, curve: Curves.easeOutCubic),
              const SizedBox(height: 8),
              Text(
                "Select another date or create a new plan.",
                style: TextStyle(color: _textGrey, fontSize: 15),
              ).animate().fadeIn(delay: 500.ms),
            ],
          ),
        ],
      ),
    );
  }
}
