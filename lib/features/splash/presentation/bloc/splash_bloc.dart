import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../auth/domain/usecases/check_auth_status.dart';
import '../../../onboarding/domain/usecases/check_onboarding_completed.dart';
import 'splash_event.dart';
import 'splash_state.dart';

export 'splash_event.dart';
export 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final CheckOnboardingCompleted checkOnboardingCompleted;
  final CheckAuthStatus checkAuthStatus;

  SplashBloc({
    required this.checkOnboardingCompleted,
    required this.checkAuthStatus,
  }) : super(const SplashInitial()) {
    on<SplashStarted>(_onStarted);
  }

  Future<void> _onStarted(SplashStarted event, Emitter<SplashState> emit) async {
    await Future.delayed(const Duration(milliseconds: 2400));

    // First launch -> walkthrough (shown once per install).
    final onboardingDone =
        (await checkOnboardingCompleted(const NoParams())).getOrElse(() => false);
    if (!onboardingDone) {
      emit(const SplashNavigate(AppRoutes.onboarding));
      return;
    }

    // Returning user -> Home if signed in, otherwise Sign In.
    final signedIn =
        (await checkAuthStatus(const NoParams())).getOrElse(() => false);
    emit(SplashNavigate(signedIn ? AppRoutes.home : AppRoutes.signIn));
  }
}
