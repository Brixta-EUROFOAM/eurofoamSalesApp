import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/dealer_model.dart';
import '../models/pjp_model.dart';
import '../models/daily_task_model.dart';
import '../models/leave_application_model.dart';
import '../models/attendance_model.dart';
import '../models/daily_visit_report_model.dart';
import '../models/geotracking_data_model.dart';
import '../models/competition_report_model.dart';
import '../models/employee_model.dart';
import '../technicalSide/models/technical_visit_report_model.dart';
import '../technicalSide/models/mason_baglift_model.dart';
import '../technicalSide/models/mason_kyc_model.dart';
import '../technicalSide/models/mason_rewards_model.dart';
import '../technicalSide/models/sites_model.dart';
import '../technicalSide/models/mason_pc_model.dart';
import '../technicalSide/models/tso_meetings_model.dart';
import '../models/team_members_model.dart';

// --- ✅ 1. (NEW) TSO USER HELPER CLASS (DEFINED HERE) ---
class TsoUser {
  final int id;
  final String name;
  TsoUser({required this.id, required this.name});

  factory TsoUser.fromJson(Map<String, dynamic> json) {
    // Uses the fields from your /api/users endpoint (firstName, lastName)
    final firstName = json['firstName'] ?? '';
    final lastName = json['lastName'] ?? '';
    return TsoUser(
      id: json['id'],
      name: '$firstName $lastName'.trim(), // Combine first and last name
    );
  }
}
// --- ⬆️ END TSO HELPER ⬆️ ---

/// ApiService: centralised HTTP helpers for your backend.
/// Note: Use ApiService.setAuthToken(...) after login to ensure
/// Authorization header is attached to subsequent requests.
class ApiService {
  //static String baseUrl = 'http://65.0.208.126'; //aws
  static String baseUrl = 'https://brixta.site'; // fix24
  //static String baseUrl = 'http://10.0.2.2:8000'; //localhost connection
  //static String baseUrl = 'https://myserver2-5ame.onrender.com'; // (masontsopart - QR + wss)
  //static String baseUrl = 'http://122.176.219.242:55000';

  // --- ✅ FIX: Initialize http.Client ---
  final http.Client _client = http.Client();

  // --- ✅ ADDED TOKEN STORAGE ---
  static String? _authToken;

  /// Set the in-memory auth token (call after successful login).
  /// This does NOT persist to secure storage; AuthService handles secure storage.
  static void setAuthToken(String? token) {
    _authToken = token;
  }

  /// Convenience getter (optional)
  static String? get authToken => _authToken;

  /// Clear the in-memory token (for logout).
  static void clearAuthToken() {
    _authToken = null;
  }

  // --- GENERAL HELPERS ---

  Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  Future<T> _get<T>(String endpoint, T Function(dynamic json) fromJson) async {
    final url = Uri.parse('$baseUrl/api/$endpoint');
    dev.log('GET: $url', name: 'ApiService');

    try {
      final response = await _client
          .get(url, headers: _authHeaders)
          .timeout(const Duration(seconds: 45)); // USE _client
      final jsonData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return fromJson(jsonData['data']);
        } else if (endpoint.startsWith('users/')) {
          // Special case for /api/users/:id which just returns { "data": ... }
          return fromJson(jsonData);
        } else {
          throw Exception(jsonData['error'] ?? 'API returned success: false');
        }
      } else {
        throw Exception(
          jsonData['error'] ??
              'Failed to load data. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      dev.log('API Error on GET $endpoint', error: e, name: 'ApiService');
      rethrow;
    }
  }

