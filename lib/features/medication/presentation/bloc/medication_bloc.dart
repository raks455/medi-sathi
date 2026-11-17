import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/medication.dart';
import '../../domain/usecases/add_medication.dart';
import '../../domain/usecases/delete_medication.dart';
import '../../domain/usecases/get_medication_options.dart';
import '../../domain/usecases/get_medications.dart';
import '../../domain/usecases/set_medication_stopped.dart';
import '../../domain/usecases/update_medication.dart';
import 'medication_event.dart';
import 'medication_state.dart';

export 'medication_event.dart';
export 'medication_state.dart';

class MedicationBloc extends Bloc<MedicationEvent, MedicationState> {
  final GetMedications getMedications;
  final GetMedicationOptions getOptions;
  final AddMedication addMedication;
  final UpdateMedication updateMedication;
  final DeleteMedication deleteMedication;
  final SetMedicationStopped setMedicationStopped;

  MedicationBloc({
    required this.getMedications,
    required this.getOptions,
    required this.addMedication,
    required this.updateMedication,
    required this.deleteMedication,
    required this.setMedicationStopped,
  }) : super(const MedicationState()) {
    on<MedicationsRequested>(_onRequested);
    on<MedicationAdded>(_onAdded);
    on<MedicationUpdated>(_onUpdated);
    on<MedicationDeleted>(_onDeleted);
    on<MedicationStopToggled>(_onStopToggled);
  }

  Future<void> _onRequested(
      MedicationsRequested e, Emitter<MedicationState> emit) async {
    emit(state.copyWith(status: MedicationStatus.loading));

    // Both requests run in parallel.
    final listFuture = getMedications(const NoParams());
    final optionsFuture = getOptions(const NoParams());
    final list = await listFuture;
    final options = await optionsFuture;

    emit(list.fold(
      (f) => state.copyWith(
          status: MedicationStatus.failure, message: f.message),
      (items) => state.copyWith(
        status: MedicationStatus.success,
        medications: items,
        // If options fail to load, the built-in fallback list stays in use.
        options: options.getOrElse(() => state.options),
      ),
    ));
  }

  Future<void> _onAdded(
          MedicationAdded e, Emitter<MedicationState> emit) =>
      _runAction<Medication>(
        emit,
        MedicationAction.add,
        () => addMedication(e.input),
        // The API lists newest first.
        (created) => [created, ...state.medications],
      );

  Future<void> _onUpdated(
          MedicationUpdated e, Emitter<MedicationState> emit) =>
      _runAction<Medication>(
        emit,
        MedicationAction.update,
        () => updateMedication(
            UpdateMedicationParams(id: e.id, input: e.input)),
        (updated) => [
          for (final m in state.medications) m.id == updated.id ? updated : m,
        ],
      );

  Future<void> _onDeleted(
          MedicationDeleted e, Emitter<MedicationState> emit) =>
      _runAction<Unit>(
        emit,
        MedicationAction.delete,
        () => deleteMedication(e.id),
        (_) => state.medications.where((m) => m.id != e.id).toList(),
      );

  Future<void> _onStopToggled(
          MedicationStopToggled e, Emitter<MedicationState> emit) =>
      _runAction<Medication>(
        emit,
        e.stopped ? MedicationAction.stop : MedicationAction.resume,
        () => setMedicationStopped(
            SetMedicationStoppedParams(id: e.id, stopped: e.stopped)),
        (updated) => [
          for (final m in state.medications) m.id == updated.id ? updated : m,
        ],
      );

  Future<void> _runAction<T>(
    Emitter<MedicationState> emit,
    MedicationAction action,
    Future<Either<Failure, T>> Function() call,
    List<Medication> Function(T result) applyToList,
  ) async {
    emit(state.copyWith(
        action: action, actionStatus: ActionStatus.inProgress));
    final result = await call();
    emit(result.fold(
      (f) => state.copyWith(
          actionStatus: ActionStatus.failure, actionMessage: f.message),
      (value) => state.copyWith(
        actionStatus: ActionStatus.success,
        medications: applyToList(value),
      ),
    ));
  }
}
