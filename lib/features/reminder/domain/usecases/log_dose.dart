import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/dose.dart';
import '../repositories/reminder_repository.dart';

class LogDose implements UseCase<ScheduledDose, LogDoseParams> {
  final ReminderRepository repository;
  LogDose(this.repository);

  @override
  Future<Either<Failure, ScheduledDose>> call(LogDoseParams p) =>
      repository.logDose(p.dose, p.status);
}

class LogDoseParams extends Equatable {
  final ScheduledDose dose;

  /// [DoseStatus.taken] or [DoseStatus.skipped].
  final DoseStatus status;
  const LogDoseParams({required this.dose, required this.status});
  @override
  List<Object?> get props => [dose, status];
}
