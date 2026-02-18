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
    if (task.status.toLowerCase() == 'completed') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Task already completed")));
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
      'pjpId': task.pjpId,
      // Pass distinct dealer keys
      'dealerId': task.relatedDealerId, // String? (UUID)
      'verifiedDealerId': task.relatedVerifiedDealerId, // int?

      'displayName': task.siteName ?? task.dealerName ?? "Site Visit",
      'description': task.description,
      'coordinates': null,
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
        // actions: [
        //    Padding(
        //     padding: const EdgeInsets.only(right: 20.0),
        //     child: InkWell(
        //       onTap: () {
        //          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Create Task Feature Coming Soon")));
        //       },
        //       borderRadius: BorderRadius.circular(12),
        //       child: Container(
        //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        //         decoration: BoxDecoration(
        //           color: _cardNavy,
        //           borderRadius: BorderRadius.circular(16),
        //           boxShadow: [
        //             BoxShadow(color: _cardNavy.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
        //           ]
        //         ),
        //         child: const Row(
        //           children: [
        //             Icon(Icons.add, color: Colors.white, size: 18),
        //             SizedBox(width: 4),
        //             Text(
        //               "Add Visit",
        //               style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        //             ),
        //           ],
        //         ),
        //       ),
        //     ),
        //   )
        // ],
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

                  final allTasks = snapshot.data ?? [];

                  final tasks = allTasks.where((t) => t.status.toLowerCase() != 'completed').toList();

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
    final isCompleted = task.status.toLowerCase() == 'completed';
    final isStarted =
        task.status.toLowerCase() == 'started' ||
        task.status.toLowerCase() == 'in progress';

    Future<void> _handleEndTask(DailyTask task) async {
      if (task.id == null || task.id!.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Invalid task ID")));
        return;
      }

      try {
        await _apiService.updateDailyTaskStatus(task.id!, "Completed");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Task marked as completed")),
        );

        _refreshTasks();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to end task: $e")));
      }
    }

    Color statusColor = _cardNavy;
    if (isCompleted) statusColor = _accentGreen;
    if (isStarted) statusColor = Colors.blue;
    if (task.status.toLowerCase() == 'assigned') statusColor = _pendingOrange;

    return Slidable(
      enabled: !isCompleted,
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
          // ✅ END VISIT
          SlidableAction(
            onPressed: (_) => _handleEndTask(task),
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
                        if (task.visitType.isNotEmpty)
                          Text(
                            task.visitType.toUpperCase(),
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
                      task.siteName ?? task.dealerName ?? "Unnamed Visit",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? _textGrey : _textDark,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (task.description != null &&
                        task.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          task.description!,
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
                            task.relatedDealerId != null
                                ? "Dealer ID: ${task.relatedDealerId}"
                                : "Location pending",
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
              if (!isCompleted)
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
