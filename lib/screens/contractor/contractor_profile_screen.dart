// lib/screens/contractor/contractor_profile_screen.dart

// 1. Import the file using a prefix 'as MasonAuth'
import 'package:assetarchiverflutter/api/firebase_auth.dart' as MasonAuth; 
import 'package:assetarchiverflutter/models/mason_model.dart';
import 'package:flutter/material.dart';

class ContractorProfileScreen extends StatelessWidget {
  final Mason mason;
  const ContractorProfileScreen({super.key, required this.mason});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome, ${mason.name}'),
            Text('Status: ${mason.kycStatus.toUpperCase()}'),
            Text('Points: ${mason.pointsBalance}'),
            const SizedBox(height: 40),
            ElevatedButton(
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
    );
  }
}