// lib/technicalSide/models/technical_visit_report_model.dart
import 'dart:convert';

TechnicalVisitReport technicalVisitReportFromJson(String str) => TechnicalVisitReport.fromJson(json.decode(str));
String technicalVisitReportToJson(TechnicalVisitReport data) => json.encode(data.toJson());

class TechnicalVisitReport {
    final String? id;
    final int userId;
    final DateTime reportDate;
    
    // --- Contact & Location ---
    final String siteNameConcernedPerson;
    final String phoneNo;
    final String? whatsappNo; // NEW
    final String? emailId;
    final String? siteAddress; // NEW
    final String? marketName; // NEW
    final String? region; // NEW
    final String? area; // NEW
    final double? latitude; // NEW
    final double? longitude; // NEW

    // --- Visit Specifics ---
    final String visitType;
    final String? visitCategory; // NEW
    final String? customerType; // NEW
    final String? purposeOfVisit; // NEW
    
    // --- Construction & Stock ---
    final String? siteVisitStage;
    final int? constAreaSqFt; // NEW
    final List<String> siteVisitBrandInUse;
    final double? currentBrandPrice; // NEW
    final double? siteStock; // NEW
    final double? estRequirement; // NEW

    // --- Dealers ---
    final String? supplyingDealerName; // NEW
    final String? nearbyDealerName; // NEW
    final String? associatedPartyName; // Legacy
    final String? channelPartnerVisit; // Legacy

    // --- Conversion ---
    final bool? isConverted; // NEW
    final String? conversionType; // NEW
    final String? conversionFromBrand;
    final double? conversionQuantityValue;
    final String? conversionQuantityUnit;

    // --- Technical Services ---
    final bool? isTechService; // NEW
    final String? serviceDesc; // NEW
    final String? serviceType;
    final String? dhalaiVerificationCode; // NEW
    final String? isVerificationStatus; // NEW
    final String? qualityComplaint;

    // --- Influencer / Mason ---
    final String? influencerName; // NEW
    final String? influencerPhone; // NEW
    final bool? isSchemeEnrolled; // NEW
    final String? influencerProductivity; // NEW
    final List<String> influencerType;

    // --- Remarks ---
    final String clientsRemarks;
    final String salespersonRemarks;
    final String? promotionalActivity;

    // --- Time & Images ---
    final DateTime checkInTime;
    final DateTime? checkOutTime;
    final String? timeSpentinLoc; // NEW
    final String? inTimeImageUrl;
    final String? outTimeImageUrl;
    final String? sitePhotoUrl; // NEW

    // --- Meta / IDs ---
    final String? siteVisitType;
    final String? meetingId;
    final String? pjpId; // NEW
    final String? masonId; // NEW
    final String? siteId; // NEW
    
    final DateTime? createdAt;
    final DateTime? updatedAt;
    
    // --- Counters ---
    final int? siteVisitsCount;
    final int? otherVisitsCount;
    final int? totalVisitsCount;
    final DateTime? firstVisitTime;
    final DateTime? lastVisitTime;
    final String? firstVisitDay;
    final String? lastVisitDay;

