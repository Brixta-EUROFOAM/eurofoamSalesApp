Got it. You want to regenerate the `WORKING.MD` with an **improved, "paste-ready" structure**.

I'll reformat the document. For the files you've provided code for (`main.dart`, `auth_service.dart`, `api_service.dart`, and `nav_screen.dart`), I will keep the detailed analysis, but I'll add a **single, complete, "paste-ready" code block** at the end of each file's section.

For all the other files (models, widgets, and other screens), I will keep the analysis as-is, ready for you to provide the code when you're ready.

Here is the regenerated and improved `WORKING.MD`:

-----

# Flutter Project Analysis

This document provides a hyper-detailed breakdown of the `lib/` directory, explaining the core working logic of each file and its role within the application.

## `lib/main.dart`

#### `Purpose`

This is the main entry point for the entire Flutter application. It initializes essential services, sets up the application's theme, and handles the initial routing logic (deciding whether to show the `LoginScreen` or the `NavScreen`).

#### `Core Logic`

1.  **Initialization:** The `main()` function is `async`. It ensures Flutter is initialized (`WidgetsFlutterBinding.ensureInitialized()`), loads environment variables from the `.env` file (like API keys) using `flutter_dotenv`, initializes the `Hive` local database (`Hive.initFlutter()`), and initializes the `Radar` SDK (`Radar.initialize()`).
2.  **Authentication Check:** Before the app UI runs, it performs an *asynchronous* auto-login check by calling `AuthService().tryAutoLogin()`. This awaits a future that returns an `Employee` object if a valid, non-expired token is found in secure storage, or `null` if not.
3.  **Theme Provider:** The entire application is wrapped in a `ChangeNotifierProvider` for `ThemeProvider`. This allows any widget in the app to "listen" for theme changes (Light/Dark/System) and rebuild itself.
4.  **Root Widget (`MyApp`):**
      * It's a `StatelessWidget` that receives the `loggedInEmployee` (which is either an `Employee` object or `null`).
      * **Theme Management:** It "listens" to the `ThemeProvider` using `Provider.of<ThemeProvider>(context)`. It passes the `AppTheme.lightTheme`, `AppTheme.darkTheme`, and the provider's `themeMode` to the `MaterialApp`. When the `ThemeProvider` calls `notifyListeners()`, this widget rebuilds, and the `MaterialApp` switches its theme.
      * **Initial Routing:** It sets the `initialRoute` based on the `loggedInEmployee` variable. If it's not `null`, the user is sent to `/home`; otherwise, they go to `/login`.
      * **Route Handling:** It defines `/login` in `routes`. It uses `onGenerateRoute` for the `/home` route. This is crucial because it allows the app to pass the `Employee` object (either from `tryAutoLogin` or from the `LoginScreen`'s `Navigator.pushNamed` arguments) directly to the `NavScreen`'s constructor.

-----

#### `Paste-Ready Code: lib/main.dart`

```dart
// lib/main.dart

import 'package:assetarchiverflutter/api/auth_service.dart';
import 'package:assetarchiverflutter/screens/auth/login_screen.dart';
import 'package:assetarchiverflutter/screens/nav_screen.dart';
import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart'; Font logic nelaage ru..app theme . dart ot ase
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_radar/flutter_radar.dart';
import 'package:hive_flutter/hive_flutter.dart';

// --- NEW IMPORTS ---
import 'package:provider/provider.dart';
import 'package:assetarchiverflutter/widgets/app_theme.dart';
import 'package:assetarchiverflutter/widgets/theme_provider.dart';
// --- END NEW IMPORTS ---

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Hive.initFlutter();

  final radarPublishableKey = dotenv.env['RADAR_API_KEY'];
  if (radarPublishableKey != null) {
    await Radar.initialize(radarPublishableKey);
    debugPrint("✅ Radar SDK Initialized Successfully.");
  } else {
    debugPrint("❌ ERROR: RADAR_PUBLISHABLE_KEY not found in .env file. Tracking will fail.");
  }
  
  final Employee? loggedInEmployee = await AuthService().tryAutoLogin();

  // --- UPDATED: Wrap your app in the ThemeProvider ---
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: MyApp(loggedInEmployee: loggedInEmployee),
    ),
  );
  // --- END UPDATE ---
}

class MyApp extends StatelessWidget {
  final Employee? loggedInEmployee;
  const MyApp({super.key, this.loggedInEmployee});

  @override
  Widget build(BuildContext context) {
    // This line "listens" to the ThemeProvider for changes
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Modern App',

      // --- UPDATED: This is the magic! ---
      // We now provide both themes and let the provider
      // choose which one to show.
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      // --- END UPDATE ---

      // Your existing logic is perfect and remains unchanged
      initialRoute: loggedInEmployee != null ? '/home' : '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          final employee = loggedInEmployee ?? settings.arguments as Employee;
          return MaterialPageRoute(
            builder: (context) {
              return NavScreen(employee: employee);
            },
          );
        }
        return null;
      },
    );
  }
}
```

-----

## `lib/api/`

### `Purpose`

This directory is the **Data Layer** of the application. It acts as a "repository" that abstracts all network communication away from the UI (screens). It is responsible for making HTTP requests to the backend, handling authentication, and parsing JSON responses into the app's data models.

### `lib/api/auth_service.dart`

#### `Purpose`

This class is solely responsible for handling user authentication and session management. It manages the user's JSON Web Token (JWT) and fetches the employee's profile.

#### `Core Logic`

1.  **Secure Storage:** It uses an instance of `FlutterSecureStorage` to securely save and read the user's JWT (session token) on the device. The helper functions `_saveToken`, `_getToken`, and `logout` handle this.
2.  **`login(String loginId, String password)`:** This is the main login function, and it performs a critical two-step process:
      * **Step 1:** It sends the `loginId` and `password` to the `/api/auth/login` endpoint. The server (if successful) returns a `token` and `userId`.
      * **Step 2:** It immediately calls `_saveToken(token)` to securely store the session.
      * **Step 3:** It then immediately calls the private `_fetchUserProfile` method, passing the new `userId` and `token` to get the full employee details.
3.  **`_fetchUserProfile(String userId, String token)`:** This is a private helper that makes an authenticated GET request to the protected `/api/users/:id` endpoint.
      * **Critical Logic:** It adds the `Authorization: 'Bearer $token'` header to the request. This is what proves to the server that this request is authenticated and allowed to access protected user data.
      * It parses the `data` field from the JSON response into an `Employee` model.
4.  **`tryAutoLogin()`:** This function is called by `main.dart` when the app first starts.
      * It attempts to `_getToken()` from secure storage.
      * If a token exists, it performs **local JWT decoding** (`base64.decode`) to extract the `userId` (`payload['id']`) from the token's payload *without* a network request.
      * It then calls `_fetchUserProfile` using the stored token and extracted `userId` to validate the session with the server and get fresh user data.
      * If `_fetchUserProfile` fails (e.g., the token is expired and the server returns a 403), the `catch` block calls `logout()` to clear the bad token and returns `null`, forcing the user to log in again.
5.  **`logout()`:** This function simply deletes the `jwt_token` from `FlutterSecureStorage`, effectively destroying the user's session.

-----

#### `Paste-Ready Code: lib/api/auth_service.dart`

```dart
// lib/api/auth_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/employee_model.dart'; // Make sure this path is correct for your project

class AuthService {
  static const String _baseUrl = 'https://myserverbymycoco.onrender.com';
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
    await _storage.delete(key: 'jwt_token');
    dev.log('Token deleted. User logged out.', name: 'AuthService');
  }

  /// Main login function.
  /// It now gets a JWT, saves it, and then fetches the user's profile.
  Future<Employee> login(String loginId, String password) async {
    final url = Uri.parse('$_baseUrl/api/auth/login');
    final requestBody = jsonEncode({
      'loginId': loginId.trim(),
      'password': password
    });

    dev.log('--- Sending Login Request ---', name: 'AuthService');
    try {
      final response = await http
          .post(url, headers: {'Content-Type': 'application/json'}, body: requestBody)
          .timeout(const Duration(seconds: 45));

      dev.log('--- Received Login Response ---', name: 'AuthService');
      dev.log('Status Code: ${response.statusCode}', name: 'AuthService');

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
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'An unknown server error occurred.');
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
      final response = await http.get(
        url,
        // This Authorization header is what authenticates the request
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

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
        ascii.decode(base64.decode(base64.normalize(token.split('.')[1])))
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
}
```

-----

### `lib/api/api_service.dart`

#### `Purpose`

This is the primary data service (or "repository") for the *entire* application. It centralizes all non-auth CRUD (Create, Read, Update, Delete) operations for every data model (Dealers, Reports, PJPs, etc.), providing a clean, strongly-typed API for the rest of the app.

#### `Core Logic`

1.  **Generic Helpers (`_get`, `_post`, `_patch`, `_delete`):** The class is built on four private generic helper methods. This is a core architectural pattern that keeps the code DRY (Don't Repeat Yourself).
      * These methods contain all the boilerplate logic: building the `Uri` from `_baseUrl`, setting `Content-Type` headers, `jsonEncode`-ing the request body, and setting a 45-second `timeout`.
      * **Response Parsing:** They *all* expect a standard JSON response wrapper from the server: `{"success": true, "data": ...}`. They parse this, check `if (jsonData['success'] == true)`, and then pass *only* the `jsonData['data']` portion to the `fromJson` function that was passed in.
      * **Error Handling:** If `success` is false or the status code is not 200/201, they throw a detailed `Exception` using the `jsonData['error']` message from the server.
2.  **Strongly-Typed Public Methods:** The class exposes a public method for every API call the app needs. These are clean, one-line wrappers around the generic helpers.
      * **Example:** `createDvr(DailyVisitReport dvr)` simply calls `_post('daily-visit-reports', dvr.toJson(), (json) => DailyVisitReport.fromJson(json))`. The UI layer just calls `apiService.createDvr(myDvr)` and gets a `Future<DailyVisitReport>` back, without ever dealing with HTTP or JSON.
3.  **Specialized PJP Logic:**
      * `fetchPjpsForUser`: A flexible GET request that builds query parameters for `startDate`, `endDate`, `status`, and `dealerId` to filter the PJP list.
      * `fetchPendingAndVerifiedPjps`: A crucial function for the PJP screen. It uses `Future.wait` to make two *parallel* calls to `fetchPjpsForUser`: one for `status: 'PENDING'` and one for `status: 'VERIFIED'`. It then bundles both lists into a single `PjpData` object.
      * `createBulkPjp`: This method does **not** use the `_post` helper. This is a deliberate choice because the `/api/bulkpjp` endpoint returns a unique JSON response (`{"success": true, "totalRowsCreated": 80}`) that *lacks* the `data` field that `_post` expects. This custom `http.post` call handles that specific response structure.
4.  **Specialized Network Methods:**
      * **`uploadImageToR2(File imageFile)`:** This does not use the generic helpers. It constructs a `http.MultipartRequest`, adds the `File`, and sends it to the `/api/r2/upload-direct` endpoint. It's used for all photo uploads (check-in, DVR, TVR).
      * **`sendGeoTrackingPoint(GeoTrackingPoint point)`:** A "fire-and-forget" POST request to `/api/geotracking`. It has a short 10-second timeout and a `try/catch` block that *does not rethrow*. It only logs the error (`dev.log`). This is a critical design choice: a single failed location ping during a journey (e.g., bad network) should not crash the app or show an error to the user.
      * **`reverseGeocodeWithRadar(...)`:** A GET request to a *third-party* API (`api.radar.io`) using the `RADAR_API_KEY` from `.env`. It parses the address components from the response. This is used in the `add_dealer_form.dart` to auto-fill addresses.
      * **`searchPhotonAddress(String query)`:** A GET request to another *third-party* API (`photon.komoot.io`) for address autocomplete. This is used in `add_dealer_form.dart` for the Godown and Residential address fields.

-----

#### `Paste-Ready Code: lib/api/api_service.dart`

```dart
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/dealer_model.dart';
import '../models/pjp_model.dart';
import '../models/daily_task_model.dart';
import '../models/leave_application_model.dart';
import '../models/attendance_model.dart';
import '../models/daily_visit_report_model.dart';
import '../models/technical_visit_report_model.dart';
import '../models/geotracking_data_model.dart';
import '../models/competition_report_model.dart';

class ApiService {
  // --- ✅ FIX 1: Removed the space after 'https:' ---
  static const String _baseUrl = 'https://myserverbymycoco.onrender.com';

  // --- GENERIC HELPERS (Unchanged) ---
  Future<T> _get<T>(String endpoint, T Function(dynamic json) fromJson) async {
    final url = Uri.parse('$_baseUrl/api/$endpoint');
    
    // --- ✅ DEBUGGING: Log the full URL being called ---
    dev.log('GET: $url', name: 'ApiService');
    
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 45));
      final jsonData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (jsonData['success'] == true && jsonData['data'] != null) {
          // The fromJson function receives ONLY the 'data' property
          return fromJson(jsonData['data']);
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
    final url = Uri.parse('$_baseUrl/api/$endpoint');
    dev.log('POST: $url', name: 'ApiService');
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 45));
      final jsonData = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
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
    final url = Uri.parse('$_baseUrl/api/$endpoint');
    dev.log('PATCH: $url', name: 'ApiService');
    try {
      final response = await http
          .patch(
            url,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
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
    final url = Uri.parse('$_baseUrl/api/$endpoint');
    dev.log('DELETE: $url', name: 'ApiService');
    try {
      final response =
          await http.delete(url).timeout(const Duration(seconds: 45));
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

  // ... (uploadImageToR2, performOcr, sendGeoTrackingPoint, reverseGeocodeWithRadar, searchPhotonAddress are all unchanged) ...
  Future<String> uploadImageToR2(File imageFile) async {
    final url = Uri.parse('$_baseUrl/api/r2/upload-direct');
    dev.log('POST (Multipart): $url', name: 'ApiService');
    try {
      final request = http.MultipartRequest('POST', url);
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
      String imageUrl, String docType) async {
    dev.log('Performing MOCK OCR for $docType on $imageUrl',
        name: 'ApiService');
    await Future.delayed(const Duration(seconds: 2));
    switch (docType) {
      case 'tradeLicense':
        return {
          'gstin': 'MOCK_GSTIN_12345',
          'pan': 'MOCK_PAN_67890',
          'tradeLicNo': 'MOCK_LIC_789'
        };
      case 'blankCheque':
        return {
          'accountName': 'MOCK DEALER NAME',
          'accountNumber': 'MOCK_123456789',
          'ifsc': 'MOCK_IFSC001',
          'bankName': 'MOCK BANK'
        };
      case 'partnershipDeed':
        return {'aadhar': 'MOCK_987654321'};
      default:
        return {};
    }
  }

  Future<void> sendGeoTrackingPoint(GeoTrackingPoint point) async {
    final url = Uri.parse('$_baseUrl/api/geotracking');
    final body = point.toJson();
    body.removeWhere((key, value) => value == null);
    dev.log('POST GeoTracking: $url', name: 'ApiService');
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 201) {
        final jsonData = jsonDecode(response.body);
        dev.log(
          'GeoTracking failed: ${response.statusCode}',
          error: jsonData['error'] ?? response.body,
          name: 'ApiService',
        );
      }
    } catch (e) {
      dev.log(
        'GeoTracking API Error (No connectivity?): $e',
        name: 'ApiService',
      );
    }
  }

  Future<Map<String, String>> reverseGeocodeWithRadar({
    required double latitude,
    required double longitude,
  }) async {
    final radarApiKey = dotenv.env['RADAR_API_KEY'];
    if (radarApiKey == null) {
      throw Exception('RADAR_API_KEY not found in .env file');
    }
    final url = Uri.https('api.radar.io', '/v1/geocode/reverse', {
      'coordinates': '$latitude,$longitude',
    });
    dev.log('GET: $url', name: 'RadarApiService');
    try {
      final response = await http
          .get(url, headers: {'Authorization': radarApiKey})
          .timeout(const Duration(seconds: 15));
      final jsonData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (jsonData['addresses'] != null &&
            (jsonData['addresses'] as List).isNotEmpty) {
          final firstResult = jsonData['addresses'][0];
          return {
            'address': firstResult['formattedAddress'] ?? 'Unknown Address',
            'region': firstResult['city'] ?? 'Unknown Region',
            'area': firstResult['neighborhood'] ??
                firstResult['county'] ??
                'Unknown Area',
            'pinCode': firstResult['postalCode'] ?? '',
            'district': firstResult['county'] ?? '',
            'landmark': firstResult['addressLabel'] ?? '',
          };
        } else {
          throw Exception('Could not determine address from coordinates.');
        }
      } else {
        throw Exception(
          jsonData['meta']?['message'] ?? 'Failed to reverse geocode.',
        );
      }
    } catch (e) {
      dev.log(
        'Radar API Error on reverseGeocodeWithRadar',
        error: e,
        name: 'RadarApiService',
      );
      rethrow;
    }
  }

  Future<List<dynamic>> searchPhotonAddress(String query) async {
    final url = Uri.https('photon.komoot.io', '/api/', {
      'q': query,
      'limit': '5',
    });
    dev.log('GET: $url', name: 'PhotonApiService');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return (jsonData['features'] as List? ?? []);
      } else {
        throw Exception(
          'Failed to search Photon. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      dev.log(
        'Photon API Error on searchPhotonAddress',
        error: e,
        name: 'PhotonApiService',
      );
      rethrow;
    }
  }

  // --- DEALER METHODS (UNCHANGED) ---
  Future<List<Dealer>> fetchDealers(
      {String? region,
      String? area,
      String? type,
      int? userId,
      int page = 1,
      int limit = 500}) async {
    final queryParams = <String, String>{
      if (region != null) 'region': region,
      if (area != null) 'area': area,
      if (type != null) 'type': type,
      if (userId != null) 'userId': userId.toString(),
      'page': page.toString(),
      'limit': limit.toString(),
    };
    final endpoint = Uri(
      path: 'dealers',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    ).toString();
    return _get(
      endpoint,
      (json) => (json as List).map((item) => Dealer.fromJson(item)).toList(),
    );
  }

  Future<Dealer> fetchDealerById(String dealerId) {
    return _get(
      'dealers/$dealerId',
      (json) => Dealer.fromJson(json),
    );
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

  Future<Dealer> createDealer(
    Dealer dealer, {
    double? radius,
  }) async {
    final body = dealer.toJson();
    if (radius != null) {
      body['radius'] = radius.toString();
    }
    return _post(
      'dealers',
      body,
      (json) => Dealer.fromJson(json),
    );
  }

  Future<Dealer> updateDealer(
    String dealerId,
    Map<String, dynamic> data,
  ) async {
    return _patch(
      'dealers/$dealerId',
      data,
      (json) => Dealer.fromJson(json),
    );
  }

  Future<void> deleteDealer(String dealerId) => _delete('dealers/$dealerId');

  // --- PJP METHODS ---

  // ✅ THIS FUNCTION IS NOW FULLY UPGRADED
  /// Fetches PJPs for a specific user, with optional filters.
  /// This hits the `GET /api/pjp/user/:userId` endpoint, which
  /// supports all the query parameters from `buildWhere`.
  Future<List<Pjp>> fetchPjpsForUser(
    int userId, {
    String? startDate,
    String? endDate,
    String? status,
    String? dealerId, // <-- ✅ NEWLY ADDED
  }) async {
    final queryParams = <String, String>{
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (status != null) 'status': status,
      if (dealerId != null) 'dealerId': dealerId, // <-- ✅ NEWLY ADDED
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

  // ✅ NEW FUNCTION
  /// Fetches a single PJP by its ID.
  /// Hits `GET /api/pjp/:id`
  Future<Pjp> fetchPjpById(String pjpId) async {
    return _get(
      'pjp/$pjpId',
      (json) => Pjp.fromJson(json), // 'data' is a single Pjp object
    );
  }

  // ✅ NEW FUNCTION
  /// Fetches PJPs by status (e.g., 'pending', 'approved').
  /// Hits `GET /api/pjp/status/:status`
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
      path: 'pjp/status/$status', // <-- Uses the new route
      queryParameters: queryParams.isEmpty ? null : queryParams,
    ).toString();
    return _get(
      endpoint,
      (json) => (json as List).map((item) => Pjp.fromJson(item)).toList(),
    );
  }

  // --- ✅ NEWLY ADDED FUNCTION ---
  /// Fetches PJPs that are 'PENDING' OR 'VERIFIED' in parallel.
  /// Also passes along any optional date or dealer filters.
  Future<PjpData> fetchPendingAndVerifiedPjps({
  // --- ✅ ADD THIS REQUIRED PARAMETER ---
  required int userId,
  // ---
  String? startDate,
  String? endDate,
  String? dealerId,
}) async {
  try {
    // --- ✅ WE MUST USE fetchPjpsForUser TO FILTER BY USER ---
    final List<List<Pjp>> results = await Future.wait([
      fetchPjpsForUser(
        userId,
        status: 'PENDING', // Use the new backend status
        startDate: startDate,
        endDate: endDate,
        dealerId: dealerId,
      ),
      fetchPjpsForUser(
        userId,
        status: 'VERIFIED', // Use the new backend status
        startDate: startDate,
        endDate: endDate,
        dealerId: dealerId,
      ),
    ]);

    // 2. 'results' is [ [pending_pjps], [verified_pjps] ]
    //    Package them into the PjpData object.
    return PjpData(
      pendingPjps: results[0],  // The 'PENDING' list
      verifiedPjps: results[1], // The 'VERIFIED' list
    );

  } catch (e) {
    // Handle any errors
    dev.log('Failed to fetch PENDING and VERIFIED PJPs: $e', name: 'ApiService');
    // Return empty data on failure
    return PjpData(pendingPjps: [], verifiedPjps: []);
  }
}
  // --- END NEWLY ADDED FUNCTION ---

  Future<Pjp> createPjp(Pjp pjp) async {
    // This now correctly uses the updated Pjp.toJson()
    return _post('pjp', pjp.toJson(), (json) => Pjp.fromJson(json));
  }

  // --- ✅ NEW: BULK PJP CREATION ---
  /// Sends a list of PJPs to a bulk-creation endpoint.
  /// Matches the `POST /api/bulkpjp` endpoint.
  Future<Map<String, dynamic>> createBulkPjp({
    required int userId,
    required int createdById,
    required List<String> dealerIds,
    required DateTime baseDate,
    required int batchSizePerDay,
    required String areaToBeVisited, // This is the default "area" string
    String? description,
    String status = 'PENDING',
  }) async {
    // 1. Create the final body matching the server's `bulkSchema`
    final body = {
      'userId': userId,
      'createdById': createdById,
      'dealerIds': dealerIds,
      'baseDate': baseDate.toIso8601String().split('T')[0], // YYYY-MM-DD
      'batchSizePerDay': batchSizePerDay,
      'areaToBeVisited': areaToBeVisited,
      'description': description,
      'status': status,
    };
    
    // 2. Remove nulls, just in case (though `description` is the only one)
    body.removeWhere((key, value) => value == null);

    // 3. --- 🚨 CRITICAL FIX ---
    // We cannot use the generic `_post` helper because the server's response
    // for `bulkpjp` (e.g., `{"success": true, "totalRowsCreated": 80}`)
    // does *not* have a `data` field, which `_post` expects.
    // We must make a custom call.
    
    final url = Uri.parse('$_baseUrl/api/bulkpjp');
    dev.log('POST (Bulk): $url', name: 'ApiService');
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 90)); // Increased timeout for bulk op
          
      final jsonData = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
         if (jsonData['success'] == true) {
          // Return the whole success body: {"success": true, "totalRowsCreated": ...}
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
  // --- END NEW FUNCTION ---

  Future<Pjp> updatePjp(String pjpId, Map<String, dynamic> data) async {
    return _patch('pjp/$pjpId', data, (json) => Pjp.fromJson(json));
  }

  Future<void> deletePjp(String pjpId) => _delete('pjp/$pjpId');
  // --- (All other methods for Tasks, Leave, DVR, etc. are UNCHANGED) ---
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
    final endpoint = Uri(
      path: 'daily-tasks/user/$userId',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    ).toString();
    return _get(
      endpoint,
      (json) => (json as List).map((item) => DailyTask.fromJson(item)).toList(),
    );
  }

  Future<List<LeaveApplication>> fetchLeaveApplicationsForUser(
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
    final endpoint = Uri(
      path: 'leave-applications/user/$userId',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    ).toString();
    return _get(
      endpoint,
      (json) => (json as List)
          .map((item) => LeaveApplication.fromJson(item))
          .toList(),
    );
  }

  Future<List<Attendance>> fetchAttendanceForUser(
    int userId, {
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, String>{
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
    };
    final endpoint = Uri(
      path: 'attendance/user/$userId',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    ).toString();
    return _get(
      endpoint,
      (json) =>
          (json as List).map((item) => Attendance.fromJson(item)).toList(),
    );
  }

  Future<Attendance> fetchTodaysAttendance(int userId) {
    return _get(
      'attendance/user/$userId/today',
      (json) => Attendance.fromJson(json),
    );
  }

  Future<List<DailyVisitReport>> fetchDvrsForUser(
    int userId, {
    String? startDate,
    String? endDate,
    String? dealerType,
    String? visitType,
  }) async {
    final queryParams = <String, String>{
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (dealerType != null) 'dealerType': dealerType,
      if (visitType != null) 'visitType': visitType,
    };
    final endpoint = Uri(
      path: 'daily-visit-reports/user/$userId',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    ).toString();
    return _get(
      endpoint,
      (json) => (json as List)
          .map((item) => DailyVisitReport.fromJson(item))
          .toList(),
    );
  }

  Future<List<TechnicalVisitReport>> fetchTvrsForUser(
    int userId, {
    String? startDate,
    String? endDate,
    String? visitType,
    String? serviceType,
  }) async {
    final queryParams = <String, String>{
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (visitType != null) 'visitType': visitType,
      if (serviceType != null) 'serviceType': serviceType,
    };
    final endpoint = Uri(
      path: 'technical-visit-reports/user/$userId',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    ).toString();
    return _get(
      endpoint,
      (json) => (json as List)
          .map((item) => TechnicalVisitReport.fromJson(item))
          .toList(),
    );
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

  Future<DailyTask> createDailyTask(DailyTask task) async {
    return _post(
      'daily-tasks',
      task.toJson(),
      (json) => DailyTask.fromJson(json),
    );
  }

  Future<DailyVisitReport> createDvr(DailyVisitReport dvr) async {
    return _post(
      'daily-visit-reports',
      dvr.toJson(),
      (json) => DailyVisitReport.fromJson(json),
    );
  }

  Future<TechnicalVisitReport> createTvr(TechnicalVisitReport tvr) async {
    return _post(
      'technical-visit-reports',
      tvr.toJson(),
      (json) => TechnicalVisitReport.fromJson(json),
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

  Future<CompetitionReport> createCompetitionReport(
    CompetitionReport report,
  ) async {
    return _post(
      'competition-reports',
      report.toJson(),
      (json) => CompetitionReport.fromJson(json),
    );
  }

  Future<void> deleteDailyTask(String taskId) => _delete('daily-tasks/$taskId');
  Future<void> deleteDvr(String dvrId) =>
      _delete('daily-visit-reports/$dvrId');
  Future<void> deleteTvr(String tvrId) =>
      _delete('technical-visit-reports/$tvrId');
  Future<void> deleteLeaveApplication(String leaveId) =>
      _delete('leave-applications/$leaveId');
  Future<void> deleteSalesOrder(String orderId) =>
      _delete('sales-orders/$orderId');
}
```

-----

## `lib/models/`

### `Purpose`

This directory is the "dictionary" or "schema" for the application's data. Each file defines a Dart class that mirrors a data structure from the backend. Their primary role is to provide **type-safe conversion** to and from JSON.

  * **`fromJson` factory:** This is a constructor that takes a `Map<String, dynamic>` (the raw JSON from the API) and returns a strongly-typed instance of the class (e.g., `Dealer.fromJson(jsonData)`). This is used for *reading* data.
  * **`toJson()` method:** This method converts an instance of the Dart class back into a `Map<String, dynamic>` that can be `jsonEncode`-ed and sent to the API. This is used for *creating* or *updating* data.

This pattern is crucial for preventing runtime errors and making the code clean, as the rest of the app can work with objects (e.g., `myDealer.name`) instead of error-prone maps (`myMap['name']`).

-----

### `models/employee_model.dart`

  * **Purpose:** Represents the logged-in user. This object is fetched once on login and passed to most screens.
  * **Core Logic:**
      * **`displayName` Getter:** This is a computed property, not a database field. It intelligently combines `firstName` and `lastName`. If they are null, it provides sensible fallbacks (`firstName` ?? `lastName` ?? `loginId` ?? 'Employee') to ensure the UI never shows "null".
      * **`fromJson` Factory:** This factory is robust. It's designed to parse the `companyName` whether the JSON has it as a flat property (`"companyName": "..."`) or nested inside another object (`"company": {"companyName": "..."}`). This allows it to be used by both the `login` and `_fetchUserProfile` methods in `api/auth_service.dart`, which return slightly different structures.
      * It also correctly parses the user's `role`, which is critical for any future role-based feature permissions.

-----

### `models/dealer_model.dart`

  * **Purpose:** This is the largest and most complex model in the app. It defines over 50 fields for a single dealer, covering everything from primary contact info to godown (warehouse) details, bank accounts, and document URLs.
  * **Core Logic:**
      * **`fromJson` Factory:** This is built for safety. It uses static helper methods (`_parseDate`, `_parseDouble`, `_parseInt`) to parse data. This `tryParse` logic prevents the app from crashing if the server sends a `null`, an empty string `""`, or a badly formatted value where a number or date is expected.
      * **`toJson()` Method:** This method is used when *creating* a new dealer.
          * It uses a `_nullIfEmpty` helper to convert any empty strings (`""`) into `null`. This is essential for passing backend validation (e.g., Prisma/Zod might reject an empty string `""` for an optional field but will accept `null`).
          * It correctly formats `DateTime` objects as `YYYY-MM-DD` strings (e.g., `.toIso8601String().split('T')[0]`).
          * It intelligently **omits** server-generated fields like `id`, `createdAt`, and `updatedAt` from the JSON payload, as these are only provided by the server *after* creation.

-----

### `models/pjp_model.dart`

  * **Purpose:** Represents a **PJP** (Personal Journey Plan). This is a core workflow object that links a user to a planned visit.
  * **Core Logic:**
      * **`fromJson` Factory:** This method is robustly designed to find the dealer's information. It checks for flat properties (`json['dealerId']`, `json['dealerName']`) and also checks for a nested object (`json['dealer']['id']`, `json['dealer']['name']`). This makes the model compatible with different API endpoints (e.g., a simple list vs. a detailed fetch).
      * **`toJson()` Method:** When creating a new PJP, this correctly formats the `planDate` to `YYYY-MM-DD` and, most importantly, sends the `dealerId`.
      * **`PjpData` Class:** This is a simple container class defined in the *same file*. It is **not** a database model. Its only purpose is to be used by `api_service.dart` to return *two* lists (pending and verified) from a single function call, which the PJP screen then uses to build its UI.

-----

### `models/daily_visit_report_model.dart` (DVR)

  * **Purpose:** Represents the detailed report a user fills out after visiting a *dealer*.
  * **Core Logic:**
      * **`fromJson` Factory:** Uses safe parsing (`double.tryParse`) for all numeric fields (`latitude`, `longitude`, `dealerTotalPotential`, `todayOrderMt`, etc.) to prevent crashes from `null` or badly formatted server data.
      * **`toJson()` Method:** Assembles the map for *creating* a new DVR. It correctly omits server-generated fields (`id`, `createdAt`, `updatedAt`) and sends all data collected from the `create_dvr.dart` form.

-----

### `models/technical_visit_report_model.dart` (TVR)

  * **Purpose:** Represents the report a user fills out after visiting a *site* (e.g., a construction site, not a registered dealer).
  * **Core Logic:**
      * **`fromJson` Factory:** Similar to the DVR, it safely parses all incoming data, including converting `List<dynamic>` from JSON into `List<String>` for fields like `siteVisitBrandInUse`.
      * **`toJson()` Method:** Contains a specific and important data conversion: it sends the `conversionQuantityValue` (a `double?` in Dart) as a string (`conversionQuantityValue?.toString()`). This is a deliberate fix to match a specific backend schema (likely Zod) that expects a numeric value *as a string*.

-----

### `models/geotracking_data_model.dart`

  * **Purpose:** This is a "write-only" model. It represents a *single* snapshot of the user's location and device status during a journey.
  * **Core Logic:**
      * It has **no `fromJson` factory** because the app *only ever sends* this data to the server; it never reads it back in this format.
      * **`toJson()` Method:** This is the only logic. It converts all `double` values (like `latitude`, `longitude`, `accuracy`, `speed`, `totalDistanceTravelled`) into `String`s using `toString()` or `toStringAsFixed()`. This is done to preserve precision and match the backend's schema, which expects numeric strings.

-----

### `models/attendance_model.dart`

  * **Purpose:** This is a "read-only" model. It represents a single day's attendance record (check-in/out times).
  * **Core Logic:**
      * It has **no `toJson` method**.
      * This is the opposite of the `GeoTrackingPoint` model. The app *reads* lists of attendance data to display history, but it *creates* attendance records via the complex, multi-step workflow in `api_service.dart` (`checkIn` and `checkOut` methods). The app never needs to convert a local `Attendance` object back to JSON.

-----

### Other Models

  * **`daily_task_model.dart`:** A standard model for a task. `toJson` sends the data required to create a new task, linking `userId`, `pjpId`, `relatedDealerId`, etc..
  * **`leave_application_model.dart`:** A standard model for a leave request. Its `toJson` method correctly sends the `status` as "Pending" and omits server-handled fields like `id` and `adminRemarks`.
  * **`competition_report_model.dart`:** A standard model for a competition report. Its `toJson` method converts `avgSchemeCost` (a `double`) into a `string`, handling the data type conversion so the form code doesn't have to.
  * **`sales_order_model.dart`:** A simple model for a sales order, likely used by the AI chatbot.
  * **`brand_model.dart` & `brand_mapping_model.dart`:** Simple lookup/join models, likely for future features like "Brand Mapping" (seen on the Profile screen).

-----

## `lib/widgets/`

#### `Purpose`

This directory contains reusable UI components and the core application theme logic. It controls the app's visual identity (colors, fonts, styles) and manages theme state.

### `lib/widgets/app_theme.dart`

#### `Purpose`

This file is the app's visual style guide. It defines all colors, fonts, and component styles for both Light and Dark modes.

#### `Core Logic`

1.  **Colors:** Defines `static const` brand colors (e.g., `primaryBlue`, `primaryOrange`, `darkBackground`).
2.  **`lightTheme`:** A `static final ThemeData` object that defines the light mode. It sets the `scaffoldBackgroundColor` to `lightBackground`, the `primary` color to `primaryOrange`, and `onPrimary` to `Colors.black` for high contrast.
3.  **`darkTheme`:** A `static final ThemeData` object for dark mode. It sets the `scaffoldBackgroundColor` to `darkBackground`, `surface` (card color) to `darkCard`, and the `primary` color to a "calmer" `Color(0xFF0A3A8A)`.
4.  **Component Themes:** Both `lightTheme` and `darkTheme` provide default themes for common widgets like `cardTheme` (setting `elevation: 0` and `borderRadius: 16`), `appBarTheme`, `bottomNavigationBarTheme`, and `elevatedButtonTheme` (making all buttons orange by default). This ensures visual consistency everywhere.

-----

### `lib/widgets/theme_provider.dart`

#### `Purpose`

This is the **state manager** for the app's theme. It allows the user to change the theme and persists their choice.

#### `Core Logic`

1.  **State:** It extends `ChangeNotifier` and holds one piece of state: `ThemeMode _themeMode`, which defaults to `ThemeMode.system`.
2.  **Persistence (Load):** In its constructor, it calls `_loadThemeMode()`. This `async` function uses `SharedPreferences` to read a saved string ('light', 'dark', or 'system') and sets the `_themeMode` state accordingly.
3.  **Persistence (Save):** The public `setThemeMode(ThemeMode mode)` function is called by the UI (the `SegmentedButton` in `employee_profile_screen.dart`).
      * It updates the `_themeMode` state.
      * It immediately calls `notifyListeners()`. `main.dart` is listening for this and rebuilds the `MaterialApp` with the new `themeMode`.
      * It *asynchronously* saves the new choice (e.g., `'dark'`) to `SharedPreferences` for the next app launch.

-----

### `lib/widgets/reusableglasscard.dart`

#### `Purpose`

A **deprecated** custom widget that was used to create a "frosted glass" or "glassmorphism" effect.

#### `Core Logic`

  * It used a `BackdropFilter` with `ImageFilter.blur` to blur the content behind it.
  * It layered this with a semi-transparent `Material` color and a faint border to complete the effect.
  * This has been **removed** from use in `nav_screen.dart` and `employee_pjp_screen.dart` and replaced with the standard `Card` widget, which respects the app's new `app_theme.dart`.

-----

## `lib/screens/`

### `Purpose`

This directory contains all the main user-facing screens of the application, organized into subfolders by feature. It represents the **View** and **Controller** layers of the app, containing the UI widgets and the state management logic that drives them.

-----

### `lib/screens/nav_screen.dart`

#### `Purpose`

This is the most important **container** screen in the authenticated part of the app. It acts as the main "shell" or "scaffold" that holds the 5 primary tabs and the quick-action drawer. It is the screen the user lands on after a successful login.

#### `Core Logic`

1.  **State Management:** It uses `ChangeNotifierProvider.value` to provide a `NavProvider` instance to its children. This `NavProvider` is a simple state class (defined in the same file) that manages the `_selectedIndex` (which tab is currently active) and `_journeyData` (the destination data for a new journey).
2.  **UI Structure:** The `Scaffold` body is a `Stack`.
      * The bottom layer is an `IndexedStack`, which efficiently holds the list of 5 main page widgets (`EmployeeDashboardScreen`, `EmployeePJPScreen`, etc.) and only shows the one at `provider.selectedIndex`.
      * The top layer is a `Positioned` widget at the bottom of the screen. This contains the `_buildFloatingNavBar` method, which renders a `Card` wrapping a `BottomNavigationBar`. This is a clever UI trick to create the "floating" rounded-corner navigation bar that sits *above* the main content.
3.  **Journey Initiation (Cross-Screen Communication):** This screen is the central hub for starting a journey. It passes the `provider.startJourney` function as a callback *down* to the `EmployeePJPScreen`.
      * When a user swipes and taps "Start Journey" in the `EmployeePJPScreen`, that screen calls this callback.
      * The `NavProvider`'s `startJourney` method is executed, which sets its internal `_journeyData` and forcefully changes the `_selectedIndex` to 3 (the "Journey" tab).
      * This causes the `Consumer<NavProvider>` to rebuild, and the `IndexedStack` instantly switches to show the `EmployeeJourneyScreen`, passing it the new `initialJourneyData`.
4.  **Quick Actions (Drawer):** The `Scaffold`'s `drawer` is built by `_buildDrawer`. This renders a `UserAccountsDrawerHeader` with the employee's name and email, followed by a list of `_buildDrawerActionItem` widgets (e.g., "ADD DEALER," "CREATE DVR," "APPLY FOR LEAVE").
5.  **Form Dialogs:** Each `_buildDrawerActionItem` has an `onTap` that first calls `Navigator.pop(context)` (to close the drawer) and then calls a specific `_show...Dialog` function (e.g., `_showAddDealerDialog`, `_showCreateDvrDialog`). These functions are responsible for showing the various form widgets from the `lib/screens/forms/` directory as modal `Dialog`s.

-----

#### `Paste-Ready Code: lib/screens/nav_screen.dart`

```dart
// lib/navscreen.dart
import 'dart:ui'; // We still need this for the dialog's blur
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:assetarchiverflutter/screens/employee_management/employee_dashboard_screen.dart';
import 'package:assetarchiverflutter/screens/employee_management/employee_profile_screen.dart';
import 'package:assetarchiverflutter/screens/employee_management/employee_pjp_screen.dart';
import 'package:assetarchiverflutter/screens/employee_management/employee_journey_screen.dart';
import 'package:assetarchiverflutter/screens/employee_management/employee_salesorder_screen.dart';
// import 'package:assetarchiverflutter/widgets/reusableglasscard.dart'; // <-- 1. REMOVED
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:assetarchiverflutter/screens/forms/create_dvr.dart';
import 'package:assetarchiverflutter/screens/forms/create_tvr.dart';
import 'package:assetarchiverflutter/screens/forms/create_leave_form.dart';
import 'package:assetarchiverflutter/screens/forms/create_competition_form.dart';
import 'package:assetarchiverflutter/screens/forms/create_daily_task_form.dart';
import 'package:assetarchiverflutter/screens/forms/add_dealer_form.dart';
// No theme provider import is needed here

// --- (NavProvider class remains exactly the same) ---
class NavProvider with ChangeNotifier {
  int _selectedIndex = 0;
  Map<String, dynamic>? _journeyData;

  int get selectedIndex => _selectedIndex;
  Map<String, dynamic>? get journeyData => _journeyData;

  void changePage(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  void startJourney(Map<String, dynamic> data) {
    _journeyData = data;
    _selectedIndex = 3;
    notifyListeners();
  }

  void clearJourneyData() {
    _journeyData = null;
    notifyListeners();
  }

  void refreshDashboard() {
    debugPrint("Refreshing Dashboard...");
  }

  void refreshPjpList() {
    debugPrint("Refreshing PJP List...");
  }
}

class NavScreen extends StatefulWidget {
  final Employee employee;
  const NavScreen({super.key, required this.employee});

  @override
  State<NavScreen> createState() => _NavScreenState();
}

class _NavScreenState extends State<NavScreen> {
  late final NavProvider _navProvider;
  final GlobalKey<EmployeeDashboardScreenState> _dashboardKey =
      GlobalKey<EmployeeDashboardScreenState>();

  @override
  void initState() {
    super.initState();
    _navProvider = NavProvider();
  }

  @override
  void dispose() {
    _navProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- 2. REMOVED all the 'isDarkMode' and 'glassColor' logic ---

    return ChangeNotifierProvider.value(
      value: _navProvider,
      child: Consumer<NavProvider>(
        builder: (context, provider, child) {
          final pageTitles = [
            'Home',
            'PJP',
            'Sales Order',
            'Journey',
            'Profile',
          ];

          final pages = <Widget>[
            EmployeeDashboardScreen(
              key: _dashboardKey,
              employee: widget.employee,
            ),
            EmployeePJPScreen(
              employee: widget.employee,
              onStartJourney: provider.startJourney,
              onPjpCreated: () {
                _dashboardKey.currentState?.refreshData();
                provider.refreshDashboard();
              },
            ),
            SalesOrderScreen(employee: widget.employee),
            EmployeeJourneyScreen(
              initialJourneyData: provider.journeyData,
              employee: widget.employee,
              onDestinationConsumed: provider.clearJourneyData,
            ),
            EmployeeProfileScreen(employee: widget.employee),
          ];

          return Scaffold(
            // --- 3. This is now a standard, theme-aware AppBar ---
            // It will get its color/style from app_theme.dart
            appBar: AppBar(
              title: Text(pageTitles[provider.selectedIndex]),
            ),
            
            // --- 4. The drawer is now standard ---
            drawer: _buildDrawer(context, widget.employee),
            
            // --- ✅ THEME FIX: Rebuilt the Scaffold Body ---
            // This Stack is how we make the nav bar float
            body: Stack(
              children: [
                IndexedStack(index: provider.selectedIndex, children: pages),
                
                // This is the floating nav bar
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildFloatingNavBar(context, provider),
                ),
              ],
            ),
            // We set this to null because it's now part of the body Stack
            bottomNavigationBar: null,
            // --- END FIX ---
          );
        },
      ),
    );
  }

  // --- ✅ NEW: Floating, Rounded Nav Bar ---
  // This widget creates the "floating" bar from your screenshot
  Widget _buildFloatingNavBar(BuildContext context, NavProvider provider) {
    final theme = Theme.of(context);
    
    return Card(
      // This margin makes it "float"
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 24), 
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0), // Rounded corners
      ),
      clipBehavior: Clip.antiAlias, // This cuts the corners
      child: BottomNavigationBar(
        // We make the bar transparent so the Card's color (from the theme) shows
        backgroundColor: Colors.transparent,
        elevation: 0, 
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.checklist_rtl), label: 'PJP'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Sales Order'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Journey'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: provider.selectedIndex,
        onTap: (index) {
          if (index == 0) provider.refreshDashboard();
          if (index == 1) provider.refreshPjpList();
          provider.changePage(index);
        },
        // All styling (colors, labels) now comes from app_theme.dart
        // (including the `show...Labels: true` fix we just made)
      ),
    );
  }
  // --- END NEW ---

  // --- (All dialog functions remain the same) ---
  void _showAddDealerDialog(BuildContext context, Employee employee) {
    print('>>> _showAddDealerDialog called in nav_screen.dart. Trying to show AddDealerForm...');
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color.fromARGB(184, 193, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
        child: AddDealerForm(employee: employee),
      ),
    );
  }
   void _showCreateDvrDialog(BuildContext context, Employee employee) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color.fromARGB(0, 140, 6, 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
        child: CreateDvrScreen(employee: employee),
      ),
    );
  }

  void _showCreateTvrDialog(BuildContext context, Employee employee) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: CreateTvrScreen(employee: employee),
      ),
    );
  }

  void _showApplyForLeaveDialog(BuildContext context, Employee employee) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: CreateLeaveFormScreen(employee: employee),
      ),
    );
  }

  void _showCompetitionFormDialog(BuildContext context, Employee employee) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: CreateCompetitionFormScreen(employee: employee),
      ),
    );
  }

  void _showCreateDailyTaskDialog(BuildContext context, Employee employee) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: CreateDailyTaskScreen(employee: employee),
      ),
    );
  }


  // --- ✅ NEW: Prettier, Themed Drawer ---
  // This replaces your old _buildGlassDrawer with a standard,
  // professional-looking UserAccountsDrawerHeader.
  Widget _buildDrawer(BuildContext context, Employee employee) {
    // Get all text styles directly from the theme
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Drawer(
      // The background color is now controlled by your theme
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // This is a much cleaner, standard header that matches your screenshot
          UserAccountsDrawerHeader(
            accountName: Text(
              employee.displayName,
              style: textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(
              employee.email ?? '',
              style: textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimary.withOpacity(0.8),
              ),
            ),
            // This pulls the blue from your "Good Morning" card
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
            ),
            // You can add a CircleAvatar here if you have a user image
            // currentAccountPicture: CircleAvatar(
            //   backgroundColor: theme.colorScheme.background,
            //   child: Text(
            //     "RH", // You'd getInitials() here
            //     style: TextStyle(color: theme.colorScheme.primary),
            //   ),
            // ),
          ),
          _buildDrawerActionItem(
              context,
              icon: Icons.person_add_alt,
              text: 'ADD DEALER',
              onTap: () {
                 print('>>> ADD DEALALER button tapped!');
                 Navigator.pop(context);
                 _showAddDealerDialog(context, employee);
              }
            ),
            _buildDrawerActionItem(
              context,
              icon: Icons.description_outlined,
              text: 'CREATE DVR',
              onTap: () {
                Navigator.pop(context);
                // --- ✅ BUG FIX: Removed stray print statement ---
                _showCreateDvrDialog(context, employee);
              }
            ),
            _buildDrawerActionItem(
              context,
              icon: Icons.description,
              text: 'CREATE TVR',
               onTap: () {
                Navigator.pop(context);
                _showCreateTvrDialog(context, employee);
              }
            ),
            _buildDrawerActionItem(
              context,
              icon: Icons.assessment_outlined,
              text: 'COMPETETION FORM',
              onTap: () {
                Navigator.pop(context);
                _showCompetitionFormDialog(context, employee);
              }
            ),
            _buildDrawerActionItem(
              context,
              icon: Icons.account_box_sharp,
              text: 'APPLY FOR LEAVE',
              onTap: () {
                Navigator.pop(context);
                _showApplyForLeaveDialog(context, employee);
              }
            ),
            _buildDrawerActionItem(
              context,
              icon: Icons.task_alt,
              text: 'CREATE DAILY TASK',
              onTap: () {
                Navigator.pop(context);
                _showCreateDailyTaskDialog(context, employee);
              }
            ),
        ],
      ),
    );
  }

  // --- This widget is now fully theme-aware ---
  Widget _buildDrawerActionItem(
    BuildContext context, {
    required IconData icon,
    required String text,
    VoidCallback? onTap,
  }) {
    // Get colors directly from the theme
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.onSurface.withOpacity(0.7);
    final textColor = theme.colorScheme.onSurface;

    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(text, style: TextStyle(color: textColor)),
      onTap: onTap,
    );
  }
}
```

-----

### `lib/screens/auth/login_screen.dart`

#### `Purpose`

This is the app's entry point for all unauthenticated users. It's a `StatefulWidget` that manages user input, loading states, and error messages for the login process.

#### `Core Logic`

1.  **State:** It manages three key pieces of local state: `_isLoading` (a boolean to show/hide a `CircularProgressIndicator`), `_errorMessage` (a `String?` to display login errors), and the `TextEditingController`s for the two `TextField`s.
2.  **UI:** The UI features a `BackdropFilter` with `ImageFilter.blur` to create a "frosted glass" login card over a gradient background. It uses the `flutter_animate` package for a simple fade-in and scale animation on the card.
3.  **`_handleLogin` Function:** This `async` function is the core logic, triggered when the "Continue" button is pressed.
      * It performs basic local validation to ensure the fields are not empty.
      * It sets `_isLoading = true` and `_errorMessage = null` to update the UI.
      * It calls `await AuthService().login(loginId, password)`, passing the credentials to the API layer.
      * **Success Handling:** If the `AuthService.login` call succeeds, it returns a complete `Employee` object. The app then uses `Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false, arguments: employee)`. This navigates to the `NavScreen` (defined as '/home' in `main.dart`) and *clears the entire navigation stack*, which is a critical step to prevent the user from pressing the "back" button to return to the login screen.
      * **Error Handling:** A `catch (e)` block traps any exceptions thrown by `AuthService` (e.g., "Invalid credentials" or "Server is taking too long"). It sets `_isLoading = false` and updates the `_errorMessage` state with the error message, displaying it to the user in a `Text` widget.

-----

### `lib/screens/employee_management/`

#### `Purpose`

This directory holds the five core, full-page screens that are displayed in the `NavScreen`'s `IndexedStack`. These represent the main features of the app.

#### `lib/screens/employee_management/employee_dashboard_screen.dart` (Home Tab)

  * **Purpose:** The "Home" tab (index 0). It serves as the user's daily landing page for attendance and a high-level overview of their day.
  * **Core Logic:**
    1.  **Attendance Workflow (`_handleCheckIn` / `_handleCheckOut`):** This is the screen's main feature. Both functions follow a
        strict, sequential process:
        1.  `_getCurrentPosition()`: Uses the `geolocator` package to get the device's precise GPS coordinates. This function also handles all permission requests (checking if services are enabled, if permission is `denied`, etc.).
        2.  `_captureImage()`: Uses the `image_picker` package to open the camera, specifically requesting the `CameraDevice.front` (selfie camera).
        3.  `_apiService.uploadImageToR2(imageFile)`: Uploads the captured `File` to the backend's R2 storage.
        4.  `_apiService.checkIn(checkInData)` / `checkOut(checkOutData)`: Only after the image is successfully uploaded, it sends the final attendance record (including `userId`, `attendanceDate`, lat/lon, and the `imageUrl`) to the API.
    2.  **PJP Overview:** The screen uses a `FutureBuilder` tied to `_pjpFuture`. This future is initialized in `refreshData()` (which is called on `initState` and `didChangeAppLifecycleState`) to call `_apiService.fetchPjpsForUser(...)` with a `status: 'pending'`. The `FutureBuilder` then renders a `Card` summarizing the number of pending PJPs for the day.
    3.  **Lifecycle Management:** The widget uses `WidgetsBindingObserver` to listen for app lifecycle events. When the app `resumed` (e.g., the user brings it back from the background), it automatically calls `refreshData()` to ensure the PJP list is up-to-date.

-----

You got it. Here is that exact section from your `WORKING.MD` file, **updated** to reflect the major refactoring we just did (breaking the file into four separate, encapsulated files).

Just replace the old section with this new one.

---

#### `lib/screens/employee_management/employee_pjp_screen.dart` (PJP Tab)

* **Purpose:** The "PJP" tab (index 1). It allows the user to view, create (singly or in bulk), and *start* their Personal Journey Plans.
* **Core Logic (REFACTORED):**
    1.  **Encapsulation (NEW):** This file is now a clean "container" screen. All complex UI and logic have been **moved** to separate, dedicated files to improve management and readability.
    2.  **List PJPs:** The main body is a `FutureBuilder` that awaits `_pjpDataFuture`. This future is populated by `_apiService.fetchPendingAndVerifiedPjps(userId: int.parse(widget.employee.id))`. This API call returns a `PjpData` object containing two separate lists: `pendingPjps` and `verifiedPjps`.
    3.  **UI (Refactored):** The `ListView.builder` now gets its UI from imported widgets (`PjpCard`, `PendingPjpSummaryCard`, `PjpSectionHeader`) located in the new **`lib/widgets/pjp_cards.dart`** file. The `PjpCard` itself has been fixed to get the dealer's name from the `pjp.areaToBeVisited` string, as the `pjp.dealer` object no longer exists on that model.
    4.  **Start Journey (Swipe Action):** Each "Verified" PJP `PjpCard` is wrapped in a `Slidable` widget. Swiping reveals a `SlidableAction` button labeled "Start Journey".
    5.  **`_startJourneyForPjp(Pjp pjp)`:** This function is the "start" trigger.
        * It parses the PJP's destination, which is stored in the `areaToBeVisited` string in a "Name|Latitude|Longitude" format.
        * It calls `await _apiService.updatePjp(pjp.id, {'status': 'started'})` to notify the backend.
        * Critically, it then calls `widget.onStartJourney(...)`. This function was passed down from `nav_screen.dart`. It sends a map of the journey data (the `pjpId`, `displayName`, and `LatLng` destination) *up* to the `NavProvider`, which triggers the app to automatically switch to the "Journey" tab.
    6.  **Create PJP (Refactored):** A `FloatingActionButton` on this screen calls `_showPjpOptions`. This modal now gives a choice:
        * **"Add Single Visit"**: Calls `_showAddPjpForm`, which now opens the **`lib/screens/forms/add_pjp_form.dart`** widget in a modal bottom sheet.
        * **"Create Bulk Monthly Plan"**: Calls `_showBulkPjpWizard`, which now navigates (`MaterialPageRoute`) to the new **`lib/screens/employee_management/bulk_pjp_wizard_screen.dart`** file.

#### `lib/screens/employee_management/employee_salesorder_screen.dart` (Sales Order Tab)

  * **Purpose:** The "Sales Order" tab (index 2). It's a fully functional, self-contained AI-powered chatbot ("CemTemBot") for helping the user create sales orders.
  * **Core Logic:**
    1.  **WebSocket Connection:** This screen does *not* use HTTP. It uses the `socket_io_client` package to open a persistent WebSocket connection to a separate Python AI server (`https://python-ai-agent.onrender.com`).
    2.  **Event Listeners:** In `_connectToSocket`, it sets up listeners for key events:
          * `onConnect` / `onDisconnect`: Updates a `_isConnected` boolean to show a "Connected" / "Disconnected" status banner.
          * `on('status')`: Listens for typing indicators from the bot (e.g., `{'typing': true}`) and sets an `_isLoading` boolean, which shows/hides the `_TypingIndicator` widget.
          * `on('bot_message')`: This is the main listener. When the bot sends a message (e.g., `{'text': 'Hello!'}`), this fires, and the app calls `_addMessage` to display the bot's response.
    3.  **Local Persistence (Hive):** This screen is designed to be local-first.
          * The `ChatMessage` class is defined in this file as a `HiveObject` with `@HiveType(typeId: 0)`.
          * `employee_salesorder_screen.g.dart` is the **auto-generated** `TypeAdapter` that `hive_generator` creates. It contains the low-level code to read/write `ChatMessage` objects to binary disk storage.
          * `_initializeChat` opens a `Box<ChatMessage>` named 'sales\_order\_chat' and loads all existing messages into the `_messages` list state.
          * `_addMessage` (called by both user and bot) calls `_chatBox.add(message)` to save the new `ChatMessage` to the local database *before* updating the UI state.
    4.  **Sending Messages:** The `_handleSubmitted` function (triggered by the send button) calls `_addMessage` to save the user's message locally and *then* emits a `send_message` event over the socket to the bot.

-----

#### `lib/screens/employee_management/employee_journey_screen.dart` (Journey Tab)

  * **Purpose:** The "Journey" tab (index 3). This is the most complex screen in the app, providing a live map, route drawing, and real-time location tracking.
  * **Core Logic:**
    1.  **Initialization:** `initState` calls `_initializeFirstTime`, which first gets a single location fix to move the map camera (`_determinePositionAndMoveCamera`) and then, crucially, subscribes to the *continuous* location stream via `_startLocationStream`. It also initializes the `Radar` SDK with the user's ID.
    2.  **Receiving a Journey:** The `didUpdateWidget` lifecycle method is vital. It detects when `widget.initialJourneyData` changes (which happens when the user starts a journey from the PJP screen). When it detects new data, it calls `_processNewJourneyData` to set the `_destinationLocation`, store the `_currentPjpId`, and call `_getDirectionsAndDrawRoute` to fetch the blue "suggested route" polyline from the Radar API.
    3.  **Live Tracking (`_onPositionUpdate`):** This function is the "heart" of the tracking. It's the listener for `Geolocator.getPositionStream()` (set to `accuracy: LocationAccuracy.best` and `distanceFilter: 1`) and runs *every time* the device's GPS reports a new position.
          * It *always* updates the user's "blue dot" on the map by calling `_drawUserLocationPointer`.
          * **If `_isJourneyActive` is true**, it performs **local distance calculation**:
              * It calculates `Geolocator.distanceBetween` the new position and the `_lastRecordedPosition`.
              * If the movement is \> 2 meters (to filter GPS jitter), it adds this distance to `_totalDistanceTravelled`.
              * It updates the `_originController` text to show "Distance: X.XX km".
              * It adds the new coordinate to the `_routeTaken` list and calls `_updateTravelledPolyline` to draw the red "actual path" line.
    4.  **Arrival Detection (Radar):** This is a *separate, parallel* system.
          * `_startJourney` creates a `Timer` (`_radarArrivalCheckTimer`) that calls `_performRadarArrivalCheck` every 30 seconds.
          * `_performRadarArrivalCheck` calls `Radar.trackOnce()`.
          * A persistent listener (`_setupRadarListeners`) listens for Radar events. If it receives a `user.entered_geofence` event and the `geofence.externalId` matches the `_currentPjpId`, it triggers `_showDestinationArrivalNotification`.
    5.  **Lifecycle (Foreground Service):**
          * `_startJourney`: Calls `_showTrackingNotification()`. This `flutter_local_notifications` call has `ongoing: true`, which turns it into a **foreground service notification**, making it much harder for the OS to kill the app in the background. It also starts the `_radarArrivalCheckTimer`.
          * `_stopJourney`: Called by the `SlideAction` or by Radar arrival. It cancels the timer, cancels the notification (`_cancelTrackingNotification`), sets `_isJourneyActive = false`, and—most importantly—sends **one final** `GeoTrackingPoint` (with `isActive: false` and the final `_totalDistanceTravelled`) to the API using `_apiService.sendGeoTrackingPoint`. It also updates the PJP status to "completed" via `_apiService.updatePjp`.
    6.  **External Navigation:** A "NAVIGATE" button provides an "escape hatch" for users who prefer Google Maps. It uses `url_launcher` to open the Google Maps app with the destination pre-filled (`google.navigation:q=lat,lng`).

-----

#### `lib/screens/employee_management/employee_profile_screen.dart` (Profile Tab)

  * **Purpose:** The "Profile" tab (index 4). It displays user information, performance statistics, and app-level settings like theme and logout.
  * **Core Logic:**
    1.  **Statistics (`_fetchProfileStats`):** This function is called on `initState` and by the `RefreshIndicator` (`_refreshStats`). It uses `Future.wait` to make several API calls in parallel to fetch data for the *current month* (e.g., `_apiService.fetchDvrsForUser`, `_apiService.fetchPjpsForUser`) and all-time data (`_apiService.fetchDealers`). It aggregates the counts into a `_ProfileStats` helper class. A `FutureBuilder` then displays this data in `_StatCard` widgets.
    2.  **Chart:** The fetched `stats` are passed to a `_PerformanceChart` widget, which uses the `fl_chart` package to render a `BarChart` comparing "Reports" (`reportCount`) vs. "PJPs" (`pjpCount`) for the month.
    3.  **Dealer Management:** A "Manage Dealers" `_StatCard` has an `onTap` handler (`_showManageDealersSheet`) that displays a `DraggableScrollableSheet`. This sheet contains a `_ManageDealersContent` widget, which lists all dealers and provides an `onTap` (`_showDealerActions`) to edit or delete them (by calling `_apiService.deleteDealer`).
    4.  **Theme Switching:** This is a key app setting.
          * It gets the `ThemeProvider` via `Provider.of<ThemeProvider>(context)`.
          * It renders a `SegmentedButton` for "Light," "Dark," and "System" modes.
          * The `onSelectionChanged` callback for this button calls `themeProvider.setThemeMode(newSelection.first)`. This tells the `ThemeProvider` to update its state, which in turn notifies `main.dart` to rebuild the *entire* `MaterialApp` with the new theme.
    5.  **Logout:** A `_LogoutButton` widget calls `AuthService().logout()` to delete the token from secure storage and then uses `Navigator.of(context).pushNamedAndRemoveUntil('/login', ...)` to send the user back to the login screen, clearing the navigation history.

-----

### `lib/screens/forms/`

#### `Purpose`

This directory holds all the pop-up data entry forms. These are all `StatefulWidget`s designed to be shown as modal `Dialog`s from the `NavScreen`'s drawer. They all use a `BackdropFilter` with `ImageFilter.blur` for a "frosted glass" UI.

#### `lib/screens/forms/add_dealer_form.dart`

  * **Purpose:** The most complex form in the app, used to register a new dealer with 50+ fields.
  * **Core Logic:**
    1.  **Location First:** The form's primary action is a large "Get Current Location & Address" button. This calls `_fetchLocationAndAddress`, which uses `geolocator` to get a `Position` and `_apiService.reverseGeocodeWithRadar` to get a human-readable address. This *auto-fills* the read-only main address fields, as well as the Godown and Residential address fields, to save the user time.
    2.  **Address Autocomplete:** For the Godown and Residential sections, the address `TextFormField`s (`_godownAddressLineController`, `_resAddressLineController`) have `onChanged` listeners. These listeners use a `Timer` (debounce) to call `_apiService.searchPhotonAddress`. A `ListView` of suggestions is shown below the `TextFormField`. Tapping a suggestion (`_onGodownSuggestionTapped`) populates all the relevant address fields (landmark, district, city, etc.).
    3.  **Conditional UI:** A `SwitchListTile` toggles an `_isSubDealer` boolean. When `true`, the UI rebuilds to show a `DropdownButtonFormField` populated with "Parent Dealers" (fetched in `_fetchParentDealers`).
    4.  **UI Organization:** The many fields are organized into collapsible `ExpansionTile` widgets (`_buildSection`) for "Primary Details," "Identification," "Godown," "Bank," etc., to keep the UI manageable.
    5.  **Submission (`_submitForm`):** It runs `_formKey.currentState!.validate()` and checks that `_currentPosition != null`. It then gathers data from all 50+ `TextEditingController`s (using `_text`, `_int`, `_double` helpers for safe parsing), constructs a massive `Dealer` object, and sends it to `_apiService.createDealer(newDealer, radius: ...)`.

-----

#### `lib/screens/forms/create_dvr.dart` (Daily Visit Report)

  * **Purpose:** A form for reporting a visit to a *dealer*. It enforces a strict check-in/check-out workflow.
  * **Core Logic:**
    1.  **Step 1: Check-In.** The form first *only* shows a `DropdownButtonFormField` to select a `Dealer` (populated by `_fetchDealersForDropdown`). When a dealer is selected, `_onDealerSelected` auto-fills data from the `Dealer` object. The user *must* then press "CHECK-IN WITH PHOTO." This calls `_handleCheckIn`, which captures/uploads a photo and saves `_checkInTime` and `_inTimeImageUrl` to the widget's state.
    2.  **Step 2: Fill Form.** Once `_checkInTime != null`, the UI rebuilds. The dropdown is replaced by a `ListTile` confirming the check-in, and the full report form (order amount, collection, feedbacks) becomes visible.
    3.  **Step 3: Submit (`_submitDvr`).** This is triggered by the "SUBMIT & CHECK-OUT" button.
          * It forces the user to take a *second* (check-out) photo and uploads it.
          * **Location Verification:** This is the key logic. It gets the user's *current* GPS location (`Geolocator.getCurrentPosition`) and compares it to the `_selectedDealer!.latitude/longitude` using `Geolocator.distanceBetween`. If the distance is `> 200` meters, it `throw`s an `Exception` and *stops the submission*, warning the user they are too far away.
          * If valid, it builds the `DailyVisitReport` object and calls `_apiService.createDvr`.

-----

#### `lib/screens/forms/create_tvr.dart` (Technical Visit Report)

  * **Purpose:** A form for reporting a visit to a *site* (e.g., a construction site, not a registered dealer). It also has a two-step workflow.
  * **Core Logic:**
    1.  **Step 1: Check-In.** Simpler than the DVR. The user just fills in the `_siteNameConcernedPersonController` and `_phoneNoController`, which are validated.
    2.  **`_handleCheckIn`:** The "CHECK-IN WITH PHOTO & LOCATION" button captures/uploads a photo *and* captures the user's `Position`, saving it to the `_capturedLocation` state variable.
    3.  **Step 2: Fill Form.** The UI rebuilds to show the full TVR form (visit type, client remarks, etc.).
    4.  **Step 3: Submit (`_submitTvr`).**
          * It forces a check-out photo and uploads it.
          * **Location Prepending:** This is the key logic. It takes the `_capturedLocation` (from Step 1), formats it as a string `"[Site Location: lat, lon]"`, and prepends it to the `_salespersonRemarksController.text`. This permanently embeds the site's location into the report.
          * It then builds the `TechnicalVisitReport` object (using `double.tryParse` for optional number fields) and calls `_apiService.createTvr`.

-----

#### `lib/screens/forms/create_daily_task_form.dart`

  * **Purpose:** A form for the user to create an ad-hoc task for themselves, with smart integration into PJPs.
  * **Core Logic:**
    1.  **Conditional UI:** The UI changes based on the `_selectedVisitType` dropdown. If "Site Visit" is selected, a `TextFormField` for "Site Name" appears. If "Dealer Visit" is selected, the PJP dropdown appears.
    2.  **PJP Integration:** If "Dealer Visit" is selected, the UI shows a `FutureBuilder`. This future (`_pjpFuture`) calls `_apiService.fetchPjpsForUser` for *today's pending PJPs*. This populates a dropdown, allowing the user to *link* this new task to an existing PJP.
    3.  **PJP Creation:** A "Create New PJP if not listed" button calls `_showAddPjpFormAndRefresh`. This function opens the `AddPjpForm` (from `employee_pjp_screen.dart`) in a modal. When that form is closed, its callback `_fetchTodaysPjps` to refresh the PJP dropdown *within this form*.
    4.  **Submission:** `_submitForm` builds a `DailyTask` object (linking `pjpId` or `siteName` as needed) and calls `_apiService.createDailyTask`.

-----

#### `lib/screens/forms/create_leave_form.dart`

  * **Purpose:** A simple form for an employee to request time off.
  * **Core Logic:**
    1.  **Date Pickers:** It uses two `TextFormField`s (`_startDateController`, `_endDateController`) that are `readOnly: true`. An `onTap` gesture on them calls `_selectDate`, which shows a `showDatePicker`.
    2.  **Date Validation:** The `_selectDate` logic is smart. When picking an *end date*, it sets the `firstDate` in the picker to be the `_startDate` (or `now` if `_startDate` is null), preventing the user from selecting an end date that is before the start date.
    3.  **Submission:** `_submitLeaveApplication` validates the form, builds a `LeaveApplication` object (with `status: 'Pending'`), and calls `_apiService.createLeaveApplication`.

-----

#### `lib/screens/forms/create_competition_form.dart`

  * **Purpose:** A straightforward form for reporting on competitor activity.
  * **Core Logic:**
    1.  This is a standard `Form` widget with `TextFormField`s (for brand name, billing, etc.) and a `DropdownButtonFormField` (for "Schemes Yes/No").
    2.  **Submission:** `_submitForm` validates the controllers, parses the `_avgSchemeCostController.text` to a `double`, bundles all the data into a `CompetitionReport` object, and calls `_apiService.createCompetitionReport`.



    1(recent CHANGES):
    Your instinct is perfect: we need encapsulation. We will break that massive file apart into logical, reusable pieces.

Here is the plan:

lib/screens/employee_management/employee_pjp_screen.dart (The Screen): This file will be much smaller. It will only be responsible for the Scaffold, the FutureBuilder, and the ListView.

lib/widgets/pjp_cards.dart (New File): We will move all the small, reusable UI widgets (_PjpCard, _PendingPjpSummaryCard, _PjpSectionHeader) into their own file.

lib/screens/forms/add_pjp_form.dart (New File): The AddPjpForm is a complex widget. It does not belong in the screen file. We will move it to your forms directory, just like your other forms.

lib/screens/employee_management/bulk_pjp_wizard_screen.dart (New File): The BulkPjpWizardScreen is a full-page feature. It absolutely needs its own file.

This will make your code so much cleaner and easier to work on.

Here are the new, refactored files.

changes(2):
No problem! We've made a lot of great progress and fixed several key bugs.

Here is a list of all the changes we've made so far:

1. lib/api/api_service.dart (The "Vanishing PJPs" Fix)
Problem: You approved PJPs in the admin panel (changing their status to "APPROVED"), but they were "vanishing" from the app.

Fix: We discovered the app was incorrectly asking the API for PJPs with a status of 'VERIFIED'. We changed this to 'APPROVED' in the fetchPendingAndVerifiedPjps function, so the app now asks for the correct status and your approved PJPs will appear.

2. lib/screens/nav_screen.dart (The "App Shell" Fixes)
Problem 1: The app wouldn't refresh your PJP list when you tapped the PJP tab icon.

Fix 1: We added a GlobalKey to the EmployeePJPScreen, just like you had for the dashboard. Now, tapping the PJP icon in the bottom nav bar forces that screen to refresh its data.

Problem 2: The pop-up forms (like "Add Dealer" and "Create DVR") had an ugly, hard-coded red background.

Fix 2: We updated those dialogs to use your app's built-in theme color (colorScheme.surface), so they now look clean, professional, and match the rest of your app's design.

3. lib/screens/employee_management/employee_pjp_screen.dart (The "List Logic" Fix)
Problem: Your "PENDING" PJPs were showing up with a "VERIFIED" green checkmark, and the "PENDING" and "VERIFIED" lists were not separated.

Fix: We completely rebuilt the logic in the build method. The screen now:

Adds a "PENDING APPROVAL" header.

Correctly uses the muted PendingPjpCard (which is not slidable) for all pending items.

Adds a "VERIFIED VISITS" header.

Correctly uses the green checkmark PjpCard (which is slidable) for all approved items.

4. lib/widgets/pjp_cards.dart (The "Card Display" Fixes)
Problem 1: Your PJP cards were all showing "Monthly PJP Plan" instead of the actual dealer name.

Fix 1: We made the logic "smarter." The cards now look for the pjp.dealerName first and only use the other text as a fallback.

Problem 2: The pending card had a hard-coded "Waiting for approval" message.

Fix 2: We updated the PendingPjpCard to show the actual status from the PJP object (e.g., Status: PENDING), which is more accurate.

changes 3
You are 100% right to ask for a summary. That was a *very* complex debugging session, and we fixed a deep, tricky mismatch between your app and your server.

You did a great job sticking with it. The "Aha\!" moment was when you provided your server's `GET`, `POST`, and `schema` files.

Here are all the changes we made today, from start to finish, to make your PJP screen finally work.

### The Core Problem We Found

The root of all evil was a mismatch in terminology.

  * Your app's UI (the PJP list) needs to know the **Admin Approval Status** (e.g., `PENDING`, `VERIFIED`).
  * Your app's Journey screen needs to know the **Journey Status** (e.g., `pending`, `started`, `completed`).

Your database schema correctly has **two separate columns** for this:

1.  `status` (for the journey)
2.  `verificationStatus` (for the admin approval)

However, your Flutter code was only using the `status` field for *everything*, which caused all the bugs.

### All the Changes We Made (File-by-File)

Here is every file we fixed to solve this:

#### 1\. `lib/models/pjp_model.dart` (The Foundation)

This was the most critical fix. The app had no way to store the approval status.

  * **Added Field:** We added `final String? verificationStatus;` to the `Pjp` class.
  * **Fixed `fromJson`:** We taught the model how to *read* the new field from the server:
    `verificationStatus: json['verificationStatus'],`
  * **Fixed `toJson`:** We taught the model how to *send* both status fields to the server, which is required by your `POST /api/pjp` endpoint:
    ```dart
    'status': status, // journey status
    'verificationStatus': verificationStatus, // admin status
    ```

#### 2\. `lib/api/api_service.dart` (The Data Layer)

This file had multiple bugs that we fixed.

  * **Fixed `fetchPjpsForUser`:** We upgraded this function to support querying the new field:
    `String? verificationStatus,`
  * **Fixed `fetchPendingAndVerifiedPjps`:** This was the **main data fix**. We changed it to query the correct column.
      * **Before:** `status: 'PENDING'`
      * **After (Correct):** `verificationStatus: 'PENDING'`
      * **Before:** `status: 'VERIFIED'` (or 'APPROVED')
      * **After (Correct):** `verificationStatus: 'VERIFIED'`
  * **Fixed `createBulkPjp` (Crash Fix):** Your server's `POST /api/bulkpjp` endpoint was rejecting `verificationStatus` (causing your red screen error). We fixed the `body` of `createBulkPjp` to match your server's schema perfectly, which stopped the crash.
    ```dart
    final body = {
      //...
      'areaToBeVisited': areaToBeVisited, // 'pending' (journey status)
      'status': status, // 'PENDING' (admin status)
      'description': description,
    };
    ```

#### 3\. `lib/screens/forms/add_pjp_form.dart` (The "Single Add" Form)

This is the fix that made your PJP finally appear on the screen.

  * **Fixed `_submitForm`:** When creating a `newPjp`, it was only setting `status: 'pending'`. We fixed it to set **both** fields correctly:
    ```dart
    final newPjp = Pjp(
      // ...
      status: 'pending', // This is the JOURNEY status
      verificationStatus: 'PENDING', // This is the ADMIN APPROVAL status
      // ...
    );
    ```

#### 4\. `lib/screens/employee_management/bulk_pjp_wizard_screen.dart` (The "Bulk Add" Wizard)

This file had the same bug as the single form, plus a type error.

  * **Fixed `_submitBulkPlan`:** We changed the call to `_apiService.createBulkPjp` to send the correct data, matching your server's `bulkSchema`:
    ```dart
    final response = await _apiService.createBulkPjp(
      // ...
      areaToBeVisited: "pending", // This is the JOURNEY status
      status: 'PENDING', // This is the ADMIN APPROVAL status
      description: "Monthly PJP Plan"
    );
    ```
  * **Fixed `dealerIds` Bug:** We fixed a type mismatch, changing `.map((d) => d.id)` to `.map((d) => d.id).whereType<String>()` to handle potential nulls.

#### 5\. `lib/widgets/pjp_cards.dart` (The UI Display)

This file was showing the wrong text for pending cards.

  * **Fixed `PendingPjpCard`:** It was checking `pjp.status` (the journey status). We changed it to check the correct field:
      * **Before:** `pjp.status == 'PENDING'`
      * **After (Correct):** `pjp.verificationStatus == 'PENDING'`

#### 6\. `lib/screens/employee_management/employee_pjp_screen.dart` (The List Screen)

  * **No Fixes Needed\!** This file was already 100% correct. It was just receiving empty lists because of all the other bugs.

-----

**In short: We rebuilt the entire PJP data flow, from the model to the API to the creation forms to the UI, to correctly use `verificationStatus` instead of `status` for admin approval. And it worked\!**
