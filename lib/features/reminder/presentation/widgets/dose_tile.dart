import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../medication/presentation/utils/medication_format.dart';
import '../../../medication/presentation/widgets/medicine_avatar.dart';
import '../../domain/entities/dose.dart';

/// One scheduled dose. With [onMark] it shows Take / Skip actions;
/// without it the tile is read-only (history).
class DoseTile extends StatelessWidget {
  final ScheduledDose dose;
  final bool isSaving;
  final void Function(DoseStatus status)? onMark;

  /// Opens the medicine's details (photo, how to take it, side effects).
  final VoidCallback? onOpen;

  const DoseTile({
    super.key,
    required this.dose,
    this.isSaving = false,
    this.onMark,
    this.onOpen,
  });

  static (String, Color) _statusStyle(DoseStatus status) => switch (status) {
        DoseStatus.taken => ('Taken'.tr, AppColors.success),
        DoseStatus.skipped => ('Skipped'.tr, AppColors.textSecondary),
        DoseStatus.missed => ('Missed'.tr, AppColors.error),
        DoseStatus.due => ('Due now'.tr, AppColors.warning),
        DoseStatus.upcoming => ('Upcoming'.tr, AppColors.secondary),
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
              // A big picture: for many users it says more than the name.
              GestureDetector(
                onTap: onOpen,
                child: MedicineAvatar(
                  medicineType: d.medicineType,
                  photoUrl: d.photoUrl,
                  size: d.photoUrl == null ? 44 : 60,
                ),
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
                      style: TextStyle(
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
                      style: TextStyle(color: AppColors.textSecondary),
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
        child: Text('Change to skipped'.tr),
      );
    }
    if (dose.status == DoseStatus.skipped) {
      return TextButton(
        onPressed: () => onMark!(DoseStatus.taken),
        child: Text('Change to taken'.tr),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary),
          onPressed: () => onMark!(DoseStatus.skipped),
          child: Text('Skip'.tr),
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
          label: Text(MedicationFormat.takeLabel(dose.medicineType)),
        ),
      ],
    );
  }
}
