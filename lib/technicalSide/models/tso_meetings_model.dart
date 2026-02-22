// lib/technicalSide/models/tso_meetings_model.dart

class TsoMeeting {
  final String? id;
  final int createdByUserId;
  final String? type;
  final DateTime? date;
  
  // Zod specific fields from your route
  final String? location;
  final double? budgetAllocated;
  
  // Drizzle pgTable specific fields
  final int? participantsCount;
  final String? zone;
  final String? market;
  final String? dealerName;
  final String? dealerAddress;
  final String? conductedBy;
  final String? giftType;
  final String? accountJsbJud;
  final double? totalExpenses;
  final bool? billSubmitted;
  final String? meetImageUrl;
  final String? siteId;
  
  // Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TsoMeeting({
    this.id,
    required this.createdByUserId,
    this.type,
    this.date,
    this.location,
    this.budgetAllocated,
    this.participantsCount,
    this.zone,
    this.market,
    this.dealerName,
    this.dealerAddress,
    this.conductedBy,
    this.giftType,
    this.accountJsbJud,
    this.totalExpenses,
    this.billSubmitted,
    this.meetImageUrl,
    this.siteId,
    this.createdAt,
    this.updatedAt,
  });

  factory TsoMeeting.fromJson(Map<String, dynamic> json) {
    return TsoMeeting(
      id: json['id']?.toString(),
      createdByUserId: json['createdByUserId'] is int 
          ? json['createdByUserId'] 
          : int.tryParse(json['createdByUserId']?.toString() ?? '0') ?? 0,
      type: json['type']?.toString(),
      date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) : null,
      location: json['location']?.toString(),
      budgetAllocated: json['budgetAllocated'] != null 
          ? double.tryParse(json['budgetAllocated'].toString()) 
          : null,
      participantsCount: json['participantsCount'] is int 
          ? json['participantsCount'] 
          : int.tryParse(json['participantsCount']?.toString() ?? ''),
      zone: json['zone']?.toString(),
      market: json['market']?.toString(),
      dealerName: json['dealerName']?.toString(),
      dealerAddress: json['dealerAddress']?.toString(),
      conductedBy: json['conductedBy']?.toString(),
      giftType: json['giftType']?.toString(),
      accountJsbJud: json['accountJsbJud']?.toString(),
      totalExpenses: json['totalExpenses'] != null 
          ? double.tryParse(json['totalExpenses'].toString()) 
          : null,
      billSubmitted: json['billSubmitted'] as bool?,
      meetImageUrl: json['meetImageUrl']?.toString(),
      siteId: json['siteId']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'createdByUserId': createdByUserId,
      if (type != null) 'type': type,
      if (date != null) 'date': date!.toIso8601String(),
      if (location != null) 'location': location,
      if (budgetAllocated != null) 'budgetAllocated': budgetAllocated,
      if (participantsCount != null) 'participantsCount': participantsCount,
      if (zone != null) 'zone': zone,
      if (market != null) 'market': market,
      if (dealerName != null) 'dealerName': dealerName,
      if (dealerAddress != null) 'dealerAddress': dealerAddress,
      if (conductedBy != null) 'conductedBy': conductedBy,
      if (giftType != null) 'giftType': giftType,
      if (accountJsbJud != null) 'accountJsbJud': accountJsbJud,
      if (totalExpenses != null) 'totalExpenses': totalExpenses,
      if (billSubmitted != null) 'billSubmitted': billSubmitted,
      if (meetImageUrl != null) 'meetImageUrl': meetImageUrl,
      if (siteId != null) 'siteId': siteId,
    };
    return data;
  }
}