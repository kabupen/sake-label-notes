# SakeLabelNotes

完全ローカル動作の「お酒ラベル画像付きメモ」iOSアプリです。

## 機能

- カメラでラベルを撮影
- 撮影画像をiOS写真アプリへ保存
- 保存画像の`localIdentifier`を使ってアプリ内で表示
- ラベル名・メモをアプリ内JSONへローカル保存
- 一覧表示、詳細編集、削除

## 技術構成

- SwiftUI
- ローカルJSONストレージ（Application Support）
- Photos / AVFoundation
- すべて端末内保存（クラウド連携なし）

## 起動方法

1. `cd SakeLabelNotes`
2. `xcodegen generate`
3. `open SakeLabelNotes.xcodeproj`
4. 実機でビルド（カメラ利用のため）

## 開発フロー

- 開発手順の正本は `docs/DEVELOPMENT.md` を参照してください。
- とくに「実装タスクは `xcodebuild` 成功までを完了条件にする」運用を必須とします。

## 権限

- Camera
- Photo Library (Read/Write)
- Photo Library Additions

`Info.plist`相当の設定は`project.yml`内に記載済みです。
