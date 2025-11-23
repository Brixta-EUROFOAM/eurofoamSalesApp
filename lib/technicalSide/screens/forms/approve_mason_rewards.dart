// lib/screens/forms/approve_mason_rewards.dart
import 'package:flutter/material.dart';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:assetarchiverflutter/technicalSide/models/mason_rewards_model.dart';

class ApproveMasonRewardsScreen extends StatefulWidget {
  const ApproveMasonRewardsScreen({super.key});

  @override
  State<ApproveMasonRewardsScreen> createState() =>
      _ApproveMasonRewardsScreenState();
}

class _ApproveMasonRewardsScreenState extends State<ApproveMasonRewardsScreen> {
  final ApiService _api = ApiService();
  late Future<List<MasonRedemption>> _redemptionsFuture;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadRedemptions();
  }

  void _loadRedemptions() {
    setState(() {
      // Assuming you added fetchPendingRedemptions() to ApiService as suggested
      // If not, this generic call mimics the logic:
      // _redemptionsFuture = _api.fetchPendingRedemptions();
      _redemptionsFuture = _fetchPendingRedemptionsInternal();
    });
  }

  // Internal helper if method is missing in ApiService yet
  Future<List<MasonRedemption>> _fetchPendingRedemptionsInternal() async {
    try {
      // 1. Get the raw list from the API (which is List<dynamic>)
      final List<dynamic> response = await _api.fetchPendingRedemptions();

      // 2. Convert each item to a MasonRedemption object
      return response.map((json) => MasonRedemption.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching redemptions: $e');
      return [];
    }
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    setState(() => _isProcessing = true);
    try {
      // Call the API to update status
      await _api.updateRedemptionStatus(id, newStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request marked as $newStatus'),
            backgroundColor: newStatus == 'approved'
                ? Colors.green
                : Colors.red,
          ),
        );
        _loadRedemptions(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _confirmAction(String id, String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${action.toUpperCase()} Request?'),
        content: Text('Are you sure you want to mark this request as $action?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'approved' ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(id, action);
            },
            child: Text(action.toUpperCase()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Approve Rewards"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRedemptions,
          ),
        ],
      ),
      body: FutureBuilder<List<MasonRedemption>>(
        future: _redemptionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.card_giftcard, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "No pending reward requests",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final list = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return _buildRedemptionCard(item);
            },
          );
        },
      ),
    );
  }

  Widget _buildRedemptionCard(MasonRedemption item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Reward Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Colors.orange,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.rewardName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Qty: ${item.quantity}",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Text(
                    item.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Mason & Delivery Details
            _detailRow(
              Icons.person_outline,
              "Mason",
              item.masonName ?? "Unknown",
            ),
            const SizedBox(height: 8),
            _detailRow(
              Icons.location_on_outlined,
              "Delivery To",
              item.deliveryAddress,
            ),
            const SizedBox(height: 8),
            _detailRow(
              Icons.calendar_today_outlined,
              "Requested",
              item.createdAt.toLocal().toString().split(' ')[0],
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text("REJECT"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _isProcessing
                        ? null
                        : () => _confirmAction(item.id, 'rejected'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text("APPROVE"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    onPressed: _isProcessing
                        ? null
                        : () => _confirmAction(item.id, 'approved'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