    TechnicalVisitReport({
        this.id,
        required this.userId,
        required this.reportDate,
        required this.visitType,
        required this.siteNameConcernedPerson,
        required this.phoneNo,
        this.whatsappNo,
        this.emailId,
        this.siteAddress,
        this.marketName,
        this.region,
        this.area,
        this.latitude,
        this.longitude,
        this.visitCategory,
        this.customerType,
        this.purposeOfVisit,
        this.siteVisitStage,
        this.constAreaSqFt,
        required this.siteVisitBrandInUse,
        this.currentBrandPrice,
        this.siteStock,
        this.estRequirement,
        this.supplyingDealerName,
        this.nearbyDealerName,
        this.associatedPartyName,
        this.channelPartnerVisit,
        this.isConverted,
        this.conversionType,
        this.conversionFromBrand,
        this.conversionQuantityValue,
        this.conversionQuantityUnit,
        this.isTechService,
        this.serviceDesc,
        this.serviceType,
        this.dhalaiVerificationCode,
        this.isVerificationStatus,
        this.qualityComplaint,
        this.influencerName,
        this.influencerPhone,
        this.isSchemeEnrolled,
        this.influencerProductivity,
        required this.influencerType,
        required this.clientsRemarks,
        required this.salespersonRemarks,
        this.promotionalActivity,
        required this.checkInTime,
        this.checkOutTime,
        this.timeSpentinLoc,
        this.inTimeImageUrl,
        this.outTimeImageUrl,
        this.sitePhotoUrl,
        this.siteVisitType,
        this.meetingId,
        this.pjpId,
        this.masonId,
        this.siteId,
        this.createdAt,
        this.updatedAt,
        this.siteVisitsCount,
        this.otherVisitsCount,
        this.totalVisitsCount,
        this.firstVisitTime,
        this.lastVisitTime,
        this.firstVisitDay,
        this.lastVisitDay,
    });

    factory TechnicalVisitReport.fromJson(Map<String, dynamic> json) => TechnicalVisitReport(
        id: json["id"],
        userId: json["userId"],
        reportDate: DateTime.parse(json["reportDate"]),
        visitType: json["visitType"],
        siteNameConcernedPerson: json["siteNameConcernedPerson"],
        phoneNo: json["phoneNo"],
        whatsappNo: json["whatsappNo"],
        emailId: json["emailId"],
        siteAddress: json["siteAddress"],
        marketName: json["marketName"],
        region: json["region"],
        area: json["area"],
        // Safe parsing for doubles
        latitude: json["latitude"] == null ? null : double.tryParse(json["latitude"].toString()),
        longitude: json["longitude"] == null ? null : double.tryParse(json["longitude"].toString()),
        
        visitCategory: json["visitCategory"],
        customerType: json["customerType"],
        purposeOfVisit: json["purposeOfVisit"],
        
        siteVisitStage: json["siteVisitStage"],
        constAreaSqFt: json["constAreaSqFt"], // int
        siteVisitBrandInUse: List<String>.from(json["siteVisitBrandInUse"].map((x) => x)),
        currentBrandPrice: json["currentBrandPrice"] == null ? null : double.tryParse(json["currentBrandPrice"].toString()),
        siteStock: json["siteStock"] == null ? null : double.tryParse(json["siteStock"].toString()),
        estRequirement: json["estRequirement"] == null ? null : double.tryParse(json["estRequirement"].toString()),
        
        supplyingDealerName: json["supplyingDealerName"],
        nearbyDealerName: json["nearbyDealerName"],
        associatedPartyName: json["associatedPartyName"],
        channelPartnerVisit: json["channelPartnerVisit"],
        
        isConverted: json["isConverted"], // bool
        conversionType: json["conversionType"],
        conversionFromBrand: json["conversionFromBrand"],
        conversionQuantityValue: json["conversionQuantityValue"] == null ? null : double.tryParse(json["conversionQuantityValue"].toString()),
        conversionQuantityUnit: json["conversionQuantityUnit"],
        
        isTechService: json["isTechService"], // bool
        serviceDesc: json["serviceDesc"],
        serviceType: json["serviceType"],
        dhalaiVerificationCode: json["dhalaiVerificationCode"],
        isVerificationStatus: json["isVerificationStatus"],
        qualityComplaint: json["qualityComplaint"],
        
        influencerName: json["influencerName"],
        influencerPhone: json["influencerPhone"],
        isSchemeEnrolled: json["isSchemeEnrolled"], // bool
        influencerProductivity: json["influencerProductivity"],
        influencerType: List<String>.from(json["influencerType"].map((x) => x)),
        
        clientsRemarks: json["clientsRemarks"],
        salespersonRemarks: json["salespersonRemarks"],
        promotionalActivity: json["promotionalActivity"],
        
        checkInTime: DateTime.parse(json["checkInTime"]),
        checkOutTime: json["checkOutTime"] == null ? null : DateTime.parse(json["checkOutTime"]),
        timeSpentinLoc: json["timeSpentinLoc"],
        inTimeImageUrl: json["inTimeImageUrl"],
        outTimeImageUrl: json["outTimeImageUrl"],
        sitePhotoUrl: json["sitePhotoUrl"],
        
        siteVisitType: json["siteVisitType"],
        meetingId: json["meetingId"],
        pjpId: json["pjpId"],
        masonId: json["masonId"],
        siteId: json["siteId"],
        
        createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
        updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
        
        firstVisitTime: json["firstVisitTime"] == null ? null : DateTime.parse(json["firstVisitTime"]),
        lastVisitTime: json["lastVisitTime"] == null ? null : DateTime.parse(json["lastVisitTime"]),
        firstVisitDay: json["firstVisitDay"],
        lastVisitDay: json["lastVisitDay"],
        siteVisitsCount: json["siteVisitsCount"],
        otherVisitsCount: json["otherVisitsCount"],
        totalVisitsCount: json["totalVisitsCount"],
    );

