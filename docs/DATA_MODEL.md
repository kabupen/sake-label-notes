# DATA_MODEL

## エンティティ: LabelEntry

- `id: UUID`
  - 各エントリを一意に識別するID
- `title: String`
  - ラベル名
- `memo: String`
  - メモ内容
- `rating: Int`
  - 0〜5 のレーティング
- `category: BeverageCategory`
  - `日本酒` `ワイン` `ウイスキー`
- `imageLocalIdentifier: String`
  - 写真ライブラリに保存した画像のローカル識別子
- `backupImageFilename: String?`
  - アプリ内バックアップ画像のファイル名
- `registeredAt: Date`
  - 登録日時。カメラ撮影時は撮影時刻、フォトライブラリ選択時は EXIF 撮影時刻を採用する

## 永続化形式

- ローカル JSON ファイルを `Application Support` に保存
- 読み書きは `LabelStore` が担当
- JSON ファイル構造:
  - ルートは `[LabelEntry]` の配列そのものとする
- 保存先ファイル:
  - `Application Support/SakeLabelNotes/entries.json`

## 画像データの管理

- 画像本体は `PhotoLibraryService` を通じて iOS 写真ライブラリに保存
- アプリ内では `imageLocalIdentifier` を保持し、必要時に読み出す
- 写真アプリ側で削除された場合に備えて、`backupImageFilename` でアプリ内バックアップを参照する
- バックアップ画像は `Application Support/SakeLabelNotes/ImageBackups` に JPEG として保存する
- バックアップ画像は長辺 `960px` 以下に縮小する
- 同じ `LabelEntry` に対して画像の差し替えが発生した場合は、新規保存とローカル識別子更新で対応

## モデル制約

- `title` は空でも保存可能とする
- `memo` は空でも可
- `imageLocalIdentifier` は画像表示時に必要
- `registeredAt` は画像登録時に自動設定する
- 旧データの `createdAt` / `updatedAt` は読込時に `registeredAt` へ移行する
- `entries.json` の並び順は `registeredAt` の降順で維持する
