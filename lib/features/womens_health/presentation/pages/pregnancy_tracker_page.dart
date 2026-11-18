import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/info_widgets.dart';
import '../../domain/womens_health.dart';
import '../cubit/womens_health_cubits.dart';

const _accent = Color(0xFF9C6ADE);

/// Pregnancy tracker: week-by-week progress, due date countdown and a
/// calendar showing how far along you are on any day.
class PregnancyTrackerPage extends StatelessWidget {
  const PregnancyTrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pregnancy tracker',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          BlocBuilder<PregnancyCubit, PregnancyState>(
            builder: (context, state) => state.pregnancy == null
                ? const SizedBox.shrink()
                : PopupMenuButton<String>(
                    tooltip: 'More',
                    onSelected: (v) => v == 'edit'
                        ? _showSetup(context, state.pregnancy)
                        : _confirmStop(context),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Change dates')),
                      PopupMenuItem(
                          value: 'stop', child: Text('Stop tracking')),
                    ],
                  ),
          ),
        ],
      ),
      body: BlocBuilder<PregnancyCubit, PregnancyState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final p = state.pregnancy;
          return RefreshIndicator(
            onRefresh: context.read<PregnancyCubit>().load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              children: [
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(state.error!,
                        style: const TextStyle(color: AppColors.error)),
                  ),
                if (p == null)
                  _Empty(onStart: () => _showSetup(context, null))
                else ...[
                  _ProgressCard(pregnancy: p),
                  const SizedBox(height: 16),
                  _TipCard(pregnancy: p),
                  const SectionLabel('Calendar'),
                  _PregnancyCalendar(pregnancy: p),
                  const SizedBox(height: 16),
                  Text(
                    'Dates are estimated from your last period (40 weeks). '
                    'Your doctor may adjust them after an ultrasound.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  static Future<void> _showSetup(BuildContext context, Pregnancy? current) async {
    final cubit = context.read<PregnancyCubit>();
    final result = await showModalBottomSheet<(DateTime, bool)>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _SetupSheet(current: current),
    );
    if (result == null) return;
    final (date, isDueDate) = result;
    final error = await cubit.save(
      lastPeriodDate: isDueDate ? null : date,
      dueDate: isDueDate ? date : null,
    );
    if (context.mounted && error != null) {
      showInfoSnack(context, error, error: true);
    }
  }

  static Future<void> _confirmStop(BuildContext context) async {
    final cubit = context.read<PregnancyCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Stop tracking?'),
        content: const Text('Your pregnancy dates will be removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Stop tracking'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final error = await cubit.stop();
    if (context.mounted && error != null) {
      showInfoSnack(context, error, error: true);
    }
  }
}

class _Empty extends StatelessWidget {
  final VoidCallback onStart;
  const _Empty({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.pregnant_woman_rounded,
                size: 52, color: _accent),
          ),
          const SizedBox(height: 18),
          Text('Track your pregnancy',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 8),
          Text(
            'See how many weeks along you are, your due date, your baby\'s '
            'size each week and tips for every trimester.',
            textAlign: TextAlign.center,
            style: TextStyle(height: 1.45, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onStart,
            style: ElevatedButton.styleFrom(backgroundColor: _accent),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start tracking'),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final Pregnancy pregnancy;
  const _ProgressCard({required this.pregnancy});

  @override
  Widget build(BuildContext context) {
    final p = pregnancy;
    final remaining = p.daysRemaining;
    final countdown = remaining > 0
        ? '$remaining days to go'
        : remaining == 0
            ? 'Due today'
            : '${-remaining} days past due date';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9C6ADE), Color(0xFFDC9B9B)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: p.percentComplete / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  color: Colors.white,
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${p.weeks}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              height: 1)),
                      const Text('weeks',
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${p.weeks} weeks ${p.days} days',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Trimester ${p.trimester} · $countdown',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92))),
                const SizedBox(height: 8),
                Text('Due ${DateFormat.yMMMMd().format(p.dueDate)}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final Pregnancy pregnancy;
  const _TipCard({required this.pregnancy});

  @override
  Widget build(BuildContext context) {
    final p = pregnancy;
    return InfoCard(
      padding: const EdgeInsets.all(16),
      children: [
        if (p.babySize != null) ...[
          Row(children: [
            const Icon(Icons.child_care_rounded, color: _accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Your baby is about the size of ${p.babySize}',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ),
          ]),
          const SizedBox(height: 12),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lightbulb_outline_rounded,
                color: AppColors.warning),
            const SizedBox(width: 10),
            Expanded(
              child: Text(p.tip,
                  style: TextStyle(
                      height: 1.45, color: AppColors.textSecondary)),
            ),
          ],
        ),
      ],
    );
  }
}

class _PregnancyCalendar extends StatefulWidget {
  final Pregnancy pregnancy;
  const _PregnancyCalendar({required this.pregnancy});

  @override
  State<_PregnancyCalendar> createState() => _PregnancyCalendarState();
}

