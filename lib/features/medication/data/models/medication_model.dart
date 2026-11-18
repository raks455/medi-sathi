import '../../domain/entities/medication.dart';

/// JSON mapping for the API's MedicationResponse / MedicationCreateRequest /
/// MedicationUpdateRequest and the /medications/options payload.
class MedicationModel {
  MedicationModel._();

  static Medication fromJson(Map<String, dynamic> json) {
    final schedule = json['schedule'];
    final inventory = json['inventory'];
    return Medication(
      id: json['id'].toString(),
      name: json['name'] as String,
      medicineType: json['medicine_type'] as String,
      dose: json['dose'] as String,
      intakeTiming: json['intake_timing'] as String,
      instructions: json['instructions'] as String?,
      schedule: schedule is Map<String, dynamic>
          ? _scheduleFromJson(schedule)
          : null,
      inventory: inventory is Map<String, dynamic>
          ? _inventoryFromJson(inventory)
          : null,
      isStopped: json['is_stopped'] as bool? ?? false,
      stoppedAt: _parseDate(json['stopped_at']),
      photoUrl: json['photo_url'] as String?,
    );
  }

  static MedicationOptions optionsFromJson(Map<String, dynamic> json) {
    return MedicationOptions(
      medicineTypes: (json['medicine_types'] as List).cast<String>(),
      intakeTimings: (json['intake_timings'] as List).cast<String>(),
    );
  }

  /// Request body for both create (POST) and update (PATCH).
  /// `schedule`, `inventory` and `instructions` are always sent, so on update
  /// an explicit null removes the schedule / stock tracking / instructions.
  ///
  /// [deviceTimezone] is used for a schedule that has no timezone yet.
  static Map<String, dynamic> toJson(MedicationInput input,
          {String? deviceTimezone}) =>
      {
        'name': input.name,
        'medicine_type': input.medicineType,
        'dose': input.dose,
        'intake_timing': input.intakeTiming,
        'instructions': input.instructions,
        'schedule': input.schedule == null
            ? null
            : _scheduleToJson(input.schedule!, deviceTimezone),
        'inventory': input.inventory == null
            ? null
            : _inventoryToJson(input.inventory!),
      };

  static MedicationSchedule _scheduleFromJson(Map<String, dynamic> json) {
    return MedicationSchedule(
      // The API sends 'HH:MM'; tolerate 'HH:MM:SS' too.
      reminderTimes: (json['reminder_times'] as List)
          .map((t) => t.toString())
          .map((t) => t.length > 5 ? t.substring(0, 5) : t)
          .toList(),
      timezone: json['timezone'] as String?,
      daysOfWeek: (json['days_of_week'] as List?)?.cast<int>(),
      startDate: _parseDate(json['start_date']),
      endDate: _parseDate(json['end_date']),
      remindersEnabled: json['reminders_enabled'] as bool? ?? true,
      alertStyle: json['alert_style'] as String? ?? AlertStyle.notification,
    );
  }

  static Map<String, dynamic> _scheduleToJson(
          MedicationSchedule s, String? deviceTimezone) =>
      {
        'reminder_times': s.reminderTimes,
        // Omitted when unknown so the server applies its default timezone.
        if ((s.timezone ?? deviceTimezone) != null)
          'timezone': s.timezone ?? deviceTimezone,
        'days_of_week': s.daysOfWeek,
        'start_date': _formatDate(s.startDate),
        'end_date': _formatDate(s.endDate),
        'reminders_enabled': s.remindersEnabled,
        'alert_style': s.alertStyle,
      };

  static MedicationInventory _inventoryFromJson(Map<String, dynamic> json) {
    return MedicationInventory(
      quantity: (json['quantity'] as num).toDouble(),
      unitsPerDose: (json['units_per_dose'] as num?)?.toDouble() ?? 1,
      refillReminderEnabled: json['refill_reminder_enabled'] as bool? ?? true,
      remindDaysBefore: json['remind_days_before'] as int? ?? 3,
      dosesLeft: json['doses_left'] as int? ?? 0,
      runsOutOn: _parseDate(json['runs_out_on']),
      daysLeft: json['days_left'] as int?,
      lowStock: json['low_stock'] as bool? ?? false,
    );
  }

  /// Only the settings: the forecast fields are calculated by the server.
  static Map<String, dynamic> _inventoryToJson(MedicationInventory i) => {
        'quantity': i.quantity,
        'units_per_dose': i.unitsPerDose,
        'refill_reminder_enabled': i.refillReminderEnabled,
        'remind_days_before': i.remindDaysBefore,
      };

  static DateTime? _parseDate(dynamic v) =>
      v is String ? DateTime.tryParse(v) : null;

  static String? _formatDate(DateTime? d) {
    if (d == null) return null;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';
  }
}
