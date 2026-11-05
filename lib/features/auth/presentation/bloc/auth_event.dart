import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class SignInSubmitted extends AuthEvent {
  final String email;
  final String password;
  const SignInSubmitted({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class SignUpSubmitted extends AuthEvent {
  final String fullName;
  final String email;
  final String password;
  const SignUpSubmitted({
    required this.fullName,
    required this.email,
    required this.password,
  });
  @override
  List<Object?> get props => [fullName, email, password];
}

class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}

/// Loads the saved user (used by Home). Emits unauthenticated if none.
class AuthUserRequested extends AuthEvent {
  const AuthUserRequested();
}

/// "Continue with Google" (works for both sign in and sign up).
class GoogleSignInRequested extends AuthEvent {
  const GoogleSignInRequested();
}
