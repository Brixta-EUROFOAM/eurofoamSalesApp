// lib/screens/contractor/contractor_gifts_screen.dart
import 'package:flutter/material.dart';
import 'package:assetarchiverflutter/models/mason_model.dart';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:assetarchiverflutter/models/reward_category_model.dart';
import 'package:assetarchiverflutter/models/reward_model.dart';
import 'package:assetarchiverflutter/models/reward_redemption_model.dart';
import 'package:intl/intl.dart';

class ContractorGiftsScreen extends StatefulWidget {
  final Mason mason;
  const ContractorGiftsScreen({super.key, required this.mason});

  @override
  State<ContractorGiftsScreen> createState() => _ContractorGiftsScreenState();
}

class _ContractorGiftsScreenState extends State<ContractorGiftsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();
  
  // State for both tabs
  late Future<List<RewardRedemption>> _redemptionsFuture;
  late Future<List<RewardCategory>> _categoriesFuture;
  late Future<List<Reward>> _rewardsFuture;
  
  int? _selectedCategoryId;
  bool _isRedeeming = false;

  // We need to track the points locally to update the UI instantly
  late int _localPointsBalance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _localPointsBalance = widget.mason.pointsBalance;
    _loadData();
  }

  // This is called if the Mason object itself is rebuilt (e.g., after KYC refresh)
  @override
  void didUpdateWidget(ContractorGiftsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mason.pointsBalance != oldWidget.mason.pointsBalance) {
      setState(() {
        _localPointsBalance = widget.mason.pointsBalance;
      });
    }
  }

  void _loadData() {
    // Load data for "Redeem" tab
    _categoriesFuture = _api.fetchRewardCategories();
    _rewardsFuture = _api.fetchRewards(categoryId: _selectedCategoryId);
    
    // Load data for "My Redemptions" tab
    if (widget.mason.id != null) {
      _redemptionsFuture = _api.fetchMyRedemptions(widget.mason.id!);
    } else {
      _redemptionsFuture = Future.error('Mason ID is missing.');
    }
    setState(() {}); // Rebuild to reflect new futures
  }

  void _onCategorySelected(int? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      // Fetch rewards for the newly selected category
      _rewardsFuture = _api.fetchRewards(categoryId: _selectedCategoryId);
    });
  }

  void _showRedeemDialog(Reward reward) {
    if (reward.pointsCost == null || _localPointsBalance < (reward.pointsCost ?? 0)) {
      _toast('You do not have enough points for this reward.', isError: true);
      return;
    }

    // For a real app, you would navigate to a new screen to collect
    // deliveryName, deliveryPhone, and deliveryAddress.
    // For now, we'll use the Mason's details as a stand-in.
    showDialog(
      context: context,
      barrierDismissible: false, // Don't dismiss on tap outside
      builder: (context) => AlertDialog(
        title: Text('Confirm Redemption'),
        content: Text(
            'Are you sure you want to redeem "${reward.name ?? 'this reward'}" for ${reward.pointsCost} points?\n\nThis will be delivered to:\n${widget.mason.name}\n${widget.mason.phoneNumber}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isRedeeming ? null : () {
              Navigator.of(context).pop();
              _performRedemption(reward);
            },
            child: _isRedeeming ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text('Redeem'),
          ),
        ],
      ),
    );
  }

  Future<void> _performRedemption(Reward reward) async {
    if (widget.mason.id == null || reward.pointsCost == null) {
      _toast('Cannot redeem: User ID or reward points are missing.', isError: true);
      return;
    }
    
    setState(() => _isRedeeming = true);

    // Use Mason's info as placeholder delivery details
    final deliveryDetails = {
      'deliveryName': widget.mason.name,
      'deliveryPhone': widget.mason.phoneNumber,
      'deliveryAddress': 'N/A (Please contact TSO)', // Placeholder
    };

    try {
      final redemption = await _api.redeemReward(
        masonId: widget.mason.id!,
        rewardId: reward.id,
        quantity: 1,
        pointsDebited: reward.pointsCost!,
        deliveryDetails: deliveryDetails,
      );
      
      if (redemption != null) {
        _toast('Redemption successful!');
        
        // Optimistically update points balance
        setState(() {
          _localPointsBalance = _localPointsBalance - reward.pointsCost!;
        });

        _loadData(); // Refresh both tabs
        _tabController.animateTo(1); // Switch to "My Redemptions"
      } else {
        _toast('Redemption failed. Please try again.', isError: true);
      }
    } catch (e) {
      _toast('An error occurred: $e', isError: true);
    } finally {
      setState(() => _isRedeeming = false);
    }
  }

  void _toast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gifts & Redemption'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.shopping_bag_outlined), text: 'Redeem'),
            Tab(icon: Icon(Icons.receipt_long_outlined), text: 'My Redemptions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRedeemTab(theme),
          _buildMyRedemptionsTab(theme),
        ],
      ),
    );
  }

  // --- TAB 1: REDEEM REWARDS ---
  Widget _buildRedeemTab(ThemeData theme) {
    return Column(
      children: [
        // --- Category Filter Bar ---
        _buildCategoryFilter(),
        
        // --- Points Header ---
        Container(
          width: double.infinity,
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text('YOUR POINTS BALANCE', style: theme.textTheme.labelMedium),
              Text(
                _localPointsBalance.toString(), // Use local state
                style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary),
              ),
            ],
          ),
        ),

        // --- Rewards List ---
        Expanded(
          child: FutureBuilder<List<Reward>>(
            future: _rewardsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error loading rewards: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text('No rewards are available in this category right now.', textAlign: TextAlign.center,),
                    ));
              }

              final rewards = snapshot.data!;
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.70, // Gave more space for button
                ),
                itemCount: rewards.length,
                itemBuilder: (context, index) {
                  return _RewardCard(
                    reward: rewards[index],
                    currentPoints: _localPointsBalance,
                    onRedeem: () => _showRedeemDialog(rewards[index]),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildCategoryFilter() {
    return FutureBuilder<List<RewardCategory>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 50, child: Center(child: LinearProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(height: 8); // No categories
        }
        final categories = snapshot.data!;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // "All" Chip
              ChoiceChip(
                label: const Text('All'),
                selected: _selectedCategoryId == null,
                onSelected: (_) => _onCategorySelected(null),
              ),
              ...categories.map((cat) {
                return Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: ChoiceChip(
                    label: Text(cat.name ?? '...'),
                    selected: _selectedCategoryId == cat.id,
                    onSelected: (_) => _onCategorySelected(cat.id),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // --- TAB 2: MY REDEMPTIONS ---
  Widget _buildMyRedemptionsTab(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: () {
        _loadData();
        return _redemptionsFuture;
      },
      child: FutureBuilder<List<RewardRedemption>>(
        future: _redemptionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading history: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: const Text('You have not redeemed any rewards yet.\nItems you redeem will appear here.', textAlign: TextAlign.center),
              ),
            );
          }

          final redemptions = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: redemptions.length,
            itemBuilder: (context, index) {
              return _RedemptionCard(redemption: redemptions[index]);
            },
          );
        },
      ),
    );
  }
}

