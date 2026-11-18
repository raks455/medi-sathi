import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/info_widgets.dart';
import '../../domain/womens_health.dart';
import '../cubit/womens_health_cubits.dart';

const _periodColor = Color(0xFFE5637A);
const _fertileColor = Color(0xFF66A3BF);
const _ovulationColor = Color(0xFF3368A0);

String _phaseLabel(String? phase) => switch (phase) {
      'menstrual' => 'Period',
      'follicular' => 'Follicular phase',
      'fertile' => 'Fertile window',
      'ovulation' => 'Ovulation day',
      'luteal' => 'Luteal phase',
      _ => '',
    };

/// Period tracker: a calendar of logged and predicted periods, fertile days
/// and ovulation, plus the cycle summary and history.
class PeriodTrackerPage extends StatefulWidget {
  const PeriodTrackerPage({super.key});

  @override
  State<PeriodTrackerPage> createState() => _PeriodTrackerPageState();
}

class _PeriodTrackerPageState extends State<PeriodTrackerPage> {
  DateTime _focused = DateTime.now();
  DateTime _selected = dayOnly(DateTime.now());

  DateTime get _today => dayOnly(DateTime.now());

  Future<void> _editPeriod({Period? period, DateTime? start}) async {
    final cubit = context.read<CycleCubit>();
    final result = await showModalBottomSheet<_PeriodForm>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PeriodSheet(period: period, start: start ?? _selected),
    );
    if (result == null || !mounted) return;
    final error = await cubit.save(
      id: period?.id,
      start: result.start,
      end: result.end,
      flow: result.flow,
      notes: result.notes,
    );
    if (mounted) {
      showInfoSnack(context, error ?? 'Saved', error: error != null);
    }
  }

  Future<void> _endPeriodOn(Period p, DateTime day) async {
    final error = await context.read<CycleCubit>().save(
        id: p.id, start: p.startDate, end: day, flow: p.flow, notes: p.notes);
    if (mounted && error != null) showInfoSnack(context, error, error: true);
  }

  Future<void> _delete(Period p) async {
    final cubit = context.read<CycleCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Delete this period?'),
        content: Text(
            'The period starting ${DateFormat.yMMMd().format(p.startDate)} '
            'will be removed and predictions recalculated.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final error = await cubit.delete(p);
    if (mounted && error != null) showInfoSnack(context, error, error: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Period tracker',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editPeriod(start: _today),
        backgroundColor: _periodColor,
        icon: const Icon(Icons.water_drop_rounded),
        label: const Text('Log period'),
      ),
      body: BlocBuilder<CycleCubit, CycleState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final o = state.overview;
          return RefreshIndicator(
            onRefresh: context.read<CycleCubit>().load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              children: [
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(state.error!,
                        style: const TextStyle(color: AppColors.error)),
                  ),
                _StatusCard(overview: o, today: _today),
                const SizedBox(height: 16),
                InfoCard(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                  children: [
                    _calendar(o),
                    const SizedBox(height: 8),
                    const _Legend(),
                  ],
                ),
                const SizedBox(height: 12),
                _dayPanel(o),
                if (state.settings != null) ...[
                  const SectionLabel('Reminders'),
                  _RemindersCard(settings: state.settings!),
                ],
                if (o.periods.isNotEmpty) ...[
                  const SectionLabel('History'),
                  InfoCard(children: [
                    for (final (i, p) in o.periods.indexed) ...[
                      if (i > 0) const InfoDivider(),
                      ListTile(
                        leading: const Icon(Icons.water_drop_rounded,
                            color: _periodColor),
                        title: Text(
                          p.ongoing
                              ? '${DateFormat.yMMMd().format(p.startDate)} – now'
                              : '${DateFormat.MMMd().format(p.startDate)} – '
                                  '${DateFormat.yMMMd().format(p.endDate!)}',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
                        ),
                        subtitle: Text(
                          [
                            '${p.lengthDays(_today)} days',
                            if (p.flow != null) '${p.flow!.label} flow',
                            if (p.notes != null) p.notes!,
                          ].join(' · '),
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        onTap: () => _editPeriod(period: p),
                      ),
                    ],
                  ]),
                ],
                const SizedBox(height: 12),
                Text(
                  'Predictions are estimates based on your logged cycles. '
                  'They are not a method of contraception.',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _calendar(CycleOverview o) {
    Widget cell(DateTime day, {bool selected = false, bool outside = false}) {
      final kind = o.kindOf(day, _today);
      final isToday = isSameDay(day, _today);
      Color? fill;
      Color text = outside
          ? AppColors.textSecondary.withValues(alpha: 0.5)
          : AppColors.textPrimary;
      BoxBorder? border;
      switch (kind) {
        case DayKind.period:
          fill = _periodColor;
          text = Colors.white;
        case DayKind.predictedPeriod:
          border = Border.all(color: _periodColor, width: 1.8);
          text = _periodColor;
        case DayKind.ovulation:
          fill = _ovulationColor;
          text = Colors.white;
        case DayKind.fertile:
          fill = _fertileColor.withValues(alpha: 0.25);
        case DayKind.none:
          break;
      }
      if (selected) {
        border = Border.all(color: AppColors.textPrimary, width: 2);
      } else if (isToday && border == null) {
        border = Border.all(color: AppColors.primary, width: 1.5);
      }
      return Center(
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: fill, shape: BoxShape.circle, border: border),
          child: Text('${day.day}',
              style: TextStyle(
                color: text,
                fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
              )),
        ),
      );
    }

    return TableCalendar<void>(
      firstDay: DateTime(_today.year - 3),
      lastDay: DateTime(_today.year + 1, 12, 31),
      focusedDay: _focused,
      startingDayOfWeek: StartingDayOfWeek.sunday,
      availableCalendarFormats: const {CalendarFormat.month: 'Month'},
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        leftChevronIcon:
            Icon(Icons.chevron_left_rounded, color: AppColors.textPrimary),
        rightChevronIcon:
            Icon(Icons.chevron_right_rounded, color: AppColors.textPrimary),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        weekendStyle: TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      rowHeight: 46,
      selectedDayPredicate: (d) => isSameDay(d, _selected),
      onDaySelected: (selected, focused) => setState(() {
        _selected = dayOnly(selected);
        _focused = focused;
      }),
      onPageChanged: (focused) => _focused = focused,
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (_, day, __) => cell(day),
        todayBuilder: (_, day, __) => cell(day),
        selectedBuilder: (_, day, __) => cell(day, selected: true),
        outsideBuilder: (_, day, __) => cell(day, outside: true),
      ),
    );
  }

  Widget _dayPanel(CycleOverview o) {
    final day = _selected;
    final period = o.periodOn(day, _today);
    final kind = o.kindOf(day, _today);
    final future = day.isAfter(_today);
    final title = DateFormat.yMMMMEEEEd().format(day);

    String description;
    final actions = <Widget>[];
    if (period != null) {
      final n = day.difference(dayOnly(period.startDate)).inDays + 1;
      description = 'Period day $n'
          '${period.flow != null ? ' · ${period.flow!.label} flow' : ''}';
      actions.add(OutlinedButton(
          onPressed: () => _editPeriod(period: period),
          child: const Text('Edit')));
      if (period.ongoing) {
        actions.add(ElevatedButton(
          onPressed: () => _endPeriodOn(period, day),
          style: ElevatedButton.styleFrom(backgroundColor: _periodColor),
          child: const Text('Ended this day'),
        ));
      }
      actions.add(TextButton(
        onPressed: () => _delete(period),
        style: TextButton.styleFrom(foregroundColor: AppColors.error),
        child: const Text('Delete'),
      ));
    } else {
      description = switch (kind) {
        DayKind.predictedPeriod => 'Period expected',
        DayKind.ovulation => 'Estimated ovulation – highest chance of pregnancy',
        DayKind.fertile => 'Fertile window – higher chance of pregnancy',
        _ => future ? 'Nothing predicted' : 'No period logged',
      };
      if (!future) {
        actions.add(ElevatedButton.icon(
          onPressed: () => _editPeriod(start: day),
          style: ElevatedButton.styleFrom(backgroundColor: _periodColor),
          icon: const Icon(Icons.water_drop_rounded, size: 18),
          label: const Text('Period started'),
        ));
      }
    }

    return InfoCard(
      padding: const EdgeInsets.all(16),
      children: [
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(description, style: TextStyle(color: AppColors.textSecondary)),
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in actions)
                SizedBox(
                  height: 44,
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      elevatedButtonTheme: ElevatedButtonThemeData(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      outlinedButtonTheme: OutlinedButtonThemeData(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    child: a,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final CycleOverview overview;
  final DateTime today;
  const _StatusCard({required this.overview, required this.today});

  @override
  Widget build(BuildContext context) {
    final o = overview;
    String headline;
    String? sub;
    if (o.lastPeriodStart == null) {
      headline = 'Start tracking';
      sub = 'Log your last period to see predictions.';
    } else {
      final current = o.periodOn(today, today);
      final days = o.daysUntilNextPeriod ?? 0;
      if (current != null) {
        headline =
            'Period day ${today.difference(dayOnly(current.startDate)).inDays + 1}';
      } else if (days > 1) {
        headline = 'Period in $days days';
      } else if (days == 1) {
        headline = 'Period expected tomorrow';
      } else if (days == 0) {
        headline = 'Period expected today';
      } else {
        headline = 'Period ${-days} day${days == -1 ? '' : 's'} late';
      }
      sub = [
        if (o.cycleDay != null) 'Cycle day ${o.cycleDay}',
        if (o.phase != null && current == null) _phaseLabel(o.phase),
      ].join(' · ');
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE5637A), Color(0xFFDC9B9B)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(headline,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800)),
          if (sub.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(sub,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.92))),
          ],
          const SizedBox(height: 16),
          Row(children: [
            _Stat('Avg cycle', '${o.averageCycleLength} days'),
            _Stat('Avg period', '${o.averagePeriodLength} days'),
            _Stat(
                'Next period',
                o.nextPeriodStart == null
                    ? '—'
                    : DateFormat.MMMd().format(o.nextPeriodStart!)),
          ]),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat(this.label, this.value);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: Colors.white.withValues(alpha: 0.85))),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget item(Widget dot, String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            dot,
            const SizedBox(width: 6),
            Text(text,
                style:
                    TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        );
    Widget dot(Color? fill, {Color? border}) => Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: border == null ? null : Border.all(color: border, width: 1.6),
          ),
        );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 6,
      children: [
        item(dot(_periodColor), 'Period'),
        item(dot(null, border: _periodColor), 'Predicted'),
        item(dot(_fertileColor.withValues(alpha: 0.35)), 'Fertile'),
        item(dot(_ovulationColor), 'Ovulation'),
      ],
    );
  }
}

