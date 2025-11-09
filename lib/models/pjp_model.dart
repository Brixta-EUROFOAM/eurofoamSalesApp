import 'dart:convert';

// --- Helper functions ---
Pjp pjpFromJson(String str) => Pjp.fromJson(json.decode(str));
String pjpToJson(Pjp data) => json.encode(data.toJson());

class Pjp {
  final String id;
  final int userId;
  final int createdById;
  final DateTime planDate;
  
  /// The JOURNEY status (e.g., 'pending', 'started', 'completed')
  final String status; 
  
  /// The ADMIN approval status (e.g., 'PENDING', 'VERIFIED')
  final String? verificationStatus;
  
  final String areaToBeVisited;
  final String? description;
  final String? dealerId;
  final String? dealerName;
  final DateTime createdAt;
  final DateTime updatedAt;

  Pjp({
    required this.id,
    required this.userId,
    required this.createdById,
    required this.planDate,
    required this.status,
    required this.areaToBeVisited,
    this.verificationStatus, // <-- ADDED
    this.description,
    this.dealerId,
    this.dealerName,
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
      
      // --- ✅ THIS IS THE FIX ---
      // Read the correct field from the server
      verificationStatus: json['verificationStatus'],
      // ---
      
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
  
  Pjp copyWith({
    String? id,
    int? userId,
    int? createdById,
    DateTime? planDate,
    String? status,
    String? verificationStatus, // <-- ADDED
    String? areaToBeVisited,
    String? description,
    String? dealerId,
    String? dealerName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Pjp(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdById: createdById ?? this.createdById,
      planDate: planDate ?? this.planDate,
      status: status ?? this.status,
      verificationStatus: verificationStatus ?? this.verificationStatus, // <-- ADDED
      areaToBeVisited: areaToBeVisited ?? this.areaToBeVisited,
      description: description ?? this.description,
      dealerId: dealerId ?? this.dealerId,
      dealerName: dealerName ?? this.dealerName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'createdById': createdById,
      'planDate': planDate.toIso8601String().split('T').first,
      
      // --- ✅ THIS IS THE FIX ---
      // Send BOTH fields, as required by the pjpInputSchema
      'status': status,
      'verificationStatus': verificationStatus,
      // ---
      
      'areaToBeVisited': areaToBeVisited,
      'description': description,
      'dealerId': dealerId,
    };
  }
}

/// A helper class to hold separated PJP lists for the UI.
class PjpData {
  final List<Pjp> pendingPjps;
  final List<Pjp> verifiedPjps; 

  PjpData({
    required this.pendingPjps,
    required this.verifiedPjps,
  });
}