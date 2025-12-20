import 'dart:convert';

Employee employeeFromJson(String str) => Employee.fromJson(json.decode(str));
String employeeToJson(Employee data) => json.encode(data.toJson());

class Employee {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? loginId;
  final String? area;
  final String? region;
  final String? companyName;
  final String? role;
  final bool isTechnicalRole;
  final String? techLoginId;
  final String? deviceId;

  String get displayName {
    if (firstName != null && lastName != null && firstName!.isNotEmpty && lastName!.isNotEmpty) {
      return '$firstName $lastName';
    }
    return firstName ?? lastName ?? loginId ?? 'Employee';
  }

  Employee({
    required this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.area,
    this.region,
    this.loginId,
    this.companyName,
    this.role,
    this.isTechnicalRole = false,
    this.techLoginId,
    this.deviceId,
  });

  // HIGHLIGHT: THE fromJson FACTORY IS NOW SMARTER
  factory Employee.fromJson(Map<String, dynamic> json) {
    // This logic handles both the nested structure from the profile endpoint
    // and the flat structure from the initial login response.
    final companyData = json['company'];
    String? extractedCompanyName;
    if (companyData is Map<String, dynamic>) {
      extractedCompanyName = companyData['companyName'];
    } else {
      extractedCompanyName = json['companyName'];
    }

    return Employee(
      id: json["id"]?.toString() ?? '',
      firstName: json["firstName"] as String?,
      lastName: json["lastName"] as String?,
      email: json["email"] as String?,
      area: json["area"] as String?,
      region: json["region"] as String?,
      loginId: json["salesmanLoginId"] as String?,
      companyName: extractedCompanyName,
      role: json["role"] as String?,
      // Backend sends 'isTechnicalRole' (bool) and 'techLoginId' (string)
      isTechnicalRole: json["isTechnicalRole"] == true,
      techLoginId: json["techLoginId"] as String?,
      deviceId: json["deviceId"] as String?,
    );
  }

  // HIGHLIGHT: UPDATED copyWith
  Employee copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? area,
    String? region,
    String? loginId,
    String? companyName,
    String? role,
    bool? isTechnicalRole,
    String? techLoginId,
    String? deviceId,
  }) {
    return Employee(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      area: area ?? this.area,
      region: region ?? this.region,
      loginId: loginId ?? this.loginId,
      companyName: companyName ?? this.companyName,
      role: role ?? this.role,
      isTechnicalRole: isTechnicalRole ?? this.isTechnicalRole,
      techLoginId: techLoginId ?? this.techLoginId,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  // HIGHLIGHT: UPDATED toJson
  Map<String, dynamic> toJson() => {
        "id": id,
        "firstName": firstName,
        "lastName": lastName,
        "email": email,
        "area": area,
        "region": region,
        "loginId": loginId,
        "companyName": companyName,
        "role": role,
        "isTechnicalRole": isTechnicalRole,
        "techLoginId": techLoginId,
        "deviceId": deviceId,
      };
}