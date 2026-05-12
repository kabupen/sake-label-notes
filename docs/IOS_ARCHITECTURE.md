# IOS_ARCHITECTURE

## アーキテクチャ概要

このアプリは、SwiftUI を UI レイヤーに、ローカルデータストアとフォトライブラリ連携をサービス層に分離したシンプルな構成を採用します。

## レイヤー

- `Views`:
  - SwiftUI ベースの画面、入力フォーム、一覧表示
  - ViewModel ではなく、軽量な `@StateObject` / `@State` を使った画面状態管理
- `Services`:
  - `LabelStore`: JSON ファイルによるエントリの永続化
  - `PhotoLibraryService`: 画像保存と写真ライブラリからの読み出し
- `Models`:
  - `LabelEntry`: ラベルメモのデータモデル

## 主要コンポーネント

- `AppLaunchView`
  - アプリ起動時のスプラッシュ表示と一覧画面への遷移を担う
- `LabelEntryListView`
  - すべてのエントリを一覧表示
  - フィルター、削除、選択操作を提供
- `SettingsView` / `OtherInfoView`
  - 一覧画面の補助メニュー配下の静的画面を提供
- `LabelEntryDetailView`
  - 単一エントリの表示と操作
- `LabelEntryEditorView`
  - 新規作成・編集の UI
- `ImagePicker`
  - 写真選択・撮影をラップ
- `PhotoThumbnailView`
  - サムネイル表示

## データフロー

1. `LabelEntryListView` が `LabelStore` に保存済みエントリを読み込む
2. 新規追加または編集時に `LabelStore` へ保存
3. 画像撮影／選択時に `PhotoLibraryService` が写真ライブラリへ保存し `localIdentifier` を取得
4. `PhotoLibraryService` は表示継続用にアプリ内バックアップ画像も保存する
5. `LabelEntry` は `localIdentifier` と必要に応じて `backupImageFilename` を保持し、表示時に写真ライブラリ読込失敗時はバックアップへフォールバックする

## 依存関係ルール

- `Views` は `Services` に依存可能
- `Services` は `Models` に依存可能
- `Models` は `Views` / `Services` に依存しない

## 例外と拡張性

- 将来的にクラウド同期を追加する場合は、`LabelStore` のインターフェースを抽象化してローカル／リモート実装を置き換え可能にします。
- `PhotoLibraryService` は権限処理と画像保存の責務に限定します。
