# API_SPEC

このプロジェクトでは外部 Web API を使用しません。内部サービス API を中心に定義します。

## LabelStore API

`LabelStore` はアプリのデータ永続化を担います。

### メソッド

- `loadEntries() throws -> [LabelEntry]`
  - ローカル JSON からエントリを読み込む
- `saveEntry(_ entry: LabelEntry) throws`
  - エントリを新規保存または更新保存する
- `deleteEntry(_ entry: LabelEntry) throws`
  - 対象エントリを削除する
- `resetStore() throws`
  - 開発用／テスト用にストアを初期化する

## PhotoLibraryService API

`PhotoLibraryService` は画像保存と読み込みを扱います。

### メソッド

- `requestAuthorization(completion: @escaping (Bool) -> Void)`
  - 写真ライブラリへのアクセス許可を要求する
- `savePhoto(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void)`
  - 画像を写真ライブラリに保存し、`localIdentifier` を返す
- `loadPhoto(localIdentifier: String, completion: @escaping (Result<UIImage, Error>) -> Void)`
  - `localIdentifier` から画像を読み込む
- `deletePhoto(localIdentifier: String, completion: @escaping (Result<Void, Error>) -> Void)`
  - 必要に応じて画像を削除する（オプション）

## アプリ内部 API

- `AppState` や画面間データバインディングは SwiftUI の `ObservableObject` / `@Binding` で実現
- 画面遷移は `NavigationStack` / `sheet` で行う

## エラー処理

- 永続化、画像操作は `Result` / `throws` でエラーを伝播
- UI ではアラートを表示してユーザーに通知
