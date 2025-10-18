# CLAUDE.md

このファイルは、Claude CodeがこのT3 Stackテンプレートリポジトリで作業する際の技術ガイダンスを提供します。

# Top-level Guidelines for Claude Code

- **All file writes must use UTF-8 encoding with LF (Unix-style) line endings, not Shift-JIS**.
- You must **think exclusively in English**. However, you must need to **respond in Japanese**.
- To maximize efficiency, if you need to execute multiple independent processes, invoke those tools concurrently, not sequentially.
- **Do not use emojis in any documentation, code comments, or commit messages unless explicitly requested by the user**.

---

## プロジェクト概要

以下の技術で構築されたフルスタックTypeScriptアプリケーションテンプレート：

- **Next.js 15** (App Router)
- **TypeScript 5.8**
- **tRPC 11** - 型安全なAPI
- **NextAuth.js v5** (Auth.js) - 認証機能
- **Drizzle ORM** - PostgreSQL対応
- **Chakra UI** - スタイリング
- **React 19** - React Query対応
- **ESLint 9** + **Prettier** - コード品質管理

---

## クイックスタート

### 前提条件

- **Node.js** 18.17以上
- **pnpm** 10.12.1
- **Docker Desktop**（PostgreSQL用）

### セットアップ手順

```bash
# 1. リポジトリのクローン
git clone <repository-url>
cd t3-app-template

# 2. 環境変数の設定
cp .env.example .env
# .envファイルを必要な値で編集

# 3. プロジェクトの初期化（ワンコマンド）
pnpm run init
# 実行内容：pnpm i && docker compose up -d && pnpm db:push

# 4. 開発サーバーの起動
pnpm dev
# サーバーは http://localhost:3304 で起動
```

### よく使うコマンド

#### 開発

```bash
pnpm dev          # 開発サーバー起動（ポート3304）
pnpm dev:all      # 開発サーバー + Drizzle Studio
pnpm build        # プロダクションビルド
pnpm preview      # ビルド + プレビュー起動
```

#### データベース

```bash
pnpm db:push      # スキーマ変更をプッシュ（開発用）
pnpm db:studio    # Drizzle Studio GUIを開く
pnpm db:generate  # マイグレーションファイル生成
pnpm db:migrate   # マイグレーション適用
```

#### コード品質

```bash
pnpm typecheck    # TypeScript検証
pnpm lint         # ESLintチェック
pnpm lint:fix     # ESLint自動修正
pnpm format       # Prettierフォーマット
pnpm ci-check     # 総合チェック（typecheck + lint + format）
```

#### Docker操作

```bash
docker compose up -d     # PostgreSQL起動
docker compose down      # 停止（データ保持）
docker compose down -v   # 停止してデータ削除
docker compose logs -f   # ログ表示
```

---

## 開発ガイドライン

### 新機能の追加フロー

1. `src/server/db/schema/`でデータベーススキーマを定義
2. `pnpm db:push`でデータベースを更新
3. モジュール構造を作成：`src/server/modules/{domain}/`
4. 以下の順序で実装：
   - `_dto.ts` - データ構造
   - `_repo.ts` - データベース操作
   - `{action}/contract.ts` - I/Oスキーマ
   - `{action}/service.ts` - ビジネスロジック
   - `{action}/endpoint.trpc.ts` - APIエンドポイント
5. `src/server/api/root.ts`にルーターを登録

### コーディング規約

#### 関数宣言スタイル

**アロー関数のみ**（ルールで強制）：

```typescript
// ❌ 禁止
function foo() {}
export function bar() {}

// ✅ 必須
const foo = () => {};
export const bar = () => {};
```

#### インポート規約

- 絶対インポートには`@/`エイリアスを使用
- インポートのグループ化：外部 → 内部 → 相対
- サーバー専用インポートは`server-only`パッケージを使用

#### エラーハンドリングのベストプラクティス

1. **リポジトリでthrowしない** - `Result<T, AppError>`を返す
2. **サービスで検証** - `.parse()`ではなく`.safeParse()`を使用
3. **エンドポイントで変換** - `AppError`を`TRPCError`に変換
4. **トランザクションスコープ** - リポジトリではなくサービス層でラップ

### Claude Agents

