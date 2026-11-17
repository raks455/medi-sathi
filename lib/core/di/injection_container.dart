import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/datasources/auth_token_storage.dart';
import '../../features/auth/data/datasources/google_auth_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/check_auth_status.dart';
import '../../features/auth/domain/usecases/get_current_user.dart';
import '../../features/auth/domain/usecases/sign_in.dart';
import '../../features/auth/domain/usecases/sign_in_with_google.dart';
import '../../features/auth/domain/usecases/sign_out.dart';
import '../../features/auth/domain/usecases/sign_up.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/medication/data/datasources/medication_remote_datasource.dart';
import '../../features/medication/data/datasources/prescription_scanner.dart';
import '../../features/medication/data/repositories/medication_repository_impl.dart';
import '../../features/medication/data/repositories/prescription_scan_repository_impl.dart';
import '../../features/medication/domain/repositories/prescription_scan_repository.dart';
import '../../features/medication/domain/usecases/scan_prescription.dart';
import '../../features/medication/domain/usecases/set_medication_stopped.dart';
import '../../features/medication/presentation/bloc/prescription_scan_bloc.dart';
import '../../features/medication/domain/repositories/medication_repository.dart';
import '../../features/medication/domain/usecases/add_medication.dart';
import '../../features/medication/domain/usecases/delete_medication.dart';
import '../../features/medication/domain/usecases/get_medication_options.dart';
import '../../features/medication/domain/usecases/get_medications.dart';
import '../../features/medication/domain/usecases/update_medication.dart';
import '../../features/medication/presentation/bloc/medication_bloc.dart';
import '../../features/notification/data/datasources/notification_remote_datasource.dart';
import '../../features/notification/data/repositories/notification_repository_impl.dart';
import '../../features/notification/data/services/push_notification_service.dart';
import '../../features/notification/domain/repositories/notification_repository.dart';
import '../../features/notification/domain/usecases/notification_usecases.dart';
import '../../features/notification/presentation/bloc/notifications_bloc.dart';
import '../../features/onboarding/data/datasources/onboarding_local_datasource.dart';
import '../../features/onboarding/data/repositories/onboarding_repository_impl.dart';
import '../../features/onboarding/domain/repositories/onboarding_repository.dart';
import '../../features/onboarding/domain/usecases/check_onboarding_completed.dart';
import '../../features/onboarding/domain/usecases/complete_onboarding.dart';
import '../../features/onboarding/domain/usecases/get_onboarding_slides.dart';
import '../../features/onboarding/presentation/bloc/onboarding_bloc.dart';
import '../../features/reminder/data/datasources/reminder_remote_datasource.dart';
import '../../features/reminder/data/repositories/reminder_repository_impl.dart';
import '../../features/reminder/domain/repositories/reminder_repository.dart';
import '../../features/reminder/domain/usecases/get_dose_schedule.dart';
import '../../features/reminder/domain/usecases/get_today_doses.dart';
import '../../features/reminder/domain/usecases/log_dose.dart';
import '../../features/reminder/presentation/bloc/dose_history_bloc.dart';
import '../../features/reminder/presentation/bloc/reminder_bloc.dart';
import '../../features/splash/presentation/bloc/splash_bloc.dart';
import '../constants/api_constants.dart';
import '../network/dio_client.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ---------- External ----------
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);

  // ---------- Auth: storage first (the network layer needs it) ----------
  sl.registerLazySingleton<AuthTokenStorage>(() => AuthTokenStorageImpl(sl()));

  // ---------- Network ----------
  sl.registerLazySingleton<DioClient>(() => DioClient(sl()));
  sl.registerLazySingleton<Dio>(() => sl<DioClient>().dio);

  // ---------- Onboarding ----------
  sl.registerLazySingleton<OnboardingLocalDataSource>(
      () => OnboardingLocalDataSourceImpl(sl()));
  sl.registerLazySingleton<OnboardingRepository>(
      () => OnboardingRepositoryImpl(sl()));
  sl.registerLazySingleton(() => CheckOnboardingCompleted(sl()));
  sl.registerLazySingleton(() => CompleteOnboarding(sl()));
  sl.registerLazySingleton(() => GetOnboardingSlides(sl()));
  sl.registerFactory(
      () => OnboardingBloc(getSlides: sl(), completeOnboarding: sl()));

  // ---------- Auth ----------
  sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn.instance);
  sl.registerLazySingleton<GoogleAuthDataSource>(
      () => GoogleAuthDataSourceImpl(firebaseAuth: sl(), googleSignIn: sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
        remote: sl(),
        tokenStorage: sl(),
        googleAuth: sl(),
        pushService: sl(),
      ));
  sl.registerLazySingleton(() => SignIn(sl()));
  sl.registerLazySingleton(() => SignUp(sl()));
  sl.registerLazySingleton(() => SignInWithGoogle(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));
  sl.registerLazySingleton(() => CheckAuthStatus(sl()));
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerFactory(() => AuthBloc(
        signIn: sl(),
        signUp: sl(),
        signInWithGoogle: sl(),
        signOut: sl(),
        getCurrentUser: sl(),
      ));

  // ---------- Medication ----------
  sl.registerLazySingleton<MedicationRemoteDataSource>(
      () => MedicationRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<MedicationRepository>(
      () => MedicationRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetMedications(sl()));
  sl.registerLazySingleton(() => GetMedicationOptions(sl()));
  sl.registerLazySingleton(() => AddMedication(sl()));
  sl.registerLazySingleton(() => UpdateMedication(sl()));
  sl.registerLazySingleton(() => DeleteMedication(sl()));
  sl.registerLazySingleton(() => SetMedicationStopped(sl()));
  sl.registerFactory(() => MedicationBloc(
        getMedications: sl(),
        getOptions: sl(),
        addMedication: sl(),
        updateMedication: sl(),
        deleteMedication: sl(),
        setMedicationStopped: sl(),
      ));

  sl.registerLazySingleton<PrescriptionScanner>(
      () => PrescriptionScannerImpl(ImagePicker()));
  sl.registerLazySingleton<PrescriptionScanRepository>(
      () => PrescriptionScanRepositoryImpl(scanner: sl()));
  sl.registerLazySingleton(() => ScanPrescription(sl()));
  sl.registerFactory(() => PrescriptionScanBloc(scanPrescription: sl()));

  // ---------- Reminders ----------
  sl.registerLazySingleton<ReminderRemoteDataSource>(
      () => ReminderRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<ReminderRepository>(
      () => ReminderRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetTodayDoses(sl()));
  sl.registerLazySingleton(() => GetDoseSchedule(sl()));
  sl.registerLazySingleton(() => LogDose(sl()));
  sl.registerFactory(() => ReminderBloc(getTodayDoses: sl(), logDose: sl()));
  sl.registerFactory(() => DoseHistoryBloc(getDoseSchedule: sl()));

  // ---------- Push notifications ----------
  sl.registerLazySingleton<NotificationRemoteDataSource>(
      () => NotificationRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<NotificationRepository>(
      () => NotificationRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetNotifications(sl()));
  sl.registerLazySingleton(() => MarkNotificationRead(sl()));
  sl.registerLazySingleton(() => MarkAllNotificationsRead(sl()));
  sl.registerFactory(() => NotificationsBloc(
        getNotifications: sl(),
        markNotificationRead: sl(),
        markAllNotificationsRead: sl(),
      ));
  sl.registerLazySingleton<PushNotificationService>(
      () => PushNotificationServiceImpl(
            messaging: FirebaseMessaging.instance,
            localNotifications: FlutterLocalNotificationsPlugin(),
            remote: sl(),
            prefs: sl(),
          ));

  // ---------- Splash ----------
  sl.registerFactory(() => SplashBloc(
        checkOnboardingCompleted: sl(),
        checkAuthStatus: sl(),
      ));
}

/// The backend is on Render's free tier and sleeps when idle. A fire-and-forget
/// ping at startup wakes it while the splash/onboarding screens are showing.
void warmUpServer() {
  sl<Dio>()
      .get<dynamic>(ApiConstants.health)
      .then<void>((_) {}, onError: (_) {});
}
