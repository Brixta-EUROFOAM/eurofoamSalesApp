// lib/technicalSide/models/mason_kyc_model.dart
class KycSubmission {
  final String id;
  final String masonId;
  final String? aadhaarNumber;
  final String? panNumber;
  final String? voterIdNumber;
  final Map<String, dynamic> documents;
  final String status; // 'pending', 'approved', 'rejected'
  final String? remark;
  final DateTime createdAt;
  
  // Joined Mason data (often sent by backend for list views)
  final MasonKycProfile? mason; 

  KycSubmission({
    required this.id,
    required this.masonId,
    this.aadhaarNumber,
    this.panNumber,
    this.voterIdNumber,
    required this.documents,
    required this.status,
    this.remark,
    required this.createdAt,
    this.mason,
  });

  factory KycSubmission.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse documents JSON
    Map<String, dynamic> parsedDocs = {};
    if (json['documents'] != null) {
      if (json['documents'] is Map) {
        parsedDocs = Map<String, dynamic>.from(json['documents']);
      } else if (json['documents'] is String) {
        // Handle case where it might come as a stringified JSON
        // parsedDocs = jsonDecode(json['documents']); // Requires import dart:convert
      }
    }

    MasonKycProfile? masonProfile;
    
    if (json['mason'] != null) {
      // Case A: Backend sends nested object
      masonProfile = MasonKycProfile.fromJson(json['mason']);
    } else if (json['masonName'] != null) {
      // Case B: Backend sends flat structure (Current Setup)
      masonProfile = MasonKycProfile(
        id: json['masonId']?.toString() ?? '',
        name: json['masonName'] ?? 'Unknown Mason',
        phoneNumber: json['masonPhone'] ?? 'No Phone', // Matches the new backend alias
        kycStatus: 'pending', // Default for flat structure context
      );
    }

    return KycSubmission(
      id: json['id']?.toString() ?? '',
      masonId: json['masonId']?.toString() ?? '',
      aadhaarNumber: json['aadhaarNumber'],
      panNumber: json['panNumber'],
      voterIdNumber: json['voterIdNumber'],
      documents: parsedDocs,
      status: json['status'] ?? 'pending',
      remark: json['remark'],
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      mason: masonProfile,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'masonId': masonId,
      'aadhaarNumber': aadhaarNumber,
      'panNumber': panNumber,
      'voterIdNumber': voterIdNumber,
      'documents': documents,
      'status': status,
      'remark': remark,
    };
  }
}

// Helper class for the nested mason object
class MasonKycProfile {
  final String id;
  final String name;
  final String phoneNumber;
  final String kycStatus;

  MasonKycProfile({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.kycStatus,
  });

  factory MasonKycProfile.fromJson(Map<String, dynamic> json) {
    return MasonKycProfile(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown',
      phoneNumber: json['phoneNumber'] ?? '',
      kycStatus: json['kycStatus'] ?? 'none',
    );
  }
}