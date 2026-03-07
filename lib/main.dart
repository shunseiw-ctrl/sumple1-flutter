import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';


import 'firebase_options.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'core/config/app_environment.dart';
import 'pages/home_page.dart';
import 'pages/admin_home_page.dart';

import 'presentation/pages/guest/guest_home_page.dart';
import 'core/utils/logger.dart';
import 'core/services/auth_service.dart';
import 'core/enums/user_role.dart';
import 'core/services/firestore_setup.dart';
import 'core/services/line_auth_service.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/constants/app_spacing.dart';

import 'core/providers/locale_provider.dart';
import 'core/providers/theme_mode_provider.dart';
import 'core/services/splash_remover.dart';
import 'package:go_router/go_router.dart';
import 'core/services/deep_link_service.dart';
import 'core/router/app_router.dart';
import 'presentation/widgets/error_retry_widget.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'core/services/force_update_service.dart';
import 'presentation/widgets/force_update_dialog.dart';
import 'core/services/analytics_service.dart';
import 'presentation/widgets/app_error_boundary.dart';

/// FCMバックグラウンドメッセージハンドラ（トップレベル関数である必要あり）
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  Logger.info('Background message received', tag: 'FCM', data: {'id': message.messageId});
}

/// フォアグラウンド通知用のローカル通知プラグイン
final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

/// Android通知チャンネル
const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
  'default',
  'デフォルト通知',
  description: 'ALBAWORKからの通知',
  importance: Importance.high,
);

/// FCM初期化（パーミッション要求、チャンネル作成、リスナー登録）
/// 起動速度のためaddPostFrameCallbackで遅延実行する
Future<void> _initializeFCM() async {
  try {
    await FirebaseMessaging.instance.requestPermission();

    // Android通知チャンネル作成
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // ローカル通知初期化
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    // フォアグラウンド通知処理
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    });

    // 通知タップ時の処理 — go_router で Deep Link ルーティング
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      Logger.info('Notification tapped', tag: 'FCM', data: message.data);
      final path = _deepLinkService.goRouterPathFromNotification(message.data);
      if (path != null) {
        _goRouterInstance?.go(path);
      }
    });

    Logger.info('FCM initialized (deferred)', tag: 'FCM');
  } catch (e) {
    Logger.error('FCM initialization failed', tag: 'FCM', error: e);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: AppConfig.firebaseOptions,
  );

  Logger.info('Environment: ${AppConfig.environmentName}', tag: 'main');

  // --- App Check ---
  try {
    if (kDebugMode) {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
      ).timeout(const Duration(seconds: 10));
    } else {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.deviceCheck,
      ).timeout(const Duration(seconds: 10));
    }
  } catch (e) {
    Logger.error('App Check activation failed', tag: 'main', error: e);
  }

  // --- Crashlytics ---
  if (!kIsWeb) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  try {
    await FirestoreSetup.initialize().timeout(const Duration(seconds: 10));
  } catch (e) {
    Logger.error('Firestore setup failed', tag: 'main', error: e);
  }

  Logger.info('Firebase initialized', tag: 'main');

  // --- FCM ---
  if (!kIsWeb) {
    // バックグラウンドハンドラはmain()に残す（Firebase要件）
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    // 残りのFCM初期化は初回フレーム後に遅延（起動時間短縮）
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeFCM());
  }

  // LINE SDK 初期化（モバイルのみ）
  if (!kIsWeb) {
    try {
      await LineSDK.instance.setup(AppConfig.lineChannelId)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      Logger.error('LINE SDK setup failed', tag: 'main', error: e);
    }
  }

  try {
    await LineAuthService().handleLineCallbackIfNeeded()
        .timeout(const Duration(seconds: 10));
  } catch (e) {
    Logger.error('LINE callback handling failed', tag: 'main', error: e);
  }

  runApp(const ProviderScope(child: MyApp()));

  if (kIsWeb) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      removeSplashScreen();
    });
  }
}

