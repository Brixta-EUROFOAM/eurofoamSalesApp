import 'package:assetarchiverflutter/models/mason_model.dart';
import 'package:flutter/material.dart';
import 'contractor_jobs_screen.dart';
import 'contractor_profile_screen.dart';
import 'contractor_drawer.dart';

// --- ✅ 1. ADD IMPORTS ---
import 'dart:async';
import 'package:assetarchiverflutter/api/api_service.dart';
// ---

class ContractorNavScreen extends StatefulWidget {
  final Mason mason;
  const ContractorNavScreen({super.key, required this.mason});

  @override
  State<ContractorNavScreen> createState() => _ContractorNavScreenState();
}

class _ContractorNavScreenState extends State<ContractorNavScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  // --- ✅ 2. ADD STATE FOR MASON AND API ---
  late Mason _currentMason;
  final ApiService _api = ApiService();
  bool _isRefreshing = false;
  // ---

  @override
  void initState() {
    super.initState();
    // --- ✅ 3. INITIALIZE STATE ---
    _currentMason = widget.mason;

    // Pages are built once. The "pending" state will be an overlay.
    // We pass the *state's* _currentMason so it can be updated
    _pages = [
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

  // --- ✅ 4. ADD REFRESH FUNCTION ---
  Future<void> _refreshKycStatus() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    try {
      // This calls GET /api/masons/:id
      // You must use the ID from the local mason object!
      if (_currentMason.id == null) {
        throw Exception("Mason ID is null, cannot refresh.");
      }

      // This uses the 'fetchMasonById' from your ApiService
      final newMason = await _api.fetchMasonById(_currentMason.id!);

      // Update the entire screen's state with the new mason data
      setState(() {
        _currentMason = newMason;
        // Rebuild the pages list with the new mason data
        _pages[0] = ContractorJobsScreen(mason: _currentMason);
        _pages[2] = ContractorProfileScreen(mason: _currentMason);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to refresh status: $e')),
      );
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }
  // ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPending = _currentMason.kycStatus == 'pending';

    return Scaffold(
      // The drawer is attached here
      // It is also disabled when pending
      drawer: isPending ? null : ContractorDrawer(mason: _currentMason),

      // --- ✅ 5. BODY IS NOW A COLUMN ---
      body: Column(
        children: [
          // --- (YOUR FLOW) THE BANNER ---
          if (isPending)
            _PendingBanner(
              onRefresh: _refreshKycStatus,
              isRefreshing: _isRefreshing,
            ),

          // --- (YOUR FLOW) THE APP (DISABLED) ---
          Expanded(
            // This widget disables all taps on the app content
            // when KYC is pending.
            child: AbsorbPointer(
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
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard_outlined),
            activeIcon: Icon(Icons.card_giftcard),
            label: 'Gift',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        type: BottomNavigationBarType.fixed, // Good for 3+ items
        backgroundColor: theme.cardColor,
        selectedItemColor: Colors.orange, // Contractor brand color
        unselectedItemColor: Colors.grey[600],
        selectedFontSize: 12,
        unselectedFontSize: 12,
        currentIndex: _selectedIndex,
        // --- ✅ 6. DISABLE TAPS ON NAV BAR ---
        onTap: isPending ? null : _onItemTapped,
        elevation: 8,
      ),
    );
  }
}

// --- ✅ 7. (NEW) PENDING BANNER WIDGET ---
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
// ---

// --- ✅ 8. ADDED A Reusable Placeholder Screen ---
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