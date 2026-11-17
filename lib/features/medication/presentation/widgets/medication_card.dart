import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/medication.dart';
import '../utils/medication_format.dart';

class MedicationCard extends StatelessWidget {
  final Medication medication;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// Stops an active medicine / resumes a stopped one.
  final VoidCallback onToggleStopped;

  /// Opens the "add stock" dialog. Only offered when stock is tracked.
  final VoidCallback onRefill;

  const MedicationCard({
    super.key,
    required this.medication,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStopped,
    required this.onRefill,
  });

  @override
  Widget build(BuildContext context) {
    final m = medication;
    final schedule = m.schedule;
    final inventory = m.inventory;
    final stopped = m.isStopped;
    final remindersOff = schedule != null && !schedule.remindersEnabled;
    final alarm = schedule != null &&
        schedule.remindersEnabled &&
        schedule.alertStyle == AlertStyle.alarm;

    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.tertiary, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.tertiaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  MedicationFormat.typeIcon(m.medicineType),
                  color: stopped ? AppColors.textSecondary : AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: stopped
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${m.dose} · ${MedicationFormat.label(m.medicineType)}'
                      ' · ${MedicationFormat.label(m.intakeTiming)}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    if (stopped)
                      const _InfoRow(
                        icon: Icons.pause_circle_outline_rounded,
                        text: 'Stopped · no doses or reminders',
                      )
                    else
                      _InfoRow(
                        icon: remindersOff
                            ? Icons.notifications_off_outlined
                            : alarm
                                ? Icons.alarm_rounded
                                : Icons.schedule_rounded,
                        text: MedicationFormat.scheduleSummary(
                                context, schedule) +
                            (remindersOff
                                ? ' · Reminders off'
                                : alarm
                                    ? ' · Alarm'
                                    : ''),
                      ),
                    if (inventory != null) ...[
                      const SizedBox(height: 4),
                      _InfoRow(
                        icon: Icons.inventory_2_outlined,
                        text: MedicationFormat.stockSummary(inventory) +
                            (inventory.lowStock ? ' · Refill soon' : ''),
                        // Low stock stands out; a stopped medicine needs none.
                        color: inventory.lowStock && !stopped
                            ? AppColors.error
                            : null,
                      ),
                    ],
                    if (m.instructions != null && m.instructions!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _InfoRow(
                        icon: Icons.notes_rounded,
                        text: m.instructions!,
                        maxLines: 2,
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<VoidCallback>(
                tooltip: 'More',
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppColors.textSecondary),
                onSelected: (action) => action(),
                // `_`: none of the callbacks use the menu's own context.
                itemBuilder: (_) => [
                  PopupMenuItem(value: onEdit, child: const Text('Edit')),
                  if (inventory != null)
                    PopupMenuItem(
                        value: onRefill, child: const Text('Add stock')),
                  PopupMenuItem(
                    value: onToggleStopped,
                    child: Text(stopped ? 'Resume medicine' : 'Stop medicine'),
                  ),
                  PopupMenuItem(
                    value: onDelete,
                    child: const Text('Delete',
                        style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final int maxLines;

  /// Text and icon colour; null uses the normal colours.
  final Color? color;

  const _InfoRow({
    required this.icon,
    required this.text,
    this.maxLines = 3,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 16, color: color ?? AppColors.icon),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: color == null ? FontWeight.w400 : FontWeight.w600,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
