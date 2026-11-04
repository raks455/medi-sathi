import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc() : super(OnboardingInitial()) {
    on<CheckOnboardingStatus>(_onCheckStatus);
    on<CompleteOnboarding>(_onComplete);
  }

  Future<void> _onCheckStatus(
    CheckOnboardingStatus event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(OnboardingLoading());
    final prefs = await SharedPreferences.getInstance();
    final isCompleted = prefs.getBool('onboarding_completed') ?? false;

    if (isCompleted) {
      emit(OnboardingCompleted());
    } else {
      emit(OnboardingNotCompleted());
    }
  }

  Future<void> _onComplete(
    CompleteOnboarding event,
    Emitter<OnboardingState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    emit(OnboardingCompleted());
  }
}