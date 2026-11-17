import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medisathi/core/theme/app_colors.dart';
import 'package:medisathi/core/theme/app_theme.dart';

void main() {
  testWidgets('chip labels are readable in both states', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Row(
          children: [
            ChoiceChip(
                label: const Text('Off'), selected: false, onSelected: (_) {}),
            ChoiceChip(
                label: const Text('On'), selected: true, onSelected: (_) {}),
            FilterChip(
                label: const Text('Day'), selected: false, onSelected: (_) {}),
            ActionChip(label: const Text('Add time'), onPressed: () {}),
          ],
        ),
      ),
    ));

    Color? colorOf(String text) =>
        tester.renderObject<RenderParagraph>(find.text(text)).text.style?.color;

    // Dark text on the white unselected chip, white on the blue selected one.
    expect(colorOf('Off'), AppColors.textPrimary);
    expect(colorOf('Day'), AppColors.textPrimary);
    expect(colorOf('Add time'), AppColors.textPrimary);
    expect(colorOf('On'), Colors.white);
  });
}
