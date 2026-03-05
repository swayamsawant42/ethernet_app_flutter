// lib/services/api_service.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import '../utils/token_storage.dart';
import '../config/api_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;

  ApiService._internal() {
    final baseUrl = ApiConfig.baseUrl;

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Interceptor to automatically add Bearer token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          // Don't set Content-Type for FormData - Dio will handle it automatically
          if (options.data is FormData) {
            options.headers.remove('Content-Type');
          }
          return handler.next(options);
        },
      ),
    );
  }

  // ---------------- HEALTH CHECKS ----------------
  Future<Map<String, dynamic>> getServerHealth() async {
    final response = await _dio.get('/health');
    return _normalizeResponse(response);
  }

  Future<Map<String, dynamic>> getLeadsHealth() async {
    final response = await _dio.get('/leads/health');
    return _normalizeResponse(response);
  }

  // ---------------- LOGIN ----------------
  Future<bool> login(String identifier, String password) async {
    try {
      print("Logging in with identifier: $identifier");
      final response = await _dio.post(
        '/auth/login',
        data: {"identifier": identifier, "password": password},
      );
      print("Response: ${response.data}");

      final normalized = _normalizeResponse(response);
      final tokens = _extractAuthTokens(normalized);
      final accessToken = tokens['accessToken'];
      final refreshToken = tokens['refreshToken'];

      if (accessToken != null && accessToken.isNotEmpty) {
        await TokenStorage.saveToken(accessToken);
        await TokenStorage.saveLoginTime(DateTime.now().toIso8601String());
        if (refreshToken != null && refreshToken.isNotEmpty) {
          await TokenStorage.saveRefreshToken(refreshToken);
        }
        return true;
      }

      return false;
    } on DioException catch (e) {
      print("ApiService.login error: ${e.response?.data ?? e.message}");
      return false;
    } catch (e) {
      print("ApiService.login unknown error: $e");
      return false;
    }
  }

  // FIXED Sign-up method - match your Postman request
  Future<bool> signUp(
    String name,
    String employeCode,
    String phoneNumber,
    String email,
    String password,
  ) async {
    try {
      print(
        "Signing up with: name=$name, employeCode=$employeCode, phoneNumber=$phoneNumber, email=$email",
      );

      final response = await _dio.post(
        '/auth/register',
        data: {
          "name": name,
          "employeCode": employeCode, // This was missing!
          "phoneNumber": phoneNumber, // This was missing!
          "email": email,
          "password": password,
        },
      );

      print("SignUp Response: ${response.data}");

      final normalized = _normalizeResponse(response);
      final tokens = _extractAuthTokens(normalized);
      final accessToken = tokens['accessToken'];
      final refreshToken = tokens['refreshToken'];

      if (accessToken != null && accessToken.isNotEmpty) {
        await TokenStorage.saveToken(accessToken);
        await TokenStorage.saveLoginTime(DateTime.now().toIso8601String());
        if (refreshToken != null && refreshToken.isNotEmpty) {
          await TokenStorage.saveRefreshToken(refreshToken);
        }
        return true;
      }

      return false;
    } on DioException catch (e) {
      print("ApiService.signUp error: ${e.response?.data ?? e.message}");
      return false;
    } catch (e) {
      print("ApiService.signUp unknown error: $e");
      return false;
    }
  }

  // ---------------- OTP VERIFICATION ----------------
  Future<bool> verifyLoginOtp({
    required int challengeId,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login/verify',
        data: {"challengeId": challengeId, "otp": otp},
      );

      final normalized = _normalizeResponse(response);
      final tokens = _extractAuthTokens(normalized);
      final accessToken = tokens['accessToken'];
      final refreshToken = tokens['refreshToken'];

      if (accessToken != null && accessToken.isNotEmpty) {
        await TokenStorage.saveToken(accessToken);
        await TokenStorage.saveLoginTime(DateTime.now().toIso8601String());
        if (refreshToken != null && refreshToken.isNotEmpty) {
          await TokenStorage.saveRefreshToken(refreshToken);
        }
        return true;
      }

      return false;
    } on DioException catch (e) {
      print(
        "ApiService.verifyLoginOtp error: ${e.response?.data ?? e.message}",
      );
      return false;
    } catch (e) {
      print("ApiService.verifyLoginOtp unknown error: $e");
      return false;
    }
  }

  // ---------------- TOKEN REFRESH ----------------
  Future<bool> refreshSession({String? refreshToken}) async {
    try {
      final token = refreshToken ?? await TokenStorage.getRefreshToken();
      if (token == null || token.isEmpty) return false;

      final response = await _dio.post(
        '/auth/refresh',
        data: {"refreshToken": token},
      );

      final normalized = _normalizeResponse(response);
      final tokens = _extractAuthTokens(normalized);
      final accessToken = tokens['accessToken'];
      final newRefreshToken = tokens['refreshToken'];

      if (accessToken != null && accessToken.isNotEmpty) {
        await TokenStorage.saveToken(accessToken);
        await TokenStorage.saveLoginTime(DateTime.now().toIso8601String());
        if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
          await TokenStorage.saveRefreshToken(newRefreshToken);
        }
        return true;
      }
      return false;
    } on DioException catch (e) {
      print(
        "ApiService.refreshSession error: ${e.response?.data ?? e.message}",
      );
      return false;
    } catch (e) {
      print("ApiService.refreshSession unknown error: $e");
      return false;
    }
  }

  // ---------------- CHANGE PASSWORD ----------------
  Future<Map<String, dynamic>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/change-password',
        data: {"oldPassword": currentPassword, "newPassword": newPassword},
      );
      final normalized = _normalizeResponse(response);
      
      // Return success status and message
      return {
        'success': normalized['success'] == true || response.statusCode == 200,
        'message': normalized['message'] ?? (response.statusCode == 200 ? 'Password changed successfully' : null),
      };
    } on DioException catch (e) {
      print(
        "ApiService.changePassword error: ${e.response?.data ?? e.message}",
      );
      
      // Extract error message from response
      String errorMessage = 'Password update failed. Please check your current password.';
      if (e.response?.data is Map<String, dynamic>) {
        final errorData = e.response!.data as Map<String, dynamic>;
        errorMessage = errorData['message'] ?? errorMessage;
      } else if (e.response?.data is String) {
        errorMessage = e.response!.data as String;
      }
      
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      print("ApiService.changePassword unknown error: $e");
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  // ---------------- USER MANAGEMENT ----------------
  Future<Map<String, dynamic>?> getUsers({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    try {
      final response = await _dio.get(
        '/users',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      return _normalizeResponse(response);
    } on DioException catch (e) {
      print("ApiService.getUsers error: ${e.response?.data ?? e.message}");
      return null;
    } catch (e) {
      print("ApiService.getUsers unknown error: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    try {
      final response = await _dio.get('/users/$id');
      return _normalizeResponse(response);
    } on DioException catch (e) {
      print("ApiService.getUserById error: ${e.response?.data ?? e.message}");
      return null;
    } catch (e) {
      print("ApiService.getUserById unknown error: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateUser({
    required int id,
    String? name,
    String? email,
    String? role,
    bool? isActive,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (name != null) payload['name'] = name;
      if (email != null) payload['email'] = email;
      if (role != null) payload['role'] = role;
      if (isActive != null) payload['isActive'] = isActive;

      final response = await _dio.put('/users/$id', data: payload);
      return _normalizeResponse(response);
    } on DioException catch (e) {
      print("ApiService.updateUser error: ${e.response?.data ?? e.message}");
      return null;
    } catch (e) {
      print("ApiService.updateUser unknown error: $e");
      return null;
    }
  }

  Future<bool> deleteUser(int id) async {
    try {
      final response = await _dio.delete('/users/$id');
      return response.statusCode == 200;
    } on DioException catch (e) {
      print("ApiService.deleteUser error: ${e.response?.data ?? e.message}");
      return false;
    } catch (e) {
      print("ApiService.deleteUser unknown error: $e");
      return false;
    }
  }
  // Add these methods to your ApiService class in api_service.dart

  // Add these methods to your ApiService class in api_service.dart

  // ---------------- GET PROFILE ----------------
  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final response = await _dio.get('/auth/profile');
      print("Profile response: ${response.data}");

      // API returns: { "success": true, "data": { ... } }
      if (response.data is Map<String, dynamic>) {
        final body = response.data as Map<String, dynamic>;

        // Check if response is successful
        if (body['success'] == true && body.containsKey('data')) {
          final data = body['data'] as Map<String, dynamic>;
          print("Profile data extracted: $data");
          return data;
        }

        // Fallback: try normalized response
        final normalized = _normalizeResponse(response);
        if (normalized.containsKey('user')) {
          return Map<String, dynamic>.from(normalized['user']);
        }
        return normalized;
      }

      return null;
    } on DioException catch (e) {
      print("ApiService.getProfile error: ${e.response?.data ?? e.message}");
      // Return null on error - don't use mock data, let caller handle it
      return null;
    } catch (e) {
      print("ApiService.getProfile unknown error: $e");
      return null;
    }
  }

  // ---------------- GET APP INFO ----------------
  Future<Map<String, dynamic>> getAppInfo() async {
    try {
      // If you have a backend endpoint for app info, call it here:
      // final response = await _dio.get('/app/info');
      // return Map<String, dynamic>.from(response.data['data']);

      // Otherwise, return static info
      return {
        "version": "1.0.0",
        "lastUpdated": "Nov 2025",
        "platform": "Flutter Web",
      };
    } catch (e) {
      print("ApiService.getAppInfo error: $e");
      return {
        "version": "1.0.0",
        "lastUpdated": "Unknown",
        "platform": "Flutter Web",
      };
    }
  }

  // ---------------- SUBMIT EXPENSE ----------------
  Future<bool> submitExpense({
    required String employeCode,
    required String name,
    required String category,
    required String amount,
    required String distanceTravelled,
    required List<String> imagePaths,
  }) async {
    try {
      print("=== STARTING EXPENSE SUBMISSION ===");
      print("Input - Employee Code: $employeCode, Name: $name");
      print(
        "Input - Category: $category, Amount: $amount, Distance: $distanceTravelled",
      );
      print("Input - Images count: ${imagePaths.length}");

      // Get user profile to ensure we have the latest data
      final profile = await getProfile();
      final String finalEmployeCode = profile?['employeCode'] ?? employeCode;
      final String finalName = profile?['name'] ?? name;

      print(
        "Profile fetched - Employee Code: $finalEmployeCode, Name: $finalName",
      );

      // Create FormData for multipart/form-data
      final FormData formData = FormData();

      // Add text fields
      formData.fields.add(
        MapEntry(
          'user',
          '{"employeCode":"$finalEmployeCode","name":"$finalName"}',
        ),
      );
      formData.fields.add(MapEntry('category', category));
      formData.fields.add(MapEntry('amount', amount));
      formData.fields.add(MapEntry('distanceTravelled', distanceTravelled));

      // Add image files to FormData (multiple files with same field name)
      for (String imagePath in imagePaths) {
        try {
          final file = await MultipartFile.fromFile(imagePath);
          formData.files.add(MapEntry('billImages', file));
          print("  Added image file: $imagePath");
        } catch (e) {
          print("  ERROR adding image file $imagePath: $e");
          // Continue with other images even if one fails
        }
      }

      print(
        "FormData created - Fields: ${formData.fields.length}, Files: ${formData.files.length}",
      );
      print("Sending POST request to: /leads/expense/add");

      print("Sending POST request to: /leads/expense/add");
      print(
        "FormData summary - Fields: ${formData.fields.length}, Files: ${formData.files.length}",
      );

      // Don't set Content-Type header - Dio will set it automatically with boundary
      final response = await _dio.post('/leads/expense/add', data: formData);

      print("=== API RESPONSE RECEIVED ===");
      print("✓ Request completed successfully!");
      print("Response status: ${response.statusCode}");
      print("Response headers: ${response.headers}");
      print("Response data type: ${response.data.runtimeType}");
      print("Response data: ${response.data}");

      // If we got here without exception, and status is 200-299, it's success
      final statusCode = response.statusCode ?? 0;

      // Accept any 2xx status code as success
      if (statusCode >= 200 && statusCode < 300) {
        print("✓✓✓ SUCCESS: Status code $statusCode indicates success ✓✓✓");

        // Log response details if available
        try {
          if (response.data != null) {
            if (response.data is Map) {
              final responseData = response.data as Map;
              print("Response message: ${responseData['message']}");
              if (responseData.containsKey('expense')) {
                print("✓ Expense object found in response");
              }
            }
          }
        } catch (e) {
          print("Note: Could not parse response details: $e");
        }

        return true;
      }

      final responseMessage = _extractErrorMessage(response.data);
      throw ExpenseSubmissionException(
        responseMessage ??
            'Server rejected the expense (status $statusCode). Please review your data.',
        statusCode: statusCode,
      );
    } on DioException catch (e) {
      print("ApiService.submitExpense DioException:");
      print("  Error message: ${e.message}");
      print("  Error type: ${e.type}");
      print("  Response status: ${e.response?.statusCode}");
      print("  Response data: ${e.response?.data}");
      print("  Response data type: ${e.response?.data?.runtimeType}");
      print("  Request path: ${e.requestOptions.path}");
      print("  Request method: ${e.requestOptions.method}");

      // Check for specific error types
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        print("  Timeout error - check your internet connection");
      }
      if (e.type == DioExceptionType.connectionError) {
        print("  Connection error - check your internet connection");
      }

      // IMPORTANT: Dio throws DioException even for successful responses (2xx)
      // Check the actual response status code, not just the exception
      final responseStatus = e.response?.statusCode;

      print("  Response status code: $responseStatus");

      // If status is 2xx (200-299), it's actually a success!
      if (responseStatus != null &&
          responseStatus >= 200 &&
          responseStatus < 300) {
        print(
          "  ⚠ DioException thrown BUT status code is $responseStatus (2xx = success)",
        );
        print("  ✓✓✓ Treating as SUCCESS despite DioException ✓✓✓");
        return true;
      }

      // Check for specific error status codes
      if (responseStatus == 401 || responseStatus == 403) {
        print("  ❌ Authentication error - token may be expired or invalid");
        print("  💡 Try logging out and logging back in");
      } else if (responseStatus == 400) {
        print("  ❌ Validation error - check the request data");
        print("  💡 Make sure all required fields are filled correctly");
      } else if (responseStatus == 404) {
        print("  ❌ Not found - API endpoint might not exist");
      } else if (responseStatus == 500) {
        print("  ❌ Server error - the server encountered an issue");
        print("  💡 Try again later or contact support");
      } else if (responseStatus != null) {
        print("  ❌ HTTP error status: $responseStatus");
      } else {
        print("  ❌ No response status code (network error or timeout)");
      }

      // Return detailed error info for debugging
      if (e.response != null) {
        final errorData = e.response!.data;
        if (errorData is Map) {
          print("  API Error message: ${errorData['message']}");
          print("  API Error keys: ${errorData.keys.toList()}");
          if (errorData.containsKey('errors')) {
            print("  API Validation errors: ${errorData['errors']}");
          }
        } else {
          print("  API Error data: $errorData");
        }
      }

      final errorMessage =
          _extractErrorMessage(e.response?.data) ??
          e.message ??
          'Expense submission failed';
      throw ExpenseSubmissionException(
        errorMessage,
        statusCode: responseStatus,
        details: e.response?.data,
      );
    } catch (e) {
      print("ApiService.submitExpense unknown error: $e");
      print("  Error type: ${e.runtimeType}");
      print("  Stack trace: ${StackTrace.current}");
      throw ExpenseSubmissionException(
        'Unexpected error while submitting expense. Please try again.',
      );
    }
  }

  Future<Map<String, dynamic>?> getExpenses({
    int page = 1,
    int limit = 10,
    String? employeCode,
  }) async {
    try {
      print("=== GET EXPENSES API CALL ===");
      print("Page: $page, Limit: $limit, Employee Code: $employeCode");

      final queryParams = <String, dynamic>{'page': page, 'limit': limit};

      // Add employeCode only if provided (API uses it for filtering)
      // Include "UNKNOWN" as well since it's a valid employeCode value
      if (employeCode != null && employeCode.isNotEmpty) {
        queryParams['employeCode'] = employeCode;
        print("Added employeCode to query: $employeCode");
      } else {
        print("No employeCode provided - backend will return all expenses");
      }

      print("Query parameters: $queryParams");

      final response = await _dio.get(
        '/leads/expense',
        queryParameters: queryParams,
      );

      print("Get expenses response status: ${response.statusCode}");
      print("Get expenses response type: ${response.data.runtimeType}");

      final normalized = _normalizeResponse(response);
      print("Normalized response type: ${normalized.runtimeType}");
      print(
        "Normalized response keys: ${normalized is Map ? (normalized as Map).keys.toList() : 'N/A'}",
      );

      return normalized;
    } on DioException catch (e) {
      print("ApiService.getExpenses DioException:");
      print("  Error: ${e.message}");
      print("  Response status: ${e.response?.statusCode}");
      print("  Response data: ${e.response?.data}");
      return null;
    } catch (e) {
      print("ApiService.getExpenses unknown error: $e");
      print("  Error type: ${e.runtimeType}");
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateExpenseStatus({
    required int expenseId,
    required String status,
  }) async {
    try {
      final response = await _dio.post(
        '/leads/expense/approve/$expenseId',
        data: {'status': status},
      );
      return _normalizeResponse(response);
    } on DioException catch (e) {
      print(
        "ApiService.updateExpenseStatus error: ${e.response?.data ?? e.message}",
      );
      return null;
    } catch (e) {
      print("ApiService.updateExpenseStatus unknown error: $e");
      return null;
    }
  }

  // ---------------- SUBMIT TRAVEL RECORD ----------------
  Future<Map<String, dynamic>?> submitTravelRecord({
    required String date,
    required double distanceKm,
    required String vehicleType,
    required dynamic route, // Can be String or Map<String, dynamic>
    List<Map<String, dynamic>>? coordinates,
    int? id, // For updating existing record
    String? startedAt, // ISO datetime string
    String? endedAt, // ISO datetime string
  }) async {
    try {
      // Map UI vehicle types to API expected values
      String formattedVehicleType;
      final vehicleTypeLower = vehicleType.toLowerCase().trim();
      
      if (vehicleTypeLower == 'vehicle 1' || vehicleTypeLower == 'own vehicle') {
        formattedVehicleType = 'OWN_VEHICLE';
      } else if (vehicleTypeLower == 'vehicle 2' || vehicleTypeLower == 'colleague') {
        formattedVehicleType = 'COLLEAGUE';
      } else if (vehicleTypeLower == 'vehicle 3' || vehicleTypeLower == 'company vehicle') {
        formattedVehicleType = 'COMPANY_VEHICLE';
      } else {
        // Fallback: try to convert to uppercase with underscores
        formattedVehicleType = vehicleType.toUpperCase().replaceAll(' ', '_');
      }

      final data = <String, dynamic>{
        'date': date,
        'distance_km': distanceKm,
        'vehicle_type': formattedVehicleType,
        'route': route,
      };

      // Add id if provided (for updates)
      if (id != null) {
        data['id'] = id;
      }

      // Add timestamps if provided
      if (startedAt != null) {
        data['started_at'] = startedAt;
      }
      if (endedAt != null) {
        data['ended_at'] = endedAt;
      }

      // Add coordinates if provided
      if (coordinates != null && coordinates.isNotEmpty) {
        data['coordinates'] = coordinates;
      }

      print("Submitting travel record with data: $data");

      final response = await _dio.post(
        '/travelTracker',
        data: data,
      );

      print("Submit travel record response: ${response.data}");

      // API returns: { "message": "...", "record": { ... } }
      if (response.data is Map<String, dynamic>) {
        final body = response.data as Map<String, dynamic>;
        if (body.containsKey('record')) {
          return Map<String, dynamic>.from(body['record']);
        }
        return body;
      }

      return null;
    } on DioException catch (e) {
      final errorMessage = e.response?.data is Map
          ? (e.response?.data as Map)['message'] ?? e.response?.data.toString()
          : e.response?.data?.toString() ?? e.message ?? 'Unknown error';
      print(
        "ApiService.submitTravelRecord error: $errorMessage",
      );
      // Return error info instead of null so UI can display it
      return {
        'error': true,
        'message': errorMessage.toString(),
      };
    } catch (e) {
      print("ApiService.submitTravelRecord unknown error: $e");
      return {
        'error': true,
        'message': e.toString(),
      };
    }
  }

  // ---------------- UPLOAD TRAVEL COORDINATES ----------------
  Future<Map<String, dynamic>?> uploadTravelCoordinates({
    required String date,
    required String route,
    required String vehicleType,
    required double totalDistance,
    required List<Map<String, dynamic>> coordinates,
  }) async {
    try {
      // Format vehicle type
      String formattedVehicleType = vehicleType.toUpperCase().replaceAll(
        ' ',
        '_',
      );

      final response = await _dio.post(
        '/travelTracker',
        data: {
          'date': date,
          'distance_km': totalDistance,
          'vehicle_type': formattedVehicleType,
          'route': route,
          'coordinates': coordinates,
        },
      );

      print("Upload travel coordinates response: ${response.data}");

      if (response.data is Map<String, dynamic>) {
        final body = response.data as Map<String, dynamic>;
        if (body.containsKey('record')) {
          return Map<String, dynamic>.from(body['record']);
        }
        return body;
      }

      return null;
    } on DioException catch (e) {
      print(
        "ApiService.uploadTravelCoordinates error: ${e.response?.data ?? e.message}",
      );
      return null;
    } catch (e) {
      print("ApiService.uploadTravelCoordinates unknown error: $e");
      return null;
    }
  }

  // ---------------- GET OWN TRAVEL RECORDS ----------------
  Future<List<dynamic>?> getOwnTravelRecords() async {
    try {
      final response = await _dio.get('/travelTracker');

      // API returns array of travel records ordered by date (newest first)
      if (response.data is List) {
        return List<dynamic>.from(response.data);
      }

      final normalized = _normalizeResponse(response);
      if (normalized['records'] is List) {
        return List<dynamic>.from(normalized['records']);
      }
      if (normalized['data'] is List) {
        return List<dynamic>.from(normalized['data']);
      }

      return null;
    } on DioException catch (e) {
      print(
        "ApiService.getOwnTravelRecords error: ${e.response?.data ?? e.message}",
      );
      return null;
    } catch (e) {
      print("ApiService.getOwnTravelRecords unknown error: $e");
      return null;
    }
  }

  // ---------------- GET OWN MONTHLY TRAVEL RECORDS ----------------
  Future<Map<String, dynamic>?> getOwnMonthlyTravel({
    required int month,
    required int year,
  }) async {
    try {
      final response = await _dio.get(
        '/travelTracker/monthwise',
        queryParameters: {'month': month, 'year': year},
      );

      // API returns: { "records": [...], "summary": {...} }
      final normalized = _normalizeResponse(response);
      return normalized;
    } on DioException catch (e) {
      print(
        "ApiService.getOwnMonthlyTravel error: ${e.response?.data ?? e.message}",
      );
      return null;
    } catch (e) {
      print("ApiService.getOwnMonthlyTravel unknown error: $e");
      return null;
    }
  }

  // ---------------- GET MONTHLY TRAVEL RECORDS (with userId filter) ----------------
  Future<Map<String, dynamic>?> getMonthlyTravelRecords({
    required int month,
    required int year,
    int? userId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'month': month,
        'year': year,
      };
      if (userId != null) {
        queryParams['user_id'] = userId;
      }

      final response = await _dio.get(
        '/travelTracker/monthwise',
        queryParameters: queryParams,
      );

      // API returns: { "records": [...], "summary": {...} }
      // Handle direct response or normalized response
      if (response.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response.data);
      }

      final normalized = _normalizeResponse(response);
      return normalized;
    } on DioException catch (e) {
      print(
        "ApiService.getMonthlyTravelRecords error: ${e.response?.data ?? e.message}",
      );
      return null;
    } catch (e) {
      print("ApiService.getMonthlyTravelRecords unknown error: $e");
      return null;
    }
  }

  // ---------------- EXECUTIVE MANAGEMENT ----------------
  Future<Map<String, dynamic>?> createEmUser({
    required String name,
    required String password,
    required int roleId,
    required List<int> moduleIds,
    String? employeCode,
    String? phoneNumber,
    String? email,
  }) async {
    try {
      final payload = {
        "name": name,
        "password": password,
        "roleId": roleId,
        "moduleIds": moduleIds,
        if (employeCode != null) "employeCode": employeCode,
        if (phoneNumber != null) "phoneNumber": phoneNumber,
        if (email != null) "email": email,
      };

      final response = await _dio.post('/leads/em/users', data: payload);
      return _normalizeResponse(response);
    } on DioException catch (e) {
      print("ApiService.createEmUser error: ${e.response?.data ?? e.message}");
      return null;
    } catch (e) {
      print("ApiService.createEmUser unknown error: $e");
      return null;
    }
  }

  Future<List<dynamic>?> getEmUsers() async {
    try {
      final response = await _dio.get('/leads/em/users');
      if (response.data is List) {
        return List<dynamic>.from(response.data);
      }
      final normalized = _normalizeResponse(response);
      return normalized['users'] is List
          ? List<dynamic>.from(normalized['users'])
          : null;
    } on DioException catch (e) {
      print("ApiService.getEmUsers error: ${e.response?.data ?? e.message}");
      return null;
    } catch (e) {
      print("ApiService.getEmUsers unknown error: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> getEmUserById(int id) async {
    try {
      final response = await _dio.get('/leads/em/users/$id');
      return _normalizeResponse(response);
    } on DioException catch (e) {
      print("ApiService.getEmUserById error: ${e.response?.data ?? e.message}");
      return null;
    } catch (e) {
      print("ApiService.getEmUserById unknown error: $e");
      return null;
    }
  }

  // ---------------- ROLE MANAGEMENT ----------------
  Future<Map<String, dynamic>?> createRole({
    required String name,
    String? description,
  }) async {
    try {
      final response = await _dio.post(
        '/role',
        data: {
          "name": name,
          if (description != null) "description": description,
        },
      );
      return _normalizeResponse(response);
    } on DioException catch (e) {
      print("ApiService.createRole error: ${e.response?.data ?? e.message}");
      return null;
    } catch (e) {
      print("ApiService.createRole unknown error: $e");
      return null;
    }
  }

  Future<List<dynamic>?> getRoles() async {
    try {
      final response = await _dio.get('/role');
      if (response.data is List) {
        return List<dynamic>.from(response.data);
      }
      final normalized = _normalizeResponse(response);
      if (normalized['roles'] is List) {
        return List<dynamic>.from(normalized['roles']);
      }
      return null;
    } on DioException catch (e) {
      print("ApiService.getRoles error: ${e.response?.data ?? e.message}");
      return null;
    } catch (e) {
      print("ApiService.getRoles unknown error: $e");
      return null;
    }
  }

  // ---------------- MODULE MANAGEMENT ----------------
  Future<Map<String, dynamic>?> createModule({
    required String name,
    String? description,
  }) async {
    try {
      final response = await _dio.post(
        '/module',
        data: {
          "name": name,
          if (description != null) "description": description,
        },
      );
      return _normalizeResponse(response);
    } on DioException catch (e) {
      print("ApiService.createModule error: ${e.response?.data ?? e.message}");
      return null;
    } catch (e) {
      print("ApiService.createModule unknown error: $e");
      return null;
    }
  }

  Future<List<dynamic>?> getModules() async {
    try {
      final response = await _dio.get('/module');
      if (response.data is List) {
        return List<dynamic>.from(response.data);
      }
      final normalized = _normalizeResponse(response);
      if (normalized['modules'] is List) {
        return List<dynamic>.from(normalized['modules']);
      }
      return null;
    } on DioException catch (e) {
      print("ApiService.getModules error: ${e.response?.data ?? e.message}");
      return null;
    } catch (e) {
      print("ApiService.getModules unknown error: $e");
      return null;
    }
  }

  // ---------------- SUBMIT FIELD SURVEY ----------------
  Future<bool> submitFieldSurvey({
    required String serviceRating,
    required String contactNumber,
    required String heardFrom,
    required String likedFeatures,
    required String feedback,
    required String customerName,
    required String customerEmail,
    required double latitude,
    required double longitude,
    String? surveyId,
  }) async {
    try {
      final payload = {
        "serviceRating": serviceRating,
        "contactNumber": contactNumber,
        "heardFrom": heardFrom,
        "likedFeatures": likedFeatures,
        "feedback": feedback,
        "customerName": customerName,
        "customerEmail": customerEmail,
        "latitude": latitude,
        "longitude": longitude,
      };

      if (surveyId != null && surveyId.isNotEmpty) {
        payload["id"] = surveyId;
      }

      print("Submitting field survey with payload: $payload");
      print("Base URL: ${_dio.options.baseUrl}");

      final response = await _dio.post('/leads/survey/add', data: payload);

      print("Survey response status: ${response.statusCode}");
      print("Survey response data: ${response.data}");

      final normalized = _normalizeResponse(response);
      final isSuccess =
          response.statusCode == 200 ||
          response.statusCode == 201 ||
          normalized['success'] == true;

      print("Survey submission success: $isSuccess");
      return isSuccess;
    } on DioException catch (e) {
      print("ApiService.submitFieldSurvey DioException:");
      print("  Error: ${e.message}");
      print("  Response: ${e.response?.data}");
      print("  Status Code: ${e.response?.statusCode}");
      print("  Request Path: ${e.requestOptions.path}");
      return false;
    } catch (e) {
      print("ApiService.submitFieldSurvey unknown error: $e");
      return false;
    }
  }

  Future<List<dynamic>?> getAllSurveys() async {
    try {
      final response = await _dio.get('/leads/survey');
      final normalized = _normalizeResponse(response);
      if (normalized['survey'] is List) {
        return List<dynamic>.from(normalized['survey']);
      }
      if (response.data is List) {
        return List<dynamic>.from(response.data);
      }
      return normalized['surveys'] is List
          ? List<dynamic>.from(normalized['surveys'])
          : null;
    } on DioException catch (e) {
      print("ApiService.getAllSurveys error: ${e.response?.data ?? e.message}");
      return null;
    } catch (e) {
      print("ApiService.getAllSurveys unknown error: $e");
      return null;
    }
  }

  // ---------------- GET FIELD SURVEYS (with pagination and filters) ----------------
  Future<List<dynamic>?> getFieldSurveys({
    int page = 1,
    int limit = 10,
    int? userId,
    String? employeCode,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (userId != null) {
        queryParams['userId'] = userId;
      }
      if (employeCode != null && employeCode.isNotEmpty) {
        queryParams['employeCode'] = employeCode;
      }

      final response = await _dio.get(
        '/leads/survey',
        queryParameters: queryParams,
      );

      // API can return either a List directly or wrapped in an object
      if (response.data is List) {
        return List<dynamic>.from(response.data);
      }

      final normalized = _normalizeResponse(response);
      if (normalized['survey'] is List) {
        return List<dynamic>.from(normalized['survey']);
      }
      if (normalized['surveys'] is List) {
        return List<dynamic>.from(normalized['surveys']);
      }
      if (normalized['data'] is List) {
        return List<dynamic>.from(normalized['data']);
      }

      return null;
    } on DioException catch (e) {
      print("ApiService.getFieldSurveys error: ${e.response?.data ?? e.message}");
      return null;
    } catch (e) {
      print("ApiService.getFieldSurveys unknown error: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> getSurveySummary() async {
    try {
      final response = await _dio.get('/leads/survey/summary');
      return _normalizeResponse(response);
    } on DioException catch (e) {
      print(
        "ApiService.getSurveySummary error: ${e.response?.data ?? e.message}",
      );
      return null;
    } catch (e) {
      print("ApiService.getSurveySummary unknown error: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> getSurveyById(int id) async {
    try {
      final response = await _dio.get('/leads/survey/$id');
      return _normalizeResponse(response);
    } on DioException catch (e) {
      print("ApiService.getSurveyById error: ${e.response?.data ?? e.message}");
      return null;
    } catch (e) {
      print("ApiService.getSurveyById unknown error: $e");
      return null;
    }
  }

  // ---------------- CREATE LEAD ----------------
  Future<Map<String, dynamic>?> createLead({
    required String name,
    required String phoneNumber,
    required String address,
    required String source,
    required String serviceType,
  }) async {
    try {
      final response = await _dio.post(
        '/leads/',
        data: {
          'name': name,
          'phone_number': phoneNumber,
          'address': address,
          'source': source,
          'service_type': serviceType,
        },
      );

      print("Create lead response: ${response.data}");

      // API returns: { "success": true, "data": { ... } } or { "lead": { ... } }
      if (response.data is Map<String, dynamic>) {
        final body = response.data as Map<String, dynamic>;
        if (body.containsKey('data')) {
          return Map<String, dynamic>.from(body['data']);
        }
        if (body.containsKey('lead')) {
          return Map<String, dynamic>.from(body['lead']);
        }
        return body;
      }

      return null;
    } on DioException catch (e) {
      print("ApiService.createLead error: ${e.response?.data ?? e.message}");
      return null;
    } catch (e) {
      print("ApiService.createLead unknown error: $e");
      return null;
    }
  }

  // ---------------- SEND CUSTOMER DETAILS FROM LEAD ----------------
  Future<Map<String, dynamic>?> sendCustomerDetailsFrom(int leadId) async {
    try {
      final response = await _dio.get('/leads/sendCustomerDetailsFrom/$leadId');

      print("Send customer details response: ${response.data}");

      if (response.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response.data);
      }

      return _normalizeResponse(response);
    } on DioException catch (e) {
      print(
        "ApiService.sendCustomerDetailsFrom error: ${e.response?.data ?? e.message}",
      );
      return null;
    } catch (e) {
      print("ApiService.sendCustomerDetailsFrom unknown error: $e");
      return null;
    }
  }

  // ---------------- LOGOUT ----------------
  Future<bool> logout() async {
    try {
      // Step 1: Call API logout endpoint with current token
      // Token is automatically added by the interceptor
      try {
        final response = await _dio.post('/auth/logout');
        print("Logout API response: ${response.data}");

        // Check if logout was successful
        if (response.data is Map<String, dynamic>) {
          final body = response.data as Map<String, dynamic>;
          final bool success = body['success'] == true;

          if (success) {
            print("Logout successful: ${body['message']}");
          } else {
            print("Logout API returned success: false");
          }
        }
      } on DioException catch (apiError) {
        // API logout failed, but we'll still clear local storage
        print(
          "ApiService.logout API error: ${apiError.response?.data ?? apiError.message}",
        );
        // Continue to clear local storage even if API call fails
      } catch (apiError) {
        print("ApiService.logout API unknown error: $apiError");
        // Continue to clear local storage even if API call fails
      }

      // Step 2: Clear token and login data from local storage
      // This should always happen, even if API call fails
      await TokenStorage.clearToken();
      await TokenStorage.clearRefreshToken();
      await TokenStorage.clearLoginTime();
      _dio.options.headers.remove('Authorization');

      return true;
    } catch (e) {
      // Ensure local storage is cleared even if there's an error
      print("ApiService.logout error: $e");
      try {
        await TokenStorage.clearToken();
        await TokenStorage.clearRefreshToken();
        await TokenStorage.clearLoginTime();
        _dio.options.headers.remove('Authorization');
      } catch (clearError) {
        print("Error clearing token storage: $clearError");
      }
      return true; // Return true to indicate logout attempt completed
    }
  }

  // ---------------- HELPERS ----------------
  /// Decode JWT token to extract user ID
  int? _getUserIdFromToken(String? token) {
    if (token == null || token.isEmpty) return null;
    
    try {
      // JWT format: header.payload.signature
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      // Decode the payload (middle part)
      final payload = parts[1];
      // Add padding if needed for base64 decoding
      String normalizedPayload = payload;
      switch (payload.length % 4) {
        case 1:
          normalizedPayload += '===';
          break;
        case 2:
          normalizedPayload += '==';
          break;
        case 3:
          normalizedPayload += '=';
          break;
      }
      
      // Decode base64
      final decodedBytes = base64Url.decode(normalizedPayload);
      final decodedString = utf8.decode(decodedBytes);
      final payloadMap = json.decode(decodedString) as Map<String, dynamic>;
      
      // Extract user ID
      final idValue = payloadMap['id'];
      if (idValue is int) {
        return idValue;
      } else if (idValue is String) {
        return int.tryParse(idValue);
      }
      return null;
    } catch (e) {
      print("Error decoding JWT token: $e");
      return null;
    }
  }

  /// Get current user ID from stored token
  Future<int?> getCurrentUserId() async {
    final token = await TokenStorage.getToken();
    return _getUserIdFromToken(token);
  }

  Map<String, dynamic> _normalizeResponse(Response response) {
    if (response.data is Map<String, dynamic>) {
      final body = Map<String, dynamic>.from(response.data);
      final data = body['data'];

      if (data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(data);
      }
      return body;
    }
    return {'raw': response.data};
  }

  Map<String, String?> _extractAuthTokens(Map<String, dynamic> normalized) {
    final rawAccessToken =
        normalized['token'] ??
        normalized['accessToken'] ??
        normalized['access_token'];
    final rawRefreshToken =
        normalized['refreshToken'] ?? normalized['refresh_token'];

    final accessToken = rawAccessToken is String
        ? rawAccessToken
        : normalized['jwtToken'];
    final refreshToken = rawRefreshToken is String
        ? rawRefreshToken
        : normalized['refresh'];

    return {
      'accessToken': accessToken is String ? accessToken : null,
      'refreshToken': refreshToken is String ? refreshToken : null,
    };
  }

  String? _extractErrorMessage(dynamic data) {
    if (data == null) return null;
    if (data is String) return data;
    if (data is Map) {
      if (data['message'] is String) return data['message'] as String;
      if (data['error'] is String) return data['error'] as String;
      if (data['errors'] is List && data['errors'].isNotEmpty) {
        final first = data['errors'].first;
        if (first is Map && first['msg'] is String)
          return first['msg'] as String;
        if (first is String) return first;
      }
    }
    return null;
  }
}

class ExpenseSubmissionException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  ExpenseSubmissionException(this.message, {this.statusCode, this.details});

  @override
  String toString() =>
      'ExpenseSubmissionException(statusCode: $statusCode, message: $message, details: $details)';
}
