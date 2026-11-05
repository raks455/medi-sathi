import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/complete_onboarding.dart';
import '../../domain/usecases/get_onboarding_slides.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';

export 'onboarding_event.dart';
export 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final GetOnboardingSlides getSlides;
  final CompleteOnboarding completeOnboarding;

  OnboardingBloc({
    required this.getSlides,
    required this.completeOnboarding,
  }) : super(const OnboardingState()) {
    on<OnboardingStarted>(_onStarted);
    on<OnboardingPageChanged>(
      (event, emit) => emit(state.copyWith(currentPage: event.page)),
    );
    on<OnboardingFinished>(_onFinished);
  }

  Future<void> _onStarted(
      OnboardingStarted event, Emitter<OnboardingState> emit) async {
    final result = await getSlides(const NoParams());
    emit(state.copyWith(slides: result.getOrElse(() => const [])));
  }

  Future<void> _onFinished(
      OnboardingFinished event, Emitter<OnboardingState> emit) async {
    await completeOnboarding(const NoParams());
    emit(state.copyWith(destination: event.destination));
  }
}