// --- WIDGET for Reward Card ---
class _RewardCard extends StatelessWidget {
  final Reward reward;
  final int currentPoints;
  final VoidCallback onRedeem;

  const _RewardCard({
    required this.reward,
    required this.currentPoints,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final points = reward.pointsCost ?? 0;
    final bool canAfford = currentPoints >= points;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              color: Colors.grey[200],
              child: Image.network(
                reward.imageUrl ?? '',
                fit: BoxFit.cover,
                errorBuilder: (context, err, stack) =>
                    Center(child: Icon(Icons.card_giftcard, size: 40, color: Colors.grey[400])),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.name ?? 'Unnamed Reward',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  points == 0 ? 'N/A' : '$points Points',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: canAfford ? theme.colorScheme.primary : theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: ElevatedButton(
              onPressed: canAfford ? onRedeem : null,
              child: Text(canAfford ? 'Redeem' : 'Not Enough Points'),
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET for Redemption History Card ---
class _RedemptionCard extends StatelessWidget {
  final RewardRedemption redemption;
  const _RedemptionCard({required this.redemption});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        // We can't show an image here, as the API only sends the name
        leading: CircleAvatar(
          backgroundColor: _statusColor(redemption.status, theme).withOpacity(0.1),
          child: Icon(Icons.card_giftcard, color: _statusColor(redemption.status, theme)),
        ),
        title: Text(
          redemption.rewardName ?? 'Reward ID: ${redemption.rewardId}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${redemption.pointsDebited} points on ${DateFormat('MMM d, yyyy').format(redemption.createdAt)}',
        ),
        trailing: Chip(
          label: Text(
            redemption.status.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          backgroundColor: _statusColor(redemption.status, theme),
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        ),
      ),
    );
  }

  Color _statusColor(String status, ThemeData theme) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'shipped':
      case 'delivered':
        return Colors.green;
      case 'rejected':
        return theme.colorScheme.error;
      case 'placed':
      default:
        return Colors.orange;
    }
  }
}