import 'package:flutter/material.dart';
import 'package:medisathi/core/constants/app_assets.dart';

import '../../../../core/theme/app_colors.dart';

/// "Continue with Google" button.
/// TODO(release): replace the text "G" with the official Google logo asset
/// from Google's branding guidelines.
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.label = 'Continue with Google',
  });

  @override
  Widget build(BuildContext context) {
      final image = Image.asset(
      AppAssets.googleLogo,
     height: 20,
     width: 20,
      fit: BoxFit.scaleDown,
      filterQuality: FilterQuality.high,
      semanticLabel: 'MediSathi logo',
    );
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        disabledBackgroundColor: AppColors.surface,
        side: BorderSide(color: AppColors.tertiary, width: 1.5),
      ),
      child: isLoading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
               image,
                const SizedBox(width: 12),
                Text(label),
              ],
            ),
    );
  }
}
