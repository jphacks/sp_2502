---
name: UseCase実装
about: バックエンドのユースケース（API）を提案・実装する
title: "[usecase] {domain}/{action}の実装"
labels: "backend, usecase"
assignees: ""
---

# ユースケース実装: {domain}/{action}

## 概要

### ドメイン

<!-- 例: note, user, post, comment など -->

**ドメイン名**:

### アクション

<!-- 例: create, update, delete, list, get など -->

**アクション名**:

### 機能説明

<!-- このユースケースが解決する問題や提供する機能を簡潔に説明 -->

### 認証

- [ ] 認証必須（protectedProcedure）
- [ ] 認証不要（publicProcedure）

### 操作タイプ

- [ ] 読み取り（query）
- [ ] 書き込み（mutation）

---

## API仕様

### リクエスト

<!-- contract.tsのrequestになるクライアントから受け取るデータ -->

```typescript
{
  // フィールド: 型, // 説明
}
```

### レスポンス

<!-- contract.tsのresponseになるクライアントに返すデータ -->

```typescript
{
  // フィールド: 型, // 説明
}
```

### バリデーションルール

## <!-- 特殊なバリデーションがあれば記載 -->

- ***

## 実装チェックリスト

### コード実装

- [ ] `_dto.ts` - DTO定義とtoDTO関数
- [ ] `_repo.ts` - リポジトリ関数
- [ ] `contract.ts` - request/response/input/outputスキーマ
- [ ] `service.ts` - executeビジネスロジック
- [ ] `endpoint.trpc.ts` - tRPCエンドポイント

### 統合

- [ ] ルーター登録（`src/server/api/routers/{domain}.ts`）
- [ ] ルートルーター登録（`src/server/api/root.ts`、新規ドメインの場合）

### 検証

- [ ] `pnpm typecheck` 通過
- [ ] `pnpm ci-check` 通過
- [ ] DBの状態確認

---

## 補足情報

### ビジネスロジックの詳細

<!-- 特殊な処理、複雑なロジックがあれば記載 -->

### 技術的な懸念事項

<!-- パフォーマンス、セキュリティ、外部API連携など -->

### 参考

<!-- 関連するissue/PRや既存実装へのリンク -->

---

## 実装ガイド

詳細な実装方法は以下を参照：

- **usecase-maker agent**: Claude Codeのsub-agentを使用して自動生成
- **既存実装**: `src/server/modules/{domain}/{action}` の既存コード
- **アーキテクチャ**: [CLAUDE.md](/CLAUDE.md)
