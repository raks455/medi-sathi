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
