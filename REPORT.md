# REPORT.md

## Skyscraper プロジェクト憲法 開発状況報告

### 1. プロジェクト概要
Blueskyクライアントアプリ「Skyscraper」の開発は、MVP（ログインとタイムライン閲覧）の達成に向けて順調に進んでいます。本報告書では、これまでの主要なタスクの実施状況と、現在のコード品質についてまとめます。

### 2. 実施済み主要タスク

#### 2.1. v0.2+v0.3-phoenix-manual: `freezed`からのモデル手動移行
- `pubspec.yaml`から`freezed`および`json_serializable`の依存関係を削除しました。
- `Author`および`Post`モデルを`freezed`に依存しないプレーンなDartクラスとして手動で再実装しました。
- 関連するLint警告（`public_member_api_docs`, `sort_constructors_first`, `eol_at_end_of_file`）を修正しました。

#### 2.2. v0.4.0-pre: デザインシステムの定義
- `lib/src/constants`ディレクトリを作成し、`theme.dart`（ライト/ダークテーマ）と`sizes.dart`（共通レイアウト定数）を定義しました。
- `lib/main.dart`に定義したテーマを適用しました。
- `lib/src/widgets/common`ディレクトリを作成し、`loading_indicator.dart`と`error_display.dart`の骨格を作成しました。
- 関連するLint警告（`public_member_api_docs`, `avoid_redundant_argument_values`, `flutter_style_todos`, `prefer_int_literals`, `always_put_required_named_parameters_first`）を修正しました。

#### 2.3. v0.4.0: ログイン画面UIとロジックの実装
- `lib/src/providers/auth/login_screen_controller.dart`を作成し、ログイン処理の状態管理（ローディング、成功、エラー）を実装しました。
- `lib/src/screens/login_screen.dart`を更新し、`LoginScreenController`と連携するUI（入力フォーム、ログインボタン、エラー表示、画面遷移）を実装しました。
- `build_runner`を実行し、必要なコードを生成しました。

#### 2.4. v0.4.0-debug: `ThemeData.brightness`競合の修正
- `flutter run -d chrome`実行時に発生した`ThemeData.brightness`と`ColorScheme.brightness`の競合エラーを特定し、`lib/src/constants/theme.dart`から`ThemeData`の`brightness`プロパティを削除することで修正しました。

#### 2.5. v0.4.1: タイムライン表示の実装
- `lib/src/providers/timeline/timeline_provider.dart`を作成し、`FakeTimelineRepository`から投稿データを取得してUIに供給するロジックを実装しました。
- `lib/src/screens/home_screen.dart`を更新し、`timelineProvider`の状態を監視してタイムライン（投稿リスト）を表示するようにしました。
- `build_runner`を実行し、必要なコードを生成しました。

#### 2.6. v0.5.0: `ShellRoute`とボトムナビゲーションの構築
- `lib/src/screens`に`search_screen.dart`, `notifications_screen.dart`, `profile_screen.dart`のプレースホルダー画面を追加しました。
- `lib/src/screens/main_shell.dart`を作成し、ボトムナビゲーションバーを持つメインUIの骨格を定義しました。
- `lib/src/navigation/app_router.dart`を`ShellRoute`を使用するように変更し、メインの4画面をボトムナビゲーションバーに統合しました。
- `build_runner`を実行し、必要なコードを生成しました。

#### 2.7. v0.5.0-fix: `const`エラーとLint警告の修正
- `notifications_screen.dart`, `profile_screen.dart`, `search_screen.dart`の`Scaffold`内の`AppBar`の`const`キーワード誤用を修正しました。
- `main_shell.dart`の`_onItemTapped`メソッド内の冗長な`break`文を削除しました。
- `public_member_api_docs`, `eol_at_end_of_file`などのLint警告を修正しました。

#### 2.8. v0.5.1: `PostCard`ウィジェットの作成
- `lib/src/widgets/post_card.dart`を新規作成し、投稿一つ分を表示するための再利用可能なカード型ウィジェットを実装しました。

#### 2.9. v0.5.2: `HomeScreen`への`PostCard`統合
- `lib/src/screens/home_screen.dart`を修正し、タイムラインの投稿表示に`PostCard`ウィジェットを使用するように変更しました。`ListView.builder`を`ListView.separated`に置き換え、各カード間に区切り線を追加しました。

#### 2.10. v0.5.3: `PostCard`ウィジェットテストの作成
- `test/src/widgets/post_card_test.dart`を新規作成し、`PostCard`ウィジェットの表示ロジックを検証するウィジェットテストを実装しました。
- テスト実行時の`NetworkImageLoadException`を回避するため、テストデータ内の`avatar`を`null`に設定し、`Icon(Icons.person)`のフォールバックをテストするように修正しました。
- `find.text`の期待値が実際の表示と一致するように修正しました。

