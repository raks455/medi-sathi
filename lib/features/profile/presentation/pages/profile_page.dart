import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_info.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/external_links.dart';
import '../../../../core/widgets/info_widgets.dart';
import '../../../app_tour/app_tour.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../notification/data/services/push_notification_service.dart';
import '../../../wellness/presentation/widgets/mood_check_in_card.dart';
import '../../../womens_health/presentation/cubit/womens_health_cubits.dart';
import '../../../womens_health/presentation/widgets/cycle_status_card.dart';
import '../cubit/profile_cubit.dart';
import '../widgets/profile_menu_sheet.dart';

/// The signed-in user, health tools and the app menu.
class ProfilePage extends StatefulWidget {
  final PushNotificationService pushService;
  const ProfilePage({super.key, required this.pushService});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _signingOut = false;

  Future<void> _openMenu() async {
    final action = await showProfileMenu(context);
    if (action == null || !mounted) return;
    switch (action) {
      case ProfileMenuAction.appTour:
        await AppTour.show(context);
      case ProfileMenuAction.helpSupport:
        context.push(AppRoutes.help);
      case ProfileMenuAction.feedback:
        context.push(AppRoutes.feedback);
      case ProfileMenuAction.aboutApp:
        context.push(AppRoutes.aboutApp);
      case ProfileMenuAction.aboutUs:
        context.push(AppRoutes.aboutUs);
      case ProfileMenuAction.privacyPolicy:
        context.push(AppRoutes.privacyPolicy);
      case ProfileMenuAction.terms:
        context.push(AppRoutes.terms);
      case ProfileMenuAction.deleteAccount:
        await _requestAccountDeletion();
      case ProfileMenuAction.signOut:
        await _confirmSignOut();
    }
  }

  /// Accounts are deleted by the support team on request by email, so the
  /// request comes from the address the account belongs to.
  Future<void> _requestAccountDeletion() async {
    final email = context.read<AuthBloc>().state.user?.email ?? '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Delete your account?'),
        content: Text(
          'To delete your account, send us an email from the address you '
          'signed up with${email.isEmpty ? '' : ' ($email)'}. We will delete '
          'your account and all its data - medicines, health records, '
          'readings and trackers - within 30 days and reply to confirm.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Write email'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final sent = await ExternalLinks.email(
      to: AppInfo.supportEmail,
      subject: '${AppInfo.appName}: account deletion request',
      body: 'Please delete my ${AppInfo.appName} account and all of its data.'
          '\n\nAccount email: $email\n',
    );
    if (!sent && mounted) {
      showInfoSnack(
          context,
          'No email app found. Email ${AppInfo.supportEmail} from $email '
          'to request deletion.',
          error: true);
    }
  }

  Future<void> _confirmSignOut() async {
    final bloc = context.read<AuthBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
            'You will stop getting medicine reminders on this phone until '
            'you sign in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _signingOut) return;
    // The app leaves for the sign-in screen when the bloc is done.
    _signingOut = true;
    bloc.add(const SignOutRequested());
  }

  /// Opens a health tool, then refreshes the cycle card (a period may have
  /// been logged there).
  Future<void> _openTool(BuildContext context, String route) async {
    final cycle = context.read<CycleCubit>();
    await context.push(route);
    if (!cycle.isClosed) cycle.load();
  }

