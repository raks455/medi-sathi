import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../medication/presentation/utils/medication_format.dart';
import '../../../medication/presentation/widgets/medicine_avatar.dart';
import '../../domain/entities/dose.dart';

/// How a dose went, for the dashboard chart.
enum DoseTiming {
  onTime('On time', Icons.check_circle_rounded),
  late('Taken late', Icons.watch_later_rounded),
  missed('Missed', Icons.cancel_rounded),
  skipped('Skipped', Icons.remove_circle_rounded),
  waiting('Still to take', Icons.radio_button_unchecked_rounded);

  /// English; shown with `.tr`.
  final String label;

  /// Every status has its own shape as well as its own colour, so the chart
  /// can be read without telling the colours apart.
  final IconData icon;
  const DoseTiming(this.label, this.icon);

  /// A dose counts as on time when it was marked taken within this long
  /// after its time (or before it).
  static const lateAfter = Duration(minutes: 30);

  static DoseTiming of(ScheduledDose dose) {
    switch (dose.status) {
      case DoseStatus.taken:
        final at = dose.respondedAt;
        return at != null && at.difference(dose.scheduledFor) > lateAfter
            ? DoseTiming.late
            : DoseTiming.onTime;
      case DoseStatus.missed:
        return DoseTiming.missed;
      case DoseStatus.skipped:
        return DoseTiming.skipped;
      case DoseStatus.due:
      case DoseStatus.upcoming:
        return DoseTiming.waiting;
    }
  }

  Color get color => switch (this) {
        DoseTiming.onTime => AppColors.success,
        DoseTiming.late => AppColors.warning,
        DoseTiming.missed => AppColors.error,
        DoseTiming.skipped => AppColors.textSecondary,
        DoseTiming.waiting => AppColors.tertiary,
      };

  /// Readable on top of [color].
  Color get onColor =>
      this == DoseTiming.waiting ? AppColors.textPrimary : Colors.white;
}

/// Dashboard card: how many of today's doses were taken on time, late or
/// missed, which ones need attention, and the same split for each of the
/// last 7 days.
class DoseTimingCard extends StatelessWidget {
  /// Today's doses.
  final List<ScheduledDose> today;

  /// Doses of recent days (any range that includes the last 7), or empty
  /// while they are not loaded.
  final List<ScheduledDose> recent;

  /// Opens a medicine's details.
  final void Function(ScheduledDose dose)? onOpen;

  const DoseTimingCard({
    super.key,
    required this.today,
    this.recent = const [],
    this.onOpen,
  });

  static Map<DoseTiming, int> _count(Iterable<ScheduledDose> doses) {
    final counts = {for (final t in DoseTiming.values) t: 0};
    for (final d in doses) {
      final t = DoseTiming.of(d);
      counts[t] = counts[t]! + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final counts = _count(today);
    final total = today.length;
    final onTime = counts[DoseTiming.onTime]!;
    final answered = total - counts[DoseTiming.waiting]!;

    // Late, missed, or waiting past their time: the ones to act on.
    final attention = [
      for (final d in today)
        if (d.status == DoseStatus.due ||
            DoseTiming.of(d) == DoseTiming.late ||
            DoseTiming.of(d) == DoseTiming.missed)
          d,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.tertiary, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's medicines".tr,
            style: TextStyle(
                fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            total == 0
                ? 'No doses scheduled'.tr
                : '{n} of {total} taken on time'
                    .trArgs({'n': onTime, 'total': total}),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          if (total > 0) ...[
            const SizedBox(height: 12),
            _SegmentedBar(counts: counts, height: 30),
            const SizedBox(height: 12),
            _Legend(counts: counts),
          ],
          if (attention.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Late or missed'.tr,
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            for (final d in attention)
              _AttentionRow(dose: d, onTap: onOpen == null ? null : () => onOpen!(d)),
          ] else if (total > 0 && answered > 0) ...[
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.thumb_up_alt_rounded,
                  size: 18, color: AppColors.success),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Nothing late or missed today. Well done!'.tr,
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ]),
          ],
          _WeekChart(recent: recent),
        ],
      ),
    );
  }
}

/// One whole (the doses) split into its parts, each part its own block with
/// its count printed on it where it fits.
class _SegmentedBar extends StatelessWidget {
  final Map<DoseTiming, int> counts;
  final double height;
  const _SegmentedBar({required this.counts, required this.height});

