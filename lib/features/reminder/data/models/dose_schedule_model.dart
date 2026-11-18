import '../../domain/entities/dose.dart';

/// JSON mapping for the API's DoseScheduleResponse.
class DoseScheduleModel {
  DoseScheduleModel._();

  static DoseSchedule fromJson(Map<String, dynamic> json) {
    final s = json['summary'] as Map<String, dynamic>;
    return DoseSchedule(
      summary: AdherenceSummary(
        total: s['total'] as int,
        taken: s['taken'] as int,
        skipped: s['skipped'] as int,
        missed: s['missed'] as int,
        due: s['due'] as int,
        upcoming: s['upcoming'] as int,
        adherencePercent: (s['adherence_percent'] as num?)?.toDouble(),
      ),
      doses: (json['doses'] as List)
          .map((d) => _doseFromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }

  static ScheduledDose _doseFromJson(Map<String, dynamic> json) {
    final respondedAt = json['responded_at'];
    return ScheduledDose(
      doseKey: json['dose_key'] as String,
      medicationId: json['medication_id'].toString(),
      medicationName: json['medication_name'] as String,
      medicineType: json['medicine_type'] as String,
      dose: json['dose'] as String,
      intakeTiming: json['intake_timing'] as String,
      instructions: json['instructions'] as String?,
      scheduledFor: DateTime.parse(json['scheduled_for'] as String),
      localDate: json['local_date'] as String,
      localTime: json['local_time'] as String,
      status: DoseStatus.fromApi(json['status'] as String),
      respondedAt:
          respondedAt is String ? DateTime.tryParse(respondedAt) : null,
      photoUrl: json['photo_url'] as String?,
    );
  }
}
