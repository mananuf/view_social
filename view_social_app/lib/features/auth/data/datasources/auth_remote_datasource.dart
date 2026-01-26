import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login(String email, String password);
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData);
  Future<Map<String, dynamic>> refreshToken(String refreshToken);
  Future<void> logout();
  Future<UserModel> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;
  
  AuthRemoteDataSourceImpl({required this.apiClient});
  
  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await apiClient.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Login failed');
    }
  }
  
  @override
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await apiClient.dio.post('/auth/register', data: userData);
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Registration failed');
    }
  }
  
  @override
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await apiClient.dio.post('/auth/refresh', data: {
        'refresh_token': refreshToken,
      });
      
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Token refresh failed');
    }
  }
  
  @override
  Future<void> logout() async {
    try {
      await apiClient.dio.post('/auth/logout');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Logout failed');
    }
  }
  
  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await apiClient.dio.get('/users/me');
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to get user data');
    }
  }
}