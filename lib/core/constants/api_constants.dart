class ApiConstants {
  ApiConstants._();

  static const baseUrl = 'https://medisathi-c41p.onrender.com';
 // static const baseUrl = 'http://127.0.0.1:8000';
  static const _api = '/api/v1';

  // Auth
  static const register = '$_api/auth/register';
  static const login = '$_api/auth/login';
  static const refresh = '$_api/auth/refresh';
  static const logout = '$_api/auth/logout';

  /// Exchanges a Firebase ID token for MediSathi tokens.
  /// NOT in the current Swagger: the backend must add this endpoint
  /// (POST {"id_token": "..."} -> TokenResponse). Change the path if yours differs.
  static const googleLogin = '$_api/auth/google';

  // Dashboard (needs Bearer token)
  static const dashboard = '$_api/dashboard';

  // Misc
  static const health = '/health';

  // medication
  static const getMedicationTypes="$_api/medications/options";
  static const listMedicines="$_api/medications";
  static const addMedicine="$_api/medications";
  static const getOneMedicine="$_api/medications/{medication_id}";
  static const updateOneMedicine="$_api/medications/{medication_id}";
  static const deleteOneMedicine="$_api/medications/{medication_id}";

  /// Path of one medicine (GET / PATCH / DELETE).
  static String medication(String id) => '$_api/medications/$id';
  static String stopMedication(String id) => '$_api/medications/$id/stop';
  static String resumeMedication(String id) => '$_api/medications/$id/resume';

  // reminders
static const todaysRemindersWithStatus="$_api/reminders/today";
static const getRemindersSchedule="$_api/reminders/schedule";
static const markADose="$_api/reminders/doses";

//notifications
static const registerDeviceForNotifications="$_api/notifications/devices";
static const unregisterDeviceForNotifications="$_api/notifications/devices";
static const testNotification="$_api/notifications/test";

  /// The in-app notification list (GET, with `limit` and `offset`).
  static const notifications = '$_api/notifications';
  static const markAllNotificationsRead = '$_api/notifications/read-all';
  static String markNotificationRead(String id) =>
      '$_api/notifications/$id/read';
}
