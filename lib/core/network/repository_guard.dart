import 'package:dartz/dartz.dart';

import '../error/exceptions.dart';
import '../error/failures.dart';

/// Runs an authenticated API call and converts exceptions into Failures.
Future<Either<Failure, T>> guardApiCall<T>(Future<T> Function() call) async {
  try {
    return Right(await call());
  } on ServerException catch (e) {
    // A 401 here means the token refresh also failed (see AuthInterceptor).
    if (e.statusCode == 401) {
      return const Left(
          ServerFailure('Your session has expired. Please sign in again.'));
    }
    return Left(ServerFailure(e.message));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (_) {
    return const Left(ServerFailure('Unexpected response from the server.'));
  }
}
