import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_info.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/external_links.dart';
import '../../../../core/widgets/info_widgets.dart';

/// Frequently asked questions and ways to contact support.
class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  static const _faqs = [
    (
      'How do I add a medicine?',
      'Open the Medicine tab and tap the + button. Choose "Enter manually" to '
          'type the details, or "Scan prescription or label" to fill them in '
          'from a photo.'
    ),
    (
      'I am not getting reminders',
      'Make sure notifications are allowed for MediSathi in your phone '
          'settings, and that you are signed in. Some phones stop apps in the '
          'background to save battery: set MediSathi to "Unrestricted" or '
          '"Not optimised" in battery settings.'
    ),
    (
      'How do I mark a dose as taken?',
      'On the Dashboard, tap "Take" next to the dose. You can also tap a '
          'reminder notification to open it.'
    ),
    (
      'How does refill tracking work?',
      'Turn on "Track my stock" when adding or editing a medicine. Each dose '
          'you mark as taken lowers the count, and you get an alert before it '
          'runs out. Use "Add stock" from the medicine\'s menu after a refill.'
    ),
    (
      'Can I pause a medicine?',
      'Yes. In the Medicine tab, open the medicine\'s menu and choose "Stop '
          'medicine". It keeps its history but stops doses and reminders until '
          'you resume it.'
    ),
    (
      'Where are my prescriptions and reports stored?',
      'Go to Profile and open Health Records. Prescriptions and other '
          'documents (lab reports, scans, discharge summaries) are kept in '
          'separate folders. Tap Upload to add a photo or PDF. After scanning '
          'a prescription you can also choose "Save to Health Records".'
    ),
    (
      'How do I track weight, blood pressure or my period?',
      'Open Profile and choose Weight & vitals, Period tracker or Pregnancy '
          'tracker. Your mood check-in is on the Dashboard.'
    ),
    (
      'How do I switch between light and dark mode?',
      'Go to Profile, tap the menu button at the top right, and choose Light, '
          'Dark or System under Appearance.'
    ),
    (
      'How do I delete my account?',
      'Open the Profile menu and tap "Delete account", or email '
          '${AppInfo.supportEmail} from the address you signed up with. We '
          'delete your account and all of its data within 30 days.'
    ),
  ];

  Future<void> _email(BuildContext context, String subject) async {
    final ok = await ExternalLinks.email(
      to: AppInfo.supportEmail,
      subject: '${AppInfo.appName}: $subject',
    );
    if (!ok && context.mounted) {
      showInfoSnack(
          context, 'No email app found. Write to ${AppInfo.supportEmail}',
          error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & support',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          const SectionLabel('Frequently asked questions'),
          InfoCard(children: [
            for (final (i, faq) in _faqs.indexed) ...[
              if (i > 0) const InfoDivider(),
              Theme(
                // No lines above and below an open tile.
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  shape: const Border(),
                  collapsedShape: const Border(),
                  iconColor: AppColors.primary,
                  collapsedIconColor: AppColors.textSecondary,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedAlignment: Alignment.centerLeft,
                  title: Text(
                    faq.$1,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  children: [
                    Text(faq.$2,
                        style: TextStyle(
                            height: 1.5, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ]),
          const SectionLabel('Still need help?'),
          InfoCard(children: [
            InfoTile(
              icon: Icons.support_agent_rounded,
              title: 'Contact support',
              subtitle: AppInfo.supportEmail,
              onTap: () => _email(context, 'Help needed'),
            ),
            const InfoDivider(),
            InfoTile(
              icon: Icons.bug_report_outlined,
              title: 'Report a problem',
              subtitle: 'Tell us what went wrong',
              onTap: () => context.push(AppRoutes.feedback),
            ),
            const InfoDivider(),
            InfoTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              onTap: () => context.push(AppRoutes.privacyPolicy),
            ),
            const InfoDivider(),
            InfoTile(
              icon: Icons.gavel_rounded,
              title: 'Terms & Conditions',
              onTap: () => context.push(AppRoutes.terms),
            ),
          ]),
        ],
      ),
    );
  }
}
