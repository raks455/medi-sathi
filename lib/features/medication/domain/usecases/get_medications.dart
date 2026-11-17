import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/medication.dart';
import '../repositories/medication_repository.dart';

class GetMedications implements UseCase<List<Medication>, NoParams> {
  final MedicationRepository repository;
  GetMedications(this.repository);

  @override
  Future<Either<Failure, List<Medication>>> call(NoParams p) =>
      repository.getMedications();
}
