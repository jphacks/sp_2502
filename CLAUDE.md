# CLAUDE.md

このファイルは、Claude Code (claude.ai/code) がこのリポジトリで作業する際のトップレベルガイダンスを提供します。

## プロジェクト概要

このプロジェクトは、カードスワイプ型のタスク管理アプリケーションです。iOSネイティブアプリとWebバックエンドAPIで構成され、音声入力によるタスク作成、AI画像生成、Auth0認証を特徴としています。

### 技術スタック全体像

**フロントエンド (iOS):**
- Swift 5.0 + SwiftUI
- MVVM + Services アーキテクチャ
- Auth0 認証（現在はスキップ中）
- tRPC + SuperJSON でバックエンドと通信
- ImagePlayground API (iOS 18.4+) による画像生成
- Speech Framework による音声認識
- 最小デプロイメントターゲット: iOS 18.0

**Web (フロントエンド + バックエンド):**
- Next.js 15 (App Router) + TypeScript 5.8
- React 19 + Chakra UI - フロントエンドUI
- tRPC 11 - 型安全なAPI（クライアント + サーバー）
- Auth0 (@auth0/nextjs-auth0 v4) - 認証機能
- Drizzle ORM + PostgreSQL - データベース
- 4層アーキテクチャ (Endpoint → Service → Repository → DTO)

## アーキテクチャ全体図

```
┌─────────────────────────────────────────────────────────────┐
│                     iOS アプリ (Swift)                        │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ View (SwiftUI)                                       │   │
│  │  - ContentView (カードスタック表示)                    │   │
│  │  - AuthView (Auth0認証)                              │   │
│  │  - CardView / TaskCardView                           │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ ViewModel (@Published)                               │   │
│  │  - CardViewModel (カード管理)                         │   │
│  │  - SpeechRecognizerViewModel (音声認識)              │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Services (シングルトン)                               │   │
│  │  - tRPCService (API通信) ─────────┐                 │   │
│  │  - ImageGeneratorService          │                 │   │
│  │  - TranslationService             │                 │   │
│  │  - EmojiSelectorService           │                 │   │
│  └───────────────────────────────────┼─────────────────┘   │
└────────────────────────────────────────┼─────────────────────┘
                                        │
                                        │ tRPC + SuperJSON
                                        │ Auth: Bearer Token
                                        │
┌────────────────────────────────────────┼─────────────────────┐
│        Web (Next.js App Router)        │                     │
│  ┌──────────────────────────────────────┼───────────────┐   │
│  │ フロントエンド (React 19 + Chakra UI) │               │   │
│  │  - app/page.tsx (ホームページ)                        │   │
│  │  - app/_components/ (UIコンポーネント)                │   │
│  │  - tRPCクライアント (型安全なAPI呼び出し)               │   │
│  └───────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────┼───────────────┐   │
│  │ API Routes                           │               │   │
│  │  /api/trpc (tRPCハンドラ) ←─────────┘               │   │
│  │  /auth/* (Auth0エンドポイント)                        │   │
│  └───────────────────────────────────────────────────────┘   │
│  ┌───────────────────────────────────────────────────────┐   │
│  │ tRPC Routers                                          │   │
│  │  - cardRouter (card.list, card.action)                │   │
│  │  - noteRouter (note.list)                             │   │
│  └───────────────────────────────────────────────────────┘   │
│  ┌───────────────────────────────────────────────────────┐   │
│  │ 4層アーキテクチャ                                       │   │
│  │  Endpoint → Service → Repository → DTO                │   │
│  │  (Result<T, AppError> パターン)                       │   │
│  └───────────────────────────────────────────────────────┘   │
│  ┌───────────────────────────────────────────────────────┐   │
│  │ Drizzle ORM + PostgreSQL                              │   │
│  │  - スキーマ: src/server/db/schema/                     │   │
│  │  - Docker: ポート5334                                  │   │
│  └───────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## ディレクトリ構造

```
sp_2502/
├── ios/                          # iOSネイティブアプリ
│   ├── CLAUDE.md                 # iOS詳細ガイド
│   ├── iosApp.swift              # エントリーポイント
│   ├── ContentView.swift         # メインView
│   ├── Models/                   # CardModel, UserModel
│   ├── ViewModels/               # CardViewModel, SpeechRecognizerViewModel
│   ├── Views/                    # AuthView, ProfileView, Card/*
│   ├── Services/                 # tRPCService, ImageGeneratorService等
│   └── Constants/                # CardConstants
├── web/                          # Webアプリケーション（フロントエンド + バックエンド）
│   ├── CLAUDE.md                 # Web詳細ガイド
│   ├── src/
│   │   ├── app/                  # Next.js App Router（フロントエンド）
│   │   │   ├── page.tsx          # ホームページ
│   │   │   ├── layout.tsx        # ルートレイアウト（Auth0Provider設定）
│   │   │   ├── _components/      # UIコンポーネント
│   │   │   └── api/trpc/         # tRPCハンドラ（バックエンドAPI）
│   │   ├── server/               # バックエンドロジック
│   │   │   ├── api/              # tRPCルーター
│   │   │   ├── auth/             # 認証ヘルパー
│   │   │   ├── db/schema/        # Drizzleスキーマ
│   │   │   ├── modules/          # ドメインモジュール（4層アーキテクチャ）
│   │   │   └── types/            # 共通型定義
│   │   ├── trpc/                 # tRPCクライアント設定
│   │   └── lib/                  # 共通ライブラリ
│   ├── package.json
│   └── docker-compose.yaml       # PostgreSQL設定
└── CLAUDE.md                     # このファイル（全体ガイド）
```

## API通信フロー

### tRPC + SuperJSON 通信

**iOS → Web**

1. **iOS側 (tRPCService.swift)**
   - ベースURL: `https://sp-2502.vercel.app/api/trpc`
   - 認証: `Authorization: Bearer {accessToken}` (KeychainHelperから取得)
   - リクエストフォーマット: `?input={"json":{...}}`
   - レスポンス: SuperJSON形式 → plain JSONに自動変換

