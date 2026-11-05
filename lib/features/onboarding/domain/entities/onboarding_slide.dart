import 'package:equatable/equatable.dart';

/// Keeps the domain free of Flutter types; the UI maps this to an icon.
enum OnboardingIllustration { reminder, addMedicine, progress, refill }

class OnboardingSlide extends Equatable {
  final String title;
  final String description;
  final OnboardingIllustration illustration;

  const OnboardingSlide({
    required this.title,
    required this.description,
    required this.illustration,
  });

  @override
  List<Object?> get props => [title, description, illustration];
}
