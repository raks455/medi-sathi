import 'package:flutter/material.dart';

import '../../../../core/constants/app_info.dart';
import '../content/legal_texts.dart';
import '../widgets/document_page.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) => const DocumentPage(
        title: 'Privacy Policy',
        lastUpdated: AppInfo.legalLastUpdated,
        intro: LegalTexts.privacyIntro,
        sections: LegalTexts.privacySections,
      );
}

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) => const DocumentPage(
        title: 'Terms & Conditions',
        lastUpdated: AppInfo.legalLastUpdated,
        intro: LegalTexts.termsIntro,
        sections: LegalTexts.termsSections,
      );
}
