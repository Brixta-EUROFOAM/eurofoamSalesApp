// lib/models/mason_model.dart
import 'dart:convert';

// Assuming you have this file for the .fromEmployee factory
import 'employee_model.dart'; 

Mason masonFromJson(String str) => Mason.fromJson(json.decode(str));
String masonToJson(Mason data) => json.encode(data.toJson());

class Mason {
  final String? id;
  final String name;
  final String phoneNumber;
  final String? kycDocumentName;
  final String? kycDocumentIdNum;
  final String kycStatus; // "none" | "pending" | "approved" | "rejected"
  final int pointsBalance;
  final String? firebaseUid;
  final int? bagsLifted;
  final bool? isReferred;
  final String? referredByUser;
  final String? referredToUser;
  final String? dealerId;
  final int? userId;

  // Optional joined fields from GET with joins
  final String? dealerName;
  final String? userName;

  // Optional timestamps (if the API returns them)
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Mason({
    this.id,
    required this.name,
    required this.phoneNumber,
    this.kycDocumentName,
    this.kycDocumentIdNum,
    this.kycStatus = 'none',
    this.pointsBalance = 0,
    this.firebaseUid,
    this.bagsLifted,
    this.isReferred,
    this.referredByUser,
    this.referredToUser,
    this.dealerId,
    this.userId,
    this.dealerName,
    this.userName,
    this.createdAt,
    this.updatedAt,
  });

  /// Convenience: build a Mason from an Employee when you must (adapter).
  /// Uses sensible fallbacks so phoneNumber isn't null.
  factory Mason.fromEmployee(Employee e) {
    final fallbackPhone = (e.loginId ?? e.email ?? '').toString();
    final name = e.displayName.isNotEmpty ? e.displayName : (e.loginId ?? 'Contractor');

    // If Employee has some company info, we can't reliably map dealerId/userId here.
    return Mason(
      id: e.id,
      name: name,
      phoneNumber: fallbackPhone.isNotEmpty ? fallbackPhone : '',
      kycDocumentName: null,
      kycDocumentIdNum: null,
      kycStatus: 'none',
      pointsBalance: 0,
      firebaseUid: null,
      bagsLifted: null,
      isReferred: null,
      referredByUser: null,
      referredToUser: null,
      dealerId: null,
      userId: null,
      dealerName: null,
      userName: null,
      createdAt: null,
      updatedAt: null,
    );
  }

  // Helper parsers
  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static bool? _parseBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    final s = v.toString().toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
    return null;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  /// Parse JSON coming from API. Accepts snake_case or camelCase keys and common fallbacks.
  factory Mason.fromJson(Map<String, dynamic> json) {
    // Accept both snake_case and camelCase, plus fallback keys (phone)
    final name = (json['name'] ?? json['firstName'] ?? '').toString();
    final phone = (json['phoneNumber'] ??
            json['phone_number'] ??
            json['phone'] ??
            json['mobile'] ??
            '')
        .toString();

    return Mason(
      id: json['id']?.toString(),
      name: name,
      phoneNumber: phone,
      kycDocumentName:
          (json['kycDocumentName'] ?? json['kyc_doc_name'])?.toString(),
      kycDocumentIdNum:
          (json['kycDocumentIdNum'] ?? json['kyc_doc_id_num'])?.toString(),
      kycStatus:
          (json['kycStatus'] ?? json['kyc_status'] ?? 'none')?.toString() ??
              'none',
      pointsBalance:
          _parseInt(json['pointsBalance'] ?? json['points_balance']) ?? 0,
      firebaseUid: (json['firebaseUid'] ?? json['firebase_uid'])?.toString(),
      bagsLifted: _parseInt(json['bagsLifted'] ?? json['bags_lifted']),
      isReferred: _parseBool(json['isReferred'] ?? json['is_referred']),
      referredByUser:
          (json['referredByUser'] ?? json['referred_by_user'])?.toString(),
      referredToUser:
          (json['referredToUser'] ?? json['referred_to_user'])?.toString(),
      dealerId: (json['dealerId'] ?? json['dealer_id'])?.toString(),
      userId: _parseInt(json['userId'] ?? json['user_id']),
      dealerName: (json['dealerName'] ?? json['dealer_name'])?.toString(),
      userName: (json['userName'] ?? json['user_name'])?.toString(),
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDate(json['updatedAt'] ?? json['updated_at']),
    );
  }

  Mason copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? kycDocumentName,
    String? kycDocumentIdNum,
    String? kycStatus,
    int? pointsBalance,
    String? firebaseUid,
    int? bagsLifted,
    bool? isReferred,
    String? referredByUser,
    String? referredToUser,
    String? dealerId,
    int? userId,
    String? dealerName,
    String? userName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Mason(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      kycDocumentName: kycDocumentName ?? this.kycDocumentName,
      kycDocumentIdNum: kycDocumentIdNum ?? this.kycDocumentIdNum,
      kycStatus: kycStatus ?? this.kycStatus,
      pointsBalance: pointsBalance ?? this.pointsBalance,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      bagsLifted: bagsLifted ?? this.bagsLifted,
      isReferred: isReferred ?? this.isReferred,
      referredByUser: referredByUser ?? this.referredByUser,
      referredToUser: referredToUser ?? this.referredToUser,
      dealerId: dealerId ?? this.dealerId,
      userId: userId ?? this.userId,
      dealerName: dealerName ?? this.dealerName,
      userName: userName ?? this.userName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converts the object into a Map for creating/updating a mason.
  /// Uses camelCase keys (what your ApiService expects).
  Map<String, dynamic> toJson() => {
        if (id != null) "id": id,
        "name": name,
        "phoneNumber": phoneNumber,
        "kycDocumentName": kycDocumentName,
        "kycDocumentIdNum": kycDocumentIdNum,
        "kycStatus": kycStatus,
        "pointsBalance": pointsBalance,
        "firebaseUid": firebaseUid,
        "bagsLifted": bagsLifted,
        "isReferred": isReferred,
        "referredByUser": referredByUser,
        "referredToUser": referredToUser,
        "dealerId": dealerId,
        "userId": userId,
      };
}