#### 2.11. v0.5.4-lintfix: 残存Lint警告の修正
- `lib/src/screens/post_detail_screen.dart`および`test/src/widgets/post_card_test.dart`の末尾に改行を追加し、`eol_at_end_of_file`警告を解消しました。
- `test/src/widgets/post_card_test.dart`内の`Post`インスタンスの`createdAt`引数を`DateTime.utc(2023)`に変更し、`avoid_redundant_argument_values`警告を解消しました。
- `test/src/widgets/post_card_test.dart`内の80文字を超える行を整形し、`lines_longer_than_80_chars`警告を解消しました。

#### 2.12. v0.6.0: Optimistic UIによる「いいね」機能の実装
- `lib/src/models/post.dart`に`isLiked`と`likeUri`プロパティを追加し、`copyWith`メソッドを更新しました。
- `lib/src/repositories/timeline_repository.dart`に`likePost`と`unlikePost`メソッドを追加し、`lib/src/repositories/fakes/fake_timeline_repository.dart`にその偽の実装を追加しました。
- `lib/src/providers/timeline/timeline_provider.dart`を`AsyncNotifierProvider`に刷新し、Optimistic UIによる「いいね」のトグルロジックを実装しました。
- `lib/src/widgets/post_card.dart`を更新し、「いいね」ボタンが`isLiked`の状態に応じてアイコンと色を変化させ、`onLikePressed`コールバックを呼び出すように修正しました。
- `lib/src/screens/home_screen.dart`を更新し、`PostCard`に`onLikePressed`コールバックを渡すように修正しました。
- `build_runner`を実行し、必要なコードを生成しました。

#### 2.13. v0.6.1: Optimistic UIによる「リポスト」機能の実装
- `lib/src/models/post.dart`に`isReposted`と`repostUri`プロパティを追加し、`copyWith`メソッドを更新しました。
- `lib/src/repositories/timeline_repository.dart`に`repostPost`と`unrepostPost`メソッドを追加し、`lib/src/repositories/fakes/fake_timeline_repository.dart`にその偽の実装を追加しました。
- `lib/src/providers/timeline/timeline_provider.dart`に`toggleRepost`メソッドを追加し、Optimistic UIによる「リポスト」のトグルロジックを実装しました。
- `lib/src/widgets/post_card.dart`を更新し、「リポスト」ボタンが`isReposted`の状態に応じてアイコンと色を変化させ、`onRepostPressed`コールバックを呼び出すように修正しました。
- `lib/src/screens/home_screen.dart`を更新し、`PostCard`に`onRepostPressed`コールバックを渡すように修正しました。
- `build_runner`を実行し、必要なコードを生成しました。

#### 2.14. v0.7.0: テキスト投稿機能の実装
- `lib/src/repositories/timeline_repository.dart`に`createPost`メソッドを追加し、`lib/src/repositories/fakes/fake_timeline_repository.dart`にその偽の実装を追加しました。
- `lib/src/providers/post/create_post_controller.dart`を新規作成し、投稿処理の状態管理とタイムラインの更新ロジックを実装しました。
- `lib/src/screens/create_post_screen.dart`を新規作成し、投稿画面のUIを実装しました。
- `lib/src/navigation/app_router.dart`に投稿画面へのルートを追加し、`lib/src/screens/main_shell.dart`に投稿ボタンを追加しました。
- `build_runner`を実行し、必要なコードを生成しました。

#### 2.15. v0.7.0-fix.1: `create_post_screen.dart`の非同期処理リファクタリング
- `lib/src/screens/create_post_screen.dart`を`ref.listen`パターンを用いてリファクタリングし、非同期処理をまたいだ`BuildContext`の安全な使用を確保しました。

#### 2.16. v0.7.0-fix.2: `Missing documentation for a public member`の修正
- `lib/src/repositories/timeline_repository.dart`および`lib/src/screens/create_post_screen.dart`にDartDocコメントを追加し、`Missing documentation for a public member`警告を解消しました。

### 3. 現在のコード品質

`flutter analyze`の実行結果、以下の5件の`info`レベルの警告が残っています。

- **`Missing a newline at the end of the file`**:
    - `lib/src/navigation/app_router.dart:70:2`
    - `lib/src/repositories/fakes/fake_timeline_repository.dart:64:2`
    - `lib/src/screens/home_screen.dart:50:2`
    - `lib/src/widgets/post_card.dart:162:2`
    - `test/src/widgets/post_card_test.dart:87:2`
    - **説明**: ファイルの末尾に改行がないことを示しています。

- **`Unnecessary use of a 'double' literal`**:
    - `lib/src/screens/create_post_screen.dart:48:39`
    - **説明**: `double`リテラル（例: `8.0`）が冗長であり、`int`リテラル（例: `8`）で十分であることを示しています。

- **`The value of the argument is redundant because it matches the default value`**:
    - `test/src/widgets/post_card_test.dart:34:19`
    - `test/src/widgets/post_card_test.dart:67:19`
    - **説明**: 引数の値がデフォルト値と同じであるため、冗長であることを示しています。

### 4. 今後の課題
- 残存するLint警告の解消。
- MVPの次のステップとして、投稿詳細画面（スレッド表示）の実装を進めます。
- API連携を`package:bluesky`に切り替え、フェイクデータではなく実際のBluesky APIからデータを取得するように変更します。
- プロジェクト憲法に則り、継続的なコード品質の維持に努めます。