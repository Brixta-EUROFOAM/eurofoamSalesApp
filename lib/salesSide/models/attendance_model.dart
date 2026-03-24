// lib/salesSide/models/attendance_model.dart
import 'dart:convert';

Attendance attendanceFromJson(String str) => Attendance.fromJson(json.decode(str));

class Attendance {
  final String id;
  final int userId;
  final DateTime attendanceDate;

  // schema names
  final DateTime? inTimeTimestamp;
  final DateTime? outTimeTimestamp;

  // UI based names (only used for POST/PATCH in dashboard - checkin & out)
  final String? checkInTime; 
  final String? checkOutTime; 

  final String? status; 
  final DateTime createdAt;
  final DateTime updatedAt;

  Attendance({
    required this.id,
    required this.userId,
    required this.attendanceDate,
    this.inTimeTimestamp,
    this.outTimeTimestamp,
    this.checkInTime,
    this.checkOutTime,
    this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    final inTs = json['inTimeTimestamp'] != null
        ? DateTime.parse(json['inTimeTimestamp'])
        : null;

    final outTs = json['outTimeTimestamp'] != null
        ? DateTime.parse(json['outTimeTimestamp'])
        : null;
    return Attendance(
      id: json['id'].toString(),
      userId: json['userId'],
      attendanceDate: DateTime.parse(json['attendanceDate']),
      inTimeTimestamp: inTs,
      outTimeTimestamp: outTs,
      checkInTime: json['checkInTime'],
      checkOutTime: json['checkOutTime'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}