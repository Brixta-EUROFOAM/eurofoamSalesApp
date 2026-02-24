// lib/models/daily_task_model.dart
import 'dart:convert';

DailyTask dailyTaskFromJson(String str) => DailyTask.fromJson(json.decode(str));
String dailyTaskToJson(DailyTask data) => json.encode(data.toJson());

class DailyTask {
  final String? id;
  final String? pjpBatchId;
  final int userId;
  final String? dealerId;
  final String? dealerNameSnapshot;
  final String? dealerMobile;
  final String? zone;
  final String? area;
  final String? route;
  final String? objective;
  final String? visitType;
  final int? requiredVisitCount;
  final String? week;
  final DateTime taskDate;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DailyTask({
    this.id,
    this.pjpBatchId,
    required this.userId,
    this.dealerId,
    this.dealerNameSnapshot,
    this.dealerMobile,
    this.zone,
    this.area,
    this.route,
    this.objective,
    this.visitType,
    this.requiredVisitCount,
    this.week,
    required this.taskDate,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory DailyTask.fromJson(Map<String, dynamic> json) => DailyTask(
        id: json["id"]?.toString(),
        pjpBatchId: json["pjpBatchId"]?.toString(),
        userId: json["userId"] is int
            ? json["userId"]
            : int.tryParse(json["userId"].toString()) ?? 0,
        dealerId: json["dealerId"]?.toString(),
        dealerNameSnapshot: json["dealerNameSnapshot"]?.toString(),
        dealerMobile: json["dealerMobile"]?.toString(),
        zone: json["zone"]?.toString(),
        area: json["area"]?.toString(),
        route: json["route"]?.toString(),
        objective: json["objective"]?.toString(),
        visitType: json["visitType"]?.toString(),
        requiredVisitCount: json["requiredVisitCount"] is int
            ? json["requiredVisitCount"]
            : int.tryParse(json["requiredVisitCount"]?.toString() ?? ''),
        week: json["week"]?.toString(),
        taskDate: DateTime.parse(json["taskDate"]),
        status: json["status"]?.toString() ?? 'Assigned',
        createdAt: json["createdAt"] == null
            ? null
            : DateTime.parse(json["createdAt"]),
        updatedAt: json["updatedAt"] == null
            ? null
            : DateTime.parse(json["updatedAt"]),
      );

  Map<String, dynamic> toJson() => {
        "pjpBatchId": pjpBatchId,
        "userId": userId,
        "dealerId": dealerId,
        "dealerNameSnapshot": dealerNameSnapshot,
        "dealerMobile": dealerMobile,
        "zone": zone,
        "area": area,
        "route": route,
        "objective": objective,
        "visitType": visitType,
        "requiredVisitCount": requiredVisitCount,
        "week": week,
        "taskDate": taskDate.toIso8601String(),
        "status": status,
      };
}