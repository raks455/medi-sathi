import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/dose.dart';
import '../../domain/usecases/get_dose_schedule.dart';

/// Loads the doses of the last [days] days, ending today.
class HistoryRequested extends Equatable {
  final int days;
  const HistoryRequested(this.days);
  @override
  List<Object?> get props => [days];
}

enum HistoryStatus { loading, success, failure }

class DoseHistoryState extends Equatable {
  final HistoryStatus status;
  final int days;
  final DoseSchedule? schedule;
  final String? message;

  const DoseHistoryState({
    this.status = HistoryStatus.loading,
    this.days = 7,
    this.schedule,
    this.message,
  });

  @override
  List<Object?> get props => [status, days, schedule, message];
}

/// Dose history and adherence for a recent date range.
class DoseHistoryBloc extends Bloc<HistoryRequested, DoseHistoryState> {
  final GetDoseSchedule getDoseSchedule;

  DoseHistoryBloc({required this.getDoseSchedule})
      : super(const DoseHistoryState()) {
    on<HistoryRequested>(_onRequested);
  }

  Future<void> _onRequested(
      HistoryRequested e, Emitter<DoseHistoryState> emit) async {
    // Reloading the same range keeps the old data on screen meanwhile.
    emit(DoseHistoryState(
      days: e.days,
      schedule: e.days == state.days ? state.schedule : null,
    ));
    final now = DateTime.now();
    final result = await getDoseSchedule(DoseScheduleParams(
      // Calendar arithmetic (not Duration) so DST changes cannot shift the day.
      startDate: DateTime(now.year, now.month, now.day - (e.days - 1)),
      endDate: DateTime(now.year, now.month, now.day),
    ));
    // A newer request (other range) was started meanwhile: drop this result.
    if (state.days != e.days) return;
    emit(result.fold(
      (f) => DoseHistoryState(
        status: HistoryStatus.failure,
        days: e.days,
        schedule: state.schedule,
        message: f.message,
      ),
      (schedule) => DoseHistoryState(
          status: HistoryStatus.success, days: e.days, schedule: schedule),
    ));
  }
}
