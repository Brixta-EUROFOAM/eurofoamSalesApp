// lib/screens/contractor/contractor_jobs_screen.dart

import 'package:assetarchiverflutter/models/mason_model.dart';
import 'package:flutter/material.dart';
// TODO: import 'package:assetarchiverflutter/api/api_service.dart';

class ContractorJobsScreen extends StatefulWidget {
  final Mason mason;
  const ContractorJobsScreen({super.key, required this.mason});

  @override
  State<ContractorJobsScreen> createState() => _ContractorJobsScreenState();
}

class _ContractorJobsScreenState extends State<ContractorJobsScreen> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assigned Jobs'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Placeholder UI from your CONTRACTOR.md file
          Text("Upcoming Jobs", style: Theme.of(context).textTheme.headlineSmall),
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
          Text("Completed Jobs", style: Theme.of(context).textTheme.headlineSmall),
          Card(
            child: ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text("Job: Repaired Generator"),
              subtitle: const Text("Site: Hilltop Towers"),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}