// lib/models/users_model.dart
class UserModel {
  final int id;
  final String email;
  final String? username;
  final String? phoneNumber;
  final String role;
  final String status;
  final String? area;
  final String? zone;

  final bool isDashboardUser;
  final String? dashboardLoginId;
  final bool isSalesAppUser;
  final String? salesmanLoginId;

  final int? reportsToId;
  final String? deviceId;
  final String? fcmToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.email,
    this.username,
    this.phoneNumber,
    required this.role,
    required this.status,
    this.area,
    this.zone,
    required this.isDashboardUser,
    this.dashboardLoginId,
    required this.isSalesAppUser,
    this.salesmanLoginId,
    this.reportsToId,
    this.deviceId,
    this.fcmToken,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      phoneNumber: json['phoneNumber'],
      role: json['role'],
      status: json['status'] ?? 'active',
      area: json['area'],
      zone: json['zone'],
      isDashboardUser: json['isDashboardUser'] ?? false,
      dashboardLoginId: json['dashboardLoginId'],
      isSalesAppUser: json['isSalesAppUser'] ?? false,
      salesmanLoginId: json['salesmanLoginId'],
      reportsToId: json['reportsToId'],
      deviceId: json['deviceId'],
      fcmToken: json['fcmToken'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'phoneNumber': phoneNumber,
      'role': role,
      'status': status,
      'area': area,
      'zone': zone,
      'isDashboardUser': isDashboardUser,
      'dashboardLoginId': dashboardLoginId,
      'isSalesAppUser': isSalesAppUser,
      'salesmanLoginId': salesmanLoginId,
      'reportsToId': reportsToId,
      'deviceId': deviceId,
      'fcmToken': fcmToken,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}