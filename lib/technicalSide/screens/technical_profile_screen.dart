// lib/technicalSide/screens/technical_profile_screen.dart
import 'dart:async';
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:assetarchiverflutter/api/auth_service.dart';
import 'package:intl/intl.dart'; 
import 'package:provider/provider.dart';
import 'package:assetarchiverflutter/widgets/theme_provider.dart';

// --- Helper Data Class for Stats ---
class TechnicalProfileStats {
  final int activeSites;
  final int pendingTvrs;
  final int upcomingVisits;
  final int completedTasks;

  TechnicalProfileStats({
    required this.activeSites,
    required this.pendingTvrs,
    required this.upcomingVisits,
    required this.completedTasks,
  });
}

class TechnicalProfileScreen extends StatefulWidget {
  final Employee employee;
  const TechnicalProfileScreen({super.key, required this.employee});

  @override
  State<TechnicalProfileScreen> createState() => _TechnicalProfileScreenState();
}

class _TechnicalProfileScreenState extends State<TechnicalProfileScreen> {
  final ApiService _apiService = ApiService();
  late Future<TechnicalProfileStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _fetchProfileStats();
  }
  
  Future<void> _refreshStats() async {
    if (mounted) {
      setState(() {
        _statsFuture = _fetchProfileStats();
      });
    }
    await _statsFuture;
  }

  Future<TechnicalProfileStats> _fetchProfileStats() async {
    final uid = int.tryParse(widget.employee.id);
    if (uid == null) throw Exception('Invalid Employee ID');

    final today = DateTime.now();
    final todayString = DateFormat('yyyy-MM-dd').format(today);

    try {
      // PARALLEL FETCHING
      final List<dynamic> results = await Future.wait([
        // 1. Active Sites (Placeholder until API is ready)
        Future.value([]), 
        
        // 2. TVRs (Technical Visit Reports) - Used to count reports submitted today
        _apiService.fetchTvrsForUser(uid, startDate: todayString, endDate: todayString),
        
        // 3. PJPs (Visits Today) - Relevant for TSEs too
        _apiService.fetchPjpsForUser(uid, status: 'APPROVED', startDate: todayString, endDate: todayString),
        
        // 4. Daily Tasks (Completed) - Relevant for TSEs too
        _apiService.fetchDailyTasksForUser(uid, status: 'Completed'),
      ]);

      // Safe casting
      final tvrsList = (results[1] is List) ? results[1] as List : [];
      final pjpList = (results[2] is List) ? results[2] as List : [];
      final tasksList = (results[3] is List) ? results[3] as List : [];

      return TechnicalProfileStats(
        activeSites: 12, // Placeholder value
        pendingTvrs: tvrsList.length, // Showing "TVRs Done Today"
        upcomingVisits: pjpList.length,
        completedTasks: tasksList.length,
      );
    } catch (e) {
      return TechnicalProfileStats(activeSites: 0, pendingTvrs: 0, upcomingVisits: 0, completedTasks: 0);
    }
  }

  String getInitials() {
    String firstNameInitial = widget.employee.firstName?.isNotEmpty == true
        ? widget.employee.firstName![0]
        : '';
    String lastNameInitial = widget.employee.lastName?.isNotEmpty == true
        ? widget.employee.lastName![0]
        : '';
    return (firstNameInitial + lastNameInitial).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    
    const primaryColor = Color(0xFF0D47A1); // Dark Blue
    const accentColor = Color(0xFFFFA000);  // Orange

    return SafeArea(
      child: FutureBuilder<TechnicalProfileStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
            return Center(child: CircularProgressIndicator(color: primaryColor));
          }
          
          final stats = snapshot.data ?? TechnicalProfileStats(
            activeSites: 0, pendingTvrs: 0, upcomingVisits: 0, completedTasks: 0
          );

          return RefreshIndicator(
            onRefresh: _refreshStats,
            color: accentColor,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 120.0),
              children: [
                
                // --- 1. Profile Header Card ---
                _ProfileHeaderCard(
                  initials: getInitials(),
                  displayName: widget.employee.displayName,
                  email: widget.employee.email ?? 'No email',
                  // ✅ Corrected Terminology
                  role: "Technical Sales Employee",
                  primaryColor: primaryColor,
                ),

                // --- 2. OVERVIEW STATS (Moved from Dashboard) ---
                const _SectionHeader('Overview Stats'),
                Column(
                  children: [
                    Row(
                      children: [
                        _buildStatCard(
                          title: "Active Sites",
                          value: stats.activeSites.toString(),
                          icon: Icons.apartment,
                          iconColor: Colors.blueAccent,
                        ),
                        const SizedBox(width: 16),
                        _buildStatCard(
                          title: "Visits Today",
                          value: stats.upcomingVisits.toString(),
                          icon: Icons.map,
                          iconColor: Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildStatCard(
                          title: "TVRs Done",
                          value: stats.pendingTvrs.toString(),
                          icon: Icons.assignment_turned_in,
                          iconColor: Colors.purple,
                        ),
                        const SizedBox(width: 16),
                        _buildStatCard(
                          title: "Tasks Done",
                          value: stats.completedTasks.toString(),
                          icon: Icons.check_circle,
                          iconColor: Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),

                // --- 3. Settings Section ---
                const _SectionHeader('App Settings'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Theme Preference', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 12),
                        SegmentedButton<ThemeMode>(
                          segments: const [
                            ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_outlined)),
                            ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_outlined)),
                            ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.phone_android_outlined)),
                          ],
                          selected: { themeProvider.themeMode },
                          onSelectionChanged: (Set<ThemeMode> newSelection) {
                            themeProvider.setThemeMode(newSelection.first);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                // --- 4. Logout Button ---
                const SizedBox(height: 32),
                _LogoutButton(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: iconColor, size: 28),
                Text(
                  value,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

// --- REUSED WIDGETS ---

class _ProfileHeaderCard extends StatelessWidget {
  final String initials;
  final String displayName;
  final String email;
  final String role;
  final Color primaryColor;

  const _ProfileHeaderCard({
    required this.initials,
    required this.displayName,
    required this.email,
    required this.role,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: primaryColor,
              child: Text(
                initials,
                style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              displayName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(email, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 12),
            Chip(
              avatar: const Icon(Icons.engineering, color: Colors.black54, size: 18),
              label: Text(role, style: const TextStyle(color: Colors.black87)),
              backgroundColor: Colors.grey[200],
              side: BorderSide.none,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 24.0, 8.0, 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, letterSpacing: 0.8, fontSize: 12),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.logout),
      label: const Text('LOG OUT'),
      onPressed: () async {
        await AuthService().logout();
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/selector', (route) => false);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red[50],
        foregroundColor: Colors.red,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }
}