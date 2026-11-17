import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/repository_guard.dart';
import '../../domain/entities/dose.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../datasources/reminder_remote_datasource.dart';

class ReminderRepositoryImpl implements ReminderRepository {
  final ReminderRemoteDataSource remote;
  ReminderRepositoryImpl(this.remote);

  @override
  Future<Either<Failure, DoseSchedule>> getToday() =>
      guardApiCall(remote.getToday);

  @override
  Future<Either<Failure, DoseSchedule>> getSchedule(
          DateTime startDate, DateTime endDate) =>
      guardApiCall(() => remote.getSchedule(startDate, endDate));

  @override
  Future<Either<Failure, ScheduledDose>> logDose(
          ScheduledDose dose, DoseStatus status) =>
      guardApiCall(() async {
        final saved = await remote.logDose(
          medicationId: dose.medicationId,
          scheduledFor: dose.scheduledFor,
          status: status,
        );
        return dose.withStatus(saved.status, saved.respondedAt);
      });
}
