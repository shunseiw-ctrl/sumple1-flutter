import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'pages/home_page.dart';
import 'presentation/pages/guest/guest_home_page.dart';
import 'core/utils/logger.dart';
import 'core/services/firestore_setup.dart';
import 'core/services/line_auth_service.dart';

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
        primaryColor: Colors.black,
        scaffoldBackgroundColor: const Color(0xFFF4F5F7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: false,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
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
            foregroundColor: Colors.black,
            side: const BorderSide(color: Colors.black, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(0, 48),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.black,
            minimumSize: const Size(0, 44),
          ),
        ),
      ),
      // 認証状態に応じて画面を切り替え
      home: const AuthGate(),
    );
  }
}

/// 認証状態に応じて適切な画面を表示するゲート
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 読み込み中
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.black),
            ),
          );
        }

        // エラー
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

        // 未認証 → ゲスト画面
        if (user == null) {
          Logger.info('User not authenticated, showing guest page', tag: 'AuthGate');
          return const GuestHomePage();
        }

        // 認証済み → ホーム画面（役割は HomePage 内で判定）
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
