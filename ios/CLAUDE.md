# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

このiOSプロジェクトは、カードスワイプ機能を持つSwiftUIアプリケーションです。MVVM + Servicesアーキテクチャを採用しており、外部ライブラリ依存がないシンプルな構成です。

## アーキテクチャ

### ディレクトリ構造

```
ios/
├── iosApp.swift              # アプリエントリーポイント
├── ContentView.swift          # メインView
├── Models/
│   └── CardModel.swift        # データモデル定義
├── ViewModels/
│   └── CardViewModel.swift    # ビジネスロジック・状態管理
├── Views/
│   ├── CardView.swift         # カード表示UI
│   └── SwipeableCardView.swift # スワイプ操作処理
├── Services/
│   └── APIService.swift       # API通信層
└── Assets.xcassets/           # 画像・アイコンアセット
```

### MVVM パターン

- **Model** (`CardModel.swift`): `Card`, `CardResponse`, `SwipeDirection` の定義。すべて `Codable` 対応
- **View** (`ContentView.swift`, `CardView.swift`, `SwipeableCardView.swift`): SwiftUIベースのUI実装
- **ViewModel** (`CardViewModel.swift`): `@Published` プロパティで状態管理、`@MainActor` でUI更新を保証
- **Service** (`APIService.swift`): シングルトンパターンでAPI通信を集約

## 開発コマンド

### ビルド

```bash
# デバッグビルド
xcodebuild -project ios.xcodeproj -scheme ios -configuration Debug build

# リリースビルド
xcodebuild -project ios.xcodeproj -scheme ios -configuration Release build
```

### 実行

```bash
# シミュレータで実行（iPhone 16 Pro の例）
xcodebuild -project ios.xcodeproj -scheme ios -destination 'platform=iOS Simulator,name=iPhone 16 Pro' run
```

または Xcode で開いて `Cmd+R` で実行。

### テスト

```bash
# 全テスト実行
xcodebuild test -project ios.xcodeproj -scheme ios -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

現在テストターゲットは未設定のため、テスト追加時は XCTest フレームワークを使用してください。

### クリーン

```bash
xcodebuild clean -project ios.xcodeproj -scheme ios
```

## 技術スタック

- **言語**: Swift 5.0
- **UIフレームワーク**: SwiftUI
- **非同期処理**: async/await
- **リアクティブ**: Combine
- **ネットワーク**: URLSession (標準ライブラリ)
- **最小デプロイメントターゲット**: iOS 26.0
- **外部依存**: なし（SPM/CocoaPods不使用）

## 重要な実装パターン

### API通信

- **ベースURL**: `http://localhost:3304/api` (開発環境)
- **エンドポイント**:
  - `GET /api/cards` - カード一覧取得
  - `POST /api/cards/{cardId}/action` - スワイプアクション送信（body: `{"action": "delete"|"like"|"skip"}`）
- **エラーハンドリング**: `APIError` enum で分類（invalidURL/networkError/decodingError/serverError）
- 本番環境では `APIService` の `baseURL` を環境変数化すること

### 状態管理

- `CardViewModel` が `ObservableObject` として機能
- `@Published` プロパティ: `currentCard`, `isLoading`, `errorMessage`
- すべての非同期メソッドに `@MainActor` を付与してUI更新の安全性を確保

### スワイプ機能

- **方向**: 上（Delete）、下（Skip）、左（Undo）、右（Like）
- **閾値**: 100pt
- **アニメーション**: `.spring()` で追従、`.easeOut(duration: 0.3)` で完了
- **Undo機能**: `swipeHistory` 配列で履歴管理、最後のアクションを復元可能

### ファイル命名規則

- View: `*View.swift`
- ViewModel: `*ViewModel.swift`
- Model: `*Model.swift`
- Service: `*Service.swift`

## データフロー

1. `ContentView` が `CardViewModel` を `@StateObject` として所有
2. `CardViewModel.loadCards()` が `APIService` 経由でカード取得
3. ユーザーがスワイプ → `SwipeableCardView` がジェスチャー検出
4. `CardViewModel.handleSwipe(direction:)` がアクションを処理:
   - API にアクション送信
   - `swipeHistory` に記録
   - 次カード表示 or 再読込
5. Undo時は `swipeHistory` から復元

## Xcodeプロジェクト設定

- **ファイル管理**: `PBXFileSystemSynchronizedRootGroup` 採用（ファイルシステム変更を自動検出）
- **ビルドフェーズ**: Sources → Frameworks → Resources
- **ビルド構成**: Debug / Release
- プロジェクトファイル手動編集は不要（Xcodeが自動管理）

## 開発時の注意点

### エラー処理
- ネットワークエラーは `errorMessage` に格納し、UI に Retry ボタンを表示
- デコードエラーは `APIError.decodingError` でキャッチし、モデル定義を確認

### パフォーマンス
- `AsyncImage` は自動的に画像をキャッシュ
- カードが空になると自動的に `loadCards()` を再実行

### コーディング規約
- `@MainActor` は UI 更新を行うメソッド・クラスに必須
- `@Published` は View が監視するプロパティのみ使用
- async/await を使用し、completion handler は避ける

## ブランチ戦略

- **メインブランチ**: `main`
- PR は `main` ブランチに対して作成
- 現在のブランチ: `famisics/ios/card`（カードView実装用）
