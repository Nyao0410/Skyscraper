

**目的**: UI実装フェーズ（v0.5.x）以降の開発効率とデザインの一貫性を最大化するため、アプリケーションの基本的なデザインシステムを定義する。このタスクは、開発計画書における`v0.5.0`の前に完了させることを目標とする。

### タスク一覧

#### 1. テーマとカラーパレットの定義 (`constants/theme.dart`)

- [ ] **ライトテーマの定義**:
    
    - [ ] `primary` (主要なボタン、アクティブな要素)
        
    - [ ] `secondary` (補助的な要素)
        
    - [ ] `background` (画面全体の背景色)
        
    - [ ] `surface` (カードなどの背景色)
        
    - [ ] `onPrimary`, `onBackground` などテキスト・アイコンの色
        
- [ ] **ダークテーマの定義**:
    
    - [ ] ライトテーマと同様のカラーセットをダークモード用に定義する。
        
- [ ] `ThemeData`オブジェクトを作成し、上記カラーパレットを適用する。
    
- [ ] `main.dart`で`theme`と`darkTheme`プロパティに上記テーマを設定する。
    

#### 2. タイポグラフィ（文字スタイル）の定義 (`constants/typography.dart`)

- [ ] `TextTheme`を定義し、以下の文字スタイルを規定する。
    
    - [ ] `displayLarge`, `displayMedium`, `displaySmall`
        
    - [ ] `headlineLarge`, `headlineMedium`, `headlineSmall`
        
    - [ ] `titleLarge`, `titleMedium`, `titleSmall` (例: カードのタイトル)
        
    - [ ] `bodyLarge`, `bodyMedium`, `bodySmall` (例: 投稿本文)
        
    - [ ] `labelLarge`, `labelMedium`, `labelSmall` (例: ボタンのテキスト)
        
- [ ] 上記`TextTheme`をテーマ(`ThemeData`)に統合する。
    

#### 3. 共通のレイアウト定数の定義 (`constants/sizes.dart`)

- [ ] アプリ全体で共通して使用するサイズ値を定数として定義する。
    
    - [ ] `p4`, `p8`, `p12`, `p16`, `p24`, `p32` (パディングやマージン用)
        
    - [ ] `radiusS`, `radiusM`, `radiusL` (角丸の半径)
        
    - [ ] `iconSizeS`, `iconSizeM`, `iconSizeL` (アイコンのサイズ)
        

#### 4. 共通ウィジェットの骨格作成 (`widgets/common/`)

- [ ] `PrimaryButton.dart`: 主要なアクションで使用するボタンの雛形を作成する。
    
- [ ] `SecondaryButton.dart`: 補助的なアクションで使用するボタンの雛形を作成する。
    
- [ ] `LoadingIndicator.dart`: `CircularProgressIndicator`を中央に表示する共通のローディングウィジェットを作成する。
    
- [ ] `ErrorDisplay.dart`: エラーメッセージを表示するための共通のエラーウィジェットを作成する。