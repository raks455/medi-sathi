class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';

  // Info screens: top-level so they open from sign-up and from Profile.
  static const privacyPolicy = '/privacy-policy';
  static const terms = '/terms';
  static const aboutApp = '/about-app';
  static const aboutUs = '/about-us';
  static const help = '/help';
  static const feedback = '/feedback';

  // Health tools opened from Profile.
  static const healthRecords = '/health-records';
  static const vitals = '/vitals';
  static const periodTracker = '/period-tracker';
  static const pregnancyTracker = '/pregnancy-tracker';
  static const water = '/water';
  static const fasting = '/fasting';

  static const home = '/';
  static const notifications = '/notifications';
  static const history = '/history';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const medications = '/medications';
  static const addMedication = '/medications/add';
  static const addManual = '/medications/add/manual';
  static const scanPrescription = '/medications/add/scan';
  static const scanReview = '/medications/add/scan/review';

  static String editMedication(String id) => '/medications/$id/edit';
}
