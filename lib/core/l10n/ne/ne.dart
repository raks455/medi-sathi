import 'ne_account.dart';
import 'ne_common.dart';
import 'ne_health.dart';
import 'ne_medicine.dart';

/// Every Nepali text, keyed by the English text it replaces.
///
/// Split by area so the files stay manageable:
/// - [neCommon]: navigation, dashboard, shared widgets and error messages
/// - [neAccount]: sign in / sign up, onboarding, profile menu, info pages
/// - [neMedicine]: medicines, reminders, dose history, notifications
/// - [neHealth]: vitals, mood, health records, period and pregnancy trackers
final Map<String, String> nepali = {
  ...neCommon,
  ...neAccount,
  ...neMedicine,
  ...neHealth,
};
