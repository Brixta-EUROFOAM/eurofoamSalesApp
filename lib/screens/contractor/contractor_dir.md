Contractor Portal: Technical README

This document provides a detailed overview and implementation plan for the new "Petty Contractor Portal." It focuses on the main navigation screen (contractor_home_screen.dart) and the new child screens required to build this user flow.

1. Overview & Purpose

The contractor_home_screen.dart file is the main app shell for any user who logs in with the "Contractor" role. It is the contractor's equivalent of NavScreen.

Its sole purpose is to provide the main navigation structure (i.e., the BottomNavigationBar) and host the different pages (tabs) for the contractor's workflow. This workflow is task-oriented, not sales-oriented.

2. User Flow & How to Get Here

This screen is the final destination for the new OTP login flow:

App Launch -> app_selector_screen.dart

User taps "Contractor Portal" -> Navigates to /contractor_login

Login -> contractor_login_screen.dart (User enters Phone + OTP)

Backend Handshake -> _finishBackendHandshake() is called.

The app sends the Firebase ID token to your backend (e.g., POST /api/auth/contractor-login).

Your backend validates the token, finds or creates an Employee with role: 'CONTRACTOR', and returns an Employee object and your app-specific JWT.

Success -> The app navigates to /contractor_home, passing the Employee object:

// Inside _finishBackendHandshake in contractor_login_screen.dart
Employee contractor = Employee.fromJson(data['employee']);
Navigator.of(context).pushNamedAndRemoveUntil(
  '/contractor_home', 
  (route) => false,
  arguments: contractor, // <-- This is how we get here
);


3. Architecture: StatefulWidget + BottomNavigationBar

To function as an app shell, your contractor_home_screen.dart file must be converted from a simple StatelessWidget (your current placeholder) into a StatefulWidget.

It will hold the state for the _selectedIndex (which tab is active).

The Scaffold body will be an IndexedStack to preserve the state of each tab as the user switches between them.

The Scaffold will have a BottomNavigationBar to control the _selectedIndex.

4. Paste-Ready Code: contractor_home_screen.dart

This is the full, upgraded code for this file. You can replace your placeholder with this.

📍 lib/screens/contractor/contractor_home_screen.dart

import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:flutter/material.dart';

// --- ✅ NEW IMPORTS ---
// We will create these two new files next
import 'package:assetarchiverflutter/screens/contractor/contractor_jobs_screen.dart';
import 'package:assetarchiverflutter/screens/contractor/contractor_profile_screen.dart';
// ---

/// This is the main "App Shell" for the Contractor Portal.
/// It holds the BottomNavigationBar and switches between pages.
class ContractorHomeScreen extends StatefulWidget {
  final Employee employee;
  const ContractorHomeScreen({super.key, required this.employee});

  @override
  State<ContractorHomeScreen> createState() => _ContractorHomeScreenState();
}

class _ContractorHomeScreenState extends State<ContractorHomeScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      // --- Page 1: The Job List ---
      ContractorJobsScreen(employee: widget.employee),
      
      // --- Page 2: The Profile Screen ---
      ContractorProfileScreen(employee: widget.employee),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        // Style to match your app's theme
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.colorScheme.surface,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.onSurfaceVariant,
        
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'Assigned Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}


5. Child Screen 1: The "Jobs" Dashboard

This screen will be the first tab in your new ContractorHomeScreen. Its job is to fetch and display a list of all tasks assigned to this contractor.

📍 Create this new file at: lib/screens/contractor/contractor_jobs_screen.dart

import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:flutter/material.dart';
// TODO: Import your new model
// import 'package:assetarchiverflutter/models/contractor_job_model.dart';
// TODO: Import your ApiService
// import 'package:assetarchiverflutter/api/api_service.dart';
// TODO: Import the new form we will create
// import 'package:assetarchiverflutter/screens/forms/contractor_work_report.dart';

class ContractorJobsScreen extends StatefulWidget {
  final Employee employee;
  const ContractorJobsScreen({super.key, required this.employee});

  @override
  State<ContractorJobsScreen> createState() => _ContractorJobsScreenState();
}

class _ContractorJobsScreenState extends State<ContractorJobsScreen> {
  // late Future<List<ContractorJob>> _jobsFuture;
  // final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  // TODO: This function will fetch jobs from your new API endpoint
  Future<void> _loadJobs() async {
    // setState(() {
    //   _jobsFuture = _apiService.fetchContractorJobs(widget.employee.id);
    // });
  }

