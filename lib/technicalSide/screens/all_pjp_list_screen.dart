// lib/technicalSide/screens/all_pjp_list_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  String _selectedTab = 'In Progress';
  List<Pjp> _allPjps = [];
  List<Pjp> _filtered = [];

  late Future<void> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadPjps();
  }

  Future<void> _loadPjps() async {
    final data = await _apiService.fetchPjpsForUser(widget.userId);
    _allPjps = data;
    _applyFilter();
  }

  void _applyFilter() {
    if (_selectedTab == 'Completed') {
      _filtered = _allPjps.where((p) {
        final status = p.status.trim().toLowerCase();
        return status == 'completed';
      }).toList();
    } else {
      _filtered = _allPjps.where((p) {
        final status = p.status.trim().toLowerCase();
        return status != 'completed';
      }).toList();
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text("Journey Plans"),
        backgroundColor: Colors.white,
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

                if (_filtered.isEmpty) {
                  return const Center(child: Text("No PJP Found"));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _buildCard(_filtered[i]),
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
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: ['In Progress', 'Completed']
            .map(
              (t) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(t),
                  selected: _selectedTab == t,
                  onSelected: (_) {
                    _selectedTab = t;
                    _applyFilter();
                  },
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildCard(Pjp p) {
    final date = DateFormat('dd MMM').format(p.planDate);
    final color = p.status == 'completed' ? Colors.green : Colors.orange;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(width: 6, color: color),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.areaToBeVisited,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.route ?? '-',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}