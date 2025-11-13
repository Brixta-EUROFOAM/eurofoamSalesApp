// 1. Import the file using a prefix 'as MasonAuth'
import 'package:assetarchiverflutter/api/firebase_auth.dart' as MasonAuth; 
import 'package:flutter/material.dart';

class KycPendingScreen extends StatelessWidget {
  const KycPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Status: Pending'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
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
                'Your KYC documents have been submitted and are now pending approval from a TSO. Please check back later.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextButton(
                onPressed: () {
                  // 2. Use the prefix and the correct class name 'AuthService'
                  MasonAuth.AuthService(baseUrl: 'https://myserverbymycoco.onrender.com').logout();
                  Navigator.of(context).pushNamedAndRemoveUntil('/selector', (r) => false);
                },
                child: const Text('LOG OUT'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}