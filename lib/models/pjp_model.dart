import 'dart:convert';

// --- Helper functions ---
Pjp pjpFromJson(String str) => Pjp.fromJson(json.decode(str));
String pjpToJson(Pjp data) => json.encode(data.toJson());

class Pjp {
  final String id;
  final int userId;
  final int createdById;
  final DateTime planDate;
  final String status; 
  final String? verificationStatus;
  final String areaToBeVisited;
  final String? description;
  
  // --- Sales Side ---
  final String? dealerId;
  final String? dealerName;

  // --- Technical Side ---
  final String? siteId;
  final String? siteName; // Helper for UI (joined from backend)

  final DateTime createdAt;
  final DateTime updatedAt;

  Pjp({
    required this.id,
    required this.userId,
    required this.createdById,
    required this.planDate,
    required this.status,
    required this.areaToBeVisited,
    this.verificationStatus,
    this.description,
    this.dealerId,
    this.dealerName,
    this.siteId,
    this.siteName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Pjp.fromJson(Map<String, dynamic> json) {
    String? foundDealerId = json['dealerId']?.toString();
    String? foundDealerName = json['dealerName']?.toString();
    if (json['dealer'] is Map<String, dynamic>) {
      foundDealerId ??= json['dealer']['id']?.toString();
      foundDealerName ??= json['dealer']['name']?.toString();
    }

    // --- Handle Site Join ---
    String? foundSiteId = json['siteId']?.toString();
    String? foundSiteName = json['siteName']?.toString();
    // If backend sends nested 'site' object
    if (json['site'] is Map<String, dynamic>) {
      foundSiteId ??= json['site']['id']?.toString();
      foundSiteName ??= json['site']['siteName']?.toString();
    }

    return Pjp(
      id: json['id']?.toString() ?? '',
      userId: json['userId'] ?? 0,
      createdById: json['createdById'] ?? 0,
      planDate: DateTime.tryParse(json['planDate'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'pending',
      areaToBeVisited: json['areaToBeVisited'] ?? '',
      description: json['description'],
      dealerId: foundDealerId,
      dealerName: foundDealerName,
      
      // Map Site fields
      siteId: foundSiteId,
      siteName: foundSiteName,

      verificationStatus: json['verificationStatus'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'createdById': createdById,
      'planDate': planDate.toIso8601String().split('T').first,
      'status': status,
      'verificationStatus': verificationStatus,
      'areaToBeVisited': areaToBeVisited,
      'description': description,
      'dealerId': dealerId,
      'siteId': siteId,
    };
  }
}

class PjpData {
  final List<Pjp> pendingPjps;
  final List<Pjp> verifiedPjps; 

  PjpData({
    required this.pendingPjps,
    required this.verifiedPjps,
  });
}