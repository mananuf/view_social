import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_routes.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../models/auth_models.dart';

abstract class AuthRemoteDataSource {
  Future<RegisterResponse> register(RegisterRequest request);
  Future<LoginResponse> verify(VerifyRequest request);
  Future<LoginResponse> login(LoginRequest request);
  Future<void> logout();
  Future<void> resendVerification(ResendVerificationRequest request);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl(this._apiClient);

  @override
  Future<RegisterResponse> register(RegisterRequest request) async {
    try {
      print(
        'Making register request to: ${_apiClient.dio.options.baseUrl}${ApiRoutes.register}',
      );
      print('Request data: ${request.toJson()}');

      final response = await _apiClient.dio.post(
        ApiRoutes.register,
        data: request.toJson(),
      );

      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');
      print('Response data type: ${response.data.runtimeType}');

      // Check if response.data is a Map
      if (response.data is! Map<String, dynamic>) {
        print(
          'ERROR: Response data is not a Map, it is: ${response.data.runtimeType}',
        );
        print('Raw response data: ${response.data}');
        throw Exception(
          'Invalid response format: expected Map but got ${response.data.runtimeType}',
        );
      }

      final responseData = response.data as Map<String, dynamic>;

      // Check if this is an error response
      if (responseData.containsKey('success') &&
          responseData['success'] == false) {
        final errorDetail = responseData['error'] as Map<String, dynamic>;
        throw ValidationFailure(errorDetail['message'] as String);
      }

      return RegisterResponse.fromJson(responseData);
    } on DioException catch (e) {
      print('DioException: ${e.message}');
      print('Response data: ${e.response?.data}');

      // Handle error response from server
      if (e.response?.data != null &&
          e.response!.data is Map<String, dynamic>) {
        final errorData = e.response!.data as Map<String, dynamic>;
        if (errorData.containsKey('error')) {
          final errorDetail = errorData['error'] as Map<String, dynamic>;
          throw ValidationFailure(errorDetail['message'] as String);
        }
      }

      throw _handleDioError(e);
    } catch (e) {
      print('General exception: $e');
      print('Exception type: ${e.runtimeType}');
      rethrow;
    }
  }

  @override
  Future<LoginResponse> verify(VerifyRequest request) async {
    try {
      print(
        'Making verify request to: ${_apiClient.dio.options.baseUrl}${ApiRoutes.verify}',
      );
      print('Request data: ${request.toJson()}');

      final response = await _apiClient.dio.post(
        ApiRoutes.verify,
        data: request.toJson(),
      );

      print('Verify response status: ${response.statusCode}');
      print('Verify response data: ${response.data}');
      print('Verify response data type: ${response.data.runtimeType}');

      // Check if response.data is a Map
      if (response.data is! Map<String, dynamic>) {
        print(
          'ERROR: Response data is not a Map, it is: ${response.data.runtimeType}',
        );
        print('Raw response data: ${response.data}');
        throw Exception(
          'Invalid response format: expected Map but got ${response.data.runtimeType}',
        );
      }

      final responseData = response.data as Map<String, dynamic>;

      // Check if this is an error response
      if (responseData.containsKey('success') &&
          responseData['success'] == false) {
        final errorDetail = responseData['error'] as Map<String, dynamic>;
        throw ValidationFailure(errorDetail['message'] as String);
      }

      final loginResponse = LoginResponse.fromJson(responseData);

      // Store token and user data
      await _storeAuthData(loginResponse);

      return loginResponse;
    } on DioException catch (e) {
      print('Verify DioException: ${e.message}');
      print('Verify response data: ${e.response?.data}');
      print('Verify status code: ${e.response?.statusCode}');

      // Handle error response from server
      if (e.response?.data != null &&
          e.response!.data is Map<String, dynamic>) {
        final errorData = e.response!.data as Map<String, dynamic>;
        if (errorData.containsKey('error')) {
          final errorDetail = errorData['error'] as Map<String, dynamic>;
          throw ValidationFailure(errorDetail['message'] as String);
        }
      }

      throw _handleDioError(e);
    } catch (e) {
      print('Verify general exception: $e');
      print('Exception type: ${e.runtimeType}');
      rethrow;
    }
  }

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      print(
        'Making login request to: ${_apiClient.dio.options.baseUrl}${ApiRoutes.login}',
      );
      print('Login request data: ${request.toJson()}');

      final response = await _apiClient.dio.post(
        ApiRoutes.login,
        data: request.toJson(),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response data: ${response.data}');
      print('Login response data type: ${response.data.runtimeType}');

      // Check if response.data is a Map
      if (response.data is! Map<String, dynamic>) {
        print(
          'ERROR: Login response data is not a Map, it is: ${response.data.runtimeType}',
        );
        print('Raw login response data: ${response.data}');
        throw Exception(
          'Invalid response format: expected Map but got ${response.data.runtimeType}',
        );
      }

      final responseData = response.data as Map<String, dynamic>;

      // Check if this is an error response
      if (responseData.containsKey('success') &&
          responseData['success'] == false) {
        final errorDetail = responseData['error'] as Map<String, dynamic>;
        throw ValidationFailure(errorDetail['message'] as String);
      }

      final loginResponse = LoginResponse.fromJson(responseData);

      // Store token and user data
      await _storeAuthData(loginResponse);

      return loginResponse;
    } on DioException catch (e) {
      print('Login DioException: ${e.message}');
      print('Login response data: ${e.response?.data}');

      // Handle error response from server
      if (e.response?.data != null &&
          e.response!.data is Map<String, dynamic>) {
        final errorData = e.response!.data as Map<String, dynamic>;
        if (errorData.containsKey('error')) {
          final errorDetail = errorData['error'] as Map<String, dynamic>;
          throw ValidationFailure(errorDetail['message'] as String);
        }
      }

      throw _handleDioError(e);
    } catch (e) {
      print('Login general exception: $e');
      print('Login exception type: ${e.runtimeType}');
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _apiClient.dio.post(ApiRoutes.logout);
    } on DioException {
      // Continue with local logout even if server request fails
      // Log error for debugging
    } finally {
      // Always clear local storage
      await _clearAuthData();
    }
  }

  @override
  Future<void> resendVerification(ResendVerificationRequest request) async {
    try {
      await _apiClient.dio.post(
        ApiRoutes.resendVerification,
        data: request.toJson(),
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> _storeAuthData(LoginResponse response) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.accessTokenKey, response.token);
    await prefs.setString(
      AppConstants.userDataKey,
      response.toJson().toString(),
    );
  }

  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.accessTokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
    await prefs.remove(AppConstants.userDataKey);
  }

  Failure _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const NetworkFailure(
          'Connection timeout. Please check your internet connection.',
        );

      case DioExceptionType.connectionError:
        return const NetworkFailure(
          'No internet connection. Please check your network settings.',
        );

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'An error occurred';

        switch (statusCode) {
          case 400:
            return ValidationFailure(message);
          case 401:
            return const AuthenticationFailure('Invalid credentials');
          case 403:
            return const AuthenticationFailure('Access denied');
          case 404:
            return const ServerFailure('Resource not found');
          case 409:
            return ValidationFailure(message);
          case 422:
            return ValidationFailure(message);
          case 500:
          default:
            return ServerFailure(message);
        }

      default:
        return ServerFailure(e.message ?? 'An unexpected error occurred');
    }
  }
}
