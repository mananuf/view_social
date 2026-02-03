import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/models/auth_models.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase implements UseCase<LoginResponse, LoginParams> {
  final AuthRepository repository;
  
  LoginUseCase(this.repository);
  
  @override
  Future<Either<Failure, LoginResponse>> call(LoginParams params) async {
    return await repository.login(
      identifier: params.identifier,
      password: params.password,
    );
  }
}

class LoginParams {
  final String identifier;
  final String password;
  
  LoginParams({
    required this.identifier,
    required this.password,
  });
}