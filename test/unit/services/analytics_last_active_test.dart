import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('lastActive tracking', () {
    test('lastActiveAt field can be written to profiles', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('profiles').doc('testUser').set({
        'lastActiveAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final doc = await firestore.collection('profiles').doc('testUser').get();
      expect(doc.exists, isTrue);
      expect(doc.data()!.containsKey('lastActiveAt'), isTrue);
    });

    test('notificationPreferences can be toggled', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('profiles').doc('testUser').set({
        'notificationPreferences': {'reengagement': false},
      }, SetOptions(merge: true));

      final doc = await firestore.collection('profiles').doc('testUser').get();
      final prefs = doc.data()!['notificationPreferences'] as Map<String, dynamic>;
      expect(prefs['reengagement'], isFalse);
    });
  });
}
