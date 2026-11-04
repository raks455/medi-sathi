import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medisathi/core/constants/colors.dart';
import 'package:medisathi/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:medisathi/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:medisathi/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:medisathi/features/onboarding/presentation/pages/onboarding_page.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Check onboarding status after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      context.read<OnboardingBloc>().add(CheckOnboardingStatus());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        if (state is OnboardingCompleted) {
          // Go to Home / Login screen later
          // For now just go to Onboarding (you can change later)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          );
        } else if (state is OnboardingNotCompleted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          );
        }
      },
      child: Scaffold(
        backgroundColor:scaffoldColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo (replace with your logo)
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.health_and_safety,
                  size: 70,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'MediSathi',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your Health Companion',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 40),
               CircularProgressIndicator(
                color:scaffoldColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}