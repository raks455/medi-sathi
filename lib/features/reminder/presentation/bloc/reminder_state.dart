import 'package:equatable/equatable.dart';

import '../../domain/entities/dose.dart';

enum ReminderStatus { initial, loading, success, failure }

class ReminderState extends Equatable {
  final ReminderStatus status;

  /// Today's doses; kept on screen while refreshing.
  final DoseSchedule? today;

  /// Error text when [status] is failure.
  final String? message;

  /// Dose keys currently being saved.
  final Set<String> marking;

  /// Set when marking a dose failed (shown once as a snackbar).
  final String? markError;

  const ReminderState({
    this.status = ReminderStatus.initial,
    this.today,
    this.message,
    this.marking = const {},
    this.markError,
  });

  ReminderState copyWith({
    ReminderStatus? status,
    DoseSchedule? today,
    String? message,
    Set<String>? marking,
    String? markError,
  }) {
    return ReminderState(
      status: status ?? this.status,
      today: today ?? this.today,
      message: message ?? this.message,
      marking: marking ?? this.marking,
      // Not carried over: it only describes the latest attempt.
      markError: markError,
    );
  }

  @override
  List<Object?> get props => [status, today, message, marking, markError];
}
