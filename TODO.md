# TODO: バックエンド実装が必要なエンドポイント

## task.unprocessedList

### 概要
未処理タスク（status="unprocessed"）の一覧を取得するエンドポイント

### エンドポイント
`GET /api/trpc/task.unprocessedList`

### リクエスト
```typescript
{
  order?: "desc" | "asc"  // デフォルト: "desc"
}
```

### レスポンス
```typescript
{
  tasks: Array<TaskDTO>
}

// TaskDTO構造（既存のtask.activeListと同じ）
{
  id: string,              // TaskId Brand型
  userId: string,          // UserId Brand型
  projectId: string,       // ProjectId Brand型
  name: string,            // 1-100文字
  createdAt: Date,
  updatedAt: Date,
  status: "unprocessed" | "active" | "completed" | "waiting",
  date: Date | null,
  priority: string | null,
  parentId: string | null  // TaskId Brand型
}
```

### 実装参考
既存の `task.activeList` エンドポイント（`src/server/modules/task/active-list/`）を参考にして、
statusフィルタを "unprocessed" に変更した同様の構造で実装してください。

### iOS側での使用箇所
- `CardViewModel.loadCards()` でカード一覧取得時に使用
- タスクステータスが "unprocessed" のもののみ表示する
