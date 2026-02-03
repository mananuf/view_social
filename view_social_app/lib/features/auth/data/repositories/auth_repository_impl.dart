import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_models.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, RegisterResponse>> register({
    required String username,
    required String password,
    required String identifier,
    required String registrationType,
    String? displayName,
  }) async {
    try {
      final request = RegisterRequest(
        username: username,
        password: password,
        identifier: identifier,
        registrationType: registrationType,
        displayName: displayName,
      );

      final response = await _remoteDataSource.register(request);
      return Right(response);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, LoginResponse>> verify({
    required String identifier,
    required String code,
  }) async {
    try {
      final request = VerifyRequest(identifier: identifier, code: code);

      final response = await _remoteDataSource.verify(request);

      // Store token and user data after successful verification
      await _storeAuthData(response);

      return Right(response);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, LoginResponse>> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final request = LoginRequest(identifier: identifier, password: password);

      final response = await _remoteDataSource.login(request);

      // Store token and user data after successful login
      await _storeAuthData(response);

      return Right(response);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _remoteDataSource.logout();

      // Clear stored auth data
      await _clearAuthData();

      return const Right(null);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resendVerification({
    required String identifier,
  }) async {
    try {
      final request = ResendVerificationRequest(identifier: identifier);
      await _remoteDataSource.resendVerification(request);
      return const Right(null);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Store authentication data (token and user info) in local storage
  Future<void> _storeAuthData(LoginResponse response) async {
    final prefs = await SharedPreferences.getInstance();

    // Store access token
    await prefs.setString(AppConstants.accessTokenKey, response.token);

    // Store user data as JSON
    final user = User.fromLoginResponse(response);
    await prefs.setString(AppConstants.userDataKey, jsonEncode(user.toJson()));
  }

  /// Clear all stored authentication data
  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(AppConstants.accessTokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
    await prefs.remove(AppConstants.userDataKey);
  }
}
