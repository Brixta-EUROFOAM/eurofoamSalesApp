import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as dev;

/// Manages the "hybrid" authentication flow.
/// - Handles Firebase OTP verification.
/// - Exchanges Firebase token for a backend JWT and Session Token.
/// - Securely stores and retrieves tokens.
/// - Implements session validation and silent refresh.
class AuthService {
  final String baseUrl;
  final _storage = const FlutterSecureStorage();
  final _client = http.Client();

  // Storage keys
  static const _jwtKey = 'app_jwt';
  static const _sessionTokenKey = 'session_token';
  static const _masonDetailsKey = 'mason_details';

  AuthService({required this.baseUrl});

  /// --- PRIVATE TOKEN HELPERS ---

  /// Stores all tokens and user info securely.
  Future<void> _storeTokens({
    required String jwt,
    required String sessionToken,
    required Map<String, dynamic> mason,
  }) async {
    await _storage.write(key: _jwtKey, value: jwt);
    await _storage.write(key: _sessionTokenKey, value: sessionToken);
    
    // Store basic user details for UI hints on next login
    // This helps pre-fill the "Welcome back, [Name]!" text
    await _storage.write(
      key: _masonDetailsKey,
      value: jsonEncode({
        'masonId': mason['id'],
        'masonName': mason['name'],
        'masonPhone': mason['phoneNumber'],
      }),
    );
    dev.log('Tokens and user details stored.', name: 'AuthService');
  }

  /// Retrieves the stored JWT and Session Token.
  Future<Map<String, String?>> _getTokens() async {
    final jwt = await _storage.read(key: _jwtKey);
    final sessionToken = await _storage.read(key: _sessionTokenKey);
    return {'jwt': jwt, 'sessionToken': sessionToken};
  }

  /// Clears all authentication data from storage.
  Future<void> _clearTokens() async {
    await _storage.delete(key: _jwtKey);
    await _storage.delete(key: _sessionTokenKey);
    await _storage.delete(key: _masonDetailsKey);
    dev.log('All tokens cleared.', name: 'AuthService');
  }

  /// --- PUBLIC SESSION MANAGEMENT ---

  /// Tries to log the user in automatically.
  /// This implements the "Validate -> Refresh" flow.
  /// Returns mason data if successful, null otherwise.
  Future<Map<String, dynamic>?> tryAutoLogin() async {
    dev.log('Attempting auto-login...', name: 'AuthService');
    final tokens = await _getTokens();
    final jwt = tokens['jwt'];
    final sessionToken = tokens['sessionToken'];

    if (jwt == null || sessionToken == null) {
      dev.log('No tokens found. Auto-login failed.', name: 'AuthService');
      return null;
    }

    // Step 1: Try to validate the current JWT with the backend
    dev.log('Validating stored JWT...', name: 'AuthService');
    final validationResponse = await _validateSession(jwt);
    if (validationResponse != null) {
      dev.log('JWT is valid. Auto-login successful.', name: 'AuthService');
      return validationResponse; // Success! Session is active.
    }

    // Step 2: JWT is invalid or expired. Try to refresh using the session token.
    dev.log('JWT invalid. Attempting to refresh session...', name: 'AuthService');
    final refreshResponse = await _refreshSession(sessionToken);
    if (refreshResponse != null) {
      dev.log('Session refresh successful. Auto-login successful.', name: 'AuthService');
      return refreshResponse; // Success! New tokens are stored.
    }

    // Step 3: Both validation and refresh failed.
    dev.log('Session refresh failed. Clearing tokens.', name: 'AuthService');
    await _clearTokens(); // Clear bad tokens
    return null;
  }

  /// Fetches basic stored user details to pre-fill login form.
  Future<Map<String, String?>> getStoredMasonDetails() async {
    final detailsString = await _storage.read(key: _masonDetailsKey);
    if (detailsString != null) {
      try {
        final data = jsonDecode(detailsString) as Map<String, dynamic>;
        // Ensure all values are returned as strings
        return {
          'masonId': data['masonId']?.toString(),
          'masonName': data['masonName']?.toString(),
          'masonPhone': data['masonPhone']?.toString(),
        };
      } catch (e) {
        dev.log('Could not parse stored mason details: $e', name: 'AuthService');
        return {};
      }
    }
    return {};
  }

