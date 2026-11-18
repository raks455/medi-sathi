import 'package:equatable/equatable.dart';

/// How a dose reminder alerts the user (API values).
class AlertStyle {
  AlertStyle._();

  /// Normal notification sound.
  static const notification = 'notification';

  /// Alarm sound at alarm volume with a stronger vibration.
  static const alarm = 'alarm';
}

/// When to take a medicine. A medicine without a schedule is "as needed".
class MedicationSchedule extends Equatable {
  /// Local times in 24h 'HH:mm', e.g. ['08:00', '20:00'].
  final List<String> reminderTimes;

  /// IANA timezone. Null lets the server use its default (Asia/Kathmandu).
  final String? timezone;

  /// 0 = Mon ... 6 = Sun. Null means every day.
  final List<int>? daysOfWeek;
  final DateTime? startDate;

  /// Last day of the course (inclusive).
  final DateTime? endDate;
  final bool remindersEnabled;

  /// One of [AlertStyle].
  final String alertStyle;

  const MedicationSchedule({
    required this.reminderTimes,
    this.timezone,
    this.daysOfWeek,
    this.startDate,
    this.endDate,
    this.remindersEnabled = true,
    this.alertStyle = AlertStyle.notification,
  });

  @override
  List<Object?> get props => [
        reminderTimes,
        timezone,
        daysOfWeek,
        startDate,
        endDate,
        remindersEnabled,
        alertStyle,
      ];
}

/// Stock of a medicine, counted in the user's own unit (tablets, ml ...).
class MedicationInventory extends Equatable {
  /// Units in stock now.
  final double quantity;

  /// Units used each time a dose is taken.
  final double unitsPerDose;
  final bool refillReminderEnabled;

  /// The refill reminder comes this many days before the stock runs out
  /// (and again on the day itself).
  final int remindDaysBefore;

  // ---- calculated by the server (ignored when saving) ----

  /// Full doses the stock still covers.
  final int dosesLeft;

  /// Estimated day the stock runs out; null when it cannot be estimated
  /// (no schedule, stopped, or enough for the whole course).
  final DateTime? runsOutOn;

  /// Days until [runsOutOn] (0 = today).
  final int? daysLeft;

  /// True once inside the refill-reminder window.
  final bool lowStock;

  const MedicationInventory({
    required this.quantity,
    this.unitsPerDose = 1,
    this.refillReminderEnabled = true,
    this.remindDaysBefore = 3,
    this.dosesLeft = 0,
    this.runsOutOn,
    this.daysLeft,
    this.lowStock = false,
  });

  /// The same settings with a different amount in stock (for a refill).
  MedicationInventory withQuantity(double quantity) => MedicationInventory(
        quantity: quantity,
        unitsPerDose: unitsPerDose,
        refillReminderEnabled: refillReminderEnabled,
        remindDaysBefore: remindDaysBefore,
      );

  @override
  List<Object?> get props => [
        quantity,
        unitsPerDose,
        refillReminderEnabled,
        remindDaysBefore,
        dosesLeft,
        runsOutOn,
        daysLeft,
        lowStock,
      ];
}

class Medication extends Equatable {
  final String id;
  final String name;

  /// API value such as 'tablet' (see [MedicationOptions.medicineTypes]).
  final String medicineType;
  final String dose;

  /// API value such as 'after_food' (see [MedicationOptions.intakeTimings]).
  final String intakeTiming;
  final String? instructions;
  final MedicationSchedule? schedule;

  /// Null when stock is not tracked.
  final MedicationInventory? inventory;

  /// A stopped medicine has no doses or reminders; its history is kept.
  final bool isStopped;
  final DateTime? stoppedAt;

  /// The user's photo of the medicine. A link that opens without signing in
  /// and changes whenever the photo does. Null when there is no photo.
  final String? photoUrl;

  const Medication({
    required this.id,
    required this.name,
    required this.medicineType,
    required this.dose,
    required this.intakeTiming,
    this.instructions,
    this.schedule,
    this.inventory,
    this.isStopped = false,
    this.stoppedAt,
    this.photoUrl,
  });

  /// The editable fields, e.g. to save this medicine with one thing changed.
  MedicationInput toInput({MedicationInventory? inventory}) => MedicationInput(
        name: name,
        medicineType: medicineType,
        dose: dose,
        intakeTiming: intakeTiming,
        instructions: instructions,
        schedule: schedule,
        inventory: inventory ?? this.inventory,
      );

  @override
  List<Object?> get props => [
        id,
        name,
        medicineType,
        dose,
        intakeTiming,
        instructions,
        schedule,
        inventory,
        isStopped,
        stoppedAt,
        photoUrl,
      ];
}

/// The editable fields of a medicine (what the add/edit form produces).
class MedicationInput extends Equatable {
  final String name;
  final String medicineType;
  final String dose;
  final String intakeTiming;
  final String? instructions;
  final MedicationSchedule? schedule;
  final MedicationInventory? inventory;

  const MedicationInput({
    required this.name,
    required this.medicineType,
    required this.dose,
    required this.intakeTiming,
    this.instructions,
    this.schedule,
    this.inventory,
  });

  @override
  List<Object?> get props =>
      [name, medicineType, dose, intakeTiming, instructions, schedule, inventory];
}

/// Allowed values for the type and intake-timing pickers.
class MedicationOptions extends Equatable {
  final List<String> medicineTypes;
  final List<String> intakeTimings;

  const MedicationOptions({
    required this.medicineTypes,
    required this.intakeTimings,
  });

  /// Used until (or if) GET /medications/options cannot be loaded.
  static const fallback = MedicationOptions(
    medicineTypes: [
      'tablet', 'capsule', 'syrup', 'injection', 'cream', 'ointment', 'gel',
      'drops', 'inhaler', 'spray', 'powder', 'patch', 'suppository', 'other',
    ],
    intakeTimings: [
      'before_food', 'after_food', 'with_food', 'empty_stomach',
      'before_sleep', 'anytime',
    ],
  );

  @override
  List<Object?> get props => [medicineTypes, intakeTimings];
}