/// グローバル navigator key（Deep Link / 通知ナビゲーション用）
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Deep Link サービス
final DeepLinkService _deepLinkService = DeepLinkService();

/// go_router インスタンス（FCM通知タップ時に使用）
GoRouter? _goRouterInstance;

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _deepLinkService.initialize(navigatorKey);
    _lifecycleListener = AppLifecycleListener(onStateChange: _onAppLifecycleChange);
  }

  void _onAppLifecycleChange(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AnalyticsService.logLastActive();
    }
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _deepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    _goRouterInstance = router;
    final lightTextTheme = GoogleFonts.notoSansJpTextTheme(
      ThemeData.light().textTheme,
    );
    final darkTextTheme = GoogleFonts.notoSansJpTextTheme(
      ThemeData.dark().textTheme,
    );

    return AppErrorBoundary(child: MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      title: 'ALBAWORK',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.ruri,
        scaffoldBackgroundColor: AppColors.background,
        extensions: const [AppColorsExtension.light],
        textTheme: lightTextTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.notoSansJp(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          shape: const Border(
            bottom: BorderSide(color: AppColors.divider, width: 0.5),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: AppColors.ruri,
          unselectedItemColor: AppColors.textHint,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: GoogleFonts.notoSansJp(
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: GoogleFonts.notoSansJp(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.ruri,
            foregroundColor: Colors.white,
            elevation: 0,
            textStyle: GoogleFonts.notoSansJp(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            ),
            minimumSize: const Size(0, 52),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.ruri,
            side: const BorderSide(color: AppColors.ruri, width: 1.5),
            textStyle: GoogleFonts.notoSansJp(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            ),
            minimumSize: const Size(0, 52),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.ruri,
            textStyle: GoogleFonts.notoSansJp(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            minimumSize: const Size(0, 44),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceElevated,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
            borderSide: const BorderSide(color: AppColors.borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
            borderSide: const BorderSide(color: AppColors.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
            borderSide: const BorderSide(color: AppColors.ruri, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintStyle: GoogleFonts.notoSansJp(
            color: AppColors.textHint,
            fontSize: 14,
          ),
          labelStyle: GoogleFonts.notoSansJp(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.chipUnselected,
          selectedColor: AppColors.ruriPale,
          labelStyle: GoogleFonts.notoSansJp(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
          ),
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 0.5,
          space: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
          margin: EdgeInsets.zero,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppColors.textPrimary,
          contentTextStyle: GoogleFonts.notoSansJp(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: AppColors.ruri,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.ruri,
          labelStyle: GoogleFonts.notoSansJp(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: GoogleFonts.notoSansJp(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: AppColors.ruri,
        scaffoldBackgroundColor: AppDarkColors.background,
        extensions: const [AppColorsExtension.dark],
        textTheme: darkTextTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: AppDarkColors.surface,
          foregroundColor: AppDarkColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.notoSansJp(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppDarkColors.textPrimary,
          ),
          shape: const Border(
            bottom: BorderSide(color: AppDarkColors.divider, width: 0.5),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: AppColors.ruri,
          unselectedItemColor: AppDarkColors.textHint,
          backgroundColor: AppDarkColors.surface,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: GoogleFonts.notoSansJp(
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: GoogleFonts.notoSansJp(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.ruri,
            foregroundColor: Colors.white,
            elevation: 0,
            textStyle: GoogleFonts.notoSansJp(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            ),
            minimumSize: const Size(0, 52),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.ruri,
            side: const BorderSide(color: AppColors.ruri, width: 1.5),
            textStyle: GoogleFonts.notoSansJp(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            ),
            minimumSize: const Size(0, 52),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.ruri,
            textStyle: GoogleFonts.notoSansJp(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            minimumSize: const Size(0, 44),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppDarkColors.surfaceElevated,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
            borderSide: const BorderSide(color: AppDarkColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
            borderSide: const BorderSide(color: AppDarkColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
            borderSide: const BorderSide(color: AppColors.ruri, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintStyle: GoogleFonts.notoSansJp(
            color: AppDarkColors.textHint,
            fontSize: 14,
          ),
          labelStyle: GoogleFonts.notoSansJp(
            color: AppDarkColors.textSecondary,
            fontSize: 14,
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppDarkColors.chipUnselected,
          selectedColor: AppDarkColors.ruriPale,
          labelStyle: GoogleFonts.notoSansJp(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
          ),
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        dividerTheme: const DividerThemeData(
          color: AppDarkColors.divider,
          thickness: 0.5,
          space: 0,
        ),
        cardTheme: CardThemeData(
          color: AppDarkColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
          margin: EdgeInsets.zero,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppDarkColors.surfaceElevated,
          contentTextStyle: GoogleFonts.notoSansJp(
            color: AppDarkColors.textPrimary,
            fontSize: 14,
          ),
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: AppColors.ruri,
          unselectedLabelColor: AppDarkColors.textSecondary,
          indicatorColor: AppColors.ruri,
          labelStyle: GoogleFonts.notoSansJp(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: GoogleFonts.notoSansJp(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      themeMode: ref.watch(themeModeProvider),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: ref.watch(localeProvider),
    ));
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authService = AuthService();
  UserRole? _cachedRole;
  String? _lastUid;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    final result = await ForceUpdateService().checkForUpdate();
    if (!mounted || result == ForceUpdateResult.upToDate) return;

    final doc = await FirebaseFirestore.instance.doc('app_config/version').get();
    final data = doc.data() ?? {};
    if (!mounted) return;

    final isIos = Theme.of(context).platform == TargetPlatform.iOS;
    final storeUrl = isIos
        ? (data['iosStoreUrl'] ?? '').toString()
        : (data['androidStoreUrl'] ?? '').toString();

    showForceUpdateDialog(
      context,
      isForced: result == ForceUpdateResult.forced,
      storeUrl: storeUrl,
      message: (data['updateMessage'] ?? '').toString(),
    );
  }

  Future<UserRole> _resolveRole(User user) async {
    if (_lastUid == user.uid && _cachedRole != null) {
      return _cachedRole!;
    }
    final role = await _authService.getCurrentUserRole();
    _lastUid = user.uid;
    _cachedRole = role;
    return role;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.ruri),
            ),
          );
        }

        if (snapshot.hasError) {
          Logger.error(
            'Auth stream error',
            tag: 'AuthGate',
            error: snapshot.error,
          );
          return Scaffold(
            body: ErrorRetryWidget.general(
              onRetry: () {
                _cachedRole = null;
                _lastUid = null;
                setState(() {});
              },
              message: context.l10n.authGate_authError,
            ),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          _cachedRole = null;
          _lastUid = null;
          Logger.info('User not authenticated, showing guest page', tag: 'AuthGate');
          return const GuestHomePage();
        }

        if (user.isAnonymous) {
          Logger.info('Guest user, showing home page', tag: 'AuthGate');
          return const HomePage();
        }

        return FutureBuilder<UserRole>(
          future: _resolveRole(user),
          builder: (context, roleSnap) {
            if (roleSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: AppColors.ruri),
                ),
              );
            }

            if (roleSnap.hasError) {
              Logger.error('Role resolution error', tag: 'AuthGate', error: roleSnap.error);
              return Scaffold(
                body: ErrorRetryWidget.general(
                  onRetry: () {
                    _cachedRole = null;
                    _lastUid = null;
                    setState(() {});
                  },
                  message: context.l10n.authGate_roleError,
                ),
              );
            }

            final role = roleSnap.data ?? UserRole.user;

            if (role.isAdmin) {
              Logger.info('Admin user, showing admin dashboard', tag: 'AuthGate',
                data: {'uid': user.uid.substring(0, 8)});
              return const AdminHomePage();
            }

            Logger.info('Worker user, showing home page', tag: 'AuthGate',
              data: {'uid': user.uid.substring(0, 8)});
            return const HomePage();
          },
        );
      },
    );
  }
}
