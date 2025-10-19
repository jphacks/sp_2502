import type { DBLike } from "@/server/db";
import { toDTO } from "@/server/modules/task/_dto";
import { selectTaskById } from "@/server/modules/task/_repo";
import type { TaskId, UserId } from "@/server/types/brand";
import { type AppError, Errors } from "@/server/types/errors";
import { type AsyncResult, Err, Ok } from "@/server/types/result";
import type { Deps } from "@/server/utils/deps";

import { input, type Output, type Request } from "./contract";

const MAX_DEPTH = 100; // 循環参照防止用の最大深度

export const execute = async (
  deps: Deps,
  cmd: Request,
): AsyncResult<Output, AppError> => {
  // 認証チェック
  if (!deps.authUserId) return Err(Errors.auth());

  // バリデーション
  const p = input.safeParse({
    userId: deps.authUserId,
    taskId: cmd.task_id,
  });
  if (!p.success) {
    return Err(Errors.validation("INVALID_INPUT", p.error.issues));
  }

  return deps.db.transaction(async tx => {
    const txDb = tx as DBLike;
    const taskChain: Output = [];
    let currentTaskId: string | null = p.data.taskId;
    let depth = 0;

    // 親タスクを辿る
    while (currentTaskId !== null && depth < MAX_DEPTH) {
      const taskResult = await selectTaskById(txDb, {
        taskId: currentTaskId as TaskId,
        userId: p.data.userId as UserId,
      });

      if (!taskResult.success) {
        return Err(taskResult.error);
      }

      const task = taskResult.data;

      // 親タスクIDを取得
      currentTaskId = task.parentId;

      // 最初のタスク（指定されたタスク自身）はスキップ
      if (depth > 0) {
        taskChain.push(toDTO(task)); // 配列の末尾に追加（親から順になるように）
      }

      depth++;
    }

    // 最大深度に達した場合はエラー
    if (depth >= MAX_DEPTH) {
      return Err(
        Errors.validation("MAX_DEPTH_EXCEEDED", [
          {
            code: "custom",
            path: ["task_id"],
            message: "Task hierarchy exceeds maximum depth",
          },
        ]),
      );
    }

    return Ok(taskChain);
  });
};
