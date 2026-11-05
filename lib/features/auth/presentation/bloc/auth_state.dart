import 'package:equatable/equatable.dart';

import '../../domain/entities/user.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, failure }

class AuthState extends Equatable {
  final AuthStatus status;
  final User? user;
  final String? message;

  /// True while the Google flow is loading (so only that button spins).
  final bool viaGoogle;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.message,
    this.viaGoogle = false,
  });

  @override
  List<Object?> get props => [status, user, message, viaGoogle];
}
