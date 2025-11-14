// lib/screens/contractor/contractor_home_screen.dart
import 'package:assetarchiverflutter/models/mason_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For number input filtering
import 'dart:async'; // For FutureBuilder

// ✅ NEW IMPORTS
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:assetarchiverflutter/models/bag_lift_model.dart';
import 'package:intl/intl.dart'; // For date formatting
// ---

// ✅ CONVERTED TO STATEFULWIDGET
class ContractorHomeScreen extends StatefulWidget {
  final Mason mason;
  const ContractorHomeScreen({super.key, required this.mason});

  @override
  State<ContractorHomeScreen> createState() => _ContractorHomeScreenState();
}

class _ContractorHomeScreenState extends State<ContractorHomeScreen> {
  // ✅ NEW STATE
  final ApiService _api = ApiService();
  final _bagCountController = TextEditingController();
  late Future<List<BagLift>> _historyFuture;
  bool _isSubmitting = false;
  // ---

  @override
  void initState() {
    super.initState();
    // ✅ Load history on init
    _loadHistory();
  }

  @override
  void dispose() {
    _bagCountController.dispose();
    super.dispose();
  }

  void _loadHistory() {
    if (widget.mason.id == null) {
      // Set future to an error if mason has no ID
      setState(() {
        _historyFuture = Future.error('Mason ID is missing.');
      });
      return;
    }
    setState(() {
      _historyFuture = _api.fetchBagHistory(widget.mason.id!);
    });
  }

  Future<void> _submitBags() async {
    if (_isSubmitting) return;

    final count = int.tryParse(_bagCountController.text);
    if (count == null || count <= 0) {
      _toast('Please enter a valid number of bags.', isError: true);
      return;
    }

    // --- ✅ FIX: We no longer check for dealerId. ---
    // We just get it, and it's fine if it's null.
    final dealerId = widget.mason.dealerId;

    setState(() => _isSubmitting = true);

    try {
      // The apiService.submitBags function already accepts a
      // nullable dealerId (String?), so this will work perfectly.
      await _api.submitBags(
        masonId: widget.mason.id!,
        bagCount: count,
        dealerId: dealerId, // ✅ PASS IT HERE (it's ok if null)
      );
      _toast('Bag submission successful! Awaiting approval.');
      _bagCountController.clear();
      _loadHistory(); // Refresh the history list
    } catch (e) {
      _toast('Submission failed: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _toast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
  // ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Contractor Home')),
      body: RefreshIndicator(
        onRefresh: () async => _loadHistory(),
        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(), // Allows pull-to-refresh
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
                widget.mason.name, // Use widget.mason
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 24),

              // --- 2. POINTS CARD ---
              _buildPointsCard(
                context,
                widget.mason.pointsBalance,
              ), // Use widget.mason

              const SizedBox(height: 24),

              // --- 3. SUBMIT BAGS CARD (NOW WIRED) ---
              _buildSubmitCard(context),

              const SizedBox(height: 32),

              // --- 4. HISTORY LIST (NOW DYNAMIC) ---
              _buildHistoryList(context),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET 2: POINTS CARD (Unchanged) ---
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
                  points.toString(),
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET 3: SUBMIT BAGS CARD (WIRED UP) ---
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
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bagCountController, // ✅ WIRED
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
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitBags, // ✅ WIRED
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'SUBMIT',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
            // ✅ This "Pending" chip is just static UI,
            // the real status is in the history list.
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.center,
              child: Chip(
                label: Text(
                  'Pending approval',
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontWeight: FontWeight.bold,
                  ),
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

  // --- WIDGET 4: HISTORY LIST (DYNAMIC) ---
  Widget _buildHistoryList(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'History',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // ✅ CONVERTED TO FUTUREBUILDER
        FutureBuilder<List<BagLift>>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No bag submission history found.'),
                ),
              );
            }

            final historyItems = snapshot.data!;

            return ListView.separated(
              physics: const NeverScrollableScrollPhysics(), // Important
              shrinkWrap: true,
              itemCount: historyItems.length,
              itemBuilder: (context, index) {
                final item = historyItems[index];
                return _buildHistoryItem(context, item: item);
              },
              separatorBuilder: (context, index) => const Divider(height: 1),
            );
          },
        ),
      ],
    );
  }

  // --- Reusable History Item (NOW USES BAGLIFT MODEL) ---
  Widget _buildHistoryItem(BuildContext context, {required BagLift item}) {
    Color statusColor;
    String statusText;

    switch (item.status.toLowerCase()) {
      case 'approved':
        statusColor = Colors.green;
        statusText = 'Approved';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Rejected';
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'Pending';
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Icon(
        Icons.shopping_bag_outlined,
        size: 30,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(
        '${item.bagCount} bags',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Text(DateFormat('MMM d, yyyy').format(item.purchaseDate)),
      trailing: Chip(
        label: Text(
          statusText,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: statusColor,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
