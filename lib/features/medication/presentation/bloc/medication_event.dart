import 'package:equatable/equatable.dart';

import '../../domain/entities/medication.dart';

abstract class MedicationEvent extends Equatable {
  const MedicationEvent();
  @override
  List<Object?> get props => [];
}

/// Loads (or refreshes) the medicine list and the picker options.
class MedicationsRequested extends MedicationEvent {
  const MedicationsRequested();
}

class MedicationAdded extends MedicationEvent {
  final MedicationInput input;
  const MedicationAdded(this.input);
  @override
  List<Object?> get props => [input];
}

class MedicationUpdated extends MedicationEvent {
  final String id;
  final MedicationInput input;
  const MedicationUpdated({required this.id, required this.input});
  @override
  List<Object?> get props => [id, input];
}

class MedicationDeleted extends MedicationEvent {
  final String id;
  const MedicationDeleted(this.id);
  @override
  List<Object?> get props => [id];
}

/// Stops ([stopped] true) or resumes a medicine.
class MedicationStopToggled extends MedicationEvent {
  final String id;
  final bool stopped;
  const MedicationStopToggled({required this.id, required this.stopped});
  @override
  List<Object?> get props => [id, stopped];
}
