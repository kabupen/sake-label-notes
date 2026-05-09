# DEVELOPMENT

このドキュメントを開発フローの正本とし、`README.md` は概要と導線のみを扱う。

## 開発環境

- macOS
- Xcode 15 以上
- Swift 5.9 以上
- SwiftUI
- XcodeGen

## セットアップ手順

1. リポジトリをクローン
2. `cd SakeLabelNotes`
3. `xcodegen generate`
4. `open SakeLabelNotes.xcodeproj`
5. 実機またはシミュレータでビルド

## フォルダ構成

- `Sources/App/`
  - アプリエントリポイントと `Info.plist`
- `Sources/Models/`
  - データモデル
- `Sources/Services/`
  - 永続化、写真ライブラリ連携
- `Sources/Views/`
  - 画面コンポーネント

## ビルドと実行

- `xcodegen generate` でプロジェクトを生成
- `open SakeLabelNotes.xcodeproj`
- `Product > Run` または `⌘R`

## 開発フロー（必須）

- すべての実装タスクは、最後に `xcodebuild` が成功するまでを作業範囲に含める。
- UI の最終見た目確認は Xcode Preview / Simulator で行うが、CLI 側ではコンパイル成立を必ず確認する。
- 変更ごとに以下を順に実行する:
  1. `xcodegen generate`
  2. `xcodebuild -project SakeLabelNotes.xcodeproj -scheme SakeLabelNotes -sdk iphonesimulator -configuration Debug build`
- `xcodebuild` が失敗した場合は、原因を修正して再実行し、成功するまで繰り返す。
- 大きな機能追加の際にはgit commit を行う。適切な粒度でcommitをまとめること。

## ビルド失敗時の確認ポイント

- `Found no destinations` が出る場合:
  - Xcode の `Settings > Components` で iOS Simulator Runtime をインストールする。
  - その後 `xcodebuild -showdestinations` で有効な destination を確認する。
- `xcodegen` 後に新規ファイルが拾われない場合:
  - `xcodegen generate` を再実行してからビルドする。
- 依存する権限文言や `Info.plist` 設定に変更がある場合:
  - `project.yml` と生成後の `.xcodeproj` の整合を確認する。

## テスト戦略

- 現状は UI/Unit テストが未設定
- 追加する場合は以下を推奨:
  - `LabelStore` の保存／読み込みテスト
  - `PhotoLibraryService` の権限と保存フローのモックテスト
  - 主要画面の UI スナップショットテスト

## コード品質

- SwiftLint を導入する場合は `project.yml` に設定を追加
- 変更を加える際は、既存のデータモデルと保存ロジックへの影響を確認

## リリース準備

- `Info.plist` の権限説明文を確認
- 実機でカメラと写真ライブラリのアクセスフローを検証
- App Store 提出時はクラウドレス設計とプライバシー文言を整備
