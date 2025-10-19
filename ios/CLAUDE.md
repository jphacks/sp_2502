# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

このiOSプロジェクトは、カードスワイプ機能と音声入力によるタスク追加機能を持つSwiftUIアプリケーションです。MVVM + Servicesアーキテクチャを採用し、Auth0による認証、ImagePlayground APIによる画像生成、音声認識機能を統合しています。

## アーキテクチャ

### ディレクトリ構造

```
ios/
├── iosApp.swift                          # アプリエントリーポイント
├── ContentView.swift                      # メインView（カードスタック表示）
├── AppConfiguration.swift                 # テストモード/APIモード切り替え
├── Constants/
│   └── CardConstants.swift               # カード関連定数（レイアウト/色/影/スワイプ設定）
├── Helper/
│   └── KeychainHelper.swift              # Keychainラッパー（アクセストークン管理）
├── Models/
│   ├── CardModel.swift                   # カードデータモデル
│   └── UserModel.swift                   # ユーザーモデル
├── ViewModels/
│   ├── CardViewModel.swift               # カード管理・ビジネスロジック
│   └── SpeechRecognizerViewModel.swift   # 音声認識・音声入力管理
├── Views/
│   ├── AuthView.swift                    # Auth0認証UI
│   ├── ProfileView.swift                 # ユーザープロフィール
│   └── Card/
│       ├── CardView.swift                # 通常カード表示UI
│       ├── TaskCardView.swift            # タスクカード表示UI
│       └── SwipeableCardView.swift       # スワイプジェスチャー処理
├── Services/
│   ├── tRPCService.swift                 # tRPC/SuperJSON対応API通信層
│   ├── ImageGeneratorService.swift       # 画像生成（ImagePlayground/CoreGraphics）
│   ├── TranslationService.swift          # 翻訳サービス（Translation API/辞書ベース）
│   ├── EmojiSelectorService.swift        # 絵文字選択ロジック
│   └── MockDataProvider.swift            # テストデータ提供
└── Assets.xcassets/                       # 画像・アイコンアセット
ios.xcodeproj/                            # Xcodeプロジェクトファイル
```

### MVVM パターン

- **Model**: `Card`, `CardResponse`, `SwipeDirection`, `User` の定義。`Codable` 対応
- **View**: SwiftUIベースのUI実装。認証、カードスワイプ、音声入力UIを提供
- **ViewModel**: `@Published` プロパティで状態管理、`@MainActor` でUI更新を保証
- **Service**: シングルトンパターンで各機能を集約（API通信、画像生成、音声認識）

## 開発コマンド

### ビルド

```bash
xcodebuild -project ios.xcodeproj -scheme ios -configuration Debug -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

作業終了前に必ず上記のコマンドでビルドし、動作を確認してください。

### クリーンビルド

```bash
xcodebuild -project ios.xcodeproj -scheme ios -configuration Debug -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' clean build
```

ビルドの不整合が発生した場合は、クリーンビルドを実行してください。

### ビルドエラーと警告の確認

```bash
xcodebuild -project ios.xcodeproj -scheme ios -configuration Debug -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build | rg "(error:|warning:.*ImageGenerator|BUILD SUCCEEDED)"
```

## 技術スタック

- **言語**: Swift 5.0
- **UIフレームワーク**: SwiftUI
- **非同期処理**: async/await
- **リアクティブ**: Combine
- **ネットワーク**: URLSession (標準ライブラリ)
- **API通信**: tRPC + SuperJSON形式
- **最小デプロイメントターゲット**: iOS 18.0
- **外部依存**:
  - Auth0.swift (SPM): 認証機能（バージョン 2.15.1+）
- **システム機能**:
  - ImagePlayground API (iOS 18.4+): AI画像生成
  - Translation Framework (iOS 18.0+): オンデバイス翻訳
  - Speech Framework: 音声認識
  - Core Graphics: フォールバック画像生成
  - Keychain Services: セキュアなトークン保存

## 重要な実装パターン

### モード切り替え（`AppConfiguration`）

- **テストモード** (`.test`): `MockDataProvider` からローカルデータを取得
- **APIモード** (`.api`): `tRPCService` 経由でバックエンドAPIと通信
- `AppConfiguration.shared.currentMode` で切り替え（`CardViewModel` が参照）

### API通信（`tRPCService`）

**tRPCService（tRPC/SuperJSON対応）**:
- **ベースURL**: `https://sp-2502.vercel.app/api/trpc`
- **エンドポイント**:
  - `GET /api/trpc/card.list` - カード一覧取得
  - `POST /api/trpc/card.action` - スワイプアクション送信（input: `{"cardId": "...", "action": "delete"|"like"|"cut"}`）
  - `GET /api/trpc/note.list` - ノート一覧取得（サンプル）
