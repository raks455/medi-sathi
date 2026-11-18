import 'package:dartz/dartz.dart';

import '../error/exceptions.dart';
import '../l10n/l10n.dart';
import '../error/failures.dart';

/// Runs an authenticated API call and converts exceptions into Failures.
Future<Either<Failure, T>> guardApiCall<T>(Future<T> Function() call) async {
  try {
    return Right(await call());
  } on ServerException catch (e) {
    // A 401 here means the token refresh also failed (see AuthInterceptor).
    if (e.statusCode == 401) {
      return Left(ServerFailure(
          'Your session has expired. Please sign in again.'.tr));
    }
    return Left(ServerFailure(e.message));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (_) {
    return Left(ServerFailure('Unexpected response from the server.'.tr));
  }
}
