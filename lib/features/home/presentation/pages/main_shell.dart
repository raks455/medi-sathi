import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../medication/presentation/bloc/medication_bloc.dart';
import '../../../notification/data/services/push_notification_service.dart';
import '../../../notification/presentation/bloc/notifications_bloc.dart';
import '../../../reminder/presentation/bloc/dose_history_bloc.dart';
import '../../../reminder/presentation/bloc/reminder_bloc.dart';

/// The signed-in app: the four tabs and the bottom navigation bar.
class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final PushNotificationService pushService;

  /// False on screens opened inside a tab (add / edit / scan), which use the
  /// full height.
  final bool showNavigationBar;

  const MainShell({
    super.key,
    required this.navigationShell,
    required this.pushService,
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

  void _onTabSelected(BuildContext context, int index) {
    // Tapping the current tab returns to its first screen.
    navigationShell.goBranch(index,
        initialLocation: index == navigationShell.currentIndex);

    // These tabs show data that other tabs can change: reload on entry.
    if (index == _dashboard) {
      context.read<ReminderBloc>().add(const TodayRequested());
      context.read<NotificationsBloc>().add(const NotificationsRequested());
    } else if (index == _medicine) {
      // Stock goes down as doses are marked taken on the dashboard.
      context.read<MedicationBloc>().add(const MedicationsRequested());
    } else if (index == _history) {
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
          pushService.registerDevice();
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
              removeBottom: showNavigationBar,
              child: navigationShell,
            ),
          ),
          if (showNavigationBar)
            NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (i) => _onTabSelected(context, i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.medication_outlined),
                  selectedIcon: Icon(Icons.medication_rounded),
                  label: 'Medicine',
                ),
                NavigationDestination(
                  icon: Icon(Icons.insights_outlined),
                  selectedIcon: Icon(Icons.insights_rounded),
                  label: 'History',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            ),
        ],
      ),
    );
  }
}
