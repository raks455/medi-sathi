import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/dose.dart';
import '../repositories/reminder_repository.dart';

class GetDoseSchedule implements UseCase<DoseSchedule, DoseScheduleParams> {
  final ReminderRepository repository;
  GetDoseSchedule(this.repository);

  @override
  Future<Either<Failure, DoseSchedule>> call(DoseScheduleParams p) =>
      repository.getSchedule(p.startDate, p.endDate);
}

class DoseScheduleParams extends Equatable {
  final DateTime startDate;
  final DateTime endDate;
  const DoseScheduleParams({required this.startDate, required this.endDate});
  @override
  List<Object?> get props => [startDate, endDate];
}
