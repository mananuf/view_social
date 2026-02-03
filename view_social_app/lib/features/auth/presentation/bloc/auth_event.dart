part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class RegisterEvent extends AuthEvent {
  final String username;
  final String password;
  final String identifier;
  final String registrationType;
  final String? displayName;

  const RegisterEvent({
    required this.username,
    required this.password,
    required this.identifier,
    required this.registrationType,
    this.displayName,
  });

  @override
  List<Object?> get props => [
    username,
    password,
    identifier,
    registrationType,
    displayName,
  ];
}

class VerifyEvent extends AuthEvent {
  final String identifier;
  final String code;

  const VerifyEvent({required this.identifier, required this.code});

  @override
  List<Object?> get props => [identifier, code];
}

class LoginEvent extends AuthEvent {
  final String identifier;
  final String password;

  const LoginEvent({required this.identifier, required this.password});

  @override
  List<Object?> get props => [identifier, password];
}

class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}

class ResendVerificationEvent extends AuthEvent {
  final String identifier;

  const ResendVerificationEvent({required this.identifier});

  @override
  List<Object?> get props => [identifier];
}
