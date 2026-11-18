import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';

/// Bottom sheet asking how to add a medicine: type it in, or scan it.
Future<void> showAddMedicineSheet(BuildContext context) {
  final router = GoRouter.of(context);
  return showModalBottomSheet<void>(
    context: context,
    // Above the bottom navigation bar.
    useRootNavigator: true,
    backgroundColor: AppColors.scaffold,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      void open(String route) {
        Navigator.of(sheetContext).pop();
        router.go(route);
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  'Add medicine',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _Option(
                icon: Icons.edit_note_rounded,
                title: 'Enter manually',
                subtitle: 'Type the name, dose and schedule',
                onTap: () => open(AppRoutes.addManual),
              ),
              const SizedBox(height: 10),
              _Option(
                icon: Icons.document_scanner_outlined,
                title: 'Scan prescription or label',
                subtitle: 'Take a photo and review what was read',
                onTap: () => open(AppRoutes.scanPrescription),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _Option extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _Option({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.tertiary, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.tertiaryLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        subtitle: Text(subtitle,
            style: TextStyle(color: AppColors.textSecondary)),
        trailing: Icon(Icons.chevron_right_rounded,
            color: AppColors.textSecondary),
      ),
    );
  }
}
