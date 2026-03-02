import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/models/early_payment_request_model.dart';
import '../../data/models/monthly_statement_model.dart';
import '../utils/logger.dart';

/// 月次支払サイクル + 即金申請サービス
class PaymentCycleService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  PaymentCycleService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Stream<List<MonthlyStatementModel>> watchStatements(String workerUid) {
    return _db
        .collection('monthly_statements')
        .where('workerUid', isEqualTo: workerUid)
        .orderBy('month', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => MonthlyStatementModel.fromFirestore(doc))
            .toList());
  }

  Future<MonthlyStatementModel?> getStatement(String statementId) async {
    final doc =
        await _db.collection('monthly_statements').doc(statementId).get();
    if (!doc.exists || doc.data() == null) return null;
    return MonthlyStatementModel.fromFirestore(doc);
  }

  Future<void> requestEarlyPayment({
    required String statementId,
    required int requestedAmount,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('認証が必要です');

    final statement = await getStatement(statementId);
    if (statement == null) throw Exception('明細が見つかりません');
    if (statement.workerUid != uid) throw Exception('権限がありません');

    final fee = EarlyPaymentRequestModel.calculateFee(requestedAmount);
    final payout = EarlyPaymentRequestModel.calculatePayout(requestedAmount);

    try {
      await _db.collection('early_payment_requests').add({
        'workerUid': uid,
        'statementId': statementId,
        'month': statement.month,
        'requestedAmount': requestedAmount,
        'earlyPaymentFee': fee,
        'payoutAmount': payout,
        'status': 'requested',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 明細にフラグを立てる
      await _db.collection('monthly_statements').doc(statementId).update({
        'earlyPaymentRequested': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Logger.info('Early payment requested',
          tag: 'PaymentCycleService',
          data: {'statementId': statementId, 'amount': requestedAmount});
    } catch (e) {
      Logger.error('Failed to request early payment',
          tag: 'PaymentCycleService', error: e);
      rethrow;
    }
  }

  Future<void> approveEarlyPayment(String requestId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('認証が必要です');

    try {
      await _db.collection('early_payment_requests').doc(requestId).update({
        'status': 'approved',
        'reviewedBy': uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      Logger.info('Early payment approved',
          tag: 'PaymentCycleService', data: {'requestId': requestId});
    } catch (e) {
      Logger.error('Failed to approve early payment',
          tag: 'PaymentCycleService', error: e);
      rethrow;
    }
  }

  Future<void> rejectEarlyPayment({
    required String requestId,
    required String reason,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('認証が必要です');

    try {
      await _db.collection('early_payment_requests').doc(requestId).update({
        'status': 'rejected',
        'reviewedBy': uid,
        'rejectionReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      Logger.info('Early payment rejected',
          tag: 'PaymentCycleService', data: {'requestId': requestId});
    } catch (e) {
      Logger.error('Failed to reject early payment',
          tag: 'PaymentCycleService', error: e);
      rethrow;
    }
  }

  Stream<List<EarlyPaymentRequestModel>> watchPendingRequests() {
    return _db
        .collection('early_payment_requests')
        .where('status', isEqualTo: 'requested')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => EarlyPaymentRequestModel.fromFirestore(doc))
            .toList());
  }
}