class _PeriodForm {
  final DateTime start;
  final DateTime? end;
  final PeriodFlow? flow;
  final String? notes;
  const _PeriodForm(this.start, this.end, this.flow, this.notes);
}

class _PeriodSheet extends StatefulWidget {
  final Period? period;
  final DateTime start;
  const _PeriodSheet({this.period, required this.start});

  @override
  State<_PeriodSheet> createState() => _PeriodSheetState();
}

class _PeriodSheetState extends State<_PeriodSheet> {
  late DateTime _start = widget.period?.startDate ?? widget.start;
  late DateTime? _end = widget.period?.endDate;
  late PeriodFlow? _flow = widget.period?.flow;
  late final _notes = TextEditingController(text: widget.period?.notes ?? '');
  String? _error;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<DateTime?> _pick(DateTime initial, DateTime first) {
    final today = dayOnly(DateTime.now());
    return showDatePicker(
      context: context,
      initialDate: initial.isAfter(today) ? today : initial,
      firstDate: first,
      lastDate: today,
    );
  }

  void _submit() {
    if (_end != null && _end!.isBefore(_start)) {
      setState(() => _error = 'The end date must be after the start date');
      return;
    }
    if (_end != null && _end!.difference(_start).inDays >= 15) {
      setState(() => _error = 'A period cannot be longer than 15 days');
      return;
    }
    Navigator.pop(
      context,
      _PeriodForm(_start, _end, _flow,
          _notes.text.trim().isEmpty ? null : _notes.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.yMMMd();
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.period == null ? 'Log period' : 'Edit period',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                )),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () async {
                final d = await _pick(_start, DateTime(2000));
                if (d != null) setState(() => _start = d);
              },
              style:
                  OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text('Started ${fmt.format(_start)}'),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Still ongoing',
                  style: TextStyle(color: AppColors.textPrimary)),
              value: _end == null,
              onChanged: (ongoing) => setState(() => _end = ongoing
                  ? null
                  : _start.add(const Duration(days: 4)).isAfter(DateTime.now())
                      ? dayOnly(DateTime.now())
                      : _start.add(const Duration(days: 4))),
            ),
            if (_end != null)
              OutlinedButton.icon(
                onPressed: () async {
                  final d = await _pick(_end!, _start);
                  if (d != null) setState(() => _end = d);
                },
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50)),
                icon: const Icon(Icons.stop_rounded),
                label: Text('Ended ${fmt.format(_end!)}'),
              ),
            const SectionLabel('PeriodFlow'),
            Wrap(spacing: 8, children: [
              for (final f in PeriodFlow.values)
                ChoiceChip(
                  label: Text(f.label),
                  selected: _flow == f,
                  showCheckmark: false,
                  onSelected: (on) => setState(() => _flow = on ? f : null),
                ),
            ]),
            const SizedBox(height: 14),
            TextField(
              controller: _notes,
              maxLength: 500,
              decoration: const InputDecoration(
                  labelText: 'Notes (symptoms, cramps …)'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!,
                    style: const TextStyle(color: AppColors.error)),
              ),
            ElevatedButton(onPressed: _submit, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}

