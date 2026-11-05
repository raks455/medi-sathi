import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_submit_button.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/or_divider.dart';
import '../widgets/password_field.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<AuthBloc>().add(SignUpSubmitted(
          fullName: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          context.go(AppRoutes.home);
        } else if (state.status == AuthStatus.failure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(state.message ?? 'Something went wrong'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ));
        }
      },
      builder: (context, state) {
        final loading = state.status == AuthStatus.loading;
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AuthHeader(
                        title: 'Create your account',
                        subtitle: 'Start your journey to never missing a dose',
                      ),
                      const SizedBox(height: 32),
                      AuthTextField(
                        controller: _name,
                        label: 'Full name',
                        icon: Icons.person_outline_rounded,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.name],
                        enabled: !loading,
                        validator: (v) => Validators.requiredField(v, 'Full name'),
                      ),
                      const SizedBox(height: 16),
                      AuthTextField(
                        controller: _email,
                        label: 'Email',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        enabled: !loading,
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 16),
                      PasswordField(
                        controller: _password,
                        enabled: !loading,
                        textInputAction: TextInputAction.next,
                        validator: Validators.newPassword,
                      ),
                      const SizedBox(height: 16),
                      PasswordField(
                        controller: _confirm,
                        label: 'Confirm password',
                        enabled: !loading,
                        validator: (v) =>
                            Validators.confirmPassword(v, _password.text),
                        onSubmitted: _submit,
                      ),
                      const SizedBox(height: 28),
                      AuthSubmitButton(
                        label: 'Create account',
                        isLoading: loading && !state.viaGoogle,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 20),
                      const OrDivider(),
                      const SizedBox(height: 20),
                      GoogleSignInButton(
                        isLoading: loading && state.viaGoogle,
                        onPressed: loading
                            ? null
                            : () => context
                                .read<AuthBloc>()
                                .add(const GoogleSignInRequested()),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Already have an account?',
                              style: TextStyle(color: AppColors.textSecondary)),
                          TextButton(
                            onPressed:
                                loading ? null : () => context.go(AppRoutes.signIn),
                            child: const Text('Sign in'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
