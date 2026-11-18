import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/info_widgets.dart';

/// What the user picked in the profile menu.
enum ProfileMenuAction {
  appTour,
  helpSupport,
  feedback,
  aboutApp,
  aboutUs,
  privacyPolicy,
  terms,
  deleteAccount,
  signOut,
}

/// Opens the profile menu. The theme is changed inside the sheet; any other
/// choice closes it and is returned to the caller.
Future<ProfileMenuAction?> showProfileMenu(BuildContext context) {
  return showModalBottomSheet<ProfileMenuAction>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _ProfileMenuSheet(),
  );
}

class _ProfileMenuSheet extends StatelessWidget {
  const _ProfileMenuSheet();

  static const _groups = [
    [
      (ProfileMenuAction.appTour, Icons.explore_outlined, 'App tour',
          'See how MediSathi works'),
      (ProfileMenuAction.helpSupport, Icons.help_outline_rounded,
          'Help & support', 'FAQs and contact'),
      (ProfileMenuAction.feedback, Icons.rate_review_outlined,
          'Send feedback', 'Ideas, problems, praise'),
    ],
    [
      (ProfileMenuAction.aboutApp, Icons.info_outline_rounded,
          'About the app', null),
      (ProfileMenuAction.aboutUs, Icons.groups_outlined, 'About us', null),
      (ProfileMenuAction.privacyPolicy, Icons.privacy_tip_outlined,
          'Privacy Policy', null),
      (ProfileMenuAction.terms, Icons.gavel_rounded, 'Terms & Conditions',
          null),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(
            'Menu',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SectionLabel('Appearance'),
          const ThemeModeSelector(),
          for (final (i, group) in _groups.indexed) ...[
            SectionLabel(i == 0 ? 'Get started' : 'About'),
            InfoCard(children: [
              for (final (j, item) in group.indexed) ...[
                if (j > 0) const InfoDivider(),
                InfoTile(
                  icon: item.$2,
                  title: item.$3,
                  subtitle: item.$4,
                  onTap: () => Navigator.of(context).pop(item.$1),
                ),
              ],
            ]),
          ],
          const SectionLabel('Account'),
          InfoCard(children: [
            InfoTile(
              icon: Icons.person_remove_outlined,
              title: 'Delete account',
              subtitle: 'Request deletion by email',
              onTap: () =>
                  Navigator.of(context).pop(ProfileMenuAction.deleteAccount),
            ),
            const InfoDivider(),
            InfoTile(
              icon: Icons.logout_rounded,
              title: 'Sign out',
              color: AppColors.error,
              onTap: () => Navigator.of(context).pop(ProfileMenuAction.signOut),
            ),
          ]),
        ],
      ),
    );
  }
}

/// System / Light / Dark switch.
class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, mode) => SizedBox(
        width: double.infinity,
        child: SegmentedButton<ThemeMode>(
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            selectedBackgroundColor: AppColors.primary,
            selectedForegroundColor: Colors.white,
            side: BorderSide(color: AppColors.tertiary, width: 1.2),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          segments: const [
            ButtonSegment(
              value: ThemeMode.system,
              icon: Icon(Icons.brightness_auto_rounded),
              label: Text('System'),
            ),
            ButtonSegment(
              value: ThemeMode.light,
              icon: Icon(Icons.light_mode_rounded),
              label: Text('Light'),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              icon: Icon(Icons.dark_mode_rounded),
              label: Text('Dark'),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (s) => context.read<ThemeCubit>().setMode(s.first),
        ),
      ),
    );
  }
}
