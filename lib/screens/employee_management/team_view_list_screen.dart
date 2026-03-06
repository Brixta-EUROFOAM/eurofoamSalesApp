// lib/screens/employee_management/team_view_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/models/team_members_model.dart';
import 'package:salesmanapp/screens/employee_management/member_activity_logs.dart';

class TeamViewListScreen extends StatefulWidget {
  final int seniorId;
  const TeamViewListScreen({super.key, required this.seniorId});

  @override
  State<TeamViewListScreen> createState() => _TeamViewListScreenState();
}

class _TeamViewListScreenState extends State<TeamViewListScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<TeamMember>> _teamFuture;

  // --- THEME ---
  static const Color _bgLight = Color(0xFFF8FAFC);
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
          "My Team",
          style: TextStyle(fontWeight: FontWeight.w900, color: _cardNavy),
        ),
        backgroundColor: _bgLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: _cardNavy),
      ),
      body: FutureBuilder<List<TeamMember>>(
        future: _teamFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _cardNavy),
            );
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final team = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _loadTeam(),
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: team.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _buildMemberCard(team[index], index),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMemberCard(TeamMember member, int index) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MemberActivityLogsScreen(member: member),
        ),
      ),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: _cardNavy.withOpacity(0.1),
              child: Text(
                member.firstName[0],
                style: const TextStyle(
                  color: _cardNavy,
                  fontWeight: FontWeight.bold,
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _textDark,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    member.role.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: _textGrey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // 📍 Zone + Area pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFEFF), // light blue
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: Color(0xFF0284C7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${member.region ?? "N/A"} • ${member.area ?? "N/A"}",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0369A1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: _textGrey),
          ],
        ),
      ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.1),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_off_outlined,
            size: 64,
            color: _textGrey.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            "No Team Members Found",
            style: TextStyle(fontWeight: FontWeight.bold, color: _textGrey),
          ),
        ],
      ),
    );
  }
}
