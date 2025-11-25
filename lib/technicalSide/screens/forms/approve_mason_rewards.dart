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

  // --- FINTECH THEME PALETTE ---
  static const Color _bgLight       = Color(0xFFF3F4F6); // Corporate Grey
  static const Color _surfaceWhite  = Colors.white;
  static const Color _textDark      = Color(0xFF111827); // Navy/Black
  static const Color _textGrey      = Color(0xFF6B7280); // Subtitle Grey
  static const Color _cardNavy      = Color(0xFF0F172A); // Deep Navy
  static const Color _accentGreen   = Color(0xFF10B981); 
  static const Color _dangerRed     = Color(0xFFEF4444);
  static const Color _purpleAccent  = Color(0xFF8B5CF6);

  @override
  void initState() {
    super.initState();
    _loadRedemptions();
  }

  void _loadRedemptions() {
    setState(() {
      _redemptionsFuture = _fetchPendingRedemptionsInternal();
    });
  }

  // Internal helper to match your existing logic
  Future<List<MasonRedemption>> _fetchPendingRedemptionsInternal() async {
    try {
      final List<dynamic> response = await _api.fetchPendingRedemptions();
      return response.map((json) => MasonRedemption.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching redemptions: $e');
      return [];
    }
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    setState(() => _isProcessing = true);
    try {
      await _api.updateRedemptionStatus(id, newStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request marked as $newStatus'),
            backgroundColor: newStatus == 'approved' ? _accentGreen : _dangerRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadRedemptions(); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: _dangerRed),
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
        backgroundColor: _surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('${action.toUpperCase()} REQUEST?', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textDark)),
        content: Text('Are you sure you want to mark this request as $action?', style: const TextStyle(color: _textGrey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: _textGrey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'approved' ? _accentGreen : _dangerRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(id, action);
            },
            child: Text(action.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: _bgLight,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textGrey, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Approve Rewards",
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _textDark),
            onPressed: _loadRedemptions,
          ),
        ],
      ),
      body: FutureBuilder<List<MasonRedemption>>(
        future: _redemptionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _cardNavy));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: _dangerRed)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                      ]
                    ),
                    child: const Icon(Icons.card_giftcard, size: 40, color: _textGrey),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No pending reward requests",
                    style: TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final list = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: list.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 16),
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
    return Container(
      decoration: BoxDecoration(
        color: _surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          // 1. Header Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF), // Light Purple
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.emoji_events, color: _purpleAccent, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.rewardName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "Qty: ${item.quantity}",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _textGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED), // Light Orange
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.status.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1, color: Color(0xFFF3F4F6)),

          // 2. Details Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _detailRow(Icons.person_outline, "Mason", item.masonName ?? "Unknown"),
                const SizedBox(height: 12),
                _detailRow(Icons.location_on_outlined, "Location", item.deliveryAddress),
                const SizedBox(height: 12),
                _detailRow(Icons.calendar_today_outlined, "Date", item.createdAt.toLocal().toString().split(' ')[0]),
              ],
            ),
          ),

          // 3. Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isProcessing ? null : () => _confirmAction(item.id, 'rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _dangerRed,
                      side: const BorderSide(color: _dangerRed),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("REJECT", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : () => _confirmAction(item.id, 'approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("APPROVE", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(color: _textGrey, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w500, color: _textDark, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}