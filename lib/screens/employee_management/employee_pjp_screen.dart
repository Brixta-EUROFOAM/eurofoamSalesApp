// lib/screens/employee_management/employee_pjp_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/models/daily_task_model.dart';
import 'package:salesmanapp/models/employee_model.dart';

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

class EmployeePJPScreenState extends State<EmployeePJPScreen> {
  final ApiService _apiService = ApiService();

  // State
  DateTime _selectedDate = DateTime.now();
  late Future<List<DailyTask>> _tasksFuture;

  // --- FINTECH THEME PALETTE ---
  final Color _bgLight = const Color(0xFFF3F4F6);
  final Color _cardNavy = const Color(0xFF0F172A);
  final Color _textDark = const Color(0xFF111827);
  final Color _textGrey = const Color(0xFF6B7280);
  final Color _surfaceWhite = Colors.white;
  final Color _accentGreen = const Color(0xFF10B981);
  final Color _pendingOrange = const Color(0xFFF59E0B);
  final Color _dangerRed = const Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _refreshTasks();
  }

  void refreshPjpList() {
    _refreshTasks();
  }

  void _refreshTasks() {
    if (mounted) {
      setState(() {
        final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
        _tasksFuture = _apiService.fetchDailyTasksForUser(
          int.parse(widget.employee.id),
          startDate: dateStr,
          endDate: dateStr,
        );
      });
    }
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _refreshTasks();
  }

  Future<void> _handleStartTask(DailyTask task) async {
    if (task.status.toLowerCase() == 'completed' || task.status.toLowerCase() == 'failed') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Task is no longer active.")),
      );
      return;
    }

    if (task.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid task ID")),
      );
      return;
    }

    final journeyData = {
      'taskId': task.id!,
      'pjpId': task.pjpBatchId,
      'dealerId': task.dealerId,
      'displayName': task.dealerNameSnapshot ?? "Site Visit",
      'description': task.objective,
      'coordinates': null,
      'visitType': task.visitType,
    };

    try {
      widget.onStartJourney(journeyData);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error starting task: $e")),
      );
    }
  }

  // ===========================================================================
  // 🚀 RESCHEDULE LOGIC (3 STRIKES RULE)
  // ===========================================================================
  
  // Helper to extract the current reschedule count from the objective string
  int _getRescheduleCount(String? objective) {
    if (objective == null) return 0;
    if (objective.contains("[Rescheduled x3]")) return 3;
    if (objective.contains("[Rescheduled x2]")) return 2;
    if (objective.contains("[Rescheduled x1]")) return 1;
    return 0;
  }

  void _showEndTaskBottomSheet(DailyTask task) {
    String selectedReason = '';
    final TextEditingController remarkController = TextEditingController();

    final int currentStrikes = _getRescheduleCount(task.objective);
    final bool maxStrikesReached = currentStrikes >= 3;

    // If max strikes reached, they CANNOT reschedule. Only fail or complete.
    final List<String> reasons = maxStrikesReached 
        ? ["Day End (Completed)", "Failed (Max Reschedules Reached)"]
        : ["Day End (Completed)", "Shop Closed", "Dealer Unavailable", "Reschedule / Other"];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final bool isReschedule = selectedReason != '' && 
                                      selectedReason != "Day End (Completed)" && 
                                      selectedReason != "Failed (Max Reschedules Reached)";

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24, left: 24, right: 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "End Visit",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _textDark),
                      ),
                      if (currentStrikes > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: maxStrikesReached ? _dangerRed.withOpacity(0.1) : _pendingOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Strike $currentStrikes of 3",
                            style: TextStyle(
                              color: maxStrikesReached ? _dangerRed : _pendingOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
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
                      fontWeight: maxStrikesReached ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // REASON CHIPS
                  Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    children: reasons.map((reason) {
                      final bool isSelected = selectedReason == reason;
                      Color chipColor = _pendingOrange;
                      if (reason == "Day End (Completed)") chipColor = _accentGreen;
                      if (reason == "Failed (Max Reschedules Reached)") chipColor = _dangerRed;

                      return ChoiceChip(
                        label: Text(reason),
                        selected: isSelected,
                        selectedColor: chipColor.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? chipColor : _textGrey,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          setModalState(() => selectedReason = selected ? reason : '');
                        },
                      );
                    }).toList(),
                  ),

                  // TEXT FIELD FOR RESCHEDULE
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    child: isReschedule
                        ? Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: TextField(
                              controller: remarkController,
                              maxLines: 2,
                              decoration: InputDecoration(
                                hintText: "Add remarks for tomorrow's visit...",
                                filled: true,
                                fillColor: _bgLight,
                                border: InputBorder.none,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: _cardNavy),
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 32),

                  // SUBMIT BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedReason == "Failed (Max Reschedules Reached)" ? _dangerRed : _cardNavy,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: selectedReason.isEmpty ? null : () {
                        Navigator.pop(context);
                        _executeEndTaskLogic(task, selectedReason, remarkController.text, currentStrikes);
                      },
                      child: Text(
                        selectedReason == "Failed (Max Reschedules Reached)" 
                            ? "MARK AS FAILED"
                            : (isReschedule ? "RESCHEDULE TO TOMORROW" : "COMPLETE VISIT"),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

Future<void> _executeEndTaskLogic(DailyTask task, String reason, String remarks, int currentStrikes) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    if (reason == "Day End (Completed)") {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text("Completing task...")));
      try {
        await _apiService.updateDailyTaskStatus(task.id!, "Completed");
        _refreshTasks();
      } catch (e) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
      return;
    }

    if (reason == "Failed (Max Reschedules Reached)") {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text("Marking task as Failed..."), backgroundColor: Colors.red));
      try {
        await _apiService.updateDailyTaskStatus(task.id!, "Failed");
        _refreshTasks();
      } catch (e) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
      return;
    }

    // --- 🚀 FIXED RESCHEDULE LOGIC ---
    scaffoldMessenger.showSnackBar(const SnackBar(content: Text("Rescheduling to tomorrow...")));
    try {
      final int newStrikeCount = currentStrikes + 1;
      
      // Clean previous tags from the objective string if they exist
      String cleanObjective = task.objective ?? 'No objective set';
      cleanObjective = cleanObjective.replaceAll(RegExp(r'\[Rescheduled x\d\] '), '');
      
      // Prepend the new strike count
      final String combinedObjective = "[Rescheduled x$newStrikeCount] Reason: $reason ${remarks.isNotEmpty ? '($remarks)' : ''} | $cleanObjective";
      
      final tomorrowTask = DailyTask(
        id: null, // 🛡️ Safest: Let the backend generate the UUID
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
        taskDate: DateTime.now().add(const Duration(days: 1)), // 🚀 MOVED TO TOMORROW
        status: "Assigned", // 🚀 MUST BE A VALID DB STATUS
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 1️⃣ Run sequentially instead of Future.wait()
      // First, successfully create the duplicate task for tomorrow.
      await _apiService.createDailyTask(tomorrowTask);

      // 2️⃣ ONLY if the new task is created, mark today's task as "Failed".
      // We use "Failed" because it is a valid Zod/DB schema enum, and the salesman 
      // technically "failed" to complete it today.
      await _apiService.updateDailyTaskStatus(task.id!, "Failed");

      // 3️⃣ Refresh the UI so the failed task disappears from the active list.
      _refreshTasks();
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text("Failed to reschedule: $e"), backgroundColor: Colors.red));
    }
  }
  // ===========================================================================

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
        toolbarHeight: 80,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isToday ? "Today's Plan" : "Visits",
              style: TextStyle(
                color: _textDark,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              "$displayDay, $displayDate",
              style: TextStyle(
                color: _textGrey,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          const SizedBox(height: 16),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _refreshTasks(),
              color: _cardNavy,
              child: FutureBuilder<List<DailyTask>>(
                future: _tasksFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: _cardNavy),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          "Data Error:\n${snapshot.error}",
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final allTasks = snapshot.data ?? [];

                  // Hide tasks that are completed, failed, or rescheduled
                  final tasks = allTasks
                      .where((t) => 
                        t.status.toLowerCase() != 'completed' && 
                        t.status.toLowerCase() != 'rescheduled' &&
                        t.status.toLowerCase() != 'failed'
                      ).toList();

                  if (tasks.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (_, index) {
                      return _buildTaskCard(tasks[index]);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 14,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final date = DateTime.now()
              .subtract(const Duration(days: 1))
              .add(Duration(days: index));
          final isSelected = DateUtils.isSameDay(date, _selectedDate);
          final isToday = DateUtils.isSameDay(date, DateTime.now());

          return GestureDetector(
            onTap: () => _onDateSelected(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 64,
              decoration: BoxDecoration(
                color: isSelected ? _cardNavy : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: isToday && !isSelected
                    ? Border.all(color: _cardNavy.withOpacity(0.2), width: 1.5)
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _cardNavy.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.05),
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
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white.withOpacity(0.6)
                          : _textGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d').format(date),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : _textDark,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskCard(DailyTask task) {
    final isStarted = task.status.toLowerCase() == 'started' || task.status.toLowerCase() == 'in progress';

    Color statusColor = _cardNavy;
    if (isStarted) statusColor = Colors.blue;
    if (task.status.toLowerCase() == 'assigned') statusColor = _pendingOrange;

    return Slidable(
      startActionPane: ActionPane(
        motion: const StretchMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _handleStartTask(task),
            backgroundColor: _accentGreen,
            foregroundColor: Colors.white,
            icon: Icons.play_arrow_rounded,
            label: 'START',
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(20),
            ),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _showEndTaskBottomSheet(task),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.stop_circle_rounded,
            label: 'END',
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(20),
            ),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () => _showTaskDetailsBottomSheet(task),
        child: Container(
          decoration: BoxDecoration(
            color: _surfaceWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 50,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              task.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (task.visitType != null &&
                              task.visitType!.isNotEmpty)
                            Text(
                              task.visitType!.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _textGrey,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        task.dealerNameSnapshot ?? "Unnamed Dealer",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (task.objective != null && task.objective!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            task.objective!,
                            style: TextStyle(fontSize: 13, color: _textGrey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: _textGrey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              task.area != null && task.zone != null
                                  ? "${task.area}, ${task.zone}"
                                  : (task.dealerId != null
                                        ? "Dealer ID: ${task.dealerId}"
                                        : "Location pending"),
                              style: TextStyle(fontSize: 12, color: _textGrey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: _textGrey.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTaskDetailsBottomSheet(DailyTask task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
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
              const SizedBox(height: 24),

              Text(
                task.dealerNameSnapshot ?? "Unnamed Dealer",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _cardNavy.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      task.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _cardNavy,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (task.week != null)
                    Text(
                      "Week: ${task.week}",
                      style: TextStyle(
                        fontSize: 12,
                        color: _textGrey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              Text(
                "Visit Details",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 16),

              _buildDetailRow(
                Icons.description_outlined,
                "Objective",
                task.objective ?? "No objective set",
              ),
              _buildDetailRow(
                Icons.phone_outlined,
                "Phone",
                task.dealerMobile ?? "Not available",
              ),
              _buildDetailRow(
                Icons.map_outlined,
                "Zone",
                task.zone ?? "Pending",
              ),
              _buildDetailRow(
                Icons.place_outlined,
                "Area",
                task.area ?? "Pending",
              ),
              if (task.route != null && task.route!.isNotEmpty)
                _buildDetailRow(
                  Icons.directions_outlined,
                  "Route",
                  task.route!,
                ),

              const SizedBox(height: 32),
            ],
          ),
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
                Text(title, style: TextStyle(fontSize: 12, color: _textGrey)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: _textDark,
                    fontWeight: FontWeight.w500,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.assignment_add,
              size: 48,
              color: _cardNavy.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No Visits Planned",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Select another date or add a visit.",
            style: TextStyle(fontSize: 14, color: _textGrey),
          ),
        ],
      ),
    );
  }
}