- SuperJSONレスポンスをplain JSONに変換してデコード
  - `superJSONToPlainJSONData()` でネストされた `result.data.json` 構造を展開
  - `decodeFromSuperJSON<T>()` で型安全にデコード
- **認証**: `Authorization: Bearer {accessToken}` ヘッダーを使用
  - アクセストークンは `KeychainHelper` から取得
  - 未認証の場合は `nil` を渡す（オプショナル）
- **エラーハンドリング**: `tRPCError` enum で分類（invalidURL/invalidResponse/networkError/decodingError/serverError）
- **リクエストフォーマット**:
  - GETリクエスト: クエリパラメータ `input` に JSON エンコードされたオブジェクトを渡す
  - 例: `?input={"json":{}}`
- **レスポンスフォーマット**: SuperJSON形式 → plain JSONに自動変換

### 認証（Auth0 + Keychain）

**Auth0統合**:
- `AuthView` がアプリのエントリーポイント（`iosApp.swift` で参照）
- Web認証フロー: `Auth0.webAuth().useHTTPS().start()`
- ログアウト: `Auth0.webAuth().useHTTPS().clearSession()`
- IDトークンから `User` モデルを生成
- **現在は認証フローがコメントアウトされ、直接 `ContentView` を表示**（`AuthView.swift:13-20`）

**KeychainHelper**:
- アクセストークンの安全な保存・取得・削除を提供
- `saveAccessToken(_:)`: トークンを Keychain に保存
- `getAccessToken()`: トークンを Keychain から取得
- `deleteAccessToken()`: トークンを削除（ログアウト時に使用）
- シングルトンパターン（`KeychainHelper.shared`）
- Service ID は Bundle ID をデフォルト使用

### 音声認識（`SpeechRecognizerViewModel`）

- **権限**: マイク使用権限 (`NSMicrophoneUsageDescription`) と音声認識権限 (`NSSpeechRecognitionUsageDescription`) が必要
- **タップ&ホールド**: マイクボタンを長押しで録音開始、離すと停止
- **コールバック**: `onRecognitionCompleted` で認識テキストを `CardViewModel` に渡す
- **エラーハンドリング**: 権限拒否時は設定画面へのリンクを表示

### 画像生成（`ImageGeneratorService`）

- **iOS 18.4+**: ImagePlayground API (`ImageCreator`) を使用
  - スタイル: `.illustration`, `.sketch`, `.animation` をタスク内容に応じて選択
  - プロンプト生成: タスクテキストからキーワード抽出してプロンプトを構築
  - `TranslationService` を使用して日本語タスクを英語に翻訳してからプロンプト生成
- **フォールバック**: Core Graphics で装飾的なグラデーション画像を生成
  - タスク内容に応じた色・装飾（数学記号、音符、グラフなど）
- **キャッシュ**: 画像は `cachesDirectory` に保存（`task_{UUID}.png`）

### 翻訳（`TranslationService`）

- **iOS 18.0+**: Translation フレームワークでオンデバイス翻訳
  - `translateToEnglish(japaneseText:)` async メソッドで日本語→英語翻訳
  - `LanguageAvailability` で翻訳モデルのインストール状態を確認（`.installed` が必要）
  - `TranslationSession` でプログラマティックに翻訳（UIなし）
- **フォールバック**: 辞書ベースの簡易翻訳
  - `basicTranslateToEnglish()` で90以上のキーワードマッピング
  - 学習、仕事、運動、食事、音楽、健康など幅広いカテゴリをカバー
