import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/presentation/widgets/auth_submit_button.dart';
import '../../domain/entities/medication.dart';
import '../../domain/entities/scanned_medicine.dart';
import '../bloc/medication_bloc.dart';
import '../utils/medication_format.dart';

/// Add a medicine, or edit one when [initial] is given.
/// [prefill] starts a new medicine from a scan, for the user to check.
/// Pops with `true` once the medicine is saved.
class MedicationFormPage extends StatefulWidget {
  final Medication? initial;
  final ScannedMedicine? prefill;
  const MedicationFormPage({super.key, this.initial, this.prefill});

  @override
  State<MedicationFormPage> createState() => _MedicationFormPageState();
}

class _MedicationFormPageState extends State<MedicationFormPage> {
  static const _maxTimes = 12; // API limit
  static const _allDays = {0, 1, 2, 3, 4, 5, 6};
  // Made when used, so it follows a change of language.
  static DateFormat get _dateFormat => DateFormat('d MMM yyyy');

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _dose;
  late final TextEditingController _instructions;

  String? _type;
  String? _timing;

  bool _hasSchedule = true;
  List<TimeOfDay> _times = [];
  Set<int> _days = {..._allDays};
  DateTime? _startDate;
  DateTime? _endDate;
  bool _remindersEnabled = true;
  String _alertStyle = AlertStyle.notification;

  // Stock tracking (inventory).
  static const _maxRemindDays = 30; // API limit
  bool _trackStock = false;
  late final TextEditingController _quantity;
  late final TextEditingController _perDose;
  bool _refillReminder = true;
  int _remindDaysBefore = 3;

  /// Shown under the schedule card after a failed submit.
  String? _scheduleError;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final m = widget.initial;
    final scan = widget.prefill;
    _name = TextEditingController(text: m?.name ?? scan?.name);
    _dose = TextEditingController(text: m?.dose ?? scan?.dose);
    _instructions = TextEditingController(text: m?.instructions);
    _type = m?.medicineType ?? scan?.medicineType;
    _timing = m?.intakeTiming ?? scan?.intakeTiming;

    final inv = m?.inventory;
    _trackStock = inv != null;
    _quantity = TextEditingController(
        text: inv == null ? '' : MedicationFormat.amount(inv.quantity));
    _perDose = TextEditingController(
        text: MedicationFormat.amount(inv?.unitsPerDose ?? 1));
    _refillReminder = inv?.refillReminderEnabled ?? true;
    _remindDaysBefore = inv?.remindDaysBefore ?? 3;

    if (scan != null) {
      _hasSchedule = !scan.asNeeded;
      _times = scan.reminderTimes
          .map(MedicationFormat.parseTime)
          .whereType<TimeOfDay>()
          .toList();
      if (scan.durationDays != null) {
        final today = DateUtils.dateOnly(DateTime.now());
        _startDate = today;
        _endDate = DateUtils.addDaysToDate(today, scan.durationDays! - 1);
      }
    }

