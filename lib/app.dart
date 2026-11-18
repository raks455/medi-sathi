import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/di/injection_container.dart';
import 'core/l10n/l10n.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/text_size_cubit.dart';
import 'core/theme/theme_cubit.dart';

class MediSathiApp extends StatelessWidget {
  const MediSathiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<ThemeCubit>()),
        BlocProvider(create: (_) => sl<LanguageCubit>()),
        BlocProvider(create: (_) => sl<TextSizeCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, mode) => MaterialApp.router(
          title: 'MediSathi',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          // Date pickers, time formats and the system's own button labels.
          locale: context.watch<LanguageCubit>().state.locale,
          supportedLocales: [for (final l in AppLang.values) l.locale],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          routerConfig: AppRouter.router,
          builder: (context, child) => MediaQuery(
            // The user's text size, on top of the phone's own setting.
            data: MediaQuery.of(context).copyWith(
              textScaler:
                  context.watch<TextSizeCubit>().state.scaler(context),
            ),
            child: LanguageSync(child: PaletteSync(child: child!)),
          ),
        ),
      ),
    );
  }
}

/// Keeps [AppColors] in step with the active theme.
///
/// Many widgets read [AppColors] directly instead of `Theme.of(context)`, so
/// they don't rebuild by themselves when the theme changes. When the
/// brightness flips, this swaps the palette and asks every widget below it to
/// rebuild once. State (scroll positions, forms, open tabs) is kept.
class PaletteSync extends StatelessWidget {
  final Widget child;
  const PaletteSync({super.key, required this.child});

  static void _rebuild(Element element) {
    element.markNeedsBuild();
    element.visitChildren(_rebuild);
  }

  @override
  Widget build(BuildContext context) {
    final changed = AppColors.use(Theme.of(context).brightness);
    if (changed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) (context as Element).visitChildren(_rebuild);
      });
    }
    return child;
  }
}
