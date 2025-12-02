// lib/screens/employee_management/employee_profile_screen.dart
import 'dart:async';
import 'package:salesmanapp/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/models/dealer_model.dart';
import 'package:salesmanapp/api/auth_service.dart';
import 'package:intl/intl.dart'; 
import 'package:provider/provider.dart';
import 'package:salesmanapp/widgets/theme_provider.dart';

class _ProfileStats {
  final int monthlyReportCount;
  final int monthlyPjpCount;
  final int allTimeDealerCount;
  final int allTimeCompletedTasksCount;

  _ProfileStats({
    required this.monthlyReportCount,
    required this.monthlyPjpCount,
    required this.allTimeDealerCount,
    required this.allTimeCompletedTasksCount,
  });
}

class EmployeeProfileScreen extends StatefulWidget {
  final Employee employee;
  const EmployeeProfileScreen({super.key, required this.employee});

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> {
  final ApiService _apiService = ApiService();
  late Future<_ProfileStats> _statsFuture;

  // --- FINTECH THEME PALETTE ---
  final Color _bgLight       = const Color(0xFFF3F4F6); 
  final Color _cardNavy      = const Color(0xFF0F172A); 
  final Color _textDark      = const Color(0xFF111827); 
  final Color _textGrey      = const Color(0xFF6B7280); 
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

  String getInitials() {
    String firstNameInitial = widget.employee.firstName?.isNotEmpty == true
        ? widget.employee.firstName![0]
        : '';
    String lastNameInitial = widget.employee.lastName?.isNotEmpty == true
        ? widget.employee.lastName![0]
        : '';
    return (firstNameInitial + lastNameInitial).toUpperCase();
  }

  String _capitalize(String? s) {
    if (s == null || s.isEmpty) return '';
    return s[0].toUpperCase() + s.substring(1);
  }

  Future<_ProfileStats> _fetchProfileStats() async {
    final employeeId = int.parse(widget.employee.id); 

    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final formatter = DateFormat('yyyy-MM-dd');
    final startDate = formatter.format(firstDayOfMonth);
    final endDate = formatter.format(lastDayOfMonth);

    final results = await Future.wait([
      _apiService.fetchDvrsForUser(employeeId, startDate: startDate, endDate: endDate),
      _apiService.fetchTvrsForUser(employeeId, startDate: startDate, endDate: endDate),
      _apiService.fetchPjpsForUser(employeeId, startDate: startDate, endDate: endDate),
      _apiService.fetchDealers(userId: employeeId),
      _apiService.fetchDailyTasksForUser(employeeId, status: 'Completed'),
    ]);

    final dvrCount = (results[0] as List).length;
    final tvrCount = (results[1] as List).length;
    final monthlyPjpCount = (results[2] as List).length;
    final allTimeDealerCount = (results[3] as List).length;
    final allTimeCompletedTasksCount = (results[4] as List).length;

    return _ProfileStats(
      monthlyReportCount: dvrCount + tvrCount,
      monthlyPjpCount: monthlyPjpCount,
      allTimeDealerCount: allTimeDealerCount,
      allTimeCompletedTasksCount: allTimeCompletedTasksCount,
    );
  }

  void _showManageDealersSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (BuildContext context, ScrollController scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: _surfaceWhite,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
            ),
            child: _ManageDealersContent(
              employee: widget.employee,
              scrollController: scrollController,
              onDealersUpdated: _refreshStats,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

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
      body: FutureBuilder<_ProfileStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
            return Center(child: CircularProgressIndicator(color: _cardNavy));
          }
          
          final stats = snapshot.data ?? _ProfileStats(
            monthlyReportCount: 0,
            monthlyPjpCount: 0,
            allTimeDealerCount: 0,
            allTimeCompletedTasksCount: 0,
          );

          return RefreshIndicator(
            onRefresh: _refreshStats,
            color: _cardNavy,
            backgroundColor: Colors.white,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 120.0),
              children: [
                
                // --- 1. Profile Header ---
                _buildFintechProfileHeader(
                  initials: getInitials(),
                  displayName: widget.employee.displayName,
                  email: widget.employee.email ?? 'No email',
                  role: _capitalize(widget.employee.role ?? 'Sales Employee'),
                ),

                const SizedBox(height: 32),

                // --- 2. Overview Stats ---
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

                Container(
                  decoration: BoxDecoration(
                    color: _surfaceWhite,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
                    ],
                  ),
                  child: Column(
                    children: [
                      _ActionListTile(
                        icon: Icons.store_mall_directory_outlined,
                        title: 'Manage Dealers',
                        trailing: stats.allTimeDealerCount.toString(),
                        onTap: _showManageDealersSheet,
                      ),
                      _ActionListTile(
                        icon: Icons.task_alt_outlined,
                        title: 'Completed Tasks',
                        trailing: stats.allTimeCompletedTasksCount.toString(),
                        onTap: () {},
                      ),
                      _ActionListTile(
                        icon: Icons.assignment_outlined,
                        title: 'Monthly Reports',
                        trailing: stats.monthlyReportCount.toString(),
                        onTap: () {},
                      ),
                      _ActionListTile(
                       icon: Icons.map_outlined,
                       title: 'Brand Mapping',
                       onTap: () {},
                       hideBorder: true, 
                     ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // --- 3. Settings ---
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
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<ThemeMode>(
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                              if (states.contains(MaterialState.selected)) return _cardNavy;
                              return _bgLight;
                            }),
                            foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                              if (states.contains(MaterialState.selected)) return Colors.white;
                              return _textGrey;
                            }),
                            side: MaterialStateProperty.all(BorderSide.none),
                            shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          ),
                          segments: const [
                            ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_outlined)),
                            ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_outlined)),
                            ButtonSegment(value: ThemeMode.system, label: Text('Auto'), icon: Icon(Icons.phone_android_outlined)),
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
                
                // --- 4. Logout ---
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
}

