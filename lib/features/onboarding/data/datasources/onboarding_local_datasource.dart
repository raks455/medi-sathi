import 'package:shared_preferences/shared_preferences.dart';

abstract class OnboardingLocalDataSource {
  Future<bool> isCompleted();
  Future<void> markCompleted();
}

class OnboardingLocalDataSourceImpl implements OnboardingLocalDataSource {
  static const _key = 'onboarding_completed';
  final SharedPreferences prefs;
  OnboardingLocalDataSourceImpl(this.prefs);

  @override
  Future<bool> isCompleted() async => prefs.getBool(_key) ?? false;

  @override
  Future<void> markCompleted() async => prefs.setBool(_key, true);
}
