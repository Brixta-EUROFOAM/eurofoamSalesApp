import 'package:flutter/material.dart';

// This screen is from your first README, now updated with the Admin Portal.

class AppSelectorScreen extends StatelessWidget {
  const AppSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.background,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onBackground,
                  ),
                ),
                Text(
                  'Please select your portal to continue.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 48),

                // --- Button 1: Salesforce (Existing App) ---
                _PortalCard(
                  theme: theme,
                  icon: Icons.storefront_outlined,
                  title: 'Salesforce Portal',
                  subtitle: 'For internal employees and sales teams.',
                  onTap: () {
                    // This will navigate to your OLD login flow
                    Navigator.of(context).pushNamed('/salesforce_login');
                  },
                ),
                
                const SizedBox(height: 24),

                // --- Button 2: Contractor (New App) ---
                _PortalCard(
                  theme: theme,
                  icon: Icons.construction_outlined,
                  title: 'Contractor Portal',
                  subtitle: 'For petty contractors and partners.',
                  onTap: () {
                    // This will navigate to your NEW login flow
                    Navigator.of(context).pushNamed('/contractor_login');
                  },
                ),

                const SizedBox(height: 24),

                // --- ✅ NEW Button 3: Admin Portal ---
                _PortalCard(
                  theme: theme,
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Admin Portal',
                  subtitle: 'For TSO and internal staff.',
                  onTap: () {
                    // This will navigate to your NEW Admin login flow
                    Navigator.of(context).pushNamed('/admin_login');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// A simple helper widget for the buttons
class _PortalCard extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PortalCard({
    required this.theme,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(
                icon, 
                size: 40, 
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right, 
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}