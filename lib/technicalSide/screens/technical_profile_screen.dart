// lib/technicalSide/screens/technical_profile_screen.dart
import 'dart:async';
import 'package:salesmanapp/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/api/auth_service.dart';
import 'package:intl/intl.dart'; 
import 'package:provider/provider.dart';
import 'package:salesmanapp/widgets/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart'; // ✅ Added for launching the form

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

  // --- FINTECH THEME PALETTE ---
  final Color _bgLight       = const Color(0xFFF3F4F6); // Corporate Light Grey
  final Color _cardNavy      = const Color(0xFF0F172A); // Deep Navy
  final Color _textDark      = const Color(0xFF111827); // Almost Black
  final Color _textGrey      = const Color(0xFF6B7280); // Subtitles
  final Color _surfaceWhite  = Colors.white;
  final Color _dangerRed     = const Color(0xFFEF4444);

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
        Future.value([]), // 1. Active Sites Placeholder
        _apiService.fetchTvrsForUser(uid, startDate: todayString, endDate: todayString), // 2. TVRs
        _apiService.fetchPjpsForUser(uid, status: 'APPROVED', startDate: todayString, endDate: todayString), // 3. PJPs
        _apiService.fetchDailyTasksForUser(uid, status: 'Completed'), // 4. Tasks
      ]);

      final tvrsList = (results[1] is List) ? results[1] as List : [];
      final pjpList = (results[2] is List) ? results[2] as List : [];
      final tasksList = (results[3] is List) ? results[3] as List : [];

      return TechnicalProfileStats(
        activeSites: 12, // Dummy data for now
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

  // ✅ Function to open the Google Form
  Future<void> _launchDeleteAccountUrl() async {
    final Uri url = Uri.parse('https://docs.google.com/forms/d/e/1FAIpQLSdq-4YaYoEckyD7H_fYl_L-ordLQIdC7RSiqmQd9w054G2Zkg/viewform?usp=publish-editor');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch url');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the form. Please contact support.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: _bgLight,
      // --- CLEAN APP BAR ---
      appBar: AppBar(
        backgroundColor: _bgLight,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Clean look
        leadingWidth: 64,
        title: Text(
          'PROFILE',
          style: TextStyle(
            color: _textDark,
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
            return Center(child: CircularProgressIndicator(color: _cardNavy));
          }
          
          final stats = snapshot.data ?? TechnicalProfileStats(
            activeSites: 0, pendingTvrs: 0, upcomingVisits: 0, completedTasks: 0
          );

          return RefreshIndicator(
            onRefresh: _refreshStats,
            color: _cardNavy, 
            backgroundColor: Colors.white, 
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 120.0),
              children: [
                
                // --- 1. Clean Profile Header ---
                _buildFintechProfileHeader(
                  initials: getInitials(),
                  displayName: widget.employee.displayName,
                  email: widget.employee.email ?? 'No email',
                  role: "Technical Sales Employee",
                ),

                const SizedBox(height: 32),

                // --- 2. OVERVIEW STATS (White Cards) ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Overview Stats",
                      style: TextStyle(color: _textDark, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Icon(Icons.bar_chart, color: _textGrey, size: 20),
                  ],
                ),
                const SizedBox(height: 16),
                
                Column(
                  children: [
                    Row(
                      children: [
                        _buildStatCard(
                          title: "Active Sites",
                          value: stats.activeSites.toString(),
                          icon: Icons.apartment,
                          iconColor: Colors.blueAccent,
                          iconBg: const Color(0xFFEFF6FF),
                        ),
                        const SizedBox(width: 16),
                        _buildStatCard(
                          title: "Visits Today",
                          value: stats.upcomingVisits.toString(),
                          icon: Icons.map,
                          iconColor: Colors.orange,
                          iconBg: const Color(0xFFFFF7ED),
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
                          iconBg: const Color(0xFFFAF5FF),
                        ),
                        const SizedBox(width: 16),
                        _buildStatCard(
                          title: "Tasks Done",
                          value: stats.completedTasks.toString(),
                          icon: Icons.check_circle,
                          iconColor: Colors.green,
                          iconBg: const Color(0xFFF0FDF4),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // --- 3. Settings Section ---
                Text(
                  "App Settings",
                  style: TextStyle(color: _textDark, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: _surfaceWhite,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                       BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Theme Preference', 
                        style: TextStyle(color: _textGrey, fontWeight: FontWeight.w600, fontSize: 14)
                      ),
                      const SizedBox(height: 16),
                      
                      // Segmented Button Styled for Light Theme
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<ThemeMode>(
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                              if (states.contains(MaterialState.selected)) {
                                return _cardNavy;
                              }
                              return _bgLight;
                            }),
                            foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                              if (states.contains(MaterialState.selected)) {
                                return Colors.white;
                              }
                              return _textGrey;
                            }),
                            side: MaterialStateProperty.all(BorderSide.none),
                            shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 12)),
                          ),
                          segments: const [
                            ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_outlined, size: 18)),
                            ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_outlined, size: 18)),
                            ButtonSegment(value: ThemeMode.system, label: Text('Auto'), icon: Icon(Icons.phone_android_outlined, size: 18)),
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
                
                const SizedBox(height: 32),

                // --- 4. ✅ Account Actions (Dropdown) ---
                Text(
                  "Account Management",
                  style: TextStyle(color: _textDark, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                Container(
                  decoration: BoxDecoration(
                    color: _surfaceWhite,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                       BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))
                    ],
                  ),
                  child: Theme(
                    // Remove internal divider line
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      leading: Icon(Icons.shield_outlined, color: _cardNavy),
                      title: Text(
                        'Privacy & Security', 
                        style: TextStyle(color: _textDark, fontWeight: FontWeight.w600, fontSize: 15)
                      ),
                      childrenPadding: const EdgeInsets.only(bottom: 12),
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                          leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          title: const Text(
                            "Request Account Deletion",
                            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          trailing: const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
                          onTap: _launchDeleteAccountUrl,
                        ),
                      ],
                    ),
                  ),
                ),

                // --- 5. Logout Button ---
                const SizedBox(height: 32),
                _LogoutButton(color: _dangerRed),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildFintechProfileHeader({
    required String initials,
    required String displayName,
    required String email,
    required String role,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8))
            ]
          ),
          child: CircleAvatar(
            radius: 45,
            backgroundColor: _cardNavy,
            child: Text(
              initials,
              style: const TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          displayName,
          style: TextStyle(
            fontSize: 22, 
            fontWeight: FontWeight.bold, 
            color: _textDark,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(email, style: TextStyle(color: _textGrey, fontSize: 14)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: _cardNavy.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            role.toUpperCase(), 
            style: TextStyle(
              color: _cardNavy, 
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.5
            )
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surfaceWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold, 
                color: _textDark
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13, 
                fontWeight: FontWeight.w500, 
                color: _textGrey
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final Color color;
  const _LogoutButton({required this.color});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.logout_rounded, size: 20),
      label: const Text(
        'Log Out',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      onPressed: () async {
        await AuthService().logout();
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/selector', (route) => false);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: color, // Red Text
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withOpacity(0.3), width: 1),
        ),
        padding: const EdgeInsets.symmetric(vertical: 18),
        shadowColor: Colors.transparent,
      ),
    );
  }
}