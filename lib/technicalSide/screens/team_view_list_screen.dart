// lib/technicalSide/screens/team_view_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/salesSide/models/team_members_model.dart';

class TechnicalTeamViewListScreen extends StatefulWidget {
  final int seniorId;
  const TechnicalTeamViewListScreen({super.key, required this.seniorId});

  @override
  State<TechnicalTeamViewListScreen> createState() => _TechnicalTeamViewListScreenState();
}

class _TechnicalTeamViewListScreenState extends State<TechnicalTeamViewListScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<TeamMember>> _teamFuture;

  // --- PREMIUM TECHNICAL THEME ---
  static const Color _bgLight = Color(0xFFF8FAFC);
  static const Color _accentBlue = Color(0xFF2563EB);
  static const Color _cardNavy = Color(0xFF0F172A);
  static const Color _textDark = Color(0xFF1E293B);
  static const Color _textGrey = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _loadTeam();
  }

  void _loadTeam() {
    setState(() {
      _teamFuture = _apiService.fetchRecursiveTeam(widget.seniorId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        title: const Text(
          "Technical Team",
          style: TextStyle(fontWeight: FontWeight.w900, color: _cardNavy, letterSpacing: -0.5),
        ),
        backgroundColor: _bgLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: _cardNavy),
      ),
      body: FutureBuilder<List<TeamMember>>(
        future: _teamFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _accentBlue));
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final team = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _loadTeam(),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: team.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildTechnicalMemberCard(team[index], index),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTechnicalMemberCard(TeamMember member, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _cardNavy.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          // SQUIRCLE ICON FOR TECH SIDE
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: _accentBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                member.firstName[0],
                style: const TextStyle(color: _accentBlue, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _textDark),
                ),
                const SizedBox(height: 2),
                Text(
                  member.role.replaceAll('-', ' ').toUpperCase(),
                  style: const TextStyle(fontSize: 10, color: _accentBlue, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 12, color: _textGrey),
                    const SizedBox(width: 4),
                    Text(
                      "${member.area ?? 'No Area'} • ${member.region ?? 'No Region'}",
                      style: const TextStyle(fontSize: 12, color: _textGrey, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: (index * 40).ms).fadeIn(duration: 400.ms).slideX(begin: 0.05, curve: Curves.easeOut);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [
              BoxShadow(color: _cardNavy.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
            ]),
            child: const Icon(Icons.engineering_outlined, size: 48, color: _textGrey),
          ),
          const SizedBox(height: 24),
          const Text(
            "No Technical Team Members",
            style: TextStyle(fontWeight: FontWeight.w900, color: _textDark, fontSize: 18),
          ),
          Text(
            "Recursive hierarchy returned zero results.",
            style: TextStyle(color: _textGrey, fontSize: 14),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }
}