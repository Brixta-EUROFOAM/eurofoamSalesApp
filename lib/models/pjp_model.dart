// lib/models/pjp_model.dart
class PjpModel {
  final String id;
  final int userId;
  final int createdById;
  final DateTime planDate;
  final String areaToBeVisited;
  final String? description;
  final String status;
  final String? verificationStatus;
  final String? additionalVisitRemarks;
  final int? dealerId;
  final String? visitDealerName;
  final String? bulkOpId;
  final String? idempotencyKey;
  final String? siteId;
  final String? route;
  final String? diversionReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PjpModel({
    required this.id,
    required this.userId,
    required this.createdById,
    required this.planDate,
    required this.areaToBeVisited,
    this.description,
    required this.status,
    this.verificationStatus,
    this.additionalVisitRemarks,
    this.dealerId,
    this.visitDealerName,
    this.bulkOpId,
    this.idempotencyKey,
    this.siteId,
    this.route,
    this.diversionReason,
    this.createdAt,
    this.updatedAt,
  });

  factory PjpModel.fromJson(Map<String, dynamic> json) {
    return PjpModel(
      id: json['id'],
      userId: json['userId'],
      createdById: json['createdById'],
      planDate: DateTime.parse(json['planDate']),
      areaToBeVisited: json['areaToBeVisited'],
      description: json['description'],
      status: json['status'],
      verificationStatus: json['verificationStatus'],
      additionalVisitRemarks: json['additionalVisitRemarks'],
      dealerId: json['dealerId'],
      visitDealerName: json['visitDealerName'] ?? json['dealerName'],
      bulkOpId: json['bulkOpId'],
      idempotencyKey: json['idempotencyKey'],
      siteId: json['siteId'],
      route: json['route'],
      diversionReason: json['diversionReason'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'createdById': createdById,
      'planDate': planDate.toIso8601String(),
      'areaToBeVisited': areaToBeVisited,
      'description': description,
      'status': status,
      'verificationStatus': verificationStatus,
      'additionalVisitRemarks': additionalVisitRemarks,
      'dealerId': dealerId,
      'visitDealerName': visitDealerName,
      'bulkOpId': bulkOpId,
      'idempotencyKey': idempotencyKey,
      'siteId': siteId,
      'route': route,
      'diversionReason': diversionReason,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}