  /// --- BACKEND API CALLS ---

  /// Step 1 (Manual Login): Exchange Firebase ID token for our backend tokens.
  /// The `name` is only sent during the *first* sign-up.
  Future<Map<String, dynamic>?> sendFirebaseIdToken(String idToken, String? name) async {
    final url = Uri.parse('$baseUrl/api/auth/firebase');
    dev.log('Sending Firebase ID token to backend...', name: 'AuthService');
    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        // Send the name along with the token.
        // The backend will only use it if it's a new user.
        body: jsonEncode({
          'idToken': idToken,
          'name': name, 
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final jwt = data['jwt'] as String;
          final sessionToken = data['sessionToken'] as String;
          final mason = data['mason'] as Map<String, dynamic>;

          // Store tokens securely
          await _storeTokens(jwt: jwt, sessionToken: sessionToken, mason: mason);
          return {'mason': mason};
        }
      }
      dev.log('Backend handshake failed: ${response.body}', name: 'AuthService');
      return null;
    } catch (e) {
      dev.log('Error in sendFirebaseIdToken: $e', name: 'AuthService');
      return null;
    }
  }

  /// Step 2 (Auto-Login): Validate the stored JWT.
  /// Hits GET /api/auth/validate
  Future<Map<String, dynamic>?> _validateSession(String jwt) async {
    final url = Uri.parse('$baseUrl/api/auth/validate');
    try {
      final response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt', // Send the JWT
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return {'mason': data['mason']}; // Session is valid
        }
      }
      // Any non-200 status means validation failed
      return null; 
    } catch (e) {
      dev.log('Error in _validateSession: $e', name: 'AuthService');
      return null;
    }
  }

  /// Step 3 (Auto-Login): Refresh the session using the session token.
  /// Hits POST /api/auth/refresh
  Future<Map<String, dynamic>?> _refreshSession(String sessionToken) async {
    final url = Uri.parse('$baseUrl/api/auth/refresh');
    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-session-token': sessionToken, // Send the session token
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final newJwt = data['jwt'] as String;
          final newSessionToken = data['sessionToken'] as String;
          final mason = data['mason'] as Map<String, dynamic>;

          // Store the NEW tokens
          await _storeTokens(jwt: newJwt, sessionToken: newSessionToken, mason: mason);
          return {'mason': mason};
        }
      }
      // Any non-200 status means refresh failed
      return null;
    } catch (e) {
      dev.log('Error in _refreshSession: $e', name: 'AuthService');
      return null;
    }
  }

  /// (Dev Only) Bypass login
  /// Hits POST /api/auth/dev-bypass
  Future<Map<String, dynamic>?> sendDevBypassLogin(String phone, String name) async {
    final url = Uri.parse('$baseUrl/api/auth/dev-bypass');
    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'name': name,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final jwt = data['jwt'] as String;
          final sessionToken = data['sessionToken'] as String;
          final mason = data['mason'] as Map<String, dynamic>;
          await _storeTokens(jwt: jwt, sessionToken: sessionToken, mason: mason);
          return {'mason': mason};
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Logout: Clears local tokens and invalidates server session.
  /// Hits POST /api/auth/logout
  Future<void> logout() async {
    final tokens = await _getTokens();
    final sessionToken = tokens['sessionToken'];

    if (sessionToken != null) {
      final url = Uri.parse('$baseUrl/api/auth/logout');
      try {
        // Tell the server to delete this session
        await _client.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'x-session-token': sessionToken,
          },
        ).timeout(const Duration(seconds: 5));
      } catch (e) {
        // Don't block logout if server call fails
        dev.log('Server logout failed, clearing local tokens anyway.', name: 'AuthService');
      }
    }
    // Always clear local data
    await _clearTokens();
    await FirebaseAuth.instance.signOut(); // Also sign out from Firebase
    dev.log('Logged out.', name: 'AuthService');
  }

  /// Helper to get the currently stored JWT (for ApiService)
  Future<String?> getStoredJwt() async {
    return await _storage.read(key: _jwtKey);
  }
}