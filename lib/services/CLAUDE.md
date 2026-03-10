# services/ — 外部サービス連携

サードパーティAPI・SDKとの統合層。

## 主要サービス

### Stripe 決済
- **アーキテクチャ**: Flutter (WebView) → Cloud Functions → Stripe API
- アプリ側で直接Stripe APIを叩かない（Cloud Functions経由）
- 現在 FeatureFlag で非表示化中（`lib/core/config/`）
- 関連: `stripe_onboarding_page`, `payment_detail`

### Google Maps
- `google_maps_flutter` パッケージ使用
- APIキーは iOS: `Info.plist` / Android: `AndroidManifest.xml` で管理
- 距離計算・ソート機能あり（`geolocator`）

### Firebase Messaging (FCM)
- プッシュ通知: `firebase_messaging` + `flutter_local_notifications`
- トークン管理は Firestore の users ドキュメントに保存
- バックグラウンド通知ハンドラーは `main.dart` で設定

### eKYC 本人確認
- 画像アップロード: `image_picker` → Firebase Storage
- レビューは管理者パネルから実施

## 注意事項
- APIキー・シークレットは絶対にコードにハードコードしない
- `.env` ファイルまたは Cloud Functions の環境変数で管理
- サービス追加時はエラーハンドリングと接続失敗時のフォールバックを必ず実装
