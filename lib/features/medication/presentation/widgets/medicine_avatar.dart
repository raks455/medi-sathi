import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../utils/medication_format.dart';

/// The picture that stands for a medicine: the user's own photo of it when
/// there is one, otherwise an icon for its form (tablet, syrup ...).
class MedicineAvatar extends StatelessWidget {
  /// API value such as 'tablet'.
  final String medicineType;
  final String? photoUrl;
  final double size;

  /// Greyed out, for a stopped medicine.
  final bool muted;

  const MedicineAvatar({
    super.key,
    required this.medicineType,
    this.photoUrl,
    this.size = 48,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final icon = Container(
      width: size,
      height: size,
      color: AppColors.tertiaryLight,
      child: Icon(
        MedicationFormat.typeIcon(medicineType),
        size: size * 0.5,
        color: muted ? AppColors.textSecondary : AppColors.primary,
      ),
    );
    final url = photoUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.29),
      child: url == null
          ? icon
          : Opacity(
              opacity: muted ? 0.55 : 1,
              child: Image.network(
                url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                // Decoded small: lists show many of these.
                cacheWidth: (size * 3).round(),
                // Offline, or the photo was removed: fall back to the icon.
                errorBuilder: (_, __, ___) => icon,
                frameBuilder: (_, child, frame, loadedNow) =>
                    frame == null && !loadedNow ? icon : child,
              ),
            ),
    );
  }
}
