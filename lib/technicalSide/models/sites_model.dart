// lib/technicalSide/models/sites_model.dart
//import 'dart:convert';

class TechnicalSite {
  final String? id;
  final String siteName;
  final String concernedPerson;
  final String phoneNo;
  final String address;
  final double latitude;
  final double longitude;
  final String? siteType;
  final String? area;
  final String? region;
  final String? stageOfConstruction;
  final DateTime? constructionStartDate;
  final String? relatedDealerId;
  final String? relatedMasonId; // UUID for mason_pc_side

  TechnicalSite({
    this.id,
    required this.siteName,
    required this.concernedPerson,
    required this.phoneNo,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.siteType,
    this.area,
    this.region,
    this.stageOfConstruction,
    this.constructionStartDate,
    this.relatedDealerId,
    this.relatedMasonId,
  });

  factory TechnicalSite.fromJson(Map<String, dynamic> json) {
    return TechnicalSite(
      id: json['id'],
      siteName: json['siteName'] ?? '',
      concernedPerson: json['concernedPerson'] ?? '',
      phoneNo: json['phoneNo'] ?? '',
      address: json['address'] ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      siteType: json['siteType'],
      area: json['area'],
      region: json['region'],
      stageOfConstruction: json['stageOfConstruction'],
      constructionStartDate: json['constructionStartDate'] != null 
          ? DateTime.tryParse(json['constructionStartDate']) 
          : null,
      relatedDealerId: json['relatedDealerID'], // Note: API usually returns camelCase, DB is mixed. Check casing.
      relatedMasonId: json['relatedMasonpcID'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'siteName': siteName,
      'concernedPerson': concernedPerson,
      'phoneNo': phoneNo,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'siteType': siteType,
      'area': area,
      'region': region,
      'stageOfConstruction': stageOfConstruction,
      'constructionStartDate': constructionStartDate?.toIso8601String(),
      'relatedDealerID': relatedDealerId,
      'relatedMasonpcID': relatedMasonId,
    };
  }
}