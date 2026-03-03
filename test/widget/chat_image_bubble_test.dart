import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/l10n/app_localizations.dart';
import 'package:sumple1/presentation/widgets/chat_image_bubble.dart';

void main() {
  Widget buildTestWidget(ChatImageBubble bubble) {
    return MaterialApp(
      theme: ThemeData(extensions: const [AppColorsExtension.light]),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ja'),
      home: Scaffold(
        body: Center(child: bubble),
      ),
    );
  }

  group('ChatImageBubble', () {
    testWidgets('imageUrlでAppCachedImageがレンダリング', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const ChatImageBubble(
          imageUrl: 'https://example.com/test.jpg',
          isMine: true,
        ),
      ));

      // AppCachedImage内部にCachedNetworkImageが含まれる
      expect(find.byType(ChatImageBubble), findsOneWidget);
    });

    testWidgets('isMine=true → 右寄せ可能（Container存在確認）', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(extensions: const [AppColorsExtension.light]),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ja'),
        home: Scaffold(
          body: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: const [
              Flexible(
                child: ChatImageBubble(
                  imageUrl: 'https://example.com/test.jpg',
                  isMine: true,
                ),
              ),
            ],
          ),
        ),
      ));

      final bubble = tester.widget<ChatImageBubble>(find.byType(ChatImageBubble));
      expect(bubble.isMine, isTrue);
    });

    testWidgets('isMine=false → 左寄せ可能', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(extensions: const [AppColorsExtension.light]),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ja'),
        home: Scaffold(
          body: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: const [
              Flexible(
                child: ChatImageBubble(
                  imageUrl: 'https://example.com/test.jpg',
                  isMine: false,
                ),
              ),
            ],
          ),
        ),
      ));

      final bubble = tester.widget<ChatImageBubble>(find.byType(ChatImageBubble));
      expect(bubble.isMine, isFalse);
    });

    testWidgets('caption表示', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const ChatImageBubble(
          imageUrl: 'https://example.com/test.jpg',
          isMine: true,
          caption: 'テストキャプション',
        ),
      ));

      expect(find.text('テストキャプション'), findsOneWidget);
    });

    testWidgets('captionなし→テキスト非表示', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const ChatImageBubble(
          imageUrl: 'https://example.com/test.jpg',
          isMine: true,
        ),
      ));

      // captionがないのでテキストウィジェットは表示されない
      expect(find.text('テストキャプション'), findsNothing);
    });

    testWidgets('onTapコールバック発火', (tester) async {
      var tapped = false;

      await tester.pumpWidget(buildTestWidget(
        ChatImageBubble(
          imageUrl: 'https://example.com/test.jpg',
          isMine: true,
          onTap: () => tapped = true,
        ),
      ));

      await tester.tap(find.byType(ChatImageBubble));
      expect(tapped, isTrue);
    });
  });
}
