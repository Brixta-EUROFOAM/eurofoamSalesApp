// lib/models/dealer_model.dart
class DealerModel {
  final int id;
  final String dealerPartyName;
  final String? contactPersonName;
  final String? contactPersonNumber;
  final String? email;
  final String? gstNo;
  final String? panNo;
  final String? zone;
  final String? district;
  final String? area;
  final String? state;
  final String? pinCode;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DealerModel({
    required this.id,
    required this.dealerPartyName,
    this.contactPersonName,
    this.contactPersonNumber,
    this.email,
    this.gstNo,
    this.panNo,
    this.zone,
    this.district,
    this.area,
    this.state,
    this.pinCode,
    this.createdAt,
    this.updatedAt,
  });

  factory DealerModel.fromJson(Map<String, dynamic> json) {
    return DealerModel(
      id: json['id'],
      dealerPartyName: json['dealerPartyName'],
      contactPersonName: json['contactPersonName'],
      contactPersonNumber: json['contactPersonNumber'],
      email: json['email'],
      gstNo: json['gstNo'],
      panNo: json['panNo'],
      zone: json['zone'],
      district: json['district'],
      area: json['area'],
      state: json['state'],
      pinCode: json['pinCode'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dealerPartyName': dealerPartyName,
      'contactPersonName': contactPersonName,
      'contactPersonNumber': contactPersonNumber,
      'email': email,
      'gstNo': gstNo,
      'panNo': panNo,
      'zone': zone,
      'district': district,
      'area': area,
      'state': state,
      'pinCode': pinCode,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}