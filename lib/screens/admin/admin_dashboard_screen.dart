import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:assetarchiverflutter/models/employee_model.dart'; // --- ✅ IMPORT THE NEW MODEL ---

class AdminDashboard extends StatefulWidget {
  // --- ✅ IT NOW REQUIRES THE LOGGED-IN EMPLOYEE ---
  final Employee employee;
  const AdminDashboard({super.key, required this.employee});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ApiService _api = ApiService();
  late Future<List<dynamic>> _pendingSubmissionsFuture;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    _pendingSubmissionsFuture = _api.fetchPendingKycSubmissions();
  }

  Future<void> _refreshData() async {
    setState(() {
      _fetchData();
    });
  }

  void _navigateToDetail(Map<String, dynamic> submission) async {
    // Navigate to the detail screen and wait for a result
    final bool? didUpdate = await Navigator.of(context).pushNamed(
      '/admin_kyc_detail',
      arguments: submission,
    ) as bool?;

    // If the detail screen returned 'true', it means an action
    // was taken (approve/reject), so we should refresh the list.
    if (didUpdate == true) {
      _refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // --- ✅ PERSONALIZED APP BAR ---
        title: Text('Welcome, ${widget.employee.displayName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
          // TODO: Add a logout button
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _pendingSubmissionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: ${snapshot.error}'),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: RefreshIndicator(
                onRefresh: _refreshData,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                     Center(child: Padding(
                       padding: const EdgeInsets.all(32.0),
                       child: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           Icon(Icons.check_circle_outline, size: 60, color: Colors.green),
                           SizedBox(height: 16),
                           Text('No pending KYC submissions found.'),
                         ],
                       ),
                     )),
                  ],
                ),
              ),
            );
          }

          final submissions = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView.builder(
              itemCount: submissions.length,
              itemBuilder: (context, index) {
                final submission = submissions[index] as Map<String, dynamic>;
                // Assuming the API returns the nested mason object
                final mason = submission['mason'] as Map<String, dynamic>?;
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.person_outline, color: Colors.orange),
                    title: Text(mason?['name'] ?? 'Unknown Mason'),
                    subtitle: Text('Phone: ${mason?['phoneNumber'] ?? 'N/A'}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _navigateToDetail(submission),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}