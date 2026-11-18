import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../app_tour/app_tour.dart';
import '../../../app_tour/app_tour_service.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../medication/presentation/bloc/medication_bloc.dart';
import '../../../notification/data/services/push_notification_service.dart';
import '../../../notification/presentation/bloc/notifications_bloc.dart';
import '../../../reminder/presentation/bloc/dose_history_bloc.dart';
import '../../../reminder/presentation/bloc/reminder_bloc.dart';

/// The signed-in app: the four tabs and the bottom navigation bar.
class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  final PushNotificationService pushService;
  final AppTourService tour;

  /// False on screens opened inside a tab (add / edit / scan), which use the
  /// full height.
  final bool showNavigationBar;

  const MainShell({
    super.key,
    required this.navigationShell,
    required this.pushService,
    required this.tour,
    required this.showNavigationBar,
  });

  // Tab order; must match the branches in AppRouter.
  static const _dashboard = 0;
  static const _medicine = 1;
  static const _history = 2;

  /// Locations that show the bottom navigation bar.
  static const tabLocations = {
    AppRoutes.home,
    AppRoutes.medications,
    AppRoutes.history,
    AppRoutes.profile,
  };

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  StatefulNavigationShell get navigationShell => widget.navigationShell;

  @override
  void initState() {
    super.initState();
    // First time in the signed-in app: show the tour once the dashboard has
    // had a moment to load.
    if (!widget.tour.completed) {
      Future.delayed(const Duration(milliseconds: 900), _showFirstTour);
    }
  }

  Future<void> _showFirstTour() async {
    if (!mounted || widget.tour.completed || !widget.showNavigationBar) return;
    await widget.tour.markCompleted();
    if (mounted) await AppTour.show(context);
  }

  void _onTabSelected(BuildContext context, int index) {
    // Tapping the current tab returns to its first screen.
    navigationShell.goBranch(index,
        initialLocation: index == navigationShell.currentIndex);

    // These tabs show data that other tabs can change: reload on entry.
    if (index == MainShell._dashboard) {
      context.read<ReminderBloc>().add(const TodayRequested());
      context.read<NotificationsBloc>().add(const NotificationsRequested());
    } else if (index == MainShell._medicine) {
      // Stock goes down as doses are marked taken on the dashboard.
      context.read<MedicationBloc>().add(const MedicationsRequested());
    } else if (index == MainShell._history) {
      final history = context.read<DoseHistoryBloc>();
      history.add(HistoryRequested(history.state.days));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (p, c) => p.status != c.status,
      listener: (context, state) {
        if (state.status == AuthStatus.unauthenticated) {
          context.go(AppRoutes.signIn);
        } else if (state.status == AuthStatus.authenticated) {
          // Signed-in user confirmed: make sure this phone gets reminders.
          widget.pushService.registerDevice();
        }
      },
      // Not a Scaffold on purpose: each tab has its own, and snackbars only
      // appear in the outermost one, where they would cover the tab's
      // floating button.
      child: Column(
        children: [
          Expanded(
            // The bar below already covers the bottom safe area.
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: widget.showNavigationBar,
              child: navigationShell,
            ),
          ),
          if (widget.showNavigationBar)
            NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (i) => _onTabSelected(context, i),
              destinations: [
                NavigationDestination(
                  key: AppTourKeys.dashboardTab,
                  icon: const Icon(Icons.dashboard_outlined),
                  selectedIcon: const Icon(Icons.dashboard_rounded),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  key: AppTourKeys.medicineTab,
                  icon: const Icon(Icons.medication_outlined),
                  selectedIcon: const Icon(Icons.medication_rounded),
                  label: 'Medicine',
                ),
                NavigationDestination(
                  key: AppTourKeys.historyTab,
                  icon: const Icon(Icons.insights_outlined),
                  selectedIcon: const Icon(Icons.insights_rounded),
                  label: 'History',
                ),
                NavigationDestination(
                  key: AppTourKeys.profileTab,
                  icon: const Icon(Icons.person_outline_rounded),
                  selectedIcon: const Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            ),
        ],
      ),
    );
  }
}
