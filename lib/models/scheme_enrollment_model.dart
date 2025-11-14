// lib/models/scheme_enrollment_model.dart

class SchemeEnrollment {
  final String masonId;
  final String schemeId;
  final String? status; // e.g., 'pending', 'approved', 'rejected'
  final DateTime enrolledAt;
  final Scheme? scheme; // Details about the scheme itself

  SchemeEnrollment({
    required this.masonId,
    required this.schemeId,
    required this.enrolledAt,
    this.status,
    this.scheme,
  });

  factory SchemeEnrollment.fromJson(Map<String, dynamic> json) {
    return SchemeEnrollment(
      masonId: json['masonId'] as String,
      schemeId: json['schemeId'] as String,
      status: json['status'] as String?,
      enrolledAt: DateTime.parse(json['enrolledAt'] as String),
      scheme: json['scheme'] != null 
          ? Scheme.fromJson(json['scheme'] as Map<String, dynamic>) 
          : null,
    );
  }
}

// Simple model for Scheme details (assuming your backend returns this structure)
class Scheme {
  final String id;
  final String name;
  final String description;
  final int pointsPerUnit;

  Scheme({
    required this.id,
    required this.name,
    required this.description,
    required this.pointsPerUnit,
  });

  factory Scheme.fromJson(Map<String, dynamic> json) {
    return Scheme(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      pointsPerUnit: json['pointsPerUnit'] as int,
    );
  }
}