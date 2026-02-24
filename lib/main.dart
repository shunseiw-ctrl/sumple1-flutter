import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'pages/home_page.dart';
import 'pages/admin_home_page.dart';
import 'pages/onboarding_page.dart';
import 'presentation/pages/guest/guest_home_page.dart';
import 'core/utils/logger.dart';
import 'core/services/auth_service.dart';
import 'core/enums/user_role.dart';
import 'core/services/firestore_setup.dart';
import 'core/services/line_auth_service.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'core/services/splash_remover.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirestoreSetup.initialize();

  Logger.info('Firebase initialized', tag: 'main');

  await LineAuthService().handleLineCallbackIfNeeded();

  runApp(const MyApp());

  if (kIsWeb) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      removeSplashScreen();
    });
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = GoogleFonts.notoSansJpTextTheme(
      Theme.of(context).textTheme,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ALBAWORK',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: AppColors.ruri,
        colorSchemeSeed: AppColors.ruri,
        scaffoldBackgroundColor: AppColors.background,
        textTheme: baseTextTheme,
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
          shape: Border(
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
            side: BorderSide(color: AppColors.ruri, width: 1.5),
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
            borderSide: BorderSide(color: AppColors.borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
            borderSide: BorderSide(color: AppColors.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
            borderSide: BorderSide(color: AppColors.ruri, width: 1.5),
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
        dividerTheme: DividerThemeData(
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
        primaryColor: AppColors.ruri,
        colorSchemeSeed: AppColors.ruri,
        scaffoldBackgroundColor: AppDarkColors.background,
        textTheme: baseTextTheme,
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
          shape: Border(
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
            side: BorderSide(color: AppColors.ruri, width: 1.5),
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
            borderSide: BorderSide(color: AppDarkColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
            borderSide: BorderSide(color: AppDarkColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
            borderSide: BorderSide(color: AppColors.ruri, width: 1.5),
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
        dividerTheme: DividerThemeData(
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
      themeMode: ThemeMode.system,
      home: const AuthGate(),
    );
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
  bool? _onboardingComplete;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('onboarding_complete') ?? false;
    if (mounted) {
      setState(() {
        _onboardingComplete = done;
      });
    }
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
    if (_onboardingComplete == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.ruri),
        ),
      );
    }

    if (_onboardingComplete == false) {
      return const OnboardingPage();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
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
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    '認証エラーが発生しました\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
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
              return Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: AppColors.ruri),
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
