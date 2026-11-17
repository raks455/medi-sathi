import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/medication.dart';
import '../repositories/medication_repository.dart';

class AddMedication implements UseCase<Medication, MedicationInput> {
  final MedicationRepository repository;
  AddMedication(this.repository);

  @override
  Future<Either<Failure, Medication>> call(MedicationInput input) =>
      repository.addMedication(input);
}
