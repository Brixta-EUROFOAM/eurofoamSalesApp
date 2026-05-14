// lib/screens/profileScreen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/api_service.dart';
import '../api/auth_service.dart';
import '../models/users_model.dart';
import '../models/dvr_model.dart';
import '../models/pjp_model.dart';
import '../models/attendance_model.dart';
import '../models/leaves_model.dart';

// Connected List Screens
import 'views/dvr_list.dart';
import 'views/leaves_list.dart';
import 'views/pjp_list.dart';
import 'loginScreen.dart';

// --- Helper Data Class for Stats ---
class SalesProfileStats {
  final int dvrsThisMonth;
  final int dvrsTotal;
  final int totalPjps;
  final int completedPjps;
  final int totalCheckIns;
  final int totalCheckOuts;
  final LeaveModel? latestLeave;

  const SalesProfileStats({
    required this.dvrsThisMonth,
    required this.dvrsTotal,
    required this.totalPjps,
    required this.completedPjps,
    required this.totalCheckIns,
    required this.totalCheckOuts,
    this.latestLeave,
  });
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  UserModel? _currentUser;
  late Future<SalesProfileStats> _statsFuture;

  // --- 🎨 PREMIUM THEME PALETTE ---
  static const Color _bgLight = Color(0xFFF8FAFC);
  static const Color _cardNavy = Color(0xFF0F172A);
  static const Color _textDark = Color(0xFF1E293B);
  static const Color _surfaceWhite = Colors.white;

  @override
  void initState() {
    super.initState();
    _statsFuture = _initProfileAndFetchStats();
  }

  Future<void> _refreshStats() async {
    final newFuture = _fetchProfileStats();
    if (mounted) setState(() => _statsFuture = newFuture);
    await newFuture;
  }

  Future<SalesProfileStats> _initProfileAndFetchStats() async {
    // 1. Load User Profile from Secure Storage
    final userJson = await _storage.read(key: 'user_profile');
    if (userJson != null) {
      _currentUser = UserModel.fromJson(jsonDecode(userJson));
    }
    // 2. Fetch Stats
    return _fetchProfileStats();
  }

  Future<SalesProfileStats> _fetchProfileStats() async {
    try {
      // Run API requests in parallel for speed
      final results = await Future.wait([
        _apiService.getDailyVisitReports().catchError((_) => <DvrModel>[]),
        _apiService.getJourneyPlans().catchError((_) => <PjpModel>[]),
        _apiService.getAttendanceHistory().catchError(
          (_) => <AttendanceModel>[],
        ),
        _apiService.getLeaves().catchError((_) => <LeaveModel>[]),
      ]);

      final List<DvrModel> allDvrs = results[0] as List<DvrModel>;
      final List<PjpModel> allPjps = results[1] as List<PjpModel>;
      final List<AttendanceModel> attendance =
          results[2] as List<AttendanceModel>;
      final List<LeaveModel> leaves = results[3] as List<LeaveModel>;

      final now = DateTime.now();

      // Calculate DVRs this month
      int dvrsThisMonth = 0;
      for (var dvr in allDvrs) {
        if (dvr.reportDate != null &&
            dvr.reportDate!.month == now.month &&
            dvr.reportDate!.year == now.year) {
          dvrsThisMonth++;
        }
      }

      // Calculate Completed PJPs
      int completedPjps = 0;
      for (var pjp in allPjps) {
        if (pjp.status.toLowerCase() == 'completed') {
          completedPjps++;
        }
      }

      // Calculate Checkouts
      int totalOuts = 0;
      for (var att in attendance) {
        if (att.outTimeTimestamp != null || att.outTimeImageCaptured) {
          totalOuts++;
        }
      }

      // Sort leaves to get the latest one
      leaves.sort(
        (a, b) => b.createdAt?.compareTo(a.createdAt ?? DateTime(2000)) ?? 0,
      );

      return SalesProfileStats(
        dvrsThisMonth: dvrsThisMonth,
        dvrsTotal: allDvrs.length,
        totalPjps: allPjps.length,
        completedPjps: completedPjps,
        totalCheckIns: attendance.length,
        totalCheckOuts: totalOuts,
        latestLeave: leaves.isNotEmpty ? leaves.first : null,
      );
    } catch (e) {
      debugPrint("Critical Error fetching stats: $e");
      return const SalesProfileStats(
        dvrsThisMonth: 0,
        dvrsTotal: 0,
        totalPjps: 0,
        completedPjps: 0,
        totalCheckIns: 0,
        totalCheckOuts: 0,
        latestLeave: null,
      );
    }
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  Future<void> _launchDeleteAccountUrl() async {
    final Uri url = Uri.parse(
      'https://docs.google.com/forms/d/e/1FAIpQLSdxWo2bZvpaI4EBxjeY2s36z4OUPthNh-k26xnitrcbbV_-cw/viewform?usp=publish-editor',
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
                totalPjps: 0,
                completedPjps: 0,
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
                      initials: _getInitials(_currentUser?.username),
                      displayName: _currentUser?.username ?? 'Salesman',
                      email: _currentUser?.email ?? 'No email',
                      role: _currentUser?.role ?? "Sales Force",
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
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DvrListScreen(),
                              ),
                            );
                          },
                        )
                        .animate()
                        .fadeIn(delay: 200.ms)
                        .scaleXY(begin: 0.9, curve: Curves.easeOutBack),

                    _StatCard(
                          title: "PJPs",
                          value: stats.totalPjps.toString(),
                          subtitle: "Assigned",
                          footer: "Completed: ${stats.completedPjps}",
                          icon: Icons.map_outlined,
                          iconColor: Colors.orange,
                          iconBg: const Color(0xFFFFF7ED),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PjpListScreen(),
                              ),
                            );
                          },
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
                            builder: (_) => const LeavesListScreen(),
                          ),
                        );
                        _refreshStats(); // Refresh stats when returning from leaves screen
                      },
                    )
                    .animate()
                    .fadeIn(delay: 500.ms)
                    .slideY(begin: 0.1, curve: Curves.easeOutCubic),

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

                // 4. ACCOUNT ACTIONS (Deletion Form)
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

// ============================================================================
// STATELESS UI COMPONENTS
// ============================================================================

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
            role.replaceAll('-', ' ').toUpperCase(),
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
  final LeaveModel? latestLeave;
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
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      },
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