class _ActionListTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final String? trailing;
  final bool hideBorder;

  const _ActionListTile({
    required this.title,
    required this.icon,
    required this.onTap,
    this.trailing,
    this.hideBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    const Color textDark = Color(0xFF111827);
    const Color textGrey = Color(0xFF6B7280);
    const Color cardNavy = Color(0xFF0F172A);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        decoration: BoxDecoration(
          border: Border(
            bottom: hideBorder
                ? BorderSide.none
                : BorderSide(color: Colors.grey.withOpacity(0.1)),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: cardNavy, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: textDark,
                  fontSize: 15,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: const TextStyle(
                  color: textGrey,
                  fontWeight: FontWeight.bold,
                  fontSize: 14
                ),
              )
            else
              Icon(
                Icons.chevron_right,
                color: textGrey.withOpacity(0.5),
                size: 20,
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
        foregroundColor: color,
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

class _ManageDealersContent extends StatefulWidget {
  final Employee employee;
  final ScrollController scrollController;
  final VoidCallback onDealersUpdated;

  const _ManageDealersContent({
    required this.employee,
    required this.scrollController,
    required this.onDealersUpdated,
  });

  @override
  State<_ManageDealersContent> createState() => _ManageDealersContentState();
}

class _ManageDealersContentState extends State<_ManageDealersContent> {
  final ApiService _apiService = ApiService();
  late Future<List<Dealer>> _dealersFuture;

  // Colors for this widget
  static const Color _textDark = Color(0xFF111827);
  static const Color _textGrey = Color(0xFF6B7280);
  static const Color _cardNavy = Color(0xFF0F172A);

  @override
  void initState() {
    super.initState();
    _refreshDealers(notifyParent: false);
  }

  void _refreshDealers({bool notifyParent = true}) {
    if (mounted) {
      setState(() {
        _dealersFuture = _apiService.fetchDealers(
          userId: int.parse(widget.employee.id), 
        );
      });
      if (notifyParent) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onDealersUpdated();
        });
      }
    }
  }

  void _deleteDealer(String dealerId) async {
     final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Confirm Deletion', style: TextStyle(color: _textDark, fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to delete this dealer? This action cannot be undone.',
          style: TextStyle(color: _textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: _textGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _apiService.deleteDealer(dealerId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dealer deleted'), backgroundColor: Colors.green));
      _refreshDealers(notifyParent: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red));
    }
  }

  void _showDealerActions(Dealer dealer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
          ),
          child: SafeArea(
            child: Wrap(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(dealer.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
                ),
                ListTile(
                  leading: const Icon(Icons.edit, color: _cardNavy),
                  title: const Text('Edit Dealer', style: TextStyle(color: _textDark)),
                  onTap: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit feature coming soon...')));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete Dealer', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.of(context).pop();
                    if (dealer.id != null) {
                      _deleteDealer(dealer.id!);
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Text(
            'Manage Your Dealers',
            style: TextStyle(
              color: _textDark,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Dealer>>(
            future: _dealersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: _cardNavy));
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No dealers found.', style: TextStyle(color: _textGrey)));
              }
              final dealers = snapshot.data!;
              return ListView.separated(
                controller: widget.scrollController,
                itemCount: dealers.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1, indent: 70, color: Color(0xFFF3F4F6)),
                itemBuilder: (context, index) {
                  final dealer = dealers[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.store, color: Colors.green, size: 24),
                    ),
                    title: Text(
                      dealer.name,
                      style: const TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text(
                      dealer.address,
                      style: const TextStyle(color: _textGrey, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.more_vert, color: _textGrey),
                    onTap: () => _showDealerActions(dealer),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}