import 'dart:convert';// You might need this

// Helper functions (unchanged)
DailyVisitReport dailyVisitReportFromJson(String str) =>
    DailyVisitReport.fromJson(json.decode(str));
String dailyVisitReportToJson(DailyVisitReport data) =>
    json.encode(data.toJson());

class DailyVisitReport {
  final String? id;
  final int userId;
  final DateTime reportDate;
  final String dealerType;
  final String? dealerName;
  final String? subDealerName;
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
  final double? overdueAmount;
  final String feedbacks;
  final String? solutionBySalesperson;
  final String? anyRemarks;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String? inTimeImageUrl;
  final String? outTimeImageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // --- ✅ ADD THIS FIELD ---
  final String? pjpId; 

  DailyVisitReport({
    this.id,
    required this.userId,
    required this.reportDate,
    required this.dealerType,
    this.dealerName,
    this.subDealerName,
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
    required this.feedbacks,
    this.solutionBySalesperson,
    this.anyRemarks,
    required this.checkInTime,
    this.checkOutTime,
    this.inTimeImageUrl,
    this.outTimeImageUrl,
    this.createdAt,
    this.updatedAt,
    
    // --- ✅ ADD THIS TO THE CONSTRUCTOR ---
    this.pjpId, 
  });

  // --- (Your fromJson factory is probably fine, but double-check) ---
  factory DailyVisitReport.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse brandSelling
    List<String> _parseBrandSelling(dynamic jsonField) {
      if (jsonField is List) {
        return jsonField.map((e) => e.toString()).toList();
      }
      if (jsonField is String) {
        // Handle comma-separated string just in case
        return jsonField.split(',').map((e) => e.trim()).toList();
      }
      return [];
    }
    
    // Find dealer name
    String? foundDealerName = json['dealerName']?.toString();
    if (json['dealer'] is Map<String, dynamic>) {
      foundDealerName ??= json['dealer']['name']?.toString();
    }

    return DailyVisitReport(
      id: json['id']?.toString(),
      userId: json['userId'] ?? 0,
      reportDate: DateTime.tryParse(json['reportDate'] ?? '') ?? DateTime.now(),
      dealerType: json['dealerType'] ?? 'Unknown',
      dealerName: foundDealerName,
      subDealerName: json['subDealerName'],
      location: json['location'] ?? 'Unknown Location',
      latitude: double.tryParse(json['latitude']?.toString() ?? '0.0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0.0') ?? 0.0,
      visitType: json['visitType'] ?? 'PLANNED',
      dealerTotalPotential: double.tryParse(json['dealerTotalPotential']?.toString() ?? '0.0') ?? 0.0,
      dealerBestPotential: double.tryParse(json['dealerBestPotential']?.toString() ?? '0.0') ?? 0.0,
      brandSelling: _parseBrandSelling(json['brandSelling']),
      contactPerson: json['contactPerson'],
      contactPersonPhoneNo: json['contactPersonPhoneNo'],
      todayOrderMt: double.tryParse(json['todayOrderMt']?.toString() ?? '0.0') ?? 0.0,
      todayCollectionRupees: double.tryParse(json['todayCollectionRupees']?.toString() ?? '0.0') ?? 0.0,
      overdueAmount: double.tryParse(json['overdueAmount']?.toString() ?? ''),
      feedbacks: json['feedbacks'] ?? '',
      solutionBySalesperson: json['solutionBySalesperson'],
      anyRemarks: json['anyRemarks'],
      checkInTime: DateTime.tryParse(json['checkInTime'] ?? '') ?? DateTime.now(),
      checkOutTime: DateTime.tryParse(json['checkOutTime'] ?? ''),
      inTimeImageUrl: json['inTimeImageUrl'],
      outTimeImageUrl: json['outTimeImageUrl'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? ''),
      
      // --- ✅ ADD THIS TO fromJson ---
      pjpId: json['pjpId']?.toString(), 
    );
  }

  // --- (Your toJson method needs to be updated) ---
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'reportDate': reportDate.toIso8601String().split('T').first, // YYYY-MM-DD
      'dealerType': dealerType,
      'dealerName': dealerName,
      'subDealerName': subDealerName,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'visitType': visitType,
      'dealerTotalPotential': dealerTotalPotential,
      'dealerBestPotential': dealerBestPotential,
      'brandSelling': brandSelling,
      'contactPerson': contactPerson,
      'contactPersonPhoneNo': contactPersonPhoneNo,
      'todayOrderMt': todayOrderMt,
      'todayCollectionRupees': todayCollectionRupees,
      'overdueAmount': overdueAmount,
      'feedbacks': feedbacks,
      'solutionBySalesperson': solutionBySalesperson,
      'anyRemarks': anyRemarks,
      'checkInTime': checkInTime.toIso8601String(), // Full ISO string
      'checkOutTime': checkOutTime?.toIso8601String(), // Full ISO string
      'inTimeImageUrl': inTimeImageUrl,
      'outTimeImageUrl': outTimeImageUrl,
      
      // --- ✅ ADD THIS TO toJson ---
      'pjpId': pjpId,
    };
  }
}