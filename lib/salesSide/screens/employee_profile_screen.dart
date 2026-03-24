// lib/salesSide/screens/employee_profile_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:salesmanapp/salesSide/models/employee_model.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/salesSide/models/leave_application_model.dart';
import 'package:salesmanapp/api/auth_service.dart';
import 'package:salesmanapp/widgets/theme_provider.dart';
import 'package:salesmanapp/salesSide/models/attendance_model.dart';
import 'package:salesmanapp/salesSide/models/daily_task_model.dart';
import 'package:salesmanapp/salesSide/models/daily_visit_report_model.dart';

// Screens for navigation
import 'package:salesmanapp/salesSide/screens/all_dvr_list_screen.dart';
import 'package:salesmanapp/salesSide/screens/all_tasks_list_screen.dart';
import 'package:salesmanapp/salesSide/screens/all_leaves_list_screen.dart';

// --- Local Drift DB & Feature Flags ---
import 'package:drift_db_viewer/drift_db_viewer.dart';
import 'package:salesmanapp/database/app_database.dart';
import 'package:salesmanapp/core/feature_flags/sales_flags.dart';

// --- Helper Data Class for Stats ---
class SalesProfileStats {
  final int dvrsThisMonth;
  final int dvrsTotal;
  final int totalTasks;
  final int completedTasks;
  final int totalCheckIns;
  final int totalCheckOuts;
  final LeaveApplication? latestLeave;

  const SalesProfileStats({
    required this.dvrsThisMonth,
    required this.dvrsTotal,
    required this.totalTasks,
    required this.completedTasks,
    required this.totalCheckIns,
    required this.totalCheckOuts,
    this.latestLeave,
  });
}

class EmployeeProfileScreen extends StatefulWidget {
  final Employee employee;
  const EmployeeProfileScreen({super.key, required this.employee});

  @override
  State<EmployeeProfileScreen> createState() => EmployeeProfileScreenState();
}

class EmployeeProfileScreenState extends State<EmployeeProfileScreen> {
  final ApiService _apiService = ApiService();
  late Future<SalesProfileStats> _statsFuture;

  // --- 🎨 PREMIUM THEME PALETTE ---
  static const Color _bgLight = Color(0xFFF8FAFC);
  static const Color _cardNavy = Color(0xFF0F172A);
  static const Color _textDark = Color(0xFF1E293B);
  static const Color _textGrey = Color(0xFF64748B);
  static const Color _surfaceWhite = Colors.white;

  @override
  void initState() {
    super.initState();
    _statsFuture = _fetchProfileStats();
  }

  Future<void> _refreshStats() async {
    // 🚀 SMOOTH UI FIX: We don't need setState here for the spinner.
    // RefreshIndicator handles it natively. We just reassign the future.
    final newFuture = _fetchProfileStats();
    if (mounted) {
      setState(() {
        _statsFuture = newFuture;
      });
    }
    await newFuture;
  }

