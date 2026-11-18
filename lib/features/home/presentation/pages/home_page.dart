import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../app_tour/app_tour.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../medication/domain/entities/medication.dart';
import '../../../medication/presentation/bloc/medication_bloc.dart';
import '../../../medication/presentation/utils/medication_format.dart';
import '../../../notification/data/services/push_notification_service.dart';
import '../../../notification/presentation/bloc/notifications_bloc.dart';
import '../../../reminder/presentation/bloc/reminder_bloc.dart';
import '../../../reminder/presentation/widgets/adherence_card.dart';
import '../../../reminder/presentation/widgets/dose_tile.dart';
import '../../../wellness/presentation/cubit/wellness_cubits.dart';
import '../../../wellness/presentation/widgets/mood_check_in_card.dart';

/// Dashboard tab: greeting, today's summary, medicine and stock overview,
/// and today's doses (mark taken / skipped).
class HomePage extends StatefulWidget {
  final PushNotificationService pushService;
  const HomePage({super.key, required this.pushService});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  StreamSubscription<void>? _pushSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // A reminder push arrived or was tapped: statuses have changed.
    _pushSub = widget.pushService.onReminder.listen((_) => _refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pushSub?.cancel();
    super.dispose();
  }

  /// Dose statuses depend on the clock, so reload when the app comes back.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _refresh() {
    if (!mounted) return;
    context.read<ReminderBloc>().add(const TodayRequested());
    context.read<NotificationsBloc>().add(const NotificationsRequested());
    context.read<MedicationBloc>().add(const MedicationsRequested());
  }

  Future<void> _pullToRefresh() {
    final bloc = context.read<ReminderBloc>();
    _refresh();
    context.read<MoodCubit>().load();
    return bloc.stream.firstWhere((s) => s.status != ReminderStatus.loading);
  }

  void _onDoseSaved(BuildContext context, ReminderState state) {
    if (state.markError != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(state.markError!),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
    } else {
      // Taking a dose uses stock, so reload the stock numbers.
      context.read<MedicationBloc>().add(const MedicationsRequested());
    }
  }

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReminderBloc, ReminderState>(
      // Fires when a dose finishes saving (successfully or not).
      listenWhen: (p, c) => c.marking.length < p.marking.length,
      listener: _onDoseSaved,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppLogo(size: 34, shadow: false),
              SizedBox(width: 10),
              Text('MediSathi',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: AppColors.primary)),
            ],
          ),
          actions: [
            BlocBuilder<NotificationsBloc, NotificationsState>(
              buildWhen: (p, c) => p.unreadCount != c.unreadCount,
              builder: (context, state) => IconButton(
                key: AppTourKeys.notificationsButton,
                tooltip: 'Notifications',
                onPressed: () => context.go(AppRoutes.notifications),
                icon: Badge(
                  isLabelVisible: state.unreadCount > 0,
                  backgroundColor: AppColors.error,
                  label: Text(
                      state.unreadCount > 99 ? '99+' : '${state.unreadCount}'),
                  child: const Icon(Icons.notifications_none_rounded),
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _pullToRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final name = state.user?.fullName ?? '';
                  return Text(
                    name.isEmpty ? _greeting() : '${_greeting()}, $name',
                    style: TextStyle(
                        fontSize: 16, color: AppColors.textPrimary),
                  );
                },
              ),
              const SizedBox(height: 14),
              const MoodCheckInCard(),
              const SizedBox(height: 12),
              BlocBuilder<ReminderBloc, ReminderState>(
                buildWhen: (p, c) => p.today?.summary != c.today?.summary,
                builder: (context, state) => state.today == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AdherenceCard(
                            title: 'Today', summary: state.today!.summary),
                      ),
              ),
              BlocBuilder<MedicationBloc, MedicationState>(
                buildWhen: (p, c) => p.medications != c.medications,
                builder: (context, state) =>
                    _MedicineOverview(medications: state.medications),
              ),
              const SizedBox(height: 20),
              Text(
                "Today's doses",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              BlocBuilder<ReminderBloc, ReminderState>(
                builder: (context, state) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _buildDoses(context, state),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDoses(BuildContext context, ReminderState state) {
    final today = state.today;
    if (today == null) {
      if (state.status == ReminderStatus.failure) {
        return [
          _Notice(
            icon: Icons.cloud_off_rounded,
            text: state.message ?? "Could not load today's doses.",
            actionLabel: 'Try again',
            onAction: _refresh,
          ),
        ];
      }
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (today.doses.isEmpty) {
      return [
        _Notice(
          icon: Icons.event_available_outlined,
          text: 'No doses scheduled for today.\n'
              'Add a medicine with a schedule to get reminders.',
          actionLabel: 'My medicines',
          onAction: () => context.go(AppRoutes.medications),
        ),
      ];
    }
    return [
      for (final d in today.doses)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: DoseTile(
            key: ValueKey(d.doseKey),
            dose: d,
            isSaving: state.marking.contains(d.doseKey),
            onMark: (status) =>
                context.read<ReminderBloc>().add(DoseMarked(d, status)),
          ),
        ),
    ];
  }
}

/// How many medicines there are, and which ones need a refill soon.
class _MedicineOverview extends StatelessWidget {
  final List<Medication> medications;
  const _MedicineOverview({required this.medications});

  @override
  Widget build(BuildContext context) {
    final active = medications.where((m) => !m.isStopped).toList();
    final stopped = medications.length - active.length;
    final lowStock =
        active.where((m) => m.inventory?.lowStock ?? false).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.medication_outlined,
                value: '${active.length}',
                label: active.length == 1 ? 'Medicine' : 'Medicines',
                caption: stopped > 0 ? '$stopped stopped' : null,
                onTap: () => context.go(AppRoutes.medications),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: Icons.inventory_2_outlined,
                value: '${lowStock.length}',
                label: 'To refill soon',
                highlight: lowStock.isNotEmpty,
                onTap: () => context.go(AppRoutes.medications),
              ),
            ),
          ],
        ),
        if (lowStock.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.error, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Refill soon',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 6),
                for (final m in lowStock)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            m.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          MedicationFormat.stockSummary(m.inventory!),
                          style:
                              TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String? caption;

  /// Draws attention (e.g. something needs a refill).
  final bool highlight;
  final VoidCallback onTap;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    this.caption,
    this.highlight = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = highlight ? AppColors.error : AppColors.primary;
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.tertiary, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.tertiaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: highlight ? accent : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      caption == null ? label : '$label · $caption',
                      maxLines: 2,
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final String text;
  final String actionLabel;
  final VoidCallback onAction;

  const _Notice({
    required this.icon,
    required this.text,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.tertiary, width: 1.2),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
