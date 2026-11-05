import 'package:flutter/material.dart';

/// "Next" on slides 1..n-1.
class OnboardingNextButton extends StatelessWidget {
  final VoidCallback onPressed;
  const OnboardingNextButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(onPressed: onPressed, child: const Text('Next'));
  }
}

/// Sign Up / Sign In choices on the final slide.
class OnboardingAuthButtons extends StatelessWidget {
  final VoidCallback onSignUp;
  final VoidCallback onSignIn;
  const OnboardingAuthButtons({
    super.key,
    required this.onSignUp,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(onPressed: onSignUp, child: const Text('Create account')),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onSignIn,
          child: const Text('I already have an account'),
        ),
      ],
    );
  }
}
