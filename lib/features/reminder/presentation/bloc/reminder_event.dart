import 'package:equatable/equatable.dart';

import '../../domain/entities/dose.dart';

abstract class ReminderEvent extends Equatable {
  const ReminderEvent();
  @override
  List<Object?> get props => [];
}

/// Loads (or refreshes) today's doses.
class TodayRequested extends ReminderEvent {
  const TodayRequested();
}

/// Marks a dose as [DoseStatus.taken] or [DoseStatus.skipped].
class DoseMarked extends ReminderEvent {
  final ScheduledDose dose;
  final DoseStatus status;
  const DoseMarked(this.dose, this.status);
  @override
  List<Object?> get props => [dose, status];
}
