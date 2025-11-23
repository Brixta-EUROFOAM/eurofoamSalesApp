// lib/technicalSide/models/mason_baglift_model.dart
class MasonBagLift {
  final String id;
  final String masonId;
  final String? masonName; // Joined field
  final String? dealerId;
  final int bagCount;
  final String status; // pending, approved, rejected
  final String? imageUrl;
  final DateTime createdAt;

  MasonBagLift({
    required this.id,
    required this.masonId,
    this.masonName,
    this.dealerId,
    required this.bagCount,
    required this.status,
    this.imageUrl,
    required this.createdAt,
  });

  factory MasonBagLift.fromJson(Map<String, dynamic> json) {
    return MasonBagLift(
      id: json['id'],
      masonId: json['masonId'],
      masonName: json['mason']?['name'] ?? json['masonName'], // Handle join variations
      dealerId: json['dealerId'],
      bagCount: int.tryParse(json['bagCount']?.toString() ?? '0') ?? 0,
      status: json['status'] ?? 'pending',
      imageUrl: json['imageUrl'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}