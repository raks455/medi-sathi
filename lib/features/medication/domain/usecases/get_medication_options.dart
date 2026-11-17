import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/medication.dart';
import '../repositories/medication_repository.dart';

class GetMedicationOptions implements UseCase<MedicationOptions, NoParams> {
  final MedicationRepository repository;
  GetMedicationOptions(this.repository);

  @override
  Future<Either<Failure, MedicationOptions>> call(NoParams p) =>
      repository.getOptions();
}
