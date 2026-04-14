// lib/salesSide/models/sales_order_model.dart

class SalesOrder {
  final String id;

  final int? userId;
  final String? dealerId;
  final String? dvrId;
  final String? pjpId;

  final DateTime orderDate;
  final String orderPartyName;

  final String? partyPhoneNo;
  final String? partyArea;
  final String? partyRegion;
  final String? partyAddress;

  final DateTime? deliveryDate;
  final String? deliveryArea;
  final String? deliveryRegion;
  final String? deliveryAddress;
  final String? deliveryLocPincode;

  final String? paymentMode;
  final String? paymentTerms;
  final double? paymentAmount;
  final double? receivedPayment;
  final DateTime? receivedPaymentDate;
  final double? pendingPayment;

  final double? orderQty;
  final String? orderUnit;

  final double? itemPrice;
  final double? discountPercentage;
  final double? itemPriceAfterDiscount;

  final String? itemType;
  final String? itemGrade;

  final String? status;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  SalesOrder({
    required this.id,
    this.userId,
    this.dealerId,
    this.dvrId,
    this.pjpId,
    required this.orderDate,
    required this.orderPartyName,
    this.partyPhoneNo,
    this.partyArea,
    this.partyRegion,
    this.partyAddress,
    this.deliveryDate,
    this.deliveryArea,
    this.deliveryRegion,
    this.deliveryAddress,
    this.deliveryLocPincode,
    this.paymentMode,
    this.paymentTerms,
    this.paymentAmount,
    this.receivedPayment,
    this.receivedPaymentDate,
    this.pendingPayment,
    this.orderQty,
    this.orderUnit,
    this.itemPrice,
    this.discountPercentage,
    this.itemPriceAfterDiscount,
    this.itemType,
    this.itemGrade,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory SalesOrder.fromJson(Map<String, dynamic> json) {
    return SalesOrder(
      id: json['id'],
      userId: json['userId'],
      dealerId: json['dealerId'],
      dvrId: json['dvrId'],
      pjpId: json['pjpId'],
      orderDate: DateTime.parse(json['orderDate']),
      orderPartyName: json['orderPartyName'] ?? '',
      partyPhoneNo: json['partyPhoneNo'],
      partyArea: json['partyArea'],
      partyRegion: json['partyRegion'],
      partyAddress: json['partyAddress'],
      deliveryDate: json['deliveryDate'] != null
          ? DateTime.parse(json['deliveryDate'])
          : null,
      deliveryArea: json['deliveryArea'],
      deliveryRegion: json['deliveryRegion'],
      deliveryAddress: json['deliveryAddress'],
      deliveryLocPincode: json['deliveryLocPincode'],
      paymentMode: json['paymentMode'],
      paymentTerms: json['paymentTerms'],
      paymentAmount: json['paymentAmount'] != null
          ? double.tryParse(json['paymentAmount'].toString())
          : null,
      receivedPayment: json['receivedPayment'] != null
          ? double.tryParse(json['receivedPayment'].toString())
          : null,
      receivedPaymentDate: json['receivedPaymentDate'] != null
          ? DateTime.parse(json['receivedPaymentDate'])
          : null,
      pendingPayment: json['pendingPayment'] != null
          ? double.tryParse(json['pendingPayment'].toString())
          : null,
      orderQty: json['orderQty'] != null
          ? double.tryParse(json['orderQty'].toString())
          : null,
      orderUnit: json['orderUnit'],
      itemPrice: json['itemPrice'] != null
          ? double.tryParse(json['itemPrice'].toString())
          : null,
      discountPercentage: json['discountPercentage'] != null
          ? double.tryParse(json['discountPercentage'].toString())
          : null,
      itemPriceAfterDiscount: json['itemPriceAfterDiscount'] != null
          ? double.tryParse(json['itemPriceAfterDiscount'].toString())
          : null,
      itemType: json['itemType'],
      itemGrade: json['itemGrade'],
      status: json['status'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "userId": userId,
      "dealerId": dealerId,
      "dvrId": dvrId,
      "pjpId": pjpId,
      "orderDate": orderDate.toIso8601String(),
      "orderPartyName": orderPartyName,
      "partyPhoneNo": partyPhoneNo,
      "partyArea": partyArea,
      "partyRegion": partyRegion,
      "partyAddress": partyAddress,
      "deliveryDate": deliveryDate?.toIso8601String(),
      "deliveryArea": deliveryArea,
      "deliveryRegion": deliveryRegion,
      "deliveryAddress": deliveryAddress,
      "deliveryLocPincode": deliveryLocPincode,
      "paymentMode": paymentMode,
      "paymentTerms": paymentTerms,
      "paymentAmount": paymentAmount,
      "receivedPayment": receivedPayment,
      "receivedPaymentDate": receivedPaymentDate?.toIso8601String(),
      "pendingPayment": pendingPayment,
      "orderQty": orderQty,
      "orderUnit": orderUnit,
      "itemPrice": itemPrice,
      "discountPercentage": discountPercentage,
      "itemPriceAfterDiscount": itemPriceAfterDiscount,
      "itemType": itemType,
      "itemGrade": itemGrade,
      "status": status ?? "Pending",
    };
  }
}