import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
import '../../features/onboarding/data/datasources/onboarding_local_datasource.dart';
import '../../features/onboarding/data/repositories/onboarding_repository_impl.dart';
import '../../features/onboarding/domain/repositories/onboarding_repository.dart';
import '../../features/onboarding/domain/usecases/check_onboarding_completed.dart';
import '../../features/onboarding/domain/usecases/complete_onboarding.dart';
import '../../features/onboarding/domain/usecases/get_onboarding_slides.dart';
import '../../features/onboarding/presentation/bloc/onboarding_bloc.dart';
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
