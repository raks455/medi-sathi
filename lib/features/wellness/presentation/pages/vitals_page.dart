import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/info_widgets.dart';
import '../../domain/wellness.dart';
import '../cubit/wellness_cubits.dart';

/// Weight, height (BMI) and blood pressure: latest values, a trend chart and
/// the full history.
class VitalsPage extends StatelessWidget {
  const VitalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weight & vitals'.tr,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: const [_UnitsMenu(), SizedBox(width: 4)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddVitalSheet(context,
            initialType: context.read<VitalsCubit>().state.selected),
        icon: const Icon(Icons.add_rounded),
        label: Text('Add reading'.tr),
      ),
      body: BlocBuilder<VitalsCubit, VitalsState>(
        builder: (context, state) {
          if (state.loading && state.readings.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final cubit = context.read<VitalsCubit>();
          return RefreshIndicator(
            onRefresh: cubit.load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              children: [
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(state.error!,
                        style: const TextStyle(color: AppColors.error)),
                  ),
                _SummaryGrid(state: state),
                const SizedBox(height: 20),
                SegmentedButton<VitalType>(
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: AppColors.primary,
                    selectedForegroundColor: Colors.white,
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(color: AppColors.tertiary, width: 1.2),
                  ),
                  segments: [
                    ButtonSegment(
                        value: VitalType.weight, label: Text('Weight'.tr)),
                    ButtonSegment(
                        value: VitalType.bloodPressure, label: Text('BP'.tr)),
                    ButtonSegment(
                        value: VitalType.height, label: Text('Height'.tr)),
                  ],
                  selected: {state.selected},
                  onSelectionChanged: (s) => cubit.select(s.first),
                ),
                const SizedBox(height: 16),
                if (state.current.length >= 2 &&
                    state.selected != VitalType.height) ...[
                  _TrendChart(
                    type: state.selected,
                    readings: state.current,
                    weightUnit: state.weightUnit,
                  ),
                  const SizedBox(height: 16),
                ],
                SectionLabel('{type} history'
                    .trArgs({'type': state.selected.label.tr})),
                if (state.current.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No {type} readings yet. Tap "Add reading" to log one.'
                          .trArgs({
                        'type': state.selected.label.tr.toLowerCase(),
                      }),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                else
                  InfoCard(children: [
                    for (final (i, r) in state.current.indexed) ...[
                      if (i > 0) const InfoDivider(),
                      _ReadingTile(
                          key: ValueKey(r.id),
                          reading: r,
                          text: state.format(r)),
                    ],
                  ]),
              ],
            ),
          );
        },
      ),
    );
  }
}

Color _severityColor(String? code) => switch (HealthLabels.severity(code)) {
      0 => AppColors.success,
      1 => AppColors.warning,
      _ => AppColors.error,
    };