2. **Web側 (tRPC Router)**
   - SuperJSON Transformer で Date、Map、Setなどを処理
   - protectedProcedure で認証チェック
   - 4層アーキテクチャで処理 (Endpoint → Service → Repository → DTO)
   - Result<T, AppError> パターンでエラーハンドリング

### 主要エンドポイント

| エンドポイント | メソッド | 用途 | iOS実装 |
|---|---|---|---|
| `/api/trpc/card.list` | GET | カード一覧取得 | `tRPCService.fetchCards()` |
| `/api/trpc/card.action` | POST | スワイプアクション送信 | `tRPCService.sendSwipeAction()` |
| `/api/trpc/note.list` | GET | ノート一覧取得 | (サンプル) |
| `/auth/login` | - | ログイン開始 | Auth0.webAuth() |
| `/auth/logout` | - | ログアウト | Auth0.webAuth().clearSession() |
| `/auth/callback` | - | OAuthコールバック | Auth0自動処理 |

## 認証フロー

### Auth0統合

**iOS側:**
- `AuthView`がエントリーポイント（現在は直接ContentViewを表示）
- アクセストークンは`KeychainHelper`で管理
- `tRPCService`がトークンをAPIリクエストヘッダーに付与

**Web側:**
- `@auth0/nextjs-auth0` v4 でセッション管理
- ミドルウェアが `/auth/*` エンドポイントを自動生成
- `protectedProcedure` でセッション検証
- `ctx.session.user.id` (user.sub) をユーザーIDとして使用

## 主要機能フロー

### 1. カード表示フロー

```
iOS: ContentView
  → CardViewModel.loadCards()
    → AppConfiguration (テストモード / APIモード)
      ├─ [テスト] MockDataProvider.getTestCards()
      └─ [API] tRPCService.fetchCards()
          → Web: /api/trpc/card.list
            → cardRouter
              → Service → Repository → PostgreSQL
                → SuperJSON レスポンス
  → iOS: カードスタック表示 (現在+次の2枚)
```

### 2. スワイプアクションフロー

```
iOS: ユーザーがカードスワイプ
  → SwipeableCardView (ジェスチャー検出)
    → CardViewModel.handleSwipe(direction:)
      → tRPCService.sendSwipeAction(cardId, action, token)
        → Web: /api/trpc/card.action
          → cardRouter
            → Service → Repository → PostgreSQL
              → 成功/失敗レスポンス
  → iOS: 次のカード表示 or 再読込
```

### 3. 音声入力タスク作成フロー

```
iOS: ユーザーがマイクボタン長押し
  → SpeechRecognizerViewModel.startRecording()
    → 音声認識開始
  → ユーザーがボタンを離す
    → 認識テキスト取得
      → CardViewModel.addTaskCard(taskText:)
        → EmojiSelectorService (絵文字選択)
        → TranslationService (日本語→英語翻訳)
        → ImageGeneratorService (画像生成)
          ├─ [iOS 18.4+] ImagePlayground API
          └─ [フォールバック] Core Graphics
        → 新しいCardをスタックに追加
  → iOS: タスクカード表示
```

## 開発コマンド

### iOS

```bash
# ディレクトリ移動
cd ios

# ビルド
xcodebuild -project ios.xcodeproj -scheme ios -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# クリーンビルド
xcodebuild -project ios.xcodeproj -scheme ios -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' clean build

# ビルドエラー確認
xcodebuild -project ios.xcodeproj -scheme ios -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build | \
  rg "(error:|warning:.*ImageGenerator|BUILD SUCCEEDED)"
```

