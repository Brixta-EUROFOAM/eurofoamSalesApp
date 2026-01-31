// lib/technicalSide/screens/technical_profile_screen.dart
import 'dart:async';
import 'package:salesmanapp/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/api/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:salesmanapp/widgets/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:salesmanapp/models/attendance_model.dart';
import 'package:salesmanapp/technicalSide/tvrwidgets/all_tvr_list_screen.dart';
import 'package:salesmanapp/technicalSide/screens/all_pjp_list_screen.dart';
import 'package:salesmanapp/technicalSide/models/technical_visit_report_model.dart';
import 'package:salesmanapp/models/pjp_model.dart';
import 'package:salesmanapp/models/daily_task_model.dart';
import 'package:salesmanapp/models/leave_application_model.dart';
import 'package:salesmanapp/technicalSide/screens/all_leaves_list_screen.dart';

// local drift db
import 'package:drift_db_viewer/drift_db_viewer.dart';
import 'package:salesmanapp/database/app_database.dart';
import 'package:salesmanapp/core/feature_flags/technical_flags.dart';

// --- Helper Data Class for Stats ---
class TechnicalProfileStats {
  final int tvrsThisMonth;
  final int tvrsTotal;
  final int upcomingVisits;
  final int completedTasks;

  final int totalPjps;
  final int completedPjps;
  final int totalCheckIns;
  final int totalCheckOuts;

  final LeaveApplication? latestLeave;