このプロジェクトには`.claude/agents/`にClaude Agent設定が含まれています：

#### usecase-maker Agent

バックエンドユースケースをスキャフォールディングする専用エージェント。プロジェクトの規約に従って3つのファイル（contract.ts、service.ts、endpoint.trpc.ts）の作成を自動化します。

**使用方法**：新しいAPIエンドポイントを実装する際に積極的に呼び出してください。

**機能**：

- 適切な4層アーキテクチャを作成
- Result型パターンに従う
- トランザクション処理の実装
- 適切な認証設定
- プロジェクトのリンターで検証

### Claude Code Hooks

このプロジェクトでは、Claude Codeのファイル編集時に自動でコード品質チェックを実行するhooksが設定されています。

#### 自動実行される処理

WriteまたはEditツールを使用してファイルを編集すると、以下の処理が自動実行されます：

1. **TypeScript型チェック** (`pnpm typecheck`)
2. **ESLint自動修正** (`pnpm lint:fix`)
3. **Prettierフォーマット** (`pnpm format`)

エラーが検出された場合は、Claude Codeにフィードバックが返され、エラー内容が表示されます。

#### 設定ファイル

- **Hook設定**: `.claude/settings.json`
- **Hookスクリプト**: `.claude/hooks/post-edit-format.sh`

#### 注意事項

- Hooksは自動的に実行されるため、Claude Codeが`pnpm ci-check`を実行する必要はありません

---

## アーキテクチャ

### プロジェクト構造

```
src/
├── app/                    # Next.js App Router
│   ├── api/               # APIルート
│   │   ├── auth/          # NextAuthエンドポイント
│   │   └── trpc/          # tRPCハンドラ
│   ├── _components/       # ページ固有のコンポーネント
│   ├── layout.tsx         # ルートレイアウト
│   └── page.tsx           # ホームページ
├── server/                 # バックエンドロジック
│   ├── api/               # tRPCルーター
│   ├── auth/              # 認証設定
│   ├── db/                # データベース層
│   │   └── schema/        # Drizzleスキーマ
│   ├── modules/           # ドメインモジュール（4層アーキテクチャ）
│   ├── types/             # 共通型定義
│   └── utils/             # ユーティリティ
├── trpc/                   # tRPCクライアント設定
└── styles/                 # グローバルスタイル
```

### 4層バックエンド設計

各機能は `src/server/modules/{domain}/{action}/` 配下で厳格な階層アーキテクチャに従います：

#### レイヤー構造

1. **エンドポイント層** (`endpoint.trpc.ts`)
   - tRPCプロシージャの定義
   - `protectedProcedure`による認証処理
   - `Result<T, AppError>`から`TRPCError`への変換
   - ユーザーコンテキストの抽出とサービスへの渡し

2. **サービス層** (`service.ts`)
   - ビジネスロジックの実装
   - Zodの`.safeParse()`による入力検証
   - `Result<T, AppError>`パターンでのエラーハンドリング
   - データベーストランザクション管理
   - リポジトリメソッドの呼び出し

3. **リポジトリ層** (`_repo.ts`)
   - データベースアクセスロジック
   - Drizzle ORMを使用したクエリ
   - トランザクション対応のための`DBLike`型を受け取る
   - すべての操作で`Result<T, AppError>`を返す

4. **DTO層** (`_dto.ts`)
   - データ変換ロジック
   - Zodスキーマ定義
   - モデル変換のための`toDTO()`関数

#### モジュール構成

```
src/server/modules/
└── note/                    # ドメイン
    ├── _dto.ts             # 共有DTO（ドメインレベル）
    ├── _repo.ts            # リポジトリ（ドメインレベル）
    ├── create/             # アクション/ユースケース
    │   ├── contract.ts     # I/Oスキーマ
    │   ├── service.ts      # ビジネスロジック
    │   └── endpoint.trpc.ts # tRPCエンドポイント
    ├── update/
    ├── delete/
    └── list/
```

### Contract設計パターン

各`contract.ts`は4つのスキーマを定義します：

```typescript
// 外部API境界（tRPC）
export const request = z.object({...});  // クライアントから受け取る
export const response = NoteDTO;         // クライアントに返す

// 内部サービス境界
export const input = z.object({          // サービス入力
  userId: UserId,                        // コンテキストから追加
  ...request.shape                       // リクエストデータも含む
});
export const output = NoteDTO;           // サービス出力
```

