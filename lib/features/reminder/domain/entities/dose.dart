import 'package:equatable/equatable.dart';

/// Status the API reports for a scheduled dose.
enum DoseStatus {
  upcoming,
  due, // time has passed but still within the grace window
  missed,
  taken,
  skipped;

  static DoseStatus fromApi(String value) => DoseStatus.values.firstWhere(
        (s) => s.name == value,
        orElse: () => DoseStatus.upcoming,
      );

  /// The user has answered this dose.
  bool get isAnswered => this == taken || this == skipped;
}

/// One dose of one medicine at one time.
class ScheduledDose extends Equatable {
  /// Unique per dose; the server uses it as the push notification tag.
  final String doseKey;
  final String medicationId;
  final String medicationName;
  final String medicineType;
  final String dose;
  final String intakeTiming;
  final String? instructions;

  /// Exact time of the dose (UTC).
  final DateTime scheduledFor;

  /// Date ('yyyy-MM-dd') and time ('HH:mm') in the schedule's timezone.
  final String localDate;
  final String localTime;
  final DoseStatus status;
  final DateTime? respondedAt;

  /// The user's photo of the medicine, if they added one.
  final String? photoUrl;

  const ScheduledDose({
    required this.doseKey,
    required this.medicationId,
    required this.medicationName,
    required this.medicineType,
    required this.dose,
    required this.intakeTiming,
    this.instructions,
    required this.scheduledFor,
    required this.localDate,
    required this.localTime,
    required this.status,
    this.respondedAt,
    this.photoUrl,
  });

  ScheduledDose withStatus(DoseStatus status, DateTime? respondedAt) {
    return ScheduledDose(
      doseKey: doseKey,
      medicationId: medicationId,
      medicationName: medicationName,
      medicineType: medicineType,
      dose: dose,
      intakeTiming: intakeTiming,
      instructions: instructions,
      scheduledFor: scheduledFor,
      localDate: localDate,
      localTime: localTime,
      status: status,
      respondedAt: respondedAt,
      photoUrl: photoUrl,
    );
  }

  @override
  List<Object?> get props =>
      [doseKey, status, respondedAt, medicationName, dose, photoUrl];
}

class AdherenceSummary extends Equatable {
  final int total;
  final int taken;
  final int skipped;
  final int missed;
  final int due;
  final int upcoming;

  /// taken / (taken + skipped + missed); null if nothing is past yet.
  final double? adherencePercent;

  const AdherenceSummary({
    required this.total,
    required this.taken,
    required this.skipped,
    required this.missed,
    required this.due,
    required this.upcoming,
    this.adherencePercent,
  });

  /// Same calculation as the server, for after a dose is marked locally.
  factory AdherenceSummary.fromDoses(List<ScheduledDose> doses) {
    int count(DoseStatus s) => doses.where((d) => d.status == s).length;
    final taken = count(DoseStatus.taken);
    final skipped = count(DoseStatus.skipped);
    final missed = count(DoseStatus.missed);
    final past = taken + skipped + missed;
    return AdherenceSummary(
      total: doses.length,
      taken: taken,
      skipped: skipped,
      missed: missed,
      due: count(DoseStatus.due),
      upcoming: count(DoseStatus.upcoming),
      adherencePercent:
          past == 0 ? null : (1000 * taken / past).round() / 10,
    );
  }

  @override
  List<Object?> get props =>
      [total, taken, skipped, missed, due, upcoming, adherencePercent];
}

/// Doses for a date range, with their adherence summary.
class DoseSchedule extends Equatable {
  final AdherenceSummary summary;
  final List<ScheduledDose> doses;

  const DoseSchedule({required this.summary, required this.doses});

  /// A copy with one dose replaced and the summary recalculated.
  DoseSchedule withDose(ScheduledDose updated) {
    final next = [
      for (final d in doses) d.doseKey == updated.doseKey ? updated : d,
    ];
    return DoseSchedule(
        summary: AdherenceSummary.fromDoses(next), doses: next);
  }

  @override
  List<Object?> get props => [summary, doses];
}
