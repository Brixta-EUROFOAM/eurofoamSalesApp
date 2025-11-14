// lib/screens/contractor/contractor_nav_screen.dart
import 'package:assetarchiverflutter/models/mason_model.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:assetarchiverflutter/api/api_service.dart';

import 'contractor_home_screen.dart';
import 'contractor_jobs_screen.dart';
import 'contractor_profile_screen.dart';
import 'contractor_drawer.dart';

class ContractorNavScreen extends StatefulWidget {
  final Mason mason;
  const ContractorNavScreen({super.key, required this.mason});

  @override
  State<ContractorNavScreen> createState() => _ContractorNavScreenState();
}

class _ContractorNavScreenState extends State<ContractorNavScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  late Mason _currentMason;
  final ApiService _api = ApiService();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _currentMason = widget.mason;

    _pages = [
      ContractorHomeScreen(mason: _currentMason),
      ContractorJobsScreen(mason: _currentMason),
      const _PlaceholderScreen(
        title: 'Gifts & Redemption',
        icon: Icons.card_giftcard_outlined,
      ),
      ContractorProfileScreen(mason: _currentMason),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _refreshKycStatus() async {
    // (This function is unchanged, it's perfect)
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    try {
      if (_currentMason.id == null) {
        throw Exception("Mason ID is null, cannot refresh.");
      }
      final newMason = await _api.fetchMasonById(_currentMason.id!);

      setState(() {
        _currentMason = newMason;
        // Rebuild all pages with the new mason data
        _pages[0] = ContractorHomeScreen(mason: _currentMason);
        _pages[1] = ContractorJobsScreen(mason: _currentMason);
        _pages[3] = ContractorProfileScreen(mason: _currentMason);
      });

      if (newMason.kycStatus == 'approved') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('KYC Approved! Welcome.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('KYC is still pending.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to refresh status: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // We still have the 'pending' banner
    final isPending = _currentMason.kycStatus == 'pending';
    
    // --- ✅ 1. ADD CHECK FOR NEW BANNER ---
    // This is for users who have NOT submitted KYC yet.
    final isKycNeeded = _currentMason.kycStatus == 'none' || 
                        _currentMason.kycStatus == 'rejected';

    return Scaffold(
      drawer: isPending ? null : ContractorDrawer(mason: _currentMason),
      body: Column(
        children: [
          // --- BANNER 1: For 'pending' (Yellow) ---
          if (isPending)
            _PendingBanner(
              onRefresh: _refreshKycStatus,
              isRefreshing: _isRefreshing,
            ),
          
          // --- ✅ 2. ADD NEW BANNER: For 'none' or 'rejected' (Blue) ---
          if (isKycNeeded)
            _KycNeededBanner(
              onTap: () {
                // This is the navigation you wanted!
                // It opens the form you provided.
                Navigator.of(context).pushNamed(
                  '/kyc_onboarding_screen',
                  arguments: _currentMason,
                );
              },
            ),

          // --- App Content ---
          Expanded(
            child: AbsorbPointer(
              // App is ONLY disabled if 'pending', not if 'needed'
              absorbing: isPending, 
              child: IndexedStack(
                index: _selectedIndex,
                children: _pages,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        // (BottomNav is unchanged, it's perfect)
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.construction_outlined), activeIcon: Icon(Icons.construction), label: 'Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.card_giftcard_outlined), activeIcon: Icon(Icons.card_giftcard), label: 'Gift'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.cardColor,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey[600],
        selectedFontSize: 12,
        unselectedFontSize: 12,
        currentIndex: _selectedIndex,
        onTap: isPending ? null : _onItemTapped,
        elevation: 8,
      ),
    );
  }
}

// --- ✅ 3. ADD THE NEW BANNER WIDGET ---
class _KycNeededBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _KycNeededBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        // Using a different color to distinguish from 'pending'
        color: Theme.of(context).colorScheme.primary.withOpacity(0.9),
        padding: EdgeInsets.fromLTRB(
            16, 16 + MediaQuery.of(context).padding.top, 16, 16),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'KYC Verification Required. Tap here to start.',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

// --- (This is your existing 'pending' banner, unchanged) ---
class _PendingBanner extends StatelessWidget {
  final VoidCallback onRefresh;
  final bool isRefreshing;
  const _PendingBanner({required this.onRefresh, required this.isRefreshing});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.amber[700],
      padding: EdgeInsets.fromLTRB(
          16, 16 + MediaQuery.of(context).padding.top, 16, 16),
      child: Row(
        // (content is unchanged)
        children: [
          const Icon(Icons.hourglass_top, color: Colors.white),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'KYC approval is pending.',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          if (isRefreshing)
            const SizedBox(
              width: 20,
              height: 20,
              child:
                  CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          else
            TextButton(
              onPressed: onRefresh,
              child: const Text(
                'Refresh',
                style: TextStyle(
                    color: Colors.white, decoration: TextDecoration.underline),
              ),
            ),
        ],
      ),
    );
  }
}

// --- (This is your existing placeholder, unchanged) ---
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  const _PlaceholderScreen({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 100, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[400],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}