class _RemindersCard extends StatelessWidget {
  final CycleSettings settings;
  const _RemindersCard({required this.settings});

  Future<void> _save(BuildContext context, CycleSettings next) async {
    final error = await context.read<CycleCubit>().updateSettings(next);
    if (error != null && context.mounted) {
      showInfoSnack(context, error, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = settings;
    final title = TextStyle(
        fontWeight: FontWeight.w600, color: AppColors.textPrimary);
    final sub = TextStyle(color: AppColors.textSecondary);
    return InfoCard(children: [
      SwitchListTile(
        secondary: const Icon(Icons.notifications_active_outlined,
            color: _periodColor),
        title: Text('Period is coming', style: title),
        subtitle: Text(
            s.periodReminders
                ? '${s.remindDaysBefore} day${s.remindDaysBefore == 1 ? '' : 's'} '
                    'before, on the day, and if it is late'
                : 'Off',
            style: sub),
        value: s.periodReminders,
        onChanged: (v) => _save(context, s.copyWith(periodReminders: v)),
      ),
      if (s.periodReminders)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Wrap(
            spacing: 8,
            children: [
              for (final days in const [1, 2, 3, 5])
                ChoiceChip(
                  label: Text('$days day${days == 1 ? '' : 's'} before'),
                  selected: s.remindDaysBefore == days,
                  showCheckmark: false,
                  onSelected: (_) =>
                      _save(context, s.copyWith(remindDaysBefore: days)),
                ),
            ],
          ),
        ),
      const InfoDivider(),
      SwitchListTile(
        secondary:
            const Icon(Icons.spa_outlined, color: _fertileColor),
        title: Text('Fertile window', style: title),
        subtitle: Text('On the first fertile day', style: sub),
        value: s.fertileReminders,
        onChanged: (v) => _save(context, s.copyWith(fertileReminders: v)),
      ),
    ]);
  }
}
