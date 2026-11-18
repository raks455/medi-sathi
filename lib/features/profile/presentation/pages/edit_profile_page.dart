import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/info_widgets.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/user_profile.dart';
import '../cubit/profile_cubit.dart';

/// Name, date of birth, gender, blood group, diseases and allergies.
class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      // The form starts from the saved profile, so it waits for it: saving a
      // form that started empty would wipe details the user already has.
      body: BlocBuilder<ProfileCubit, ProfileState>(
        buildWhen: (a, b) =>
            (a.profile == null) != (b.profile == null) ||
            a.error != b.error ||
            a.loading != b.loading,
        builder: (context, state) {
          final profile = state.profile;
          if (profile != null) return _ProfileForm(initial: profile);
          if (state.loading || state.error == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: context.read<ProfileCubit>().load,
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileForm extends StatefulWidget {
  final UserProfile initial;
  const _ProfileForm({required this.initial});

  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial.fullName);
  late DateTime? _born = widget.initial.dateOfBirth;
  late Gender? _gender = widget.initial.gender;
  late String? _bloodGroup = widget.initial.bloodGroup;
  late List<String> _conditions = [...widget.initial.conditions];
  late List<String> _allergies = [...widget.initial.allergies];
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _born ?? DateTime(now.year - 30),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.calendar,
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Date of birth',
    );
    if (picked != null && mounted) setState(() => _born = picked);
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final cubit = context.read<ProfileCubit>();
    final auth = context.read<AuthBloc>();
    setState(() => _saving = true);
    final error = await cubit.save(UserProfile(
      email: widget.initial.email,
      fullName: _name.text.trim(),
      dateOfBirth: _born,
      gender: _gender,
      bloodGroup: _bloodGroup,
      conditions: _conditions,
      allergies: _allergies,
    ));
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      showInfoSnack(context, error, error: true);
      return;
    }
    // The name on the dashboard and profile comes from the saved session.
    auth.add(const AuthUserRequested());
    showInfoSnack(context, 'Profile saved');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final born = _born;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            maxLength: 100,
            decoration: const InputDecoration(
              labelText: 'Full name',
              prefixIcon: Icon(Icons.person_outline_rounded),
              counterText: '',
            ),
            validator: (v) => (v ?? '').trim().length < 2
                ? 'Enter your name'
                : null,
          ),
          const SizedBox(height: 14),
          // Age is worked out from the date of birth, so it stays right
          // every year.
          InkWell(
            onTap: _pickBirthDate,
            borderRadius: BorderRadius.circular(14),
            child: InputDecorator(
              isEmpty: born == null,
              decoration: InputDecoration(
                labelText: 'Date of birth',
                prefixIcon: const Icon(Icons.cake_outlined),
                suffixIcon: born == null
                    ? const Icon(Icons.calendar_today_rounded, size: 20)
                    : IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => setState(() => _born = null),
                      ),
              ),
              child: born == null
                  ? null
                  : Text(
                      '${DateFormat.yMMMd().format(born)}  ·  '
                      '${UserProfile.ageOn(born)} years old',
                      style: TextStyle(
                          fontSize: 16, color: AppColors.textPrimary),
                    ),
            ),
          ),
          const SectionLabel('Gender'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final g in Gender.values)
              ChoiceChip(
                label: Text(g.label),
                selected: _gender == g,
                showCheckmark: false,
                onSelected: (on) => setState(() => _gender = on ? g : null),
              ),
          ]),
          const SectionLabel('Blood group'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final b in UserProfile.bloodGroups)
              ChoiceChip(
                label: Text(b),
                selected: _bloodGroup == b,
                showCheckmark: false,
                onSelected: (on) =>
                    setState(() => _bloodGroup = on ? b : null),
              ),
          ]),
          const SectionLabel('Diseases & conditions'),
          _TagPicker(
            suggestions: UserProfile.commonConditions,
            selected: _conditions,
            hint: 'Add another disease',
            onChanged: (v) => setState(() => _conditions = v),
          ),
          const SectionLabel('Allergies'),
          _TagPicker(
            suggestions: UserProfile.commonAllergies,
            selected: _allergies,
            hint: 'Add another allergy',
            onChanged: (v) => setState(() => _allergies = v),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}

/// Chips to pick from [suggestions], plus a field to add something else.
class _TagPicker extends StatefulWidget {
  final List<String> suggestions;
  final List<String> selected;
  final String hint;
  final ValueChanged<List<String>> onChanged;

  const _TagPicker({
    required this.suggestions,
    required this.selected,
    required this.hint,
    required this.onChanged,
  });

  @override
  State<_TagPicker> createState() => _TagPickerState();
}

class _TagPickerState extends State<_TagPicker> {
  static const _max = 30;
  final _custom = TextEditingController();

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  bool _has(String tag) =>
      widget.selected.any((s) => s.toLowerCase() == tag.toLowerCase());

  void _toggle(String tag, bool on) {
    if (on && widget.selected.length >= _max) return;
    widget.onChanged([
      for (final s in widget.selected)
        if (s.toLowerCase() != tag.toLowerCase()) s,
      if (on) tag,
    ]);
  }

  void _addCustom() {
    final text = _custom.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text.isEmpty) return;
    // Typing a suggestion's name picks that suggestion.
    final known = widget.suggestions
        .where((s) => s.toLowerCase() == text.toLowerCase());
    if (!_has(text)) _toggle(known.isEmpty ? text : known.first, true);
    _custom.clear();
  }

  @override
  Widget build(BuildContext context) {
    final suggested = widget.suggestions.map((s) => s.toLowerCase()).toSet();
    final own = [
      for (final s in widget.selected)
        if (!suggested.contains(s.toLowerCase())) s,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final tag in widget.suggestions)
            FilterChip(
              label: Text(tag),
              selected: _has(tag),
              onSelected: (on) => _toggle(tag, on),
            ),
          // Ones the user typed: tap the cross to remove.
          for (final tag in own)
            InputChip(
              label: Text(tag),
              selected: true,
              showCheckmark: false,
              onDeleted: () => _toggle(tag, false),
            ),
        ]),
        const SizedBox(height: 10),
        TextField(
          controller: _custom,
          maxLength: 60,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _addCustom(),
          decoration: InputDecoration(
            hintText: widget.hint,
            counterText: '',
            suffixIcon: IconButton(
              tooltip: 'Add',
              icon: const Icon(Icons.add_circle_outline_rounded),
              onPressed: _addCustom,
            ),
          ),
        ),
      ],
    );
  }
}
