// lib/models/daily_task_model.dart
import 'dart:convert';

DailyTask dailyTaskFromJson(String str) => DailyTask.fromJson(json.decode(str));
String dailyTaskToJson(DailyTask data) => json.encode(data.toJson());

class DailyTask {
    final String? id;
    final int userId;
    final int assignedByUserId;
    final DateTime taskDate;
    final String visitType;
    
    // Dealer references
    final String? relatedDealerId; // For "dealers" table (string ID)
    final int? relatedVerifiedDealerId; // For "verifiedDealers" table (int ID)
    
    final String? siteName;
    final String? description;
    final String status;
    
    // Additional info from schema
    final String? dealerName;
    final String? dealerCategory;
    final String? pjpCycle;
    
    // PJP & Site links
    final String? pjpId;
    final String? siteId; // UUID from technicalSites

    final DateTime? createdAt;
    final DateTime? updatedAt;

    DailyTask({
        this.id,
        required this.userId,
        required this.assignedByUserId,
        required this.taskDate,
        required this.visitType,
        this.relatedDealerId,
        this.relatedVerifiedDealerId,
        this.siteName,
        this.description,
        required this.status,
        this.dealerName,
        this.dealerCategory,
        this.pjpCycle,
        this.pjpId,
        this.siteId,
        this.createdAt,
        this.updatedAt,
    });

    factory DailyTask.fromJson(Map<String, dynamic> json) => DailyTask(
        id: json["id"]?.toString(),
        userId: json["userId"] is int ? json["userId"] : int.tryParse(json["userId"].toString()) ?? 0,
        assignedByUserId: json["assignedByUserId"] is int ? json["assignedByUserId"] : int.tryParse(json["assignedByUserId"].toString()) ?? 0,
        taskDate: DateTime.parse(json["taskDate"]),
        visitType: json["visitType"] ?? '',
        
        relatedDealerId: json["relatedDealerId"]?.toString(),
        relatedVerifiedDealerId: json["relatedVerifiedDealerId"] is int ? json["relatedVerifiedDealerId"] : int.tryParse(json["relatedVerifiedDealerId"]?.toString() ?? ''),

        siteName: json["siteName"],
        description: json["description"],
        status: json["status"] ?? 'Assigned',
        
        dealerName: json["dealerName"],
        dealerCategory: json["dealerCategory"],
        pjpCycle: json["pjpCycle"],
        
        pjpId: json["pjpId"]?.toString(),
        siteId: json["siteId"]?.toString(),

        createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
        updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
    );

    /// Converts the object into a Map for creating a new task.
    Map<String, dynamic> toJson() => {
        "userId": userId,
        "assignedByUserId": assignedByUserId,
        "taskDate": taskDate.toIso8601String(),
        "visitType": visitType,
        "relatedDealerId": relatedDealerId,
        "relatedVerifiedDealerId": relatedVerifiedDealerId,
        "siteName": siteName,
        "description": description,
        "status": status,
        "dealerName": dealerName,
        "dealerCategory": dealerCategory,
        "pjpCycle": pjpCycle,
        "pjpId": pjpId,
        "siteId": siteId,
    };
}