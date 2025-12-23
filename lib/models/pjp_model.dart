import 'dart:convert';

// --- Helper functions ---
Pjp pjpFromJson(String str) => Pjp.fromJson(json.decode(str));
String pjpToJson(Pjp data) => json.encode(data.toJson());

class Pjp {
  final String id;
  final int userId;
  final int createdById;
  final DateTime planDate;
  final String status; 
  final String? verificationStatus;
  final String areaToBeVisited;
  final String? route; // Specific destination address
  final String? description;
  final String? additionalVisitRemarks; // Admin remarks
  final String? diversionReason;

  // --- Numerical Targets (Excel Columns) ---
  final int plannedNewSiteVisits;
  final int plannedFollowUpSiteVisits;
  final int plannedNewDealerVisits;
  final int plannedInfluencerVisits;
  
  // --- Business Value Targets ---
  final int noOfConvertedBags;
  final int noOfMasonPcSchemes;

  // --- Influencer / PC-Mason Focus ---
  final String? influencerName;
  final String? influencerPhone;
  final String? activityType;
  
  // --- Relationship IDs ---
  final String? dealerId;
  final String? dealerName; // Helper for UI
  final String? siteId;
  final String? siteName; // Helper for UI

  final DateTime createdAt;
  final DateTime updatedAt;

  Pjp({
    required this.id,
    required this.userId,
    required this.createdById,
    required this.planDate,
    required this.status,
    required this.areaToBeVisited,
    this.route,
    this.verificationStatus,
    this.description,
    this.additionalVisitRemarks,
    this.diversionReason,
    this.plannedNewSiteVisits = 0,
    this.plannedFollowUpSiteVisits = 0,
    this.plannedNewDealerVisits = 0,
    this.plannedInfluencerVisits = 0,
    this.noOfConvertedBags = 0,
    this.noOfMasonPcSchemes = 0,
    this.influencerName,
    this.influencerPhone,
    this.activityType,
    this.dealerId,
    this.dealerName,
    this.siteId,
    this.siteName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Pjp.fromJson(Map<String, dynamic> json) {
    // Helper to extract nested dealer info
    String? foundDealerId = json['dealerId']?.toString();
    String? foundDealerName = json['dealerName']?.toString();
    if (json['dealer'] is Map<String, dynamic>) {
      foundDealerId ??= json['dealer']['id']?.toString();
      foundDealerName ??= json['dealer']['name']?.toString();
    }

    // Helper to extract nested site info
    String? foundSiteId = json['siteId']?.toString();
    String? foundSiteName = json['siteName']?.toString();
    if (json['site'] is Map<String, dynamic>) {
      foundSiteId ??= json['site']['id']?.toString();
      foundSiteName ??= json['site']['siteName']?.toString();
    }

    return Pjp(
      id: json['id']?.toString() ?? '',
      userId: json['userId'] is int ? json['userId'] : int.tryParse(json['userId']?.toString() ?? '0') ?? 0,
      createdById: json['createdById'] is int ? json['createdById'] : int.tryParse(json['createdById']?.toString() ?? '0') ?? 0,
      planDate: DateTime.tryParse(json['planDate'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'PENDING',
      verificationStatus: json['verificationStatus'],
      areaToBeVisited: json['areaToBeVisited'] ?? '',
      route: json['route'],
      description: json['description'],
      additionalVisitRemarks: json['additionalVisitRemarks'],
      diversionReason: json['diversionReason'],

      // Numerical Parsers
      plannedNewSiteVisits: json['plannedNewSiteVisits'] ?? 0,
      plannedFollowUpSiteVisits: json['plannedFollowUpSiteVisits'] ?? 0,
      plannedNewDealerVisits: json['plannedNewDealerVisits'] ?? 0,
      plannedInfluencerVisits: json['plannedInfluencerVisits'] ?? 0,
      noOfConvertedBags: json['noOfConvertedBags'] ?? 0,
      noOfMasonPcSchemes: json['noOfMasonPcSchemes'] ?? 0,

      // Influencer Data
      influencerName: json['influencerName'],
      influencerPhone: json['influencerPhone'],
      activityType: json['activityType'],

      dealerId: foundDealerId,
      dealerName: foundDealerName,
      siteId: foundSiteId,
      siteName: foundSiteName,

      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'createdById': createdById,
      'planDate': planDate.toIso8601String().split('T').first, // YYYY-MM-DD
      'status': status,
      'verificationStatus': verificationStatus,
      'areaToBeVisited': areaToBeVisited,
      'route': route,
      'description': description,
      'additionalVisitRemarks': additionalVisitRemarks,
      'diversionReason': diversionReason,
      'plannedNewSiteVisits': plannedNewSiteVisits,
      'plannedFollowUpSiteVisits': plannedFollowUpSiteVisits,
      'plannedNewDealerVisits': plannedNewDealerVisits,
      'plannedInfluencerVisits': plannedInfluencerVisits,
      'noOfConvertedBags': noOfConvertedBags,
      'noOfMasonPcSchemes': noOfMasonPcSchemes,
      'influencerName': influencerName,
      'influencerPhone': influencerPhone,
      'activityType': activityType,
      'dealerId': dealerId,
      'siteId': siteId,
    };
  }
}

class PjpData {
  final List<Pjp> pendingPjps;
  final List<Pjp> verifiedPjps; 

  PjpData({
    required this.pendingPjps,
    required this.verifiedPjps,
  });
}