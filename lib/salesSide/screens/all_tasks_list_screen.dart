// lib/salesSide/screens/all_tasks_list_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/salesSide/models/daily_task_model.dart';

class AllTasksListScreen extends StatefulWidget {
  final int userId;
  const AllTasksListScreen({super.key, required this.userId});

  @override
  State<AllTasksListScreen> createState() => _AllTasksListScreenState();
}

class _AllTasksListScreenState extends State<AllTasksListScreen> {
  final ApiService _apiService = ApiService();
  String _selectedTab = 'In Progress';
  List<DailyTask> _allTasks = [];
  List<DailyTask> _filteredTasks = [];
  late Future<void> _future;

  final Color _bgLight = const Color(0xFFF5F5F7);
  final Color _surfaceWhite = Colors.white;

  @override
  void initState() {
    super.initState();
    _future = _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final data = await _apiService.fetchDailyTasksForUser(widget.userId);
      if (mounted) {
        setState(() {
          _allTasks = data;
          _applyFilter();
        });
      }
    } catch (e) {
      debugPrint("Error loading PJPs: $e");
    }
  }

  void _applyFilter() {
    if (_selectedTab == 'Completed') {
      _filteredTasks = _allTasks.where((t) => t.status.toLowerCase() == 'completed').toList();
    } else {
      _filteredTasks = _allTasks.where((t) => t.status.toLowerCase() != 'completed').toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        title: const Text("PJPs (Daily Tasks)"),
        backgroundColor: _surfaceWhite,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(
            child: FutureBuilder(
              future: _future,
              builder: (_, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_filteredTasks.isEmpty) {
                  return Center(child: Text("No ${_selectedTab} PJPs", style: TextStyle(color: Colors.grey.shade500)));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredTasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _buildCard(_filteredTasks[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: _surfaceWhite,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: ['In Progress', 'Completed'].map((t) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(t),
            selected: _selectedTab == t,
            onSelected: (selected) {
              if (selected) {
                setState(() { _selectedTab = t; _applyFilter(); });
              }
            },
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildCard(DailyTask t) {
    final dateStr = DateFormat('dd MMM').format(t.taskDate);
    final isCompleted = t.status.toLowerCase() == 'completed';
    final color = isCompleted ? Colors.green : Colors.orange;

    // LOGIC: Show Dealer Name -> Site Name -> Description
    String displayName = "Unknown Visit";
    if (t.dealerNameSnapshot != null && t.dealerNameSnapshot!.isNotEmpty) {
      displayName = t.dealerNameSnapshot!;
    } else {
      displayName = t.visitType ?? 'No Description';
    }

    return Container(
      decoration: BoxDecoration(
        color: _surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)))),
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                          child: Text(t.status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                        ),
                        Text(dateStr, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // CHANGED HERE: Using displayName variable calculated above
                    Text(
                      displayName, 
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), 
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis
                    ),
                    const SizedBox(height: 4),
                    Text("Visit: ${t.visitType}", style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    
                    // Show ID if available just for extra context since name is now main title
                    if (t.dealerId != null)
                       Text("ID: ${t.dealerId}", style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}