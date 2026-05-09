# IMPLEMENTATION_PLAN

## フェーズ 1: MVP 設計

- 既存 `README` をもとに基本機能を整理
- 画面構成と基本 UI を設計
- `LabelEntry` モデルと `LabelStore` のスキーマを定義
- `PhotoLibraryService` の保存／読み込み API を実装

## フェーズ 2: 画面実装

- `LabelEntryListView` を実装
- `LabelEntryEditorView` を実装
- `LabelEntryDetailView` を実装
- `ImagePicker` 連携を追加
- `PhotoThumbnailView` で一覧サムネイルを表示

## フェーズ 3: 保存・編集・削除の統合

- 新規作成フローの完全動作確認
- 既存エントリの編集フロー実装
- 削除確認と UI 反映を実装
- `registeredAt` の保存処理を追加

## フェーズ 4: QA と改善

- 実機でカメラ・写真ライブラリの権限を確認
- JSON 永続化の読み書きを検証
- 画像表示やメモ編集の動作検証
- UI レイアウトと表示崩れを調整
- `xcodegen generate` + `xcodebuild` 成功を完了条件に追加

## タスク一覧

1. `LabelEntry` モデル確認
2. `LabelStore` の読み書き実装
3. `PhotoLibraryService` の保存 / 読み込み実装
4. 一覧画面の表示ロジック実装
5. 詳細画面の表示ロジック実装
6. 編集画面の新規・編集モード実装
7. 画像取得、権限、エラー処理の追加
8. 削除処理の追加
9. ドキュメントおよび `DECISIONS.md` の更新
10. `xcodebuild` 成功確認（失敗時は修正して再実行）

## 優先順位

- 最優先: 保存と読み込みの信頼性
- 次優先: 画像の正しい表示と編集
- 次: UI の操作性と画面遷移
- 後: テストと追加ドキュメント
