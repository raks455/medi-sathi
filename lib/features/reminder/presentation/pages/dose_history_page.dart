import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/dose.dart';
import '../bloc/dose_history_bloc.dart';
import '../widgets/adherence_card.dart';
import '../widgets/dose_tile.dart';

/// Past doses and adherence for the last 7 or 30 days.
class DoseHistoryPage extends StatelessWidget {
  const DoseHistoryPage({super.key});

  static const _ranges = [7, 30]; // the API allows at most 31 days
  // Made when used, so it follows a change of language.
  static DateFormat get _dayFormat => DateFormat('EEEE, d MMM');

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DoseHistoryBloc, DoseHistoryState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text('History'.tr,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    for (final days in _ranges)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('Last {n} days'.trArgs({'n': days})),
                          selected: state.days == days,
                          showCheckmark: false,
                          onSelected: (_) => context
                              .read<DoseHistoryBloc>()
                              .add(HistoryRequested(days)),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(child: _buildBody(context, state)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, DoseHistoryState state) {
    // Data from an earlier load stays visible during (and after a failed)
    // refresh.
    final status =
        state.schedule != null ? HistoryStatus.success : state.status;
    switch (status) {
      case HistoryStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case HistoryStatus.failure:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded,
                    size: 44, color: AppColors.primary),
                const SizedBox(height: 12),
                Text(
                  state.message ?? 'Could not load your history.'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                TextButton(
                  onPressed: () => context
                      .read<DoseHistoryBloc>()
                      .add(HistoryRequested(state.days)),
                  child: Text('Try again'.tr),
                ),
              ],
            ),
          ),
        );
      case HistoryStatus.success:
        final schedule = state.schedule!;
        // Newest day first; within a day the API's time order is kept.
        final byDay = <String, List<ScheduledDose>>{};
        for (final d in schedule.doses) {
          byDay.putIfAbsent(d.localDate, () => []).add(d);
        }
        final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            AdherenceCard(
              title: 'Last {n} days'.trArgs({'n': state.days}),
              summary: schedule.summary,
            ),
            if (days.isEmpty)
              Padding(
                padding: EdgeInsets.only(top: 40),
                child: Text(
                  'No scheduled doses in this period.'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            for (final day in days) ...[
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 10),
                child: Text(
                  _dayLabel(day),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              for (final d in byDay[day]!)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: DoseTile(key: ValueKey(d.doseKey), dose: d),
                ),
            ],
          ],
        );
    }
  }

  static String _dayLabel(String localDate) {
    final date = DateTime.tryParse(localDate);
    return date == null ? localDate : _dayFormat.format(date);
  }
}
