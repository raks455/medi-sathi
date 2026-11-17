import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/medication_repository.dart';

class DeleteMedication implements UseCase<Unit, String> {
  final MedicationRepository repository;
  DeleteMedication(this.repository);

  @override
  Future<Either<Failure, Unit>> call(String id) =>
      repository.deleteMedication(id);
}