この分離により以下が可能になります：

- API/サービス境界の明確化
- コンテキスト注入（例：userId）
- 内部検証ルールの適用
- 全レイヤーでの型安全性

### 共通パターン

#### サービス実装

```typescript
export const execute = async (
  deps: Deps,
  cmd: Request,
): AsyncResult<Output, AppError> => {
  // 認証チェック
  if (!deps.authUserId) return Err(Errors.auth());

  // バリデーション
  const parsed = input.safeParse({
    userId: deps.authUserId,
    ...cmd,
  });
  if (!parsed.success) {
    return Err(Errors.validation("INVALID_INPUT", parsed.error.issues));
  }

  // トランザクション
  return deps.db.transaction(async tx => {
    const result = await repository(tx as DBLike, parsed.data);
    if (!result.success) return Err(result.error);
    return Ok(toDTO(result.data));
  });
};
```

#### エンドポイント実装

```typescript
export const createNote = protectedProcedure
  .input(request)
  .output(response)
  .mutation(async ({ ctx, input }) => {
    const deps = createAuthDeps(ctx.db, UserId.parse(ctx.session.user.id));
    const result = await execute(deps, input);
    if (!result.success) throw toTrpcError(result.error);
    return result.data;
  });
```

---

## 技術設定

### エラーハンドリング

#### Result型パターン

Go言語に触発された明示的エラーハンドリング用のResult型：

```typescript
type Result<T, E> = Ok<T> | Err<E>;
type AsyncResult<T, E = Error> = Promise<Result<T, E>>;

// 使用例
const result = await someOperation();
if (!result.success) {
  return Err(result.error);
}
return Ok(result.data);
```

#### AppError型

構造化されたエラー表現：

```typescript
type AppError = {
  kind: ErrorKind; // "validation" | "not_found" | "conflict" | "auth" | ...
  code: string; // 機械判定用コード
  message?: string; // 内部向けメッセージ
  safeMessage?: string; // ユーザー向けメッセージ
  details?: unknown; // 追加情報（例：ZodIssue[]）
  cause?: unknown; // 元のエラー
};
```

エラーファクトリ：

```typescript
Errors.validation("INVALID_INPUT", zodError.issues);
Errors.notFound();
Errors.auth();
Errors.infraDb("DB_ERROR", error);
```

### 型システム

#### Brand型

型安全な識別子（`src/server/types/brand.ts`）：

```typescript
type Brand<T, B> = T & { __brand: B };
type UserId = Brand<string, "UserId">;
type NoteId = Brand<string, "NoteId">;

// 型レベルのID安全性
const userId: UserId = UserId.parse("user_123");
const postId: PostId = PostId.parse("post_456");
// コンパイル時にuserIdとpostIdを混同できない
```

#### DBLike型

トランザクション対応のデータベース抽象化：

```typescript
type DBLike = typeof db | Parameters<Parameters<typeof db.transaction>[0]>[0];
```

すべてのリポジトリ関数は柔軟なトランザクションサポートのため`DBLike`を受け取ります。

#### トランザクション管理

アトミック操作のためにサービス層でトランザクションを管理：

```typescript
return deps.db.transaction(async tx => {
  // 1つのトランザクション内で複数のリポジトリ操作
  const post = await insertPost(tx as DBLike, postData);
  await updateUserPostCount(tx as DBLike, userId);
  return Ok(toDTO(post));
});
```

### データベース（Drizzle ORM）

#### 設定

- **スキーマの場所**：`src/server/db/schema/`
- **テーブルプレフィックス**：`template_`（マルチプロジェクトスキーマ対応）
- **型推論**：Drizzleから`InsertNote`、`SelectNote`など
- **リレーション**：`schema/relations.ts`で定義

#### Docker設定

PostgreSQLデータベースはDockerで実行：

- **ポート**：5334（設定可能）
- **デフォルト認証情報**：postgres/postgres
- **データベース名**：template

### tRPC設定

