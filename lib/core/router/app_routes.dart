class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';

  static const home = '/';
  static const notifications = '/notifications';
  static const history = '/history';
  static const profile = '/profile';
  static const medications = '/medications';
  static const addMedication = '/medications/add';
  static const addManual = '/medications/add/manual';
  static const scanPrescription = '/medications/add/scan';
  static const scanReview = '/medications/add/scan/review';

  static String editMedication(String id) => '/medications/$id/edit';
}
