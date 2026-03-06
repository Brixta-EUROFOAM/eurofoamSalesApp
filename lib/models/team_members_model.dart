// lib/models/team_members_model.dart
class TeamMember {
  final int id;
  final String firstName;
  final String lastName;
  final String role;
  final String? email;
  final String? area;
  final String? region;
  final int? reportsToId;

  TeamMember({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.email,
    this.area,
    this.region,
    this.reportsToId,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      id: json['id'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      role: json['role'] ?? '',
      email: json['email'],
      area: json['area'],
      region: json['region'],
      reportsToId: json['reportsToId'],
    );
  }

  String get fullName => '$firstName $lastName'.trim();
}