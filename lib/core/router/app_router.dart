import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/sign_in_page.dart';
import '../../features/auth/presentation/pages/sign_up_page.dart';
import '../../features/habits/habit_pages.dart';
import '../../features/habits/habits.dart';
import '../../features/health_records/domain/health_record.dart';
import '../../features/health_records/presentation/cubit/health_records_cubit.dart';
import '../../features/health_records/presentation/pages/health_records_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/info/presentation/pages/about_app_page.dart';
import '../../features/info/presentation/pages/about_us_page.dart';
import '../../features/info/presentation/pages/feedback_page.dart';
import '../../features/info/presentation/pages/help_support_page.dart';
import '../../features/info/presentation/pages/legal_pages.dart';
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
import '../../features/profile/presentation/cubit/profile_cubit.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/reminder/presentation/bloc/dose_history_bloc.dart';
import '../../features/reminder/presentation/bloc/reminder_bloc.dart';
import '../../features/reminder/presentation/pages/dose_history_page.dart';
import '../../features/splash/presentation/bloc/splash_bloc.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/wellness/presentation/cubit/wellness_cubits.dart';
import '../../features/wellness/presentation/pages/vitals_page.dart';
import '../../features/womens_health/presentation/cubit/womens_health_cubits.dart';
import '../../features/womens_health/presentation/pages/period_tracker_page.dart';
import '../../features/womens_health/presentation/pages/pregnancy_tracker_page.dart';
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

      GoRoute(
        path: AppRoutes.privacyPolicy,
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
      GoRoute(
        path: AppRoutes.terms,
        builder: (context, state) => const TermsPage(),
      ),
      GoRoute(
        path: AppRoutes.aboutApp,
        builder: (context, state) => const AboutAppPage(),
      ),
      GoRoute(
        path: AppRoutes.aboutUs,
        builder: (context, state) => const AboutUsPage(),
      ),
      GoRoute(
        path: AppRoutes.help,
        builder: (context, state) => const HelpSupportPage(),
      ),
      GoRoute(
        path: AppRoutes.feedback,
        builder: (context, state) => FeedbackPage(service: sl()),
      ),
      GoRoute(
        path: AppRoutes.healthRecords,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<HealthRecordsCubit>()..load(),
          child: HealthRecordsPage(
            initialFolder: state.uri.queryParameters['folder'] ==
                    RecordFolder.healthRecords.apiValue
                ? RecordFolder.healthRecords
                : RecordFolder.prescriptions,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.vitals,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<VitalsCubit>()..load(),
          child: const VitalsPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.water,
        builder: (context, state) => BlocProvider.value(
          value: sl<WaterCubit>()..load(),
          child: const WaterTrackerPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.fasting,
        builder: (context, state) => BlocProvider.value(
          value: sl<FastingCubit>()..load(),
          child: const FastingTrackerPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.periodTracker,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<CycleCubit>()..load(),
          child: const PeriodTrackerPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.pregnancyTracker,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<PregnancyCubit>()..load(),
          child: const PregnancyTrackerPage(),
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
            BlocProvider(create: (_) => sl<MoodCubit>()..load()),
            BlocProvider(create: (_) => sl<ProfileCubit>()..load()),
            BlocProvider.value(value: sl<WaterCubit>()..load()),
            BlocProvider.value(value: sl<FastingCubit>()..load()),
          ],
          child: MainShell(
            navigationShell: navigationShell,
            pushService: sl(),
            tour: sl(),
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
                    child: ScanMedicinePage(records: sl()),
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
              builder: (context, state) => BlocProvider(
                create: (_) => sl<CycleCubit>()..load(),
                child: ProfilePage(pushService: sl()),
              ),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (context, state) => const EditProfilePage(),
                ),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
}
