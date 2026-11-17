import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/medication.dart';

abstract class MedicationRepository {
  Future<Either<Failure, List<Medication>>> getMedications();
  Future<Either<Failure, MedicationOptions>> getOptions();
  Future<Either<Failure, Medication>> addMedication(MedicationInput input);
  Future<Either<Failure, Medication>> updateMedication(
      String id, MedicationInput input);
  Future<Either<Failure, Unit>> deleteMedication(String id);

  /// Stops ([stopped] true) or resumes a medicine.
  Future<Either<Failure, Medication>> setStopped(String id,
      {required bool stopped});
}
