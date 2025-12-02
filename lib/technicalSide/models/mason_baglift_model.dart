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
  final String? siteId;
  final String? siteKeyPersonName;
  final String? siteKeyPersonPhone;
  final String? verificationSiteImageUrl;
  final String? verificationProofImageUrl;
  final DateTime approvedAt;
  final String? approvedBy;

  MasonBagLift({
    required this.id,
    required this.masonId,
    this.masonName,
    this.dealerId,
    required this.bagCount,
    required this.status,
    this.imageUrl,
    this.siteId,
    this.siteKeyPersonName,
    this.siteKeyPersonPhone,
    this.verificationSiteImageUrl,
    this.verificationProofImageUrl,
    required this.approvedAt,
    this.approvedBy,
    required this.createdAt,
  });

  factory MasonBagLift.fromJson(Map<String, dynamic> json) {
    return MasonBagLift(
      id: json['id'],
      masonId: json['masonId'],
      masonName:
          json['mason']?['name'] ?? json['masonName'], // Handle join variations
      dealerId: json['dealerId'],
      bagCount: int.tryParse(json['bagCount']?.toString() ?? '0') ?? 0,
      status: json['status'] ?? 'pending',
      imageUrl: json['imageUrl'],
      siteId: json['siteId']?.toString(),
      siteKeyPersonName: json['siteKeyPersonName'],
      siteKeyPersonPhone: json['siteKeyPersonPhone'],
      verificationSiteImageUrl: json['verificationSiteImageUrl'],
      verificationProofImageUrl: json['verificationProofImageUrl'],
      approvedAt: DateTime.tryParse(json['approvedAt'] ?? '') ?? DateTime.now(),
      approvedBy: json['approvedBy'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
