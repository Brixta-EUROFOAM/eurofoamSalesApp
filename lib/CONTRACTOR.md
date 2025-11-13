Contractor Portal - Technical README & Project Plan

1. Overview & Core Purpose

This document outlines the full project structure and architecture for the new "Petty Contractor Portal." This portal is a second, distinct application "hung" on the main app shell, designed for a different user base (contractors) with a completely different workflow.

User Base: Third-party petty contractors.

Authentication: Phone Number + OTP (via Firebase Auth).

Core Workflow: This app is task-oriented, not sales-oriented. The user flow is:

Log in.

View a list of assigned "Jobs" (tasks).

Select a job.

Complete the job (e.g., a technical fix, an installation).

Submit a simple "Work Completion Report" with photos.

2. The "Dual Boot" Authentication Flow

This is the high-level authentication flow from app launch to the contractor's dashboard.

User Launch: User opens the app and lands on app_selector_screen.dart (File 1).

Portal Selection: User taps "Contractor Portal."

Navigation: App navigates to /contractor_login.

OTP Login: contractor_login_screen.dart (File 4) is shown.

User enters their phone number (e.g., +91...).

_sendOtp is called.

FirebaseAuth.instance.verifyPhoneNumber sends an OTP to the user's phone.

OTP Verification:

User enters the 6-digit OTP.

_verifyOtp is called.

PhoneAuthProvider.credential is created.

_auth.signInWithCredential(cred) signs the user into Firebase.

Backend Handshake (The "Real" Login):

_finishBackendHandshake is called.

The app gets the Firebase idToken from the signed-in user.

This idToken is sent to our backend at a new endpoint (e.g., POST /api/auth/contractor-login).

Our backend verifies the Firebase token, finds or creates a user with that phone number, and generates our own app-specific JWT (just like it does for Salesforce login).

The backend returns the Employee object (with role: 'CONTRACTOR') and the app_jwt.

Navigation:

The app saves the app_jwt to secure storage.

The app navigates to /contractor_home, passing the Employee object as an argument.

3. Proposed Project Structure (New Files)

This is the file structure we will build for the contractor portal.

lib/
├── screens/
│   ├── auth/
│   │   ├── app_selector_screen.dart     # (DONE) The "dual boot" selector.
│   │   ├── contractor_login_screen.dart # (DONE) The OTP login UI.
│   │   ├── salesforce_splash_screen.dart # (DONE) Salesforce auto-login.
│   │   └── login_screen.dart            # (DONE) The Salesforce login UI.
│   │
│   ├── contractor/  <-- ✅ NEW FOLDER
│   │   ├── contractor_nav_screen.dart   # (NEXT) The "App Shell" for contractors.
│   │   ├── contractor_jobs_screen.dart  # (NEXT) The main dashboard/job list.
│   │   └── contractor_profile_screen.dart # (NEXT) A simple profile page.
│   │
│   ├── forms/
│   │   ├── contractor_work_report.dart  # (NEXT) A "lite" DVR for contractors.
│   │   └── ... (your existing forms)
│   │
│   └── ... (your other screens)
│
├── models/
│   ├── contractor_job_model.dart        # (NEXT) A model for a single "Job"
│   └── ... (your existing models)
│
└── main.dart                          # (DONE) The main app router.


4. Key File: contractor_nav_screen.dart (The New App Shell)

This is the contractor's equivalent of your NavScreen. It will be a simple, 2-tab interface: Jobs and Profile.

📍 Sample Code for lib/screens/contractor/contractor_nav_screen.dart

import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:assetarchiverflutter/screens/contractor/contractor_jobs_screen.dart';
import 'package:assetarchiverflutter/screens/contractor/contractor_profile_screen.dart';
import 'package:flutter/material.dart';

class ContractorNavScreen extends StatefulWidget {
  final Employee employee;
  const ContractorNavScreen({super.key, required this.employee});

  @override
  State<ContractorNavScreen> createState() => _ContractorNavScreenState();
}

class _ContractorNavScreenState extends State<ContractorNavScreen> {
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
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Assigned Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        // You can style this to match your app theme
      ),
    );
  }
}


5. Feature: Contractor Jobs List

This is the "dashboard" for the contractor. It's a simple list of tasks assigned to them.

📍 Sample Code for lib/screens/contractor/contractor_jobs_screen.dart

