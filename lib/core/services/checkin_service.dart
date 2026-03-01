import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'location_service.dart';

class CheckinResult {
  final bool success;
  final String message;
  final double? distance;

  CheckinResult({required this.success, required this.message, this.distance});
}

class CheckinService {
  static const double maxDistanceMeters = 100.0;

  /// QRデータからjobIdとshiftCodeをパース
  /// フォーマット: albawork://checkin/{jobId}/{shiftCode}
  static ({String jobId, String shiftCode})? parseQrData(String qrData) {
    final uri = Uri.tryParse(qrData);
    if (uri == null) return null;
    if (uri.scheme != 'albawork') return null;
    if (uri.host != 'checkin') return null;

    final segments = uri.pathSegments;
    if (segments.length != 2) return null;

    return (jobId: segments[0], shiftCode: segments[1]);
  }

  /// QRコード検証 + GPS検証 + チェックイン記録
  static Future<CheckinResult> performCheckin({
    required String applicationId,
    required String qrData,
    required bool isCheckOut,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return CheckinResult(success: false, message: 'ログインが必要です');
    }

    // 1. QRパース
    final parsed = parseQrData(qrData);
    if (parsed == null) {
      return CheckinResult(success: false, message: '無効なQRコードです');
    }

    final jobId = parsed.jobId;
    final shiftCode = parsed.shiftCode;

    // 2. QRコード検証（Firestoreにshiftが存在するか）
    final shiftsQuery = await FirebaseFirestore.instance
        .collection('jobs')
        .doc(jobId)
        .collection('shifts')
        .where('qrCode', isEqualTo: shiftCode)
        .limit(1)
        .get();

    if (shiftsQuery.docs.isEmpty) {
      return CheckinResult(success: false, message: 'QRコードが無効または期限切れです');
    }

    // 3. GPS取得
    late final double userLat;
    late final double userLon;
    try {
      final position = await LocationService.getCurrentPosition();
      userLat = position.latitude;
      userLon = position.longitude;
    } on LocationException catch (e) {
      return CheckinResult(success: false, message: e.message);
    } catch (e) {
      return CheckinResult(success: false, message: '位置情報の取得に失敗しました');
    }

    // 4. 現場座標取得
    final jobDoc = await FirebaseFirestore.instance.collection('jobs').doc(jobId).get();
    final jobData = jobDoc.data();

    double? distance;
    bool gpsVerified = true;

    if (jobData != null && jobData['latitude'] != null && jobData['longitude'] != null) {
      final jobLat = (jobData['latitude'] as num).toDouble();
      final jobLon = (jobData['longitude'] as num).toDouble();

      distance = LocationService.calculateDistance(userLat, userLon, jobLat, jobLon);

      if (distance > maxDistanceMeters) {
        return CheckinResult(
          success: false,
          message: '現場から${distance.round()}m離れています。${maxDistanceMeters.round()}m以内に近づいてください。',
          distance: distance,
        );
      }
      gpsVerified = true;
    }

    // 5. Firestore更新
    final updateData = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
      'qrVerified': true,
      'gpsVerified': gpsVerified,
    };

    if (isCheckOut) {
      updateData['checkOutAt'] = FieldValue.serverTimestamp();
      updateData['checkInStatus'] = 'checked_out';
      updateData['checkOutLatitude'] = userLat;
      updateData['checkOutLongitude'] = userLon;
      if (distance != null) updateData['checkOutDistance'] = distance;
    } else {
      updateData['checkInAt'] = FieldValue.serverTimestamp();
      updateData['checkInStatus'] = 'checked_in';
      updateData['checkInMethod'] = 'qr_gps';
      updateData['checkInLatitude'] = userLat;
      updateData['checkInLongitude'] = userLon;
      if (distance != null) updateData['checkInDistance'] = distance;
    }

    await FirebaseFirestore.instance
        .collection('applications')
        .doc(applicationId)
        .update(updateData);

    final action = isCheckOut ? '退勤' : '出勤';
    final distanceText = distance != null ? '（現場から${distance.round()}m）' : '';
    return CheckinResult(
      success: true,
      message: '$actionしました$distanceText',
      distance: distance,
    );
  }
}
