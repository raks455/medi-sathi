import 'package:equatable/equatable.dart';

/// Where the picture to scan comes from.
enum ScanSource { camera, gallery }

/// A medicine read from a photo of a prescription or label.
/// Everything except the name is a best guess (or missing), so it must be
/// reviewed in the add-medicine form before it is saved.
class ScannedMedicine extends Equatable {
  final String name;

  /// API values (e.g. 'tablet', 'after_food'); null when not recognised.
  final String? medicineType;
  final String? dose;
  final String? intakeTiming;

  /// Suggested reminder times in 'HH:mm'; empty when no frequency was found.
  final List<String> reminderTimes;

  /// True when the text says "as needed" (SOS / PRN): no schedule.
  final bool asNeeded;

  /// Length of the course in days, when written (e.g. "x 5 days").
  final int? durationDays;

  /// The line(s) of text this was read from, shown so the user can compare.
  final String sourceText;

  const ScannedMedicine({
    required this.name,
    this.medicineType,
    this.dose,
    this.intakeTiming,
    this.reminderTimes = const [],
    this.asNeeded = false,
    this.durationDays,
    required this.sourceText,
  });

  @override
  List<Object?> get props => [
        name,
        medicineType,
        dose,
        intakeTiming,
        reminderTimes,
        asNeeded,
        durationDays,
        sourceText,
      ];
}
