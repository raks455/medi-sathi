import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Widgets the tour points at. Each key is attached to exactly one widget.
class AppTourKeys {
  AppTourKeys._();

  static final dashboardTab = GlobalKey(debugLabel: 'tour-dashboard-tab');
  static final medicineTab = GlobalKey(debugLabel: 'tour-medicine-tab');
  static final historyTab = GlobalKey(debugLabel: 'tour-history-tab');
  static final profileTab = GlobalKey(debugLabel: 'tour-profile-tab');
  static final notificationsButton = GlobalKey(debugLabel: 'tour-bell');
  static final profileMenuButton = GlobalKey(debugLabel: 'tour-profile-menu');
}

class TourStep {
  /// The widget to highlight. Null shows the card in the middle of the
  /// screen. Steps whose widget is not on screen are skipped.
  final GlobalKey? target;
  final IconData icon;
  final String title;
  final String body;

  const TourStep({
    this.target,
    required this.icon,
    required this.title,
    required this.body,
  });
}

/// A step-by-step walkthrough that dims the screen and highlights one part
/// of the app at a time.
class AppTour {
  AppTour._();

  static List<TourStep> get defaultSteps => [
        const TourStep(
          icon: Icons.waving_hand_rounded,
          title: 'Welcome to MediSathi',
          body: 'Take a quick tour to see where everything is. '
              'It only takes a few seconds.',
        ),
        TourStep(
          target: AppTourKeys.dashboardTab,
          icon: Icons.dashboard_rounded,
          title: 'Dashboard',
          body: 'Tell us how you are feeling, see today\'s doses and tap '
              '"Take" when you take a medicine.',
        ),
        TourStep(
          target: AppTourKeys.notificationsButton,
          icon: Icons.notifications_rounded,
          title: 'Notifications',
          body: 'Dose reminders and refill alerts are collected here.',
        ),
        TourStep(
          target: AppTourKeys.medicineTab,
          icon: Icons.medication_rounded,
          title: 'Medicine',
          body: 'Add medicines by typing them in or by scanning a '
              'prescription. Track stock and get refill alerts.',
        ),
        TourStep(
          target: AppTourKeys.historyTab,
          icon: Icons.insights_rounded,
          title: 'History',
          body: 'See which doses you took, skipped or missed over the last '
              'days and weeks.',
        ),
        TourStep(
          target: AppTourKeys.profileTab,
          icon: Icons.person_rounded,
          title: 'Profile',
          body: 'Health Records for prescriptions and reports, weight and '
              'blood pressure, and period and pregnancy trackers.',
        ),
        TourStep(
          target: AppTourKeys.profileMenuButton,
          icon: Icons.menu_rounded,
          title: 'Menu',
          body: 'Switch between light and dark mode, replay this tour, get '
              'help, send feedback, read our policies or sign out.',
        ),
        const TourStep(
          icon: Icons.check_circle_rounded,
          title: 'You\'re all set!',
          body: 'Add your first medicine and MediSathi will remind you when '
              'it\'s time. You can replay this tour from the Profile menu.',
        ),
      ];

  /// Shows the tour above everything else. Completes when it is finished or
  /// skipped.
  static Future<void> show(BuildContext context, {List<TourStep>? steps}) {
    final visible =
        (steps ?? defaultSteps).where((s) => _isOnScreen(s.target)).toList();
    if (visible.isEmpty) return Future.value();
    return Navigator.of(context, rootNavigator: true).push(PageRouteBuilder(
      opaque: false,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => _TourOverlay(steps: visible),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    ));
  }

  static bool _isOnScreen(GlobalKey? key) {
    if (key == null) return true;
    final context = key.currentContext;
    final box = context?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return false;
    // Tabs that are not selected stay in the tree but are offstage.
    var hidden = false;
    context!.visitAncestorElements((element) {
      final widget = element.widget;
      if (widget is Offstage && widget.offstage) hidden = true;
      if (widget is Visibility && !widget.visible) hidden = true;
      return !hidden;
    });
    return !hidden;
  }

  static Rect? _rectOf(GlobalKey? key) {
    final box = key?.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}

class _TourOverlay extends StatefulWidget {
  final List<TourStep> steps;
  const _TourOverlay({required this.steps});

  @override
  State<_TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<_TourOverlay> {
  int _index = 0;

  bool get _isLast => _index == widget.steps.length - 1;

  void _next() {
    if (_isLast) {
      Navigator.of(context).pop();
    } else {
      setState(() => _index++);
    }
  }

  void _back() {
    if (_index > 0) setState(() => _index--);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final step = widget.steps[_index];
    final target = AppTour._rectOf(step.target)?.inflate(6);
    // No target: the hole shrinks to nothing in the middle of the screen.
    final hole = target ?? Rect.fromCenter(
        center: size.center(Offset.zero), width: 0, height: 0);

    final card = _TourCard(
      key: ValueKey(_index),
      step: step,
      index: _index,
      count: widget.steps.length,
      onNext: _next,
      onBack: _index == 0 ? null : _back,
      onSkip: () => Navigator.of(context).pop(),
    );

    Widget positionedCard;
    if (target == null) {
      positionedCard = Center(
        child: Padding(padding: const EdgeInsets.all(24), child: card),
      );
    } else if (target.center.dy > size.height / 2) {
      positionedCard = Positioned(
        left: 16,
        right: 16,
        bottom: size.height - target.top + 14,
        child: card,
      );
    } else {
      positionedCard = Positioned(
        left: 16,
        right: 16,
        top: target.bottom + 14,
        child: card,
      );
    }

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _next,
              child: TweenAnimationBuilder<Rect?>(
                tween: RectTween(end: hole),
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                builder: (_, rect, __) =>
                    CustomPaint(painter: _ScrimPainter(rect ?? hole)),
              ),
            ),
          ),
          positionedCard,
        ],
      ),
    );
  }
}

class _ScrimPainter extends CustomPainter {
  final Rect hole;
  _ScrimPainter(this.hole);

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Paint()..color = Colors.black.withValues(alpha: 0.72);
    final full = Path()..addRect(Offset.zero & size);
    if (hole.width < 1 || hole.height < 1) {
      canvas.drawPath(full, scrim);
      return;
    }
    final rrect = RRect.fromRectAndRadius(hole, const Radius.circular(18));
    canvas.drawPath(
      Path.combine(PathOperation.difference, full, Path()..addRRect(rrect)),
      scrim,
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(_ScrimPainter old) => old.hole != hole;
}

class _TourCard extends StatelessWidget {
  final TourStep step;
  final int index;
  final int count;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback onSkip;

  const _TourCard({
    super.key,
    required this.step,
    required this.index,
    required this.count,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final last = index == count - 1;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 12 * (1 - t)), child: child),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(step.icon, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      step.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${index + 1}/$count',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                step.body,
                style: TextStyle(
                    fontSize: 15, height: 1.45, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (!last)
                    TextButton(
                      onPressed: onSkip,
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary),
                      child: const Text('Skip'),
                    ),
                  const Spacer(),
                  if (onBack != null)
                    TextButton(onPressed: onBack, child: const Text('Back')),
                  const SizedBox(width: 4),
                  FilledButton(
                    onPressed: onNext,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(last ? 'Get started' : 'Next'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
