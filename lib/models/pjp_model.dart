import 'dart:convert';

// --- Helper functions are unchanged ---
Pjp pjpFromJson(String str) => Pjp.fromJson(json.decode(str));
String pjpToJson(Pjp data) => json.encode(data.toJson());

class Pjp {
  final String id;
  final int userId;
  final int createdById;
  final DateTime planDate;
  final String status;
  final String areaToBeVisited; // Kept for existing logic
  final String? description;
  
  // --- ✅ UPGRADED FIELDS ---
  final String? dealerId; // This is what the server needs
  final String? dealerName; // This is useful for display
  // --- END UPGRADE ---

  final DateTime createdAt;
  final DateTime updatedAt;

  Pjp({
    required this.id,
    required this.userId,
    required this.createdById,
    required this.planDate,
    required this.status,
    required this.areaToBeVisited,
    
    // --- ✅ UPGRADED CONSTRUCTOR ---
    this.dealerId,
    this.dealerName,
    // --- END UPGRADE ---

    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  /// ✅ Handles both camelCase and snake_case from server
  /// ✅ Now smartly parses dealer info
  factory Pjp.fromJson(Map<String, dynamic> json) {
    
    // Smartly find dealer info, whether it's flat or nested
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
      status: json['status'] ?? 'pending', // Default to pending
      areaToBeVisited: json['areaToBeVisited'] ?? '',
      
      // --- ✅ UPGRADED ---
      dealerId: foundDealerId,
      dealerName: foundDealerName,
      // --- END UPGRADE ---
      
      description: json['description'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  /// ✅ Proper copyWith
  Pjp copyWith({
    String? id,
    int? userId,
    int? createdById,
    DateTime? planDate,
    String? status,
    String? areaToBeVisited,
    String? description,
    
    // --- ✅ UPGRADED ---
    String? dealerId,
    String? dealerName,
    // --- END UPGRADE ---

    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Pjp(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdById: createdById ?? this.createdById,
      planDate: planDate ?? this.planDate,
      status: status ?? this.status,
      areaToBeVisited: areaToBeVisited ?? this.areaToBeVisited,
      description: description ?? this.description,
      
      // --- ✅ UPGRADED ---
      dealerId: dealerId ?? this.dealerId,
      dealerName: dealerName ?? this.dealerName,
      // --- END UPGRADE ---
      
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// ✅ Matches server camelCase schema
  /// ✅ Now sends the correct dealerId
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'createdById': createdById,
      'planDate': planDate.toIso8601String().split('T').first,
      'status': status,
      'areaToBeVisited': areaToBeVisited, // Still sent for compatibility
      'description': description,
      
      // --- ✅ UPGRADED ---
      'dealerId': dealerId, // Send the ID
      // 'dealerName': dealerName, // No need to send name, server has it
      // --- END UPGRADE ---
    };
  }
}
class PjpData {
  final List<Pjp> pendingPjps;
  final List<Pjp> verifiedPjps; // We use 'verified' to match your new ApiService function

  PjpData({
    required this.pendingPjps,
    required this.verifiedPjps,
  });
}