import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/models/auth_models.dart';
import '../repositories/auth_repository.dart';

class VerifyUseCase implements UseCase<LoginResponse, VerifyParams> {
  final AuthRepository repository;
  
  VerifyUseCase(this.repository);
  
  @override
  Future<Either<Failure, LoginResponse>> call(VerifyParams params) async {
    return await repository.verify(
      identifier: params.identifier,
      code: params.code,
    );
  }
}

class VerifyParams {
  final String identifier;
  final String code;
  
  VerifyParams({
    required this.identifier,
    required this.code,
  });
}