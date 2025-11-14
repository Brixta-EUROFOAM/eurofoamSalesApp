// lib/screens/contractor/contractor_jobs_screen.dart
import 'package:assetarchiverflutter/models/mason_model.dart';
import 'package:assetarchiverflutter/models/scheme_enrollment_model.dart';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as dev;

enum ScreenState { loading, notEnrolled, enrolledPending, enrolledApproved }

class ContractorJobsScreen extends StatefulWidget {
  final Mason mason;
  const ContractorJobsScreen({super.key, required this.mason});

  @override
  State<ContractorJobsScreen> createState() => _ContractorJobsScreenState();
}

class _ContractorJobsScreenState extends State<ContractorJobsScreen> {
  ScreenState _screenState = ScreenState.loading;
  final ApiService _api = ApiService();
  List<SchemeEnrollment> _enrollments = [];
  
  static const String _defaultSchemeId = 'd0c41829-5775-4d7a-8f78-3a936a285d8e'; 

  @override
  void initState() {
    super.initState();
    _fetchEnrollmentStatus();
  }

  @override
  void didUpdateWidget(ContractorJobsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mason.id != oldWidget.mason.id) {
      _fetchEnrollmentStatus();
    }
  }

  Future<void> _fetchEnrollmentStatus() async {
    // (This function is unchanged)
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
              _screenState = ScreenState.notEnrolled;
          }
        });
      }
    }
  }
  
  Future<void> _enrollInScheme() async {
    // (This function is unchanged and will just sit here until you need it)
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
        await _fetchEnrollmentStatus(); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enrollment failed. Please try again.')),
        );
        setState(() => _screenState = ScreenState.notEnrolled);
      }
    }
  }

  // --- (This view is unchanged) ---
  Widget _buildEnrolledSchemeView() {
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
          _buildJobList(context),
        ],
      ),
    );
  }

  // --- ✅ 1. THIS IS THE NEW INFORMATIONAL VIEW ---
  Widget _buildSchemeDetailsView() {
    final theme = Theme.of(context);

    // No Stack, no button. Just a scrollable list of info.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // --- Main Offer Card ---
          Card(
            elevation: 2,
            shadowColor: Colors.black.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mason Gifting',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dual Points Offer',
                    style: theme.textTheme.headlineLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '2X POINTS',
                    style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // --- 4 Info Cards ---
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.25,
            children: const [
              _InfoCard(
                icon: Icons.person_outline,
                title: 'Eligibility',
                body: 'Open to all registered masons',
              ),
              _InfoCard(
                icon: Icons.add_shopping_cart,
                title: 'How to Earn',
                body: 'Lift bags to earn 2 points per bag',
              ),
              _InfoCard(
                icon: Icons.calendar_today_outlined,
                title: 'Caps & Validity',
                body: 'Maximum of 50 points per week. Offer valid through May 31, 2024',
              ),
              _InfoCard(
                icon: Icons.check_circle_outline,
                title: 'Claim Process',
                body: 'Submit bag lifting proof for verification. Requires admin review',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // --- Link Tiles ---
          _LinkTile(
            icon: Icons.quiz_outlined,
            title: 'FAQ',
            onTap: () {},
          ),
          _LinkTile(
            icon: Icons.support_agent_outlined,
            title: 'Contact Support',
            onTap: () {},
          ),
        ],
      ),
    );
  }
  
  // --- (This view is unchanged) ---
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
  
  // --- (This view is unchanged) ---
  Widget _buildLoadingView() {
    return const Center(child: CircularProgressIndicator());
  }
  
  // --- (This view is unchanged) ---
  Widget _buildJobList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 48),
        Text("Assigned Jobs (For Reference)", style: Theme.of(context).textTheme.headlineSmall),
        Text("Upcoming Jobs", style: Theme.of(context).textTheme.titleLarge),
        Card(
          child: ListTile(
            leading: const Icon(Icons.construction, color: Colors.orange),
            title: const Text("Job: Fix Leaking Pipe"),
            subtitle: const Text("Site: ABC Apartments, Site 10B"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ),
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
    String appBarTitle;

    switch (_screenState) {
      case ScreenState.loading:
        appBarTitle = 'Loading...';
        bodyContent = _buildLoadingView();
        break;
      case ScreenState.notEnrolled:
        appBarTitle = 'Scheme Details'; // From screenshot
        bodyContent = _buildSchemeDetailsView(); // The new UI
        break;
      case ScreenState.enrolledPending:
        appBarTitle = 'Enrollment Pending';
        bodyContent = _buildPendingApprovalView();
        break;
      case ScreenState.enrolledApproved:
        appBarTitle = 'Your Jobs & Scheme'; 
        bodyContent = SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: _buildEnrolledSchemeView()
        );
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        // --- ✅ 2. REMOVED CUSTOM APPBAR COLORING ---
        // This will now just follow your app's theme
      ),
      body: bodyContent,
    );
  }
}


// --- ✅ 3. HELPER WIDGETS FOR THE NEW UI ---
// (These are styled to work with both light and dark themes)

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _InfoCard({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      // Use a subtle color from the theme
      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              body,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _LinkTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
        title: Text(
          title,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}