  Future<T> _post<T>(
    String endpoint,
    Map<String, dynamic> body,
    T Function(dynamic json) fromJson,
  ) async {
    final url = Uri.parse('$baseUrl/api/$endpoint');
    dev.log('POST: $url', name: 'ApiService');

    final headers = _authHeaders;
    headers['Content-Type'] = 'application/json; charset=UTF-8';

    try {
      final response =
          await _client // USE _client
              .post(
                url,
                headers: headers, // Use updated headers
                body: jsonEncode(body),
              )
              .timeout(const Duration(seconds: 45));
      final jsonData = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        // Special case for login which returns data directly
        if (endpoint == 'auth/login') {
          return fromJson(jsonData);
        }

        if (jsonData['success'] == true && jsonData['data'] != null) {
          return fromJson(jsonData['data']);
        } else {
          throw Exception(jsonData['error'] ?? 'API returned success: false');
        }
      } else {
        final errorDetails = jsonData['details'] != null
            ? jsonEncode(jsonData['details'])
            : 'No details from server.';
        throw Exception(
          '${jsonData['error'] ?? 'Failed to create item'}. Details: $errorDetails',
        );
      }
    } catch (e) {
      dev.log('API Error on POST $endpoint', error: e, name: 'ApiService');
      rethrow;
    }
  }

  Future<T> _patch<T>(
    String endpoint,
    Map<String, dynamic> body,
    T Function(dynamic json) fromJson,
  ) async {
    final url = Uri.parse('$baseUrl/api/$endpoint');
    dev.log('PATCH: $url', name: 'ApiService');

    final headers = _authHeaders;
    headers['Content-Type'] = 'application/json; charset=UTF-8';

    try {
      final response =
          await _client // USE _client
              .patch(
                url,
                headers: headers, // Use updated headers
                body: jsonEncode(body),
              )
              .timeout(const Duration(seconds: 45));
      final jsonData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return fromJson(jsonData['data']);
        } else {
          throw Exception(jsonData['error'] ?? 'API returned success: false');
        }
      } else {
        throw Exception(
          jsonData['error'] ??
              'Failed to update item. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      dev.log('API Error on PATCH $endpoint', error: e, name: 'ApiService');
      rethrow;
    }
  }

  Future<void> _delete(String endpoint) async {
    final url = Uri.parse('$baseUrl/api/$endpoint');
    dev.log('DELETE: $url', name: 'ApiService');

    try {
      final response =
          await _client // USE _client
              .delete(url, headers: _authHeaders)
              .timeout(const Duration(seconds: 45));
      if (response.statusCode != 200 && response.statusCode != 204) {
        final jsonData = jsonDecode(response.body);
        throw Exception(
          jsonData['error'] ??
              'Failed to delete item. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      dev.log('API Error on DELETE $endpoint', error: e, name: 'ApiService');
      rethrow;
    }
  }
  // --- (END OF NEW REWARD METHODS) ---

  // -------------------------------------------------------------------
  // LEGACY/CORE METHODS (Kept for completeness)
  // -------------------------------------------------------------------
  Future<String> uploadImageToR2(File imageFile) async {
    final url = Uri.parse('$baseUrl/api/r2/upload-direct');
    dev.log('POST (Multipart): $url', name: 'ApiService');
    try {
      final request = http.MultipartRequest('POST', url);
      // NOTE: We assume the backend is configured to accept the Auth token via a file field or custom header
      if (_authToken != null) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 90),
      );
      final response = await http.Response.fromStream(streamedResponse);
      final jsonData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (jsonData['success'] == true && jsonData['publicUrl'] != null) {
          return jsonData['publicUrl'];
        } else {
          throw Exception(
            jsonData['error'] ?? 'Image upload API returned success: false',
          );
        }
      } else {
        throw Exception(
          jsonData['error'] ??
              'Failed to upload image. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      dev.log(
        'API Error on POST uploadImageToR2',
        error: e,
        name: 'ApiService',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> performOcr(
    String imageUrl,
    String docType,
  ) async {
    dev.log(
      'Performing MOCK OCR for $docType on $imageUrl',
      name: 'ApiService',
    );
    await Future.delayed(const Duration(seconds: 2));
    return {};
  }

  Future<String?> sendGeoTrackingPoint(GeoTrackingPoint point) async {
    final body = point.toJson();

    // 2. POST to /api/geotracking
    final response = await _post(
      'geotracking',
      body,
      (json) => json, // We just want the raw JSON response to extract the ID
    );

    dev.log(
      'GeoTracking point sent successfully: ${point.locationType}',
      name: 'ApiService',
    );

    // 3. Extract and return the ID (useful if you need to PATCH this point later)
    if (response is Map<String, dynamic> && response['id'] != null) {
      return response['id'].toString();
    }
    return null;
  }

  Future<void> updateGeoTrackingPoint(
    String id,
    Map<String, dynamic> updateData,
  ) async {
    await _patch('geotracking/$id', updateData, (json) => json);
    dev.log('GeoTracking point $id updated successfully', name: 'ApiService');
  }

  Future<Map<String, String>> reverseGeocodeWithRadar({
    required double latitude,
    required double longitude,
  }) async {
    final radarApiKey = dotenv.env['RADAR_API_KEY'];
    if (radarApiKey == null) {
      throw Exception('RADAR_API_KEY not found in .env file');
    }

    final url = Uri.parse(
      'https://api.radar.io/v1/geocode/reverse?coordinates=$latitude,$longitude',
    );

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': radarApiKey},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['addresses'] != null &&
            (data['addresses'] as List).isNotEmpty) {
          final address = data['addresses'][0];

          // Radar returns components. We try to map them to your fields.
          // Note: Radar fields vary by country. Adjust based on India/Your region.
          return {
            'address': address['formattedAddress'] ?? '',
            'region': address['state'] ?? address['county'] ?? '',
            'area': address['city'] ?? address['placeLabel'] ?? '',
            'pinCode': address['postalCode'] ?? '',
          };
        } else {
          // No address found, return raw lat/lng as address
          return {
            'address': '$latitude, $longitude',
            'region': '',
            'area': '',
            'pinCode': '',
          };
        }
      } else {
        throw Exception(
          'Radar API Error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to reverse geocode: $e');
    }
  }

  Future<List<dynamic>> searchPhotonAddress(String query) async {
    throw Exception('Failed to search Photon.');
  }

  Future<List<Dealer>> fetchDealers({
    String? region,
    String? area,
    String? type,
    int? userId,
    String? search,
    int page = 1,
    int limit = 300,
  }) async {
    // 1. Build the query string
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'page': page.toString(),
    };
    if (region != null) queryParams['region'] = region;
    if (area != null) queryParams['area'] = area;
    if (type != null) queryParams['type'] = type;
    if (userId != null) queryParams['userId'] = userId.toString();
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final queryString = Uri(queryParameters: queryParams).query;

    // 2. Call the endpoint
    return _get(
      'dealers?$queryString',
      (json) => (json as List).map((item) => Dealer.fromJson(item)).toList(),
    );
  }

  Future<Dealer> fetchDealerById(String dealerId) async {
    // Calls GET /api/dealers/:id
    return _get('dealers/$dealerId', (json) => Dealer.fromJson(json));
  }

  Future<List<Dealer>> fetchDealersByUserId(int userId) async {
    return _get(
      'dealers/user/$userId',
      (json) => (json as List).map((item) => Dealer.fromJson(item)).toList(),
    );
  }

  Future<List<Dealer>> fetchDealersByRegion(String region) async {
    return _get(
      'dealers/region/$region',
      (json) => (json as List).map((item) => Dealer.fromJson(item)).toList(),
    );
  }

  Future<List<Dealer>> fetchDealersByArea(String area) async {
    return _get(
      'dealers/area/$area',
      (json) => (json as List).map((item) => Dealer.fromJson(item)).toList(),
    );
  }

  Future<Dealer> createDealer(Dealer dealer, {double? radius}) async {
    final body = dealer.toJson();
    if (radius != null) {
      body['radius'] = radius.toString();
    }
    return _post('dealers', body, (json) => Dealer.fromJson(json));
  }

  Future<Dealer> updateDealer(
    String dealerId,
    Map<String, dynamic> data,
  ) async {
    return _patch('dealers/$dealerId', data, (json) => Dealer.fromJson(json));
  }

  Future<Dealer> updateDealerGeofence({
    required String dealerId,
    required double latitude,
    required double longitude,
    double radius = 25.0,
  }) async {
    final body = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
    };
    return _patch('dealers/$dealerId', body, (json) => Dealer.fromJson(json));
  }

  Future<void> deleteDealer(String dealerId) => _delete('dealers/$dealerId');
  Future<List<Pjp>> fetchPjpsForUser(
    int userId, {
    String? startDate,
    String? endDate,
    String? status,
    String? verificationStatus,
    String? dealerId,
  }) async {
    final queryParams = <String, String>{
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (status != null) 'status': status,
      if (dealerId != null) 'dealerId': dealerId,
    };
    final endpoint = Uri(
      path: 'pjp/user/$userId',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    ).toString();
    return _get(
      endpoint,
      (json) => (json as List).map((item) => Pjp.fromJson(item)).toList(),
    );
  }

  Future<Pjp> fetchPjpById(String pjpId) async {
    return _get('pjp/$pjpId', (json) => Pjp.fromJson(json));
  }

  Future<List<Pjp>> fetchPjpsByStatus(
    String status, {
    String? startDate,
    String? endDate,
    String? dealerId,
  }) async {
    final queryParams = <String, String>{
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (dealerId != null) 'dealerId': dealerId,
    };
    final endpoint = Uri(
      path: 'pjp/status/$status',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    ).toString();
    return _get(
      endpoint,
      (json) => (json as List).map((item) => Pjp.fromJson(item)).toList(),
    );
  }

  // ✅ NEW: Fetch Stats for Approval Logic
  Future<Map<String, int>> getMasonBagStats({
    required String masonId,
    required String siteId,
  }) async {
    final queryString = 'masonId=$masonId&siteId=$siteId';

    // We use the generic _get helper
    return _get('mason-stats?$queryString', (json) {
      // The backend returns { "data": { "overall": 100, "site": 50 } }
      // Our _get helper unwraps "data", so 'json' here IS the inner object.
      return {
        'overall': int.tryParse(json['overall']?.toString() ?? '0') ?? 0,
        'site': int.tryParse(json['site']?.toString() ?? '0') ?? 0,
      };
    });
  }

  Future<PjpData> fetchPendingAndVerifiedPjps({
    required int userId,
    String? startDate,
    String? endDate,
    String? dealerId,
  }) async {
    try {
      final results = await Future.wait([
        fetchPjpsForUser(
          userId,
          status: 'PENDING',
          startDate: startDate,
          endDate: endDate,
          dealerId: dealerId,
        ),
        fetchPjpsForUser(
          userId,
          status: 'APPROVED',
          startDate: startDate,
          endDate: endDate,
          dealerId: dealerId,
        ),
      ]);
      return PjpData(pendingPjps: results[0], verifiedPjps: results[1]);
    } catch (e) {
      dev.log(
        'Failed to fetch PENDING and VERIFIED PJPs: $e',
        name: 'ApiService',
      );
      return PjpData(pendingPjps: [], verifiedPjps: []);
    }
  }

  Future<Pjp> createPjp(Pjp pjp) async {
    final Map<String, dynamic> payload = Map<String, dynamic>.from(
      pjp.toJson(),
    );
    payload.remove('id');
    payload.remove('createdAt');
    payload.remove('updatedAt');
    payload.remove('diversionReason');
    payload.remove('siteName');
    payload.remove('dealerName');

    // ✅ NORMALIZE EMPTY STRINGS → null
    payload.updateAll((key, value) {
      if (value is String && value.trim().isEmpty) {
        return null;
      }
      return value;
    });

    return _post('pjp', payload, (json) => Pjp.fromJson(json));
  }

  Future<Map<String, dynamic>> createBulkPjp({
    required int userId,
    required int createdById,
    List<String>? dealerIds,
    List<String>? siteIds,
    required DateTime baseDate,
    required int batchSizePerDay,
    required String areaToBeVisited,
    String? description,
    String status = 'PENDING',
    int plannedNewSiteVisits = 0,
    int plannedFollowUpSiteVisits = 0,
    int plannedNewDealerVisits = 0,
    int plannedInfluencerVisits = 0,
    int noOfConvertedBags = 0,
    int noOfMasonPcSchemes = 0,
  }) async {
    final body = {
      'userId': userId,
      'createdById': createdById,
      'dealerIds': dealerIds,
      'siteIds': siteIds,
      'baseDate': baseDate.toIso8601String().split('T').first,
      'batchSizePerDay': batchSizePerDay,
      'areaToBeVisited': areaToBeVisited,
      'description': description,
      'status': status,
      'plannedNewSiteVisits': plannedNewSiteVisits,
      'plannedFollowUpSiteVisits': plannedFollowUpSiteVisits,
      'plannedNewDealerVisits': plannedNewDealerVisits,
      'plannedInfluencerVisits': plannedInfluencerVisits,
      'noOfConvertedBags': noOfConvertedBags,
      'noOfMasonPcSchemes': noOfMasonPcSchemes,
    };
    body.removeWhere((key, value) => value == null);
    final url = Uri.parse('$baseUrl/api/bulkpjp');
    dev.log('POST (Bulk): $url', name: 'ApiService');
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 90));
      final jsonData = jsonDecode(response.body);
      if (response.statusCode == 201) {
        if (jsonData['success'] == true) {
          return jsonData;
        } else {
          throw Exception(jsonData['error'] ?? 'API returned success: false');
        }
      } else {
        final errorDetails = jsonData['details'] != null
            ? jsonEncode(jsonData['details'])
            : 'No details from server.';
        throw Exception(
          '${jsonData['error'] ?? 'Failed to create bulk PJP'}. Details: $errorDetails',
        );
      }
    } catch (e) {
      dev.log('API Error on POST bulkpjp', error: e, name: 'ApiService');
      rethrow;
    }
  }

  Future<Pjp> updatePjp(String pjpId, Map<String, dynamic> data) async {
    return _patch('pjp/$pjpId', data, (json) => Pjp.fromJson(json));
  }

  Future<void> deletePjp(String pjpId) => _delete('pjp/$pjpId');
  Future<List<Attendance>> fetchAttendanceForUser(
    int userId, {
    String? startDate,
    String? endDate,
    int limit = 100, // Default limit
  }) async {
    final queryParams = <String, String>{
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      'limit': limit.toString(),
    };

    final queryString = Uri(queryParameters: queryParams).query;

    return _get(
      'attendance/user/$userId?$queryString',
      (json) =>
          (json as List).map((item) => Attendance.fromJson(item)).toList(),
    );
  }

  Future<Attendance> fetchTodaysAttendance(
    int userId, {
    String role = 'SALES',
  }) {
    // Default to SALES
    return _get(
      'attendance/user/$userId/today?role=$role',
      (json) => Attendance.fromJson(json),
    );
  }

  Future<List<Mason>> fetchNewRegistrations(int userId) async {
    return fetchMasons(
      userId: userId,
      status: 'pending_tso', // Matches backend logic
      limit: 100,
    );
  }

  // ✅ CORRECTED: Manually handle POST to keep 'credentials'
  // ✅ FIX: Manually handle the POST request to keep 'credentials'
  Future<Map<String, dynamic>> submitMasonKyc(
    Map<String, dynamic> kycData,
  ) async {
    final url = Uri.parse('$baseUrl/api/kyc-submissions');
    dev.log('POST (Direct): $url', name: 'ApiService');

    try {
      // 1. Use _client.post directly (Bypassing the _post helper that strips data)
      final response = await _client.post(
        url,
        headers: _authHeaders,
        body: jsonEncode(kycData),
      );

      final jsonData = jsonDecode(response.body);

      // 2. Return the WHOLE JSON (so the UI can find 'credentials')
      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonData;
      } else {
        throw Exception(jsonData['error'] ?? 'Failed to submit KYC');
      }
    } catch (e) {
      dev.log('API Error on submitMasonKyc', error: e, name: 'ApiService');
      rethrow;
    }
  }

  // 🟢 Create a Placeholder Mason (Calls /register-interest)
  // 🟢 UPDATED: Added 'tsoId' as a required parameter
  Future<String?> createMasonPlaceholder({
    required String name,
    required String phone,
    required String tsoId, // 👈 ADD THIS
  }) async {
    try {
      // ❌ DELETE ALL THIS SHARED PREFERENCES STUFF
      // final prefs = await SharedPreferences.getInstance();
      // final String? employeeJson = prefs.getString('user_data');
      // if (employeeJson == null) ...

      // ✅ JUST CALL THE API DIRECTLY USING THE PASSED ID
      final response = await _client.post(
        // Use _client if available, or http.post
        Uri.parse('$baseUrl/api/auth/register-interest'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "phoneNumber": phone,
          "tsoId": tsoId, // 👈 Use the parameter directly
          "deviceId": null,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['masonId'];
      } else {
        debugPrint("Create Mason Failed: ${data['error']}");
        return null;
      }
    } catch (e) {
      debugPrint("Create Mason Error: $e");
      return null;
    }
  }

  Future<Attendance> checkIn(Map<String, dynamic> checkInData) async {
    return _post(
      'attendance/check-in',
      checkInData,
      (json) => Attendance.fromJson(json),
    );
  }

  Future<Attendance> checkOut(Map<String, dynamic> checkOutData) async {
    return _post(
      'attendance/check-out',
      checkOutData,
      (json) => Attendance.fromJson(json),
    );
  }

  Future<List<DailyTask>> fetchDailyTasksForUser(
    int userId, {
    String? startDate,
    String? endDate,
    String? status,
  }) async {
    final queryParams = <String, String>{
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (status != null) 'status': status,
    };

    final queryString = Uri(queryParameters: queryParams).query;
    final endpoint =
        'daily-tasks/user/$userId${queryString.isNotEmpty ? '?$queryString' : ''}';

    return _get(endpoint, (json) {
      final dataArray = json is Map<String, dynamic> && json.containsKey('data')
          ? json['data']
          : json;

      return (dataArray as List)
          .map((item) => DailyTask.fromJson(item))
          .toList();
    });
  }

  Future<DailyTask> createDailyTask(DailyTask task) async {
    return _post(
      'daily-tasks',
      task.toJson(),
      (json) => DailyTask.fromJson(json),
    );
  }

  // Generic DailyTask Update
  Future<void> updateDailyTask(
    String taskId,
    Map<String, dynamic> updateData,
  ) async {
    await _patch('daily-tasks/$taskId', updateData, (json) => json);
  }

  // Just update the DailyTask status
  Future<void> updateDailyTaskStatus(String taskId, String status) async {
    await _patch('daily-tasks/$taskId', {'status': status}, (json) => json);
  }

  Future<void> deleteDailyTask(String taskId) => _delete('daily-tasks/$taskId');

  Future<List<LeaveApplication>> fetchLeaveApplicationsForUser(
    int userId, {
    String? startDate,
    String? endDate,
    String? status,
    String? leaveType,
    int limit = 50,
  }) async {
    final queryParams = <String, String>{
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (status != null) 'status': status,
      if (leaveType != null) 'leaveType': leaveType,
      'limit': limit.toString(),
    };

    final queryString = Uri(queryParameters: queryParams).query;
    final endpoint =
        'leave-applications/user/$userId${queryString.isNotEmpty ? '?$queryString' : ''}';

    return _get(
      endpoint,
      (json) => (json as List)
          .map((item) => LeaveApplication.fromJson(item))
          .toList(),
    );
  }

  Future<LeaveApplication> createLeaveApplication(
    LeaveApplication leaveApp,
  ) async {
    return _post(
      'leave-applications',
      leaveApp.toJson(),
      (json) => LeaveApplication.fromJson(json),
    );
  }

  Future<void> updateLeaveStatus({
    required String leaveId,
    required String status,
    String? adminRemarks,
  }) async {
    final body = {
      'status': status,
      if (adminRemarks != null) 'adminRemarks': adminRemarks,
    };
    await _patch('leave-applications/$leaveId', body, (json) => null);
  }

  Future<void> deleteLeaveApplication(String leaveId) =>
      _delete('leave-applications/$leaveId');

  Future<List<DailyVisitReport>> fetchDvrsForUser(
    int userId, {
    String? startDate,
    String? endDate,
    String? dealerType,
    String? visitType,
    int limit = 100,
  }) async {
    final queryParams = <String, String>{
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (dealerType != null && dealerType != 'All') 'dealerType': dealerType,
      if (visitType != null) 'visitType': visitType,
      'limit': limit.toString(),
    };

    final queryString = Uri(queryParameters: queryParams).query;
    final endpoint =
        'daily-visit-reports/user/$userId${queryString.isNotEmpty ? '?$queryString' : ''}';

    return _get(endpoint, (json) {
      final List dataList = json is List ? json : (json['data'] ?? []);
      return dataList.map((item) => DailyVisitReport.fromJson(item)).toList();
    });
  }

  Future<DailyVisitReport> createDvr(DailyVisitReport dvr) async {
    return _post(
      'daily-visit-reports',
      dvr.toJson(),
      (json) => DailyVisitReport.fromJson(json),
    );
  }

  Future<void> deleteDvr(String dvrId) => _delete('daily-visit-reports/$dvrId');

  Future<List<TechnicalVisitReport>> fetchTvrsForUser(
    int userId, {
    String? startDate,
    String? endDate,
    String? visitType,
    int? limit,
  }) async {
    final queryParams = <String, String>{
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (visitType != null) 'visitType': visitType,
      if (limit != null) 'limit': limit.toString(),
    };

    final queryString = Uri(queryParameters: queryParams).query;
    final endpoint =
        'technical-visit-reports/user/$userId${queryString.isNotEmpty ? '?$queryString' : ''}';

    return _get(
      endpoint,
      (json) => (json as List)
          .map((item) => TechnicalVisitReport.fromJson(item))
          .toList(),
    );
  }

  Future<TechnicalVisitReport> createTvr(TechnicalVisitReport tvr) async {
    return _post(
      'technical-visit-reports',
      tvr.toJson(),
      (json) => TechnicalVisitReport.fromJson(json),
    );
  }

  Future<void> deleteTvr(String tvrId) =>
      _delete('technical-visit-reports/$tvrId');
  Future<CompetitionReport> createCompetitionReport(
    CompetitionReport report,
  ) async {
    return _post(
      'competition-reports',
      report.toJson(),
      (json) => CompetitionReport.fromJson(json),
    );
  }

  Future<void> deleteSalesOrder(String orderId) =>
      _delete('sales-orders/$orderId');

  Future<Employee> fetchEmployeeProfile(String userId) async {
    final json = await _get(
      'users/$userId',
      (json) => json as Map<String, dynamic>,
    );

    return Employee.fromJson(json['data']);
  }

  Future<List<KycSubmission>> fetchPendingKycSubmissions({int? userId}) async {
    final queryParams = <String, String>{'status': 'pending'};

    if (userId != null) {
      queryParams['userId'] = userId.toString();
    }

    final queryString = Uri(queryParameters: queryParams).query;

    return _get(
      'kyc-submissions?$queryString',
      (json) => (json as List).map((e) => KycSubmission.fromJson(e)).toList(),
    );
  }

  Future<void> reviewKycSubmission(
    String submissionId,
    String status, {
    String? remark,
    Map<String, dynamic>? masonUpdates,
  }) async {
    final body = {
      'status': status,
      if (remark != null) 'remark': remark,
      if (masonUpdates != null) 'masonUpdates': masonUpdates,
    };
    await _patch('kyc-submissions/$submissionId', body, (json) => null);
  }

  Future<void> createTechnicalSite(TechnicalSite site) async {
    await _post(
      'technical-sites',
      site.toJson(),
      (json) => null,
    ); // Adjust endpoint if different
  }

  Future<TechnicalSite> updateTechnicalSite(
    String siteId,
    Map<String, dynamic> data,
  ) async {
    return _patch(
      'technical-sites/$siteId',
      data,
      (json) => TechnicalSite.fromJson(json),
    );
  }

  // 1. Fetch ALL approved lifts for TSO (For the Total Count on Card)
  Future<List<MasonBagLift>> fetchAllApprovedBagLiftsForTso(
    String userId,
  ) async {
    final queryString = 'userId=$userId&status=approved&limit=1000';
    //final queryString = 'userId=$userId';
    return _get('bag-lifts?$queryString', (json) {
      return (json as List).map((e) => MasonBagLift.fromJson(e)).toList();
    });
  }

  // 2. Fetch History for Specific Mason (For the Popup)
  Future<List<MasonBagLift>> fetchMasonBagLiftHistory(String masonId) async {
    return _get('bag-lifts?masonId=$masonId&limit=100', (json) {
      debugPrint('Mapper json type: ${json.runtimeType}');
      //debugPrint('Mapper json value: $json');
      return (json as List).map((e) => MasonBagLift.fromJson(e)).toList();
    });
  }

  Future<List<MasonBagLift>> fetchPendingBagLifts({int? userId}) async {
    // 1. Build Query Parameters safely
    final queryParams = <String, String>{
      'status': 'pending', // Always fetch pending
    };

    // 2. Add User ID if it exists (This triggers the TSO filter on backend)
    if (userId != null) {
      queryParams['userId'] = userId.toString();
    }

    // 3. Construct URI manually to pass to your _get helper
    // or simply reconstruct the query string.
    // Since your _get takes a string endpoint, let's format it correctly:

    final queryString = Uri(queryParameters: queryParams).query;
    // Result: "status=pending&userId=123"

    return _get('bag-lifts?$queryString', (json) {
      return (json as List).map((e) => MasonBagLift.fromJson(e)).toList();
    });
  }

  // Approve/Reject Bag Lift
  Future<void> updateBagLiftStatus(
    String id,
    String status, {
    int? bagCount,
    String? purchaseDate,
    String? siteId,
    String? dealerId,
    String? siteKeyPersonName,
    String? siteKeyPersonPhone,
    String? memo,
    String? verificationSiteImageUrl,
    String? verificationProofImageUrl,
    String? approvedAt,
    int? approvedBy,
  }) async {
    final body = {
      'status': status,
      if (bagCount != null) 'bagCount': bagCount,
      if (purchaseDate != null) 'purchaseDate': purchaseDate,
      if (siteId != null) 'siteId': siteId,
      if (dealerId != null) 'dealerId': dealerId,
      if (siteKeyPersonName != null) 'siteKeyPersonName': siteKeyPersonName,
      if (siteKeyPersonPhone != null) 'siteKeyPersonPhone': siteKeyPersonPhone,
      if (memo != null) 'memo': memo,
      if (verificationSiteImageUrl != null)
        'verificationSiteImageUrl': verificationSiteImageUrl,
      if (verificationProofImageUrl != null)
        'verificationProofImageUrl': verificationProofImageUrl,

      if (approvedBy != null) 'approvedBy': approvedBy,
    };
    await _patch('bag-lifts/$id', body, (json) => null);
  }

  Future<List<MasonRedemption>> fetchPendingRedemptions({
    int? userId,
    String status = 'placed',
  }) async {
    final queryParams = <String, String>{
      'status':
          status, // 'placed' is usually the pending status for rewards then 'approved' for approved but not delivered rewards
    };

    // Filter by TSO if provided
    if (userId != null) {
      queryParams['userId'] = userId.toString();
    }

    final queryString = Uri(queryParameters: queryParams).query;

    return _get('rewards-redemption?$queryString', (json) {
      return (json as List).map((e) => MasonRedemption.fromJson(e)).toList();
    });
  }

  Future<void> updateRedemptionStatus(String id, String status) async {
    await _patch('rewards-redemption/$id', {'status': status}, (json) => null);
  }

  // Fetch Sites for Dropdown (and general use)
  Future<List<TechnicalSite>> fetchTechnicalSites({
    int? userId,
    String? region,
    String? search,
    int limit = 50,
  }) async {
    final queryParams = <String, String>{'limit': limit.toString()};

    if (userId != null) queryParams['userId'] = userId.toString();
    if (region != null) queryParams['region'] = region;

    // Pass search query to backend
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final queryString = Uri(queryParameters: queryParams).query;

    return _get(
      'technical-sites?$queryString',
      (json) => (json as List).map((e) => TechnicalSite.fromJson(e)).toList(),
    );
  }

  // Helper to fetch single site by ID (needed for Journey start)
  Future<TechnicalSite> fetchTechnicalSiteById(String siteId) async {
    // Assuming backend has GET /technical-sites/:id
    return _get(
      'technical-sites/$siteId',
      (json) => TechnicalSite.fromJson(json),
    );
  }

  Future<List<Mason>> fetchMasons({
    String? search,
    String? region,
    String? area,
    int? userId,
    String? status, // ✅ ADDED STATUS PARAMETER
    int limit = 50,
  }) async {
    final queryParams = <String, String>{'limit': limit.toString()};

    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (region != null) queryParams['region'] = region;
    if (area != null) queryParams['area'] = area;
    if (userId != null) queryParams['userId'] = userId.toString();
    if (status != null) queryParams['kycStatus'] = status; // ✅ Pass to backend

    final queryString = Uri(queryParameters: queryParams).query;

    return _get(
      'masons?$queryString',
      (json) => (json as List).map((e) => Mason.fromJson(e)).toList(),
    );
  }

  Future<List<TsoMeeting>> fetchTsoMeetings({
    String? startDate,
    String? endDate,
    String? type,
    int? createdByUserId,
    int page = 1,
    int limit = 50,
    String? sortBy,
    String? sortDir,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;
    if (type != null) queryParams['type'] = type;
    if (createdByUserId != null)
      queryParams['createdByUserId'] = createdByUserId.toString();
    if (sortBy != null) queryParams['sortBy'] = sortBy;
    if (sortDir != null) queryParams['sortDir'] = sortDir;

    final queryString = Uri(queryParameters: queryParams).query;

    return _get(
      'tso-meetings?$queryString',
      (json) =>
          (json as List).map((item) => TsoMeeting.fromJson(item)).toList(),
    );
  }

  Future<List<TsoMeeting>> fetchTsoMeetingsByUserId(
    int userId, {
    String? startDate,
    String? endDate,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;

    final queryString = Uri(queryParameters: queryParams).query;

    return _get(
      'tso-meetings/user/$userId?$queryString',
      (json) =>
          (json as List).map((item) => TsoMeeting.fromJson(item)).toList(),
    );
  }

  Future<TsoMeeting> fetchTsoMeetingById(String meetingId) async {
    return _get('tso-meetings/$meetingId', (json) => TsoMeeting.fromJson(json));
  }

  Future<TsoMeeting> createTsoMeeting(TsoMeeting meeting) async {
    return _post(
      'tso-meetings',
      meeting.toJson(),
      (json) => TsoMeeting.fromJson(json),
    );
  }

  Future<TsoMeeting> updateTsoMeeting(
    String meetingId,
    Map<String, dynamic> updateData,
  ) async {
    return _patch(
      'tso-meetings/$meetingId',
      updateData,
      (json) => TsoMeeting.fromJson(json),
    );
  }

  Future<List<TeamMember>> fetchRecursiveTeam(int seniorId) async {
    return _get(
      'team/recursive/$seniorId',
      (json) =>
          (json as List).map((item) => TeamMember.fromJson(item)).toList(),
    );
  }
}
