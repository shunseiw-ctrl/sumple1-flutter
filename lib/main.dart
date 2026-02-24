import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'pages/home_page.dart';
import 'presentation/pages/guest/guest_home_page.dart';
import 'core/utils/logger.dart';
import 'core/services/firestore_setup.dart';
import 'core/services/line_auth_service.dart';
import 'package:sumple1/core/constants/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirestoreSetup.initialize();

  Logger.info('Firebase initialized', tag: 'main');

  await LineAuthService().handleLineCallbackIfNeeded();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ALBAWORK',
      theme: ThemeData(
        primaryColor: AppColors.ruri,
        colorSchemeSeed: AppColors.ruri,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: false,
          shape: Border(
            bottom: BorderSide(color: AppColors.divider, width: 0.5),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: AppColors.ruri,
          unselectedItemColor: AppColors.textHint,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.ruri,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(0, 48),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.ruri,
            side: BorderSide(color: AppColors.ruri, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(0, 48),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.ruri,
            minimumSize: const Size(0, 44),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
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
          Logger.info('User not authenticated, showing guest page', tag: 'AuthGate');
          return const GuestHomePage();
        }

        Logger.info(
          'User authenticated, showing home page',
          tag: 'AuthGate',
          data: {'uid': user.uid.substring(0, 8)},
        );
        return const HomePage();
      },
    );
  }
}
