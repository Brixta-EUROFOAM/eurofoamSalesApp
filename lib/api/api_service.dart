// lib/api/api_service.dart
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

import '../models/dealer_model.dart';
import '../models/dvr_model.dart';
import '../models/pjp_model.dart';
import '../models/leaves_model.dart';
import '../models/attendance_model.dart';

enum HttpMethod { get, post, put, patch, delete }

class ApiService {
  // Base URL for Sales App routes
  static const String baseUrl = 'http://10.0.2.2:8000/api/salesApp'; //localhost
  //static const String baseUrl = 'http://122.176.219.242:55008/api/salesApp'; // brixta.site server

  // Base URL specifically for the photo upload route
  static const String uploadUrl =
      'http://122.176.219.242:55008/api/supabase/photo-upload';

  final AuthService _authService = AuthService();

  /// ---------------------------------------------------------
  /// CORE HTTP WRAPPER
  /// ---------------------------------------------------------
  Future<dynamic> _handleRequest(
    HttpMethod method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final uri = Uri.parse('$baseUrl$endpoint');
      http.Response response;

      const timeout = Duration(seconds: 20);

      switch (method) {
        case HttpMethod.get:
          response = await http.get(uri, headers: headers).timeout(timeout);
          break;
        case HttpMethod.post:
          response = await http
              .post(uri, headers: headers, body: jsonEncode(body))
              .timeout(timeout);
          break;
        case HttpMethod.put:
          response = await http
              .put(uri, headers: headers, body: jsonEncode(body))
              .timeout(timeout);
          break;
        case HttpMethod.patch:
          response = await http
              .patch(uri, headers: headers, body: jsonEncode(body))
              .timeout(timeout);
          break;
        case HttpMethod.delete:
          response = await http.delete(uri, headers: headers).timeout(timeout);
          break;
      }

      if (response.statusCode == 401) {
        print("Token expired. Forcing logout.");
        await _authService.logout();
        throw Exception("Session expired. Please log in again.");
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['error'] ??
              errorData['message'] ??
              'API Error: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      throw Exception(
        "Request timed out. Please check your internet connection.",
      );
    } catch (e) {
      print('API Wrapper Error [$method $endpoint]: $e');
      rethrow;
    }
  }

  /// ---------------------------------------------------------
  /// PHOTO UPLOAD (Multipart Request)
  /// ---------------------------------------------------------
  Future<String> uploadPhoto(File imageFile) async {
    try {
      final token = await _authService.getToken();
      final uri = Uri.parse(uploadUrl);

      final request = http.MultipartRequest('POST', uri);

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      // 20-second timeout for image uploads to handle slow networks
      final response = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final respStr = await response.stream.bytesToString();
      final data = jsonDecode(respStr);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['publicUrl'];
      } else {
        throw Exception(data['error'] ?? 'Upload failed');
      }
    } catch (e) {
      print('Photo Upload Error: $e');
      throw Exception('Failed to upload photo: $e');
    }
  }

  /// ---------------------------------------------------------
  /// DEALERS
  /// ---------------------------------------------------------
  Future<List<DealerModel>> getDealers({
    String? searchQuery,
    int limit = 50,
  }) async {
    try {
      String endpoint = '/dealers?limit=$limit';
      if (searchQuery != null && searchQuery.isNotEmpty) {
        endpoint += '&search=${Uri.encodeComponent(searchQuery)}';
      }

      final response = await _handleRequest(HttpMethod.get, endpoint);
      final List data = response['data'] ?? [];
      return data.map((json) => DealerModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> addDealer(DealerModel dealer) async {
    try {
      await _handleRequest(HttpMethod.post, '/dealers', body: dealer.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// ---------------------------------------------------------
  /// DAILY VISIT REPORTS (DVR)
  /// ---------------------------------------------------------
  Future<List<DvrModel>> getDailyVisitReports() async {
    try {
      final response = await _handleRequest(
        HttpMethod.get,
        '/daily-visit-reports',
      );
      final List data = response['data'] ?? [];
      return data.map((json) => DvrModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> submitDailyVisitReport(DvrModel dvr) async {
    try {
      await _handleRequest(
        HttpMethod.post,
        '/daily-visit-reports',
        body: dvr.toJson(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// ---------------------------------------------------------
  /// PERMANENT JOURNEY PLANS (PJP)
  /// ---------------------------------------------------------
  Future<List<PjpModel>> getJourneyPlans() async {
    try {
      final response = await _handleRequest(
        HttpMethod.get,
        '/permanent-journey-plans',
      );
      final List data = response['data'] ?? [];
      return data.map((json) => PjpModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> submitBulkJourneyPlans(List<PjpModel> plans) async {
    try {
      await _handleRequest(
        HttpMethod.post,
        '/permanent-journey-plans/bulk',
        body: {'plans': plans.map((p) => p.toJson()).toList()},
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateJourneyPlanStatus(String pjpId, String status) async {
    try {
      await _handleRequest(
        HttpMethod.patch,
        '/permanent-journey-plans/$pjpId',
        body: {'status': status},
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// ---------------------------------------------------------
  /// LEAVES
  /// ---------------------------------------------------------
  Future<List<LeaveModel>> getLeaves() async {
    try {
      final response = await _handleRequest(HttpMethod.get, '/leaves');
      final List data = response['data'] ?? [];
      return data.map((json) => LeaveModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> applyForLeave(LeaveModel leave) async {
    try {
      await _handleRequest(HttpMethod.post, '/leaves', body: leave.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// ---------------------------------------------------------
  /// ATTENDANCE
  /// ---------------------------------------------------------
  Future<List<AttendanceModel>> getAttendanceHistory({bool todayOnly = false}) async {
    try {
      final endpoint = todayOnly ? '/attendance?today=true' : '/attendance';
      final response = await _handleRequest(HttpMethod.get, endpoint);
      final List data = response['data'] ?? [];
      return data.map((json) => AttendanceModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Attendance GET Error: $e");
      return [];
    }
  }

  Future<bool> markAttendanceIn(AttendanceModel attendance) async {
    try {
      await _handleRequest(
        HttpMethod.post,
        '/attendance/in',
        body: attendance.toJson(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markAttendanceOut(AttendanceModel attendance) async {
    try {
      await _handleRequest(
        HttpMethod.patch,
        '/attendance/out',
        // Pass only the fields needed for checkout, including ID if you have it
        body: {
          'id': attendance.id != 0 ? attendance.id : null,
          'outTimeLatitude': attendance.outTimeLatitude,
          'outTimeLongitude': attendance.outTimeLongitude,
          'outTimeImageUrl': attendance.outTimeImageUrl,
          'outTimeImageCaptured': attendance.outTimeImageCaptured,
        },
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}
