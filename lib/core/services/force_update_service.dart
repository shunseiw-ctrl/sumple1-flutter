import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';

enum ForceUpdateResult { upToDate, recommended, forced }

class ForceUpdateService {
  final FirebaseFirestore _db;

  ForceUpdateService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  Future<ForceUpdateResult> checkForUpdate() async {
    try {
      final doc = await _db.doc('app_config/version').get();
      if (!doc.exists) return ForceUpdateResult.upToDate;

      final data = doc.data()!;
      final minVersion = data['minVersion'] as String? ?? '0.0.0';
      final recommended = data['recommendedVersion'] as String? ?? '0.0.0';

      final info = await PackageInfo.fromPlatform();
      final current = info.version;

      if (isLessThan(current, minVersion)) return ForceUpdateResult.forced;
      if (isLessThan(current, recommended)) {
        return ForceUpdateResult.recommended;
      }
      return ForceUpdateResult.upToDate;
    } catch (_) {
      return ForceUpdateResult.upToDate;
    }
  }

  /// セマンティックバージョン比較: a < b なら true
  static bool isLessThan(String a, String b) {
    final aParts = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final bParts = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    while (aParts.length < 3) {
      aParts.add(0);
    }
    while (bParts.length < 3) {
      bParts.add(0);
    }

    for (int i = 0; i < 3; i++) {
      if (aParts[i] < bParts[i]) return true;
      if (aParts[i] > bParts[i]) return false;
    }
    return false;
  }
}
