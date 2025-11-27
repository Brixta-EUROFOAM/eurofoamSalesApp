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

// --- (_ProfileStats class remains the same) ---
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
    final theme = Theme.of(context);
    
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
              color: theme.colorScheme.surface,
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

  // --- ✅ THIS IS THE CORRECTED BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: FutureBuilder<_ProfileStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return Center(
              child: CircularProgressIndicator(color: theme.colorScheme.primary),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            );
          }
          final stats =
              snapshot.data ??
              _ProfileStats(
                monthlyReportCount: 0,
                monthlyPjpCount: 0,
                allTimeDealerCount: 0,
                allTimeCompletedTasksCount: 0,
              );

          return RefreshIndicator(
            onRefresh: _refreshStats,
            color: theme.colorScheme.onPrimary,
            backgroundColor: theme.colorScheme.primary,
            child: ListView(
              // --- ✅ THE FIX ---
              // Add 120px of bottom padding to clear the floating nav bar
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 120.0),
              // --- END FIX ---
              children: [
                
                // --- 1. NEW Profile Header Card ---
                _ProfileHeaderCard(
                  initials: getInitials(),
                  displayName: widget.employee.displayName,
                  email: widget.employee.email ?? 'No email',
                  role: _capitalize(widget.employee.role ?? 'Employee'),
                ),

                // --- 2. NEW Action & Stats List ---
                const _SectionHeader('Toolbox & Stats'),
                Card(
                  clipBehavior: Clip.antiAlias,
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
                        icon: Icons.event_note_outlined,
                        title: 'Apply for Leave',
                        onTap: () {},
                      ),
                       _ActionListTile(
                        icon: Icons.map_outlined,
                        title: 'Brand Mapping',
                        onTap: () {},
                        hideBorder: true, // No border on the last item
                      ),
                    ],
                  ),
                ),

                // --- 3. NEW Settings Section ---
                const _SectionHeader('App Settings'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Theme Preference',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        SegmentedButton<ThemeMode>(
                          segments: const [
                            ButtonSegment(
                              value: ThemeMode.light,
                              label: Text('Light'),
                              icon: Icon(Icons.light_mode_outlined),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              label: Text('Dark'),
                              icon: Icon(Icons.dark_mode_outlined),
                            ),
                            ButtonSegment(
                              value: ThemeMode.system,
                              label: Text('System'),
                              icon: Icon(Icons.phone_android_outlined),
                            ),
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
                
                // --- 4. Logout Button (Unchanged) ---
                const SizedBox(height: 32),
                _LogoutButton(),
              ],
            ),
          );
        },
      ),
    );
  }
}

// --- ✅ NEW WIDGET: A clean header for the user's profile info ---
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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                initials,
                style: textTheme.headlineLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              displayName,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Chip(
              avatar: Icon(
                Icons.work_outline,
                color: theme.colorScheme.onSurfaceVariant,
                size: 18,
              ),
              label: Text(
                role,
                style: textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              side: BorderSide.none,
            ),
          ],
        ),
      ),
    );
  }
}

// --- ✅ NEW WIDGET: A clean, reusable list tile for actions ---
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
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          border: Border(
            bottom: hideBorder
                ? BorderSide.none
                : BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
              ),
          ],
        ),
      ),
    );
  }
}

// --- ✅ NEW WIDGET: A simple header for sections ---
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title); // <-- Positional argument

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 24.0, 8.0, 8.0),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}

// --- (PerformanceChart class was removed) ---

// --- (_ManageDealersContent class remains the same) ---
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
        title: const Text('Confirm Deletion'),
        content: const Text(
          'Are you sure you want to delete this dealer? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _apiService.deleteDealer(dealerId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dealer deleted'),
          backgroundColor: Colors.green,
        ),
      );
      _refreshDealers(notifyParent: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editDealer(Dealer dealer) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Editing ${dealer.name}...')));
  }

  void _showDealerActions(Dealer dealer) {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
          ),
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.edit, color: theme.colorScheme.onPrimary.withOpacity(0.7)),
                title: Text(
                  'Edit Dealer',
                  style: TextStyle(color: theme.colorScheme.onPrimary),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _editDealer(dealer);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: theme.colorScheme.error),
                title: Text(
                  'Delete Dealer',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  if (dealer.id != null) {
                    _deleteDealer(dealer.id!);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error: Dealer ID is missing.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
              ListTile(
                title: Center(
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: theme.colorScheme.onPrimary.withOpacity(0.7)),
                  ),
                ),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Text(
            'Manage Your Dealers',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Dealer>>(
            future: _dealersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: theme.colorScheme.primary),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    'No dealers found for this user.',
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                  ),
                );
              }
              final dealers = snapshot.data!;
              return ListView.builder(
                controller: widget.scrollController,
                itemCount: dealers.length,
                itemBuilder: (context, index) {
                  final dealer = dealers[index];
                  return ListTile(
                    leading: Icon(Icons.store_outlined, color: theme.colorScheme.primary),
                    title: Text(
                      dealer.name,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      dealer.address,
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Icon(
                      Icons.more_vert,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
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

// --- (_LogoutButton class remains the same) ---
class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ElevatedButton.icon(
      icon: const Icon(Icons.logout),
      label: const Text('LOG OUT'),
      onPressed: () async {
        await AuthService().logout();
        if (context.mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.error,
        foregroundColor: theme.colorScheme.onError,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }
}