  TechnicalProfileStats({
    required this.tvrsThisMonth,
    required this.tvrsTotal,
    required this.upcomingVisits,
    required this.completedTasks,
    required this.totalPjps,
    required this.completedPjps,
    required this.totalCheckIns,
    required this.totalCheckOuts,
    this.latestLeave,
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

  // --- 🎨 PREMIUM THEME PALETTE ---
  final Color _bgLight = const Color(0xFFF8FAFC); // Slate 50
  final Color _cardNavy = const Color(0xFF0F172A); // Deep Navy
  final Color _textDark = const Color(0xFF1E293B); // Slate 800
  final Color _textGrey = const Color(0xFF64748B); // Slate 500
  final Color _surfaceWhite = Colors.white;
  final Color _dangerRed = const Color(0xFFEF4444);

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
    final startOfMonth = DateTime(today.year, today.month, 1);
    final endOfMonth = DateTime(today.year, today.month + 1, 0);
    final startMonthStr = DateFormat('yyyy-MM-dd').format(startOfMonth);
    final endMonthStr = DateFormat('yyyy-MM-dd').format(endOfMonth);

    // 1. Define separate futures to handle errors individually
    // This ensures if Attendance fails, TVRs still show up.

    var tvrsMonthFuture = _apiService.fetchTvrsForUser(
      uid,
      startDate: startMonthStr,
      endDate: endMonthStr,
    );
    var tvrsTotalFuture = _apiService.fetchTvrsForUser(
      uid,
      limit: 10000,
    ); // Only fetches IDs usually, or small objects

    // Increase limit to ensure we count ALL PJPs correctly
    var pjpFuture = _apiService.fetchPjpsForUser(uid);

    var tasksFuture = _apiService.fetchDailyTasksForUser(
      uid,
      status: 'Completed',
    );
    var attendanceFuture = _apiService.fetchAttendanceForUser(uid, limit: 1000);

    var leaveFuture = _apiService.fetchLeaveApplicationsForUser(uid, limit: 1);

    try {
      // We use a helper to catch errors per request
      final results = await Future.wait([
        Future.value([]), // Index 0 placeholder
        tvrsMonthFuture.catchError((_) => <TechnicalVisitReport>[]),
        tvrsTotalFuture.catchError((_) => <TechnicalVisitReport>[]),
        pjpFuture.catchError((_) => <Pjp>[]),
        tasksFuture.catchError((_) => <DailyTask>[]),
        attendanceFuture.catchError((_) => <Attendance>[]),
        leaveFuture.catchError((_) => <LeaveApplication>[]),
      ]);

      final tvrsThisMonth = results[1] as List<TechnicalVisitReport>;
      final tvrsTotal = results[2] as List<TechnicalVisitReport>;
      final pjps = results[3] as List<Pjp>;
      final tasksList = results[4] as List<DailyTask>;
      final attendance = results[5] as List<Attendance>;
      final leaves = results[6] as List<LeaveApplication>;

      final totalIns = attendance.length;
      final totalOuts = attendance
          .where((a) => a.outTimeTimestamp != null)
          .length;

      // Calculate PJP stats
      final completedPjps = pjps
          .where((p) => p.status.toLowerCase() == 'completed')
          .length;

      return TechnicalProfileStats(
        tvrsThisMonth: tvrsThisMonth.length,
        tvrsTotal: tvrsTotal.length,
        upcomingVisits: pjps.length, // Or filter for future dates if needed
        completedTasks: tasksList.length,
        totalPjps: pjps.length,
        completedPjps: completedPjps,
        totalCheckIns: totalIns,
        totalCheckOuts: totalOuts,
        latestLeave: leaves.isNotEmpty ? leaves.first : null,
      );
    } catch (e) {
      debugPrint("Critical Error fetching stats: $e");
      // Only return 0s if something catastrophic happens
      return TechnicalProfileStats(
        tvrsThisMonth: 0,
        tvrsTotal: 0,
        upcomingVisits: 0,
        completedTasks: 0,
        totalPjps: 0,
        completedPjps: 0,
        totalCheckIns: 0,
        totalCheckOuts: 0,
        latestLeave: null,
      );
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

  Future<void> _launchDeleteAccountUrl() async {
    final Uri url = Uri.parse(
      'https://docs.google.com/forms/d/e/1FAIpQLSdq-4YaYoEckyD7H_fYl_L-ordLQIdC7RSiqmQd9w054G2Zkg/viewform?usp=publish-editor',
    );
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch url');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the form. Please contact support.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final flags = context.read<TechnicalFlags>();

    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: _bgLight,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
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
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return Center(child: CircularProgressIndicator(color: _cardNavy));
          }

          final stats =
              snapshot.data ??
              TechnicalProfileStats(
                tvrsThisMonth: 0,
                tvrsTotal: 0,
                upcomingVisits: 0,
                completedTasks: 0,
                totalPjps: 0,
                completedPjps: 0,
                totalCheckIns: 0,
                totalCheckOuts: 0,
              );

          return RefreshIndicator(
            onRefresh: _refreshStats,
            color: _cardNavy,
            backgroundColor: Colors.white,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 120.0),
              children: [
                // --- 1. PROFILE HEADER ---
                _buildFintechProfileHeader(
                  initials: getInitials(),
                  displayName: widget.employee.displayName,
                  email: widget.employee.email ?? 'No email',
                  role: "Technical Sales",
                ),

                const SizedBox(height: 32),

                // --- 2. OVERVIEW STATS ---
                Text(
                  "Overview",
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 0.85,
                  children: [
                    _buildStatCard(
                      title: "TVRs",
                      value: stats.tvrsThisMonth.toString(),
                      subtitle: "This month",
                      footer: "Lifetime: ${stats.tvrsTotal}",
                      icon: Icons.assignment_turned_in_rounded,
                      iconColor: Colors.purple,
                      iconBg: const Color(0xFFFAF5FF),
                      onTap: () {
                        final userId = int.tryParse(widget.employee.id);
                        if (userId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserTvrListScreen(userId: userId),
                            ),
                          );
                        }
                      },
                    ),

                    _buildStatCard(
                      title: "PJP",
                      value: stats.totalPjps.toString(),
                      subtitle: "Total plans",
                      footer: "Completed: ${stats.completedPjps}",
                      icon: Icons.route,
                      iconColor: Colors.indigo,
                      iconBg: const Color(0xFFE0E7FF),
                      onTap: () {
                        final userId = int.tryParse(widget.employee.id);
                        if (userId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserPjpListScreen(userId: userId),
                            ),
                          );
                        }
                      },
                    ),

                    _buildStatCard(
                      title: "Attendance",
                      value: stats.totalCheckIns.toString(),
                      subtitle: "Total Ins",
                      footer: "Total In + Out: ${stats.totalCheckOuts}",
                      icon: Icons.access_time_filled,
                      iconColor: Colors.green,
                      iconBg: const Color(0xFFECFDF5),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Leave Application Section
                Text(
                  "Leave Application",
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                _buildDetailedLeaveCard(
                  context: context,
                  latestLeave: stats.latestLeave,
                ),

                // --- 3. SETTINGS ---
                Text(
                  "Preferences",
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: _surfaceWhite,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'App Theme',
                        style: TextStyle(
                          color: _textGrey,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<ThemeMode>(
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.resolveWith<Color>((
                                  states,
                                ) {
                                  if (states.contains(MaterialState.selected))
                                    return _cardNavy;
                                  return _bgLight;
                                }),
                            foregroundColor:
                                MaterialStateProperty.resolveWith<Color>((
                                  states,
                                ) {
                                  if (states.contains(MaterialState.selected))
                                    return Colors.white;
                                  return _textGrey;
                                }),
                            side: MaterialStateProperty.all(BorderSide.none),
                            shape: MaterialStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            padding: MaterialStateProperty.all(
                              const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                          segments: const [
                            ButtonSegment(
                              value: ThemeMode.light,
                              label: Text('Light'),
                              icon: Icon(Icons.light_mode_outlined, size: 18),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              label: Text('Dark'),
                              icon: Icon(Icons.dark_mode_outlined, size: 18),
                            ),
                            ButtonSegment(
                              value: ThemeMode.system,
                              label: Text('Auto'),
                              icon: Icon(
                                Icons.phone_android_outlined,
                                size: 18,
                              ),
                            ),
                          ],
                          selected: {themeProvider.themeMode},
                          onSelectionChanged: (Set<ThemeMode> newSelection) {
                            themeProvider.setThemeMode(newSelection.first);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                //  ----- DEBUG TOOLS -----
                if (flags.showDbViewer) ...[
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: _surfaceWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.purple.withOpacity(0.2)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      leading: const Icon(Icons.storage, color: Colors.purple),
                      title: const Text(
                        "Local Database",
                        style: TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.purple,
                      ),
                      onTap: () {
                        final db = AppDatabase.instance;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => DriftDbViewer(db),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                // --- 4. ACCOUNT ACTIONS ---
                const SizedBox(height: 32),
                Text(
                  "Account",
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  decoration: BoxDecoration(
                    color: _surfaceWhite,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _cardNavy.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.shield_outlined,
                          color: _cardNavy,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'Privacy & Security',
                        style: TextStyle(
                          color: _textDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      childrenPadding: const EdgeInsets.only(bottom: 12),
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                          ),
                          leading: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          title: const Text(
                            "Request Account Deletion",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.open_in_new,
                            size: 16,
                            color: Colors.grey,
                          ),
                          onTap: _launchDeleteAccountUrl,
                        ),
                      ],
                    ),
                  ),
                ),

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
              BoxShadow(
                color: _cardNavy.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: _cardNavy,
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          displayName,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: _textDark,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: TextStyle(
            color: _textGrey,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _cardNavy.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            role.toUpperCase(),
            style: TextStyle(
              color: _cardNavy,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    String? subtitle,
    String? footer,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _surfaceWhite,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                // Only show arrow if it's clickable
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: _textGrey.withOpacity(0.4),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: _textDark,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle != null ? "$title\n$subtitle" : title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textGrey,
                height: 1.2,
              ),
            ),
            if (footer != null) ...[
              const SizedBox(height: 8),
              Text(
                footer,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _textGrey.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedLeaveCard({
    required BuildContext context,
    required LeaveApplication?
    latestLeave,
  }) {
    const Color cardBg = Color(
      0xFFFEE2E2,
    ); 
    const Color iconColor = Colors.redAccent;
    const IconData iconData =
        Icons.calendar_month_outlined; 

    return GestureDetector(
      onTap: () async {
        final userId = int.parse(widget.employee.id);

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AllLeavesListScreen(userId: userId),
          ),
        );

        _refreshStats();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _surfaceWhite,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(iconData, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Leaves", 
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Apply & view history", 
                    style: TextStyle(
                      fontSize: 13,
                      color: _textGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow/Action
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: _textGrey.withOpacity(0.4),
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
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      onPressed: () async {
        await AuthService().logout();
        if (context.mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/selector', (route) => false);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }
}