import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_today_doses.dart';
import '../../domain/usecases/log_dose.dart';
import 'reminder_event.dart';
import 'reminder_state.dart';

export 'reminder_event.dart';
export 'reminder_state.dart';

/// Today's doses and marking them taken / skipped.
class ReminderBloc extends Bloc<ReminderEvent, ReminderState> {
  final GetTodayDoses getTodayDoses;
  final LogDose logDose;

  ReminderBloc({required this.getTodayDoses, required this.logDose})
      : super(const ReminderState()) {
    on<TodayRequested>(_onTodayRequested);
    on<DoseMarked>(_onDoseMarked);
  }

  Future<void> _onTodayRequested(
      TodayRequested e, Emitter<ReminderState> emit) async {
    emit(state.copyWith(status: ReminderStatus.loading));
    final result = await getTodayDoses(const NoParams());
    emit(result.fold(
      (f) => state.copyWith(
          status: ReminderStatus.failure, message: f.message),
      (today) => state.copyWith(status: ReminderStatus.success, today: today),
    ));
  }

  Future<void> _onDoseMarked(
      DoseMarked e, Emitter<ReminderState> emit) async {
    final key = e.dose.doseKey;
    if (state.marking.contains(key)) return;
    emit(state.copyWith(marking: {...state.marking, key}));

    final result = await logDose(LogDoseParams(dose: e.dose, status: e.status));
    final marking = {...state.marking}..remove(key);
    emit(result.fold(
      (f) => state.copyWith(marking: marking, markError: f.message),
      (saved) => state.copyWith(
        marking: marking,
        today: state.today?.withDose(saved),
      ),
    ));
  }
}
