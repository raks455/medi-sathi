import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../core/error/failures.dart';

/// Strips the time so dates compare by calendar day.
DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool _between(DateTime day, DateTime start, DateTime end) {
  final d = dayOnly(day);
  return !d.isBefore(dayOnly(start)) && !d.isAfter(dayOnly(end));
}

// ---- period tracker ---------------------------------------------------------

enum PeriodFlow {
  light('light', 'Light'),
  medium('medium', 'Medium'),
  heavy('heavy', 'Heavy');

  final String apiValue;
  final String label;
  const PeriodFlow(this.apiValue, this.label);

  static PeriodFlow? fromApi(String? v) {
    for (final f in values) {
      if (f.apiValue == v) return f;
    }
    return null;
  }
}

class Period extends Equatable {
  final String id;
  final DateTime startDate;

  /// Null while the period is ongoing.
  final DateTime? endDate;
  final PeriodFlow? flow;
  final String? notes;

  const Period({
    required this.id,
    required this.startDate,
    this.endDate,
    this.flow,
    this.notes,
  });

  bool get ongoing => endDate == null;

  /// Days of this period. An ongoing one counts up to [today].
  bool covers(DateTime day, DateTime today) =>
      _between(day, startDate, endDate ?? today);

  int lengthDays(DateTime today) =>
      dayOnly(endDate ?? today).difference(dayOnly(startDate)).inDays + 1;

  @override
  List<Object?> get props => [id, startDate, endDate, flow, notes];
}

class CycleWindow extends Equatable {
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime ovulationDate;
  final DateTime fertileStart;
  final DateTime fertileEnd;
  final bool predicted;

  const CycleWindow({
    required this.periodStart,
    required this.periodEnd,
    required this.ovulationDate,
    required this.fertileStart,
    required this.fertileEnd,
    required this.predicted,
  });

  bool inFertile(DateTime day) => _between(day, fertileStart, fertileEnd);
  bool inPeriod(DateTime day) => _between(day, periodStart, periodEnd);
  bool isOvulation(DateTime day) => dayOnly(day) == dayOnly(ovulationDate);

  @override
  List<Object?> get props =>
      [periodStart, periodEnd, ovulationDate, fertileStart, fertileEnd, predicted];
}

/// What a calendar day means in the cycle.
enum DayKind { period, predictedPeriod, ovulation, fertile, none }

class CycleOverview extends Equatable {
  final int averageCycleLength;
  final int averagePeriodLength;
  final DateTime? lastPeriodStart;
  final DateTime? nextPeriodStart;

  /// Negative when the period is late.
  final int? daysUntilNextPeriod;
  final int? cycleDay;

  /// menstrual | follicular | fertile | ovulation | luteal
  final String? phase;
  final List<CycleWindow> windows;

  /// Newest first.
  final List<Period> periods;

  const CycleOverview({
    this.averageCycleLength = 28,
    this.averagePeriodLength = 5,
    this.lastPeriodStart,
    this.nextPeriodStart,
    this.daysUntilNextPeriod,
    this.cycleDay,
    this.phase,
    this.windows = const [],
    this.periods = const [],
  });

  Period? periodOn(DateTime day, DateTime today) {
    for (final p in periods) {
      if (p.covers(day, today)) return p;
    }
    return null;
  }

  DayKind kindOf(DateTime day, DateTime today) {
    if (periodOn(day, today) != null) return DayKind.period;
    for (final w in windows) {
      if (w.predicted && w.inPeriod(day) && !dayOnly(day).isBefore(dayOnly(today))) {
        return DayKind.predictedPeriod;
      }
      if (w.isOvulation(day)) return DayKind.ovulation;
      if (w.inFertile(day)) return DayKind.fertile;
    }
    return DayKind.none;
  }

  @override
  List<Object?> get props => [
        averageCycleLength, averagePeriodLength, lastPeriodStart,
        nextPeriodStart, daysUntilNextPeriod, cycleDay, phase, windows, periods,
      ];
}

