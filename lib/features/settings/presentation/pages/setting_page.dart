import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false,
        title: Text('Settings'.tr,    style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Center(
        child: Text('Settings'.tr),
      ),
    );
  }
}
