import 'package:flutter/material.dart';

import '../constants/app_assets.dart';

/// The MediSathi capsule-friend badge.
///
/// [withRing] adds a white ring around the (blue) badge so it stays visible on
/// blue backgrounds such as the splash screen.
class AppLogo extends StatelessWidget {
  final double size;
  final bool withRing;
  final bool shadow;

  const AppLogo({
    super.key,
    this.size = 84,
    this.withRing = false,
    this.shadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      AppAssets.logoMark,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'MediSathi logo',
    );

    return Container(
      padding: withRing ? EdgeInsets.all(size * 0.06) : EdgeInsets.zero,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: withRing ? Colors.white : null,
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: withRing ? 0.18 : 0.14),
                  blurRadius: withRing ? 28 : 18,
                  offset: Offset(0, withRing ? 12 : 8),
                ),
              ]
            : null,
      ),
      child: image,
    );
  }
}