/// App bar menu to pick the units for weight and height.
class _UnitsMenu extends StatelessWidget {
  const _UnitsMenu();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<VitalsCubit>();
    final state = context.watch<VitalsCubit>().state;
    PopupMenuItem<Object> heading(String text) => PopupMenuItem<Object>(
          enabled: false,
          height: 32,
          child: Text(text.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              )),
        );
    return PopupMenuButton<Object>(
      tooltip: 'Units'.tr,
      icon: const Icon(Icons.straighten_rounded),
      onSelected: (unit) {
        if (unit is WeightUnit) cubit.setWeightUnit(unit);
        if (unit is HeightUnit) cubit.setHeightUnit(unit);
      },
      itemBuilder: (_) => [
        heading('Weight in'.tr),
        for (final u in WeightUnit.values)
          CheckedPopupMenuItem<Object>(
            value: u,
            checked: state.weightUnit == u,
            child: Text(u.label),
          ),
        const PopupMenuDivider(),
        heading('Height in'.tr),
        for (final u in HeightUnit.values)
          CheckedPopupMenuItem<Object>(
            value: u,
            checked: state.heightUnit == u,
            child: Text(u.label),
          ),
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final VitalsState state;
  const _SummaryGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    final s = state.summary;
    final unit = state.weightUnit;
    String? change;
    if (s.weightChange30d != null && s.weightChange30d != 0) {
      final v = s.weightChange30d!;
      change = '{change} in 30 days'.trArgs({
        'change': '${v > 0 ? '+' : '-'}${formatNumber(unit.fromKg(v.abs()))} '
            '${unit.label}',
      });
    }
    final cards = [
      _StatCard(
        icon: Icons.monitor_weight_outlined,
        label: 'Weight'.tr,
        value: s.weight == null ? '—' : state.format(s.weight!),
        caption: change,
      ),
      _StatCard(
        icon: Icons.height_rounded,
        label: 'Height'.tr,
        value: s.height == null ? '—' : state.format(s.height!),
      ),
      _StatCard(
        icon: Icons.speed_rounded,
        label: 'BMI',
        value: s.bmi?.toStringAsFixed(1) ?? '—',
        caption: s.bmi == null
            ? 'Add weight and height'.tr
            : HealthLabels.category(s.bmiCategory),
        captionColor: s.bmi == null ? null : _severityColor(s.bmiCategory),
      ),
      _StatCard(
        icon: Icons.favorite_outline_rounded,
        label: 'Blood pressure'.tr,
        value: s.bloodPressure == null ? '—' : state.format(s.bloodPressure!),
        caption: s.bloodPressure == null
            ? null
            : HealthLabels.category(s.bloodPressure!.category),
        captionColor: s.bloodPressure == null
            ? null
            : _severityColor(s.bloodPressure!.category),
      ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final w = (c.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [for (final card in cards) SizedBox(width: w, child: card)],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? caption;
  final Color? captionColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.caption,
    this.captionColor,
  });

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      padding: const EdgeInsets.all(14),
      children: [
        Row(children: [
          Icon(icon, size: 18, color: AppColors.icon),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
        ]),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              )),
        ),
        const SizedBox(height: 2),
        Text(
          caption ?? ' ',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: captionColor ?? AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _TrendChart extends StatelessWidget {
  final VitalType type;
  final List<VitalReading> readings;
  final WeightUnit weightUnit;
  const _TrendChart({
    required this.type,
    required this.readings,
    required this.weightUnit,
  });

  @override
  Widget build(BuildContext context) {
    // Oldest first, at most the last 30 readings.
    final points = readings.take(30).toList().reversed.toList();
    final first = points.first.recordedAt;
    double x(VitalReading r) =>
        r.recordedAt.difference(first).inHours / 24.0;

    final top = [
      for (final r in points)
        FlSpot(
            x(r),
            type == VitalType.weight
                ? weightUnit.fromKg(r.value)
                : r.value),
    ];
    final bottom = type == VitalType.bloodPressure
        ? [
            for (final r in points)
              if (r.value2 != null) FlSpot(x(r), r.value2!),
          ]
        : <FlSpot>[];
    final values = [...top, ...bottom].map((s) => s.y);
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final pad = ((maxY - minY) * 0.2).clamp(2, 50).toDouble();

    LineChartBarData line(List<FlSpot> spots, Color color) => LineChartBarData(
          spots: spots,
          isCurved: true,
          preventCurveOverShooting: true,
          color: color,
          barWidth: 3,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
              show: bottom.isEmpty, color: color.withValues(alpha: 0.12)),
        );

    return InfoCard(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      children: [
        SizedBox(
          height: 190,
          child: LineChart(
            LineChartData(
              minY: (minY - pad).floorToDouble(),
              maxY: (maxY + pad).ceilToDouble(),
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: AppColors.tertiary, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: _interval(x(points.last)),
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        DateFormat.MMMd().format(
                            first.add(Duration(hours: (value * 24).round()))
                                .toLocal()),
                        style: TextStyle(
                            fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) => Text(
                      value.toStringAsFixed(0),
                      style: TextStyle(
                          fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
              lineBarsData: [
                line(top, AppColors.primary),
                if (bottom.isNotEmpty) line(bottom, AppColors.icon),
              ],
            ),
          ),
        ),
        if (bottom.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 8),
            child: Row(children: [
              _Legend(color: AppColors.primary, text: 'Systolic'.tr),
              const SizedBox(width: 16),
              _Legend(color: AppColors.icon, text: 'Diastolic'.tr),
            ]),
          ),
      ],
    );
  }

  static double _interval(double spanDays) {
    if (spanDays <= 0) return 1;
    return (spanDays / 4).clamp(1, 365).ceilToDouble();
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;
  const _Legend({required this.color, required this.text});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 6),
        Text(text,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ]);
}

class _ReadingTile extends StatelessWidget {
  final VitalReading reading;

  /// The value in the units the user picked.
  final String text;
  const _ReadingTile({super.key, required this.reading, required this.text});

  Future<void> _delete(BuildContext context) async {
    final cubit = context.read<VitalsCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text('Delete this reading?'.tr),
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
    final error = await cubit.delete(reading);
    if (error != null && context.mounted) {
      showInfoSnack(context, error, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = reading;
    final when = DateFormat.yMMMd().add_jm().format(r.recordedAt.toLocal());
    final extra = [
      if (r.pulse != null) 'Pulse {n}'.trArgs({'n': r.pulse}),
      if (r.category != null) HealthLabels.category(r.category),
      if (r.note != null) r.note!,
    ].join(' · ');
    return ListTile(
      onTap: () => showEditVitalSheet(context, r),
      title: Text(text,
          style: TextStyle(
              fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      subtitle: Text(extra.isEmpty ? when : '$when\n$extra',
          style: TextStyle(color: AppColors.textSecondary)),
      isThreeLine: extra.isNotEmpty,
      trailing: PopupMenuButton<String>(
        tooltip: 'Edit or delete'.tr,
        icon: Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
        onSelected: (action) => action == 'edit'
            ? showEditVitalSheet(context, r)
            : _delete(context),
        itemBuilder: (_) => [
          PopupMenuItem(value: 'edit', child: Text('Edit'.tr)),
          PopupMenuItem(value: 'delete', child: Text('Delete'.tr)),
        ],
      ),
    );
  }
}

/// Sheet to log weight, height and blood pressure - any or all of them in
/// one go. Uses the [VitalsCubit] above [context].
Future<void> showAddVitalSheet(BuildContext context,
        {VitalType initialType = VitalType.weight}) =>
    _showVitalSheet(context, _VitalForm(initialType: initialType));

/// Sheet to correct a saved reading.
Future<void> showEditVitalSheet(BuildContext context, VitalReading reading) =>
    _showVitalSheet(
        context, _VitalForm(initialType: reading.type, editing: reading));

Future<void> _showVitalSheet(BuildContext context, Widget form) {
  final cubit = context.read<VitalsCubit>();
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => BlocProvider.value(value: cubit, child: form),
  );
}

class _VitalForm extends StatefulWidget {
  /// The reading whose field is focused first.
  final VitalType initialType;

  /// The reading being corrected, or null to add new ones.
  final VitalReading? editing;
  const _VitalForm({required this.initialType, this.editing});

  @override
  State<_VitalForm> createState() => _VitalFormState();
}

class _VitalFormState extends State<_VitalForm> {
  final _formKey = GlobalKey<FormState>();
  // One controller per field, so nothing typed is lost or carried over
  // between readings.
  final _weight = TextEditingController();
  final _height = TextEditingController(); // cm or m
  final _feet = TextEditingController();
  final _inches = TextEditingController();
  final _systolic = TextEditingController();
  final _diastolic = TextEditingController();
  final _pulse = TextEditingController();
  final _note = TextEditingController();
  late DateTime _when;
  bool _saving = false;
  String? _error;

  /// The value fields as filled in for [_VitalForm.editing]; while they are
  /// unchanged the stored value is sent back as it is, without rounding.
  String? _original;

  VitalReading? get _editing => widget.editing;
  VitalsCubit get _cubit => context.read<VitalsCubit>();

  @override
  void initState() {
    super.initState();
    final r = _editing;
    _when = r?.recordedAt.toLocal() ?? DateTime.now();
    if (r == null) return;
    final state = _cubit.state;
    _note.text = r.note ?? '';
    switch (r.type) {
      case VitalType.weight:
        _weight.text = formatNumber(state.weightUnit.fromKg(r.value));
      case VitalType.height:
        _showHeight(r.value, state.heightUnit);
      case VitalType.bloodPressure:
        _systolic.text = '${r.value.round()}';
        _diastolic.text = r.value2 == null ? '' : '${r.value2!.round()}';
        _pulse.text = r.pulse?.toString() ?? '';
    }
    _original = _signature(state);
  }

  @override
  void dispose() {
    for (final c in [
      _weight, _height, _feet, _inches, _systolic, _diastolic, _pulse, _note,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String _signature(VitalsState s) => [
        s.weightUnit.name, s.heightUnit.name, _weight.text, _height.text,
        _feet.text, _inches.text, _systolic.text, _diastolic.text,
      ].join('|');

  static double? _num(String s) =>
      double.tryParse(s.trim().replaceAll(',', '.'));

  static bool _blank(TextEditingController c) => c.text.trim().isEmpty;

  static double _round2(double v) => double.parse(v.toStringAsFixed(2));

  bool _shows(VitalType type) => _editing == null || _editing!.type == type;

  // ---- which readings were filled in ----

  bool get _weightEmpty => _blank(_weight);

  bool _heightEmpty(HeightUnit unit) => unit == HeightUnit.ftIn
      ? _blank(_feet) && _blank(_inches)
      : _blank(_height);

  bool get _pressureEmpty =>
      _blank(_systolic) && _blank(_diastolic) && _blank(_pulse);

  // ---- height in the chosen unit ----

  /// The typed height in cm, or null if it is not a number.
  double? _heightCm(HeightUnit unit) {
    switch (unit) {
      case HeightUnit.cm:
        return _num(_height.text);
      case HeightUnit.m:
        final m = _num(_height.text);
        return m == null ? null : m * 100;
      case HeightUnit.ftIn:
        final feet = _blank(_feet) ? 0 : int.tryParse(_feet.text.trim());
        final inches = _blank(_inches) ? 0.0 : _num(_inches.text);
        if (feet == null || inches == null) return null;
        return HeightUnit.cmFromFeetInches(feet, inches);
    }
  }

  void _showHeight(double cm, HeightUnit unit) {
    switch (unit) {
      case HeightUnit.cm:
        _height.text = formatNumber(cm);
      case HeightUnit.m:
        _height.text = formatNumber(cm / 100, digits: 2);
      case HeightUnit.ftIn:
        final (feet, inches) = HeightUnit.feetInches(cm);
        _feet.text = '$feet';
        _inches.text = formatNumber(inches);
    }
  }

  /// Switching units converts what is already typed.
  void _switchWeightUnit(WeightUnit to) {
    final from = _cubit.state.weightUnit;
    final typed = _num(_weight.text);
    if (typed != null) {
      _weight.text = formatNumber(to.fromKg(from.toKg(typed)));
    }
    _cubit.setWeightUnit(to);
  }

  void _switchHeightUnit(HeightUnit to) {
    final from = _cubit.state.heightUnit;
    final cm = _heightEmpty(from) ? null : _heightCm(from);
    _height.clear();
    _feet.clear();
    _inches.clear();
    if (cm != null) _showHeight(cm, to);
    _cubit.setHeightUnit(to);
  }

  // ---- validation ----

  /// For a field that may stay empty when adding (the reading is skipped) but
  /// not when correcting a reading.
  String? _emptyError(String message) => _editing == null ? null : message;

  String? _validateWeight(WeightUnit unit) {
    if (_weightEmpty) return _emptyError('Enter the weight'.tr);
    final typed = _num(_weight.text);
    if (typed == null) return 'Enter a number'.tr;
    final kg = unit.toKg(typed);
    if (kg < 1 || kg > 500) {
      return 'Should be between {min} and {max} {unit}'.trArgs({
        'min': unit.fromKg(1).ceil(),
        'max': unit.fromKg(500).floor(),
        'unit': unit.label,
      });
    }
    return null;
  }

  String? _validateHeight(HeightUnit unit) {
    if (_heightEmpty(unit)) return _emptyError('Enter the height'.tr);
    final cm = _heightCm(unit);
    if (cm == null) return 'Enter a number'.tr;
    if (unit == HeightUnit.ftIn) {
      final inches = _blank(_inches) ? 0.0 : _num(_inches.text)!;
      if (inches >= 12) return 'Inches should be less than 12'.tr;
    }
    if (cm < 30 || cm > 272) {
      return switch (unit) {
        HeightUnit.cm => 'Should be between 30 and 272 cm'.tr,
        HeightUnit.m => 'Should be between 0.3 and 2.72 m'.tr,
        HeightUnit.ftIn => 'Should be between 1 ft and 8 ft 11 in'.tr,
      };
    }
    return null;
  }

  String? _validateSystolic() {
    if (_pressureEmpty) return _emptyError('Enter systolic'.tr);
    final n = _num(_systolic.text);
    if (n == null) return 'Enter systolic'.tr;
    if (n < 50 || n > 300) return 'Should be 50 to 300'.tr;
    return null;
  }

  String? _validateDiastolic() {
    if (_pressureEmpty) return _emptyError('Enter diastolic'.tr);
    final n = _num(_diastolic.text);
    if (n == null) return 'Enter diastolic'.tr;
    if (n < 30 || n > 200) return 'Should be 30 to 200'.tr;
    final systolic = _num(_systolic.text);
    if (systolic != null && n >= systolic) return 'Must be below systolic'.tr;
    return null;
  }

  String? _validatePulse() {
    if (_blank(_pulse)) return null;
    final n = int.tryParse(_pulse.text.trim());
    if (n == null || n < 20 || n > 250) return 'Should be 20 to 250'.tr;
    return null;
  }

  // ---- actions ----

  Future<void> _pickWhen() async {
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(_when));
    if (!mounted) return;
    final t = time ?? TimeOfDay.fromDateTime(_when);
    final picked = DateTime(day.year, day.month, day.day, t.hour, t.minute);
    setState(() => _when = picked.isAfter(now) ? now : picked);
  }

  /// The filled-in readings, in kg / cm / mmHg.
  List<VitalInput> _inputs(VitalsState state) {
    final editing = _editing;
    final untouched = editing != null && _signature(state) == _original;
    final note = _note.text;
    return [
      if (_shows(VitalType.weight) && !_weightEmpty)
        VitalInput(
          type: VitalType.weight,
          value: untouched
              ? editing.value
              : _round2(state.weightUnit.toKg(_num(_weight.text)!)),
          note: note,
          recordedAt: _when,
        ),
      if (_shows(VitalType.height) && !_heightEmpty(state.heightUnit))
        VitalInput(
          type: VitalType.height,
          value: untouched
              ? editing.value
              : _round2(_heightCm(state.heightUnit)!),
          note: note,
          recordedAt: _when,
        ),
      if (_shows(VitalType.bloodPressure) && !_pressureEmpty)
        VitalInput(
          type: VitalType.bloodPressure,
          value: _num(_systolic.text)!,
          value2: _num(_diastolic.text),
          pulse: _blank(_pulse) ? null : int.tryParse(_pulse.text.trim()),
          note: note,
          recordedAt: _when,
        ),
    ];
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final cubit = _cubit;
    final inputs = _inputs(cubit.state);
    if (inputs.isEmpty) {
      setState(() => _error = 'Enter at least one reading.'.tr);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    String? error;
    final editing = _editing;
    if (editing != null) {
      error = await cubit.update(editing, inputs.single);
    } else {
      final result = await cubit.addAll(inputs);
      error = result.error;
      if (error != null && result.saved.isNotEmpty) {
        // Clear what was stored so saving again cannot add it twice.
        if (result.saved.contains(VitalType.weight)) _weight.clear();
        if (result.saved.contains(VitalType.height)) {
          _height.clear();
          _feet.clear();
          _inches.clear();
        }
        final names = result.saved
            .map((t) => t.label.tr.toLowerCase())
            .join(' and '.tr);
        error = 'Saved your {names}, but not the rest: {error}'
            .trArgs({'names': names, 'error': error});
      }
    }
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context);
    } else {
      // Shown inside the sheet: a snackbar would be hidden behind it.
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  static final _decimal = [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
  ];
  static final _digits = [FilteringTextInputFormatter.digitsOnly];
  static const _decimalKeyboard =
      TextInputType.numberWithOptions(decimal: true);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VitalsCubit>().state;
    final weightUnit = state.weightUnit;
    final heightUnit = state.heightUnit;
    final adding = _editing == null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  adding
                      ? 'Add readings'.tr
                      : 'Edit {type}'.trArgs({
                          'type': _editing!.type.label.tr.toLowerCase(),
                        }),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  )),
              if (adding) ...[
                const SizedBox(height: 4),
                Text('Fill in what you measured. Leave the rest empty.'.tr,
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
              if (_shows(VitalType.weight)) ...[
                _FieldHeading(
                  'Weight'.tr,
                  trailing: _UnitToggle<WeightUnit>(
                    units: {for (final u in WeightUnit.values) u: u.label},
                    selected: weightUnit,
                    onChanged: _switchWeightUnit,
                  ),
                ),
                TextFormField(
                  controller: _weight,
                  autofocus: widget.initialType == VitalType.weight,
                  keyboardType: _decimalKeyboard,
                  inputFormatters: _decimal,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                      labelText: 'Weight'.tr, suffixText: weightUnit.label),
                  validator: (_) => _validateWeight(weightUnit),
                ),
              ],
              if (_shows(VitalType.height)) ...[
                _FieldHeading(
                  'Height'.tr,
                  trailing: _UnitToggle<HeightUnit>(
                    units: {for (final u in HeightUnit.values) u: u.label},
                    selected: heightUnit,
                    onChanged: _switchHeightUnit,
                  ),
                ),
                if (heightUnit == HeightUnit.ftIn)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _feet,
                          autofocus: widget.initialType == VitalType.height,
                          keyboardType: TextInputType.number,
                          inputFormatters: _digits,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                              labelText: 'Feet'.tr, suffixText: 'ft'),
                          validator: (_) => _validateHeight(heightUnit),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _inches,
                          keyboardType: _decimalKeyboard,
                          inputFormatters: _decimal,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                              labelText: 'Inches'.tr, suffixText: 'in'),
                        ),
                      ),
                    ],
                  )
                else
                  TextFormField(
                    controller: _height,
                    autofocus: widget.initialType == VitalType.height,
                    keyboardType: _decimalKeyboard,
                    inputFormatters: _decimal,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                        labelText: 'Height'.tr, suffixText: heightUnit.label),
                    validator: (_) => _validateHeight(heightUnit),
                  ),
              ],
              if (_shows(VitalType.bloodPressure)) ...[
                _FieldHeading('Blood pressure'.tr),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _systolic,
                        autofocus:
                            widget.initialType == VitalType.bloodPressure,
                        keyboardType: TextInputType.number,
                        inputFormatters: _digits,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                            labelText: 'Systolic (top)'.tr,
                            suffixText: 'mmHg'),
                        validator: (_) => _validateSystolic(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _diastolic,
                        keyboardType: TextInputType.number,
                        inputFormatters: _digits,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                            labelText: 'Diastolic (bottom)'.tr,
                            suffixText: 'mmHg'),
                        validator: (_) => _validateDiastolic(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pulse,
                  keyboardType: TextInputType.number,
                  inputFormatters: _digits,
                  decoration: InputDecoration(
                      labelText: 'Pulse (optional)'.tr, suffixText: 'bpm'),
                  validator: (_) => _validatePulse(),
                ),
              ],
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickWhen,
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50)),
                icon: const Icon(Icons.schedule_rounded),
                label: Text(DateFormat.yMMMd().add_jm().format(_when)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _note,
                maxLength: 300,
                decoration:
                    InputDecoration(labelText: 'Note (optional)'.tr),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(_error!,
                      style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600)),
                ),
              const SizedBox(height: 6),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(adding ? 'Save'.tr : 'Save changes'.tr),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The name of a reading above its fields, with its unit picker.
class _FieldHeading extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const _FieldHeading(this.text, {this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        // On a narrow phone the unit picker drops below the name.
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Text(text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                )),
            if (trailing != null)
              FittedBox(fit: BoxFit.scaleDown, child: trailing!),
          ],
        ),
      );
}

class _UnitToggle<T> extends StatelessWidget {
  final Map<T, String> units;
  final T selected;
  final ValueChanged<T> onChanged;
  const _UnitToggle({
    required this.units,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => SegmentedButton<T>(
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          selectedBackgroundColor: AppColors.primary,
          selectedForegroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          side: BorderSide(color: AppColors.tertiary, width: 1.2),
        ),
        segments: [
          for (final e in units.entries)
            ButtonSegment(value: e.key, label: Text(e.value)),
        ],
        selected: {selected},
        onSelectionChanged: (s) => onChanged(s.first),
      );
}
