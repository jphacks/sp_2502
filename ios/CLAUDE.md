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
├── Models/
│   ├── CardModel.swift                   # カードデータモデル
│   └── UserModel.swift                   # ユーザーモデル
├── ViewModels/
│   ├── CardViewModel.swift               # カード管理・ビジネスロジック
│   └── SpeechRecognizerViewModel.swift   # 音声認識・音声入力管理
├── Views/
│   ├── AuthView.swift                    # Auth0認証UI
│   ├── CardView.swift                    # カード表示UI
│   ├── SwipeableCardView.swift           # スワイプジェスチャー処理
│   └── ProfileView.swift                 # ユーザープロフィール
├── Services/
│   ├── APIService.swift                  # API通信層
│   ├── ImageGeneratorService.swift       # 画像生成（ImagePlayground/CoreGraphics）
│   ├── EmojiSelectorService.swift        # 絵文字選択ロジック
│   └── MockDataProvider.swift            # テストデータ提供
└── Assets.xcassets/                       # 画像・アイコンアセット
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

### ビルドエラーと警告の確認

```bash
xcodebuild -project ios.xcodeproj -scheme ios -configuration Debug -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build | rg -E "(error:|warning:.*ImageGenerator|BUILD SUCCEEDED)"
```

## 技術スタック

- **言語**: Swift 5.0
- **UIフレームワーク**: SwiftUI
- **非同期処理**: async/await
- **リアクティブ**: Combine
- **ネットワーク**: URLSession (標準ライブラリ)
- **最小デプロイメントターゲット**: iOS 18.0
- **外部依存**:
  - Auth0.swift (SPM): 認証機能（バージョン 2.15.1+）
- **システム機能**:
  - ImagePlayground API (iOS 18.4+): AI画像生成
  - Speech Framework: 音声認識
  - Core Graphics: フォールバック画像生成

## 重要な実装パターン

### モード切り替え（`AppConfiguration`）

- **テストモード** (`.test`): `MockDataProvider` からローカルデータを取得
- **APIモード** (`.api`): `APIService` 経由でバックエンドAPIと通信
- `AppConfiguration.shared.currentMode` で切り替え（`CardViewModel` が参照）

### API通信（`APIService`）

- **ベースURL**: `http://localhost:3304/api` (開発環境)
- **エンドポイント**:
  - `GET /api/cards` - カード一覧取得
  - `POST /api/cards/{cardId}/action` - スワイプアクション送信（body: `{"action": "delete"|"like"|"skip"}`）
- **エラーハンドリング**: `APIError` enum で分類（invalidURL/networkError/decodingError/serverError）
- 本番環境では `baseURL` を環境変数化すること

### 認証（Auth0）

- `AuthView` がアプリのエントリーポイント（`iosApp.swift` で参照）
- Web認証フロー: `Auth0.webAuth().useHTTPS().start()`
- ログアウト: `Auth0.webAuth().useHTTPS().clearSession()`
- IDトークンから `User` モデルを生成
- **現在は認証フローがコメントアウトされ、直接 `ContentView` を表示**（`AuthView.swift:13-20`）

### 音声認識（`SpeechRecognizerViewModel`）

- **権限**: マイク使用権限 (`NSMicrophoneUsageDescription`) と音声認識権限 (`NSSpeechRecognitionUsageDescription`) が必要
- **タップ&ホールド**: マイクボタンを長押しで録音開始、離すと停止
- **コールバック**: `onRecognitionCompleted` で認識テキストを `CardViewModel` に渡す
- **エラーハンドリング**: 権限拒否時は設定画面へのリンクを表示

### 画像生成（`ImageGeneratorService`）

- **iOS 18.4+**: ImagePlayground API (`ImageCreator`) を使用
  - スタイル: `.illustration`, `.sketch`, `.animation` をタスク内容に応じて選択
  - プロンプト生成: タスクテキストからキーワード抽出してプロンプトを構築
- **フォールバック**: Core Graphics で装飾的なグラデーション画像を生成
  - タスク内容に応じた色・装飾（数学記号、音符、グラフなど）
- **キャッシュ**: 画像は `cachesDirectory` に保存（`task_{UUID}.png`）

### 状態管理（`CardViewModel`）

- `@Published` プロパティ: `currentCard`, `isLoading`, `isGeneratingCard`, `errorMessage`
- すべての非同期メソッドに `@MainActor` を付与してUI更新の安全性を確保
- タスクカード追加: `addTaskCard(taskText:)` → 絵文字選択 → 画像生成 → カードスタックに挿入

### スワイプ機能（`SwipeableCardView`）

- **方向**: 上（Delete）、下（Skip）、左（Undo）、右（Like）
- **閾値**: 100pt
- **アニメーション**: `.spring()` で追従、`.easeOut(duration: 0.3)` で完了
- **進行度コールバック**: `onSwipeProgress` で背後のカードのスケール/オフセットを調整
- **Undo機能**: `swipeHistory` 配列で履歴管理、最後のアクションを復元可能

### ファイル命名規則

- View: `*View.swift`
- ViewModel: `*ViewModel.swift`
- Model: `*Model.swift`
- Service: `*Service.swift`

## データフロー

### カード表示フロー

1. `iosApp` → `AuthView` → `ContentView`（認証フローは現在スキップ）
2. `ContentView` が `CardViewModel` と `SpeechRecognizerViewModel` を `@StateObject` として所有
3. `CardViewModel.loadCards()` が `AppConfiguration` に応じてデータ取得:
   - テストモード: `MockDataProvider.getTestCards()`
   - APIモード: `APIService.shared.fetchCards()`
4. カードスタック表示: 現在のカード + 次の2枚をZStackで重ねて表示
5. ユーザーがスワイプ → `SwipeableCardView` がジェスチャー検出
6. `CardViewModel.handleSwipe(direction:)` がアクションを処理:
   - APIモードの場合: `APIService` にアクション送信
   - `swipeHistory` に記録
   - 次カード表示 or 再読込
7. Undo時は `swipeHistory` から復元

### 音声入力フロー

1. ユーザーがマイクボタンを長押し
2. `SpeechRecognizerViewModel.startRecording()` が権限確認 → 音声認識開始
3. ユーザーがボタンを離す → `stopRecording()` で認識停止
4. `onRecognitionCompleted` コールバックで認識テキストを取得
5. `CardViewModel.addTaskCard(taskText:)` が呼ばれる:
   - `EmojiSelectorService` でタスクに合った絵文字を選択
   - `ImageGeneratorService` で画像生成（ImagePlayground API → フォールバック）
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

### 音声認識

- 初回起動時に権限リクエストが表示される
- `Info.plist` に権限説明文が必須（`NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription`）
- 権限拒否時は設定アプリへのリンクを提供

### エラー処理

- ネットワークエラーは `errorMessage` に格納し、UI に Retry ボタンを表示
- デコードエラーは `APIError.decodingError` でキャッチし、モデル定義を確認
- 画像生成失敗時は必ずフォールバックを実行

### パフォーマンス

- `AsyncImage` は自動的に画像をキャッシュ
- カードが空になると自動的に `loadCards()` を再実行
- タスク画像は `cachesDirectory` に保存され、アプリ再起動後も利用可能

### コーディング規約

- `@MainActor` は UI 更新を行うメソッド・クラスに必須
- `@Published` は View が監視するプロパティのみ使用
- async/await を使用し、completion handler は避ける
- シングルトンサービスは `static let shared` パターンを使用

## ブランチ戦略

- **メインブランチ**: `main`
- PR は `main` ブランチに対して作成
- 現在のブランチ: `famisics/ios/card`（カードView実装用）
