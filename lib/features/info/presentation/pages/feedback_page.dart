import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_info.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/external_links.dart';
import '../../../../core/widgets/info_widgets.dart';
import '../../data/feedback_service.dart';

/// Collects a rating, a topic and a message and sends them to the team.
/// If the server can't be reached, offers to send the same by email.
class FeedbackPage extends StatefulWidget {
  final FeedbackService service;
  const FeedbackPage({super.key, required this.service});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  static const _topics = ['Suggestion', 'Problem', 'Compliment', 'Other'];

  final _formKey = GlobalKey<FormState>();
  final _message = TextEditingController();
  String _topic = _topics.first;
  int _rating = 0;
  bool _sending = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _sending = true);

    final result = await widget.service.send(
      topic: _topic.toLowerCase(),
      message: _message.text.trim(),
      rating: _rating == 0 ? null : _rating,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    result.fold(
      (f) => showDialog<void>(
        context: context,
        builder: (d) => AlertDialog(
          title: Text('Could not send'.tr),
          content: Text('{error}\n\nYou can send it by email instead.'
              .trArgs({'error': f.message})),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(d),
                child: Text('Cancel'.tr)),
            TextButton(
              onPressed: () {
                Navigator.pop(d);
                _sendByEmail();
              },
              child: Text('Use email'.tr),
            ),
          ],
        ),
      ),
      (_) {
        showInfoSnack(context, 'Thank you! Your feedback was sent.'.tr);
        context.pop();
      },
    );
  }

  Future<void> _sendByEmail() async {
    final (version, os) = await FeedbackService.deviceInfo();
    final body = StringBuffer()
      ..writeln(_message.text.trim())
      ..writeln()
      ..writeln('---')
      ..writeln('Topic: $_topic')
      ..writeln('Rating: ${_rating == 0 ? 'not given' : '$_rating / 5'}')
      ..writeln('App: $version · $os');
    final ok = await ExternalLinks.email(
      to: AppInfo.feedbackEmail,
      subject: '${AppInfo.appName} feedback: $_topic',
      body: body.toString(),
    );
    if (!ok && mounted) {
      showInfoSnack(
          context,
          'No email app found. Write to {email}'
              .trArgs({'email': AppInfo.feedbackEmail}),
          error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Send feedback'.tr,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            Text(
              ('We read every message. Tell us what you like, what is '
                      'confusing, or what we should build next.')
                  .tr,
              style: TextStyle(height: 1.45, color: AppColors.textSecondary),
            ),
            const SectionLabel('How do you like MediSathi?'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var star = 1; star <= 5; star++)
                  IconButton(
                    tooltip: star == 1
                        ? '1 star'.tr
                        : '{n} stars'.trArgs({'n': star}),
                    iconSize: 36,
                    onPressed: () => setState(
                        () => _rating = _rating == star ? 0 : star),
                    icon: Icon(
                      star <= _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: star <= _rating
                          ? AppColors.warning
                          : AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
            const SectionLabel('Topic'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final topic in _topics)
                  ChoiceChip(
                    label: Text(topic.tr),
                    selected: _topic == topic,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _topic = topic),
                  ),
              ],
            ),
            const SectionLabel('Your message'),
            TextFormField(
              controller: _message,
              minLines: 5,
              maxLines: 10,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Write your feedback here'.tr,
                alignLabelWithHint: true,
              ),
              validator: (v) => (v ?? '').trim().length < 5
                  ? 'Please write a few words'.tr
                  : null,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text('Send feedback'.tr),
            ),
            const SizedBox(height: 10),
            Text(
              ('Your app version and phone type are sent with your message '
                      'to help us fix problems.')
                  .tr,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
