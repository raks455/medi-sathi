import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/info_widgets.dart';
import '../../domain/wellness.dart';
import '../cubit/wellness_cubits.dart';

/// Dashboard card: "How are you feeling right now?" with five moods, then
/// today's answer and the last seven days.
class MoodCheckInCard extends StatefulWidget {
  const MoodCheckInCard({super.key});

  @override
  State<MoodCheckInCard> createState() => _MoodCheckInCardState();
}

class _MoodCheckInCardState extends State<MoodCheckInCard> {
  /// Shows the picker again after today's mood was logged.
  bool _changing = false;

  Future<void> _pick(Mood mood) async {
    final cubit = context.read<MoodCubit>();
    final details = await showModalBottomSheet<_MoodDetails>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _MoodDetailsSheet(mood: mood),
    );
    if (details == null || !mounted) return;
    final error =
        await cubit.checkIn(mood, note: details.note, tags: details.tags);
    if (!mounted) return;
    if (error != null) {
      showInfoSnack(context, error, error: true);
    } else {
      setState(() => _changing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MoodCubit, MoodState>(
      builder: (context, state) {
        final today = state.today;
        final asking = today == null || _changing;
        return InfoCard(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    asking
                        ? 'How are you feeling right now?'
                        : 'Today you feel ${today.mood.label.toLowerCase()}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (state.saving)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (!asking)
                  TextButton(
                    onPressed: () => setState(() => _changing = true),
                    child: const Text('Update'),
                  )
                else if (today != null)
                  TextButton(
                    onPressed: () => setState(() => _changing = false),
                    child: const Text('Cancel'),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (asking)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final m in Mood.values)
                    _MoodButton(
                      mood: m,
                      onTap: state.saving ? null : () => _pick(m),
                    ),
                ],
              )
            else ...[
              Row(
                children: [
                  Text(today.mood.emoji, style: const TextStyle(fontSize: 34)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      [
                        'Checked in at ${DateFormat.jm().format(today.recordedAt.toLocal())}',
                        if (today.tags.isNotEmpty) today.tags.join(', '),
                        if (today.note != null) '"${today.note}"',
                      ].join('\n'),
                      style: TextStyle(
                          height: 1.4, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _WeekStrip(entries: state.entries),
            ],
          ],
        );
      },
    );
  }
}

class _MoodButton extends StatelessWidget {
  final Mood mood;
  final VoidCallback? onTap;
  const _MoodButton({required this.mood, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: mood.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: mood.color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Text(mood.emoji, style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(height: 4),
              Text(mood.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

/// The last seven days, one dot per day showing that day's latest mood.
class _WeekStrip extends StatelessWidget {
  final List<MoodEntry> entries;
  const _WeekStrip({required this.entries});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = [
      for (var i = 6; i >= 0; i--)
        DateTime(now.year, now.month, now.day).subtract(Duration(days: i)),
    ];
    MoodEntry? latestOn(DateTime day) {
      for (final e in entries) {
        final l = e.recordedAt.toLocal();
        if (l.year == day.year && l.month == day.month && l.day == day.day) {
          return e;
        }
      }
      return null;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final day in days)
          Column(children: [
            Text(
              latestOn(day)?.mood.emoji ?? '·',
              style: TextStyle(
                  fontSize: 18,
                  color: AppColors.textSecondary.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 2),
            Text(DateFormat.E().format(day).substring(0, 2),
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ]),
      ],
    );
  }
}

class _MoodDetails {
  final String? note;
  final List<String> tags;
  const _MoodDetails(this.note, this.tags);
}

class _MoodDetailsSheet extends StatefulWidget {
  final Mood mood;
  const _MoodDetailsSheet({required this.mood});

  @override
  State<_MoodDetailsSheet> createState() => _MoodDetailsSheetState();
}

class _MoodDetailsSheetState extends State<_MoodDetailsSheet> {
  final _note = TextEditingController();
  final _tags = <String>{};

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Text(widget.mood.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 10),
              Text('Feeling ${widget.mood.label.toLowerCase()}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  )),
            ]),
            const SectionLabel('Anything else? (optional)'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in [...Mood.suggestedTags, ...Mood.cycleTags])
                  FilterChip(
                    label: Text(tag),
                    selected: _tags.contains(tag),
                    onSelected: (on) => setState(
                        () => on ? _tags.add(tag) : _tags.remove(tag)),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _note,
              maxLength: 500,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Add a note'),
            ),
            const SizedBox(height: 6),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                  context, _MoodDetails(_note.text, _tags.toList())),
              child: const Text('Save check-in'),
            ),
          ],
        ),
      ),
    );
  }
}
