import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';

/// Cuts a translated sentence at `{terms}` and `{privacy}` so the two names
/// can be links, in whatever order the language puts them.
List<T> _withLinks<T>(
  String sentence, {
  required T Function(String text) plain,
  required T Function(String name) link,
}) {
  final parts = <T>[];
  sentence.splitMapJoin(
    RegExp(r'\{(terms|privacy)\}'),
    onMatch: (m) {
      parts.add(link(m[1]!));
      return '';
    },
    onNonMatch: (text) {
      if (text.isNotEmpty) parts.add(plain(text));
      return '';
    },
  );
  return parts;
}

/// "I agree to the Terms & Conditions and Privacy Policy" checkbox. The two
/// names open the documents.
class TermsConsent extends StatefulWidget {
  final bool value;
  final bool showError;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const TermsConsent({
    super.key,
    required this.value,
    required this.onChanged,
    this.showError = false,
    this.enabled = true,
  });

  @override
  State<TermsConsent> createState() => _TermsConsentState();
}

class _TermsConsentState extends State<TermsConsent> {
  late final _termsTap = TapGestureRecognizer()
    ..onTap = () => context.push(AppRoutes.terms);
  late final _privacyTap = TapGestureRecognizer()
    ..onTap = () => context.push(AppRoutes.privacyPolicy);

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final link = TextStyle(
      color: AppColors.primary,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.primary,
    );
    final error = widget.showError && !widget.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: Checkbox(
                key: const ValueKey('terms-consent-checkbox'),
                value: widget.value,
                isError: error,
                onChanged: widget.enabled
                    ? (v) => widget.onChanged(v ?? false)
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(
                        height: 1.4, color: AppColors.textSecondary),
                    children: _withLinks<InlineSpan>(
                      'I have read and agree to the {terms} and {privacy}.'.tr,
                      plain: (text) => TextSpan(text: text),
                      link: (name) => name == 'terms'
                          ? TextSpan(
                              text: 'Terms & Conditions'.tr,
                              style: link,
                              recognizer: _termsTap)
                          : TextSpan(
                              text: 'Privacy Policy'.tr,
                              style: link,
                              recognizer: _privacyTap),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (error)
          Padding(
            padding: const EdgeInsets.only(left: 40, top: 4),
            child: Text(
              ('Please accept the Terms & Conditions and Privacy Policy to '
                      'continue.')
                  .tr,
              style: TextStyle(
                  fontSize: 12.5, color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }
}

/// Passive notice for screens where an account may be created without the
/// sign-up form (Google sign-in from the sign-in screen).
class LegalNotice extends StatelessWidget {
  const LegalNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(fontSize: 12.5, color: AppColors.textSecondary);
    Widget link(String text, String route) => GestureDetector(
          onTap: () => context.push(route),
          child: Text(
            text,
            style: base.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primary,
            ),
          ),
        );
    return Wrap(
      alignment: WrapAlignment.center,
      runSpacing: 2,
      children: _withLinks<Widget>(
        'By continuing, you agree to our {terms} and {privacy}.'.tr,
        plain: (text) => Text(text, style: base),
        link: (name) => name == 'terms'
            ? link('Terms & Conditions'.tr, AppRoutes.terms)
            : link('Privacy Policy'.tr, AppRoutes.privacyPolicy),
      ),
    );
  }
}
