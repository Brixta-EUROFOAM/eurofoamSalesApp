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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      // Use a SingleChildScrollView to look good on all screen sizes
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- 1. PROFILE HEADER ---
            CircleAvatar(
              radius: 50,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                mason.name.isNotEmpty ? mason.name[0].toUpperCase() : '?',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              mason.name,
              style: theme.textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              mason.phoneNumber,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),

            // --- 2. INFORMATION CARDS ---
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  _InfoTile(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'KYC Status',
                    trailing: _buildKycChip(mason.kycStatus, theme),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _InfoTile(
                    icon: Icons.star_border_outlined,
                    title: 'Points Balance',
                    trailing: Text(
                      mason.pointsBalance.toString(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // --- 3. OTHER LINKS (Placeholder) ---
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  _InfoTile(
                    icon: Icons.edit_outlined,
                    title: 'Edit Profile',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Navigate to Edit Profile Page
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _InfoTile(
                    icon: Icons.support_agent_outlined,
                    title: 'Contact Support',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Navigate to Support Page
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // --- 4. LOG OUT BUTTON ---
            Card(
              elevation: 0,
              // Use the error color scheme for a "danger" action
              color: theme.colorScheme.errorContainer.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(Icons.logout, color: theme.colorScheme.error),
                title: Text(
                  'Log Out',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.error,
                  ),
                ),
                onTap: () {
                  // Use the prefix and the correct class name
                  MasonAuth.AuthService(
                          baseUrl: 'https://myserverbymycoco.onrender.com')
                      .logout();
                  
                  // --- ✅ BUG FIX: Navigate to '/' (AppSelector) not '/selector' ---
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/', (r) => false);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widget for the KYC Status Chip ---
  Widget _buildKycChip(String status, ThemeData theme) {
    Color color;
    String text;
    switch (status) {
      case 'approved':
        color = Colors.green[700]!;
        text = 'Approved';
        break;
      case 'pending':
        color = Colors.orange[800]!;
        text = 'Pending';
        break;
      default:
        color = theme.colorScheme.error;
        text = 'Rejected / Not Started';
    }
    return Chip(
      label: Text(text,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: color,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

// --- Helper Widget for the Info Tiles ---
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;
  final VoidCallback? onTap;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: trailing,
      onTap: onTap,
    );
  }
}