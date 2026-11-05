import 'package:equatable/equatable.dart';

import '../../domain/entities/onboarding_slide.dart';
import 'onboarding_event.dart';

class OnboardingState extends Equatable {
  final List<OnboardingSlide> slides;
  final int currentPage;
  final OnboardingDestination? destination;

  const OnboardingState({
    this.slides = const [],
    this.currentPage = 0,
    this.destination,
  });

  bool get isLast => slides.isNotEmpty && currentPage == slides.length - 1;

  OnboardingState copyWith({
    List<OnboardingSlide>? slides,
    int? currentPage,
    OnboardingDestination? destination,
  }) {
    return OnboardingState(
      slides: slides ?? this.slides,
      currentPage: currentPage ?? this.currentPage,
      destination: destination ?? this.destination,
    );
  }

  @override
  List<Object?> get props => [slides, currentPage, destination];
}
