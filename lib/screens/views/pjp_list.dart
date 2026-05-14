// lib/screens/views/pjp_list.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../api/api_service.dart';
import '../../models/pjp_model.dart';

// Import the form so they can add a new PJP directly from this screen
import '../forms/add_PJP_form.dart'; 

class PjpListScreen extends StatefulWidget {
  const PjpListScreen({Key? key}) : super(key: key);

  @override
  State<PjpListScreen> createState() => _PjpListScreenState();
}

class _PjpListScreenState extends State<PjpListScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<PjpModel>> _pjpFuture;

  String _selectedTab = 'In Progress';
  List<PjpModel> _allTasks = [];
  List<PjpModel> _filteredTasks = [];

  // --- 🎨 PREMIUM THEME PALETTE ---
  static const Color _bgLight = Color(0xFFF8FAFC);
  static const Color _surfaceWhite = Colors.white;
  static const Color _textDark = Color(0xFF1E293B);
  static const Color _textGrey = Color(0xFF64748B);
  static const Color _cardNavy = Color(0xFF0F172A);

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() {
    setState(() {
      _pjpFuture = _apiService.getJourneyPlans().then((data) {
        _allTasks = data;
        _applyFilter();
        return data;
      }).catchError((e) {
        debugPrint("Error loading PJPs: $e");
        return <PjpModel>[];
      });
    });
  }

  Future<void> _handleRefresh() async {
    _loadTasks();
    await _pjpFuture;
  }

  void _applyFilter() {
    if (_selectedTab == 'Completed') {
      _filteredTasks = _allTasks.where((t) => t.status.toLowerCase() == 'completed').toList();
    } else {
      _filteredTasks = _allTasks.where((t) => t.status.toLowerCase() != 'completed').toList();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        title: const Text(
          "Journey Plans",
          style: TextStyle(
            color: _cardNavy,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, curve: Curves.easeOut),
        backgroundColor: _bgLight,
        iconTheme: const IconThemeData(color: _cardNavy),
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 70,
      ),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: _cardNavy,
              backgroundColor: Colors.white,
              child: FutureBuilder<List<PjpModel>>(
                future: _pjpFuture,
                builder: (_, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: _cardNavy));
                  }

                  if (_filteredTasks.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 100), // Extra bottom padding for FAB
                    itemCount: _filteredTasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (_, i) {
                      return _buildCard(_filteredTasks[i])
                          .animate(delay: (i * 40).ms)
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.1, curve: Curves.easeOut);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      // Add a Floating Action Button to quickly plan a new PJP
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPjpFormScreen()),
          );
          if (result == true) {
            _handleRefresh(); // Refresh list if a new plan was submitted
          }
        },
        backgroundColor: _cardNavy,
        icon: const Icon(Icons.abc_rounded, color: Colors.white),
        label: const Text("New Plan", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
      ).animate().scale(delay: 600.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: _bgLight,
      padding: const EdgeInsets.only(left: 20, bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ['In Progress', 'Completed'].map((t) {
            final isSelected = _selectedTab == t;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ChoiceChip(
                label: Text(
                  t,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : _textGrey,
                  ),
                ),
                selected: isSelected,
                selectedColor: _cardNavy,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                side: BorderSide(color: isSelected ? _cardNavy : Colors.grey.shade300),
                onSelected: (selected) {
                  if (selected) {
                    _selectedTab = t;
                    _applyFilter();
                  }
                },
              ),
            );
          }).toList(),
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
                    BoxShadow(color: _cardNavy.withOpacity(0.06), blurRadius: 30, offset: const Offset(0, 15)),
                  ],
                ),
                child: Icon(Icons.map_outlined, size: 48, color: _textGrey.withOpacity(0.5)),
              ).animate().scale(delay: 100.ms, curve: Curves.easeOutBack, duration: 600.ms),
              const SizedBox(height: 32),
              Text(
                "No $_selectedTab Plans",
                style: const TextStyle(color: _textDark, fontWeight: FontWeight.w900, fontSize: 20),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.5, curve: Curves.easeOutCubic),
              const SizedBox(height: 8),
              const Text(
                "Tap 'New Plan' to schedule visits.",
                style: TextStyle(color: _textGrey, fontSize: 15),
              ).animate().fadeIn(delay: 300.ms),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard(PjpModel t) {
    final dateStr = DateFormat('dd MMM yyyy').format(t.planDate);
    final isCompleted = t.status.toLowerCase() == 'completed';
    final color = isCompleted ? Colors.green : Colors.orange;
    final icon = isCompleted ? Icons.check_circle_rounded : Icons.pending_actions_rounded;

    // Use the backend-joined dealer name, or fallback to the manual area text
    final String displayName = t.visitDealerName ?? t.areaToBeVisited;

    return Container(
      decoration: BoxDecoration(
        color: _surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: _cardNavy.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left color indicator bar
            Container(
              width: 8,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row: Status & Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 12, color: color),
                              const SizedBox(width: 4),
                              Text(
                                t.status.toUpperCase(),
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          dateStr,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textGrey.withOpacity(0.8)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Main Title
                    Text(
                      displayName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _textDark),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    
                    // Description or Subtitle
                    Text(
                      t.description != null && t.description!.isNotEmpty 
                        ? t.description! 
                        : "No specific objective provided.",
                      style: TextStyle(fontSize: 14, color: _textGrey.withOpacity(0.9), height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Footer details (e.g., if it's a registered dealer)
                    if (t.dealerId != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.storefront_rounded, size: 14, color: _textGrey),
                          const SizedBox(width: 4),
                          Text(
                            "Network Dealer ID: ${t.dealerId}",
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textGrey),
                          ),
                        ],
                      ),
                    ],
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