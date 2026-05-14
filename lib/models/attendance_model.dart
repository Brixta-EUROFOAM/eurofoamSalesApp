// lib/models/attendance_model.dart
class AttendanceModel {
  final String id;
  final int userId;
  final DateTime attendanceDate;
  final String locationName;
  final DateTime inTimeTimestamp;
  final DateTime? outTimeTimestamp;
  final bool inTimeImageCaptured;
  final bool outTimeImageCaptured;

  final String? inTimeImageUrl;
  final String? outTimeImageUrl;
  
  final double inTimeLatitude;
  final double inTimeLongitude;
  final double? outTimeLatitude;
  final double? outTimeLongitude;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? role;

  AttendanceModel({
    required this.id,
    required this.userId,
    required this.attendanceDate,
    required this.locationName,
    required this.inTimeTimestamp,
    this.outTimeTimestamp,
    required this.inTimeImageCaptured,
    required this.outTimeImageCaptured,
    this.inTimeImageUrl,
    this.outTimeImageUrl,
    required this.inTimeLatitude,
    required this.inTimeLongitude,
    this.outTimeLatitude,
    this.outTimeLongitude,
    this.createdAt,
    this.updatedAt,
    this.role,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'],
      userId: json['userId'],
      attendanceDate: DateTime.parse(json['attendanceDate']),
      locationName: json['locationName'],
      inTimeTimestamp: DateTime.parse(json['inTimeTimestamp']).toLocal(),
      outTimeTimestamp: json['outTimeTimestamp'] != null ? DateTime.parse(json['outTimeTimestamp']).toLocal() : null,
      inTimeImageCaptured: json['inTimeImageCaptured'] ?? false,
      outTimeImageCaptured: json['outTimeImageCaptured'] ?? false,
      inTimeImageUrl: json['inTimeImageUrl'],
      outTimeImageUrl: json['outTimeImageUrl'],
      inTimeLatitude: (json['inTimeLatitude'] as num).toDouble(),
      inTimeLongitude: (json['inTimeLongitude'] as num).toDouble(),
      outTimeLatitude: (json['outTimeLatitude'] as num?)?.toDouble(),
      outTimeLongitude: (json['outTimeLongitude'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']).toLocal() : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']).toLocal() : null,
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'attendanceDate': attendanceDate.toIso8601String().split('T')[0],
      'locationName': locationName,
      'inTimeTimestamp': inTimeTimestamp.toUtc().toIso8601String(),
      'outTimeTimestamp': outTimeTimestamp?.toUtc().toIso8601String(),
      'inTimeImageCaptured': inTimeImageCaptured,
      'outTimeImageCaptured': outTimeImageCaptured,
      'inTimeImageUrl': inTimeImageUrl,
      'outTimeImageUrl': outTimeImageUrl,
      'inTimeLatitude': inTimeLatitude,
      'inTimeLongitude': inTimeLongitude,
      'outTimeLatitude': outTimeLatitude,
      'outTimeLongitude': outTimeLongitude,
      'createdAt': createdAt?.toUtc().toIso8601String(),
      'updatedAt': updatedAt?.toUtc().toIso8601String(),
      'role': role,
    };
  }
}