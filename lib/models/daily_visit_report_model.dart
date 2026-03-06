// lib/models/daily_visit_report_model.dart
import 'dart:convert';

DailyVisitReport dailyVisitReportFromJson(String str) =>
    DailyVisitReport.fromJson(json.decode(str));
String dailyVisitReportToJson(DailyVisitReport data) =>
    json.encode(data.toJson());

class DailyVisitReport {
  final String? id;
  final int userId;
  final String? dealerId;
  final String? subDealerId;
  final DateTime reportDate;
  final String dealerType;
  final String? dealerName;
  final String? subDealerName;
  final double? overdueAmount;
  final String? timeSpentinLoc;

  final String? customerType;
  final String? partyType;
  final String? nameOfParty;
  final String? contactNoOfParty;
  final DateTime? expectedActivationDate;

  final String location;
  final double latitude;
  final double longitude;
  final String visitType;
  final double dealerTotalPotential;
  final double dealerBestPotential;
  final List<String> brandSelling;
  final String? contactPerson;
  final String? contactPersonPhoneNo;
  final double todayOrderMt;
  final double todayCollectionRupees;
  final String feedbacks;
  final String? solutionBySalesperson;
  final String? anyRemarks;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String? inTimeImageUrl;
  final String? outTimeImageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? pjpId;

  DailyVisitReport({
    this.id,
    required this.userId,
    this.dealerId,
    this.subDealerId,
    required this.reportDate,
    required this.dealerType,
    this.dealerName,
    this.subDealerName,
    this.customerType,
    this.partyType,
    this.nameOfParty,
    this.contactNoOfParty,
    this.expectedActivationDate,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.visitType,
    required this.dealerTotalPotential,
    required this.dealerBestPotential,
    required this.brandSelling,
    this.contactPerson,
    this.contactPersonPhoneNo,
    required this.todayOrderMt,
    required this.todayCollectionRupees,
    this.overdueAmount,
    this.timeSpentinLoc,
    required this.feedbacks,
    this.solutionBySalesperson,
    this.anyRemarks,
    required this.checkInTime,
    this.checkOutTime,
    this.inTimeImageUrl,
    this.outTimeImageUrl,
    this.createdAt,
    this.updatedAt,
    this.pjpId,
  });

  factory DailyVisitReport.fromJson(Map<String, dynamic> json) {
    List<String> parseBrandSelling(dynamic jsonField) {
      if (jsonField is List) {
        return jsonField.map((e) => e.toString()).toList();
      }
      if (jsonField is String) {
        return jsonField.split(',').map((e) => e.trim()).toList();
      }
      return [];
    }

    String? foundDealerName = json['dealerName']?.toString();
    if (json['dealer'] is Map<String, dynamic>) {
      foundDealerName ??= json['dealer']['name']?.toString();
    }

    return DailyVisitReport(
      id: json['id']?.toString(),
      userId: json['userId'] ?? 0,
      dealerId: json['dealerId']?.toString(),
      subDealerId: json['subDealerId']?.toString(),
      reportDate: DateTime.tryParse(json['reportDate'] ?? '') ?? DateTime.now(),
      dealerType: json['dealerType'] ?? 'Unknown',
      dealerName: foundDealerName,
      subDealerName: json['subDealerName'],
      customerType: json['customerType']?.toString() ?? json['customer_type']?.toString(),
      partyType: json['partyType']?.toString() ?? json['party_type']?.toString(),
      nameOfParty: json['nameOfParty']?.toString() ?? json['name_of_party']?.toString(),
      contactNoOfParty: json['contactNoOfParty']?.toString() ?? json['contact_no_of_party']?.toString(),
      expectedActivationDate: DateTime.tryParse(
        json['expectedActivationDate'] ?? '',
      ),
      location: json['location'] ?? 'Unknown Location',
      latitude: double.tryParse(json['latitude']?.toString() ?? '0.0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0.0') ?? 0.0,
      visitType: json['visitType'] ?? 'PLANNED',
      dealerTotalPotential:
          double.tryParse(json['dealerTotalPotential']?.toString() ?? '0.0') ??
          0.0,
      dealerBestPotential:
          double.tryParse(json['dealerBestPotential']?.toString() ?? '0.0') ??
          0.0,
      brandSelling: parseBrandSelling(json['brandSelling']),
      contactPerson: json['contactPerson'],
      contactPersonPhoneNo: json['contactPersonPhoneNo'],
      todayOrderMt:
          double.tryParse(json['todayOrderMt']?.toString() ?? '0.0') ?? 0.0,
      todayCollectionRupees:
          double.tryParse(json['todayCollectionRupees']?.toString() ?? '0.0') ??
          0.0,
      overdueAmount: double.tryParse(json['overdueAmount']?.toString() ?? ''),
      timeSpentinLoc: json['timeSpentinLoc']?.toString(),
      feedbacks: json['feedbacks'] ?? '',
      solutionBySalesperson: json['solutionBySalesperson'],
      anyRemarks: json['anyRemarks'],
      checkInTime:
          DateTime.tryParse(json['checkInTime'] ?? '') ?? DateTime.now(),
      checkOutTime: DateTime.tryParse(json['checkOutTime'] ?? ''),
      inTimeImageUrl: json['inTimeImageUrl'],
      outTimeImageUrl: json['outTimeImageUrl'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? ''),
      pjpId: json['pjpId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'userId': userId,
      'dealerId': dealerId,
      'subDealerId': subDealerId,
      'reportDate': reportDate.toIso8601String().split('T').first,
      'dealerType': dealerType,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'visitType': visitType,
      'customerType': customerType,
      'partyType': partyType,
      'nameOfParty': nameOfParty,
      'contactNoOfParty': contactNoOfParty,
      'expectedActivationDate': expectedActivationDate
          ?.toIso8601String()
          .split('T')
          .first,
      'dealerTotalPotential': dealerTotalPotential,
      'dealerBestPotential': dealerBestPotential,
      'brandSelling': brandSelling,
      'contactPerson': contactPerson,
      'contactPersonPhoneNo': contactPersonPhoneNo,
      'todayOrderMt': todayOrderMt,
      'todayCollectionRupees': todayCollectionRupees,
      'overdueAmount': overdueAmount,
      'timeSpentinLoc': timeSpentinLoc,
      'feedbacks': feedbacks,
      'solutionBySalesperson': solutionBySalesperson,
      'anyRemarks': anyRemarks,
      'checkInTime': checkInTime.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'inTimeImageUrl': inTimeImageUrl,
      'outTimeImageUrl': outTimeImageUrl,
      'pjpId': pjpId,
    };

    data.removeWhere((key, value) => value == null);
    return data;
  }
}
