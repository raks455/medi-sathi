import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n.dart';
import 'app_colors.dart';

/// How large the app's text is. It is applied on top of the phone's own
/// font-size setting.
enum AppTextSize {
  small(0.9, 'Small'),
  medium(1.0, 'Medium'),
  large(1.2, 'Large'),
  extraLarge(1.4, 'Extra large');

  final double factor;

  /// English; shown with `.tr`.
  final String label;
  const AppTextSize(this.factor, this.label);

  /// Beyond this, rows and buttons no longer fit on a small phone.
  static const maxScale = 1.7;

  /// The text scale for the screens below [context].
  TextScaler scaler(BuildContext context) {
    final system = MediaQuery.textScalerOf(context).scale(100) / 100;
    return TextScaler.linear((system * factor).clamp(0.85, maxScale));
  }
}

/// The user's text size, saved on the device.
class TextSizeCubit extends Cubit<AppTextSize> {
  static const _key = 'text_size';
  final SharedPreferences prefs;

  TextSizeCubit(this.prefs)
      : super(AppTextSize.values.asNameMap()[prefs.getString(_key)] ??
            AppTextSize.medium);

  Future<void> setSize(AppTextSize size) async {
    if (size == state) return;
    emit(size);
    await prefs.setString(_key, size.name);
  }
}

/// Four "A"s of growing size: the choice shows what it does, so it can be
/// made without reading.
class TextSizeSelector extends StatelessWidget {
  const TextSizeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TextSizeCubit, AppTextSize>(
      builder: (context, size) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The buttons keep one size whatever is chosen, or they would
          // jump around under the finger.
          MediaQuery.withNoTextScaling(
            child: SegmentedButton<AppTextSize>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.textPrimary,
                selectedBackgroundColor: AppColors.primary,
                selectedForegroundColor: Colors.white,
                side: BorderSide(color: AppColors.tertiary, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              segments: [
                for (final s in AppTextSize.values)
                  ButtonSegment(
                    value: s,
                    tooltip: s.label.tr,
                    label: SizedBox(
                      height: 34,
                      child: Center(
                        child: Text(
                          'A',
                          style: TextStyle(
                            fontSize: 14 + 5.0 * s.index,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
              selected: {size},
              onSelectionChanged: (s) =>
                  context.read<TextSizeCubit>().setSize(s.first),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '{size} · This is how text will look.'
                .trArgs({'size': size.label.tr}),
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
