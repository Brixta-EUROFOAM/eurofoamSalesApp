// lib/screens/contractor/contractor_jobs_screen.dart
import 'package:assetarchiverflutter/models/mason_model.dart';
import 'package:assetarchiverflutter/models/scheme_enrollment_model.dart';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as dev;
import 'package:intl/intl.dart'; // For formatting dates

// --- ✅ MODIFIED STATE ---
// We simplify the state. We just load the data.
// The UI will be built based on what's in the lists.
enum ScreenState { loading, loaded, error }

class ContractorJobsScreen extends StatefulWidget {
  final Mason mason;
  const ContractorJobsScreen({super.key, required this.mason});

  @override
  State<ContractorJobsScreen> createState() => _ContractorJobsScreenState();
}

class _ContractorJobsScreenState extends State<ContractorJobsScreen> {
  ScreenState _screenState = ScreenState.loading;
  final ApiService _api = ApiService();
  bool _isEnrolling = false;

  // --- ✅ NEW STATE VARIABLES ---
  List<SchemeEnrollment> _enrollments = [];
  List<Scheme> _activeSchemes = [];
  String _error = '';
  // ---

  @override
  void initState() {
    super.initState();
    _loadSchemeData();
  }

  @override
  void didUpdateWidget(ContractorJobsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh data if the mason object itself changes
    if (widget.mason.id != oldWidget.mason.id) {
      _loadSchemeData();
    }
  }

  // --- ✅ RENAMED & UPDATED to fetch BOTH endpoints ---
  Future<void> _loadSchemeData() async {
    final masonId = widget.mason.id;

    if (masonId == null) {
      dev.log('Mason ID missing. Cannot fetch schemes.', name: 'Scheme');
      if (mounted) {
        setState(() {
          _screenState = ScreenState.error;
          _error = 'Your user ID is missing. Cannot fetch schemes.';
        });
      }
      return;
    }

    if (mounted) setState(() => _screenState = ScreenState.loading);

    try {
      // Fetch both lists in parallel
      final results = await Future.wait([
        _api.fetchEnrolledSchemes(masonId),
        _api.fetchActiveSchemes(),
      ]);

      if (mounted) {
        setState(() {
          _enrollments = results[0] as List<SchemeEnrollment>;
          _activeSchemes = results[1] as List<Scheme>;
          _screenState = ScreenState.loaded;
        });
      }
    } catch (e) {
      dev.log('Failed to load scheme data: $e', name: 'Scheme');
      if (mounted) {
        setState(() {
          _screenState = ScreenState.error;
          _error = 'Failed to load scheme data. Please try again.';
        });
      }
    }
  }

  Future<void> _enrollInScheme(String schemeId) async {
    if (_isEnrolling) return;
    setState(() => _isEnrolling = true);

    final masonId = widget.mason.id;
    if (masonId == null) {
      _toast('Cannot enroll: User ID is missing.', isError: true);
      setState(() => _isEnrolling = false);
      return;
    }

    try {
      final enrollment =
          await _api.enrollMasonInScheme(masonId: masonId, schemeId: schemeId);

      if (mounted) {
        if (enrollment != null) {
          _toast('Enrollment successful! Awaiting admin approval.');
          _loadSchemeData(); // Refresh all data
        } else {
          _toast('Enrollment failed. Please try again.', isError: true);
        }
      }
    } catch (e) {
      _toast('An error occurred: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isEnrolling = false);
      }
    }
  }

  void _toast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Colors.green,
      ),
    );
  }

  // --- ✅ NEW: Main UI Builder ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schemes & Offers'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSchemeData,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_screenState) {
      case ScreenState.loading:
        return const Center(child: CircularProgressIndicator());
      case ScreenState.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        );
      case ScreenState.loaded:
        return _buildLoadedView();
    }
  }

  // --- ✅ NEW: Loaded View ---
  Widget _buildLoadedView() {
    // Find schemes the user is NOT enrolled in
    final enrolledSchemeIds = _enrollments.map((e) => e.schemeId).toSet();
    final availableSchemes = _activeSchemes
        .where((s) => !enrolledSchemeIds.contains(s.id))
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // --- 1. Enrolled Schemes Section ---
        Text(
          'Your Enrolled Schemes',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildEnrolledList(),
        
        const SizedBox(height: 24),

        // --- 2. Available Schemes Section ---
        Text(
          'Available Schemes',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildAvailableList(availableSchemes),
      ],
    );
  }

  // --- ✅ NEW: Enrolled List Builder ---
  Widget _buildEnrolledList() {
    if (_enrollments.isEmpty) {
      return Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text('You are not enrolled in any schemes yet.'),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _enrollments.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final enrollment = _enrollments[index];
        final scheme = enrollment.scheme;
        return _SchemeCard(
          scheme: scheme,
          status: enrollment.status, // Pass the enrollment status
          onEnroll: null, // No enroll button for already-enrolled schemes
          isEnrolling: _isEnrolling,
        );
      },
    );
  }

  // --- ✅ NEW: Available List Builder ---
  Widget _buildAvailableList(List<Scheme> availableSchemes) {
    if (availableSchemes.isEmpty) {
      return Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text('No other schemes are available to join right now.'),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: availableSchemes.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final scheme = availableSchemes[index];
        return _SchemeCard(
          scheme: scheme,
          status: null, // No status, it's just available
          onEnroll: () => _enrollInScheme(scheme.id),
          isEnrolling: _isEnrolling,
        );
      },
    );
  }
}

// --- ✅ NEW: Reusable Scheme Card Widget ---
class _SchemeCard extends StatelessWidget {
  final Scheme? scheme;
  final String? status; // 'pending', 'approved', 'rejected', or null
  final VoidCallback? onEnroll;
  final bool isEnrolling;

  const _SchemeCard({
    required this.scheme,
    this.status,
    this.onEnroll,
    required this.isEnrolling,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (scheme == null) {
      return const Card(
        margin: EdgeInsets.only(bottom: 12),
        child: ListTile(title: Text('Scheme details not available.')),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header with Title and Status/Button ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    scheme!.name,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (status != null) // Show status chip
                  _buildStatusChip(status!, theme)
                else if (onEnroll != null) // Show enroll button
                  ElevatedButton(
                    onPressed: isEnrolling ? null : onEnroll,
                    child: isEnrolling 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Enroll'),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // --- Description ---
            if (scheme!.description.isNotEmpty) ...[
              Text(
                scheme!.description,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
            ],

            // --- Details (Dates, Points) ---
            _buildDetailRow(
              theme,
              Icons.calendar_today_outlined,
              'Start Date',
              _formatDate(scheme!.startDate),
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              theme,
              Icons.event_busy_outlined,
              'End Date',
              _formatDate(scheme!.endDate),
            ),
            if (scheme!.pointsPerUnit > 0) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                theme,
                Icons.star_outline,
                'Points per Unit',
                scheme!.pointsPerUnit.toString(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper for status chip
  Widget _buildStatusChip(String status, ThemeData theme) {
    Color color;
    String text;
    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.green;
        text = 'Approved';
        break;
      case 'pending':
        color = Colors.orange;
        text = 'Pending';
        break;
      case 'rejected':
        color = theme.colorScheme.error;
        text = 'Rejected';
        break;
      default:
        color = Colors.grey;
        text = status.toUpperCase();
    }
    return Chip(
      label: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: color,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  // Helper for detail rows
  Widget _buildDetailRow(
      ThemeData theme, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}