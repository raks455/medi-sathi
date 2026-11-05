import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

/// PLACEHOLDER dashboard: shows the signed-in user and a sign out button.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (p, c) =>
          c.status == AuthStatus.unauthenticated && p.status != c.status,
      listener: (context, state) => context.go(AppRoutes.signIn),
      builder: (context, state) {
        final name = state.user?.fullName ?? '';
        return Scaffold(
          appBar: AppBar(
            title: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppLogo(size: 34, shadow: false),
                SizedBox(width: 10),
                Text('MediSathi',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: AppColors.primary)),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Sign out',
                icon: const Icon(Icons.logout_rounded),
                onPressed: () =>
                    context.read<AuthBloc>().add(const SignOutRequested()),
              ),
            ],
          ),
          body: Center(
            child: Text(
              name.isEmpty ? 'Welcome!' : 'Welcome, $name',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        );
      },
    );
  }
}
