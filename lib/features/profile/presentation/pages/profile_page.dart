import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../notification/data/services/push_notification_service.dart';

/// The signed-in user, notification test and sign out.
class ProfilePage extends StatefulWidget {
  final PushNotificationService pushService;
  const ProfilePage({super.key, required this.pushService});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _sendingTest = false;
  bool _signingOut = false;

  Future<void> _sendTestPush() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sendingTest = true);
    final result = await widget.pushService.sendTestPush();
    if (mounted) setState(() => _sendingTest = false);

    final (text, isError) = result.fold(
      (f) => (f.message, true),
      (sentTo) => sentTo > 0
          ? ('Test notification sent', false)
          : ('The test notification could not be delivered', true),
    );
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ));
  }

  Future<void> _confirmSignOut() async {
    final bloc = context.read<AuthBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
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
    if (confirmed != true || !mounted) return;
    // The app leaves for the sign-in screen when the bloc is done.
    setState(() => _signingOut = true);
    bloc.add(const SignOutRequested());
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
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final name = state.user?.fullName ?? '';
          final email = state.user?.email ?? '';
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Container(
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
                        _initials(name, email),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
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
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _Tile(
                icon: Icons.notifications_active_outlined,
                title: 'Send test notification',
                subtitle: 'Check that reminders reach this phone',
                busy: _sendingTest,
                onTap: _sendTestPush,
              ),
              const SizedBox(height: 12),
              _Tile(
                icon: Icons.logout_rounded,
                title: 'Sign out',
                color: AppColors.error,
                busy: _signingOut,
                onTap: _confirmSignOut,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final bool busy;
  final VoidCallback onTap;

  const _Tile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.color = AppColors.textPrimary,
    this.busy = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.tertiary, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: busy ? null : onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(icon,
            color: color == AppColors.textPrimary ? AppColors.icon : color),
        title: Text(title,
            style: TextStyle(fontWeight: FontWeight.w600, color: color)),
        subtitle: subtitle == null
            ? null
            : Text(subtitle!,
                style: const TextStyle(color: AppColors.textSecondary)),
        trailing: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : null,
      ),
    );
  }
}
