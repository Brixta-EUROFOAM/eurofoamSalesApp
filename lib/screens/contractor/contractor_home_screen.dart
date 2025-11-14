// lib/screens/contractor/contractor_home_screen.dart
import 'package:assetarchiverflutter/models/mason_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For number input filtering

class ContractorHomeScreen extends StatelessWidget {
  final Mason mason;
  const ContractorHomeScreen({super.key, required this.mason});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // This screen NOW ALWAYS shows the welcome message and the dashboard.
    // The NavScreen will show a banner on top if KYC is needed.
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contractor Home'),
        // You can add the profile icon here if you want
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.account_circle_outlined),
        //     onPressed: () {
        //       // TODO: Navigate to profile
        //     },
        //   ),
        // ],
      ),
      // Use a SingleChildScrollView to prevent overflow
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. WELCOME MESSAGE ---
            Text(
              'Welcome Back,',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              mason.name,
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: 24),

            // --- 2. POINTS CARD ---
            _buildPointsCard(context, mason.pointsBalance),
            
            const SizedBox(height: 24),

            // --- 3. SUBMIT BAGS CARD ---
            _buildSubmitCard(context),

            const SizedBox(height: 32),

            // --- 4. HISTORY LIST ---
            _buildHistoryList(context),
          ],
        ),
      ),
    );
  }

  // --- WIDGET 2: POINTS CARD ---
  Widget _buildPointsCard(BuildContext context, int points) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.primary.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Text(
                  'YOUR POINTS',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  points.toString(), // Use the real mason points
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            // Example of the icon from the screenshot
            // const SizedBox(width: 40),
            // const Icon(
            //   Icons.shopping_bag_outlined, 
            //   size: 60, 
            //   color: Colors.orange,
            // ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET 3: SUBMIT BAGS CARD ---
  Widget _buildSubmitCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Submit Your Bags',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // This is the "Number of bags" text field
            TextField(
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Number of bags',
                prefixIcon: Icon(
                  Icons.shopping_bag_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // The "SUBMIT" button
            ElevatedButton(
              onPressed: () {
                // TODO: Connect to backend
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary, // Dark color
                foregroundColor: theme.colorScheme.onPrimary, // Light text
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'SUBMIT',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 8),
            // The "Pending approval" chip
            Align(
              alignment: Alignment.center,
              child: Chip(
                label: Text(
                  'Pending approval',
                  style:
                      TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold),
                ),
                backgroundColor: Colors.orange[100],
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET 4: HISTORY LIST ---
  Widget _buildHistoryList(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'History',
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        // Placeholder Item 1
        _buildHistoryItem(
          context,
          icon: Icons.shopping_bag_outlined,
          title: '8 bags',
          status: 'Approved',
          color: Colors.green,
        ),
        const Divider(height: 1),
        // Placeholder Item 2
        _buildHistoryItem(
          context,
          icon: Icons.shopping_bag_outlined,
          title: '8 bags',
          status: 'Rejected',
          color: Colors.red,
        ),
        const Divider(height: 1),
        // Placeholder Item 3
        _buildHistoryItem(
          context,
          icon: Icons.shopping_bag_outlined,
          title: '12 bags',
          status: 'Approved',
          color: Colors.green,
        ),
      ],
    );
  }

  // --- Reusable History Item Widget ---
  Widget _buildHistoryItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String status,
    required Color color,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Icon(
        icon,
        size: 30,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(
        title,
        style:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      trailing: Chip(
        label: Text(
          status,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: color,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}