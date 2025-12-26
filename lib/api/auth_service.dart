// lib/api/auth_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/employee_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _baseUrl = 'http://13.203.79.51'; //aws
  //static const String _baseUrl = 'http://10.0.2.2:8000'; //localhost connection
  final _storage = const FlutterSecureStorage();

  /// Saves the JWT to the device's secure storage.
  Future<void> _saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
    dev.log('Token saved to secure storage.', name: 'AuthService');
  }

  /// Reads the JWT from the device's secure storage.
  Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  /// Deletes the JWT from storage to log the user out.
Future<void> logout() async {
  await _storage.deleteAll();

  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();

  dev.log('User fully logged out', name: 'AuthService');
}


  /// Main login function.
  /// It now gets a JWT, saves it, and then fetches the user's profile.
  Future<Employee> login(
    String loginId,
    String password,
    String deviceId,
    String? fcmToken,
  ) async {
    final url = Uri.parse('$_baseUrl/api/auth/login');
    final requestBody = jsonEncode({
      'loginId': loginId.trim(),
      'password': password,
      'deviceId': deviceId,
      'fcmToken': fcmToken,
    });

    //dev.log('--- Sending Login Request ---', name: 'AuthService');
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: requestBody,
          )
          .timeout(const Duration(seconds: 45));

      //dev.log('--- Received Login Response ---', name: 'AuthService');
      //dev.log('Status Code: ${response.statusCode}', name: 'AuthService');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String? token = data['token'];
        final int? userId = data['userId'];

        if (token != null && userId != null) {
          // 1. Save the token
          await _saveToken(token);

          // 2. Use the token to fetch the protected profile data
          return await _fetchUserProfile(userId.toString(), token);
        } else {
          throw Exception('Login response is missing token or userId.');
        }
      } else if (response.statusCode == 403) {
        // Handle specific Device Lock error from backend
        throw Exception(data['error'] ?? "Device unauthorized");
      } else {
        // Handle all other errors (401, 400, 500, etc.)
        throw Exception(data['error'] ?? "Login failed");
      }
    } on TimeoutException {
      throw Exception('Server is taking too long to respond.');
    } catch (e) {
      dev.log('AuthService Login Error', error: e, name: 'AuthService');
      rethrow; // Rethrow to be caught by the UI
    }
  }

  /// Fetches the user profile from the protected /api/users/:id endpoint.
  /// It now requires a token to be sent in the headers.
  Future<Employee> _fetchUserProfile(String userId, String token) async {
    final url = Uri.parse('$_baseUrl/api/users/$userId');
    dev.log('--- Fetching User Profile with Token ---', name: 'AuthService');
    try {
      final response = await http
          .get(
            url,
            // This Authorization header is what authenticates the request
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      dev.log('--- Received Profile Response ---', name: 'AuthService');
      dev.log('Status Code: ${response.statusCode}', name: 'AuthService');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('data')) {
          return Employee.fromJson(data['data']);
        } else {
          throw Exception('Profile "data" key is missing in the response.');
        }
      } else {
        final errorData = jsonDecode(response.body);
        if (response.statusCode == 403) {
          throw Exception("Session expired. Please log in again.");
        }
        throw Exception(errorData['error'] ?? 'Failed to load user profile.');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// A new method to be called on app startup.
  /// It checks for a saved token and tries to log the user in automatically.
  Future<Employee?> tryAutoLogin() async {
    dev.log('--- Attempting Auto-Login ---', name: 'AuthService');
    final token = await _getToken();

    if (token == null) {
      dev.log('No token found. Auto-login skipped.', name: 'AuthService');
      return null; // No token, no auto-login.
    }

    try {
      // Decode the user ID directly from the token payload to be efficient
      final payload = json.decode(
        ascii.decode(base64.decode(base64.normalize(token.split('.')[1]))),
      );
      final String userId = payload['id'].toString();

      // Use the existing token to fetch the user's profile
      final employee = await _fetchUserProfile(userId, token);
      dev.log('Auto-login successful!', name: 'AuthService');
      return employee;
    } catch (e) {
      // If the token is expired or invalid, it will fail.
      // Clear the bad token and return null.
      dev.log('Auto-login failed: ${e.toString()}', name: 'AuthService');
      await logout();
      return null;
    }
  }
// Inside AuthService class

  Future<void> syncDeviceToken(dynamic userId, String fcmToken, String deviceId) async {
    final url = Uri.parse('$_baseUrl/api/users/device');
    
    // USING PRINT SO IT DEFINITELY SHOWS UP
    print("🔵 [Sync] Step 1: Process Started.");
    
    final authToken = await _getToken(); 
    
    if (authToken == null) {
        print("❌ [Sync] FAILURE: No Auth Token found in storage.");
        return;
    }

    // 1. DEBUG ID PARSING
    print("🔵 [Sync] Step 2: Parsing ID. Raw: '$userId' (Type: ${userId.runtimeType})");
    
    int? parsedId;
    if (userId is int) {
      parsedId = userId;
    } else if (userId is String) {
      parsedId = int.tryParse(userId);
    }

    if (parsedId == null) {
       print("❌ [Sync] FAILURE: Could not parse User ID to int.");
       return;
    }
    
    print("🟢 [Sync] Step 3: ID Parsed as: $parsedId");

    try {
      print("🚀 [Sync] Step 4: Sending PUT Request to $url");
      
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken', 
        },
        body: json.encode({
          'userId': parsedId,
          'fcmToken': fcmToken,
          'deviceId': deviceId,
        }),
      );

      print("📥 [Sync] Step 5: Response Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        print("✅ [Sync] SUCCESS: Token updated in database!");
      } else {
        print("⚠️ [Sync] SERVER REJECTED: ${response.body}");
      }
    } catch (e) {
      print("🔥 [Sync] CRASH: HTTP Request failed: $e");
    }
  }
}