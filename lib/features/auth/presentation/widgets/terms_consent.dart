import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';

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
                    children: [
                      const TextSpan(text: 'I have read and agree to the '),
                      TextSpan(
                          text: 'Terms & Conditions',
                          style: link,
                          recognizer: _termsTap),
                      const TextSpan(text: ' and '),
                      TextSpan(
                          text: 'Privacy Policy',
                          style: link,
                          recognizer: _privacyTap),
                      const TextSpan(text: '.'),
                    ],
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
              'Please accept the Terms & Conditions and Privacy Policy to '
              'continue.',
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
      children: [
        Text('By continuing, you agree to our ', style: base),
        link('Terms & Conditions', AppRoutes.terms),
        Text(' and ', style: base),
        link('Privacy Policy', AppRoutes.privacyPolicy),
        Text('.', style: base),
      ],
    );
  }
}
