import 'package:url_launcher/url_launcher.dart';

/// Public privacy policy (GitHub Pages). Also entered in Play Console.
const privacyPolicyUrl =
    'https://josel120.github.io/politicas/allflag/privacidad/';

/// Opens [url] in the user's browser. url_launcher needs no INTERNET
/// permission in AllFlag: the browser does the networking.
Future<bool> openExternalUrl(Uri url) async {
  try {
    return await launchUrl(url, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
