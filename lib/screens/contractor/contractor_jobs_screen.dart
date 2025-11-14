import 'package:assetarchiverflutter/models/mason_model.dart';
import 'package:assetarchiverflutter/models/scheme_enrollment_model.dart';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as dev;

enum ScreenState { loading, notEnrolled, enrolledPending, enrolledApproved }

class ContractorJobsScreen extends StatefulWidget {
  final Mason mason; // RESTORED: Must receive the Mason object here
  const ContractorJobsScreen({super.key, required this.mason});

  @override
  State<ContractorJobsScreen> createState() => _ContractorJobsScreenState();
}

class _ContractorJobsScreenState extends State<ContractorJobsScreen> {
  ScreenState _screenState = ScreenState.loading;
  final ApiService _api = ApiService();
  List<SchemeEnrollment> _enrollments = [];
  
  // NOTE: This is a placeholder ID. In a real app, this should come from a central configuration/API
  static const String _defaultSchemeId = 'd0c41829-5775-4d7a-8f78-3a936a285d8e'; 

  @override
  void initState() {
    super.initState();
    // Start fetching enrollment status immediately when the Mason object is available
    _fetchEnrollmentStatus();
  }

  // Use didUpdateWidget to re-fetch if the parent sends a new Mason object (e.g., status refresh)
  @override
  void didUpdateWidget(ContractorJobsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mason.id != oldWidget.mason.id) {
      _fetchEnrollmentStatus();
    }
  }

  Future<void> _fetchEnrollmentStatus() async {
    final masonId = widget.mason.id;

    if (masonId == null) {
      dev.log('Mason ID missing. Cannot fetch schemes.', name: 'Scheme');
      if (mounted) setState(() => _screenState = ScreenState.notEnrolled); 
      return;
    }

    if (mounted) setState(() => _screenState = ScreenState.loading);

    final schemes = await _api.fetchEnrolledSchemes(masonId);

    if (mounted) {
      if (schemes.isEmpty) {
        setState(() {
          _enrollments = [];
          _screenState = ScreenState.notEnrolled;
        });
      } else {
        // Find the enrollment for the default scheme, or use the first one found
        final currentEnrollment = schemes.firstWhere(
          (e) => e.schemeId == _defaultSchemeId,
          orElse: () => schemes.first,
        );
        
        setState(() {
          _enrollments = schemes;
          switch (currentEnrollment.status) {
            case 'approved':
              _screenState = ScreenState.enrolledApproved;
              break;
            case 'pending':
              _screenState = ScreenState.enrolledPending;
              break;
            default:
              _screenState = ScreenState.notEnrolled; // Treat unknown status as needing enrollment
          }
        });
      }
    }
  }
  
  Future<void> _enrollInScheme() async {
    final masonId = widget.mason.id;
    if (masonId == null) return;

    if (mounted) setState(() => _screenState = ScreenState.loading);

    final enrollment = await _api.enrollMasonInScheme(
      masonId: masonId, 
      schemeId: _defaultSchemeId
    );

    if (mounted) {
      if (enrollment != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enrollment successful! Awaiting admin approval.')),
        );
        // Refresh status to show the pending screen
        await _fetchEnrollmentStatus(); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enrollment failed. Please try again.')),
        );
        // Revert state if necessary, or just remain in 'notEnrolled'
        setState(() => _screenState = ScreenState.notEnrolled);
      }
    }
  }

  Widget _buildEnrolledSchemeView() {
    // Safely get the active scheme details
    final activeEnrollment = _enrollments.isNotEmpty 
        ? _enrollments.firstWhere(
            (e) => e.status == 'approved' || e.schemeId == _defaultSchemeId, 
            orElse: () => _enrollments.first,
          )
        : null;

    final schemeName = activeEnrollment?.scheme?.name ?? 'Reward Scheme';
    final pointsPerUnit = activeEnrollment?.scheme?.pointsPerUnit ?? 0;
    final mason = widget.mason;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.star, size: 80, color: Colors.amber),
          const SizedBox(height: 16),
          Text('Welcome to $schemeName!', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Your Current Points: ${mason.pointsBalance}', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Text('You earn $pointsPerUnit points per unit purchase.', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 48),
          
          // Show the original job list below the scheme banner
          _buildJobList(context),
        ],
      ),
    );
  }

  Widget _buildNotEnrolledView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, size: 80, color: Colors.orange),
            const SizedBox(height: 16),
            Text('Maximize Your Earnings!', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('Join our Contractor Rewards Scheme to start earning points for every unit of cement you purchase for your projects.', 
              textAlign: TextAlign.center, 
              style: Theme.of(context).textTheme.titleMedium
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _enrollInScheme,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange, 
                minimumSize: const Size(double.infinity, 50)
              ),
              child: const Text('ENROLL NOW'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPendingApprovalView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.access_time_filled, size: 80, color: Colors.blueGrey),
            const SizedBox(height: 16),
            Text('Enrollment Pending', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('Your application to the rewards scheme has been submitted and is awaiting approval from an administrator.', 
              textAlign: TextAlign.center, 
              style: Theme.of(context).textTheme.titleMedium
            ),
            const SizedBox(height: 32),
            Text('We will notify you once approved!', style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLoadingView() {
    return const Center(child: CircularProgressIndicator());
  }
  
  Widget _buildJobList(BuildContext context) {
    // This is your original jobs placeholder, now integrated into the scheme view
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 48),
        Text("Assigned Jobs (For Reference)", style: Theme.of(context).textTheme.headlineSmall),
        // Placeholder UI from your CONTRACTOR.md file
        Text("Upcoming Jobs", style: Theme.of(context).textTheme.titleLarge),
        Card(
          child: ListTile(
            leading: const Icon(Icons.construction, color: Colors.orange),
            title: const Text("Job: Fix Leaking Pipe"),
            subtitle: const Text("Site: ABC Apartments, Site 10B"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to Work Report Form
            },
          ),
        ),
        // ... (rest of the placeholder jobs list) ...
        Card(
            child: ListTile(
              leading: const Icon(Icons.construction, color: Colors.orange),
              title: const Text("Job: Install New Fixture"),
              subtitle: const Text("Site: Downtown Plaza, Unit 5"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 24),
          Text("Completed Jobs", style: Theme.of(context).textTheme.titleLarge),
          Card(
            child: ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text("Job: Repaired Generator"),
              subtitle: const Text("Site: Hilltop Towers"),
              onTap: () {},
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;

    switch (_screenState) {
      case ScreenState.loading:
        bodyContent = _buildLoadingView();
        break;
      case ScreenState.notEnrolled:
        bodyContent = _buildNotEnrolledView();
        break;
      case ScreenState.enrolledPending:
        bodyContent = _buildPendingApprovalView();
        break;
      case ScreenState.enrolledApproved:
        bodyContent = SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: _buildEnrolledSchemeView()
        );
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contractor Dashboard'),
      ),
      body: bodyContent,
    );
  }
}