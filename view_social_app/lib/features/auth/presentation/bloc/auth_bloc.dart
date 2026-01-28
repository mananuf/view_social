import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/models/user_model.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiClient apiClient;

  AuthBloc({required this.apiClient}) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthTokenRefreshRequested>(_onAuthTokenRefreshRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.accessTokenKey);
      final userJson = prefs.getString(AppConstants.userDataKey);

      if (token != null && userJson != null) {
        final user = UserModel.fromJson(jsonDecode(userJson));
        emit(AuthAuthenticated(user: user, accessToken: token));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final response = await apiClient.dio.post('/auth/login', data: {
        'email': event.email,
        'password': event.password,
      });

      final accessToken = response.data['access_token'] as String;
      final refreshToken = response.data['refresh_token'] as String;
      final user = UserModel.fromJson(response.data['user']);

      // Persist tokens and user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.accessTokenKey, accessToken);
      await prefs.setString(AppConstants.refreshTokenKey, refreshToken);
      await prefs.setString(AppConstants.userDataKey, jsonEncode(user.toJson()));

      emit(AuthAuthenticated(user: user, accessToken: accessToken));
    } catch (e) {
      emit(AuthError(_getErrorMessage(e)));
    }
  }

  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final response = await apiClient.dio.post('/auth/register', data: {
        'username': event.username,
        'email': event.email,
        'password': event.password,
        if (event.phoneNumber != null) 'phone_number': event.phoneNumber,
      });

      final accessToken = response.data['access_token'] as String;
      final refreshToken = response.data['refresh_token'] as String;
      final user = UserModel.fromJson(response.data['user']);

      // Persist tokens and user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.accessTokenKey, accessToken);
      await prefs.setString(AppConstants.refreshTokenKey, refreshToken);
      await prefs.setString(AppConstants.userDataKey, jsonEncode(user.toJson()));

      emit(AuthAuthenticated(user: user, accessToken: accessToken));
    } catch (e) {
      emit(AuthError(_getErrorMessage(e)));
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      // Call logout endpoint
      await apiClient.dio.post('/auth/logout');
    } catch (e) {
      // Continue with logout even if API call fails
    }

    // Clear local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.accessTokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
    await prefs.remove(AppConstants.userDataKey);

    emit(const AuthUnauthenticated());
  }

  Future<void> _onAuthTokenRefreshRequested(
    AuthTokenRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(AppConstants.refreshTokenKey);

      if (refreshToken == null) {
        emit(const AuthUnauthenticated());
        return;
      }

      final response = await apiClient.dio.post('/auth/refresh', data: {
        'refresh_token': refreshToken,
      });

      final newAccessToken = response.data['access_token'] as String;
      await prefs.setString(AppConstants.accessTokenKey, newAccessToken);

      // Get current user data
      final userJson = prefs.getString(AppConstants.userDataKey);
      if (userJson != null) {
        final user = UserModel.fromJson(jsonDecode(userJson));
        emit(AuthAuthenticated(user: user, accessToken: newAccessToken));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(const AuthUnauthenticated());
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('DioException')) {
      return 'Network error. Please check your connection.';
    }
    return 'Authentication failed. Please try again.';
  }
}