/// Period reminder preferences (sent as push notifications in the morning).
class CycleSettings extends Equatable {
  final bool periodReminders;
  final int remindDaysBefore;
  final bool fertileReminders;

  const CycleSettings({
    this.periodReminders = true,
    this.remindDaysBefore = 2,
    this.fertileReminders = false,
  });

  CycleSettings copyWith(
          {bool? periodReminders, int? remindDaysBefore, bool? fertileReminders}) =>
      CycleSettings(
        periodReminders: periodReminders ?? this.periodReminders,
        remindDaysBefore: remindDaysBefore ?? this.remindDaysBefore,
        fertileReminders: fertileReminders ?? this.fertileReminders,
      );

  @override
  List<Object?> get props => [periodReminders, remindDaysBefore, fertileReminders];
}

/// Plain-language description of a cycle phase.
class CyclePhaseInfo {
  final String title;
  final String description;
  const CyclePhaseInfo(this.title, this.description);

  static CyclePhaseInfo? of(String? phase) => switch (phase) {
        'menstrual' => const CyclePhaseInfo('Period',
            'Rest, stay hydrated and use heat for cramps if needed.'),
        'follicular' => const CyclePhaseInfo('Follicular phase',
            'Energy often rises after your period. A good time for exercise.'),
        'fertile' => const CyclePhaseInfo('Fertile window',
            'Higher chance of pregnancy over the next few days.'),
        'ovulation' => const CyclePhaseInfo('Ovulation day',
            'Your most fertile day. Some people feel mild one-sided pain.'),
        'luteal' => const CyclePhaseInfo('Luteal phase',
            'PMS signs like bloating, cravings or mood changes are common now.'),
        _ => null,
      };
}

// ---- pregnancy ---------------------------------------------------------------

class Pregnancy extends Equatable {
  final String id;
  final DateTime lastPeriodDate;
  final DateTime dueDate;
  final String? notes;
  final int weeks;
  final int days;
  final int trimester;
  final int daysRemaining;
  final double percentComplete;
  final String? babySize;
  final String tip;

  const Pregnancy({
    required this.id,
    required this.lastPeriodDate,
    required this.dueDate,
    this.notes,
    required this.weeks,
    required this.days,
    required this.trimester,
    required this.daysRemaining,
    required this.percentComplete,
    this.babySize,
    required this.tip,
  });

  /// Gestational age on [day] as (weeks, days).
  (int, int) ageOn(DateTime day) {
    final total = dayOnly(day).difference(dayOnly(lastPeriodDate)).inDays;
    final clamped = total < 0 ? 0 : total;
    return (clamped ~/ 7, clamped % 7);
  }

  DateTime get secondTrimesterStart =>
      dayOnly(lastPeriodDate).add(const Duration(days: 13 * 7));
  DateTime get thirdTrimesterStart =>
      dayOnly(lastPeriodDate).add(const Duration(days: 27 * 7));

  @override
  List<Object?> get props => [
        id, lastPeriodDate, dueDate, notes, weeks, days, trimester,
        daysRemaining, percentComplete, babySize, tip,
      ];
}

// ---- repository -------------------------------------------------------------

abstract class WomensHealthRepository {
  Future<Either<Failure, CycleOverview>> getCycleOverview();
  Future<Either<Failure, Period>> savePeriod({
    String? id,
    required DateTime start,
    DateTime? end,
    PeriodFlow? flow,
    String? notes,
  });
  Future<Either<Failure, Unit>> deletePeriod(String id);
  Future<Either<Failure, CycleSettings>> getSettings();
  Future<Either<Failure, CycleSettings>> saveSettings(CycleSettings settings);

  /// Right(null) when no pregnancy is being tracked.
  Future<Either<Failure, Pregnancy?>> getPregnancy();

  /// Give exactly one of [lastPeriodDate] and [dueDate].
  Future<Either<Failure, Pregnancy>> savePregnancy(
      {DateTime? lastPeriodDate, DateTime? dueDate, String? notes});
  Future<Either<Failure, Unit>> deletePregnancy();
}
