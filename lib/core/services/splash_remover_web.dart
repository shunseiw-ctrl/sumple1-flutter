import 'package:web/web.dart' as web;
import 'package:flutter/foundation.dart';

void removeSplashScreenImpl() {
  try {
    final splash = web.document.getElementById('splash');
    if (splash != null) {
      splash.classList.add('fade-out');
      Future.delayed(const Duration(milliseconds: 500), () {
        try {
          splash.remove();
        } catch (e) {
          debugPrint('[SplashRemover] スプラッシュ要素の削除に失敗: $e');
        }
      });
    }
  } catch (e) {
    debugPrint('[SplashRemover] スプラッシュスクリーンの処理に失敗: $e');
  }
}
