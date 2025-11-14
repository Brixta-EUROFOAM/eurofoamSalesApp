import 'package:assetarchiverflutter/models/mason_model.dart';
import 'package:assetarchiverflutter/api/firebase_auth.dart' as MasonAuth;
import 'package:flutter/material.dart';

class ContractorDrawer extends StatelessWidget {
  final Mason mason;
  const ContractorDrawer({super.key, required this.mason});

  @override
  Widget build(BuildContext context) {
    // Logout function
    void _logout() {
      MasonAuth.AuthService(baseUrl: 'https://myserverbymycoco.onrender.com').logout();
      Navigator.of(context).pushNamedAndRemoveUntil('/selector', (r) => false);
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // --- Drawer Header ---
          UserAccountsDrawerHeader(
            accountName: Text(
              mason.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            accountEmail: Text(mason.phoneNumber),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                mason.name.isNotEmpty ? mason.name[0].toUpperCase() : 'M',
                style: const TextStyle(fontSize: 24, color: Colors.orange),
              ),
            ),
            decoration: const BoxDecoration(
              color: Colors.orange,
            ),
          ),
          
          // --- Menu Items (from your screenshots) ---
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('My Profile'),
            onTap: () {
              // TODO: Navigate to profile screen
              Navigator.of(context).pop(); // close drawer
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_business_outlined),
            title: const Text('Add Bags/Sites'),
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('Account Statement'),
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.card_giftcard_outlined),
            title: const Text('Redemption'),
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.support_agent_outlined),
            title: const Text('Support'),
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
          
          const Divider(),
          
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red.shade700),
            title: Text(
              'Logout',
              style: TextStyle(color: Colors.red.shade700),
            ),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}