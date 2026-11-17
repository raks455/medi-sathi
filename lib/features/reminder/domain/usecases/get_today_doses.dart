import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/dose.dart';
import '../repositories/reminder_repository.dart';

class GetTodayDoses implements UseCase<DoseSchedule, NoParams> {
  final ReminderRepository repository;
  GetTodayDoses(this.repository);

  @override
  Future<Either<Failure, DoseSchedule>> call(NoParams p) =>
      repository.getToday();
}
