import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../test/helpers/test_helpers.dart';

void main() {
  group('FavoritesPage', () {
    testWidgets('お気に入り一覧が表示される', (tester) async {
      // お気に入りページの基本構造テスト
      await tester.pumpWidget(
        buildTestApp(
          Scaffold(
            appBar: AppBar(title: const Text('お気に入り案件')),
            body: ListView(
              children: const [
                ListTile(
                  leading: Icon(Icons.work),
                  title: Text('内装工事'),
                  subtitle: Text('東京都新宿区'),
                  trailing: Icon(Icons.favorite, color: Colors.red),
                ),
                ListTile(
                  leading: Icon(Icons.work),
                  title: Text('外壁塗装'),
                  subtitle: Text('大阪府大阪市'),
                  trailing: Icon(Icons.favorite, color: Colors.red),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('お気に入り案件'), findsOneWidget);
      expect(find.text('内装工事'), findsOneWidget);
      expect(find.text('外壁塗装'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNWidgets(2));
    });
  });
}
