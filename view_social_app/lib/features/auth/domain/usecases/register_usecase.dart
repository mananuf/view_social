import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/models/auth_models.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase implements UseCase<RegisterResponse, RegisterParams> {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  @override
  Future<Either<Failure, RegisterResponse>> call(RegisterParams params) async {
    return await repository.register(
      username: params.username,
      password: params.password,
      identifier: params.identifier,
      registrationType: params.registrationType,
      displayName: params.displayName,
    );
  }
}

class RegisterParams {
  final String username;
  final String password;
  final String identifier;
  final String registrationType;
  final String? displayName;

  RegisterParams({
    required this.username,
    required this.password,
    required this.identifier,
    required this.registrationType,
    this.displayName,
  });
}