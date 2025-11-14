// lib/models/bag_lift_model.dart
import 'dart:developer' as dev;

class BagLift {
  final String id;
  final String masonId;
  final DateTime purchaseDate;
  final int bagCount;
  final int pointsCredited;
  final String status;
  final DateTime? approvedAt;
  final String? imageUrl;

  BagLift({
    required this.id,
    required this.masonId,
    required this.purchaseDate,
    required this.bagCount,
    required this.pointsCredited,
    required this.status,
    this.approvedAt,
    this.imageUrl,
  });

  factory BagLift.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse dates
    DateTime? parseDate(String? dateStr) {
      if (dateStr == null) return null;
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        dev.log('Invalid date format: $dateStr', name: 'BagLiftModel');
        return null;
      }
    }

    return BagLift(
      id: json['id'] as String,
      masonId: json['masonId'] as String,
      // Use purchaseDate, matching your schema
      purchaseDate: parseDate(json['purchaseDate']) ?? DateTime.now(),
      // Use bagCount, matching your schema
      bagCount: (json['bagCount'] as num? ?? 0).toInt(),
      // Use pointsCredited, matching your schema
      pointsCredited: (json['pointsCredited'] as num? ?? 0).toInt(),
      status: json['status'] as String? ?? 'pending',
      // Use approvedAt, matching your schema
      approvedAt: parseDate(json['approvedAt']),
      imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String?,
    );
  }
}