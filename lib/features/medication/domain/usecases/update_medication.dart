import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/medication.dart';
import '../repositories/medication_repository.dart';

class UpdateMedication implements UseCase<Medication, UpdateMedicationParams> {
  final MedicationRepository repository;
  UpdateMedication(this.repository);

  @override
  Future<Either<Failure, Medication>> call(UpdateMedicationParams p) =>
      repository.updateMedication(p.id, p.input);
}

class UpdateMedicationParams extends Equatable {
  final String id;
  final MedicationInput input;
  const UpdateMedicationParams({required this.id, required this.input});
  @override
  List<Object?> get props => [id, input];
}
