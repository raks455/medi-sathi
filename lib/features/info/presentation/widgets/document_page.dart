import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../content/legal_texts.dart';

/// A long, readable text page (privacy policy, terms).
class DocumentPage extends StatelessWidget {
  final String title;
  final String? lastUpdated;
  final String intro;
  final List<DocSection> sections;

  const DocumentPage({
    super.key,
    required this.title,
    this.lastUpdated,
    required this.intro,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    final body = TextStyle(
        fontSize: 15, height: 1.55, color: AppColors.textPrimary);
    return Scaffold(
      appBar: AppBar(
        title: Text(title.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            if (lastUpdated != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                    'Last updated: {date}'.trArgs({'date': lastUpdated}),
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
              ),
            Text(intro, style: body),
            for (final section in sections) ...[
              const SizedBox(height: 22),
              Text(section.title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  )),
              const SizedBox(height: 8),
              for (final line in section.body)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: line.startsWith('• ')
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text('•',
                                  style: body.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800)),
                            ),
                            Expanded(
                                child: Text(line.substring(2), style: body)),
                          ],
                        )
                      : Text(line, style: body),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
