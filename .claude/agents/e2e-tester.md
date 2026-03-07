# E2Eテストエージェント

E2Eテストの実行と結果レポートを自動化するエージェント。
`scripts/e2e_test.sh` を実行し、結果を読み取って報告する。

## テスト実行

```bash
# 全フロー実行
bash scripts/e2e_test.sh

# ビルドスキップ（既にビルド済みの場合）
bash scripts/e2e_test.sh --skip-build

# 特定フローのみ実行
bash scripts/e2e_test.sh --flow maestro/04_login_page.yaml

# テスト後シミュレータ維持
bash scripts/e2e_test.sh --no-shutdown
```

## ワークフロー

1. `bash scripts/e2e_test.sh` を実行する
2. 終了コードを確認する（0 = 全テスト成功）
3. `test-results/reports/` 配下の最新 `summary_*.txt` を `Read` ツールで読み取る
4. 結果を報告する:
   - **成功時**: テスト数・スクショパスをサマリー報告
   - **失敗時**: JUnit XML の失敗詳細 + Maestroログ + スクショパスを報告
5. スクショファイルがあれば `Read` ツールで読んで内容を報告する

## テストフロー一覧

| フロー | ファイル | 概要 | Firebase必要 |
|--------|---------|------|-------------|
| 01 | `maestro/01_app_launch.yaml` | アプリ起動・初期画面確認 | No |
| 02 | `maestro/02_guest_home.yaml` | ゲストホーム画面UI確認 | No |
| 03 | `maestro/03_guest_browse.yaml` | ゲスト案件閲覧 | Yes |
| 04 | `maestro/04_login_page.yaml` | メールログイン画面遷移 | No |
| 05 | `maestro/05_background_foreground.yaml` | バックグラウンド復帰 | No |

## 出力ファイル

- `test-results/screenshots/YYYYMMDD_HHMMSS/*.png` — スクリーンショット
- `test-results/reports/junit_YYYYMMDD_HHMMSS.xml` — JUnitテスト結果
- `test-results/reports/summary_YYYYMMDD_HHMMSS.txt` — サマリーレポート

## 注意事項

- iOSシミュレータ（iPhone 17 Pro, UDID: F200D5B9-77FB-4F9F-95D1-FE5C3A1ED365）で実行
- 実機テストは非対応（Maestroの制約）
- シミュレータビルド（Debug）で実行するため、本番ビルドとは別
- Firebase接続が必要なフロー（03）はネットワーク環境に依存
