// models/dealer_model.dart


class Dealer {
  final String? id; // Nullable for creation
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
  final DateTime? createdAt; // Nullable for creation
  final DateTime? updatedAt; // Nullable for creation

  // --- NEW FIELDS FROM ZOD SCHEMA ---
  final String? verificationStatus; // e.g., 'PENDING'
  final String? whatsappNo;
  final String? emailId;
  final String? businessType; // Separate from 'type'
  final String? gstinNo;
  final String? panNo;
  final String? tradeLicNo;
  final String? aadharNo;

  // Godown
  final int? godownSizeSqFt;
  final String? godownCapacityMTBags;
  final String? godownAddressLine;
  final String? godownLandMark;
  final String? godownDistrict;
  final String? godownArea;
  final String? godownRegion;
  final String? godownPinCode;

  // Residential
  final String? residentialAddressLine;
  final String? residentialLandMark;
  final String? residentialDistrict;
  final String? residentialArea;
  final String? residentialRegion;
  final String? residentialPinCode;

  // Bank
  final String? bankAccountName;
  final String? bankName;
  final String? bankBranchAddress;
  final String? bankAccountNumber;
  final String? bankIfscCode;

  // Sales & promoter
  final String? brandName;
  final double? monthlySaleMT;
  final int? noOfDealers;
  final String? areaCovered;
  final double? projectedMonthlySalesBestCementMT;
  final int? noOfEmployeesInSales;

  // Declaration
  final String? declarationName;
  final String? declarationPlace;
  final DateTime? declarationDate;

  // Document URLs
  final String? tradeLicencePicUrl;
  final String? shopPicUrl;
  final String? dealerPicUrl;
  final String? blankChequePicUrl;
  final String? partnershipDeedPicUrl;

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

    // --- NEW FIELDS ---
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

  factory Dealer.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse dates
    DateTime? _parseDate(String? dateStr) {
      if (dateStr == null) return null;
      return DateTime.tryParse(dateStr);
    }

    return Dealer(
      id: json['id']?.toString(),
      userId: json['userId'],
      type: json['type'] ?? '',
      parentDealerId: json['parentDealerId'],
      name: json['name'] ?? '',
      region: json['region'] ?? '',
      area: json['area'] ?? '',
      phoneNo: json['phoneNo'] ?? '',
      address: json['address'] ?? '',
      pinCode: json['pinCode'],
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      dateOfBirth: _parseDate(json['dateOfBirth']),
      anniversaryDate: _parseDate(json['anniversaryDate']),
      totalPotential: double.tryParse(json['totalPotential'].toString()) ?? 0.0,
      bestPotential: double.tryParse(json['bestPotential'].toString()) ?? 0.0,
      brandSelling: List<String>.from(json['brandSelling'] ?? []),
      feedbacks: json['feedbacks'] ?? '',
      remarks: json['remarks'],
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),

      // --- NEW FIELDS ---
      verificationStatus: json['verificationStatus'],
      whatsappNo: json['whatsappNo'],
      emailId: json['emailId'],
      businessType: json['businessType'],
      gstinNo: json['gstinNo'],
      panNo: json['panNo'],
      tradeLicNo: json['tradeLicNo'],
      aadharNo: json['aadharNo'],
      godownSizeSqFt: json['godownSizeSqFt'],
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
      monthlySaleMT: double.tryParse(json['monthlySaleMT']?.toString() ?? ''),
      noOfDealers: json['noOfDealers'],
      areaCovered: json['areaCovered'],
      projectedMonthlySalesBestCementMT: double.tryParse(
          json['projectedMonthlySalesBestCementMT']?.toString() ?? ''),
      noOfEmployeesInSales: json['noOfEmployeesInSales'],
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
    // Helper to send null for empty strings, matching Zod's `strOrNull`
    String? _nullIfEmpty(String? s) => (s == null || s.trim().isEmpty) ? null : s;

    return {
      'id': _nullIfEmpty(id), // Include ID if it exists
      'userId': userId,
      'type': type,
      'parentDealerId': _nullIfEmpty(parentDealerId),
      'name': name,
      'region': region,
      'area': area,
      'phoneNo': phoneNo,
      'address': address,
      'pinCode': _nullIfEmpty(pinCode),
      'latitude': latitude?.toString(), // Now included in toJson
      'longitude': longitude?.toString(), // Now included in toJson
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'anniversaryDate': anniversaryDate?.toIso8601String(),
      'totalPotential': totalPotential.toString(),
      'bestPotential': bestPotential.toString(),
      'brandSelling': brandSelling,
      'feedbacks': feedbacks,
      'remarks': _nullIfEmpty(remarks),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),

      // --- NEW FIELDS ---
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
      'declarationDate': declarationDate?.toIso8601String(),
      'tradeLicencePicUrl': _nullIfEmpty(tradeLicencePicUrl),
      'shopPicUrl': _nullIfEmpty(shopPicUrl),
      'dealerPicUrl': _nullIfEmpty(dealerPicUrl),
      'blankChequePicUrl': _nullIfEmpty(blankChequePicUrl),
      'partnershipDeedPicUrl': _nullIfEmpty(partnershipDeedPicUrl),
    };
  }

  // --- Boilerplate ---
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Dealer && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Dealer{id: $id, name: $name}';
  }
}