# DATA_MODEL

## エンティティ: LabelEntry

- `id: UUID`
  - 各エントリを一意に識別するID
- `title: String`
  - ラベル名
- `notes: String`
  - メモ内容
- `photoLocalIdentifier: String`
  - 写真ライブラリに保存した画像のローカル識別子
- `createdAt: Date`
  - 作成日時
- `updatedAt: Date`
  - 更新日時

## 永続化形式

- ローカル JSON ファイルを `Application Support` に保存
- 読み書きは `LabelStore` が担当
- JSON ファイル構造:
  - `entries: [LabelEntry]`

## 画像データの管理

- 画像本体は `PhotoLibraryService` を通じて iOS 写真ライブラリに保存
- アプリ内では `photoLocalIdentifier` を保持し、必要時に読み出す
- 同じ `LabelEntry` に対して画像の差し替えが発生した場合は、新規保存とローカル識別子更新で対応

## モデル制約

- `title` は空でないことを期待する
- `notes` は空でも可
- `photoLocalIdentifier` は必須ではないが、画像表示時に必要
- `createdAt` / `updatedAt` は保存時に自動設定
