import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up.dart';
import 'auth_event.dart';
import 'auth_state.dart';

export 'auth_event.dart';
export 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignIn signIn;
  final SignUp signUp;
  final SignInWithGoogle signInWithGoogle;
  final SignOut signOut;
  final GetCurrentUser getCurrentUser;

  AuthBloc({
    required this.signIn,
    required this.signUp,
    required this.signInWithGoogle,
    required this.signOut,
    required this.getCurrentUser,
  }) : super(const AuthState()) {
    on<SignInSubmitted>(_onSignIn);
    on<SignUpSubmitted>(_onSignUp);
    on<GoogleSignInRequested>(_onGoogle);
    on<SignOutRequested>(_onSignOut);
    on<AuthUserRequested>(_onUserRequested);
  }

  Future<void> _onSignIn(SignInSubmitted e, Emitter<AuthState> emit) async {
    emit(const AuthState(status: AuthStatus.loading));
    final result =
        await signIn(SignInParams(email: e.email, password: e.password));
    emit(result.fold(
      (f) => AuthState(status: AuthStatus.failure, message: f.message),
      (user) => AuthState(status: AuthStatus.authenticated, user: user),
    ));
  }

  Future<void> _onSignUp(SignUpSubmitted e, Emitter<AuthState> emit) async {
    emit(const AuthState(status: AuthStatus.loading));
    final result = await signUp(SignUpParams(
      email: e.email,
      password: e.password,
      fullName: e.fullName,
    ));
    emit(result.fold(
      (f) => AuthState(status: AuthStatus.failure, message: f.message),
      (user) => AuthState(status: AuthStatus.authenticated, user: user),
    ));
  }

  Future<void> _onGoogle(
      GoogleSignInRequested e, Emitter<AuthState> emit) async {
    emit(const AuthState(status: AuthStatus.loading, viaGoogle: true));
    final result = await signInWithGoogle(const NoParams());
    emit(result.fold(
      // Closing the Google picker is not an error: just return to the form.
      (f) => f is CancelledFailure
          ? const AuthState()
          : AuthState(status: AuthStatus.failure, message: f.message),
      (user) => AuthState(status: AuthStatus.authenticated, user: user),
    ));
  }

  Future<void> _onSignOut(SignOutRequested e, Emitter<AuthState> emit) async {
    await signOut(const NoParams());
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> _onUserRequested(
      AuthUserRequested e, Emitter<AuthState> emit) async {
    final result = await getCurrentUser(const NoParams());
    final user = result.getOrElse(() => null);
    emit(user == null
        ? const AuthState(status: AuthStatus.unauthenticated)
        : AuthState(status: AuthStatus.authenticated, user: user));
  }
}