- **Transformer**：SuperJSON（Date、Map、Setなどを処理）
- **Error Formatter**：ZodErrorsを自動的にフラット化
- **Timing Middleware**：開発環境で100-500msの人工的遅延を追加
- **Auth Middleware**：`protectedProcedure`でセッション検証
- **Context**：`db`、`session`、`headers`を提供

### 認証（NextAuth.js v5）

- **Adapter**：Drizzleアダプター
- **Providers**：Discord OAuth（拡張可能）
- **Session Strategy**：データベースセッション
- **Tables**：`template_`プレフィックス付きの`users`、`accounts`、`sessions`

#### 認証と認可パターン

認証が必要なエンドポイントには`protectedProcedure`を使用：

```typescript
export const createPost = protectedProcedure
  .input(request)
  .output(response)
  .mutation(async ({ ctx, input }) => {
    // ctx.session.userが保証される
    const deps = createAuthDeps(ctx.db, UserId.parse(ctx.session.user.id));
    // ...
  });
```

### 環境変数設定

環境変数は`@t3-oss/env-nextjs`を使用して検証されます。スキーマは`/src/env.js`で定義され、実行時に検証されます。

#### 必須変数

- `AUTH_SECRET` - NextAuthシークレット（本番環境のみ）
- `AUTH_DISCORD_ID` - Discord OAuthアプリID
- `AUTH_DISCORD_SECRET` - Discord OAuthシークレット
- `POSTGRES_*` - データベース接続（DATABASE_URLに統合）

#### 設定例（`.env`）

```env
# 認証シークレット（本番環境では必須）
AUTH_SECRET="your-secret-key"

# Discord OAuth（認証プロバイダー）
AUTH_DISCORD_ID="your-discord-app-id"
AUTH_DISCORD_SECRET="your-discord-app-secret"

# PostgreSQL接続
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=template
POSTGRES_HOST=localhost
POSTGRES_PORT=5334
```

### MCPサーバー

プロジェクトにはModel Context Protocolサーバー（`.mcp.json`）が含まれています：

- **context7** - コンテキスト管理
- **playwright** - ブラウザ自動化
- **figma-dev-mode** - Figma統合
- **chakra-ui** - コンポーネントライブラリ

---

## リファレンス

### テストアプローチ

現在、テストフレームワークは設定されていませんが、アーキテクチャは以下をサポートします：

- モック依存関係を使用したサービスのユニットテスト
- テストトランザクションを使用したリポジトリテスト
- tRPCクライアント経由のE2Eテスト
- 第一防衛線としての型チェック

### トラブルシューティング

#### データベースに接続できない

```bash
# Dockerが起動しているか確認
docker compose ps

# 起動していない場合、起動
docker compose up -d

# ログを確認
docker compose logs postgres
```

#### 型エラー

```bash
# 型チェック実行
pnpm typecheck

# 必要に応じて依存関係を再インストール
rm -rf node_modules pnpm-lock.yaml
pnpm install
```

#### マイグレーションエラー

```bash
# スキーマを強制リセット（開発環境のみ）
docker compose down -v
docker compose up -d
pnpm db:push
```

#### ポートが既に使用されている

ポート3304または5334が既に使用されている場合：

```bash
# ポートを使用しているプロセスを見つけて停止（macOS/Linux）
lsof -ti:3304 | xargs kill -9
lsof -ti:5334 | xargs kill -9

# またはpackage.jsonとdocker-compose.yamlでポートを変更
```

### パフォーマンスのベストプラクティス

1. **React Queryの活用** - 適切なキャッシュ設定でAPIコールを削減
2. **動的インポート** - ページ/コンポーネントごとのコード分割
3. **データベースインデックス** - 頻繁にクエリされるカラムにインデックスを追加
4. **トランザクションスコープの最小化** - 必要な操作のみをトランザクション内でラップ
5. **Turbopack** - より高速な開発ビルド（デフォルトで有効）
6. **クエリ最適化** - Drizzleのクエリビルダーを効率的に使用
7. **APIレスポンスキャッシング** - tRPCとReact Queryでスマートキャッシング

### セキュリティプラクティス

- 全レイヤーでの**入力検証**
- Drizzle ORMによる**SQLインジェクション防止**
- 保護されたプロシージャでの**認証チェック**
- ビルド時の**環境変数検証**
- スタック全体での**型安全性**
