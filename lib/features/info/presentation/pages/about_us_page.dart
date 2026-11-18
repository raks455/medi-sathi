import 'package:flutter/material.dart';

import '../../../../core/constants/app_info.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/external_links.dart';
import '../../../../core/widgets/info_widgets.dart';

/// Who builds MediSathi and why.
class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  static const _values = [
    (Icons.favorite_outline_rounded, 'Care first',
        'Built for patients, families and caregivers.'),
    (Icons.lock_outline_rounded, 'Private by design',
        'Your health data is never sold or used for ads.'),
    (Icons.touch_app_outlined, 'Simple to use',
        'Clear screens and big buttons for every age.'),
  ];

  @override
  Widget build(BuildContext context) {
    final body =
        TextStyle(fontSize: 15, height: 1.55, color: AppColors.textPrimary);
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('About us', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.splashGradient,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.groups_rounded, color: Colors.white, size: 34),
                SizedBox(height: 12),
                Text(
                  'Our mission',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Help everyone take the right medicine at the right time.',
                  style: TextStyle(color: Colors.white, height: 1.4),
                ),
              ],
            ),
          ),
          const SectionLabel('Who we are'),
          InfoCard(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${AppInfo.appName} ("Sathi" means companion) is made by '
                '${AppInfo.publisher} in ${AppInfo.country}. We saw how easy it '
                'is to forget a dose, run out of a medicine, or lose track of '
                'a family member\'s treatment, so we built a simple companion '
                'that reminds, tracks and helps you stay on schedule.',
                style: body,
              ),
            ],
          ),
          const SectionLabel('What we value'),
          InfoCard(children: [
            for (final (i, v) in _values.indexed) ...[
              if (i > 0) const InfoDivider(),
              InfoTile(icon: v.$1, title: v.$2, subtitle: v.$3),
            ],
          ]),
          const SectionLabel('Get in touch'),
          InfoCard(children: [
            InfoTile(
              icon: Icons.mail_outline_rounded,
              title: 'Email us',
              subtitle: AppInfo.supportEmail,
              onTap: () async {
                final ok = await ExternalLinks.email(
                    to: AppInfo.supportEmail,
                    subject: '${AppInfo.appName}: hello');
                if (!ok && context.mounted) {
                  showInfoSnack(context,
                      'No email app found. Write to ${AppInfo.supportEmail}',
                      error: true);
                }
              },
            ),
          ]),
        ],
      ),
    );
  }
}
