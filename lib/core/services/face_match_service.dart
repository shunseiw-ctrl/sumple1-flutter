import 'package:cloud_functions/cloud_functions.dart';
import 'package:sumple1/core/utils/logger.dart';

/// 顔照合結果
class FaceMatchResult {
  final double score;
  final bool matched;
  final String? error;

  const FaceMatchResult({
    required this.score,
    required this.matched,
    this.error,
  });

  factory FaceMatchResult.fromMap(Map<String, dynamic> map) {
    return FaceMatchResult(
      score: (map['score'] as num?)?.toDouble() ?? 0,
      matched: map['matched'] == true,
      error: map['error']?.toString(),
    );
  }

  factory FaceMatchResult.failure(String errorMessage) {
    return FaceMatchResult(
      score: 0,
      matched: false,
      error: errorMessage,
    );
  }
}

/// Cloud Functions verifyFaceMatch を呼び出すサービス
class FaceMatchService {
  final FirebaseFunctions _functions;

  FaceMatchService({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'asia-northeast1');

  /// 顔照合を実行
  /// [uid] 対象ユーザーのUID
  Future<FaceMatchResult> verifyFaceMatch(String uid) async {
    try {
      Logger.info('顔照合を開始', tag: 'FaceMatchService', data: {'uid': uid});

      final callable = _functions.httpsCallable(
        'verifyFaceMatch',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
      );

      final result = await callable.call<Map<String, dynamic>>({'uid': uid});
      final data = result.data;

      Logger.info(
        '顔照合完了',
        tag: 'FaceMatchService',
        data: {'score': data['score'], 'matched': data['matched']},
      );

      return FaceMatchResult.fromMap(data);
    } on FirebaseFunctionsException catch (e) {
      Logger.error(
        '顔照合CFエラー',
        tag: 'FaceMatchService',
        error: e,
        data: {'code': e.code, 'message': e.message},
      );
      return FaceMatchResult.failure(e.message ?? '顔照合に失敗しました');
    } catch (e) {
      Logger.error('顔照合エラー', tag: 'FaceMatchService', error: e);
      return FaceMatchResult.failure('顔照合に失敗しました');
    }
  }
}
