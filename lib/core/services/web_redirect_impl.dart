import 'dart:js_interop';
import 'package:web/web.dart' as web;

void redirectTo(String url) {
  web.window.location.href = url;
}

String getCurrentUrl() {
  return web.window.location.href;
}

void clearUrlParams() {
  final href = web.window.location.href;
  final uri = Uri.parse(href);
  if (uri.fragment.isNotEmpty || uri.queryParameters.isNotEmpty) {
    final cleanUrl = uri.replace(fragment: '', queryParameters: {}).toString();
    final finalUrl = cleanUrl.endsWith('#') ? cleanUrl.substring(0, cleanUrl.length - 1) : cleanUrl;
    final finalUrl2 = finalUrl.endsWith('?') ? finalUrl.substring(0, finalUrl.length - 1) : finalUrl;
    web.window.history.replaceState(''.toJS, '', finalUrl2);
  }
}
