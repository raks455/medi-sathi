import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';
import 'ne/ne.dart';

/// The languages the app can be used in.
enum AppLang {
  en('en', 'English'),
  ne('ne', 'नेपाली');

  final String code;

  /// The language's own name, shown in the language picker.
  final String nativeName;
  const AppLang(this.code, this.nativeName);

  Locale get locale => Locale(code);

  static AppLang fromCode(String? code) =>
      values.firstWhere((l) => l.code == code, orElse: () => en);
}

/// Translations, keyed by the English text.
///
/// Screens write the English text and add `.tr`:
///
///     Text('Add medicine'.tr)
///     Text('{n} doses left'.trArgs({'n': 3}))
///
/// The Nepali text for each English text lives in `ne/`. A text without a
/// translation is shown in English, so a missing entry is never a crash.
///
/// The current language is static, like [AppColors]: [LanguageSync] rebuilds
/// the screens when it changes.
class L10n {
  L10n._();

  static AppLang current = AppLang.en;

  static bool get isNepali => current == AppLang.ne;

  static String tr(String english, [Map<String, Object?>? args]) {
    var text = current == AppLang.ne ? (nepali[english] ?? english) : english;
    if (args != null) {
      args.forEach((key, value) {
        text = text.replaceAll('{$key}', '$value');
      });
    }
    return text;
  }
}

extension Translate on String {
  /// This English text in the current language.
  String get tr => L10n.tr(this);

  /// Like [tr], filling in `{name}` placeholders.
  String trArgs(Map<String, Object?> args) => L10n.tr(this, args);
}

/// The user's language, saved on the device.
class LanguageCubit extends Cubit<AppLang> {
  static const _key = 'app_language';
  final SharedPreferences prefs;

  /// Tells the server, which writes the reminder notifications.
  final Future<void> Function(AppLang lang)? onChanged;

  LanguageCubit(this.prefs, {this.onChanged}) : super(_read(prefs)) {
    _apply(state);
  }

  /// The saved choice, or Nepali when the phone itself is set to Nepali.
  static AppLang _read(SharedPreferences prefs) {
    final saved = prefs.getString(_key);
    if (saved != null) return AppLang.fromCode(saved);
    final device =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return AppLang.fromCode(device);
  }

  static void _apply(AppLang lang) {
    L10n.current = lang;
    // Dates and month names from DateFormat follow the language too.
    Intl.defaultLocale = lang.code;
  }

  Future<void> setLanguage(AppLang lang) async {
    if (lang == state) return;
    _apply(lang);
    emit(lang);
    await prefs.setString(_key, lang.code);
    syncWithServer();
  }

  /// Best effort: the app works without it, only reminders stay in the old
  /// language until the next successful call.
  void syncWithServer() {
    onChanged?.call(state).catchError((_) {});
  }
}

/// Rebuilds every widget below it when the language changes.
///
/// Texts come from the static [L10n], so widgets do not rebuild by
/// themselves. State (scroll positions, forms, open tabs) is kept.
class LanguageSync extends StatefulWidget {
  final Widget child;
  const LanguageSync({super.key, required this.child});

  @override
  State<LanguageSync> createState() => _LanguageSyncState();
}

class _LanguageSyncState extends State<LanguageSync> {
  AppLang? _shown;

  static void _rebuild(Element element) {
    element.markNeedsBuild();
    element.visitChildren(_rebuild);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageCubit>().state;
    if (_shown != null && _shown != lang) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.visitChildElements(_rebuild);
      });
    }
    _shown = lang;
    return widget.child;
  }
}

/// English / नेपाली switch for a settings list.
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageCubit, AppLang>(
      builder: (context, lang) => SizedBox(
        width: double.infinity,
        child: SegmentedButton<AppLang>(
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            selectedBackgroundColor: AppColors.primary,
            selectedForegroundColor: Colors.white,
            side: BorderSide(color: AppColors.tertiary, width: 1.2),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          segments: [
            for (final l in AppLang.values)
              ButtonSegment(value: l, label: Text(l.nativeName)),
          ],
          selected: {lang},
          onSelectionChanged: (s) =>
              context.read<LanguageCubit>().setLanguage(s.first),
        ),
      ),
    );
  }
}

/// Small button for an app bar that switches to the other language. It shows
/// the language it switches to, in that language, so it can be found by
/// someone who cannot read the current one.
class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageCubit, AppLang>(
      builder: (context, lang) {
        final other = lang == AppLang.en ? AppLang.ne : AppLang.en;
        return TextButton.icon(
          onPressed: () => context.read<LanguageCubit>().setLanguage(other),
          icon: const Icon(Icons.language_rounded, size: 20),
          label: Text(other.nativeName),
        );
      },
    );
  }
}
