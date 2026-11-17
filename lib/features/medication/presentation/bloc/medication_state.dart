import 'package:equatable/equatable.dart';

import '../../domain/entities/medication.dart';

/// Status of loading the list.
enum MedicationStatus { initial, loading, success, failure }

/// The last add / edit / delete that was started.
enum MedicationAction { none, add, update, delete, stop, resume }

enum ActionStatus { idle, inProgress, success, failure }

class MedicationState extends Equatable {
  final MedicationStatus status;
  final List<Medication> medications;
  final MedicationOptions options;

  /// Error text when [status] is failure.
  final String? message;

  final MedicationAction action;
  final ActionStatus actionStatus;

  /// Error text when [actionStatus] is failure.
  final String? actionMessage;

  const MedicationState({
    this.status = MedicationStatus.initial,
    this.medications = const [],
    this.options = MedicationOptions.fallback,
    this.message,
    this.action = MedicationAction.none,
    this.actionStatus = ActionStatus.idle,
    this.actionMessage,
  });

  bool get isBusy => actionStatus == ActionStatus.inProgress;

  MedicationState copyWith({
    MedicationStatus? status,
    List<Medication>? medications,
    MedicationOptions? options,
    String? message,
    MedicationAction? action,
    ActionStatus? actionStatus,
    String? actionMessage,
  }) {
    return MedicationState(
      status: status ?? this.status,
      medications: medications ?? this.medications,
      options: options ?? this.options,
      message: message ?? this.message,
      action: action ?? this.action,
      actionStatus: actionStatus ?? this.actionStatus,
      // Not carried over: it only describes the latest action result.
      actionMessage: actionMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        medications,
        options,
        message,
        action,
        actionStatus,
        actionMessage,
      ];
}
