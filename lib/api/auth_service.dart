// lib/api/auth_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/users_model.dart';

class AuthService {
  // Use a centralized config file or .env for this in the future
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  //static const String baseUrl = 'https://your-production-domain.com/api/salesApp';
  
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Handles the login request, securely stores the JWT, and returns the UserModel
  Future<Map<String, dynamic>> login(String loginId, String password) async {
    try {
      final url = Uri.parse('$baseUrl/auth/login');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'salesmanLoginId': loginId, 
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _storage.write(key: 'jwt_token', value: data['token']);
        
        // Strictly parse the user data using the UserModel
        final user = UserModel.fromJson(data['user']);
        
        // Optional: Cache user profile locally
        await _storage.write(key: 'user_profile', value: jsonEncode(user.toJson()));
        
        return {'success': true, 'user': user};
      } else {
        return {'success': false, 'message': data['error'] ?? 'Invalid credentials'};
      }
    } on TimeoutException {
      return {'success': false, 'message': 'Connection timed out. Please try again.'};
    } catch (e) {
      print('Login Error: $e');
      return {'success': false, 'message': 'A network error occurred.'};
    }
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    // Navigate to Login Screen using your routing system after calling this
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}