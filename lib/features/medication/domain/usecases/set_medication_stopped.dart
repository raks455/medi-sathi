import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/medication.dart';
import '../repositories/medication_repository.dart';

/// Stops a medicine (no more doses or reminders, history kept) or resumes it.
class SetMedicationStopped
    implements UseCase<Medication, SetMedicationStoppedParams> {
  final MedicationRepository repository;
  SetMedicationStopped(this.repository);

  @override
  Future<Either<Failure, Medication>> call(SetMedicationStoppedParams p) =>
      repository.setStopped(p.id, stopped: p.stopped);
}

class SetMedicationStoppedParams extends Equatable {
  final String id;
  final bool stopped;
  const SetMedicationStoppedParams({required this.id, required this.stopped});
  @override
  List<Object?> get props => [id, stopped];
}
