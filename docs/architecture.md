# ALBAWORK アーキテクチャ概要

## システム構成

```
[Flutter App] ←→ [Firebase Auth]
      ↕              ↕
[Firestore DB] ←→ [Cloud Functions] ←→ [Stripe API]
      ↕
[Firebase Storage]  [Firebase Messaging]  [Crashlytics]
```

## レイヤー構成

```
UI層:     pages/ & presentation/  — 画面表示、ユーザー操作
状態層:   core/providers/         — Riverpod による状態管理
データ層: data/repositories/       — Firestore CRUD 操作
モデル層: data/models/            — ドキュメント⇔オブジェクト変換
サービス層: services/             — 外部API連携（Stripe, Maps等）
```

**依存方向**: UI → 状態 → データ → Firebase（一方向）

## 認証フロー

```
起動 → GuestHomePage（認証不要で案件閲覧可能）
        ↓ 応募・チャット等の操作
      LoginPage（Email/電話番号/Apple Sign In）
        ↓ 認証成功
      AuthGate → ロール判定 → 職人 or 管理者画面
```

## 状態管理（Riverpod）

- **グローバル状態**: `lib/core/providers/` — 認証、Firebase インスタンス、Admin データ
- **ページ固有状態**: 各ページ内で定義
- **パターン**: `StateNotifierProvider` + `AsyncValue<T>`
- **Admin ストリーム**: `rxdart` の `combineLatest` でリアルタイム統合

## ルーティング（go_router）

- `ShellRoute` でボトムナビゲーション構成
- `redirect` で認証ガード
- `app_links` で Deep Linking 対応

## データフロー

```
[ユーザー操作] → [Provider.method()] → [Repository.crud()] → [Firestore]
                                                                  ↓
[UI更新] ← [StreamProvider / FutureProvider] ← [Firestore Stream/Query]
```

## 技術選定の理由

| 技術 | 選定理由 |
|------|---------|
| Flutter | iOS/Android/Web のクロスプラットフォーム |
| Firebase | BaaS によるサーバーレス運用、リアルタイム同期 |
| Riverpod | 型安全な状態管理、テスタビリティ |
| go_router | 宣言的ルーティング、Deep Linking サポート |
| Cloud Functions | サーバーサイドロジック（Stripe決済、認証処理） |
| rxdart | 複雑なストリーム操作（Admin パネル） |

## セキュリティ

- **Firestore Rules**: `firestore.rules` でドキュメントレベルのアクセス制御
- **Cloud Functions**: 決済・認証などの機密処理はサーバーサイドで実行
- **レート制限**: API 呼び出しにレート制限を適用
- **eKYC**: 本人確認プロセスで不正利用を防止