  @override
  Widget build(BuildContext context) {
    final parts = [
      for (final t in DoseTiming.values)
        if (counts[t]! > 0) t,
    ];
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            for (final (i, t) in parts.indexed) ...[
              // A gap in the card's own colour keeps neighbours apart.
              if (i > 0) const SizedBox(width: 2),
              Expanded(
                flex: counts[t]!,
                child: Tooltip(
                  message: '${t.label.tr}: ${counts[t]}',
                  triggerMode: TooltipTriggerMode.tap,
                  child: Container(
                    color: t.color,
                    alignment: Alignment.center,
                    child: LayoutBuilder(
                      builder: (context, box) => box.maxWidth < 18
                          ? const SizedBox.shrink()
                          : Text(
                              '${counts[t]}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: t.onColor,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Map<DoseTiming, int> counts;
  const _Legend({required this.counts});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: [
        for (final t in DoseTiming.values)
          // "Skipped" is rare: listed only when it happened.
          if (counts[t]! > 0 || t != DoseTiming.skipped)
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(t.icon,
                  size: 18,
                  color: t == DoseTiming.waiting
                      ? AppColors.textSecondary
                      : t.color),
              const SizedBox(width: 5),
              Text(
                '${t.label.tr} ',
                style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
              ),
              Text(
                '${counts[t]}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ]),
      ],
    );
  }
}

/// One dose that is late, was taken late, or was missed.
class _AttentionRow extends StatelessWidget {
  final ScheduledDose dose;
  final VoidCallback? onTap;
  const _AttentionRow({required this.dose, this.onTap});

  static String _duration(Duration d) {
    final minutes = d.inMinutes;
    if (minutes < 60) return '{n} min'.trArgs({'n': minutes});
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0
        ? '{h} h'.trArgs({'h': hours})
        : '{h} h {m} min'.trArgs({'h': hours, 'm': rest});
  }

  @override
  Widget build(BuildContext context) {
    final d = dose;
    final timing = DoseTiming.of(d);
    final (String text, Color color, IconData icon) = switch (timing) {
      DoseTiming.late => (
          'Taken {time} late'.trArgs({
            'time': _duration(d.respondedAt!.difference(d.scheduledFor)),
          }),
          AppColors.warning,
          timing.icon,
        ),
      DoseTiming.missed => ('Missed'.tr, AppColors.error, timing.icon),
      // Past its time but not answered yet.
      _ => (
          'Take it now · {time} late'.trArgs({
            'time': _duration(DateTime.now().difference(d.scheduledFor)),
          }),
          AppColors.warning,
          Icons.notifications_active_rounded,
        ),
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MedicineAvatar(
                medicineType: d.medicineType, photoUrl: d.photoUrl, size: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.medicationName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                  Text(
                    '${MedicationFormat.displayTime(context, d.localTime)}'
                    ' · ${d.dose}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  // Under the name, so neither is cut short on a narrow phone.
                  Row(children: [
                    Icon(icon, size: 16, color: color),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        text,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The last 7 days, one stacked bar per day on a shared scale.
class _WeekChart extends StatelessWidget {
  final List<ScheduledDose> recent;
  const _WeekChart({required this.recent});

  static const _barHeight = 64.0;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = [
      for (var i = 6; i >= 0; i--) DateTime(now.year, now.month, now.day - i),
    ];
    final key = DateFormat('yyyy-MM-dd', 'en');
    final byDay = <String, List<ScheduledDose>>{};
    for (final d in recent) {
      byDay.putIfAbsent(d.localDate, () => []).add(d);
    }
    final perDay = [
      for (final day in days)
        DoseTimingCard._count(byDay[key.format(day)] ?? const []),
    ];
    int total(Map<DoseTiming, int> c) => c.values.fold(0, (a, b) => a + b);
    final most = perDay.map(total).fold(0, (a, b) => a > b ? a : b);
    if (most == 0) return const SizedBox.shrink();

    const order = [
      DoseTiming.onTime,
      DoseTiming.late,
      DoseTiming.missed,
      DoseTiming.skipped,
      DoseTiming.waiting,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Divider(height: 1, color: AppColors.tertiary),
        const SizedBox(height: 12),
        Text(
          'Last 7 days'.tr,
          style: TextStyle(
              fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final (i, day) in days.indexed)
              Expanded(
                child: Tooltip(
                  triggerMode: TooltipTriggerMode.tap,
                  message: [
                    DateFormat.MMMEd().format(day),
                    for (final t in order)
                      if (perDay[i][t]! > 0) '${t.label.tr}: ${perDay[i][t]}',
                    if (total(perDay[i]) == 0) 'No doses scheduled'.tr,
                  ].join('\n'),
                  child: Column(
                    children: [
                      SizedBox(
                        height: _barHeight,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: _DayBar(
                            counts: perDay[i],
                            order: order,
                            height: _barHeight * total(perDay[i]) / most,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        i == 6 ? 'Today'.tr : DateFormat.E().format(day),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              i == 6 ? FontWeight.w700 : FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _DayBar extends StatelessWidget {
  final Map<DoseTiming, int> counts;
  final List<DoseTiming> order;
  final double height;
  const _DayBar({
    required this.counts,
    required this.order,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final parts = [
      for (final t in order)
        if (counts[t]! > 0) t,
    ];
    if (parts.isEmpty) {
      // A day with nothing scheduled still marks its place on the axis.
      return Container(width: 18, height: 2, color: AppColors.tertiary);
    }
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      child: SizedBox(
        width: 18,
        height: height,
        child: Column(
          // On time sits on the baseline, so its height compares across days.
          verticalDirection: VerticalDirection.up,
          children: [
            for (final (i, t) in parts.indexed) ...[
              if (i > 0) const SizedBox(height: 2),
              Expanded(flex: counts[t]!, child: Container(color: t.color)),
            ],
          ],
        ),
      ),
    );
  }
}