- **出力フォーマット**: 英字とスペースのみに制限（`removeNonEnglishCharacters()`）
- ImagePlayground API のプロンプト生成で使用

### 状態管理（`CardViewModel`）

- `@Published` プロパティ: `currentCard`, `isLoading`, `isGeneratingCard`, `errorMessage`
- すべての非同期メソッドに `@MainActor` を付与してUI更新の安全性を確保
- タスクカード追加: `addTaskCard(taskText:)` → 絵文字選択 → 画像生成 → カードスタックに挿入

### スワイプ機能（`SwipeableCardView`）

- **方向**: 上（Delete）、左（Undo）、右（Like）、cut（Cut）
  - 上スワイプ: タスク削除
  - 右スワイプ: いいね
  - 左スワイプ: 直前のアクションを取り消し
  - Cutボタン: カット操作（左下のボタンから実行）
- **閾値**: 100pt
- **アニメーション**: `.spring()` で追従、`.easeOut(duration: 0.3)` で完了
- **進行度コールバック**: `onSwipeProgress` で背後のカードのスケール/オフセットを調整
- **Undo機能**: `swipeHistory` 配列で履歴管理、最後のアクションを復元可能

### ファイル命名規則

- View: `*View.swift`
- ViewModel: `*ViewModel.swift`
- Model: `*Model.swift`
- Service: `*Service.swift`
- Helper: `*Helper.swift`
- Constants: `*Constants.swift`

### UI構造の分離

- **CardView**: 通常のAPIから取得したカード表示（画像URL、タイトル、説明を表示）
- **TaskCardView**: 音声入力で作成したタスクカード専用（ローカル画像パス、絵文字を表示）
  - `loadImageFromPath()` でキャッシュされた画像をファイルシステムから読み込む
  - 背景色は `CardConstants.Colors.taskCardBackground`
- **SwipeableCardView**: 上記2種類のカードを包含し、スワイプジェスチャーを処理

### 定数管理（`CardConstants`）

UI関連の値を一元管理:
- **Layout**: アスペクト比、角丸、パディング、フレームサイズ
- **Colors**: グラデーション定義（外側カード、内側カード、ゴールドフレーム、テキストオーバーレイ）
- **Shadow**: 影の設定（色、半径、オフセット）
- **Typography**: フォントサイズ、ウェイト、色
- **Swipe**: スワイプ閾値、回転係数、アニメーション時間、方向別の設定（色、アイコン、テキスト）

## データフロー

### カード表示フロー

1. `iosApp` → `AuthView` → `ContentView`（認証フローは現在スキップ）
2. `ContentView` が `CardViewModel` と `SpeechRecognizerViewModel` を `@StateObject` として所有
3. `CardViewModel.loadCards()` が `AppConfiguration` に応じてデータ取得:
   - テストモード: `MockDataProvider.getTestCards()`
   - APIモード: `tRPCService.fetchCards(accessToken:)` でtRPCサーバーから取得
     - アクセストークンは `KeychainHelper.getAccessToken()` から取得
4. カードスタック表示: 現在のカード + 次の2枚をZStackで重ねて表示
5. ユーザーがスワイプ → `SwipeableCardView` がジェスチャー検出
6. `CardViewModel.handleSwipe(direction:)` がアクションを処理:
   - APIモードの場合: `tRPCService.sendSwipeAction(cardId:action:accessToken:)` にアクション送信
   - 次カード表示 or 再読込
7. カードが空になると自動的に `loadCards()` を再実行

### 音声入力フロー

1. ユーザーがマイクボタンを長押し
2. `SpeechRecognizerViewModel.startRecording()` が権限確認 → 音声認識開始
3. ユーザーがボタンを離す → `stopRecording()` で認識停止
4. `onRecognitionCompleted` コールバックで認識テキストを取得
5. `CardViewModel.addTaskCard(taskText:)` が呼ばれる:
   - `EmojiSelectorService` でタスクに合った絵文字を選択
   - `TranslationService` で日本語タスクを英語に翻訳（iOS 18+ Translation API → 辞書ベース）
   - `ImageGeneratorService` で翻訳後のテキストから画像生成（ImagePlayground API → Core Graphics フォールバック）
   - 新しい `Card` を作成してカードスタックの先頭に挿入

