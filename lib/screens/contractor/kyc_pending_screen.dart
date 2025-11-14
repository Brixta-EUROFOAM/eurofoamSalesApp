// 1. Import the file using a prefix 'as MasonAuth'
import 'package:assetarchiverflutter/api/firebase_auth.dart' as MasonAuth; 
import 'package:flutter/material.dart';

// --- ✅ NEW IMPORTS ---
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:assetarchiverflutter/models/mason_model.dart';
// --- END NEW IMPORTS ---

// --- ✅ CONVERTED TO STATEFULWIDGET ---
class KycPendingScreen extends StatefulWidget {
  // It MUST receive the mason object to be able to refresh
  final Mason mason; 
  const KycPendingScreen({super.key, required this.mason});

  @override
  State<KycPendingScreen> createState() => _KycPendingScreenState();
}

class _KycPendingScreenState extends State<KycPendingScreen> {
  final ApiService _api = ApiService();

  Future<void> _checkStatus() async {
    if (widget.mason.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Mason ID is missing.')),
      );
      return;
    }

    try {
      final newMason = await _api.fetchMasonById(widget.mason.id!);
      
      if (newMason.kycStatus == 'approved') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Congratulations! Your KYC has been approved.'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate to home, which will now route to the dashboard
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/contractor_home', 
            (r) => false,
            arguments: newMason.toJson(), // Pass the full, updated mason data
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Your KYC is still pending.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to check status: $e')),
        );
      }
    }
  }

  void _logout() {
    // 2. Use the prefix and the correct class name 'AuthService'
    MasonAuth.AuthService(baseUrl: 'https://myserverbymycoco.onrender.com').logout();
    Navigator.of(context).pushNamedAndRemoveUntil('/selector', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Status: Pending'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Log Out',
          ),
        ],
        automaticallyImplyLeading: false, // Don't show back button
      ),
      // --- ✅ ADDED REFRESHINDICATOR ---
      body: RefreshIndicator(
        onRefresh: _checkStatus,
        child: Center(
          // ListViews are needed for RefreshIndicator to work on empty screens
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.15),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.hourglass_top,
                      size: 80,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Submission Received',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your KYC documents are pending approval from a TSO. Pull down to refresh your status.',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}