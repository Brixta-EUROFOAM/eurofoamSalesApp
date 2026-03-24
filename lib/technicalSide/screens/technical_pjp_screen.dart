// lib/technicalSide/screens/technical_pjp_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart'; // 🔥 ADDED FOR ANIMATIONS

import 'package:salesmanapp/salesSide/models/employee_model.dart';
import 'package:salesmanapp/salesSide/models/pjp_model.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/technicalSide/screens/forms/create_technical_pjp_form.dart';
import 'package:salesmanapp/technicalSide/screens/bulk_technical_pjp_wizard_screen.dart';

import 'package:salesmanapp/core/feature_flags/technical_flags.dart';
import 'package:salesmanapp/core/app_kernel.dart';
import 'package:salesmanapp/features/technicalPjpcreate/pjp_create_controller.dart';
import 'package:salesmanapp/features/technicalPjpcreate/pjp_create_results.dart';
import 'package:salesmanapp/features/technicalPjpshowcreateOptions/create_option_controller.dart';
import 'package:salesmanapp/features/JourneyModeController/journey_mode_result.dart';
import 'package:salesmanapp/services/states/pjpStates/startJourney.dart';

class TechnicalPjpScreen extends StatefulWidget {
  final Employee employee;
  final Function(Map<String, dynamic> journeyData) onStartJourney;

  const TechnicalPjpScreen({
    super.key,
    required this.employee,
    required this.onStartJourney,
  });

  @override
  State<TechnicalPjpScreen> createState() => TechnicalPjpScreenState();
}

class TechnicalPjpScreenState extends State<TechnicalPjpScreen> {
  final ApiService _apiService = ApiService();

  // 🚀 O(1) STATE MANAGEMENT: Replaced FutureBuilder
  List<Pjp> _activePjps = [];
  bool _isLoading = true;

  DateTime _selectedDate = DateTime.now();
  late final List<DateTime> _cachedDates; // 🚀 OPTIMIZATION: Memoized Dates

  late JourneyStateMachine _journeyManager;

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
    final flags = context.read<TechnicalFlags>();

    // 🚀 O(1) DATE CACHING: Calculate dates once, not on every build frame
    final now = DateTime.now();
    _cachedDates = List.generate(
      30,
      (i) => now.subtract(const Duration(days: 2)).add(Duration(days: i)),
    );

    if (flags.createPjp) refreshPjpList();

