import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medisathi/core/constants/colors.dart';
import 'package:medisathi/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:medisathi/features/splash/presentation/pages/splash_page.dart';

void main() {
  runApp(const MediSathiApp());
}

class MediSathiApp extends StatelessWidget {
  const MediSathiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OnboardingBloc(),
      child: MaterialApp(
        title: 'MediSathi',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: secondaryColor,
          colorScheme: ColorScheme.fromSeed(
            seedColor: secondaryColor,
          ),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}