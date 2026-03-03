import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/l10n/app_localizations.dart';

/// テスト用MaterialAppラッパー
Widget buildTestApp(Widget child) {
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
    home: Scaffold(body: child),
  );
}

/// BuildContext取得用ヘルパー
Widget buildTestAppWithCallback(void Function(BuildContext) callback) {
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
    home: Builder(
      builder: (context) {
        callback(context);
        return const SizedBox.shrink();
      },
    ),
  );
}

/// Riverpod付きテストアプリ
Widget buildTestAppWithRiverpod(Widget child, {List<Override>? overrides}) {
  return ProviderScope(
    overrides: overrides ?? [],
    child: MaterialApp(
      theme: ThemeData(extensions: const [AppColorsExtension.light]),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ja'),
      home: Scaffold(body: child),
    ),
  );
}

/// GoRouter付きテストアプリ
Widget buildTestAppWithRouter(Widget child) {
  return ProviderScope(
    child: MaterialApp.router(
      theme: ThemeData(extensions: const [AppColorsExtension.light]),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ja'),
      routerConfig: GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => child),
      ]),
    ),
  );
}
