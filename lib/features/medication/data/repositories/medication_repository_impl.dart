import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/repository_guard.dart';
import '../../domain/entities/medication.dart';
import '../../domain/repositories/medication_repository.dart';
import '../datasources/medication_remote_datasource.dart';

class MedicationRepositoryImpl implements MedicationRepository {
  final MedicationRemoteDataSource remote;
  MedicationRepositoryImpl(this.remote);

  @override
  Future<Either<Failure, List<Medication>>> getMedications() =>
      guardApiCall(remote.getMedications);

  @override
  Future<Either<Failure, MedicationOptions>> getOptions() =>
      guardApiCall(remote.getOptions);

  @override
  Future<Either<Failure, Medication>> addMedication(MedicationInput input) =>
      guardApiCall(() => remote.addMedication(input));

  @override
  Future<Either<Failure, Medication>> updateMedication(
          String id, MedicationInput input) =>
      guardApiCall(() => remote.updateMedication(id, input));

  @override
  Future<Either<Failure, Medication>> setStopped(String id,
          {required bool stopped}) =>
      guardApiCall(() => remote.setStopped(id, stopped: stopped));

  @override
  Future<Either<Failure, Unit>> deleteMedication(String id) =>
      guardApiCall(() async {
        await remote.deleteMedication(id);
        return unit;
      });
}
