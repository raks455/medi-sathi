import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../bloc/onboarding_bloc.dart';
import '../widgets/onboarding_buttons.dart';
import '../widgets/onboarding_slide_view.dart';
import '../widgets/page_indicator.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int page) => _controller.animateToPage(
        page,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: BlocConsumer<OnboardingBloc, OnboardingState>(
        listenWhen: (prev, curr) =>
            curr.destination != null && prev.destination != curr.destination,
        listener: (context, state) {
          context.go(state.destination == OnboardingDestination.signUp
              ? AppRoutes.signUp
              : AppRoutes.signIn);
        },
        builder: (context, state) {
          if (state.slides.isEmpty) {
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }

          final bloc = context.read<OnboardingBloc>();
          final lastIndex = state.slides.length - 1;

          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  // Top bar: brand + Skip
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 12, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            AppLogo(size: 36, shadow: false),
                            SizedBox(width: 8),
                            Text(
                              'MediSathi',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        AnimatedOpacity(
                          opacity: state.isLast ? 0 : 1,
                          duration: const Duration(milliseconds: 200),
                          child: IgnorePointer(
                            ignoring: state.isLast,
                            child: TextButton(
                              onPressed: () => _goTo(lastIndex),
                              child: const Text('Skip'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Slides
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: state.slides.length,
                      onPageChanged: (i) => bloc.add(OnboardingPageChanged(i)),
                      itemBuilder: (_, i) =>
                          OnboardingSlideView(slide: state.slides[i]),
                    ),
                  ),

                  PageIndicator(
                    count: state.slides.length,
                    current: state.currentPage,
                  ),
                  const SizedBox(height: 28),

                  // Bottom actions (fixed height so layout does not jump)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: SizedBox(
                      height: 124,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: state.isLast
                            ? OnboardingAuthButtons(
                                onSignUp: () => bloc.add(const OnboardingFinished(
                                    OnboardingDestination.signUp)),
                                onSignIn: () => bloc.add(const OnboardingFinished(
                                    OnboardingDestination.signIn)),
                              )
                            : OnboardingNextButton(
                                onPressed: () => _goTo(state.currentPage + 1),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
