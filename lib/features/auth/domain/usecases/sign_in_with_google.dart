import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// One use case for both "sign up with Google" and "sign in with Google":
/// the backend creates the account on first use.
class SignInWithGoogle implements UseCase<User, NoParams> {
  final AuthRepository repository;
  SignInWithGoogle(this.repository);

  @override
  Future<Either<Failure, User>> call(NoParams params) =>
      repository.signInWithGoogle();
}
