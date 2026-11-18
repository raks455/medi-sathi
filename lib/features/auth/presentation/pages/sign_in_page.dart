import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n.dart';
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
import '../widgets/terms_consent.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<AuthBloc>().add(
          SignInSubmitted(email: _email.text.trim(), password: _password.text),
        );
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
              content: Text(state.message ?? 'Something went wrong'.tr),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ));
        }
      },
      builder: (context, state) {
        final loading = state.status == AuthStatus.loading;
        return Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const AuthHeader(
                            title: 'Welcome back',
                            subtitle: 'Sign in to keep track of your medicines',
                          ),
                          const SizedBox(height: 36),
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
                            autofillHints: const [AutofillHints.password],
                            validator: Validators.loginPassword,
                            onSubmitted: _submit,
                          ),
                          const SizedBox(height: 28),
                          AuthSubmitButton(
                            label: 'Sign in',
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
                              Text('New to MediSathi?'.tr,
                                  style: TextStyle(color: AppColors.textSecondary)),
                              TextButton(
                                onPressed:
                                    loading ? null : () => context.go(AppRoutes.signUp),
                                child: Text('Create account'.tr),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const LegalNotice(),
                        ],
                      ),
                    ),
                  ),
                ),
                // Lets the user pick a language before signing in.
                const Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.only(top: 4, right: 8),
                    child: LanguageButton(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
