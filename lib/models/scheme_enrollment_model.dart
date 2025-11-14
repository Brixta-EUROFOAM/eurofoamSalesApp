// lib/models/scheme_enrollment_model.dart
import 'dart:developer' as dev;

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
    DateTime? parseDate(String? dateStr) {
      if (dateStr == null) return null;
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        dev.log('Invalid date format: $dateStr', name: 'SchemeEnrollmentModel');
        return null;
      }
    }
    
    return SchemeEnrollment(
      masonId: json['masonId'] as String,
      schemeId: json['schemeId'] as String,
      status: json['status'] as String?,
      // Use 'enrolledAt' from your schema, fallback to 'enrolled_at'
      enrolledAt: parseDate(json['enrolledAt'] ?? json['enrolled_at']) ?? DateTime.now(),
      scheme: json['scheme'] != null
          ? Scheme.fromJson(json['scheme'] as Map<String, dynamic>)
          : null,
    );
  }
}

// Model for Scheme details, mapping to your 'schemes_offers' table
class Scheme {
  final String id;
  final String name;
  final String description;
  final int pointsPerUnit; // Keeping this from old model, as points are common
  
  // --- ✅ NEW FIELDS from schemes_offers schema ---
  final DateTime? startDate;
  final DateTime? endDate;

  Scheme({
    required this.id,
    required this.name,
    required this.description,
    this.pointsPerUnit = 0, // Default to 0 if not provided
    this.startDate,
    this.endDate,
  });

  factory Scheme.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse dates
    DateTime? parseDate(String? dateStr) {
      if (dateStr == null) return null;
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        dev.log('Invalid date format: $dateStr', name: 'SchemeModel');
        return null;
      }
    }

    return Scheme(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '', // Handle null description
      // Keep pointsPerUnit parsing if it exists, otherwise default
      pointsPerUnit: (json['pointsPerUnit'] as num? ?? 0).toInt(),
      
      // --- ✅ PARSE NEW FIELDS ---
      // Use snake_case from your schema as the primary key
      startDate: parseDate(json['startDate'] ?? json['start_date']),
      endDate: parseDate(json['endDate'] ?? json['end_date']),
    );
  }
}