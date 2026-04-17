class DestinationModel {
  final int? id;
  final String? institution;
  final String? zone;
  final String? district;
  final String? destination;

  DestinationModel({
    this.id,
    this.institution,
    this.zone,
    this.district,
    this.destination,
  });

  factory DestinationModel.fromJson(Map<String, dynamic> json) {
    return DestinationModel(
      id: json['id'] != null ? (json['id'] as num).toInt() : null,
      institution: json['institution'] as String?,
      zone: json['zone'] as String?,
      district: json['district'] as String?,
      destination: json['destination'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'institution': institution,
      'zone': zone,
      'district': district,
      'destination': destination,
    };

    if (id != null) {
      data['id'] = id;
    }

    return data;
  }

  DestinationModel copyWith({
    int? id,
    String? institution,
    String? zone,
    String? district,
    String? destination,
  }) {
    return DestinationModel(
      id: id ?? this.id,
      institution: institution ?? this.institution,
      zone: zone ?? this.zone,
      district: district ?? this.district,
      destination: destination ?? this.destination,
    );
  }

  @override
  String toString() {
    return 'DestinationModel(id: $id, institution: $institution, zone: $zone, district: $district, destination: $destination)';
  }
}