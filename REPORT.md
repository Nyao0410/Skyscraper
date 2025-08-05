# REPORT.md

## 2025年8月5日

### v0.1.0 タスク実行時のエラーと修正

#### 問題1: `flutter pub run build_runner build` 実行時のエラー (初期)

`flutter pub run build_runner build --delete-conflicting-outputs` コマンド実行時に、`custom_lint_core`と`analyzer`のバージョン競合によるエラーが発生しました。具体的には、`custom_lint_core-0.6.3`が`AugmentationImportDirective`などの型を見つけられないというエラーでした。

**原因**: `pubspec.yaml`で固定されていた`custom_lint`、`riverpod_lint`、`very_good_analysis`のバージョンが古く、現在のFlutter/Dart SDK (3.8.1) および他の依存パッケージとの互換性が失われていたためです。特に、`custom_lint_core-0.6.3`がDart 3.3で導入された機能を使用しているにもかかわらず、プロジェクトのSDKが3.2.0と設定されていたことが原因でした。

**修正**: `pubspec.yaml`の`environment.sdk`を`'>=3.2.0 <4.0.0'`に設定し、`custom_lint`を`0.8.0`に更新しました。

#### 問題2: `pubspec.yaml`のYAML構文エラー

上記の問題1の修正後、`flutter pub get`実行時に`pubspec.yaml`のYAML構文エラーが発生しました。具体的には、`json_annotation`と`json_serializable`のインデントがずれていました。

**原因**: 以前の`replace`操作で、文字列置換時にインデントが正しく適用されなかったためです。

**修正**: `pubspec.yaml`を読み込み、手動でインデントを修正する`replace`コマンドを実行し、正しいYAML構文に修正しました。

#### 問題3: `flutter pub get` 実行時の依存関係競合 (連鎖)

YAML構文エラー修正後、再度`flutter pub get`を実行したところ、複数の依存関係競合が連鎖的に発生しました。

**3.1. `custom_lint` と `freezed_annotation` の競合**
- **問題**: `custom_lint 0.8.0`が`freezed_annotation ^3.0.0`を要求する一方、プロジェクトでは`freezed_annotation 2.4.1`が指定されていました。
- **修正**: `freezed_annotation`を`3.1.0`に、`freezed`を`3.2.0`に更新しました。

**3.2. `riverpod_lint` と `custom_lint` の `analyzer_plugin` 競合**
- **問題**: `riverpod_lint 2.3.10`が`analyzer_plugin ^0.11.2`を要求する一方、`custom_lint 0.8.0`が`analyzer_plugin ^0.13.0`を要求していました。
- **修正**: `riverpod_lint`を最新のプレリリースバージョンである`3.0.0-dev.17`に更新しました。これに伴い、`riverpod_annotation`も`3.0.0-dev.17`に更新しました。

**3.3. `custom_lint` と `json_serializable` の `analyzer` 競合**
- **問題**: `custom_lint >=0.8.0`が`analyzer ^7.5.0`を要求する一方、`json_serializable 6.8.0`が`analyzer >=5.12.0 <7.0.0`を要求していました。
- **修正**: `json_serializable`を最新の安定バージョンである`6.10.0`に更新しました。

**3.4. `freezed` と `riverpod_generator` の `source_gen` 競合**
- **問題**: `freezed >=3.2.0`が`source_gen ^3.0.0`を要求する一方、`riverpod_generator 2.4.0`が`source_gen ^1.2.0`を要求していました。
- **修正**: `riverpod_generator`を最新の安定バージョンである`2.6.5`に更新しました。

**3.5. `freezed` と `build_runner` の `dart_style` 競合**
- **問題**: `freezed >=3.1.0`が`dart_style ^3.0.0`を要求する一方、`build_runner 2.4.10`が`dart_style ^2.0.0`を要求していました。
- **修正**: `build_runner`を最新の安定バージョンである`2.6.0`に更新しました。

**3.6. `bluesky` と `flutter_test` の `characters` 競合**
- **問題**: `bluesky 1.0.1`が`characters ^1.4.1`を要求する一方、`flutter_test`は`characters 1.4.0`に固定されています。これはFlutter SDKの内部的な依存関係によるもので、現時点では解決策が見つかっていません。

### v0.1.0-rollback タスク実行時の問題

`v0.1.0-rollback`タスクにおいて、`pubspec.yaml`を「実績のある安定バージョンセット」に戻し、`flutter pub get`は成功しましたが、`flutter pub run build_runner build`が再度失敗しました。

**問題**: `custom_lint 0.6.4` (およびその推移的依存関係である`custom_lint_core-0.6.3`) が、現在のFlutter/Dart SDK (3.8.1) と互換性がないため、`Type 'AugmentationImportDirective' not found`というエラーが発生しました。このエラーは、`custom_lint_core`がDart 3.3で導入された機能を使用していることを示唆しており、現在のSDKバージョンとのミスマッチが原因です。

**現状**: 「実績のある安定バージョンセット」として提供された`custom_lint`、`riverpod_lint`、`very_good_analysis`のバージョンは、現在のFlutter/Dart SDK (3.8.1) と互換性がないことが判明しました。

### v0.1.0-hotfix タスク実行時の問題と解決

`v0.1.0-hotfix`タスクでは、コアパッケージの安定性を維持しつつ、Linting環境を近代化改修することを目標としました。

**問題**: `flutter pub get`実行時に、`custom_lint`、`riverpod_lint`、`custom_lint_builder`、`rxdart`間の複雑な依存関係競合が発生しました。エラーメッセージは`custom_lint`を`^0.6.10`にアップグレードすることを推奨していました。

**解決**: `custom_lint`を`0.6.10`に更新したところ、`flutter pub get`が正常に完了しました。その後、`flutter pub run build_runner build --delete-conflicting-outputs`も成功し、プロジェクトの基盤が正常に構築されました。

**警告**: `build_runner`の実行時に、`riverpod_generator`が`analyzer`のバージョンについて警告を発しました（`Analyzer language version: 3.7.0`, `SDK language version: 3.8.0`）。これは、`analyzer`のバージョンがSDKのバージョンと完全に一致していないことを示唆していますが、ビルド自体は成功しました。

### v0.1.1 タスク実行時の問題と解決

`v0.1.1`タスクにおいて、`flutter run -d chrome`コマンドを実行したところ、`lib/src/screens/home_screen.dart`と`lib/src/screens/login_screen.dart`で`const`に関するエラーが発生しました。

**問題**: `Cannot invoke a non-'const' constructor where a const expression is expected`というエラーメッセージが表示され、`AppBar`や`Text`ウィジェットのコンストラクタが`const`ではないにもかかわらず、`const`コンテキストで使用されていることが原因でした。

**試行と結果**: 
1. `AppBar`の`const`を削除 -> 失敗 (エラー継続)
2. `Text`ウィジェットに`const`を追加 -> 失敗 (エラー継続)
3. `Scaffold`の`const`を削除 -> 失敗 (エラー継続)
4. `HomeScreen`と`LoginScreen`の`build`メソッド内の`const`キーワードを全て削除 -> 成功

**解決**: `HomeScreen`と`LoginScreen`の`build`メソッド内の`const`キーワードを全て削除することで、デバッグビルドが成功し、アプリケーションがChromeで起動することを確認しました。

### 今後の対応

プロジェクトの基盤構築は完了しました。今後は、憲法に則り、MVP開発を進めていきます。