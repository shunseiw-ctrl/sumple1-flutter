import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 紹介コードサービス（DI対応）
class ReferralService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ReferralService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  static const _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static const _codeLength = 6;

  /// 6文字の英数字紹介コードを生成し、referral_codes/{uid} に保存する。
  /// 既に存在する場合は既存コードを返す。
  Future<String> generateCode(String uid) async {
    final docRef = _firestore.collection('referral_codes').doc(uid);
    final doc = await docRef.get();

    if (doc.exists) {
      final data = doc.data();
      if (data != null && data['code'] != null) {
        return data['code'] as String;
      }
    }

    final random = Random.secure();
    final code = String.fromCharCodes(
      Iterable.generate(
        _codeLength,
        (_) => _chars.codeUnitAt(random.nextInt(_chars.length)),
      ),
    );

    await docRef.set({
      'code': code,
      'uid': uid,
      'usageCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return code;
  }

  /// 自分の紹介コードを取得する。存在しなければ null。
  Future<String?> getMyCode(String uid) async {
    final doc = await _firestore.collection('referral_codes').doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data();
    return data?['code'] as String?;
  }

  /// 紹介コードを適用する。
  /// - 存在しないコードは例外
  /// - 自己紹介（自分のコード）は例外
  /// - 認証されていなければ例外
  /// - 重複適用は例外
  Future<void> applyCode(String code, String uid) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('ログインが必要です');
    }

    // コードが存在するか検索
    final codeQuery = await _firestore
        .collection('referral_codes')
        .where('code', isEqualTo: code)
        .limit(1)
        .get();

    if (codeQuery.docs.isEmpty) {
      throw Exception('紹介コードが見つかりません');
    }

    final codeDoc = codeQuery.docs.first;
    final referrerUid = codeDoc.data()['uid'] as String;

    // 自己紹介チェック
    if (referrerUid == uid) {
      throw Exception('自分の紹介コードは使用できません');
    }

    // 重複チェック: 同じユーザーが同じコードを既に使っていないか
    final existingReferral = await _firestore
        .collection('referrals')
        .where('refereeUid', isEqualTo: uid)
        .where('code', isEqualTo: code)
        .limit(1)
        .get();

    if (existingReferral.docs.isNotEmpty) {
      throw Exception('このコードは既に適用済みです');
    }

    // 紹介ドキュメント作成
    await _firestore.collection('referrals').add({
      'code': code,
      'referrerUid': referrerUid,
      'refereeUid': uid,
      'status': 'pending',
      'rewardGranted': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 完了した紹介数を取得する。
  Future<int> getReferralStats(String uid) async {
    final query = await _firestore
        .collection('referrals')
        .where('referrerUid', isEqualTo: uid)
        .where('status', isEqualTo: 'completed')
        .get();
    return query.docs.length;
  }
}
