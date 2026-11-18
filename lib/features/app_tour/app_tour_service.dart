import 'package:shared_preferences/shared_preferences.dart';

/// Remembers whether the user has seen the app tour on this device.
class AppTourService {
  static const _key = 'app_tour_completed';
  final SharedPreferences prefs;
  AppTourService(this.prefs);

  bool get completed => prefs.getBool(_key) ?? false;

  Future<void> markCompleted() => prefs.setBool(_key, true);
}
