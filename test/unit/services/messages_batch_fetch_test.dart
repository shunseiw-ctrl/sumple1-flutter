import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  group('messages batch fetch', () {
    test('複数appIdのチャットデータ一括取得', () async {
      await fakeFirestore.collection('chats').doc('app1').set({
        'lastMessageText': 'こんにちは',
        'unreadCountApplicant': 3,
      });
      await fakeFirestore.collection('chats').doc('app2').set({
        'lastMessageText': 'お疲れ様です',
        'unreadCountApplicant': 0,
      });

      final appIds = ['app1', 'app2'];
      final result = <String, Map<String, dynamic>>{};

      final snap = await fakeFirestore.collection('chats')
          .where(FieldPath.documentId, whereIn: appIds).get();
      for (final doc in snap.docs) {
        result[doc.id] = doc.data();
      }

      expect(result.length, 2);
      expect(result['app1']?['lastMessageText'], 'こんにちは');
      expect(result['app2']?['unreadCountApplicant'], 0);
    });

    test('空appIdリストでの動作', () async {
      // whereInに空リストを渡すとエラーになるため、事前チェックが必要
      final appIds = <String>[];
      final result = <String, Map<String, dynamic>>{};

      if (appIds.isNotEmpty) {
        final snap = await fakeFirestore.collection('chats')
            .where(FieldPath.documentId, whereIn: appIds).get();
        for (final doc in snap.docs) {
          result[doc.id] = doc.data();
        }
      }

      expect(result, isEmpty);
    });
  });
}
