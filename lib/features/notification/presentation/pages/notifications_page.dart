import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/app_notification.dart';
import '../bloc/notifications_bloc.dart';

/// Every reminder and alert the server has sent, newest first.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  Future<void> _refresh(BuildContext context) {
    final bloc = context.read<NotificationsBloc>()
      ..add(const NotificationsRequested());
    return bloc.stream
        .firstWhere((s) => s.status != NotificationsStatus.loading);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsBloc, NotificationsState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Notifications',
                style: TextStyle(fontWeight: FontWeight.w700)),
            actions: [
              if (state.unreadCount > 0)
                TextButton(
                  onPressed: () => context
                      .read<NotificationsBloc>()
                      .add(const NotificationsAllMarkedRead()),
                  child: const Text('Mark all read'),
                ),
            ],
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, NotificationsState state) {
    if (state.items.isEmpty) {
      switch (state.status) {
        case NotificationsStatus.initial:
        case NotificationsStatus.loading:
          return const Center(child: CircularProgressIndicator());
        case NotificationsStatus.failure:
          return _Message(
            icon: Icons.cloud_off_rounded,
            title: 'Could not load notifications',
            subtitle: state.message ?? 'Something went wrong.',
            actionLabel: 'Try again',
            onAction: () => context
                .read<NotificationsBloc>()
                .add(const NotificationsRequested()),
          );
        case NotificationsStatus.success:
          return const _Message(
            icon: Icons.notifications_none_rounded,
            title: 'No notifications yet',
            subtitle: 'Dose reminders and refill reminders will appear here.',
          );
      }
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _refresh(context),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        // One extra row for "Load older" / its spinner.
        itemCount: state.items.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          if (i == state.items.length) {
            return Center(
              child: state.loadingMore
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    )
                  : TextButton(
                      onPressed: () => context
                          .read<NotificationsBloc>()
                          .add(const NotificationsMoreRequested()),
                      child: const Text('Load older'),
                    ),
            );
          }
          final n = state.items[i];
          return _NotificationTile(
            key: ValueKey(n.id),
            notification: n,
            onTap: () => context
                .read<NotificationsBloc>()
                .add(NotificationMarkedRead(n.id)),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  static IconData _icon(String type) => switch (type) {
        AppNotification.typeDoseReminder => Icons.medication_outlined,
        AppNotification.typeRefillReminder => Icons.inventory_2_outlined,
        _ => Icons.notifications_none_rounded,
      };

  /// 'Just now', '5 min ago', '3 h ago', 'Yesterday, 8:00 AM', '12 Nov, 8:00 AM'.
  static String _when(BuildContext context, DateTime createdAt) {
    final local = createdAt.toLocal();
    final now = DateTime.now();
    final age = now.difference(local);
    if (age.inMinutes < 1) return 'Just now';
    if (age.inMinutes < 60) return '${age.inMinutes} min ago';
    if (age.inHours < 6) return '${age.inHours} h ago';

    final time = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(local));
    final days = DateUtils.dateOnly(now)
        .difference(DateUtils.dateOnly(local))
        .inDays;
    if (days == 0) return 'Today, $time';
    if (days == 1) return 'Yesterday, $time';
    return '${DateFormat('d MMM').format(local)}, $time';
  }

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final unread = !n.isRead;
    return Material(
      // Unread ones are tinted so they stand out from the white read ones.
      color: unread ? AppColors.tertiaryLight : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.tertiary, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: unread ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: unread ? AppColors.surface : AppColors.tertiaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_icon(n.type), color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (n.body.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(n.body,
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      _when(context, n.createdAt),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (unread)
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(left: 8, top: 4),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _Message({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.tertiaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 20),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
