import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/medication.dart';

/// Display helpers for the API's medicine values.
class MedicationFormat {
  MedicationFormat._();

  /// English; shown with `.tr`.
  static const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// 'before_food' -> 'Before food', in the app's language.
  static String label(String apiValue) => englishLabel(apiValue).tr;

  /// 'before_food' -> 'Before food', always in English (for the PDF).
  static String englishLabel(String apiValue) {
    final text = apiValue.replaceAll('_', ' ').trim();
    return text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
  }

  /// The word on the button that marks a dose as taken. English says "Take"
  /// for every medicine; in Nepali a tablet is eaten, a cream is applied and
  /// drops are put in.
  static String takeLabel(String medicineType) {
    if (!L10n.isNepali) return 'Take';
    switch (medicineType) {
      case 'tablet':
      case 'capsule':
      case 'syrup':
      case 'powder':
        return 'Take'.tr;
      case 'cream':
      case 'ointment':
      case 'gel':
      case 'patch':
      case 'injection':
        return 'Take (apply)'.tr;
      case 'drops':
        return 'Take (drops)'.tr;
      default:
        return 'Take (other)'.tr;
    }
  }

  static IconData typeIcon(String medicineType) {
    switch (medicineType) {
      case 'syrup':
        return Icons.local_drink_outlined;
      case 'injection':
        return Icons.vaccines_outlined;
      case 'cream':
      case 'ointment':
      case 'gel':
        return Icons.sanitizer_outlined;
      case 'drops':
        return Icons.water_drop_outlined;
      case 'inhaler':
      case 'spray':
        return Icons.air_rounded;
      case 'patch':
        return Icons.healing_outlined;
      case 'tablet':
      case 'capsule':
        return Icons.medication_outlined;
      default:
        return Icons.medical_services_outlined;
    }
  }

  /// 'HH:mm' -> TimeOfDay (null if malformed).
  static TimeOfDay? parseTime(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }
    return TimeOfDay(hour: h, minute: m);
  }

  /// TimeOfDay -> 'HH:mm' as the API expects.
  static String apiTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// 'HH:mm' -> the device's preferred format, e.g. '8:00 AM'.
  static String displayTime(BuildContext context, String hhmm) {
    final t = parseTime(hhmm);
    return t == null
        ? hhmm
        : MaterialLocalizations.of(context).formatTimeOfDay(t);
  }

  static String daysLabel(List<int>? daysOfWeek) {
    if (daysOfWeek == null || daysOfWeek.length == 7) return 'Every day'.tr;
    return daysOfWeek
        .where((d) => d >= 0 && d < 7)
        .map((d) => dayNames[d].tr)
        .join(', ');
  }

  /// One-line summary: '8:00 AM, 8:00 PM · Every day' or 'As needed'.
  static String scheduleSummary(
      BuildContext context, MedicationSchedule? schedule) {
    if (schedule == null) return 'As needed'.tr;
    final times =
        schedule.reminderTimes.map((t) => displayTime(context, t)).join(', ');
    return '$times · ${daysLabel(schedule.daysOfWeek)}';
  }

  /// 30.0 -> '30', 2.5 -> '2.5'.
  static String amount(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');

  /// When the stock runs out: 'runs out today', 'runs out tomorrow',
  /// 'lasts 6 days'. Null when the server could not estimate it.
  static String? runsOutLabel(MedicationInventory inventory) {
    final days = inventory.daysLeft;
    if (days == null) return null;
    if (days <= 0) return 'runs out today'.tr;
    if (days == 1) return 'runs out tomorrow'.tr;
    return 'lasts {n} days'.trArgs({'n': days});
  }

  static String doses(int n) =>
      n == 1 ? '1 dose'.tr : '{n} doses'.trArgs({'n': n});

  /// Full doses the stock covers.
  static int dosesInStock(MedicationInventory inventory) =>
      inventory.unitsPerDose <= 0
          ? 0
          : (inventory.quantity / inventory.unitsPerDose + 1e-9).floor();

  /// One-line stock summary: '12 doses left · lasts 6 days', or with more
  /// than one unit per dose '24 left (12 doses) · lasts 6 days'.
  static String stockSummary(MedicationInventory inventory) {
    final n = dosesInStock(inventory);
    final left = inventory.unitsPerDose == 1
        ? '{doses} left'.trArgs({'doses': doses(n)})
        : '{amount} left ({doses})'.trArgs(
            {'amount': amount(inventory.quantity), 'doses': doses(n)});
    final runsOut = runsOutLabel(inventory);
    return runsOut == null ? left : '$left · $runsOut';
  }

  /// "Today: 1 of 2 doses left" / "Today: 2 of 2 taken". Null when nothing
  /// is scheduled today.
  static String? todaySummary({required int total, required int left, required int taken}) {
    if (total == 0) return null;
    if (left > 0) {
      return 'Today: {left} of {doses} left'
          .trArgs({'left': left, 'doses': doses(total)});
    }
    return 'Today: {taken} of {total} taken'
        .trArgs({'taken': taken, 'total': total});
  }

  /// Doses still to come in a course with an end date, counting today's
  /// remaining ones ([todayLeft], or times not yet passed when unknown).
  /// Null for courses without an end date or as-needed medicines.
  static int? courseDosesLeft(MedicationSchedule schedule,
      {required DateTime now, int? todayLeft}) {
    final end = schedule.endDate;
    if (end == null || schedule.reminderTimes.isEmpty) return null;
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(end.year, end.month, end.day);
    if (lastDay.isBefore(today)) return 0;

    bool scheduledOn(DateTime d) {
      final days = schedule.daysOfWeek;
      if (days != null && !days.contains(d.weekday - 1)) return false;
      final start = schedule.startDate;
      return start == null ||
          !d.isBefore(DateTime(start.year, start.month, start.day));
    }

    final perDay = schedule.reminderTimes.length;
    var count = 0;
    if (scheduledOn(today)) {
      count += todayLeft ??
          schedule.reminderTimes.where((t) {
            final parts = t.split(':');
            final at = DateTime(now.year, now.month, now.day,
                int.parse(parts[0]), int.parse(parts[1]));
            return at.isAfter(now);
          }).length;
    }
    for (var d = today.add(const Duration(days: 1));
        !d.isAfter(lastDay);
        d = DateTime(d.year, d.month, d.day + 1)) {
      if (scheduledOn(d)) count += perDay;
    }
    return count;
  }
}
