import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../medication/presentation/utils/medication_format.dart';
import '../../domain/entities/dose.dart';

/// One scheduled dose. With [onMark] it shows Take / Skip actions;
/// without it the tile is read-only (history).
class DoseTile extends StatelessWidget {
  final ScheduledDose dose;
  final bool isSaving;
  final void Function(DoseStatus status)? onMark;

  const DoseTile({
    super.key,
    required this.dose,
    this.isSaving = false,
    this.onMark,
  });

  static (String, Color) _statusStyle(DoseStatus status) => switch (status) {
        DoseStatus.taken => ('Taken', AppColors.success),
        DoseStatus.skipped => ('Skipped', AppColors.textSecondary),
        DoseStatus.missed => ('Missed', AppColors.error),
        DoseStatus.due => ('Due now', AppColors.warning),
        DoseStatus.upcoming => ('Upcoming', AppColors.secondary),
      };

  @override
  Widget build(BuildContext context) {
    final d = dose;
    final (statusLabel, statusColor) = _statusStyle(d.status);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.tertiary, width: 1.2),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.tertiaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(MedicationFormat.typeIcon(d.medicineType),
                    color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.medicationName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${MedicationFormat.displayTime(context, d.localTime)}'
                      ' · ${d.dose}'
                      ' · ${MedicationFormat.label(d.intakeTiming)}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (onMark != null)
            SizedBox(
              height: 44,
              child: Align(
                alignment: Alignment.centerRight,
                child: isSaving
                    ? const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      )
                    : _actions(),
              ),
            )
          else
            const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _actions() {
    // An answered dose can still be changed to the other answer.
    if (dose.status == DoseStatus.taken) {
      return TextButton(
        onPressed: () => onMark!(DoseStatus.skipped),
        child: const Text('Change to skipped'),
      );
    }
    if (dose.status == DoseStatus.skipped) {
      return TextButton(
        onPressed: () => onMark!(DoseStatus.taken),
        child: const Text('Change to taken'),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary),
          onPressed: () => onMark!(DoseStatus.skipped),
          child: const Text('Skip'),
        ),
        const SizedBox(width: 4),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => onMark!(DoseStatus.taken),
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text('Take'),
        ),
      ],
    );
  }
}
