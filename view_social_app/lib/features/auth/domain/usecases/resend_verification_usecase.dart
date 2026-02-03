import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class ResendVerificationUseCase
    implements UseCase<void, ResendVerificationParams> {
  final AuthRepository repository;

  ResendVerificationUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ResendVerificationParams params) async {
    return await repository.resendVerification(identifier: params.identifier);
  }
}

class ResendVerificationParams {
  final String identifier;

  ResendVerificationParams({required this.identifier});
}
