import 'package:flutter/material.dart';

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
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        disabledBackgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.tertiary, width: 1.5),
      ),
      child: isLoading
          ? const SizedBox(
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
                const Text(
                  'G',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4285F4),
                  ),
                ),
                const SizedBox(width: 12),
                Text(label),
              ],
            ),
    );
  }
}
