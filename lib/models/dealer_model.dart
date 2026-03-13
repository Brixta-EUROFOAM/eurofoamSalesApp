import 'dart:convert';

class Dealer {
  final String? id;
  final int? userId;
  final String type;
  final String? parentDealerId;
  final String name;
  final String region;
  final String area;
  final String phoneNo;
  final String address;
  final String? pinCode;
  final double? latitude;
  final double? longitude;
  final DateTime? dateOfBirth;
  final DateTime? anniversaryDate;
  final double totalPotential;
  final double bestPotential;
  final List<String> brandSelling;
  final String feedbacks;
  final String? remarks;

  final String? dealerDevelopmentStatus;
  final String? dealerDevelopmentObstacle;
  final double? salesGrowthPercentage;
  final int? noOfPJP;
  final String? nameOfFirm;
  final String? underSalesPromoterName;

  // Verification & IDs
  final String? verificationStatus; // e.g., 'PENDING'
  final String? whatsappNo;
  final String? emailId;
  final String? businessType; // Separate from 'type'
  final String? gstinNo;
  final String? panNo;
  final String? tradeLicNo;
  final String? aadharNo;

  // ... (all other fields like godown, residential, bank...)
  final int? godownSizeSqFt;
  final String? godownCapacityMTBags;
  final String? godownAddressLine;
  final String? godownLandMark;
  final String? godownDistrict;
  final String? godownArea;
  final String? godownRegion;
  final String? godownPinCode;
  final String? residentialAddressLine;
  final String? residentialLandMark;
  final String? residentialDistrict;
  final String? residentialArea;
  final String? residentialRegion;
  final String? residentialPinCode;
  final String? bankAccountName;
  final String? bankName;
  final String? bankBranchAddress;
  final String? bankAccountNumber;
  final String? bankIfscCode;
  final String? brandName;
  final double? monthlySaleMT;
  final int? noOfDealers;
  final String? areaCovered;
  final double? projectedMonthlySalesBestCementMT;
  final int? noOfEmployeesInSales;
  final String? declarationName;
  final String? declarationPlace;
  final DateTime? declarationDate;
  final String? tradeLicencePicUrl;
  final String? shopPicUrl;
  final String? dealerPicUrl;
  final String? blankChequePicUrl;
  final String? partnershipDeedPicUrl;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  Dealer({
    this.id,
    this.userId,
    required this.type,
    this.parentDealerId,
    required this.name,
    required this.region,
    required this.area,
    required this.phoneNo,
    required this.address,
    this.pinCode,
    this.latitude,
    this.longitude,
    this.dateOfBirth,
    this.anniversaryDate,
    required this.totalPotential,
    required this.bestPotential,
    required this.brandSelling,
    required this.feedbacks,
    this.remarks,
    this.createdAt,
    this.updatedAt,
    this.dealerDevelopmentStatus,
    this.dealerDevelopmentObstacle,
    this.salesGrowthPercentage,
    this.noOfPJP,
    this.nameOfFirm,
    this.underSalesPromoterName,

    this.verificationStatus,
    this.whatsappNo,
    this.emailId,
    this.businessType,
    this.gstinNo,
    this.panNo,
    this.tradeLicNo,
    this.aadharNo,
    this.godownSizeSqFt,
    this.godownCapacityMTBags,
    this.godownAddressLine,
    this.godownLandMark,
    this.godownDistrict,
    this.godownArea,
    this.godownRegion,
    this.godownPinCode,
    this.residentialAddressLine,
    this.residentialLandMark,
    this.residentialDistrict,
    this.residentialArea,
    this.residentialRegion,
    this.residentialPinCode,
    this.bankAccountName,
    this.bankName,
    this.bankBranchAddress,
    this.bankAccountNumber,
    this.bankIfscCode,
    this.brandName,
    this.monthlySaleMT,
    this.noOfDealers,
    this.areaCovered,
    this.projectedMonthlySalesBestCementMT,
    this.noOfEmployeesInSales,
    this.declarationName,
    this.declarationPlace,
    this.declarationDate,
    this.tradeLicencePicUrl,
    this.shopPicUrl,
    this.dealerPicUrl,
    this.blankChequePicUrl,
    this.partnershipDeedPicUrl,
  });

