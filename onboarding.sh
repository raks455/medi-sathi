#!/usr/bin/env bash
# MediSathi - Splash + Onboarding walkthrough -> Sign Up / Sign In
# Run from the PROJECT ROOT (folder with pubspec.yaml):
#   bash add_onboarding_auth.sh
set -e

[ -f pubspec.yaml ] || { echo "Run this inside the medisathi project folder."; exit 1; }

L=lib
A=$L/features/auth
O=$L/features/onboarding
S=$L/features/splash

# ---------- AUTH: rename to Sign In / Sign Up ----------
mkdir -p $A/domain/usecases $A/presentation/{pages,widgets,bloc}
[ -f $A/domain/usecases/login.dart ]    && mv $A/domain/usecases/login.dart    $A/domain/usecases/sign_in.dart
[ -f $A/domain/usecases/register.dart ] && mv $A/domain/usecases/register.dart $A/domain/usecases/sign_up.dart
[ -f $A/domain/usecases/logout.dart ]   && mv $A/domain/usecases/logout.dart   $A/domain/usecases/sign_out.dart
rm -f $A/presentation/pages/login_page.dart $A/presentation/pages/register_page.dart

touch $A/domain/usecases/{sign_in,sign_up,sign_out,get_current_user}.dart
touch $A/domain/usecases/check_auth_status.dart            # is there a saved token?
touch $A/data/datasources/auth_token_storage.dart          # secure token storage
touch $A/presentation/pages/sign_in_page.dart
touch $A/presentation/pages/sign_up_page.dart
touch $A/presentation/widgets/{auth_text_field,password_field,auth_submit_button}.dart

# ---------- ONBOARDING (walkthrough) ----------
mkdir -p $O/data/datasources $O/domain/{entities,repositories,usecases} $O/presentation/{bloc,pages,widgets}

touch $O/data/datasources/onboarding_local_datasource.dart   # "seen" flag in shared_preferences
touch $O/data/repositories/onboarding_repository_impl.dart 2>/dev/null || {
  mkdir -p $O/data/repositories; touch $O/data/repositories/onboarding_repository_impl.dart; }
touch $O/domain/entities/onboarding_slide.dart               # title, description, image
touch $O/domain/repositories/onboarding_repository.dart
touch $O/domain/usecases/{check_onboarding_completed,complete_onboarding,get_onboarding_slides}.dart
touch $O/presentation/bloc/onboarding_{bloc,event,state}.dart
touch $O/presentation/pages/onboarding_page.dart             # PageView + Skip; last slide -> Sign Up / Sign In
touch $O/presentation/widgets/{onboarding_slide_view,page_indicator,onboarding_buttons}.dart

# ---------- SPLASH (decides where to go on launch) ----------
mkdir -p $S/presentation/{bloc,pages}
touch $S/presentation/pages/splash_page.dart
touch $S/presentation/bloc/splash_{bloc,event,state}.dart

# ---------- assets ----------
mkdir -p assets/{images/onboarding,icons,animations}

# ---------- routes ----------
cat > $L/core/router/app_routes.dart <<'EOF'
class AppRoutes {
  // Launch + auth
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';

  // App
  static const home = '/';
  static const medications = '/medications';
  static const addMedication = '/medications/add';
  static const addManual = '/medications/add/manual';
  static const scanPrescription = '/medications/add/scan';
  static const scanReview = '/medications/add/scan/review';
}
EOF

# ---------- flow notes ----------
cat > $O/LAUNCH_FLOW.md <<'EOF'
# Launch flow

App start -> SplashPage
  ├─ onboarding NOT completed        -> OnboardingPage (walkthrough)
  │                                      ├─ Skip / Get started
  │                                      ├─ [Sign Up]  -> SignUpPage -> Home
  │                                      └─ [Sign In]  -> SignInPage -> Home
  ├─ onboarding done, NOT signed in  -> SignInPage  (link: "Create account" -> SignUpPage)
  └─ onboarding done, signed in      -> Home

Rules
- Mark onboarding completed as soon as the user taps Skip, Sign Up or Sign In.
- Onboarding is shown only once per install.
- Router redirect (go_router) uses SplashBloc state; no screen decides navigation by itself.

Suggested slides
1. Never miss a dose        (smart reminders)
2. Add medicines your way   (scan prescription or enter manually)
3. Track your progress      (adherence, streaks)
4. Stay stocked             (refill alerts)  -> Sign Up / Sign In buttons
EOF

echo "Splash + onboarding + sign in/up structure created."