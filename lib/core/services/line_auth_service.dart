import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';
import 'web_redirect.dart' as web_redirect;
import 'package:http/http.dart' as http;

class LineAuthService {
  static final LineAuthService _instance = LineAuthService._();
  factory LineAuthService() => _instance;
  LineAuthService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  /// Cloud Functions LINE Auth エンドポイントのベース URL
  /// 本番環境では Firebase Hosting の rewrite で CF にプロキシされるため、
  /// 相対パスのままで動作する。将来的に直接 CF URL を指定する場合はここを変更。
  static String _getLineAuthBaseUrl() {
    return '';  // 空文字 = 相対パス（Firebase Hosting rewrite 経由）
  }

  Future<bool> handleLineCallbackIfNeeded() async {
    if (!kIsWeb) return false;

    try {
      final currentUrl = web_redirect.getCurrentUrl();
      if (currentUrl.isEmpty) return false;

      final uri = Uri.parse(currentUrl);
      final fragment = uri.fragment;
      if (fragment.isEmpty) return false;

      final fragmentParams = Uri.splitQueryString(fragment);

      final lineError = fragmentParams['line_error'];
      if (lineError != null) {
        Logger.warning('LINE login error: $lineError', tag: 'LineAuthService');
        web_redirect.clearUrlParams();
        return false;
      }

      final exchangeCode = fragmentParams['line_code'];
      if (exchangeCode == null || exchangeCode.isEmpty) return false;

      web_redirect.clearUrlParams();

      return await _exchangeCodeAndSignIn(exchangeCode);
    } catch (e) {
      Logger.error('Error checking LINE callback', tag: 'LineAuthService', error: e);
      return false;
    }
  }

  Future<bool> _exchangeCodeAndSignIn(String code) async {
    try {
      final baseUrl = _getLineAuthBaseUrl().isNotEmpty
          ? _getLineAuthBaseUrl()
          : Uri.base.origin;
      final response = await http.post(
        Uri.parse('$baseUrl/auth/line/exchange'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'code': code}),
      );

      if (response.statusCode != 200) {
        Logger.warning('Token exchange failed: ${response.statusCode}', tag: 'LineAuthService');
        return false;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final customToken = data['customToken'] as String?;
      final profile = data['profile'] as Map<String, dynamic>?;

      if (customToken == null || customToken.isEmpty) {
        Logger.warning('No custom token in exchange response', tag: 'LineAuthService');
        return false;
      }

      final credential = await _auth.signInWithCustomToken(customToken);
      final user = credential.user;

      if (user != null && profile != null) {
        try {
          await _db.doc('profiles/${user.uid}').set({
            'displayName': profile['displayName'] ?? '',
            'photoUrl': profile['photoUrl'] ?? '',
            'provider': 'line',
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (e) {
          Logger.warning('Failed to save LINE profile', tag: 'LineAuthService');
        }
      }

      Logger.info('LINE login successful', tag: 'LineAuthService');
      return true;
    } catch (e) {
      Logger.error('LINE token exchange/sign-in failed', tag: 'LineAuthService', error: e);
      return false;
    }
  }

  void startLineLogin() {
    if (!kIsWeb) return;
    final base = _getLineAuthBaseUrl();
    if (base.isNotEmpty) {
      web_redirect.redirectTo('$base/auth/line');
    } else {
      web_redirect.redirectTo('/auth/line');
    }
  }
}