  // Helper to safely parse dates
  // 🚀 BULLETPROOF DATE PARSER (Handles both API Strings and SQLite Ints)
  static DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is DateTime) return val;
    if (val is int) {
      // SQLite saves dates as Unix timestamps (seconds)
      return DateTime.fromMillisecondsSinceEpoch(val * 1000);
    }
    return DateTime.tryParse(val.toString());
  }

  // Helper to safely parse doubles
  static double? _parseDouble(dynamic val) {
    if (val == null) return null;
    return double.tryParse(val.toString());
  }

  // 🚀 BULLETPROOF INT PARSER (Handles API sending "6.0" instead of "6")
  static int? _parseInt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    if (val is double) return val.toInt();
    return int.tryParse(val.toString()) ??
        double.tryParse(val.toString())?.toInt();
  }

  factory Dealer.fromJson(Map<String, dynamic> json) {
    return Dealer(
      id: json['id']?.toString(),
      userId: _parseInt(json['userId']),
      type: json['type'] ?? '',
      parentDealerId: json['parentDealerId'],
      name: json['name'] ?? '',
      region: json['region'] ?? '',
      area: json['area'] ?? '',
      phoneNo: json['phoneNo'] ?? '',
      address: json['address'] ?? '',
      pinCode: json['pinCode'],
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      dateOfBirth: _parseDate(json['dateOfBirth']),
      anniversaryDate: _parseDate(json['anniversaryDate']),
      totalPotential: _parseDouble(json['totalPotential']) ?? 0.0,
      bestPotential: _parseDouble(json['bestPotential']) ?? 0.0,

      // 🚀 HERE IS THE SAFE PARSER FOR BRAND SELLING
      brandSelling: () {
        final val = json['brandSelling'];
        if (val == null) return <String>[];
        if (val is List) return val.map((e) => e.toString()).toList();
        if (val is String) {
          try {
            final decoded = jsonDecode(val);
            if (decoded is List)
              return decoded.map((e) => e.toString()).toList();
          } catch (_) {}
          return val.split(',').map((e) => e.trim()).toList();
        }
        return <String>[];
      }(),

      feedbacks: json['feedbacks'] ?? '',
      remarks: json['remarks'],
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),

      dealerDevelopmentStatus: json['dealerDevelopmentStatus'],
      dealerDevelopmentObstacle: json['dealerDevelopmentObstacle'],
      salesGrowthPercentage: _parseDouble(json['salesGrowthPercentage']),
      noOfPJP: _parseInt(json['noOfPJP']),
      nameOfFirm: json['nameOfFirm'],
      underSalesPromoterName: json['underSalesPromoterName'],

      verificationStatus: json['verificationStatus'],
      whatsappNo: json['whatsappNo'],
      emailId: json['emailId'],
      businessType: json['businessType'],
      gstinNo: json['gstinNo'],
      panNo: json['panNo'],
      tradeLicNo: json['tradeLicNo'],
      aadharNo: json['aadharNo'],
      godownSizeSqFt: _parseInt(json['godownSizeSqFt']),
      godownCapacityMTBags: json['godownCapacityMTBags'],
      godownAddressLine: json['godownAddressLine'],
      godownLandMark: json['godownLandMark'],
      godownDistrict: json['godownDistrict'],
      godownArea: json['godownArea'],
      godownRegion: json['godownRegion'],
      godownPinCode: json['godownPinCode'],
      residentialAddressLine: json['residentialAddressLine'],
      residentialLandMark: json['residentialLandMark'],
      residentialDistrict: json['residentialDistrict'],
      residentialArea: json['residentialArea'],
      residentialRegion: json['residentialRegion'],
      residentialPinCode: json['residentialPinCode'],
      bankAccountName: json['bankAccountName'],
      bankName: json['bankName'],
      bankBranchAddress: json['bankBranchAddress'],
      bankAccountNumber: json['bankAccountNumber'],
      bankIfscCode: json['bankIfscCode'],
      brandName: json['brandName'],
      monthlySaleMT: _parseDouble(json['monthlySaleMT']),
      noOfDealers: _parseInt(json['noOfDealers']),
      areaCovered: json['areaCovered'],
      projectedMonthlySalesBestCementMT: _parseDouble(
        json['projectedMonthlySalesBestCementMT'],
      ),
      noOfEmployeesInSales: _parseInt(json['noOfEmployeesInSales']),
      declarationName: json['declarationName'],
      declarationPlace: json['declarationPlace'],
      declarationDate: _parseDate(json['declarationDate']),
      tradeLicencePicUrl: json['tradeLicencePicUrl'],
      shopPicUrl: json['shopPicUrl'],
      dealerPicUrl: json['dealerPicUrl'],
      blankChequePicUrl: json['blankChequePicUrl'],
      partnershipDeedPicUrl: json['partnershipDeedPicUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    // Helper to send null for empty strings
    String? _nullIfEmpty(String? s) =>
        (s == null || s.trim().isEmpty) ? null : s.trim();

    return {
      'id': id,
      'userId': userId,
      'type': type,
      'parentDealerId': _nullIfEmpty(parentDealerId),
      'name': name,
      'region': region,
      'area': area,
      'phoneNo': phoneNo,
      'address': address,
      'pinCode': _nullIfEmpty(pinCode),
      'latitude': latitude,
      'longitude': longitude,
      'dateOfBirth': dateOfBirth?.toIso8601String().split(
        'T',
      )[0], // Send as YYYY-MM-DD
      'anniversaryDate': anniversaryDate?.toIso8601String().split('T')[0],
      'totalPotential': totalPotential,
      'bestPotential': bestPotential,
      'brandSelling': brandSelling,
      'feedbacks': feedbacks,
      'remarks': _nullIfEmpty(remarks),

      // 'createdAt': createdAt?.toIso8601String(), // <-- REMOVED
      // 'updatedAt': updatedAt?.toIso8601String(), // <-- REMOVED
      'dealerDevelopmentStatus': _nullIfEmpty(dealerDevelopmentStatus),
      'dealerDevelopmentObstacle': _nullIfEmpty(dealerDevelopmentObstacle),
      'salesGrowthPercentage': salesGrowthPercentage,
      'noOfPJP': noOfPJP,
      'nameOfFirm': _nullIfEmpty(nameOfFirm),
      'underSalesPromoterName': _nullIfEmpty(underSalesPromoterName),

      'verificationStatus': _nullIfEmpty(verificationStatus),
      'whatsappNo': _nullIfEmpty(whatsappNo),
      'emailId': _nullIfEmpty(emailId),
      'businessType': _nullIfEmpty(businessType),
      'gstinNo': _nullIfEmpty(gstinNo),
      'panNo': _nullIfEmpty(panNo),
      'tradeLicNo': _nullIfEmpty(tradeLicNo),
      'aadharNo': _nullIfEmpty(aadharNo),
      'godownSizeSqFt': godownSizeSqFt,
      'godownCapacityMTBags': _nullIfEmpty(godownCapacityMTBags),
      'godownAddressLine': _nullIfEmpty(godownAddressLine),
      'godownLandMark': _nullIfEmpty(godownLandMark),
      'godownDistrict': _nullIfEmpty(godownDistrict),
      'godownArea': _nullIfEmpty(godownArea),
      'godownRegion': _nullIfEmpty(godownRegion),
      'godownPinCode': _nullIfEmpty(godownPinCode),
      'residentialAddressLine': _nullIfEmpty(residentialAddressLine),
      'residentialLandMark': _nullIfEmpty(residentialLandMark),
      'residentialDistrict': _nullIfEmpty(residentialDistrict),
      'residentialArea': _nullIfEmpty(residentialArea),
      'residentialRegion': _nullIfEmpty(residentialRegion),
      'residentialPinCode': _nullIfEmpty(residentialPinCode),
      'bankAccountName': _nullIfEmpty(bankAccountName),
      'bankName': _nullIfEmpty(bankName),
      'bankBranchAddress': _nullIfEmpty(bankBranchAddress),
      'bankAccountNumber': _nullIfEmpty(bankAccountNumber),
      'bankIfscCode': _nullIfEmpty(bankIfscCode),
      'brandName': _nullIfEmpty(brandName),
      'monthlySaleMT': monthlySaleMT,
      'noOfDealers': noOfDealers,
      'areaCovered': _nullIfEmpty(areaCovered),
      'projectedMonthlySalesBestCementMT': projectedMonthlySalesBestCementMT,
      'noOfEmployeesInSales': noOfEmployeesInSales,
      'declarationName': _nullIfEmpty(declarationName),
      'declarationPlace': _nullIfEmpty(declarationPlace),
      'declarationDate': declarationDate?.toIso8601String().split('T')[0],
      'tradeLicencePicUrl': _nullIfEmpty(tradeLicencePicUrl),
      'shopPicUrl': _nullIfEmpty(shopPicUrl),
      'dealerPicUrl': _nullIfEmpty(dealerPicUrl),
      'blankChequePicUrl': _nullIfEmpty(blankChequePicUrl),
      'partnershipDeedPicUrl': _nullIfEmpty(partnershipDeedPicUrl),
    };
  }
}
