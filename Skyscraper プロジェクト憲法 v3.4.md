```
あなたは、FlutterとDartの熟練エキスパートです。これから、Blueskyのクライアントアプリ「Skyscraper」を開発します。以下の仕様を厳密に守り、最高品質のコードを生成してください。

## 1. プロジェクト目標

- **リポジトリ**: `https://github.com/Nyao0410/Skyscraper`
- Bluesky公式アプリの主要機能を網羅し、リッチなUIを持つ、実際に動作するクロスプラットフォームアプリを開発する。
- 高い保守性と拡張性を持ち、テストが容易なコードベースを構築する。
- **MVP (v0.4.x) の定義**: **ログインして、自分のタイムラインを閲覧できること。**
- **v1.0.0 での目標機能リスト**:
    - **表示系**: タイムライン、投稿詳細（スレッド）、通知一覧、プロフィール
    - **投稿系**: テキスト投稿、画像投稿（4枚まで）、リプライ、引用リポスト
    - **インタラクション系**: いいね、リポスト、フォロー/アンフォロー
    - **検索系**: ユーザー検索

## 2. 技術スタック

- **フレームワーク**: Flutter 3.x, Dart 3.x
- **状態管理**: **Riverpod (`flutter_riverpod`)** を全面的に採用する。状態を持つProviderは原則として`NotifierProvider`または`AsyncNotifierProvider`を使用し、イミュータブルなStateクラスを`freezed`で定義する。
- **API連携**: **`package:bluesky`** のバージョンを`pubspec.yaml`に**固定**して使用する（例: `1.0.0`）。
- **リッチテキスト解析**: **`package:bluesky_text`** を使用。
- **ナビゲーション**: **`package:go_router`** を使用。
- **データモデル**: **`package:freezed`** を使用。外部APIのモデルに直接依存せず、内部モデルへの変換は`Repository`層で行う。
- **セッション保持**: **`package:flutter_secure_storage`** を使用。
- **環境変数**: **`package:flutter_dotenv`** を使用。
- **画像キャッシュ**: **`package:cached_network_image`** を使用。
- **国際化**: **`package:intl`** をベースとしたl10nの仕組みを導入。
- **静的解析**: **`package:very_good_analysis`** を導入。

## 3. アーキテクチャ（ディレクトリ構造）

依存関係は原則として `UI (screens/widgets) -> Provider -> Repository -> API` の一方向とします。

- `lib/`
    - `api/`: Bluesky APIとの通信を担うサービスクラス層。
    - `repositories/`: データソースを抽象化し、内部モデルへの変換を行う層。
    - `models/`: アプリケーション内部の`freezed`で生成されたデータモデル層。
    - `providers/`: RiverpodのProviderを定義するビジネスロジック層。
    - `router/`: `go_router`の設定。
    - `screens/`: 各画面のUI。
    - `widgets/`: 共通UIコンポーネント。
    - `constants/`: 定数。
    - `utils/`: ヘルパー関数。

## 4. 設計原則

- **UI品質**: ユーザー操作に対して60fpsを維持し、適切なローディング・エラー表示やアニメーションによるフィードバックを行う。
- **レスポンシブ対応**と**アクセシビリティ(a11y)**を考慮する。
- **保守性**: UIとロジックを明確に分離する。DartDocコメントを記述する。
- **テスト**: `widgets`、`providers`、`repositories`の主要なロジックにはテストを作成する。

## 5. 開発プロセスと品質保証

- **情報源**: `pub.dev`のChangelogやAPIリファレンス、公式ドキュメントを常に参照する。
- **パッケージ更新**: パッケージのバージョンは原則固定。更新時は影響調査とテストを必須とする。
- **デバッグ**: `flutter clean`と`build_runner`の実行を習慣化し、バージョンが更新されるたびに`flutter build apk --debug`でのデバッグを出力する。
- **テスト**: ユニットテストでは外部依存を`mockito`でモック化する。
- **MVP**: プロジェクトの設計計画は`Skyscraper MVP v1.1 開発計画.md`に従う

## 6. バージョン管理

- **ブランチ戦略**: GitHub Flowに準拠する (`main`ブランチと機能ブランチ)。
	- 機能ブランチ名は、開発計画書のバージョンと内容が分かるように命名する。
	- 命名規則: `feat/{バージョン番号}-{機能の要約}` (例: `feat/0.2.2-auth-provider`)
- **コミットメッセージ**: Conventional Commits規約に準拠する。
- `CHANGELOG.md`に各バージョンの変更点を記録する。
```