    Map<String, dynamic> toJson() => {
        "userId": userId,
        "reportDate": reportDate.toIso8601String(),
        "visitType": visitType,
        "siteNameConcernedPerson": siteNameConcernedPerson,
        "phoneNo": phoneNo,
        "whatsappNo": whatsappNo,
        "emailId": emailId,
        "siteAddress": siteAddress,
        "marketName": marketName,
        "region": region,
        "area": area,
        "latitude": latitude?.toString(), // Send as string/number depending on backend expectation
        "longitude": longitude?.toString(),
        
        "visitCategory": visitCategory,
        "customerType": customerType,
        "purposeOfVisit": purposeOfVisit,
        
        "siteVisitStage": siteVisitStage,
        "constAreaSqFt": constAreaSqFt,
        "siteVisitBrandInUse": List<dynamic>.from(siteVisitBrandInUse.map((x) => x)),
        "currentBrandPrice": currentBrandPrice?.toString(),
        "siteStock": siteStock?.toString(),
        "estRequirement": estRequirement?.toString(),
        
        "supplyingDealerName": supplyingDealerName,
        "nearbyDealerName": nearbyDealerName,
        "associatedPartyName": associatedPartyName,
        "channelPartnerVisit": channelPartnerVisit,
        
        "isConverted": isConverted,
        "conversionType": conversionType,
        "conversionFromBrand": conversionFromBrand,
        "conversionQuantityValue": conversionQuantityValue?.toString(),
        "conversionQuantityUnit": conversionQuantityUnit,
        
        "isTechService": isTechService,
        "serviceDesc": serviceDesc,
        "serviceType": serviceType,
        "dhalaiVerificationCode": dhalaiVerificationCode,
        "isVerificationStatus": isVerificationStatus,
        "qualityComplaint": qualityComplaint,
        
        "influencerName": influencerName,
        "influencerPhone": influencerPhone,
        "isSchemeEnrolled": isSchemeEnrolled,
        "influencerProductivity": influencerProductivity,
        "influencerType": List<dynamic>.from(influencerType.map((x) => x)),
        
        "clientsRemarks": clientsRemarks,
        "salespersonRemarks": salespersonRemarks,
        "promotionalActivity": promotionalActivity,
        
        "checkInTime": checkInTime.toIso8601String(),
        "checkOutTime": checkOutTime?.toIso8601String(),
        "timeSpentinLoc": timeSpentinLoc,
        "inTimeImageUrl": inTimeImageUrl,
        "outTimeImageUrl": outTimeImageUrl,
        "sitePhotoUrl": sitePhotoUrl,
        
        "siteVisitType": siteVisitType,
        "meetingId": meetingId,
        "pjpId": pjpId,
        "masonId": masonId,
        "siteId": siteId,

        // Optional: Include counters if you need to send them back, though usually read-only
        "siteVisitsCount": siteVisitsCount,
        "otherVisitsCount": otherVisitsCount,
        "totalVisitsCount": totalVisitsCount,
    };
}