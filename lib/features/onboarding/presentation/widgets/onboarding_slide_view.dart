import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/onboarding_slide.dart';

class OnboardingSlideView extends StatelessWidget {
  final OnboardingSlide slide;
  const OnboardingSlideView({super.key, required this.slide});

  IconData get _icon => switch (slide.illustration) {
        OnboardingIllustration.reminder => Icons.notifications_active_rounded,
        OnboardingIllustration.addMedicine => Icons.document_scanner_rounded,
        OnboardingIllustration.progress => Icons.show_chart_rounded,
        OnboardingIllustration.refill => Icons.inventory_2_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Illustration(icon: _icon),
          const SizedBox(height: 40),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mint concentric circles, a blue gradient badge, and two floating
/// medicine icons in the dusty-rose icon colour.
class _Illustration extends StatelessWidget {
  final IconData icon;
  const _Illustration({required this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 290,
      height: 290,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 270,
            height: 270,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.tertiaryLight,
            ),
          ),
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.tertiary,
            ),
          ),
          Container(
            width: 124,
            height: 124,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.secondary, AppColors.primary],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(icon, size: 60, color: Colors.white),
          ),
          const Positioned(
            top: 14,
            right: 20,
            child: _FloatingChip(icon: Icons.vaccines_rounded),
          ),
          const Positioned(
            bottom: 22,
            left: 14,
            child: _FloatingChip(icon: Icons.healing_rounded),
          ),
        ],
      ),
    );
  }
}

class _FloatingChip extends StatelessWidget {
  final IconData icon;
  const _FloatingChip({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, size: 24, color: AppColors.icon),
    );
  }
}
