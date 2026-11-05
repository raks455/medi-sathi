import 'package:equatable/equatable.dart';

enum OnboardingDestination { signIn, signUp }

abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();
  @override
  List<Object?> get props => [];
}

class OnboardingStarted extends OnboardingEvent {
  const OnboardingStarted();
}

class OnboardingPageChanged extends OnboardingEvent {
  final int page;
  const OnboardingPageChanged(this.page);
  @override
  List<Object?> get props => [page];
}

/// User tapped Sign Up or Sign In on the last slide.
class OnboardingFinished extends OnboardingEvent {
  final OnboardingDestination destination;
  const OnboardingFinished(this.destination);
  @override
  List<Object?> get props => [destination];
}
