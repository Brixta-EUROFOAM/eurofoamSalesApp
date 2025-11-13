// lib/screens/contractor/contractor_nav_screen.dart

import 'package:assetarchiverflutter/models/mason_model.dart';
import 'package:flutter/material.dart';

// We'll create these two child screens next
import 'contractor_jobs_screen.dart';
import 'contractor_profile_screen.dart';

class ContractorNavScreen extends StatefulWidget {
  final Mason mason;
  const ContractorNavScreen({super.key, required this.mason});

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
      ContractorJobsScreen(mason: widget.mason),
      
      // --- Page 2: The Profile Screen ---
      ContractorProfileScreen(mason: widget.mason),
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
        // Style it to match your app
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}