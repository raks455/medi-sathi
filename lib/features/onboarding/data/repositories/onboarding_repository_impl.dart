import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/onboarding_slide.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../datasources/onboarding_local_datasource.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  final OnboardingLocalDataSource local;
  OnboardingRepositoryImpl(this.local);

  @override
  Future<Either<Failure, bool>> isCompleted() async {
    try {
      return Right(await local.isCompleted());
    } catch (_) {
      return const Left(CacheFailure('Could not read onboarding status'));
    }
  }

  @override
  Future<Either<Failure, Unit>> complete() async {
    try {
      await local.markCompleted();
      return Right(unit);
    } catch (_) {
      return const Left(CacheFailure('Could not save onboarding status'));
    }
  }

  @override
  List<OnboardingSlide> getSlides() => const [
        OnboardingSlide(
          title: 'Never miss a dose',
          description:
              'Gentle reminders at the right time, every day, so taking your medicines becomes a habit.',
          illustration: OnboardingIllustration.reminder,
        ),
        OnboardingSlide(
          title: 'Add medicines your way',
          description:
              'Snap a photo of your prescription and we will read it for you, or enter medicines manually.',
          illustration: OnboardingIllustration.addMedicine,
        ),
        OnboardingSlide(
          title: 'Track your progress',
          description:
              'See your daily, weekly and monthly adherence and build streaks that keep you going.',
          illustration: OnboardingIllustration.progress,
        ),
        OnboardingSlide(
          title: 'Never run out',
          description:
              'Know how many pills are left and get an alert before it is time to refill.',
          illustration: OnboardingIllustration.refill,
        ),
      ];
}