### Web

```bash
# ディレクトリ移動
cd web

# 初期化（初回のみ）
pnpm run init
# 実行内容: pnpm i && docker compose up -d && pnpm db:push

# 開発サーバー起動
pnpm dev          # http://localhost:3304
pnpm dev:all      # 開発サーバー + Drizzle Studio

# ビルド
pnpm build        # プロダクションビルド
pnpm preview      # ビルド + プレビュー

# データベース
pnpm db:push      # スキーマ変更をプッシュ
pnpm db:studio    # Drizzle Studio GUI
pnpm db:generate  # マイグレーション生成
pnpm db:migrate   # マイグレーション適用

# コード品質（Hooksで自動実行）
pnpm typecheck    # TypeScript検証
pnpm lint         # ESLintチェック
pnpm lint:fix     # ESLint自動修正
pnpm format       # Prettierフォーマット
pnpm ci-check     # 総合チェック

# Docker
docker compose up -d     # PostgreSQL起動
docker compose down      # 停止
docker compose down -v   # 停止＆データ削除
```

## 重要な実装パターン

### iOS: モード切り替え

- `AppConfiguration.shared.currentMode` で `.test` / `.api` を切り替え
- テストモード: ローカルモックデータを使用
- APIモード: Web バックエンドと通信

### Web: 4層アーキテクチャ

```
Endpoint (endpoint.trpc.ts)
  ↓ protectedProcedure で認証
  ↓ Result<T, AppError> → TRPCError 変換
Service (service.ts)
  ↓ ビジネスロジック
  ↓ トランザクション管理
Repository (_repo.ts)
  ↓ データベースアクセス
  ↓ Drizzle ORM
DTO (_dto.ts)
  ↓ データ変換
PostgreSQL
```

### エラーハンドリング

**iOS:**
- `tRPCError` enum で分類
- `errorMessage` に格納してUI表示
- 画像生成失敗時はCore Graphicsフォールバック

**Web:**
- `Result<T, AppError>` パターン
- リポジトリでthrowしない
- サービスで `.safeParse()` 検証
- エンドポイントで `toTrpcError()` 変換

## 環境変数

### iOS

- **Auth0設定**: Info.plist に設定（現在は認証スキップ中）
- **APIベースURL**: `https://sp-2502.vercel.app/api/trpc`

### Web (.env)

**Auth0関連:**
```bash
AUTH0_SECRET=<openssl rand -base64 32>
AUTH0_BASE_URL=http://localhost:3304
AUTH0_ISSUER_BASE_URL=https://your-tenant.auth0.com
AUTH0_CLIENT_ID=<Auth0 Application ID>
AUTH0_CLIENT_SECRET=<Auth0 Application Secret>
```

**データベース関連:**
```bash
POSTGRES_HOST=localhost
POSTGRES_PORT=5334
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=database
DATABASE_URL=postgresql://postgres:postgres@localhost:5334/database
```

## 技術的な注意点

### iOS

1. **ImagePlayground API**: iOS 18.4+ のみ、シミュレーターでは動作しない可能性
2. **Translation API**: iOS 18.0+ のみ、初回使用時にモデルダウンロードが必要
3. **音声認識**: Info.plist に権限説明文が必須
4. **認証フロー**: 現在はコメントアウトされている（`AuthView.swift:13-20`）
5. **RESTful API は使用しない**: tRPCサーバーのみ使用

### Web

1. **Claude Code Hooks**: ファイル編集時に自動でtypecheck + lint + format実行
2. **usecase-maker Agent**: 新規APIエンドポイント作成時に活用
3. **SuperJSON Transformer**: Date、Map、Setなどを自動処理
4. **Timing Middleware**: 開発環境で100-500msの人工的遅延
5. **アロー関数のみ**: `function` 宣言は禁止（ESLintルール）

## ブランチ戦略

- **メインブランチ**: `main`
- **現在のブランチ**: `famisics/#15/improve-swift`
- PRは `main` ブランチに対して作成

## 詳細ガイド

- **iOS詳細**: `ios/CLAUDE.md` を参照
- **Web詳細**: `web/CLAUDE.md` を参照

## 開発時の基本方針

1. **型安全性**: iOS (Swift型) ↔ Web (TypeScript型) でエンドツーエンドの型安全性を維持
2. **エラーハンドリング**: 両プラットフォームで明示的なエラー処理
3. **認証**: Auth0による統一認証（現在はiOS側で一時的にスキップ）
4. **API通信**: tRPC + SuperJSONのみ使用（RESTful APIは使用しない）
5. **コード品質**: iOS (xcodebuild) / Web (typecheck + lint + format) で検証
