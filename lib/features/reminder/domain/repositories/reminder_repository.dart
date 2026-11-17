import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/dose.dart';

abstract class ReminderRepository {
  /// Today's doses in the device's timezone.
  Future<Either<Failure, DoseSchedule>> getToday();

  /// Doses for a date range (the API allows at most 31 days).
  Future<Either<Failure, DoseSchedule>> getSchedule(
      DateTime startDate, DateTime endDate);

  /// Marks a dose taken or skipped. Returns the dose with its new status.
  Future<Either<Failure, ScheduledDose>> logDose(
      ScheduledDose dose, DoseStatus status);
}
