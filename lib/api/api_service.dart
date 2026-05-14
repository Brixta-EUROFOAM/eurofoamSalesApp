// lib/api/api_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

import '../models/dealer_model.dart';
import '../models/dvr_model.dart';
import '../models/pjp_model.dart';
import '../models/leaves_model.dart';
import '../models/attendance_model.dart';

enum HttpMethod { get, post, put, patch, delete }

class ApiService {

  static const String baseUrl = 'http://10.0.2.2:8000/api';
  //static const String baseUrl = 'https://your-production-domain.com/api/salesApp';
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
          response = await http.post(uri, headers: headers, body: jsonEncode(body)).timeout(timeout);
          break;
        case HttpMethod.put:
          response = await http.put(uri, headers: headers, body: jsonEncode(body)).timeout(timeout);
          break;
        case HttpMethod.patch:
          response = await http.patch(uri, headers: headers, body: jsonEncode(body)).timeout(timeout);
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
        throw Exception(errorData['error'] ?? errorData['message'] ?? 'API Error: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception("Request timed out. Please check your internet connection.");
    } catch (e) {
      print('API Wrapper Error [$method $endpoint]: $e');
      rethrow; 
    }
  }

  /// ---------------------------------------------------------
  /// DEALERS
  /// ---------------------------------------------------------
  Future<List<DealerModel>> getDealers() async {
    try {
      final response = await _handleRequest(HttpMethod.get, '/dealers');
      final List data = response['data'] ?? [];
      return data.map((json) => DealerModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// ---------------------------------------------------------
  /// DAILY VISIT REPORTS (DVR)
  /// ---------------------------------------------------------
  Future<List<DvrModel>> getDailyVisitReports() async {
    try {
      final response = await _handleRequest(HttpMethod.get, '/daily-visit-reports');
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
      final response = await _handleRequest(HttpMethod.get, '/permanent-journey-plans');
      final List data = response['data'] ?? [];
      return data.map((json) => PjpModel.fromJson(json)).toList();
    } catch (e) {
      return [];
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
      await _handleRequest(
        HttpMethod.post, 
        '/leaves',
        body: leave.toJson(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// ---------------------------------------------------------
  /// ATTENDANCE
  /// ---------------------------------------------------------
  Future<List<AttendanceModel>> getAttendanceHistory() async {
    try {
      final response = await _handleRequest(HttpMethod.get, '/attendance');
      final List data = response['data'] ?? [];
      return data.map((json) => AttendanceModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> markAttendance(AttendanceModel attendance) async {
    try {
      await _handleRequest(
        HttpMethod.post, 
        '/attendance',
        body: attendance.toJson(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }
  
}