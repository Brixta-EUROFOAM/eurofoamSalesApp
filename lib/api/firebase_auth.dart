import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final _secure = const FlutterSecureStorage();
  final String baseUrl;

  AuthService({required this.baseUrl});

  /// Sends the Firebase ID token to your backend.
  ///
  /// On success, saves the app_jwt and session_token,
  /// and returns the 'mason' user object.
  /// Returns `null` on failure.
  Future<Map<String, dynamic>?> sendFirebaseIdToken(String idToken) async {
    final uri = Uri.parse('$baseUrl/api/auth/firebase');
    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;

        // Parse response based on CONTRACTORSERVERSIDE.md
        final appJwt = data['jwt'] as String?;
        final sessionToken = data['sessionToken'] as String?;
        final mason = data['mason'] as Map<String, dynamic>?;

        // Save tokens securely
        if (appJwt != null) {
          await _secure.write(key: 'app_jwt', value: appJwt);
        }
        if (sessionToken != null) {
          await _secure.write(key: 'session_token', value: sessionToken);
        }

        // Return the user object for navigation
        return mason;
      } else {
        // Log the error for debugging
        print('Server error (${res.statusCode}): ${res.body}');
        return null;
      }
    } catch (e) {
      // Log network or parsing errors
      print('AuthService error: $e');
      return null;
    }
  }

  // --- ⬇️ START BYPASS MODIFICATION ⬇️ ---

  /// Bypasses Firebase and logs in directly with a phone number.
  ///
  /// This should ONLY be called in debug mode. It hits a special
  /// debug-only backend route.
  Future<Map<String, dynamic>?> sendDevBypassLogin(String phone) async {
    final uri = Uri.parse('$baseUrl/api/auth/firebase-dev-bypass');
    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}), // Send the phone number
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;

        // Parse response (same as the real function)
        final appJwt = data['jwt'] as String?;
        final sessionToken = data['sessionToken'] as String?;
        final mason = data['mason'] as Map<String, dynamic>?;

        // Save tokens securely
        if (appJwt != null) {
          await _secure.write(key: 'app_jwt', value: appJwt);
        }
        if (sessionToken != null) {
          await _secure.write(key: 'session_token', value: sessionToken);
        }

        // Return the user object for navigation
        return mason;
      } else {
        // Log the error for debugging
        print('Server error (${res.statusCode}): ${res.body}');
        return null;
      }
    } catch (e) {
      // Log network or parsing errors
      print('AuthService (Bypass) error: $e');
      return null;
    }
  }
  // --- ⬆️ END BYPASS MODIFICATION ⬆️ ---

  /// Logs the user out by invalidating the session on the backend
  /// and clearing local tokens.
  Future<void> logout() async {
    final sessionToken = await _secure.read(key: 'session_token');
    if (sessionToken != null) {
      final uri = Uri.parse('$baseUrl/api/auth/logout');
      try {
        await http.post(uri, headers: {'x-session-token': sessionToken});
      } catch (e) {
        // Fails silently if network is off, which is fine for logout
        print('Logout network error: $e');
      }
    }
    // Always clear local tokens
    await _secure.delete(key: 'app_jwt');
    await _secure.delete(key: 'session_token');
  }

  /// Retrieves the stored app_jwt.
  Future<String?> getStoredJwt() => _secure.read(key: 'app_jwt');
}