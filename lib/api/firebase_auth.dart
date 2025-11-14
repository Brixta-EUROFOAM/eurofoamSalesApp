import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:assetarchiverflutter/api/api_service.dart';
import 'dart:developer' as dev;

class AuthService {
  final _secure = const FlutterSecureStorage();
  final String baseUrl;

  AuthService({required this.baseUrl});

  // -------------------------------------------------------------------
  // 1. INITIAL LOGIN HANDLER (Saves long-lived session_token)
  // -------------------------------------------------------------------

  /// Sends the Firebase ID token to your backend.
  ///
  /// On success, saves app_jwt and session_token, and returns the full response.
  Future<Map<String, dynamic>?> sendFirebaseIdToken(String idToken) async {
    final uri = Uri.parse('$baseUrl/api/auth/firebase');
    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      dev.log('POST $uri status=${res.statusCode} body=${res.body}', name: 'AuthService');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;

        final appJwt = data['jwt'] as String?;
        final sessionToken = data['sessionToken'] as String?;
        final masonData = data['mason'] as Map<String, dynamic>?;

        // Save tokens and basic user data for future auto-login
        if (appJwt != null && sessionToken != null && masonData != null) {
          await _saveSession(appJwt, sessionToken, masonData);
          dev.log('Stored server JWT and Session Token successfully.', name: 'AuthService');
        }

        return data;
      } else {
        dev.log('Server error (${res.statusCode}): ${res.body}', name: 'AuthService');
        return null;
      }
    } catch (e, st) {
      dev.log('AuthService error: $e\n$st', name: 'AuthService');
      return null;
    }
  }

  // --- Session Storage Helper ---
  Future<void> _saveSession(String appJwt, String sessionToken, Map<String, dynamic> masonData) async {
    await _secure.write(key: 'app_jwt', value: appJwt);
    await _secure.write(key: 'session_token', value: sessionToken);
    
    // Save primary user details for returning user UI (ContractorLoginScreen)
    await _secure.write(key: 'masonName', value: masonData['name'] ?? '');
    await _secure.write(key: 'masonPhone', value: masonData['phoneNumber'] ?? '');
    
    // Set global token for all future API calls
    ApiService.setAuthToken(appJwt);
  }

  // -------------------------------------------------------------------
  // 2. SESSION VALIDATION HELPERS
  // -------------------------------------------------------------------

  /// Checks the current stored JWT against the server. Returns Mason data if valid.
  Future<Map<String, dynamic>?> _validateSession() async {
    final jwt = await _secure.read(key: 'app_jwt');
    if (jwt == null) return null;

    final uri = Uri.parse('$baseUrl/api/auth/validate');
    try {
      final res = await http.get(
        uri,
        // MUST explicitly set the Authorization header for this call
        headers: {
          'Authorization': 'Bearer $jwt',
        },
      );

      dev.log('GET /auth/validate status=${res.statusCode}', name: 'AuthService');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return data; // Returns { success: true, mason: {...} }
      }
      return null;
    } catch (e, st) {
      dev.log('Validation error: $e\n$st', name: 'AuthService');
      return null;
    }
  }

  /// Attempts to get a new JWT using the stored long-lived session_token.
  /// If successful, saves the NEW tokens and returns true.
  Future<bool> _refreshSession() async {
    final sessionToken = await _secure.read(key: 'session_token');
    if (sessionToken == null) return false;

    final uri = Uri.parse('$baseUrl/api/auth/refresh');
    try {
      final res = await http.post(
        uri,
        // Sends the long-lived token via custom header
        headers: {'x-session-token': sessionToken},
      );
      
      dev.log('POST /auth/refresh status=${res.statusCode}', name: 'AuthService');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final newAppJwt = data['jwt'] as String?;
        final newSessionToken = data['sessionToken'] as String?;

        if (newAppJwt != null && newSessionToken != null) {
          // We need Mason data to proceed, but /refresh doesn't return it.
          // We must save the new tokens and proceed to validate them.
          await _secure.write(key: 'app_jwt', value: newAppJwt);
          await _secure.write(key: 'session_token', value: newSessionToken);
          ApiService.setAuthToken(newAppJwt);
          return true; // Successfully refreshed!
        }
      }
      return false; // Refresh failed (token truly expired/invalid)
    } catch (e, st) {
      dev.log('Refresh network error: $e\n$st', name: 'AuthService');
      return false;
    }
  }


  // -------------------------------------------------------------------
  // 3. CORE AUTO-LOGIN LOGIC
  // -------------------------------------------------------------------

  /// Main function for auto-login/session restoration.
  /// 
  /// Tries to validate the JWT. If validation fails with 401, attempts a silent refresh.
  Future<Map<String, dynamic>?> tryAutoLogin() async {
    // 1. Attempt standard validation (JWT should be valid here)
    var serverStub = await _validateSession();

    if (serverStub != null) {
      dev.log('Validation SUCCESS.', name: 'AuthService');
      return serverStub;
    }
    
    dev.log('Validation FAILED (Token expired or invalid).', name: 'AuthService');

    // 2. Validation failed: Attempt silent session refresh
    final didRefresh = await _refreshSession();

    if (didRefresh) {
      dev.log('Silent Refresh SUCCESS. Re-validating new JWT.', name: 'AuthService');
      // 3. Refresh successful: Re-validate using the newly saved JWT
      serverStub = await _validateSession(); 
      
      if (serverStub != null) {
        dev.log('Re-validation SUCCESS with new JWT.', name: 'AuthService');
        return serverStub;
      }
    }
    
    // 4. Final fail: Clear everything and require manual login
    dev.log('Refresh or Re-validation FAILED. Clearing session.', name: 'AuthService');
    await logout(notifyServer: false); 
    return null;
  }

  // --- Other Methods ---

  // ... (sendDevBypassLogin is unchanged) ...
  Future<Map<String, dynamic>?> sendDevBypassLogin(String phone) async {
    final uri = Uri.parse('$baseUrl/api/auth/firebase-dev-bypass');
    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      );

      dev.log('POST (bypass) $uri status=${res.statusCode} body=${res.body}', name: 'AuthService');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final appJwt = data['jwt'] as String?;
        final sessionToken = data['sessionToken'] as String?;
        final masonData = data['mason'] as Map<String, dynamic>?;

        if (appJwt != null && sessionToken != null && masonData != null) {
          await _saveSession(appJwt, sessionToken, masonData);
          dev.log('Stored server JWT for bypass.', name: 'AuthService');
        }
        return data;
      } else {
        dev.log('Server error (${res.statusCode}): ${res.body}', name: 'AuthService');
        return null;
      }
    } catch (e, st) {
      dev.log('AuthService (Bypass) error: $e\n$st', name: 'AuthService');
      return null;
    }
  }


  /// Logs the user out by invalidating the session on the backend
  /// and clearing local tokens.
  Future<void> logout({bool notifyServer = true}) async {
    final sessionToken = await _secure.read(key: 'session_token');
    if (sessionToken != null && notifyServer) {
      final uri = Uri.parse('$baseUrl/api/auth/logout');
      try {
        await http.post(uri, headers: {'x-session-token': sessionToken});
      } catch (e) {
        dev.log('Logout network error: $e', name: 'AuthService');
      }
    }
    await _secure.delete(key: 'app_jwt');
    await _secure.delete(key: 'session_token');
    await _secure.delete(key: 'masonName');
    await _secure.delete(key: 'masonPhone');
    ApiService.setAuthToken(null);
  }

  /// Retrieves the stored app_jwt.
  Future<String?> getStoredJwt() => _secure.read(key: 'app_jwt');

  /// Retrieves stored name and phone for returning user UI.
  Future<Map<String, String?>> getStoredMasonDetails() async {
    return {
      'masonName': await _secure.read(key: 'masonName'),
      'masonPhone': await _secure.read(key: 'masonPhone'),
    };
  }
}