import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:flutter/material.dart';
// TODO: import 'package:assetarchiverflutter/models/contractor_job_model.dart';
// TODO: import 'package:assetarchiverflutter/api/api_service.dart';

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

  void _loadJobs() {
    // setState(() {
    //   _jobsFuture = _apiService.fetchContractorJobs(widget.employee.id);
    // });
  }

  void _onJobTapped(dynamic /*ContractorJob*/ job) {
    // TODO: Navigate to the Work Report Form
    // Navigator.of(context).push(MaterialPageRoute(
    //   builder: (context) => ContractorWorkReportForm(job: job),
    // ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assigned Jobs'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadJobs(),
        // TODO: Build a FutureBuilder for _jobsFuture
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Placeholder UI
            Text("Upcoming Jobs", style: Theme.of(context).textTheme.headlineSmall),
            Card(
              child: ListTile(
                leading: Icon(Icons.construction, color: Colors.orange),
                title: Text("Job: Fix Leaking Pipe"),
                subtitle: Text("Site: ABC Apartments, Site 10B"),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  // _onJobTapped(job);
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.construction, color: Colors.orange),
                title: Text("Job: Install New Fixture"),
                subtitle: Text("Site: Downtown Plaza, Unit 5"),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  // _onJobTapped(job);
                },
              ),
            ),
            const SizedBox(height: 24),
            Text("Completed Jobs", style: Theme.of(context).textTheme.headlineSmall),
            Card(
              child: ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text("Job: Repaired Generator"),
                subtitle: Text("Site: Hilltop Towers"),
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}


6. Feature: Contractor Work Report

This is the contractor's "DVR-Lite." When they tap a job, this form opens.

📍 Sample Code for lib/screens/forms/contractor_work_report.dart

import 'package:flutter/material.dart';
// TODO: import 'package:image_picker/image_picker.dart';
// TODO: import 'dart:io';

class ContractorWorkReportForm extends StatefulWidget {
  final dynamic /*ContractorJob*/ job;
  const ContractorWorkReportForm({super.key, required this.job});

  @override
  State<ContractorWorkReportForm> createState() => _ContractorWorkReportFormState();
}

class _ContractorWorkReportFormState extends State<ContractorWorkReportForm> {
  final _remarksController = TextEditingController();
  // File? _beforeImage;
  // File? _afterImage;
  bool _isLoading = false;

  Future<void> _takePhoto(String type) async {
    // TODO: Implement image_picker logic
    // final ImagePicker picker = ImagePicker();
    // final XFile? image = await picker.pickImage(source: ImageSource.camera);
    // if (image != null) {
    //   setState(() {
    //     if (type == 'before') _beforeImage = File(image.path);
    //     if (type == 'after') _afterImage = File(image.path);
    //   });
    // }
  }

  Future<void> _submitReport() async {
    setState(() => _isLoading = true);
    // 1. TODO: Upload _beforeImage to R2, get URL
    // 2. TODO: Upload _afterImage to R2, get URL
    // 3. TODO: Call new API endpoint:
    //    await _apiService.submitWorkReport(
    //      jobId: widget.job.id,
    //      remarks: _remarksController.text,
    //      beforeImageUrl: beforeUrl,
    //      afterImageUrl: afterUrl,
    //    );
    // 4. TODO: Navigate back
    //    Navigator.of(context).pop();
    await Future.delayed(const Duration(seconds: 1)); // Placeholder
    setState(() => _isLoading = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Submit Work Report"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Job: ${widget.job.title}", style: Theme.of(context).textTheme.headlineSmall),
            Text("Site: ${widget.job.location}", style: Theme.of(context).textTheme.titleMedium),
            
            const SizedBox(height: 24),
            
            // --- Photo Uploads ---
            _buildPhotoCard(
              context,
              title: "Before Photo",
              icon: Icons.camera_alt_outlined,
              // imageFile: _beforeImage,
              onTap: () => _takePhoto('before'),
            ),
            const SizedBox(height: 16),
            _buildPhotoCard(
              context,
              title: "After Photo",
              icon: Icons.check_circle_outline,
              // imageFile: _afterImage,
              onTap: () => _takePhoto('after'),
            ),

            const SizedBox(height: 24),

            // --- Remarks ---
            TextFormField(
              controller: _remarksController,
              decoration: const InputDecoration(
                labelText: 'Work Remarks',
                hintText: 'Describe the work completed...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            
            const SizedBox(height: 24),
            
            // --- Submit ---
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _submitReport,
                child: const Text('SUBMIT COMPLETION REPORT'),
              ),
          ],
        ),
      ),
    );
  }

  // Helper for photo card
  Widget _buildPhotoCard(BuildContext context, {
    required String title,
    required IconData icon,
    // required File? imageFile,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 150,
          width: double.infinity,
          // TODO: Add logic to show image
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


7. New Backend API Endpoints Required

To support this new portal, your backend will need to be updated with the following:

POST /api/auth/contractor-login

Body: { "idToken": "..." } (Firebase ID Token)

Action: Verifies the token with Firebase Admin SDK. Finds or creates a user with the given phone number and role: 'CONTRACTOR'. Returns a new app_jwt and Employee object for this user.

This is your new "Hybrid step."

GET /api/tasks/contractor/:userId

Action: Returns a list of all jobs/tasks assigned to this contractor.

Response: [{ "id": "...", "title": "Fix Leak", "location": "...", "status": "Pending", ... }]

POST /api/work-reports

Body: { "jobId": "...", "remarks": "...", "beforeImageUrl": "...", "afterImageUrl": "..." }

Action: Submits the contractor's work report. Should probably mark the original job/task as "Completed."