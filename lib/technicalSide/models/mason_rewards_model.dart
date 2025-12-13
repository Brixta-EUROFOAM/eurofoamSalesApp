// lib/technicalSide/models/mason_rewards_model.dart
class MasonRedemption {
  final String id;
  final String masonId;
  final String? masonName; 
  final String rewardName; 
  final String? masonPhone;
  final int points;
  final int quantity;
  final String status; // placed, approved, shipped, delivered
  final String deliveryAddress;
  final DateTime createdAt;

  MasonRedemption({
    required this.id,
    required this.masonId,
    this.masonName,
    this.masonPhone,
    required this.rewardName,
    required this.quantity,
    required this.points,
    required this.status,
    required this.deliveryAddress,
    required this.createdAt,
  });

  factory MasonRedemption.fromJson(Map<String, dynamic> json) {
    return MasonRedemption(
      id: json['id'],
      masonId: json['masonId'],
      masonName: json['masonName'] ?? json['mason']?['name'] ?? 'Unknown Mason',
      rewardName: json['rewardName'] ?? json['reward']?['itemName'] ?? 'Unknown Reward',
      masonPhone: json['masonPhone'] ?? json['mason']?['phoneNumber'] ?? 'No Phone',
      quantity: json['quantity'] ?? 1,
      points: int.tryParse(json['pointsDebited']?.toString() ?? '0') ?? 0,
      status: json['status'] ?? 'placed',
      deliveryAddress: json['deliveryAddress'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}