    if (m != null) {
      final s = m.schedule;
      _hasSchedule = s != null;
      if (s != null) {
        _times = s.reminderTimes
            .map(MedicationFormat.parseTime)
            .whereType<TimeOfDay>()
            .toList();
        _days = s.daysOfWeek?.toSet() ?? {..._allDays};
        _startDate = s.startDate;
        _endDate = s.endDate;
        _remindersEnabled = s.remindersEnabled;
        _alertStyle = s.alertStyle;
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _dose.dispose();
    _instructions.dispose();
    _quantity.dispose();
    _perDose.dispose();
    super.dispose();
  }

  // ---- schedule editing ----

  Future<void> _addTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      helpText: 'Reminder time'.tr,
    );
    if (picked == null || !mounted) return;
    if (_times.contains(picked)) return; // the API rejects duplicates
    setState(() {
      _times = [..._times, picked]
        ..sort((a, b) => (a.hour * 60 + a.minute) - (b.hour * 60 + b.minute));
      _scheduleError = null;
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final current = isStart ? _startDate : _endDate;
    // An end date can never be before the start date.
    final first = isStart ? DateTime(2000) : (_startDate ?? DateTime(2000));
    var initial = current ?? (isStart ? today : (_startDate ?? today));
    if (initial.isBefore(first)) initial = first;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime(2100),
      helpText: isStart ? 'Start date'.tr : 'End date (last day)'.tr,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
      } else {
        _endDate = picked;
      }
    });
  }

  // ---- submit ----

  void _submit() {
    FocusScope.of(context).unfocus();
    final fieldsOk = _formKey.currentState?.validate() ?? false;

    String? scheduleError;
    if (_hasSchedule) {
      if (_times.isEmpty) {
        scheduleError = 'Add at least one reminder time'.tr;
      } else if (_days.isEmpty) {
        scheduleError = 'Select at least one day'.tr;
      }
    }
    setState(() => _scheduleError = scheduleError);
    if (!fieldsOk || scheduleError != null) return;

    final instructions = _instructions.text.trim();
    final input = MedicationInput(
      name: _name.text.trim(),
      medicineType: _type !,
      dose: _dose.text.trim(),
      intakeTiming: _timing!,
      instructions: instructions.isEmpty ? null : instructions,
      schedule: !_hasSchedule
          ? null
          : MedicationSchedule(
              reminderTimes: _times.map(MedicationFormat.apiTime).toList(),
              // Keep the saved timezone on edit; new ones get the device's.
              timezone: widget.initial?.schedule?.timezone,
              daysOfWeek:
                  _days.length == 7 ? null : (_days.toList()..sort()),
              startDate: _startDate,
              endDate: _endDate,
              remindersEnabled: _remindersEnabled,
              alertStyle: _alertStyle,
            ),
      inventory: !_trackStock
          ? null
          : MedicationInventory(
              quantity: double.parse(_quantity.text.trim()),
              unitsPerDose: double.parse(_perDose.text.trim()),
              refillReminderEnabled: _refillReminder,
              remindDaysBefore: _remindDaysBefore,
            ),
    );

    final bloc = context.read<MedicationBloc>();
    if (_isEdit) {
      bloc.add(MedicationUpdated(id: widget.initial!.id, input: input));
    } else {
      bloc.add(MedicationAdded(input));
    }
  }

  void _onActionResult(BuildContext context, MedicationState state) {
    final mine = state.action ==
        (_isEdit ? MedicationAction.update : MedicationAction.add);
    if (!mine) return;
    if (state.actionStatus == ActionStatus.success) {
      // The list page shows the confirmation.
      Navigator.of(context).pop(true);
    } else if (state.actionStatus == ActionStatus.failure) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(state.actionMessage ?? 'Something went wrong'.tr),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
    }
  }

  // ---- UI ----

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MedicationBloc, MedicationState>(
      listenWhen: (p, c) => p.actionStatus != c.actionStatus,
      listener: _onActionResult,
      builder: (context, state) {
        final saving = state.isBusy;
        // Keep a saved value selectable even if the server no longer lists it.
        final types = _withCurrent(state.options.medicineTypes, _type);
        final timings = _withCurrent(state.options.intakeTimings, _timing);

        return Scaffold(
          appBar: AppBar(
            title: Text(_isEdit ? 'Edit medicine'.tr : 'Add medicine'.tr,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          body: SafeArea(
            child: AbsorbPointer(
              absorbing: saving,
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    if (widget.prefill != null)
                      const _ScanNotice(),
                    _SectionTitle('Medicine'.tr),
                    TextFormField(
                      controller: _name,
                      maxLength: 150,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      validator: (v) => Validators.requiredField(v, 'Name'.tr),
                      decoration: InputDecoration(
                        labelText: 'Medicine name'.tr,
                        hintText: 'e.g. Paracetamol'.tr,
                        prefixIcon: const Icon(Icons.medication_outlined),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _type,
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(16),
                      dropdownColor: AppColors.surface,
                      validator: (v) => v == null ? 'Type is required'.tr : null,
                      decoration: InputDecoration(
                        labelText: 'Type'.tr,
                        prefixIcon: const Icon(Icons.category_outlined),
                      ),
                      items: [
                        for (final t in types)
                          DropdownMenuItem(
                            value: t,
                            child: Text(MedicationFormat.label(t)),
                          ),
                      ],
                      onChanged: (v) => setState(() => _type = v),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dose,
                      maxLength: 100,
                      textInputAction: TextInputAction.next,
                      validator: (v) => Validators.requiredField(v, 'Dose'.tr),
                      decoration: InputDecoration(
                        labelText: 'Dose'.tr,
                        hintText: 'e.g. 500 mg'.tr,
                        prefixIcon: const Icon(Icons.scale_outlined),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 20),
                    _SectionTitle('When to take it'.tr),
                    FormField<String>(
                      initialValue: _timing,
                      validator: (_) =>
                          _timing == null ? 'Choose when to take it'.tr : null,
                      builder: (field) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              for (final t in timings)
                                ChoiceChip(
                          
                                  label: Text(MedicationFormat.label(t)),
                                  selected: _timing == t,
                                  showCheckmark: false,
                                  onSelected: (_) {
                                    setState(() => _timing = t);
                                    field.didChange(t);
                                  },
                                ),
                            ],
                          ),
                          if (field.hasError) _ErrorText(field.errorText!),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _instructions,
                      maxLength: 1000,
                      minLines: 2,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: 'Instructions (optional)'.tr,
                        hintText:
                            'e.g. Take 1 tablet twice a day with water'.tr,
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionTitle('Schedule'.tr),
                    _buildScheduleCard(context),
                    if (_scheduleError != null) _ErrorText(_scheduleError!),
                    const SizedBox(height: 12),
                    _SectionTitle('Stock and refills'.tr),
                    _buildStockCard(),
                    const SizedBox(height: 28),
                    AuthSubmitButton(
                      label: _isEdit ? 'Save changes'.tr : 'Add medicine'.tr,
                      isLoading: saving,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScheduleCard(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _scheduleError != null ? AppColors.error : AppColors.tertiary,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            value: _hasSchedule,
            onChanged: (v) => setState(() {
              _hasSchedule = v;
              _scheduleError = null;
            }),
            title: Text('Take on a schedule'.tr,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              _hasSchedule
                  ? 'Set the times you take this medicine'.tr
                  : 'Off: taken only when needed'.tr,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          if (_hasSchedule) ...[
            Divider(height: 1, color: AppColors.tertiary),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('Times'.tr),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final t in _times)
                        InputChip(
                          label: Text(localizations.formatTimeOfDay(t)),
                          onDeleted: () =>
                              setState(() => _times = [..._times]..remove(t)),
                        ),
                      if (_times.length < _maxTimes)
                        ActionChip(
                          avatar: Icon(Icons.add_rounded,
                              size: 18, color: AppColors.primary),
                          label: Text('Add time'.tr),
                          onPressed: _addTime,
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _FieldLabel('Days'.tr),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (var d = 0; d < 7; d++)
                        FilterChip(
                          label: Text(MedicationFormat.dayNames[d].tr),
                          selected: _days.contains(d),
                          showCheckmark: false,
                          onSelected: (on) => setState(() {
                            _days = {..._days};
                            on ? _days.add(d) : _days.remove(d);
                            _scheduleError = null;
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _FieldLabel('Course dates (optional)'.tr),
                  Row(
                    children: [
                      Expanded(
                        child: _DateField(
                          label: 'Start'.tr,
                          value: _startDate == null
                              ? null
                              : _dateFormat.format(_startDate!),
                          onTap: () => _pickDate(isStart: true),
                          onClear: () => setState(() => _startDate = null),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DateField(
                          label: 'End'.tr,
                          value: _endDate == null
                              ? null
                              : _dateFormat.format(_endDate!),
                          onTap: () => _pickDate(isStart: false),
                          onClear: () => setState(() => _endDate = null),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SwitchListTile(
              value: _remindersEnabled,
              onChanged: (v) => setState(() => _remindersEnabled = v),
              secondary: const Icon(Icons.notifications_active_outlined,
                  color: AppColors.icon),
              title: Text('Remind me'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            if (_remindersEnabled)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('Alert me with'.tr),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          avatar: Icon(Icons.notifications_none_rounded,
                              size: 18,
                              color: _alertStyle == AlertStyle.notification
                                  ? Colors.white
                                  : AppColors.primary),
                          label: Text('Notification'.tr),
                          selected: _alertStyle == AlertStyle.notification,
                          showCheckmark: false,
                          onSelected: (_) => setState(
                              () => _alertStyle = AlertStyle.notification),
                        ),
                        ChoiceChip(
                          avatar: Icon(Icons.alarm_rounded,
                              size: 18,
                              color: _alertStyle == AlertStyle.alarm
                                  ? Colors.white
                                  : AppColors.primary),
                          label: Text('Alarm'.tr),
                          selected: _alertStyle == AlertStyle.alarm,
                          showCheckmark: false,
                          onSelected: (_) =>
                              setState(() => _alertStyle = AlertStyle.alarm),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _alertStyle == AlertStyle.alarm
                          ? 'Rings with your alarm sound at alarm volume and '
                                  'vibrates strongly.'
                              .tr
                          : 'A normal notification with its usual sound.'.tr,
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStockCard() {
    String? positive(String? v, {required bool allowZero}) {
      if (!_trackStock) return null;
      final n = double.tryParse(v?.trim() ?? '');
      if (n == null || n < 0 || (!allowZero && n == 0)) {
        return 'Enter a number'.tr;
      }
      return null;
    }

    final numberFormat = [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
    ];
    const numberKeyboard = TextInputType.numberWithOptions(decimal: true);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.tertiary, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            value: _trackStock,
            onChanged: (v) => setState(() => _trackStock = v),
            title: Text('Track my stock'.tr,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              _trackStock
                  ? 'Each dose you mark as taken is deducted'.tr
                  : 'Off: no stock count or refill reminders'.tr,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          if (_trackStock) ...[
            Divider(height: 1, color: AppColors.tertiary),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantity,
                      keyboardType: numberKeyboard,
                      inputFormatters: numberFormat,
                      validator: (v) => positive(v, allowZero: true),
                      decoration: InputDecoration(
                        labelText: 'In stock now'.tr,
                        hintText: 'e.g. 30'.tr,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _perDose,
                      keyboardType: numberKeyboard,
                      inputFormatters: numberFormat,
                      validator: (v) => positive(v, allowZero: false),
                      decoration: InputDecoration(
                        labelText: 'Used per dose'.tr,
                        hintText: 'e.g. 1'.tr,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 6, 16, 4),
              child: Text(
                'Count in your own unit: tablets, ml, puffs...'.tr,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            SwitchListTile(
              value: _refillReminder,
              onChanged: (v) => setState(() => _refillReminder = v),
              secondary: const Icon(Icons.inventory_2_outlined,
                  color: AppColors.icon),
              title: Text('Remind me to refill'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            if (_refillReminder)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _remindDaysBefore == 0
                                ? 'Only on the day it runs out'.tr
                                : _remindDaysBefore == 1
                                    ? '1 day before it runs out'.tr
                                    : '{n} days before it runs out'
                                        .trArgs({'n': _remindDaysBefore}),
                            style: TextStyle(
                                color: AppColors.textPrimary),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Fewer days'.tr,
                          icon: const Icon(Icons.remove_circle_outline_rounded),
                          color: AppColors.primary,
                          onPressed: _remindDaysBefore <= 0
                              ? null
                              : () => setState(() => _remindDaysBefore--),
                        ),
                        IconButton(
                          tooltip: 'More days'.tr,
                          icon: const Icon(Icons.add_circle_outline_rounded),
                          color: AppColors.primary,
                          onPressed: _remindDaysBefore >= _maxRemindDays
                              ? null
                              : () => setState(() => _remindDaysBefore++),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        _hasSchedule
                            ? (_remindDaysBefore == 0
                                ? 'You get one reminder, on the day your '
                                        'stock runs out.'
                                    .tr
                                : 'You get a second reminder on the day '
                                        'your stock runs out.'
                                    .tr)
                            // The run-out date is worked out from the schedule.
                            : 'Refill reminders need a schedule. Without one '
                                    'the stock is only counted.'
                                .tr,
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  static List<String> _withCurrent(List<String> options, String? current) =>
      current == null || options.contains(current)
          ? options
          : [...options, current];
}

class _ScanNotice extends StatelessWidget {
  const _ScanNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.tertiaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.fact_check_outlined, color: AppColors.primary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Filled in from your scan. Check every detail against the '
                      'prescription before saving.'
                  .tr,
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String text;
  const _ErrorText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 6),
      child: Text(text,
          style: const TextStyle(fontSize: 12, color: AppColors.error)),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        padding: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.tertiary, width: 1.2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: value == null
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
            ),
            if (value == null)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.calendar_today_outlined,
                    size: 18, color: AppColors.icon),
              )
            else
              IconButton(
                tooltip: 'Clear {label} date'.trArgs({'label': label}),
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.close_rounded,
                    size: 18, color: AppColors.textSecondary),
                onPressed: onClear,
              ),
          ],
        ),
      ),
    );
  }
}
