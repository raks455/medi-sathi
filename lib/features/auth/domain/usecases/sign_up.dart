import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class SignUp implements UseCase<User, SignUpParams> {
  final AuthRepository repository;
  SignUp(this.repository);

  @override
  Future<Either<Failure, User>> call(SignUpParams p) => repository.signUp(
        email: p.email,
        password: p.password,
        fullName: p.fullName,
      );
}

class SignUpParams extends Equatable {
  final String email;
  final String password;
  final String fullName;
  const SignUpParams({
    required this.email,
    required this.password,
    required this.fullName,
  });
  @override
  List<Object?> get props => [email, password, fullName];
}
