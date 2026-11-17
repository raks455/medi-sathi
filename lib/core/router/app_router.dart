import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/sign_in_page.dart';
import '../../features/auth/presentation/pages/sign_up_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/pages/main_shell.dart';
import '../../features/medication/presentation/bloc/medication_bloc.dart';
import '../../features/medication/presentation/bloc/prescription_scan_bloc.dart';
import '../../features/medication/presentation/pages/medication_form_page.dart';
import '../../features/medication/presentation/pages/medications_page.dart';
import '../../features/medication/presentation/pages/scan_medicine_page.dart';
import '../../features/notification/presentation/bloc/notifications_bloc.dart';
import '../../features/notification/presentation/pages/notifications_page.dart';
import '../../features/onboarding/presentation/bloc/onboarding_bloc.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/reminder/presentation/bloc/dose_history_bloc.dart';
import '../../features/reminder/presentation/bloc/reminder_bloc.dart';
import '../../features/reminder/presentation/pages/dose_history_page.dart';
import '../../features/splash/presentation/bloc/splash_bloc.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../di/injection_container.dart';
import 'app_routes.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = create();

  /// [initialLocation] is only changed by tests.
  static GoRouter create({String initialLocation = AppRoutes.splash}) =>
      GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<SplashBloc>()..add(const SplashStarted()),
          child: const SplashPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<OnboardingBloc>()..add(const OnboardingStarted()),
          child: const OnboardingPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<AuthBloc>(),
          child: const SignInPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<AuthBloc>(),
          child: const SignUpPage(),
        ),
      ),

      // The signed-in app: four tabs behind a bottom navigation bar. Each tab
      // keeps its own state. The blocs live as long as the user is signed in
      // and are shared by every screen inside the tabs.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => sl<AuthBloc>()..add(const AuthUserRequested()),
            ),
            BlocProvider(
              create: (_) => sl<ReminderBloc>()..add(const TodayRequested()),
            ),
            BlocProvider(
              create: (_) =>
                  sl<MedicationBloc>()..add(const MedicationsRequested()),
            ),
            BlocProvider(
              create: (_) =>
                  sl<DoseHistoryBloc>()..add(const HistoryRequested(7)),
            ),
            BlocProvider(
              create: (_) =>
                  sl<NotificationsBloc>()..add(const NotificationsRequested()),
            ),
          ],
          child: MainShell(
            navigationShell: navigationShell,
            pushService: sl(),
            showNavigationBar:
                MainShell.tabLocations.contains(state.uri.path),
          ),
        ),
        // Order must match the destinations in MainShell.
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => HomePage(pushService: sl()),
              routes: [
                GoRoute(
                  path: 'notifications',
                  builder: (context, state) => const NotificationsPage(),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.medications,
              builder: (context, state) => const MedicationsPage(),
              routes: [
                GoRoute(
                  path: 'add/manual',
                  builder: (context, state) => const MedicationFormPage(),
                ),
                GoRoute(
                  path: 'add/scan',
                  builder: (context, state) => BlocProvider(
                    create: (_) => sl<PrescriptionScanBloc>(),
                    child: const ScanMedicinePage(),
                  ),
                ),
                GoRoute(
                  path: ':id/edit',
                  builder: (context, state) {
                    final id = state.pathParameters['id'];
                    final matches = context
                        .read<MedicationBloc>()
                        .state
                        .medications
                        .where((m) => m.id == id);
                    // Unknown id (e.g. list not loaded yet): show the list.
                    return matches.isEmpty
                        ? const MedicationsPage()
                        : MedicationFormPage(initial: matches.first);
                  },
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.history,
              builder: (context, state) => const DoseHistoryPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.profile,
              builder: (context, state) => ProfilePage(pushService: sl()),
            ),
          ]),
        ],
      ),
    ],
  );
}
