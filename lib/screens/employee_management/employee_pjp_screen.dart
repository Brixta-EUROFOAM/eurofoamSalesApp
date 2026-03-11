// lib/screens/employee_management/employee_pjp_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/models/daily_task_model.dart';
import 'package:salesmanapp/models/employee_model.dart';
import 'package:salesmanapp/screens/employee_management/bulk_pjp_wizard_screen.dart';

class EmployeePJPScreen extends StatefulWidget {
  final Employee employee;
  final Function(Map<String, dynamic> journeyData) onStartJourney;
  final VoidCallback onPjpCreated;

  const EmployeePJPScreen({
    super.key,
    required this.employee,
    required this.onStartJourney,
    required this.onPjpCreated,
  });

  @override
  State<EmployeePJPScreen> createState() => EmployeePJPScreenState();
}

// 🚀 ZERO-BATTERY AUTO REFRESH: Added WidgetsBindingObserver
class EmployeePJPScreenState extends State<EmployeePJPScreen>
    with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();

  // 🚀 O(1) STATE MANAGEMENT: Replaced FutureBuilder
  List<DailyTask> _activeTasks = [];
  bool _isLoading = true;

  DateTime _selectedDate = DateTime.now();
  late final List<DateTime> _cachedDates; // 🚀 OPTIMIZATION: Memoized Dates

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
    WidgetsBinding.instance.addObserver(this); // Register lifecycle observer

    // 🚀 O(1) DATE CACHING: Calculate dates once, not on every build frame
    final now = DateTime.now();
    _cachedDates = List.generate(
      14,
      (i) => now.subtract(const Duration(days: 1)).add(Duration(days: i)),
    );

    _refreshTasks();
  }

  // 🚀 AUTO-REFRESH TRIGGER: Fires instantly when user returns to the app
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshTasks();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Prevent memory leak
    super.dispose();
  }

  void refreshPjpList() => _refreshTasks();

  // 🚀 O(N) FETCH & FILTER EXACTLY ONCE
  Future<void> _refreshTasks() async {
    setState(() => _isLoading = true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final allTasks = await _apiService.fetchDailyTasksForUser(
        int.parse(widget.employee.id),
        startDate: dateStr,
        endDate: dateStr,
      );

      final active = <DailyTask>[];
      for (var t in allTasks) {
        final s = t.status.toLowerCase();
        if (s != 'completed' && s != 'rescheduled' && s != 'failed') {
          active.add(t);
        }
      }

      if (mounted) {
        setState(() {
          _activeTasks = active;
          _isLoading = false;
        });
      }
    } 
    catch (e) {
      // if (mounted) {
      //   setState(() => _isLoading = false);
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text('Error loading tasks: $e'),
      //       backgroundColor: _dangerRed,
      //     ),
      //   );
      // }
    }
  }

  void _onDateSelected(DateTime date) {
    HapticFeedback.selectionClick();
    setState(() => _selectedDate = date);
    _refreshTasks();
  }

  Future<void> _handleStartTask(DailyTask task) async {
    if (task.status.toLowerCase() == 'completed' ||
        task.status.toLowerCase() == 'failed') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Task is no longer active.",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
      return;
    }

    if (task.id == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid task ID")));
      return;
    }

    final journeyData = {
      'taskId': task.id!,
      'pjpId': task.pjpBatchId,
      'dealerId': task.dealerId,
      'displayName': task.dealerNameSnapshot ?? "Site Visit",
      'description': task.objective,
      'coordinates': (task.latitude != null && task.longitude != null) 
          ? {'lat': task.latitude, 'lng': task.longitude} 
          : null,
      'visitType': task.visitType,
    };

    try {
      widget.onStartJourney(journeyData);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error starting task: $e")));
    }
  }

  void _openBulkPlanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BulkPjpWizardScreen(
          employee: widget.employee,
          onPjpCreated: () {
            refreshPjpList(); // refresh task list
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // 🚀 RESCHEDULE LOGIC (3 STRIKES RULE)
  // ===========================================================================
  int _getRescheduleCount(String? objective) {
    if (objective == null) return 0;
    if (objective.contains("[Rescheduled x3]")) return 3;
    if (objective.contains("[Rescheduled x2]")) return 2;
    if (objective.contains("[Rescheduled x1]")) return 1;
    return 0;
  }

  void _showEndTaskBottomSheet(DailyTask task) {
    HapticFeedback.mediumImpact();
    String selectedReason = '';
    final TextEditingController remarkController = TextEditingController();

    final int currentStrikes = _getRescheduleCount(task.objective);
    final bool maxStrikesReached = currentStrikes >= 3;

    final List<String> reasons = maxStrikesReached
        ? ["Day End (Completed)", "Failed (Max Reschedules Reached)"]
        : [
            "Day End (Completed)",
            "Shop Closed",
            "Dealer Unavailable",
            "Reschedule / Other",
          ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final bool isReschedule =
                selectedReason != '' &&
                selectedReason != "Day End (Completed)" &&
                selectedReason != "Failed (Max Reschedules Reached)";

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "End Visit",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: _textDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (currentStrikes > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: maxStrikesReached
                                ? _dangerRed.withOpacity(0.1)
                                : _pendingOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "Strike $currentStrikes of 3",
                            style: TextStyle(
                              color: maxStrikesReached
                                  ? _dangerRed
                                  : _pendingOrange,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ).animate().scale(curve: Curves.easeOutBack),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    maxStrikesReached
                        ? "This visit has been rescheduled 3 times. It must be completed or marked as failed."
                        : "Why are you ending this visit?",
                    style: TextStyle(
                      fontSize: 14,
                      color: maxStrikesReached ? _dangerRed : _textGrey,
                      fontWeight: maxStrikesReached
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // REASON CHIPS
                  Wrap(
                    spacing: 10,
                    runSpacing: 12,
                    children: reasons.map((reason) {
                      final bool isSelected = selectedReason == reason;
                      Color chipColor = _pendingOrange;
                      if (reason == "Day End (Completed)")
                        chipColor = _accentGreen;
                      if (reason == "Failed (Max Reschedules Reached)")
                        chipColor = _dangerRed;

                      return ChoiceChip(
                        label: Text(reason),
                        selected: isSelected,
                        selectedColor: chipColor.withOpacity(0.15),
                        backgroundColor: _bgLight,
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected ? chipColor : Colors.transparent,
                          ),
                        ),
                        labelStyle: TextStyle(
                          color: isSelected ? chipColor : _textGrey,
                          fontWeight: isSelected
                              ? FontWeight.w900
                              : FontWeight.w600,
                        ),
                        onSelected: (selected) {
                          HapticFeedback.selectionClick();
                          setModalState(
                            () => selectedReason = selected ? reason : '',
                          );
                        },
                      );
                    }).toList(),
                  ),

                  // TEXT FIELD FOR RESCHEDULE
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    child: isReschedule
                        ? Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: TextField(
                              controller: remarkController,
                              maxLines: 2,
                              style: TextStyle(
                                color: _textDark,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: "Add remarks for tomorrow's visit...",
                                hintStyle: TextStyle(
                                  color: _textGrey.withOpacity(0.7),
                                ),
                                filled: true,
                                fillColor: _bgLight,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: _cardNavy,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ).animate().fadeIn().slideY(begin: -0.1),
                          )
                        : const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 32),

                  // SUBMIT BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            selectedReason == "Failed (Max Reschedules Reached)"
                            ? _dangerRed
                            : _cardNavy,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: selectedReason.isEmpty ? 0 : 8,
                        shadowColor:
                            (selectedReason ==
                                        "Failed (Max Reschedules Reached)"
                                    ? _dangerRed
                                    : _cardNavy)
                                .withOpacity(0.4),
                      ),
                      onPressed: selectedReason.isEmpty
                          ? null
                          : () {
                              Navigator.pop(context);
                              _executeEndTaskLogic(
                                task,
                                selectedReason,
                                remarkController.text,
                                currentStrikes,
                              );
                            },
                      child: Text(
                        selectedReason == "Failed (Max Reschedules Reached)"
                            ? "MARK AS FAILED"
                            : (isReschedule
                                  ? "RESCHEDULE TO TOMORROW"
                                  : "COMPLETE VISIT"),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().slideY(
              begin: 1.0,
              duration: 400.ms,
              curve: Curves.easeOutCubic,
            );
          },
        );
      },
    ).whenComplete(() => remarkController.dispose()); // 🚀 PREVENT MEMORY LEAK
  }

  Future<void> _executeEndTaskLogic(
    DailyTask task,
    String reason,
    String remarks,
    int currentStrikes,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (reason == "Day End (Completed)") {
      try {
        await _apiService.updateDailyTaskStatus(task.id!, "Completed");
        _refreshTasks();
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
      return;
    }

    if (reason == "Failed (Max Reschedules Reached)") {
      try {
        await _apiService.updateDailyTaskStatus(task.id!, "Failed");
        _refreshTasks();
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
      return;
    }

    try {
      final int newStrikeCount = currentStrikes + 1;

      String cleanObjective = task.objective ?? 'No objective set';
      cleanObjective = cleanObjective.replaceAll(
        RegExp(r'\[Rescheduled x\d\] '),
        '',
      );

      final String combinedObjective =
          "[Rescheduled x$newStrikeCount] Reason: $reason ${remarks.isNotEmpty ? '($remarks)' : ''} | $cleanObjective";

      final tomorrowTask = DailyTask(
        id: null,
        pjpBatchId: task.pjpBatchId,
        userId: task.userId,
        dealerId: task.dealerId,
        dealerNameSnapshot: task.dealerNameSnapshot,
        dealerMobile: task.dealerMobile,
        zone: task.zone,
        area: task.area,
        route: task.route,
        objective: combinedObjective,
        visitType: task.visitType,
        requiredVisitCount: task.requiredVisitCount,
        week: task.week,
        taskDate: DateTime.now().add(const Duration(days: 1)),
        status: "Assigned",
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _apiService.createDailyTask(tomorrowTask);
      await _apiService.updateDailyTaskStatus(task.id!, "Failed");

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: const Text(
            "Rescheduled to tomorrow",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: _accentBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      _refreshTasks();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text("Failed to reschedule: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    isToday ? "Today's Plan" : "Visits",
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
                        "$displayDay, $displayDate",
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
          Padding(
            padding: const EdgeInsets.only(right: 20.0, top: 10),
            child:
                InkWell(
                      onTap: _openBulkPlanner,
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
              onRefresh: _refreshTasks,
              color: _cardNavy,
              backgroundColor: Colors.white,
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: _cardNavy))
                  : _activeTasks.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                      itemCount: _activeTasks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (_, index) {
                        // ✨ KEYED STAGGERED LIST ANIMATION FOR $O(1)$ DIFFING
                        return _buildTaskCard(_activeTasks[index])
                            .animate(
                              key: ValueKey(_activeTasks[index].id),
                              delay: (index * 50).ms,
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
              .slideX(begin: 0.2, curve: Curves.easeOut);
        },
      ),
    );
  }

  // ✨ THE SQUIRCLE CARD UI WITH EXPLICIT START BUTTON
  Widget _buildTaskCard(DailyTask task) {
    final isPending = task.status.toLowerCase() == 'pending';
    final isStarted =
        task.status.toLowerCase() == 'started' ||
        task.status.toLowerCase() == 'in progress';
    final isAssigned = task.status.toLowerCase() == 'assigned' || task.status.toLowerCase() == 'approved';

    Color statusColor = _cardNavy;
    if (isStarted) statusColor = _accentBlue;
    if (isAssigned) statusColor = _accentGreen;
    if (isPending) statusColor = _pendingOrange;

    final String displayAddress = task.area != null && task.zone != null
        ? "${task.area}, ${task.zone}"
        : (task.dealerId != null
              ? "Dealer ID: ${task.dealerId}"
              : "Location pending");

    Widget cardContent = Slidable(
      enabled: !isPending,
      startActionPane: ActionPane(
        motion: const BehindMotion(),
        children: [
          SlidableAction(
            onPressed: (_) {
              HapticFeedback.heavyImpact();
              _handleStartTask(task);
            },
            backgroundColor: _bgLight,
            foregroundColor: _accentGreen,
            icon: Icons.play_arrow_rounded,
            label: 'Start',
            borderRadius: BorderRadius.circular(20),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _showEndTaskBottomSheet(task),
            backgroundColor: _bgLight,
            foregroundColor: Colors.red,
            icon: Icons.stop_circle_outlined,
            label: 'End',
            borderRadius: BorderRadius.circular(20),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () => _showTaskDetailsBottomSheet(task),
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
                  onTap: () => _showTaskDetailsBottomSheet(task),
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        // ✨ SQUIRCLE AVATAR
                        Container(
                          height: 56,
                          width: 56,
                          decoration: BoxDecoration(
                            color: isStarted
                                ? _accentBlue.withOpacity(0.1)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            isStarted
                                ? Icons.near_me_rounded
                                : Icons.storefront_rounded,
                            color: isStarted ? _accentBlue : _cardNavy,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                      task.status.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: statusColor,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  if (task.visitType != null &&
                                      task.visitType!.isNotEmpty)
                                    Text(
                                      task.visitType!.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: _textGrey,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                ],
                              ),
                              Text(
                                task.dealerNameSnapshot ?? "Unnamed Dealer",
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

                        // 🚀 THE EXPLICIT TAP-TO-PLAY BUTTON
                        if (!isStarted && !isPending)
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.heavyImpact();
                              _handleStartTask(task);
                            },
                            child: Container(
                              height: 44,
                              width: 44,
                              decoration: BoxDecoration(
                                color: _accentGreen.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                // NO CONST KEYWORD HERE
                                Icons.play_arrow_rounded,
                                color: _accentGreen,
                                size: 24,
                              ),
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
            ],
          ),
        ),
      ),
    );

    if (isStarted) {
      return cardContent
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(duration: 2500.ms, color: Colors.blue.withOpacity(0.2));
    }
    return cardContent;
  }

  void _showTaskDetailsBottomSheet(DailyTask task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
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

              Text(
                    task.dealerNameSnapshot ?? "Unnamed Dealer",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: _textDark,
                      letterSpacing: -0.5,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.2, curve: Curves.easeOutCubic),
              const SizedBox(height: 6),
              Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _cardNavy.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          task.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: _cardNavy,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (task.week != null)
                        Text(
                          "Week: ${task.week}",
                          style: TextStyle(
                            fontSize: 12,
                            color: _textGrey,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                    ],
                  )
                  .animate()
                  .fadeIn(delay: 50.ms, duration: 300.ms)
                  .slideX(begin: -0.1, curve: Curves.easeOutCubic),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Divider(height: 1),
              ),

              Text(
                "VISIT DETAILS",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  color: _textGrey,
                  letterSpacing: 1.2,
                ),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 16),

              _buildDetailRow(
                Icons.description_rounded,
                "Objective",
                task.objective ?? "No objective set",
              ).animate().fadeIn(delay: 150.ms).slideX(begin: -0.05),
              _buildDetailRow(
                Icons.phone_rounded,
                "Phone",
                task.dealerMobile ?? "Not available",
              ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.05),
              _buildDetailRow(
                Icons.map_rounded,
                "Zone",
                task.zone ?? "Pending",
              ).animate().fadeIn(delay: 250.ms).slideX(begin: -0.05),
              _buildDetailRow(
                Icons.place_rounded,
                "Area",
                task.area ?? "Pending",
              ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.05),
              if (task.route != null && task.route!.isNotEmpty)
                _buildDetailRow(
                  Icons.directions_rounded,
                  "Route",
                  task.route!,
                ).animate().fadeIn(delay: 350.ms).slideX(begin: -0.05),

              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ).animate().slideY(
          begin: 1.0,
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: _textGrey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: _textGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: _textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(), // Allows pull-to-refresh
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
                  Icons.assignment_add,
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
                  )
                  .animate()
                  .fadeIn(delay: 400.ms)
                  .slideY(begin: 0.5, curve: Curves.easeOutCubic),
              const SizedBox(height: 8),
              Text(
                "Select another date to view tasks.",
                style: TextStyle(color: _textGrey, fontSize: 15),
              ).animate().fadeIn(delay: 500.ms),
            ],
          ),
        ],
      ),
    );
  }
}
