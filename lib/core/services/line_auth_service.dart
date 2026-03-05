import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/logger.dart';
import 'web_redirect.dart' as web_redirect;
import 'package:http/http.dart' as http;
import 'analytics_service.dart';

class LineAuthService {
  static final LineAuthService _instance = LineAuthService._();
  factory LineAuthService() => _instance;
  LineAuthService._()
      : _auth = FirebaseAuth.instance,
        _db = FirebaseFirestore.instance,
        _httpClient = http.Client();

  /// テスト用コンストラクタ（DI対応）
  LineAuthService.forTesting({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required http.Client httpClient,
  })  : _auth = auth,
        _db = firestore,
        _httpClient = httpClient;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final http.Client _httpClient;

  /// Firebase Hosting のベース URL
  static const String _hostingBaseUrl = 'https://alba-work.web.app';

  /// Cloud Functions LINE Auth エンドポイントのベース URL
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

  /// モバイルアプリがUniversal Link経由で受け取ったコールバックを処理
  Future<bool> handleMobileLineCallback(Uri uri) async {
    try {
      final code = uri.queryParameters['code'];
      if (code == null || code.isEmpty) {
        Logger.warning('No code in LINE mobile callback', tag: 'LineAuthService');
        return false;
      }

      final error = uri.queryParameters['error'];
      if (error != null) {
        Logger.warning('LINE mobile callback error: $error', tag: 'LineAuthService');
        return false;
      }

      return await _exchangeCodeAndSignIn(code);
    } catch (e) {
      Logger.error('LINE mobile callback failed', tag: 'LineAuthService', error: e);
      return false;
    }
  }

  Future<bool> _exchangeCodeAndSignIn(String code) async {
    try {
      // モバイルでは絶対URL、Webでは相対パスを使用
      final String exchangeUrl;
      if (kIsWeb) {
        final baseUrl = _getLineAuthBaseUrl().isNotEmpty
            ? _getLineAuthBaseUrl()
            : Uri.base.origin;
        exchangeUrl = '$baseUrl/auth/line/exchange';
      } else {
        exchangeUrl = '$_hostingBaseUrl/auth/line/exchange';
      }

      final response = await _httpClient.post(
        Uri.parse(exchangeUrl),
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

      try {
        await AnalyticsService.logLogin('line');
      } catch (_) {
        // テスト環境ではFirebase Analytics未初期化のため無視
      }
      Logger.info('LINE login successful', tag: 'LineAuthService');
      return true;
    } catch (e) {
      Logger.error('LINE token exchange/sign-in failed', tag: 'LineAuthService', error: e);
      return false;
    }
  }

  void startLineLogin() {
    if (kIsWeb) {
      // Web: リダイレクトで認証開始
      final base = _getLineAuthBaseUrl();
      if (base.isNotEmpty) {
        web_redirect.redirectTo('$base/auth/line');
      } else {
        web_redirect.redirectTo('/auth/line');
      }
    } else {
      // モバイル: 外部ブラウザでLINE認証画面を開く
      _startMobileLineLogin();
    }
  }

  Future<void> _startMobileLineLogin() async {
    final url = Uri.parse('$_hostingBaseUrl/auth/line?platform=mobile');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      Logger.error('Failed to launch LINE auth URL', tag: 'LineAuthService', error: e);
    }
  }
}
