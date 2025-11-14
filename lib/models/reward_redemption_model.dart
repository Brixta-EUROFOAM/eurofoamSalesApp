// lib/models/reward_redemption.dart
import 'dart:developer' as dev;

class RewardRedemption {
  final String id;
  final String masonId;
  final int rewardId;
  final int quantity;
  final String status;
  final int pointsDebited;
  final String? deliveryName;
  final String? deliveryPhone;
  final String? deliveryAddress;
  final DateTime createdAt;
  
  // Flat fields from your API join
  final String? rewardName;
  final String? masonName;

  RewardRedemption({
    required this.id,
    required this.masonId,
    required this.rewardId,
    required this.quantity,
    required this.status,
    required this.pointsDebited,
    this.deliveryName,
    this.deliveryPhone,
    this.deliveryAddress,
    required this.createdAt,
    this.rewardName,
    this.masonName,
  });

  factory RewardRedemption.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? dateStr) {
      if (dateStr == null) return null;
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        dev.log('Invalid date format: $dateStr', name: 'RewardRedemptionModel');
        return null;
      }
    }
    
    int? _parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    return RewardRedemption(
      id: json['id'] as String,
      masonId: json['masonId'] as String? ?? json['mason_id'] as String? ?? '',
      rewardId: _parseInt(json['rewardId'] ?? json['reward_id']) ?? 0,
      quantity: _parseInt(json['quantity']) ?? 1,
      status: json['status'] as String? ?? 'pending',
      pointsDebited: _parseInt(json['pointsDebited'] ?? json['points_debited']) ?? 0,
      deliveryName: json['deliveryName'] as String?,
      deliveryPhone: json['deliveryPhone'] as String?,
      deliveryAddress: json['deliveryAddress'] as String?,
      createdAt: parseDate(json['createdAt'] ?? json['created_at']) ?? DateTime.now(),
      // Flat fields from API
      rewardName: json['rewardName'] as String?,
      masonName: json['masonName'] as String?,
    );
  }
}