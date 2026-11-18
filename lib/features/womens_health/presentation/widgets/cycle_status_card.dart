import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/womens_health.dart';
import '../cubit/womens_health_cubits.dart';

/// Profile card: which cycle phase you are in today and when the next period
/// is due. Tapping it opens the period tracker.
class CycleStatusCard extends StatelessWidget {
  final VoidCallback onOpen;
  const CycleStatusCard({super.key, required this.onOpen});

  static const _rose = Color(0xFFE5637A);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CycleCubit, CycleState>(
      builder: (context, state) {
        if (state.loading) return const SizedBox.shrink();
        final o = state.overview;
        final today = dayOnly(DateTime.now());

        String title;
        String body;
        String? footer;
        if (o.lastPeriodStart == null) {
          title = 'Know your cycle';
          body = 'Log your period to see which phase you are in and get a '
              'reminder before the next one.';
        } else {
          final current = o.periodOn(today, today);
          final info = CyclePhaseInfo.of(current != null ? 'menstrual' : o.phase);
          final day = current != null
              ? 'Period day ${today.difference(dayOnly(current.startDate)).inDays + 1}'
              : 'Cycle day ${o.cycleDay ?? '-'}';
          title = info == null ? day : '$day · ${info.title}';
          body = info?.description ?? '';
          final days = o.daysUntilNextPeriod;
          if (current == null && days != null && o.nextPeriodStart != null) {
            final date = DateFormat.MMMd().format(o.nextPeriodStart!);
            footer = days > 1
                ? 'Next period in $days days ($date)'
                : days == 1
                    ? 'Next period expected tomorrow'
                    : days == 0
                        ? 'Period expected today'
                        : 'Period ${-days} day${days == -1 ? '' : 's'} late';
          }
        }

        return Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.tertiary, width: 1.2),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _rose.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.water_drop_rounded, color: _rose),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            )),
                        if (body.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(body,
                              style: TextStyle(
                                  height: 1.4,
                                  color: AppColors.textSecondary)),
                        ],
                        if (footer != null) ...[
                          const SizedBox(height: 8),
                          Text(footer,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _rose,
                              )),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
