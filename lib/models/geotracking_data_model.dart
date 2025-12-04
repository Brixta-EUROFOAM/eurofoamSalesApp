class GeoTrackingPoint {
  // Required fields based on server schema/logic
  final int userId;
  final String journeyId;
  final double latitude;
  final double longitude;
  final bool isActive;

  // Location/Motion details
  final double? accuracy;
  final double? speed;
  final double? heading;
  final double? altitude;
  final String? recordedAt; // Server defaults to now(), but can be overridden

  // Trip details
  final double? destLat;
  final double? destLng;
  final double? totalDistanceTravelled;

  // App/Device state (Matching server schema)
  final String? locationType;
  final String? appState;
  final double? batteryLevel;
  final bool? isCharging;
  final String? networkStatus;
  final String? ipAddress;
  final String? siteName;
  final String? activityType;
  final String? siteId;
  final String? dealerId;

  GeoTrackingPoint({
    required this.userId,
    required this.journeyId,
    required this.latitude,
    required this.longitude,
    this.isActive = true, // Matches server default
    this.accuracy,
    this.speed,
    this.heading,
    this.altitude,
    this.recordedAt,
    this.destLat,
    this.destLng,
    this.totalDistanceTravelled,
    this.locationType,
    this.appState,
    this.batteryLevel,
    this.isCharging,
    this.networkStatus,
    this.ipAddress,
    this.siteName,
    this.activityType,
    this.siteId,
    this.dealerId,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'userId': userId,
      'journeyId': journeyId,
      'isActive': isActive,
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'destLat': destLat?.toString(),
      'destLng': destLng?.toString(),
      'accuracy': accuracy?.toStringAsFixed(2),
      'speed': speed?.toStringAsFixed(2),
      'heading': heading?.toStringAsFixed(2),
      'altitude': altitude?.toStringAsFixed(2),
      'totalDistanceTravelled': totalDistanceTravelled?.toStringAsFixed(3),
      'recordedAt': recordedAt, // Leave this as is here
      'locationType': locationType,
      'appState': appState,
      'batteryLevel': batteryLevel?.toStringAsFixed(2),
      'isCharging': isCharging,
      'networkStatus': networkStatus,
      'ipAddress': ipAddress,
      'siteName': siteName,
      'activityType': activityType,
      'siteId': siteId,
      'dealerId': dealerId,
    };
    // This allows the backend to use its default values (like defaultNow() for dates)
    data.removeWhere((key, value) => value == null);

    return data;
  }
}
