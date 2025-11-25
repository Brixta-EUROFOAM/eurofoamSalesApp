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

  // --- THEME CONSTANTS ---
  static const Color scaffoldBg     = Color(0xFF020617); // Navy
  static const Color surfaceDark    = Color(0xFF1E293B); // Slate 800
  static const Color accentYellow   = Color(0xFFFFA000); // Amber
  static const Color accentColor    = _ProfileHeaderCard.surfaceDark;


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
      final List<dynamic> results = await Future.wait([
        Future.value([]), // 1. Active Sites
        _apiService.fetchTvrsForUser(uid, startDate: todayString, endDate: todayString), // 2. TVRs
        _apiService.fetchPjpsForUser(uid, status: 'APPROVED', startDate: todayString, endDate: todayString), // 3. PJPs
        _apiService.fetchDailyTasksForUser(uid, status: 'Completed'), // 4. Tasks
      ]);

      final tvrsList = (results[1] is List) ? results[1] as List : [];
      final pjpList = (results[2] is List) ? results[2] as List : [];
      final tasksList = (results[3] is List) ? results[3] as List : [];

      return TechnicalProfileStats(
        activeSites: 12, 
        pendingTvrs: tvrsList.length, 
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
    
    return Scaffold(
      backgroundColor: scaffoldBg,
      // --- APP BAR (Consistent with others) ---
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
          child: InkWell(
            onTap: () => Scaffold.of(context).openDrawer(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
            ),
          ),
        ),
        title: const Text(
          'PROFILE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: FutureBuilder<TechnicalProfileStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
            return const Center(child: CircularProgressIndicator(color: accentYellow));
          }
          
          final stats = snapshot.data ?? TechnicalProfileStats(
            activeSites: 0, pendingTvrs: 0, upcomingVisits: 0, completedTasks: 0
          );

          return RefreshIndicator(
            onRefresh: _refreshStats,
            color: accentColor, // Orange spinner
            backgroundColor: surfaceDark, // Dark bg for spinner
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 120.0),
              children: [
                
                // --- 1. Profile Header Card ---
                _ProfileHeaderCard(
                  initials: getInitials(),
                  displayName: widget.employee.displayName,
                  email: widget.employee.email ?? 'No email',
                  role: "Technical Sales Employee",
                ),

                // --- 2. OVERVIEW STATS ---
                const _SectionHeader('OVERVIEW STATS'),
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
                          iconColor: accentYellow,
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
                          iconColor: Colors.purpleAccent,
                        ),
                        const SizedBox(width: 16),
                        _buildStatCard(
                          title: "Tasks Done",
                          value: stats.completedTasks.toString(),
                          icon: Icons.check_circle,
                          iconColor: Colors.greenAccent,
                        ),
                      ],
                    ),
                  ],
                ),

                // --- 3. Settings Section ---
                const _SectionHeader('APP SETTINGS'),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: surfaceDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Theme Preference', 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                      ),
                      const SizedBox(height: 12),
                      
                      // Custom Styled Segmented Button
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<ThemeMode>(
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                              if (states.contains(MaterialState.selected)) {
                                return accentYellow;
                              }
                              return Colors.white.withOpacity(0.05);
                            }),
                            foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                              if (states.contains(MaterialState.selected)) {
                                return Colors.black;
                              }
                              return Colors.white70;
                            }),
                            side: MaterialStateProperty.all(BorderSide(color: Colors.white.withOpacity(0.1))),
                          ),
                          segments: const [
                            ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_outlined, size: 16)),
                            ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_outlined, size: 16)),
                            ButtonSegment(value: ThemeMode.system, label: Text('Auto'), icon: Icon(Icons.phone_android_outlined, size: 16)),
                          ],
                          selected: { themeProvider.themeMode },
                          onSelectionChanged: (Set<ThemeMode> newSelection) {
                            themeProvider.setThemeMode(newSelection.first);
                          },
                        ),
                      ),
                    ],
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
          color: surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))
          ],
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
                  style: const TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.w900, 
                    color: Colors.white
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13, 
                fontWeight: FontWeight.w600, 
                color: Colors.white54
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- REUSED WIDGETS (THEMED) ---

class _ProfileHeaderCard extends StatelessWidget {
  final String initials;
  final String displayName;
  final String email;
  final String role;

  // Constants
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color brandBlue = Color(0xFF0B4AA8);
  static const Color accentYellow = Color(0xFFFFA000);

  const _ProfileHeaderCard({
    required this.initials,
    required this.displayName,
    required this.email,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: brandBlue,
              child: Text(
                initials,
                style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold, 
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(email, style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: accentYellow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.engineering, color: Colors.black, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    role.toUpperCase(), 
                    style: const TextStyle(
                      color: Colors.black, 
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    )
                  ),
                ],
              ),
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
        style: const TextStyle(
          color: Colors.white38, 
          fontWeight: FontWeight.w900, 
          letterSpacing: 1.2, 
          fontSize: 12
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  static const Color dangerRed = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.logout),
      label: const Text(
        'LOG OUT',
        style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0),
      ),
      onPressed: () async {
        await AuthService().logout();
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/selector', (route) => false);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: dangerRed.withOpacity(0.1), // Transparent Red
        foregroundColor: dangerRed, // Red Text
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: dangerRed, width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }
}