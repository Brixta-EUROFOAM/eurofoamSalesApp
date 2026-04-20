// lib/salesSide/models/outstanding_report_model.dart
class OutstandingReport {
  final String id;
  final DateTime? reportDate;
  final String? dealerName;
  final String? dealerPartyName;
  final String? zone;

  final double? pendingAmt;
  final double? securityDepositAmt;

  final Map<String, dynamic>? ageingData;

  final String institution;
  final int? verifiedDealerId;

  final DateTime? createdAt;

  OutstandingReport({
    required this.id,
    required this.institution,
    this.reportDate,
    this.dealerName,
    this.dealerPartyName,
    this.zone,
    this.pendingAmt,
    this.securityDepositAmt,
    this.ageingData,
    this.verifiedDealerId,
    this.createdAt,
  });

  factory OutstandingReport.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic val) {
      if (val == null) return null;
      return double.tryParse(val.toString());
    }

    return OutstandingReport(
      id: json['id']?.toString() ?? '',
      institution: json['institution']?.toString() ?? 'UNKNOWN',

      reportDate: json['reportDate'] != null
          ? DateTime.tryParse(json['reportDate'])
          : null,

      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,

      dealerName: json['dealerName']?.toString(),
      dealerPartyName: json['dealerPartyName']?.toString(),
      zone: json['zone']?.toString(),

      pendingAmt: parseDouble(json['pendingAmt'] ?? json['pending_amt']),
      securityDepositAmt: parseDouble(json['securityDepositAmt'] ?? json['security_deposit_amt']),

      ageingData: json['ageingData'] != null 
          ? Map<String, dynamic>.from(json['ageingData']) 
          : (json['ageing_data'] != null ? Map<String, dynamic>.from(json['ageing_data']) : {}),

      verifiedDealerId: json['verifiedDealerId'] is int
          ? json['verifiedDealerId']
          : int.tryParse(json['verifiedDealerId']?.toString() ?? ''),
    );
  }
}