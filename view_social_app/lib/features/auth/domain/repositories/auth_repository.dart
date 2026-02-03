import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/auth_models.dart';

abstract class AuthRepository {
  Future<Either<Failure, RegisterResponse>> register({
    required String username,
    required String password,
    required String identifier,
    required String registrationType,
    String? displayName,
  });
  
  Future<Either<Failure, LoginResponse>> verify({
    required String identifier,
    required String code,
  });
  
  Future<Either<Failure, LoginResponse>> login({
    required String identifier,
    required String password,
  });
  
  Future<Either<Failure, void>> logout();
  
  Future<Either<Failure, void>> resendVerification({
    required String identifier,
  });
}