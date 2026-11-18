import '../../../../core/constants/app_info.dart';

/// One titled section of a long document. Lines in [body] that start with
/// "• " are shown as bullet points.
class DocSection {
  final String title;
  final List<String> body;
  const DocSection(this.title, this.body);
}

class LegalTexts {
  LegalTexts._();

  static const _app = AppInfo.appName;

  // ---------------------------------------------------------------------------
  // Privacy policy
  // ---------------------------------------------------------------------------

  static const privacyIntro =
      'This Privacy Policy explains what information $_app collects, how it '
      'is used, and the choices you have. By creating an account or using '
      '$_app you agree to this policy.';

  static const privacySections = [
    DocSection('1. Information we collect', [
      'Account details: your full name, email address and password. If you '
          'sign in with Google we receive your name, email address and Google '
          'account identifier from Google.',
      'Health information you enter: the medicines you add, their dose, '
          'type, timing, schedule, stock levels and instructions, and the '
          'doses you mark as taken, skipped or missed.',
      'Health records you upload: prescription photos, lab reports, scan '
          'reports and other documents you choose to store, with the title, '
          'date and notes you give them.',
      'Health measurements and check-ins you log: weight, height, blood '
          'pressure and pulse, how you are feeling, and, if you use them, '
          'your period dates and pregnancy dates.',
      'Device information: a push notification token for your phone and '
          'your time zone, so reminders arrive at the right local time.',
      'Feedback you choose to send us by email.',
    ]),
    DocSection('2. Camera and photos', [
      'When you scan a prescription or medicine label, the photo is read on '
          'your phone using on-device text recognition. The photo is only '
          'uploaded if you choose "Save to Health Records". Otherwise only the '
          'medicine details you review and save are stored with your account.',
      'Files you upload to Health Records are stored on our servers so you '
          'can open them from any phone you sign in on.',
      'Camera and photo access is only requested when you choose to scan, '
          'and you can turn it off at any time in your phone settings.',
    ]),
    DocSection('3. How we use your information', [
      '• To create and secure your account and sign you in.',
      '• To schedule and send medicine and refill reminders.',
      '• To show your dose history and adherence summary.',
      '• To keep your health records and show your measurements, BMI, '
          'mood history, cycle predictions and pregnancy progress.',
      '• To answer your support requests and improve the app.',
      'We do not sell your personal information, and we do not use your '
          'health information for advertising.',
    ]),
    DocSection('4. Services we rely on', [
      'We use a small number of trusted providers to run $_app:',
      '• Google Firebase (authentication and push notifications).',
      '• Google Sign-In, if you choose to sign in with Google.',
      '• Google ML Kit for on-device text recognition.',
      '• A cloud hosting provider for our server and database.',
      'These providers process data only to provide their service to us and '
          'are bound by their own privacy policies.',
    ]),
    DocSection('5. Storage and security', [
      'Your data is sent over encrypted connections (HTTPS). Passwords are '
          'never stored in plain text; they are stored as secure hashes. '
          'Your sign-in session is stored on your device.',
      'No method of storage or transmission is completely secure, but we '
          'take reasonable measures to protect your information.',
    ]),
    DocSection('6. How long we keep data', [
      'We keep your account and medicine information for as long as your '
          'account is active. You can delete individual files, readings and '
          'entries in the app at any time.',
      'To delete your account, email ${AppInfo.supportEmail} from the address '
          'you signed up with (or use "Delete account" in the Profile menu). '
          'We delete your account and all of its data, including medicines, '
          'doses, notifications, health records, measurements, mood, cycle '
          'and pregnancy data, within 30 days, except where we must keep it '
          'by law.',
    ]),
    DocSection('7. Your choices and rights', [
      '• View and edit your medicines at any time in the app.',
      '• Turn notifications off in your phone settings.',
      '• Sign out to stop reminders on a phone.',
      '• Ask for a copy of your data, or ask us to correct or delete it, by '
          'emailing ${AppInfo.privacyEmail}.',
    ]),
    DocSection('8. Children', [
      '$_app is not intended for children under 13. A parent or guardian '
          'may use the app to manage a child\'s medicines on their own '
          'account. If you believe a child has given us personal information, '
          'contact us and we will delete it.',
    ]),
    DocSection('9. Changes to this policy', [
      'We may update this policy from time to time. We will show the new '
          'date at the top of this page and, for important changes, let you '
          'know in the app.',
    ]),
    DocSection('10. Contact us', [
      'Questions about your privacy? Email ${AppInfo.privacyEmail}.',
    ]),
  ];

  // ---------------------------------------------------------------------------
  // Terms and conditions
  // ---------------------------------------------------------------------------

  static const termsIntro =
      'These Terms and Conditions ("Terms") govern your use of the $_app '
      'mobile app. Please read them carefully. By creating an account or '
      'using $_app you agree to these Terms. If you do not agree, do not use '
      'the app.';

  static const termsSections = [
    DocSection('1. Not medical advice', [
      'Health measurements, period and fertility predictions and pregnancy '
          'information in $_app are estimates for your own tracking. Period '
          'predictions are not a method of contraception.',
      '$_app is a reminder and tracking tool. It does not provide medical '
          'advice, diagnosis or treatment, and it does not replace your '
          'doctor or pharmacist.',
      'Always follow the instructions of a qualified health professional. '
          'Never change, stop or start a medicine because of something shown '
          'in the app. In an emergency, contact your local emergency services '
          'immediately.',
    ]),
    DocSection('2. Reminders may not always arrive', [
      'Reminders depend on your phone, its settings, battery optimisation, '
          'network connection and third-party notification services. We '
          'cannot guarantee that every reminder will be delivered on time. '
          'You remain responsible for taking your medicines correctly.',
    ]),
    DocSection('3. Prescription scanning', [
      'Text recognition can make mistakes. Always check every scanned '
          'medicine name, dose and timing against your prescription before '
          'saving it.',
    ]),
    DocSection('4. Your account', [
      '• You must give accurate information when you sign up.',
      '• You are responsible for keeping your password safe and for activity '
          'on your account.',
      '• You must be at least 13 years old, or use the app with the '
          'permission and supervision of a parent or guardian.',
      '• Tell us right away if you think your account has been misused.',
    ]),
    DocSection('5. Acceptable use', [
      'You agree not to misuse $_app, including by trying to access other '
          'people\'s data, disrupting the service, reverse engineering the '
          'app, or using it for anything unlawful.',
    ]),
    DocSection('6. Your data', [
      'You own the information you add to $_app. You allow us to store and '
          'process it only to provide the service, as described in our '
          'Privacy Policy.',
    ]),
    DocSection('7. Changes and availability', [
      'We may update, suspend or stop parts of the app at any time. We may '
          'update these Terms; if you keep using the app after a change, you '
          'accept the new Terms.',
    ]),
    DocSection('8. Ending your use', [
      'You can stop using $_app at any time and ask us to delete your '
          'account. We may suspend accounts that break these Terms.',
    ]),
    DocSection('9. Limitation of liability', [
      '$_app is provided "as is" without warranties of any kind. To the '
          'fullest extent allowed by law, we are not liable for any injury, '
          'loss or damage arising from your use of the app, including missed '
          'or late reminders or incorrect information.',
    ]),
    DocSection('10. Governing law', [
      'These Terms are governed by the laws of ${AppInfo.country}.',
    ]),
    DocSection('11. Contact us', [
      'Questions about these Terms? Email ${AppInfo.supportEmail}.',
    ]),
  ];
}
