// lib/technicalSide/models/mason_rewards_model.dart
class MasonRedemption {
  final String id;
  final String masonId;
  final String? masonName; // Joined
  final String rewardName; // Joined
  final int quantity;
  final String status; // placed, approved, shipped, delivered
  final String deliveryAddress;
  final DateTime createdAt;

  MasonRedemption({
    required this.id,
    required this.masonId,
    this.masonName,
    required this.rewardName,
    required this.quantity,
    required this.status,
    required this.deliveryAddress,
    required this.createdAt,
  });

  factory MasonRedemption.fromJson(Map<String, dynamic> json) {
    return MasonRedemption(
      id: json['id'],
      masonId: json['masonId'],
      masonName: json['mason']?['name'],
      // Assuming the backend joins the reward table to give the name
      rewardName: json['reward']?['itemName'] ?? 'Unknown Reward',
      quantity: json['quantity'] ?? 1,
      status: json['status'] ?? 'placed',
      deliveryAddress: json['deliveryAddress'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}