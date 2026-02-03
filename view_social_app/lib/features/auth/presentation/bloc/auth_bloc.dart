import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/auth_models.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/verify_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/resend_verification_usecase.dart';
import '../../../../core/usecases/usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final RegisterUseCase registerUseCase;
  final VerifyUseCase verifyUseCase;
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final ResendVerificationUseCase resendVerificationUseCase;

  AuthBloc({
    required this.registerUseCase,
    required this.verifyUseCase,
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.resendVerificationUseCase,
  }) : super(AuthInitial()) {
    on<RegisterEvent>(_onRegister);
    on<VerifyEvent>(_onVerify);
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
    on<ResendVerificationEvent>(_onResendVerification);
  }

  Future<void> _onRegister(RegisterEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await registerUseCase(
      RegisterParams(
        username: event.username,
        password: event.password,
        identifier: event.identifier,
        registrationType: event.registrationType,
        displayName: event.displayName,
      ),
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (response) => emit(RegisterSuccess(response)),
    );
  }

  Future<void> _onVerify(VerifyEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await verifyUseCase(
      VerifyParams(identifier: event.identifier, code: event.code),
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (response) => emit(AuthSuccess(User.fromLoginResponse(response))),
    );
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await loginUseCase(
      LoginParams(identifier: event.identifier, password: event.password),
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (response) => emit(AuthSuccess(User.fromLoginResponse(response))),
    );
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await logoutUseCase(NoParams());

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthInitial()),
    );
  }

  Future<void> _onResendVerification(
    ResendVerificationEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await resendVerificationUseCase(
      ResendVerificationParams(identifier: event.identifier),
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(ResendVerificationSuccess()),
    );
  }
}
