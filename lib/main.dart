import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';

// ✅ 職人用の通常起動
import 'pages/home_page.dart';

// ✅ 管理者ログインは HomePage -> ProfilePage から遷移で使う想定
// （main.dart から直接は呼ばないが、ファイルが存在していても問題なし）
// import 'pages/admin_login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ 起動時に認証状態を用意（ログイン済みならスキップ）
  final auth = FirebaseAuth.instance;
  if (auth.currentUser == null) {
    await auth.signInAnonymously();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,

      // ✅ HomePage は const constructor なので const でOK（＝あなたのHomePageはA）
      home: HomePage(),
    );
  }
}