    _journeyManager = JourneyStateMachine(
      apiService: _apiService,
      flags: flags,
    );
    _journeyManager.addListener(_onJourneyStateChanged);
  }

  @override
  void dispose() {
    _journeyManager.removeListener(_onJourneyStateChanged);
    _journeyManager.dispose();
    super.dispose();
  }

  void _onJourneyStateChanged() {
    final state = _journeyManager.value;

    if (state is JourneySuccess) {
      widget.onStartJourney({
        'pjp': state.pjp,
        'displayName': state.result.displayName,
        'destination': state.result.destination,
        'journeyMode': JourneyMode.planned,
        'isSite': state.result.isSite,
        'site': null,
        'dealer': null,
      });
      _journeyManager.reset();
    } else if (state is JourneyFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            state.errorMessage,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      _journeyManager.reset();
    }
  }

  // 🚀 O(N) FETCH & FILTER EXACTLY ONCE
  Future<void> refreshPjpList() async {
    setState(() => _isLoading = true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final data = await _apiService.fetchPjpsForUser(
        int.parse(widget.employee.id),
        startDate: dateStr,
        endDate: dateStr,
      );

      final active = <Pjp>[];
      for (var p in data) {
        if (p.status != 'COMPLETED') active.add(p);
      }

      if (mounted) {
        setState(() {
          _activePjps = active;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading plans: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _onDateSelected(DateTime date) {
    setState(() => _selectedDate = date);
    refreshPjpList();
  }

  void _showCreateOptions() {
    try {
      final controller = AppKernel.instance.feature<CreateOptionController>();
      final options = controller.getOptions();

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) {
          return SafeArea(
            child: Wrap(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child:
                      Text(
                        "Plan New Visit",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: _cardNavy,
                          letterSpacing: -0.5,
                        ),
                      ).animate().fadeIn().slideY(
                        begin: 0.2,
                        curve: Curves.easeOutBack,
                      ),
                ),
                ...options.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _bgLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(option.icon, color: _cardNavy),
                        ),
                        title: Text(
                          option.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _textDark,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          option.subtitle,
                          style: TextStyle(color: _textGrey, fontSize: 13),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          switch (option.mode) {
                            case PjpCreateMode.single:
                              _showSingleCreateForm();
                              break;
                            case PjpCreateMode.bulk:
                              _showBulkWizard();
                              break;
                          }
                        },
                      )
                      .animate()
                      .fadeIn(delay: (100 + (index * 50)).ms)
                      .slideX(begin: -0.1, curve: Curves.easeOutCubic);
                }),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _showSingleCreateForm() {
    try {
      final controller = AppKernel.instance.feature<PjpCreateController>();
      final result = controller.startSingle();
      if (result.mode == PjpCreateMode.single) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          enableDrag: false,
          builder: (_) => CreateTechnicalPjpForm(
            employee: widget.employee,
            onPjpCreated: refreshPjpList,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _showBulkWizard() {
    try {
      final controller = AppKernel.instance.feature<PjpCreateController>();
      final result = controller.startBulk();
      if (result.mode == PjpCreateMode.bulk) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BulkTechnicalPjpWizardScreen(
              employee: widget.employee,
              onPjpCreated: refreshPjpList,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _startJourney(Pjp pjp) async {
    await _journeyManager.dispatch(StartJourneyIntent(pjp));
  }

  Future<void> _completePjp(Pjp pjp) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "End Visit Plan?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "This will mark the PJP as COMPLETED.\n\n"
          "• You cannot start this journey again today.\n"
          "• Ensure you have submitted all reports.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "CANCEL",
              style: TextStyle(color: _textGrey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "END VISIT",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ).animate().scale(curve: Curves.easeOutBack, duration: 400.ms),
    );

    if (confirm != true) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _apiService.updatePjp(pjp.id, {'status': 'COMPLETED'});
      if (mounted) Navigator.pop(context);
      refreshPjpList();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Visit Marked as Completed",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: _accentGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to end: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final flags = context.read<TechnicalFlags>();
    final displayDate = DateFormat('d MMMM, yyyy').format(_selectedDate);
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
                    isToday ? "Today's Plan" : "Scheduled Visits",
                    style: TextStyle(
                      color: _cardNavy,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: -0.1, curve: Curves.easeOut),
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
                        displayDate,
                        style: TextStyle(
                          color: _textGrey,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 400.ms)
                  .slideX(begin: -0.1, curve: Curves.easeOut),
            ],
          ),
        ),
        actions: [
          if (flags.createPjp)
            Padding(
              padding: const EdgeInsets.only(right: 20.0, top: 10),
              child: Center(
                child:
                    InkWell(
                          onTap: _showCreateOptions,
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
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "New Plan",
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
      body: Column(
        children: [
          const SizedBox(height: 10),
          if (flags.visits) _buildDateSelector(),
          const SizedBox(height: 16),
          Expanded(
            child: flags.pjpjourney
                ? RefreshIndicator(
                    onRefresh: refreshPjpList,
                    color: _cardNavy,
                    backgroundColor: Colors.white,
                    child: _isLoading
                        ? Center(
                            child: CircularProgressIndicator(color: _cardNavy),
                          )
                        : _activePjps.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                            itemCount: _activePjps.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              // ✨ KEYED STAGGERED LIST ANIMATION FOR $O(1)$ DIFFING
                              return _buildVisitCard(_activePjps[index])
                                  .animate(
                                    key: ValueKey(_activePjps[index].id),
                                    delay: (index * 50).ms,
                                  )
                                  .fadeIn(duration: 400.ms)
                                  .slideY(begin: 0.1, curve: Curves.easeOut);
                            },
                          ),
                  )
                : const SizedBox.shrink(),
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
        itemCount: _cachedDates.length, // 🚀 Pulls from O(1) cache
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
              )
              .animate()
              .fadeIn(delay: (index * 20).ms)
              .slideX(begin: 0.2, curve: Curves.easeOut); // ✨ Smooth scroll-in
        },
      ),
    );
  }

  Widget _buildVisitCard(Pjp pjp) {
    final flags = context.read<TechnicalFlags>();
    final isPending = pjp.status.toUpperCase() == 'PENDING';
    final isInProgress = pjp.status.toUpperCase() == 'IN_PROGRESS';

    final statusColor = isPending
        ? Colors.orange
        : (isInProgress ? _accentBlue : _accentGreen);
    final statusText = isPending
        ? "PENDING"
        : (isInProgress ? "IN PROGRESS" : "APPROVED");

    String displayName = "Planned Area Visit";
    String displayAddress = "";
    try {
      final parts = pjp.areaToBeVisited.split('|');
      if (parts.isNotEmpty && parts.first.trim().isNotEmpty) {
        displayName = parts.first.trim();
        displayAddress = parts.first;
      }
    } catch (_) {}

    // 🚀 O(1) REBUILD TARGETING:
    // AnimatedBuilder listens directly to _journeyManager.
    // Now, ONLY the card handles its own loading state without rebuilding the entire list.
    return AnimatedBuilder(
      animation: _journeyManager,
      builder: (context, child) {
        final currentState = _journeyManager.value;
        final bool isStarting =
            (currentState is JourneyProcessing) &&
            (currentState.pjpId == pjp.id);
        final bool isBusy = currentState is JourneyProcessing;

        return Slidable(
          enabled: !isBusy && flags.pjpjourney && !isPending,
          startActionPane: ActionPane(
            motion: const BehindMotion(),
            children: [
              SlidableAction(
                onPressed: (_) => _startJourney(pjp),
                backgroundColor: _bgLight,
                foregroundColor: _accentGreen,
                icon: Icons.navigation_rounded,
                label: isInProgress ? 'Resume' : 'Start',
                borderRadius: BorderRadius.circular(20),
              ),
            ],
          ),
          endActionPane: ActionPane(
            motion: const BehindMotion(),
            children: [
              SlidableAction(
                onPressed: (_) => isBusy ? null : _completePjp(pjp),
                backgroundColor: _bgLight,
                foregroundColor: Colors.red,
                icon: Icons.stop_circle_outlined,
                label: 'End',
                borderRadius: BorderRadius.circular(20),
              ),
            ],
          ),
          child: Container(
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
            child: Stack(
              alignment: Alignment.center,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: (flags.journey && !isBusy)
                        ? () => _startJourney(pjp)
                        : null,
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: isStarting ? 0.5 : 1.0,
                        child: Row(
                          children: [
                            Container(
                              height: 56,
                              width: 56,
                              decoration: BoxDecoration(
                                color: isInProgress
                                    ? _accentBlue.withOpacity(0.1)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(
                                isInProgress
                                    ? Icons.near_me_rounded
                                    : Icons.location_city_rounded,
                                color: isInProgress ? _accentBlue : _cardNavy,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 18),
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
                                      statusText,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: statusColor,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    displayName,
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
                                        Icons.location_on,
                                        color: _textGrey,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          displayAddress,
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
                            if (!isPending)
                              Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: _bgLight,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  color: _cardNavy,
                                  size: 20,
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  Icons.lock_clock,
                                  size: 16,
                                  color: _textGrey,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (isStarting)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: _accentGreen,
                        ),
                      ),
                    ).animate().fadeIn(duration: 200.ms),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final flags = context.read<TechnicalFlags>();
    return Center(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(), // Allow pull-to-refresh
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
                  Icons.map_outlined,
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
                    "No Plans for Today",
                    style: TextStyle(
                      color: _textDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 400.ms)
                  .slideY(begin: 0.5, curve: Curves.easeOutCubic),
              const SizedBox(height: 8),
              Text(
                "Your schedule is clear.",
                style: TextStyle(color: _textGrey, fontSize: 15),
              ).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 32),
              if (flags.createPjp)
                ElevatedButton.icon(
                      onPressed: _showCreateOptions,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text("Create New Plan"),
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
                    .fadeIn(delay: 600.ms)
                    .scale(curve: Curves.easeOutBack),
            ],
          ),
        ],
      ),
    );
  }
}
