import '../l10n/l10n.dart';

class Validators {
  Validators._();

  static String? requiredField(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? '{label} is required'.trArgs({'label': label}) : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required'.tr;
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
    return ok ? null : 'Enter a valid email address'.tr;
  }

  /// Sign in: only check it is not empty (server decides if it is correct).
  static String? loginPassword(String? v) =>
      (v == null || v.isEmpty) ? 'Password is required'.tr : null;

  /// Sign up: 8+ characters (matches the API's example password length).
  static String? newPassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required'.tr;
    if (v.length < 8) return 'Use at least 8 characters'.tr;
    return null;
  }

  static String? confirmPassword(String? v, String original) {
    if (v == null || v.isEmpty) return 'Please confirm your password'.tr;
    return v == original ? null : 'Passwords do not match'.tr;
  }
}
