import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';

class MediSathiApp extends StatelessWidget {
  const MediSathiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ThemeCubit>(),
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, mode) => MaterialApp.router(
          title: 'MediSathi',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          routerConfig: AppRouter.router,
          builder: (context, child) => PaletteSync(child: child!),
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
