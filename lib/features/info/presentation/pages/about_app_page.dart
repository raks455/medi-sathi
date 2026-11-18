import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/constants/app_info.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/info_widgets.dart';

/// What the app does, its version, and links to the legal pages.
class AboutAppPage extends StatefulWidget {
  const AboutAppPage({super.key});

  @override
  State<AboutAppPage> createState() => _AboutAppPageState();
}

class _AboutAppPageState extends State<AboutAppPage> {
  String? _version;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() => _version = '${info.version} (${info.buildNumber})');
      }
    }, onError: (_) {});
  }

  static const _features = [
    (Icons.alarm_rounded, 'Dose reminders',
        'Alerts at the right local time, even across time zones.'),
    (Icons.document_scanner_outlined, 'Scan prescriptions',
        'Add medicines from a photo. Text is read on your phone.'),
    (Icons.insights_rounded, 'Track adherence',
        'See taken, skipped and missed doses over time.'),
    (Icons.inventory_2_outlined, 'Refill alerts',
        'Know before a medicine runs out.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About the app'.tr,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const Center(child: AppLogo(size: 88)),
          const SizedBox(height: 14),
          Text(
            AppInfo.appName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _version == null
                ? AppInfo.tagline.tr
                : 'Version {version}'.trArgs({'version': _version}),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SectionLabel('What MediSathi does'),
          InfoCard(children: [
            for (final (i, f) in _features.indexed) ...[
              if (i > 0) const InfoDivider(),
              InfoTile(icon: f.$1, title: f.$2, subtitle: f.$3),
            ],
          ]),
          const SectionLabel('Important'),
          InfoCard(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.health_and_safety_outlined,
                      color: AppColors.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ('{app} helps you remember and track your '
                              'medicines. It is not medical advice. Always '
                              'follow your doctor\'s or pharmacist\'s '
                              'instructions.')
                          .trArgs({'app': AppInfo.appName}),
                      style: TextStyle(
                          height: 1.45, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SectionLabel('Legal'),
          InfoCard(children: [
            InfoTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              onTap: () => context.push(AppRoutes.privacyPolicy),
            ),
            const InfoDivider(),
            InfoTile(
              icon: Icons.gavel_rounded,
              title: 'Terms & Conditions',
              onTap: () => context.push(AppRoutes.terms),
            ),
            const InfoDivider(),
            InfoTile(
              icon: Icons.code_rounded,
              title: 'Open-source licences',
              onTap: () => showLicensePage(
                context: context,
                applicationName: AppInfo.appName,
                applicationVersion: _version,
              ),
            ),
          ]),
          const SizedBox(height: 24),
          Text(
            '© ${DateTime.now().year} ${AppInfo.publisher}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
