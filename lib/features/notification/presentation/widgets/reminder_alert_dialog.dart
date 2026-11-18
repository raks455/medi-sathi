import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/services/push_notification_service.dart';

/// A reminder that cannot be missed by someone who does not hear the
/// notification sound: it fills the screen with the medicine's picture and
/// name and the phone vibrates. Shown when a reminder arrives while the app
/// is open.
Future<void> showReminderAlert(BuildContext context, ReminderAlert alert) {
  // Three strong buzzes, felt with the phone in the hand or on a table.
  () async {
    for (var i = 0; i < 3; i++) {
      await HapticFeedback.vibrate();
      await Future<void>.delayed(const Duration(milliseconds: 600));
    }
  }();
  return showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (dialog) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppColors.primary, width: 3),
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (alert.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                alert.imageUrl!,
                width: 180,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _Bell(),
              ),
            )
          else
            const _Bell(),
          const SizedBox(height: 16),
          Text(
            alert.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          if (alert.body.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              alert.body,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(dialog).pop(),
          child: Text('OK, show my medicines'.tr),
        ),
      ],
    ),
  );
}

class _Bell extends StatelessWidget {
  const _Bell();

  @override
  Widget build(BuildContext context) => Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: AppColors.tertiaryLight,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.notifications_active_rounded,
            size: 56, color: AppColors.primary),
      );
}
