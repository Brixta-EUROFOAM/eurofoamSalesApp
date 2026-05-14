// lib/models/dvr_model.dart
class DvrModel {
  final String id;
  final DateTime? reportDate;
  final String? dealerType;
  final String? visitType;
  final String? location;
  final double? latitude;
  final double? longitude;
  final List<String>? brandSelling;

  final String? nameOfParty;
  final String? contactNoOfParty;
  final DateTime? expectedActivationDate;
  final double? currentDealerOutstandingAmt;

  final double? todayOrderQty;
  final double? todayCollectionRupees;
  final double? overdueAmount;
  final String? feedbacks;

  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? timeSpentinLoc;
  final String? inTimeImageUrl;
  final String? outTimeImageUrl;
  
  final int userId;
  final String? pjpId;
  final int? dealerId;
  final String? idempotencyKey;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DvrModel({
    required this.id,
    this.reportDate,
    this.dealerType,
    this.visitType,
    this.location,
    this.latitude,
    this.longitude,
    this.brandSelling,
    this.nameOfParty,
    this.contactNoOfParty,
    this.expectedActivationDate,
    this.currentDealerOutstandingAmt,
    this.todayOrderQty,
    this.todayCollectionRupees,
    this.overdueAmount,
    this.feedbacks,
    this.checkInTime,
    this.checkOutTime,
    this.timeSpentinLoc,
    this.inTimeImageUrl,
    this.outTimeImageUrl,
    required this.userId,
    this.pjpId,
    this.dealerId,
    this.idempotencyKey,
    this.createdAt,
    this.updatedAt,
  });

  factory DvrModel.fromJson(Map<String, dynamic> json) {
    return DvrModel(
      id: json['id'],
      reportDate: json['reportDate'] != null ? DateTime.parse(json['reportDate']) : null,
      dealerType: json['dealerType'],
      visitType: json['visitType'],
      location: json['location'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      brandSelling: (json['brandSelling'] as List?)?.map((e) => e.toString()).toList(),
      nameOfParty: json['nameOfParty'],
      contactNoOfParty: json['contactNoOfParty'],
      expectedActivationDate: json['expectedActivationDate'] != null ? DateTime.parse(json['expectedActivationDate']) : null,
      currentDealerOutstandingAmt: (json['currentDealerOutstandingAmt'] as num?)?.toDouble(),
      todayOrderQty: (json['todayOrderQty'] as num?)?.toDouble(),
      todayCollectionRupees: (json['todayCollectionRupees'] as num?)?.toDouble(),
      overdueAmount: (json['overdueAmount'] as num?)?.toDouble(),
      feedbacks: json['feedbacks'],
      checkInTime: json['checkInTime'] != null ? DateTime.parse(json['checkInTime']).toLocal() : null,
      checkOutTime: json['checkOutTime'] != null ? DateTime.parse(json['checkOutTime']).toLocal() : null,
      timeSpentinLoc: json['timeSpentinLoc'],
      inTimeImageUrl: json['inTimeImageUrl'],
      outTimeImageUrl: json['outTimeImageUrl'],
      userId: json['userId'],
      pjpId: json['pjpId'],
      dealerId: json['dealerId'],
      idempotencyKey: json['idempotencyKey'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']).toLocal() : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']).toLocal() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reportDate': reportDate?.toIso8601String().split('T')[0],
      'dealerType': dealerType,
      'visitType': visitType,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'brandSelling': brandSelling,
      'nameOfParty': nameOfParty,
      'contactNoOfParty': contactNoOfParty,
      'expectedActivationDate': expectedActivationDate?.toIso8601String().split('T')[0],
      'currentDealerOutstandingAmt': currentDealerOutstandingAmt,
      'todayOrderQty': todayOrderQty,
      'todayCollectionRupees': todayCollectionRupees,
      'overdueAmount': overdueAmount,
      'feedbacks': feedbacks,
      'checkInTime': checkInTime?.toUtc().toIso8601String(),
      'checkOutTime': checkOutTime?.toUtc().toIso8601String(),
      'timeSpentinLoc': timeSpentinLoc,
      'inTimeImageUrl': inTimeImageUrl,
      'outTimeImageUrl': outTimeImageUrl,
      'userId': userId,
      'pjpId': pjpId,
      'dealerId': dealerId,
      'idempotencyKey': idempotencyKey,
      'createdAt': createdAt?.toUtc().toIso8601String(),
      'updatedAt': updatedAt?.toUtc().toIso8601String(),
    };
  }
}