  Future<SalesProfileStats> _fetchProfileStats() async {
    final uid = int.tryParse(widget.employee.id);
    if (uid == null) throw Exception('Invalid Employee ID');

    final today = DateTime.now();
    final startOfMonth = DateTime(today.year, today.month, 1);
    final endOfMonth = DateTime(today.year, today.month + 1, 0);
    final startMonthStr = DateFormat('yyyy-MM-dd').format(startOfMonth);
    final endMonthStr = DateFormat('yyyy-MM-dd').format(endOfMonth);

    try {
      // 🚀 SPEED OPTIMIZATION: Fire all network requests concurrently
      final results = await Future.wait([
        _apiService
            .fetchDvrsForUser(
              uid,
              startDate: startMonthStr,
              endDate: endMonthStr,
            )
            .catchError((_) => <DailyVisitReport>[]),
        _apiService
            .fetchDailyTasksForUser(uid)
            .catchError((_) => <DailyTask>[]),
        _apiService
            .fetchAttendanceForUser(uid, limit: 1000)
            .catchError((_) => <Attendance>[]),
        _apiService
            .fetchLeaveApplicationsForUser(uid, limit: 1)
            .catchError((_) => <LeaveApplication>[]),
      ]);

      // 🚀 CPU & MEMORY OPTIMIZATION: Main thread is vastly faster than spawning an Isolate for this.
      final dvrsThisMonth = results[0] as List<DailyVisitReport>;
      final allTasks = results[1] as List<DailyTask>;
      final attendance = results[2] as List<Attendance>;
      final leaves = results[3] as List<LeaveApplication>;

      int completedTasks = 0;
      for (var t in allTasks) {
        // Space optimization: No temporary string allocations (.toLowerCase())
        if (t.status == 'completed' || t.status == 'Completed') {
          completedTasks++;
        }
      }

      int totalOuts = 0;
      for (var a in attendance) {
        if (a.outTimeTimestamp != null) totalOuts++;
      }

      return SalesProfileStats(
        dvrsThisMonth: dvrsThisMonth.length,
        dvrsTotal: dvrsThisMonth.length,
        totalTasks: allTasks.length,
        completedTasks: completedTasks,
        totalCheckIns: attendance.length,
        totalCheckOuts: totalOuts,
        latestLeave: leaves.isNotEmpty ? leaves.first : null,
      );
    } catch (e) {
      debugPrint("Critical Error fetching stats: $e");
      return const SalesProfileStats(
        dvrsThisMonth: 0,
        dvrsTotal: 0,
        totalTasks: 0,
        completedTasks: 0,
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
      if (!await launchUrl(url, mode: LaunchMode.externalApplication))
          {throw Exception('Could not launch url');}
    } catch (e) {
      if (mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the form. Please contact support.'),
          ),
        );
    }}
  }

  // 🚀 O(1) EXTREME OPTIMIZATION SYNC METHOD
  Future<void> syncOfflineDealers() async {
    try {
      int page = 1;
      int newlyAdded = 0;
      int patched = 0;
      bool hasMore = true;
      const int batchSize = 500;

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🔄 Background sync started..."),
            duration: Duration(seconds: 3),
            backgroundColor: Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // 🚀 Fetch IDs into memory (Set has O(1) lookup time)
      final Set<String> existingIds = await AppDatabase.instance
          .getAllDealerIdsFast();

      while (hasMore) {
        // 🚀 Yield the thread minimally to keep UI at 60fps
        await Future.delayed(const Duration(milliseconds: 16));

        final batch = await _apiService.fetchDealers(
          search: "",
          limit: batchSize,
          page: page,
        );

        if (batch.isEmpty) {
          hasMore = false;
          break;
        }

        // 🚀 O(1) Logic Update: Set.add() returns true if the item was newly added, false if it existed!
        for (var dealer in batch) {
          if (dealer.id != null) {
            if (existingIds.add(dealer.id!)) {
              newlyAdded++;
            } else {
              patched++;
            }
          }
        }

        // 🚀 RAM SAVER: Removed Map.from() overhead. Drift handles insertion async.
        final dealerJsonList = batch.map((d) => d.toJson()).toList();
        await AppDatabase.instance.syncDealersToLocal(dealerJsonList);

        page++;
        if (batch.length < batchSize) hasMore = false;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "✅ Sync Complete!\nAdded: $newlyAdded | Patched: $patched\nTotal in Vault: ${existingIds.length}",
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      debugPrint("🚨 SYNC ERROR: $e");
      if (mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Sync stopped at error: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }}
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final flags = context.read<SalesFlags>();

    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: _bgLight,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'PROFILE',
          style: TextStyle(
            color: _textDark,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),
      ),
      body: FutureBuilder<SalesProfileStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          // 🚀 JANK FIX: Only show loading circle if we have NO previous data.
          if (!snapshot.hasData &&
              snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _cardNavy),
            );
          }

          final stats =
              snapshot.data ??
              const SalesProfileStats(
                dvrsThisMonth: 0,
                dvrsTotal: 0,
                totalTasks: 0,
                completedTasks: 0,
                totalCheckIns: 0,
                totalCheckOuts: 0,
                latestLeave: null,
              );

          return RefreshIndicator(
            onRefresh: _refreshStats,
            color: _cardNavy,
            backgroundColor: Colors.white,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 120.0),
              children: [
                // 1. PROFILE HEADER
                _ProfileHeaderCard(
                      initials: getInitials(),
                      displayName: widget.employee.displayName,
                      email: widget.employee.email ?? 'No email',
                      role: widget.employee.role ?? "Sales Force",
                    )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(
                      begin: const Offset(0.9, 0.9),
                      curve: Curves.easeOutBack,
                    ),

                const SizedBox(height: 32),
                const Text(
                  "Overview",
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
                const SizedBox(height: 16),

                // 2. OVERVIEW STATS
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 0.85,
                  children: [
                    _StatCard(
                          title: "DVRs",
                          value: stats.dvrsThisMonth.toString(),
                          subtitle: "This month",
                          footer: "Total: ${stats.dvrsTotal}",
                          icon: Icons.assignment_turned_in_rounded,
                          iconColor: Colors.blueAccent,
                          iconBg: const Color(0xFFEFF6FF),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AllDvrListScreen(
                                userId: int.parse(widget.employee.id),
                              ),
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 200.ms)
                        .scaleXY(begin: 0.9, curve: Curves.easeOutBack),

                    _StatCard(
                          title: "PJPs",
                          value: stats.totalTasks.toString(),
                          subtitle: "Assigned",
                          footer: "Completed: ${stats.completedTasks}",
                          icon: Icons.task_alt_rounded,
                          iconColor: Colors.orange,
                          iconBg: const Color(0xFFFFF7ED),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AllTasksListScreen(
                                userId: int.parse(widget.employee.id),
                              ),
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 300.ms)
                        .scaleXY(begin: 0.9, curve: Curves.easeOutBack),

                    _StatCard(
                          title: "Attendance",
                          value: stats.totalCheckIns.toString(),
                          subtitle: "Total Ins",
                          footer: "Total In + Out: ${stats.totalCheckOuts}",
                          icon: Icons.access_time_filled,
                          iconColor: Colors.green,
                          iconBg: const Color(0xFFECFDF5),
                        )
                        .animate()
                        .fadeIn(delay: 400.ms)
                        .scaleXY(begin: 0.9, curve: Curves.easeOutBack),
                  ],
                ),

                const SizedBox(height: 32),
                const Text(
                  "Leave Application",
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(delay: 450.ms).slideX(begin: -0.1),
                const SizedBox(height: 16),

                // 3. LEAVE APPLICATION
                _DetailedLeaveCard(
                      latestLeave: stats.latestLeave,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AllLeavesListScreen(
                              userId: int.parse(widget.employee.id),
                            ),
                          ),
                        );
                        _refreshStats();
                      },
                    )
                    .animate()
                    .fadeIn(delay: 500.ms)
                    .slideY(begin: 0.1, curve: Curves.easeOutCubic),

                const SizedBox(height: 32),
                const Text(
                  "Preferences",
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(delay: 550.ms).slideX(begin: -0.1),
                const SizedBox(height: 16),

                // 4. PREFERENCES (THEME)
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
                          const Text(
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
                                    WidgetStateProperty.resolveWith<Color>(
                                      (states) =>
                                          states.contains(WidgetState.selected)
                                          ? _cardNavy
                                          : _bgLight,
                                    ),
                                foregroundColor:
                                    WidgetStateProperty.resolveWith<Color>(
                                      (states) =>
                                          states.contains(WidgetState.selected)
                                          ? Colors.white
                                          : _textGrey,
                                    ),
                                side: WidgetStateProperty.all(BorderSide.none),
                                shape: WidgetStateProperty.all(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                padding: WidgetStateProperty.all(
                                  const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                              segments: const [
                                ButtonSegment(
                                  value: ThemeMode.light,
                                  label: Text('Light'),
                                  icon: Icon(
                                    Icons.light_mode_outlined,
                                    size: 18,
                                  ),
                                ),
                                ButtonSegment(
                                  value: ThemeMode.dark,
                                  label: Text('Dark'),
                                  icon: Icon(
                                    Icons.dark_mode_outlined,
                                    size: 18,
                                  ),
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
                              onSelectionChanged:
                                  (Set<ThemeMode> newSelection) => themeProvider
                                      .setThemeMode(newSelection.first),
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 600.ms)
                    .slideY(begin: 0.1, curve: Curves.easeOutCubic),

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
                  ).animate().fadeIn(delay: 650.ms),
                ],

                if (flags.accountSwitcher &&
                    widget.employee.isTechnicalRole &&
                    widget.employee.techLoginId?.isNotEmpty == true) ...[
                  const SizedBox(height: 32),
                  const Text(
                    "Switch Portal",
                    style: TextStyle(
                      color: _textDark,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(delay: 700.ms).slideX(begin: -0.1),
                  const SizedBox(height: 16),
                  Container(
                        decoration: BoxDecoration(
                          color: _surfaceWhite,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFF0F766E).withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.06),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.engineering_rounded,
                              color: Color(0xFF0F766E),
                              size: 26,
                            ),
                          ),
                          title: const Text(
                            "Switch to Technical Side",
                            style: TextStyle(
                              color: Color(0xFF0F766E),
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: const Text(
                            "Access TSE Dashboard Side",
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Color(0xFF0F766E),
                          ),
                          onTap: () async {
                            if (widget.employee.isTechnicalRole) {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setBool('is_technical_mode', true);
                              if (context.mounted){
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/technical_home',
                                  (route) => false,
                                  arguments: widget.employee,
                                );
                              }}
                          },
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 750.ms)
                      .slideY(begin: 0.1, curve: Curves.easeOutCubic)
                      .animate(onPlay: (c) => c.repeat(count: 3, reverse: true))
                      .shimmer(
                        duration: 2500.ms,
                        color: const Color(0xFF0F766E).withOpacity(0.1),
                      ),
                ],

                if (flags.offlineSync) ...[
                  const SizedBox(height: 32),
                  const Text(
                    "Offline Data",
                    style: TextStyle(
                      color: _textDark,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(delay: 780.ms).slideX(begin: -0.1),
                  const SizedBox(height: 16),
                  Container(
                        decoration: BoxDecoration(
                          color: _surfaceWhite,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.blueAccent.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.06),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.cloud_download_rounded,
                              color: Colors.blueAccent,
                              size: 26,
                            ),
                          ),
                          title: const Text(
                            "Sync Offline Dealers",
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Colors.blueAccent,
                          ),
                          onTap: () async {
                            HapticFeedback.mediumImpact();
                            await syncOfflineDealers();
                          },
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 800.ms)
                      .slideY(begin: 0.1, curve: Curves.easeOutCubic),
                ],

                const SizedBox(height: 32),
                const Text(
                  "Account",
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(delay: 800.ms).slideX(begin: -0.1),
                const SizedBox(height: 16),

                // 5. ACCOUNT ACTIONS
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
                            child: const Icon(
                              Icons.shield_outlined,
                              color: _cardNavy,
                              size: 20,
                            ),
                          ),
                          title: const Text(
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
                    )
                    .animate()
                    .fadeIn(delay: 850.ms)
                    .slideY(begin: 0.1, curve: Curves.easeOutCubic),

                const SizedBox(height: 32),
                const _LogoutButton().animate().fadeIn(delay: 950.ms),
              ],
            ),
          );
        },
      ),
    );
  }
}

// 🚀 SPACE & CPU OPTIMIZATION: Stateless cached widgets
class _ProfileHeaderCard extends StatelessWidget {
  final String initials;
  final String displayName;
  final String email;
  final String role;

  const _ProfileHeaderCard({
    required this.initials,
    required this.displayName,
    required this.email,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFF0F172A),
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
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E293B),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            role.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final String footer;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.footer,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
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
                if (onTap != null)
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "$title\n$subtitle",
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              footer,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF64748B).withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailedLeaveCard extends StatelessWidget {
  final LeaveApplication? latestLeave;
  final VoidCallback onTap;

  const _DetailedLeaveCard({required this.latestLeave, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.calendar_month_outlined,
                color: Colors.redAccent,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Leaves",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    latestLeave != null
                        ? "Latest: ${latestLeave!.status}"
                        : "Apply & view history",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: const Color(0xFF64748B).withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

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
        if (context.mounted){
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/selector', (route) => false);
      }},
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFEF4444),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: const Color(0xFFEF4444).withOpacity(0.2)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }
}