  void _onJobTapped(dynamic /*ContractorJob*/ job) {
    // TODO: Navigate to the Work Report Form
    // This will open the new form to submit a "before/after" photo report
    // Navigator.of(context).push(MaterialPageRoute(
    //   builder: (context) => ContractorWorkReportForm(job: job),
    // ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assigned Jobs'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadJobs,
        // TODO: Replace this ListView with a FutureBuilder for _jobsFuture
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // This is placeholder UI
            Text("Upcoming Jobs", style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: Icon(Icons.construction, color: theme.colorScheme.primary),
                title: const Text("Job: Fix Leaking Pipe"),
                subtitle: const Text("Site: ABC Apartments, Site 10B"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // _onJobTapped(job);
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.construction, color: theme.colorScheme.primary),
                title: const Text("Job: Install New Fixture"),
                subtitle: const Text("Site: Downtown Plaza, Unit 5"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // _onJobTapped(job);
                },
              ),
            ),
            const SizedBox(height: 24),
            Text("Completed Jobs", style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            Card(
              child: ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: const Text("Job: Repaired Generator"),
                subtitle: const Text("Site: Hilltop Towers"),
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}


6. Child Screen 2: The "Contractor Profile"

This will be the second tab. It's a simple screen to show who is logged in and provide a Logout button.

📍 Create this new file at: lib/screens/contractor/contractor_profile_screen.dart

import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:assetarchiverflutter/api/auth_service.dart'; // We can re-use the Salesforce auth service

class ContractorProfileScreen extends StatelessWidget {
  final Employee employee;
  const ContractorProfileScreen({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- Simple Profile Header ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: theme.colorScheme.primary,
                      child: Icon(
                        Icons.construction_outlined, 
                        size: 40, 
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      employee.displayName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      employee.role ?? 'Contractor',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const Spacer(), // Pushes logout button to the bottom

            // --- Logout Button ---
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('LOG OUT'),
              onPressed: () async {
                // TODO: We need a new AuthService().logoutContractor()
                // that also signs out of Firebase
                
                // For now, this will clear the app_jwt
                await AuthService().logout(); 
                
                if (context.mounted) {
                  // Navigate back to the App Selector, not the login screen
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/selector', 
                    (route) => false
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 20), // Padding from bottom
          ],
        ),
      ),
    );
  }
}


7. New Data Model Required

Your new "Jobs" screen needs a data model.

📍 Create this new file at: lib/models/contractor_job_model.dart

import 'dart:convert';

// Helper functions
ContractorJob contractorJobFromJson(String str) =>
    ContractorJob.fromJson(json.decode(str));

class ContractorJob {
  final String id;
  final String title;
  final String description;
  final String location;
  final String status; // e.g., "Pending", "In Progress", "Completed"
  final DateTime assignedDate;
  final String? dealerName; // Optional: The dealer who raised the request
  
  ContractorJob({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.status,
    required this.assignedDate,
    this.dealerName,
  });

  factory ContractorJob.fromJson(Map<String, dynamic> json) {
    return ContractorJob(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Untitled Job',
      description: json['description'] ?? '',
      location: json['location'] ?? 'No location specified',
      status: json['status'] ?? 'Pending',
      assignedDate: DateTime.tryParse(json['assignedDate'] ?? '') ?? DateTime.now(),
      dealerName: json['dealerName']?.toString(),
    );
  }

  // No toJson() needed if the app doesn't create jobs, only reads them.
}


8. New API Endpoints Required

To make this work, your backend (myserverbymycoco.onrender.com) will need these new endpoints:

POST /api/auth/contractor-login:

Body: { "idToken": "..." }

Action: Verifies the Firebase token, finds or creates an Employee with role: 'CONTRACTOR', and returns an Employee object and your app_jwt.

GET /api/contractor/jobs: (or /api/tasks/contractor/:userId)

Action: Returns a list of ContractorJob objects assigned to the logged-in contractor.

POST /api/contractor/work-report:

Action: Submits the new ContractorWorkReportForm.

Body: { "jobId": "...", "remarks": "...", "beforeImageUrl": "...", "afterImageUrl": "..." }