import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/info_widgets.dart';
import '../../domain/womens_health.dart';
import '../cubit/womens_health_cubits.dart';

const _periodColor = Color(0xFFE5637A);
const _fertileColor = Color(0xFF66A3BF);
const _ovulationColor = Color(0xFF3368A0);

String _phaseLabel(String? phase) => switch (phase) {
      'menstrual' => 'Period'.tr,
      'follicular' => 'Follicular phase'.tr,
      'fertile' => 'Fertile window'.tr,
      'ovulation' => 'Ovulation day'.tr,
      'luteal' => 'Luteal phase'.tr,
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
      showInfoSnack(context, error ?? 'Saved'.tr, error: error != null);
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
        title: Text('Delete this period?'.tr),
        content: Text(
            'The period starting {date} will be removed and predictions recalculated.'
                .trArgs({'date': DateFormat.yMMMd().format(p.startDate)})),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: Text('Cancel'.tr)),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(d, true),
            child: Text('Delete'.tr),
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
        title: Text('Period tracker'.tr,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editPeriod(start: _today),
        backgroundColor: _periodColor,
        icon: const Icon(Icons.water_drop_rounded),
        label: Text('Log period'.tr),
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
                  SectionLabel('Reminders'.tr),
                  _RemindersCard(settings: state.settings!),
                ],
                if (o.periods.isNotEmpty) ...[
                  SectionLabel('History'.tr),
                  InfoCard(children: [
                    for (final (i, p) in o.periods.indexed) ...[
                      if (i > 0) const InfoDivider(),
                      ListTile(
                        leading: const Icon(Icons.water_drop_rounded,
                            color: _periodColor),
                        title: Text(
                          p.ongoing
                              ? '{date} – now'.trArgs({
                                  'date':
                                      DateFormat.yMMMd().format(p.startDate),
                                })
                              : '${DateFormat.MMMd().format(p.startDate)} – '
                                  '${DateFormat.yMMMd().format(p.endDate!)}',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
                        ),
                        subtitle: Text(
                          [
                            '{n} days'.trArgs({'n': p.lengthDays(_today)}),
                            if (p.flow != null) p.flow!.flowLabel,
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
                          'They are not a method of contraception.'
                      .tr,
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
      description = 'Period day {n}'.trArgs({'n': n}) +
          (period.flow != null ? ' · ${period.flow!.flowLabel}' : '');
      actions.add(OutlinedButton(
          onPressed: () => _editPeriod(period: period),
          child: Text('Edit'.tr)));
      if (period.ongoing) {
        actions.add(ElevatedButton(
          onPressed: () => _endPeriodOn(period, day),
          style: ElevatedButton.styleFrom(backgroundColor: _periodColor),
          child: Text('Ended this day'.tr),
        ));
      }
      actions.add(TextButton(
        onPressed: () => _delete(period),
        style: TextButton.styleFrom(foregroundColor: AppColors.error),
        child: Text('Delete'.tr),
      ));
    } else {
      description = switch (kind) {
        DayKind.predictedPeriod => 'Period expected'.tr,
        DayKind.ovulation =>
          'Estimated ovulation – highest chance of pregnancy'.tr,
        DayKind.fertile => 'Fertile window – higher chance of pregnancy'.tr,
        _ => future ? 'Nothing predicted'.tr : 'No period logged'.tr,
      };
      if (!future) {
        actions.add(ElevatedButton.icon(
          onPressed: () => _editPeriod(start: day),
          style: ElevatedButton.styleFrom(backgroundColor: _periodColor),
          icon: const Icon(Icons.water_drop_rounded, size: 18),
          label: Text('Period started'.tr),
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
      headline = 'Start tracking'.tr;
      sub = 'Log your last period to see predictions.'.tr;
    } else {
      final current = o.periodOn(today, today);
      final days = o.daysUntilNextPeriod ?? 0;
      if (current != null) {
        headline = 'Period day {n}'.trArgs({
          'n': today.difference(dayOnly(current.startDate)).inDays + 1,
        });
      } else if (days > 1) {
        headline = 'Period in {n} days'.trArgs({'n': days});
      } else if (days == 1) {
        headline = 'Period expected tomorrow'.tr;
      } else if (days == 0) {
        headline = 'Period expected today'.tr;
      } else if (days == -1) {
        headline = 'Period 1 day late'.tr;
      } else {
        headline = 'Period {n} days late'.trArgs({'n': -days});
      }
      sub = [
        if (o.cycleDay != null) 'Cycle day {n}'.trArgs({'n': o.cycleDay}),
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
            _Stat('Avg cycle'.tr,
                '{n} days'.trArgs({'n': o.averageCycleLength})),
            _Stat('Avg period'.tr,
                '{n} days'.trArgs({'n': o.averagePeriodLength})),
            _Stat(
                'Next period'.tr,
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
        item(dot(_periodColor), 'Period'.tr),
        item(dot(null, border: _periodColor), 'Predicted'.tr),
        item(dot(_fertileColor.withValues(alpha: 0.35)), 'Fertile'.tr),
        item(dot(_ovulationColor), 'Ovulation'.tr),
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
      setState(() => _error = 'The end date must be after the start date'.tr);
      return;
    }
    if (_end != null && _end!.difference(_start).inDays >= 15) {
      setState(() => _error = 'A period cannot be longer than 15 days'.tr);
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
            Text(widget.period == null ? 'Log period'.tr : 'Edit period'.tr,
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
              label: Text(
                  'Started {date}'.trArgs({'date': fmt.format(_start)})),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Still ongoing'.tr,
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
                label: Text(
                    'Ended {date}'.trArgs({'date': fmt.format(_end!)})),
              ),
            SectionLabel('PeriodFlow'.tr),
            Wrap(spacing: 8, children: [
              for (final f in PeriodFlow.values)
                ChoiceChip(
                  label: Text(f.localizedLabel),
                  selected: _flow == f,
                  showCheckmark: false,
                  onSelected: (on) => setState(() => _flow = on ? f : null),
                ),
            ]),
            const SizedBox(height: 14),
            TextField(
              controller: _notes,
              maxLength: 500,
              decoration: InputDecoration(
                  labelText: 'Notes (symptoms, cramps …)'.tr),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!,
                    style: const TextStyle(color: AppColors.error)),
              ),
            ElevatedButton(onPressed: _submit, child: Text('Save'.tr)),
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
        title: Text('Period is coming'.tr, style: title),
        subtitle: Text(
            s.periodReminders
                ? s.remindDaysBefore == 1
                    ? '1 day before, on the day, and if it is late'.tr
                    : '{n} days before, on the day, and if it is late'
                        .trArgs({'n': s.remindDaysBefore})
                : 'Off'.tr,
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
                  label: Text(days == 1
                      ? '1 day before'.tr
                      : '{n} days before'.trArgs({'n': days})),
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
        title: Text('Fertile window'.tr, style: title),
        subtitle: Text('On the first fertile day'.tr, style: sub),
        value: s.fertileReminders,
        onChanged: (v) => _save(context, s.copyWith(fertileReminders: v)),
      ),
    ]);
  }
}
