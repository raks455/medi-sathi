import 'package:url_launcher/url_launcher.dart';

/// Opens email drafts and web pages in other apps.
class ExternalLinks {
  ExternalLinks._();

  /// Opens the user's email app with a draft. Returns false when no email
  /// app could be opened.
  static Future<bool> email({
    required String to,
    String subject = '',
    String body = '',
  }) {
    // Uri(queryParameters:) encodes spaces as '+', which some email apps
    // show literally, so encode by hand.
    final query = [
      if (subject.isNotEmpty) 'subject=${Uri.encodeComponent(subject)}',
      if (body.isNotEmpty) 'body=${Uri.encodeComponent(body)}',
    ].join('&');
    return _launch(Uri.parse('mailto:$to${query.isEmpty ? '' : '?$query'}'));
  }

  static Future<bool> web(String url) =>
      _launch(Uri.parse(url), mode: LaunchMode.externalApplication);

  static Future<bool> _launch(Uri uri,
      {LaunchMode mode = LaunchMode.platformDefault}) async {
    try {
      return await launchUrl(uri, mode: mode);
    } catch (_) {
      return false;
    }
  }
}