## Xcodeプロジェクト設定

- **ファイル管理**: `PBXFileSystemSynchronizedRootGroup` 採用（ファイルシステム変更を自動検出）
- **ビルドフェーズ**: Sources → Frameworks → Resources
- **ビルド構成**: Debug / Release
- **SPMパッケージ**: Auth0.swift (2.15.1+)
- **Bundle ID**: `net.uiro.taskne.ios.famisics`
- **Development Team**: XTG6342868
- プロジェクトファイル手動編集は不要（Xcodeが自動管理）

## 開発時の注意点

### ImagePlayground API

- iOS 18.4+ でのみ利用可能
- デバイスがサポートしていない場合、`ImageCreator.Error.notSupported` エラーが発生
- 必ずフォールバック処理（Core Graphics）を用意すること
- シミュレーターでは動作しない可能性があるため、実機テスト推奨

### Translation API

- iOS 18.0+ で利用可能（`canImport(Translation)` で判定）
- 初回使用時に翻訳モデルのダウンロードが必要な場合がある
- `LanguageAvailability.status(from:to:)` で `.installed` を確認
- モデル未インストール時は辞書ベース翻訳にフォールバック
- 出力は必ず英字とスペースのみに制限（ImagePlayground API の制約対応）

### 音声認識

- 初回起動時に権限リクエストが表示される
- `Info.plist` に権限説明文が必須（`NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription`）
- 権限拒否時は設定アプリへのリンクを提供

### エラー処理

- ネットワークエラーは `errorMessage` に格納し、UI に Retry ボタンを表示
- デコードエラーは `tRPCError.decodingError` でキャッチし、モデル定義を確認
- SuperJSON変換エラーは `superJSONToPlainJSONData()` 内で処理
- 画像生成失敗時は必ずフォールバックを実行
- 認証エラー（401）時は `KeychainHelper` でトークンを確認

### パフォーマンス

- `AsyncImage` は自動的に画像をキャッシュ
- カードが空になると自動的に `loadCards()` を再実行
- タスク画像は `cachesDirectory` に保存され、アプリ再起動後も利用可能

### コーディング規約

- `@MainActor` は UI 更新を行うメソッド・クラスに必須
- `@Published` は View が監視するプロパティのみ使用
- async/await を使用し、completion handler は避ける
- シングルトンサービスは `static let shared` パターンを使用
- UI定数は `CardConstants` に集約（ハードコーディングを避ける）
- セキュアな情報は `KeychainHelper` を使用（UserDefaults は非推奨）

## UI実装の詳細

### Figmaベースデザイン

- **背景色**: RGB(146, 0, 0) - 赤系統のブランドカラー
- **カードサイズ**: 画面幅の90%、画面高さの70%
- **カードスタック**: 現在のカード + 次の2枚を重ねて表示
  - 背後のカードは opacity 0.5〜0.35、scale 0.95〜0.90
  - スワイプ進行度に応じて背後カードが前面に移動（スケール・オフセット調整）
- **装飾要素**: 左上・右下に回転したカードを背景装飾として配置
- **アクションボタン**:
  - Delete（右上）: 赤色、ゴミ箱アイコン
  - Cut（左下）: オレンジ色、はさみアイコン
  - Like（右下）: 緑色、サムズアップアイコン
  - マイク（下部中央）: 録音中は赤色に変化、1.2倍にスケール

### 状態表示

- **ローディング**: `ProgressView` + "Loading cards..." テキスト
- **カード生成中**: `ProgressView` + "カードを生成中..." テキスト
- **エラー**: 警告アイコン + エラーメッセージ + Retryボタン
- **カード不在**: "No more cards" メッセージ（自動リロード発動）

## ブランチ戦略

- **メインブランチ**: `main`
- PR は `main` ブランチに対して作成
- RESTful API は使わず、 tRPCサーバーのみを使います。\
該当する RESTful API へのリクエスト部分も削除し、 tRPC のリクエストを使うようにしてください。