# Skyscraper (Bluesky Client)

Skyscraperは、Flutterで構築された多機能なBlueskyクライアントアプリです。
Blueskyの基本機能に加え、動画投稿やチャット（DM）、高度なカスタマイズ機能を備えています。

## 🚀 主な機能

- **タイムライン**: ホーム、通知、検索、スレッド表示。
- **投稿機能**:
  - テキスト投稿（リンクの自動認識）。
  - 画像および動画の添付。
  - リアルタイムの文字数カウント。
  - 下書き保存機能。
  - **予約投稿機能**: 指定した時間に自動で投稿。
- **チャット (DM)**:
  - Blueskyのチャットプロトコルに対応したリアルタイムメッセージング。
  - メッセージのローカルキャッシュによる高速な表示。
- **プロフィール**: プロフィール表示、編集、ユーザー検索。
- **カスタマイズ**:
  - ダークモード/ライトモードの切り替え。
  - フォントサイズおよびフォントファミリーの変更。
  - 多言語対応（日本語/英語）。
- **メディア**: インアプリ動画プレイヤー、画像ビューアー。

## 🛠 技術スタック

- **Framework**: [Flutter](https://flutter.dev/) (SDK ^3.9.0)
- **API**: [bluesky](https://pub.dev/packages/bluesky) (Bluesky/AT Protocol)
- **Local Storage**:
  - `sqflite`: 下書きやデータのキャッシュ。
  - `flutter_secure_storage`: 認証情報の安全な保存。
  - `shared_preferences`: アプリ設定の保存。
- **Media**: `video_player`, `chewie`, `image_picker`.
- **Background**: `workmanager` によるバックグラウンド処理。
- **Localization**: `flutter_localizations`, `intl`.

## 📂 プロジェクト構造

```text
lib/
├── main.dart           # アプリのエントリーポイント、初期化処理
├── models/             # データモデルクラス
├── screens/            # 各画面のUI実装
│   ├── timeline_screen.dart
│   ├── chat_screen.dart
│   ├── new_post_screen.dart
│   └── ...
├── services/           # ビジネスロジック、API通信、状態管理
│   ├── bluesky_service.dart    # Bluesky APIとの通信
│   ├── database_service.dart   # SQLite操作
│   └── ...
├── widgets/            # 再利用可能なUIコンポーネント
│   ├── post_widget.dart
│   ├── video_player_widget.dart
│   └── ...
├── themes/             # テーマ定義
└── utils/              # ユーティリティ関数
```

## 🏁 開発の始め方

### 1. 依存関係のインストール
```bash
flutter pub get
```

### 2. ローカライズファイルの生成
多言語対応（L10n）を使用しているため、初回実行前や `.arb` ファイル編集後に以下のコマンドを実行してください。
```bash
flutter gen-l10n
```

### 3. アプリの実行
```bash
flutter run
```

## 📝 開発ガイドライン

- **状態管理**: シンプルな `ValueNotifier` や `setState` を中心に構成されています。
- **API通信**: `BlueskyService` を通じて行います。新しいAPIエンドポイントを追加する場合は、このクラスを拡張してください。
- **UI**: `widgets/` 内のコンポーネントを再利用し、一貫性のあるデザインを維持してください。
- **ローカライズ**: `lib/l10n/` 内の `.arb` ファイルを編集し、`flutter gen-l10n` を実行して反映させます。

---
Developed with ❤️ using Flutter.
