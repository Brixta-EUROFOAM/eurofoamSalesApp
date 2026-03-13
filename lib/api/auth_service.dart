// lib/api/auth_service.dart
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/employee_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salesmanapp/database/app_database.dart';
// import 'package:geolocator/geolocator.dart';
import 'api_service.dart';

class AuthService {
  static String baseUrl = 'http://65.0.208.126'; //aws
  //static  String baseUrl = 'http://10.0.2.2:8000'; //localhost connection
  //static String baseUrl = 'https://myserver2-5ame.onrender.com'; // (masontsopart - QR + wss)

  final _storage = const FlutterSecureStorage();
  static const String _kCachedProfileKey = 'offline_user_profile_cache';
  static const String _kLastVerifiedKey = 'offline_last_verified_ts';
  static const int _kOfflineGracePeriodHours = 12;

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
    final url = Uri.parse('$baseUrl/api/auth/login');
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

  /// 🚀 The "Fire and Forget" Background Missile
  /// Silently downloads and caches all dealers without blocking the UI
  // 🚀 Pass the current logged-in Employee object here
 Future<void> syncDealersForOffline() async {
  try {
    dev.log('🔄 Starting dealer cache sync...', name: 'AuthService');

    final api = ApiService();

    int page = 1;
    const int limit = 500;   // fetch in chunks
    List<dynamic> allDealers = [];

    while (true) {
      final dealers = await api.fetchDealers(page: page, limit: limit);

      if (dealers.isEmpty) break;

      allDealers.addAll(dealers.map((d) => d.toJson()));
      page++;
    }

    if (allDealers.isNotEmpty) {
      await AppDatabase.instance.syncDealersToLocal(allDealers);
      dev.log(
        '✅ Dealer cache updated: ${allDealers.length} dealers stored locally',
        name: 'AuthService',
      );
    } else {
      dev.log('⚠️ No dealers returned from server', name: 'AuthService');
    }
  } catch (e) {
    dev.log('🔥 Dealer sync failed: $e', name: 'AuthService');
  }
}
  /// Fetches the user profile from the protected /api/users/:id endpoint.
  /// It now requires a token to be sent in the headers.
  /// Fetches the user profile and CACHES it for offline use.
  Future<Employee> _fetchUserProfile(String userId, String token) async {
    final url = Uri.parse('$baseUrl/api/users/$userId');
    dev.log('--- Fetching User Profile with Token ---', name: 'AuthService');
    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('data')) {
          // ✅ SUCCESS: Cache the profile data for future offline use
          await _cacheUserProfile(data['data']);
          final currentEmployee = Employee.fromJson(data['data']);
          syncDealersForOffline();

          return currentEmployee;
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

  Future<void> _cacheUserProfile(Map<String, dynamic> jsonData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kCachedProfileKey, jsonEncode(jsonData));
      await prefs.setInt(
        _kLastVerifiedKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      dev.log('User profile cached for offline fallback.', name: 'AuthService');
    } catch (e) {
      dev.log('Failed to cache user profile: $e', name: 'AuthService');
    }
  }

  /// ✅ Attempts to restore user from local cache if internet is down
  Future<Employee?> _tryOfflineLogin() async {
    dev.log(
      '⚠️ Network unreachable. Attempting Offline Login...',
      name: 'AuthService',
    );
    final prefs = await SharedPreferences.getInstance();

    final String? cachedData = prefs.getString(_kCachedProfileKey);
    final int? lastVerified = prefs.getInt(_kLastVerifiedKey);

    if (cachedData != null && lastVerified != null) {
      final lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastVerified);
      final difference = DateTime.now().difference(lastSyncTime);

      // ⏳ TIMER LOGIC: Check if within grace period (24 hours)
      if (difference.inHours < _kOfflineGracePeriodHours) {
        dev.log(
          '✅ Offline Session Valid (${difference.inMinutes} mins old). Restoring...',
          name: 'AuthService',
        );
        try {
          final Map<String, dynamic> json = jsonDecode(cachedData);
          return Employee.fromJson(json);
        } catch (e) {
          dev.log('❌ Corrupt offline data.', name: 'AuthService');
        }
      } else {
        dev.log(
          '❌ Offline Session Expired (${difference.inHours} hours old). Force Login.',
          name: 'AuthService',
        );
      }
    } else {
      dev.log('❌ No offline data found.', name: 'AuthService');
    }

    // If we fail to restore, we must let the error propagate so the UI shows the Login Screen
    return null;
  }

  /// A new method to be called on app startup.
  /// It checks for a saved token and tries to log the user in automatically.
  /// Updated AutoLogin with Offline Fallback
  Future<Employee?> tryAutoLogin() async {
    dev.log('--- Attempting Auto-Login ---', name: 'AuthService');
    final token = await _getToken();

    if (token == null) {
      dev.log('No token found. Auto-login skipped.', name: 'AuthService');
      return null;
    }

    try {
      // Decode user ID
      final payload = json.decode(
        ascii.decode(base64.decode(base64.normalize(token.split('.')[1]))),
      );
      final String userId = payload['id'].toString();

      // Try to fetch fresh data from server
      final employee = await _fetchUserProfile(userId, token);
      dev.log('Auto-login successful!', name: 'AuthService');
      return employee;
    } on SocketException {
      // 🛑 NO INTERNET: Try Offline
      final offlineUser = await _tryOfflineLogin();
      if (offlineUser != null) return offlineUser;

      // If offline login failed (expired/missing), rethrow so UI shows login screen
      rethrow;
    } on TimeoutException {
      // 🛑 SLOW INTERNET: Try Offline
      final offlineUser = await _tryOfflineLogin();
      if (offlineUser != null) return offlineUser;

      rethrow;
    } catch (e) {
      // ⚠️ ACTUAL AUTH ERROR (401/403)
      final errorStr = e.toString().toLowerCase();

      if (errorStr.contains("401") ||
          errorStr.contains("403") ||
          errorStr.contains("session expired") ||
          errorStr.contains("invalid token")) {
        dev.log('Session invalid ($e). Logging out.', name: 'AuthService');
        await logout();
      } else {
        // Unknown error? Try offline fallback just in case it's a server 500 error
        final offlineUser = await _tryOfflineLogin();
        if (offlineUser != null) return offlineUser;

        dev.log('Unknown error ($e).', name: 'AuthService');
        rethrow;
      }
      return null;
    }
  }
  // Inside AuthService class

  Future<void> syncDeviceToken(
    dynamic userId,
    String fcmToken,
    String deviceId,
  ) async {
    final url = Uri.parse('$baseUrl/api/users/device');

    // USING PRINT SO IT DEFINITELY SHOWS UP
    print("🔵 [Sync] Step 1: Process Started.");

    final authToken = await _getToken();

    if (authToken == null) {
      print("❌ [Sync] FAILURE: No Auth Token found in storage.");
      return;
    }

    // 1. DEBUG ID PARSING
    print(
      "🔵 [Sync] Step 2: Parsing ID. Raw: '$userId' (Type: ${userId.runtimeType})",
    );

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
