import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/di/injection_container.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/info_widgets.dart';
import '../profile/domain/user_profile.dart';
import 'habits.dart';

/// 1250 -> '1.25 L', 250 -> '250 ml'.
String formatWater(int ml) {
  if (ml < 1000) return '$ml ml';
  final litres = (ml / 1000).toStringAsFixed(2);
  return '${litres.replaceFirst(RegExp(r'\.?0+$'), '')} L';
}

/// '5 h 12 min', '45 min'.
String formatHours(Duration d) {
  final minutes = d.inMinutes < 0 ? 0 : d.inMinutes;
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '{n} min'.trArgs({'n': m});
  return m == 0
      ? '{h} h'.trArgs({'h': h})
      : '{h} h {m} min'.trArgs({'h': h, 'm': m});
}

/// A thick ring that fills clockwise from the top, with [child] inside.
class ProgressRing extends StatelessWidget {
  /// 0..1.
  final double progress;
  final Color color;
  final double size;
  final double stroke;
  final Widget? child;

  const ProgressRing({
    super.key,
    required this.progress,
    required this.color,
    this.size = 220,
    this.stroke = 18,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress.clamp(0, 1).toDouble(),
          color: color,
          track: AppColors.tertiary,
          stroke: stroke,
        ),
        child: Center(
          child: Padding(padding: EdgeInsets.all(stroke + 8), child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color track;
  final double stroke;
  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
    required this.stroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = track);
    if (progress > 0) {
      canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false,
          paint..color = color);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}

const _waterColor = Color(0xFF2E86C1);
const _fastColor = Color(0xFF8E6BBF);

// ---- water ------------------------------------------------------------------

class WaterTrackerPage extends StatelessWidget {
  const WaterTrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Water'.tr,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: BlocBuilder<WaterCubit, WaterState>(
        builder: (context, state) {
          if (!state.loaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final cubit = context.read<WaterCubit>();
          final glasses = state.todayMl / state.glassMl;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Center(
                child: ProgressRing(
                  progress: state.progress,
                  color: state.goalReached ? AppColors.success : _waterColor,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        state.goalReached
                            ? Icons.check_circle_rounded
                            : Icons.water_drop_rounded,
                        color:
                            state.goalReached ? AppColors.success : _waterColor,
                        size: 30,
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        child: Text(
                          formatWater(state.todayMl),
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      FittedBox(
                        child: Text(
                          'of {goal}'.trArgs({'goal': formatWater(state.goalMl)}),
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                state.goalReached
                    ? 'You reached your goal for today. Well done!'.tr
                    : state.glassesLeft == 1
                        ? '1 more glass to reach your goal'.tr
                        : '{n} more glasses to reach your goal'
                            .trArgs({'n': state.glassesLeft}),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '{n} glasses today'.trArgs({
                  'n': glasses == glasses.roundToDouble()
                      ? glasses.round()
                      : glasses.toStringAsFixed(1),
                }),
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              // One big button for the usual glass: the thing done most.
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _waterColor,
                  minimumSize: const Size.fromHeight(64),
                ),
                onPressed: () => cubit.drink(),
                icon: const Icon(Icons.local_drink_rounded, size: 26),
                label: Text('I drank a glass ({size})'
                    .trArgs({'size': formatWater(state.glassMl)})),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => cubit.drink(500),
                    child: Text('+ {size}'.trArgs({'size': formatWater(500)})),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => cubit.drink(1000),
                    child:
                        Text('+ {size}'.trArgs({'size': formatWater(1000)})),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: state.todayAdds.isEmpty ? null : cubit.undo,
                    icon: const Icon(Icons.undo_rounded, size: 18),
                    label: FittedBox(child: Text('Undo'.tr)),
                  ),
                ),
              ]),
              SectionLabel('Last 7 days'.tr),
              InfoCard(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 10),
                children: [_WaterWeek(state: state)],
              ),
              SectionLabel('My daily goal'.tr),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final g in WaterState.goals)
                  ChoiceChip(
                    label: Text(formatWater(g)),
                    selected: state.goalMl == g,
                    showCheckmark: false,
                    onSelected: (_) => cubit.setGoal(g),
                  ),
              ]),
              SectionLabel('My glass holds'.tr),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final g in WaterState.glasses)
                  ChoiceChip(
                    label: Text(formatWater(g)),
                    selected: state.glassMl == g,
                    showCheckmark: false,
                    onSelected: (_) => cubit.setGlass(g),
                  ),
              ]),
              const SizedBox(height: 20),
              _Caution(
                'If you have heart or kidney disease, your doctor may have '
                        'told you to limit how much you drink. Follow that '
                        'advice, not this goal.'
                    .tr,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Water drunk on each of the last 7 days against the goal.
class _WaterWeek extends StatelessWidget {
  final WaterState state;
  const _WaterWeek({required this.state});

  static const _height = 96.0;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = [
      for (var i = 6; i >= 0; i--) DateTime(now.year, now.month, now.day - i),
    ];
    final amounts = [for (final d in days) state.on(d)];
    final top = math.max(state.goalMl, amounts.reduce(math.max)) * 1.1;
    final goalY = _height * (1 - state.goalMl / top);

    return Column(
      children: [
        SizedBox(
          height: _height,
          child: Stack(
            children: [
              // The goal: a line the bars are read against.
              Positioned(
                left: 0,
                right: 0,
                top: goalY,
                child: Container(height: 1.5, color: AppColors.textSecondary),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final (i, ml) in amounts.indexed)
                    Expanded(
                      child: Tooltip(
                        triggerMode: TooltipTriggerMode.tap,
                        message: '${DateFormat.MMMEd().format(days[i])}\n'
                            '${formatWater(ml)}',
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: 22,
                            // A day with nothing still marks its place.
                            height: math.max(2, _height * ml / top),
                            decoration: BoxDecoration(
                              color: ml == 0
                                  ? AppColors.tertiary
                                  : ml >= state.goalMl
                                      ? AppColors.success
                                      : _waterColor,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(children: [
          for (final (i, d) in days.indexed)
            Expanded(
              child: Text(
                i == 6 ? 'Today'.tr : DateFormat.E().format(d),
                textAlign: TextAlign.center,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.clip,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: i == 6 ? FontWeight.w700 : FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Container(width: 16, height: 1.5, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text('Goal'.tr,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(width: 14),
          const Icon(Icons.check_circle_rounded,
              size: 14, color: AppColors.success),
          const SizedBox(width: 4),
          Text('Goal reached'.tr,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ]),
      ],
    );
  }
}

// ---- fasting ----------------------------------------------------------------

class FastingTrackerPage extends StatefulWidget {
  const FastingTrackerPage({super.key});

  @override
  State<FastingTrackerPage> createState() => _FastingTrackerPageState();
}

class _FastingTrackerPageState extends State<FastingTrackerPage> {
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    // The ring and the times move on while the page is open.
    _clock = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  /// Health conditions from the profile that make fasting risky.
  static bool _atRisk() {
    try {
      final conditions = sl<ProfileRepository>().cached?.conditions ?? const [];
      return conditions.any((c) => c.toLowerCase().contains('diabet'));
    } catch (_) {
      return false;
    }
  }

  Future<void> _pickStart(FastingCubit cubit, DateTime current) async {
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: now.subtract(const Duration(days: 2)),
      lastDate: now,
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(current));
    if (time == null) return;
    await cubit
        .start(DateTime(day.year, day.month, day.day, time.hour, time.minute));
  }

  Future<void> _confirmEnd(FastingCubit cubit, FastingState state) async {
    if (state.reachedGoal(DateTime.now())) return cubit.end();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text('End your fast now?'.tr),
        content: Text('You have not reached your goal yet. That is fine: '
                'stop whenever you feel unwell.'
            .tr),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: Text('Keep fasting'.tr)),
          TextButton(
              onPressed: () => Navigator.pop(d, true),
              child: Text('End fast'.tr)),
        ],
      ),
    );
    if (ok == true) await cubit.end();
  }

  @override
  Widget build(BuildContext context) {
    final clock = DateFormat.jm();
    return Scaffold(
      appBar: AppBar(
        title: Text('Fasting'.tr,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: BlocBuilder<FastingCubit, FastingState>(
        builder: (context, state) {
          if (!state.loaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final cubit = context.read<FastingCubit>();
          final now = DateTime.now();
          final done = state.reachedGoal(now);
          final left = state.isFasting
              ? state.endsAt!.difference(now)
              : Duration.zero;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _Caution(
                (_atRisk()
                        ? 'Your profile says you have diabetes. Fasting can '
                            'make your blood sugar drop dangerously. Do not '
                            'fast without your doctor agreeing to it.'
                        : 'Fasting is not safe for everyone. Ask your doctor '
                            'first if you have diabetes, are pregnant or '
                            'breastfeeding, are under 18, or are elderly or '
                            'unwell.')
                    .tr,
              ),
              const SizedBox(height: 8),
              _Caution(
                'Keep taking your medicines at their usual times. Some must '
                        'be taken with food: plan your eating hours around '
                        'them.'
                    .tr,
                icon: Icons.medication_outlined,
              ),
              const SizedBox(height: 20),
              Center(
                child: ProgressRing(
                  progress: state.progress(now),
                  color: done ? AppColors.success : _fastColor,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        done
                            ? Icons.check_circle_rounded
                            : state.isFasting
                                ? Icons.hourglass_bottom_rounded
                                : Icons.restaurant_rounded,
                        color: done ? AppColors.success : _fastColor,
                        size: 30,
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        child: Text(
                          state.isFasting
                              ? formatHours(state.elapsed(now))
                              : 'Not fasting'.tr,
                          style: TextStyle(
                            fontSize: state.isFasting ? 30 : 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      FittedBox(
                        child: Text(
                          'Goal: {h} hours'.trArgs({'h': state.goalHours}),
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (state.isFasting) ...[
                Text(
                  done
                      ? 'Goal reached. You can eat now.'.tr
                      : '{time} to go · you can eat at {clock}'.trArgs({
                          'time': formatHours(left),
                          'clock': clock.format(state.endsAt!),
                        }),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: () => _pickStart(cubit, state.startedAt!),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text('Started {when}'.trArgs({
                    'when': DateFormat.MMMd().add_jm().format(state.startedAt!),
                  })),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: done ? AppColors.success : _fastColor,
                    minimumSize: const Size.fromHeight(60),
                  ),
                  onPressed: () => _confirmEnd(cubit, state),
                  icon: const Icon(Icons.restaurant_rounded),
                  label: Text('End fast'.tr),
                ),
              ] else ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _fastColor,
                    minimumSize: const Size.fromHeight(60),
                  ),
                  onPressed: () => cubit.start(),
                  icon: const Icon(Icons.play_arrow_rounded, size: 28),
                  label: Text('Start fasting now'.tr),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => _pickStart(cubit, now),
                  child: Text('I started earlier'.tr),
                ),
              ],
              SectionLabel('How long to fast'.tr),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final h in FastingState.plans)
                  ChoiceChip(
                    label: Text('{h} h'.trArgs({'h': h})),
                    selected: state.goalHours == h,
                    showCheckmark: false,
                    onSelected: (_) => cubit.setGoal(h),
                  ),
              ]),
              const SizedBox(height: 8),
              Text(
                'Fast for {fast} hours, eat within {eat} hours. Water is '
                        'allowed while fasting. New to this? Start with 12.'
                    .trArgs({
                  'fast': state.goalHours,
                  'eat': 24 - state.goalHours,
                }),
                style: TextStyle(color: AppColors.textSecondary),
              ),
              if (state.history.isNotEmpty) ...[
                SectionLabel('Past fasts'.tr),
                InfoCard(children: [
                  for (final (i, f) in state.history.take(14).indexed) ...[
                    if (i > 0) const InfoDivider(),
                    ListTile(
                      leading: Icon(
                        f.reachedGoal
                            ? Icons.check_circle_rounded
                            : Icons.timelapse_rounded,
                        color: f.reachedGoal
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                      title: Text(
                        formatHours(f.length),
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary),
                      ),
                      subtitle: Text(
                        '${DateFormat.MMMd().add_jm().format(f.start)} · '
                        '${(f.reachedGoal ? 'Goal of {h} h reached' : 'Goal was {h} h').trArgs({'h': f.goalHours})}',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      trailing: IconButton(
                        tooltip: 'Delete'.tr,
                        icon: Icon(Icons.delete_outline_rounded,
                            color: AppColors.textSecondary),
                        onPressed: () => cubit.deleteFast(f),
                      ),
                    ),
                  ],
                ]),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// A health warning that must not be missed.
class _Caution extends StatelessWidget {
  final String text;
  final IconData icon;
  const _Caution(this.text, {this.icon = Icons.warning_amber_rounded});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.tertiary, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 13.5, height: 1.35, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
