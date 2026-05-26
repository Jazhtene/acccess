import 'package:access_mobile/shared/constants/facebook_config.dart';
import 'package:access_mobile/shared/services/facebook_open_url.dart';

/// Opens Facebook in the browser to share a link (no Page token or permissions).
class FacebookBrowserShare {
  FacebookBrowserShare._();

  static String get pageUrl =>
      'https://www.facebook.com/profile.php?id=${FacebookConfig.defaultPageId}';

  static String buildSharerUrl({required String linkUrl, String? quote}) {
    final params = <String, String>{'u': linkUrl};
    if (quote != null && quote.trim().isNotEmpty) {
      params['quote'] = quote.trim();
    }
    return Uri(
      scheme: 'https',
      host: 'www.facebook.com',
      path: '/sharer/sharer.php',
      queryParameters: params,
    ).toString();
  }

  static Future<bool> openShare({required String linkUrl, String? quote}) {
    return openExternalUrl(buildSharerUrl(linkUrl: linkUrl, quote: quote));
  }

  static Future<bool> openPage() => openExternalUrl(pageUrl);
}