  static String _initials(String name, String email) {
    final words =
        name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return email.isEmpty ? '?' : email[0].toUpperCase();
    final first = words.first[0];
    final last = words.length > 1 ? words.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            key: AppTourKeys.profileMenuButton,
            tooltip: 'Menu',
            icon: const Icon(Icons.menu_rounded),
            onPressed: _openMenu,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final profileState = context.watch<ProfileCubit>().state;
          final profile = profileState.profile;
          final name = state.user?.fullName ?? profile?.fullName ?? '';
          final email = state.user?.email ?? profile?.email ?? '';
          // The period and pregnancy trackers are only for women.
          final female = profileState.isFemale;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _UserCard(
                name: name,
                email: email,
                initials: _initials(name, email),
                onEdit: () => context.push(AppRoutes.editProfile),
              ),
              const SectionLabel('About me'),
              _AboutMeCard(
                state: profileState,
                onEdit: () => context.push(AppRoutes.editProfile),
                onRetry: context.read<ProfileCubit>().load,
              ),
              if (female) ...[
                const SectionLabel('Today'),
                CycleStatusCard(
                  onOpen: () => _openTool(context, AppRoutes.periodTracker),
                ),
              ],
              const SectionLabel('My health'),
              _HealthGrid(
                showWomensHealth: female,
                onOpen: (route) => _openTool(context, route),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final String name;
  final String email;
  final String initials;
  final VoidCallback onEdit;

  const _UserCard({
    required this.name,
    required this.email,
    required this.initials,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.splashGradient,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF3368A0),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'MediSathi user' : name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit profile',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// Age, gender, blood group, diseases and allergies. Tap to edit.
class _AboutMeCard extends StatelessWidget {
  final ProfileState state;
  final VoidCallback onEdit;
  final VoidCallback onRetry;

  const _AboutMeCard({
    required this.state,
    required this.onEdit,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final p = state.profile;
    if (p == null) {
      return InfoCard(children: [
        state.error == null
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            : InfoTile(
                icon: Icons.refresh_rounded,
                title: 'Could not load your details',
                subtitle: state.error,
                onTap: onRetry,
              ),
      ]);
    }
    String list(List<String> items) =>
        items.isEmpty ? 'None added' : items.join(', ');
    final rows = <(IconData, String, String)>[
      (
        Icons.cake_outlined,
        'Age',
        p.age == null ? 'Not set' : '${p.age} years',
      ),
      (Icons.wc_rounded, 'Gender', p.gender?.label ?? 'Not set'),
      (Icons.bloodtype_outlined, 'Blood group', p.bloodGroup ?? 'Not set'),
      (
        Icons.medical_information_outlined,
        'Diseases & conditions',
        list(p.conditions),
      ),
      (Icons.warning_amber_rounded, 'Allergies', list(p.allergies)),
    ];
    return InfoCard(children: [
      for (final (i, (icon, title, value)) in rows.indexed) ...[
        if (i > 0) const InfoDivider(),
        InfoTile(icon: icon, title: title, subtitle: value, onTap: onEdit),
      ],
      if (p.gender == null) ...[
        const InfoDivider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Text(
            'The period and pregnancy trackers are shown when your gender '
            'is set to female.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
        ),
      ],
    ]);
  }
}

/// Health Records and vitals and, for women, the period and pregnancy
/// trackers.
class _HealthGrid extends StatelessWidget {
  final ValueChanged<String> onOpen;
  final bool showWomensHealth;
  const _HealthGrid({required this.onOpen, required this.showWomensHealth});

  static const _womensRoutes = {
    AppRoutes.periodTracker,
    AppRoutes.pregnancyTracker,
  };

  static const _items = [
    (Icons.folder_shared_rounded, 'Health Records',
        'Prescriptions, lab reports & documents', AppRoutes.healthRecords,
        Color(0xFF3368A0)),
    (Icons.monitor_weight_rounded, 'Weight & vitals',
        'Weight, height, BMI, blood pressure', AppRoutes.vitals,
        Color(0xFF4E9A7B)),
    (Icons.water_drop_rounded, 'Period tracker',
        'Cycle calendar & predictions', AppRoutes.periodTracker,
        Color(0xFFE5637A)),
    (Icons.pregnant_woman_rounded, 'Pregnancy tracker',
        'Week by week to your due date', AppRoutes.pregnancyTracker,
        Color(0xFF9C6ADE)),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final width = (c.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final (icon, title, subtitle, route, color) in _items)
              if (showWomensHealth || !_womensRoutes.contains(route))
              SizedBox(
                width: width,
                child: Material(
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(color: AppColors.tertiary, width: 1.2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onOpen(route),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(icon, color: color),
                          ),
                          const SizedBox(height: 12),
                          Text(title,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              )),
                          const SizedBox(height: 4),
                          Text(subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.3,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