class _PregnancyCalendarState extends State<_PregnancyCalendar> {
  DateTime _focused = DateTime.now();
  DateTime _selected = dayOnly(DateTime.now());

  String? _milestone(DateTime day) {
    final p = widget.pregnancy;
    if (isSameDay(day, p.dueDate)) return 'Due date';
    if (isSameDay(day, p.secondTrimesterStart)) return 'Second trimester begins';
    if (isSameDay(day, p.thirdTrimesterStart)) return 'Third trimester begins';
    if (isSameDay(day, p.lastPeriodDate)) return 'First day of last period';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pregnancy;
    final first = dayOnly(p.lastPeriodDate);
    final last = dayOnly(p.dueDate).add(const Duration(days: 42));
    final focused = _focused.isBefore(first)
        ? first
        : _focused.isAfter(last)
            ? last
            : _focused;

    Widget cell(DateTime day, {bool selected = false, bool outside = false}) {
      final inRange = !day.isBefore(first) && !day.isAfter(dayOnly(p.dueDate));
      final milestone = _milestone(day) != null;
      final isToday = isSameDay(day, DateTime.now());
      final due = isSameDay(day, p.dueDate);
      return Center(
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: due
                ? _accent
                : milestone
                    ? _accent.withValues(alpha: 0.35)
                    : inRange
                        ? _accent.withValues(alpha: 0.08)
                        : null,
            border: selected
                ? Border.all(color: AppColors.textPrimary, width: 2)
                : isToday
                    ? Border.all(color: AppColors.primary, width: 1.5)
                    : null,
          ),
          child: Text('${day.day}',
              style: TextStyle(
                color: due
                    ? Colors.white
                    : outside
                        ? AppColors.textSecondary.withValues(alpha: 0.5)
                        : AppColors.textPrimary,
                fontWeight: isToday || due ? FontWeight.w800 : FontWeight.w500,
              )),
        ),
      );
    }

    final (w, d) = p.ageOn(_selected);
    final milestone = _milestone(_selected);
    final beforeStart = _selected.isBefore(first);

    return InfoCard(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 14),
      children: [
        TableCalendar<void>(
          firstDay: first,
          lastDay: last,
          focusedDay: focused,
          availableCalendarFormats: const {CalendarFormat.month: 'Month'},
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            leftChevronIcon: Icon(Icons.chevron_left_rounded,
                color: AppColors.textPrimary),
            rightChevronIcon: Icon(Icons.chevron_right_rounded,
                color: AppColors.textPrimary),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle:
                TextStyle(fontSize: 12, color: AppColors.textSecondary),
            weekendStyle:
                TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          rowHeight: 46,
          selectedDayPredicate: (day) => isSameDay(day, _selected),
          onDaySelected: (s, f) => setState(() {
            _selected = dayOnly(s);
            _focused = f;
          }),
          onPageChanged: (f) => _focused = f,
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (_, day, __) => cell(day),
            todayBuilder: (_, day, __) => cell(day),
            selectedBuilder: (_, day, __) => cell(day, selected: true),
            outsideBuilder: (_, day, __) => cell(day, outside: true),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            [
              DateFormat.yMMMMEEEEd().format(_selected),
              if (!beforeStart) '$w weeks $d days',
              if (milestone != null) milestone,
            ].join(' · '),
            textAlign: TextAlign.center,
            style: TextStyle(
                fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _SetupSheet extends StatefulWidget {
  final Pregnancy? current;
  const _SetupSheet({this.current});

  @override
  State<_SetupSheet> createState() => _SetupSheetState();
}

class _SetupSheetState extends State<_SetupSheet> {
  bool _byDueDate = false;
  late DateTime? _date = widget.current?.lastPeriodDate;

  Future<void> _pick() async {
    final today = dayOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ??
          (_byDueDate ? today.add(const Duration(days: 180)) : today),
      firstDate: _byDueDate
          ? today.subtract(const Duration(days: 42))
          : today.subtract(const Duration(days: 300)),
      lastDate: _byDueDate ? today.add(const Duration(days: 300)) : today,
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
              widget.current == null
                  ? 'Start pregnancy tracking'
                  : 'Change dates',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 14),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: _accent,
              selectedForegroundColor: Colors.white,
              foregroundColor: AppColors.textPrimary,
            ),
            segments: const [
              ButtonSegment(value: false, label: Text('Last period')),
              ButtonSegment(value: true, label: Text('Due date')),
            ],
            selected: {_byDueDate},
            onSelectionChanged: (s) => setState(() {
              _byDueDate = s.first;
              _date = null;
            }),
          ),
          const SizedBox(height: 12),
          Text(
            _byDueDate
                ? 'Use the due date your doctor gave you.'
                : 'The first day of your last menstrual period.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pick,
            style:
                OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            icon: const Icon(Icons.event_rounded),
            label: Text(_date == null
                ? 'Choose a date'
                : DateFormat.yMMMMd().format(_date!)),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _date == null
                ? null
                : () => Navigator.pop(context, (_date!, _byDueDate)),
            style: ElevatedButton.styleFrom(backgroundColor: _accent),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
