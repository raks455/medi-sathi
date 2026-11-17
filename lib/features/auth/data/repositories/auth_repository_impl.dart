import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user.dart';
import '../../../notification/data/services/push_notification_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_token_storage.dart';
import '../datasources/google_auth_datasource.dart';
import '../models/auth_session_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remote;
  final AuthTokenStorage tokenStorage;
  final GoogleAuthDataSource googleAuth;
  final PushNotificationService pushService;

  AuthRepositoryImpl({
    required this.remote,
    required this.tokenStorage,
    required this.googleAuth,
    required this.pushService,
  });

  @override
  Future<Either<Failure, User>> signIn({
    required String email,
    required String password,
  }) =>
      _authenticate(() => remote.login(email: email, password: password));

  @override
  Future<Either<Failure, User>> signUp({
    required String email,
    required String password,
    required String fullName,
  }) =>
      _authenticate(() => remote.register(
            email: email,
            password: password,
            fullName: fullName,
          ));

  @override
  Future<Either<Failure, User>> signInWithGoogle() => _authenticate(() async {
        final firebaseIdToken = await googleAuth.signInAndGetFirebaseIdToken();
        try {
          return await remote.loginWithGoogle(firebaseIdToken);
        } on ServerException catch (e) {
          // Endpoint missing on the backend (see ApiConstants.googleLogin).
          if (e.statusCode == 404 || e.statusCode == 405) {
            throw ServerException(
                'Google sign-in is not enabled on the server yet.',
                statusCode: e.statusCode);
          }
          rethrow;
        }
      });

  Future<Either<Failure, User>> _authenticate(
      Future<AuthSessionModel> Function() call) async {
    try {
      final session = await call();
      await tokenStorage.saveSession(session);
      return Right(session.toUser());
    } on AuthCancelledException {
      return const Left(CancelledFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure('Unexpected response from the server.'));
    }
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      // Needs the access token, so it must run before the session is cleared.
      await pushService.unregisterDevice();
      final refresh = await tokenStorage.readRefreshToken();
      if (refresh != null) {
        // Best effort: even if the server call fails we still sign out locally.
        try {
          await remote.logout(refresh);
        } catch (_) {}
      }
      await tokenStorage.clear();
      try {
        await googleAuth.signOut();
      } catch (_) {}
      return Right(unit);
    } catch (_) {
      return const Left(CacheFailure('Could not sign out.'));
    }
  }

  @override
  Future<Either<Failure, bool>> isSignedIn() async {
    try {
      final token = await tokenStorage.readAccessToken();
      return Right(token != null && token.isNotEmpty);
    } catch (_) {
      return const Left(CacheFailure('Could not read login status'));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final session = await tokenStorage.readSession();
      return Right(session?.toUser());
    } catch (_) {
      return const Left(CacheFailure('Could not read user'));
    }
  }
}
