import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The user's light / dark / follow-the-phone choice, saved on the device.
class ThemeCubit extends Cubit<ThemeMode> {
  static const _key = 'theme_mode';
  final SharedPreferences prefs;

  ThemeCubit(this.prefs) : super(_read(prefs));

  static ThemeMode _read(SharedPreferences prefs) =>
      ThemeMode.values.asNameMap()[prefs.getString(_key)] ?? ThemeMode.system;

  Future<void> setMode(ThemeMode mode) async {
    if (mode == state) return;
    emit(mode);
    await prefs.setString(_key, mode.name);
  }
}
