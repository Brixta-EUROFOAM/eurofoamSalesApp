// lib/screens/employee_management/employee_profile_screen.dart
import 'dart:async';
import 'package:assetarchiverflutter/models/employee_model.dart';
// import 'package:assetarchiverflutter/widgets/reusableglasscard.dart'; // <-- REMOVED
import 'package:flutter/material.dart';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:assetarchiverflutter/models/dealer_model.dart';
import 'package:assetarchiverflutter/api/auth_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart'; 
// --- NEW IMPORTS ---
import 'package:provider/provider.dart';
import 'package:assetarchiverflutter/widgets/theme_provider.dart';
// --- END NEW IMPORTS ---

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
    // --- ✅ BUG FIX: Your original code was correct. We MUST parse the String ID to an int. ---
    // This is LINE 78
    final employeeId = int.parse(widget.employee.id); 

    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final formatter = DateFormat('yyyy-MM-dd');
    final startDate = formatter.format(firstDayOfMonth);
    final endDate = formatter.format(lastDayOfMonth);

    // --- ✅ BUG FIX: Pass the 'employeeId' (int) to all API calls ---
    final results = await Future.wait([
      _apiService.fetchDvrsForUser(employeeId, startDate: startDate, endDate: endDate),     // Line 83
      _apiService.fetchTvrsForUser(employeeId, startDate: startDate, endDate: endDate),     // Line 84
      _apiService.fetchPjpsForUser(employeeId, startDate: startDate, endDate: endDate),     // Line 85
      _apiService.fetchDealers(userId: employeeId),                               // Line 86
      _apiService.fetchDailyTasksForUser(employeeId, status: 'Completed'),            // Line 87
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

  @override
  Widget build(BuildContext
    context) {
    // --- Get theme and provider ---
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    // --- END ---

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
              padding: const EdgeInsets.all(16.0),
              children: [
                Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        getInitials(),
                        style: textTheme.headlineLarge?.copyWith(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.employee.displayName,
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.employee.email ?? 'No email',
                      style: textTheme.bodyLarge?.copyWith(
                        color: textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Chip(
                      avatar: Icon(
                        Icons.work_outline,
                        color: textTheme.bodyMedium?.color,
                        size: 18,
                      ),
                      label: Text(
                        _capitalize(widget.employee.role ?? 'Employee'),
                        style: textTheme.bodyMedium,
                      ),
                      backgroundColor: theme.colorScheme.surface.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: theme.colorScheme.onSurface.withOpacity(0.1),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.description_outlined,
                        label: 'Reports (This Month)',
                        value: stats.monthlyReportCount.toString(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.store_mall_directory_outlined,
                        label: 'Manage Dealers',
                        value: stats.allTimeDealerCount.toString(),
                        onTap: _showManageDealersSheet,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.checklist_rtl_outlined,
                        label: 'PJPs (This Month)',
                        value: stats.monthlyPjpCount.toString(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.task_alt_outlined,
                        label: 'Tasks Done',
                        value: stats.allTimeCompletedTasksCount.toString(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _PerformanceChart(
                  reportCount: stats.monthlyReportCount.toDouble(),
                  pjpCount: stats.monthlyPjpCount.toDouble(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.event_note_outlined,
                        label: 'Apply for Leave',
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.map_outlined,
                        label: 'Brand Mapping',
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
                
                // --- ✅ NEW: THEME TOGGLE ADDED ---
                const Divider(height: 48),
                Text(
                  'Theme Preference',
                  style: textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
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
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.selected)) {
                          return theme.colorScheme.secondary; // Orange
                        }
                        return theme.colorScheme.surface; // Card color
                      },
                    ),
                    foregroundColor: MaterialStateProperty.resolveWith<Color?>(
                       (Set<MaterialState> states) {
                        if (states.contains(MaterialState.selected)) {
                          return theme.colorScheme.onSecondary; // Black
                        }
                        return theme.colorScheme.onSurface.withOpacity(0.7);
                      },
                    ),
                  ),
                ),
                // --- END NEW: THEME TOGGLE ---

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

// --- (PerformanceChart class remains the same) ---
class _PerformanceChart extends StatelessWidget {
  final double reportCount;
  final double pjpCount;

  const _PerformanceChart({required this.reportCount, required this.pjpCount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.military_tech_outlined,
                  color: Colors.amber,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Text(
                  'MONTHLY PERFORMANCE (${DateFormat('MMMM').format(DateTime.now())})',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 150,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (reportCount > pjpCount ? reportCount : pjpCount) * 1.2 + 5,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Colors.blueGrey,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        String label = rod.toY.round().toString();
                        return BarTooltipItem(
                          label,
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                    handleBuiltInTouches: true,
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => _getBottomTitles(value, meta, theme),
                        reservedSize: 38,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: [
                    _makeBarGroup(0, reportCount, Colors.blueAccent),
                    _makeBarGroup(1, pjpCount, Colors.amber),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 22,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
        ),
      ],
    );
  }

  static Widget _getBottomTitles(double value, TitleMeta meta, ThemeData theme) {
    final style = TextStyle(
      color: theme.colorScheme.onSurface.withOpacity(0.7),
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    
    Widget text;
    switch (value.toInt()) {
      case 0:
        text = Text('Reports', style: style);
        break;
      case 1:
        text = Text('PJPs', style: style);
        break;
      default:
        text = Text('', style: style);
        break;
    }
    return SideTitleWidget(axisSide: meta.axisSide, child: text);
  }
}

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
          // --- ✅ BUG FIX: The employeeId is a String, but the API needs an int. ---
          // This is LINE 486
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
    // ... (rest of this function is fine) ...
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

// --- (_StatCard class remains the same) ---
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    icon, 
                    color: theme.colorScheme.onSurface.withOpacity(0.7), 
                    size: 28
                  ),
                  Text(
                    value,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label, 
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- (_ActionCard class remains the same) ---
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(
                icon, 
                color: theme.colorScheme.onSurface, 
                size: 32
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
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

