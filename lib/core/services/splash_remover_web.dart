// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void removeSplashScreenImpl() {
  try {
    final splash = html.document.getElementById('splash');
    if (splash != null) {
      splash.classes.add('fade-out');
      Future.delayed(const Duration(milliseconds: 500), () {
        try {
          splash.remove();
        } catch (_) {}
      });
    }
  } catch (_) {}
}
