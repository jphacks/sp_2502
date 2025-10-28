import * as Sentry from "@sentry/nextjs";

import type { DBLike } from "@/server/db";
import { toDTO } from "@/server/modules/task/_dto";
import {
  selectTaskById,
  updateTaskStatus,
  selectChildTasksByParentId,
} from "@/server/modules/task/_repo";
import type { UserId, TaskId } from "@/server/types/brand";
import { type AppError, Errors } from "@/server/types/errors";
import { Err, Ok } from "@/server/types/result";
import type { AsyncResult } from "@/server/types/result";
import type { Deps } from "@/server/utils/deps";

import { input, type Output, type Request } from "./contract";

export const execute = async (
  deps: Deps,
  cmd: Request,
): AsyncResult<Output, AppError> => {
  if (!deps.authUserId) {
    return Err(Errors.auth());
  }

  const parsed = input.safeParse({
    ...cmd,
    userId: deps.authUserId,
  });
  if (!parsed.success) {
    return Err(Errors.validation("INVALID_INPUT", parsed.error.issues));
  }

  return Sentry.startSpan(
    {
      name: "task.statusUpdate.execute",
      op: "db.tx",
    },
    async () =>
      deps.db.transaction(async tx => {
        const txDb = tx as DBLike;

        // タスクのステータスを更新
        const updateResult = await updateTaskStatus(txDb, {
          taskId: parsed.data.taskId as TaskId,
          userId: parsed.data.userId as UserId,
          status: parsed.data.status,
        });

        if (!updateResult.success) {
          return Err(updateResult.error);
        }

        const updatedTask = updateResult.data;

        // statusがcompletedになった場合、親タスクの処理を行う
        if (parsed.data.status === "completed" && updatedTask.parentId) {
          const parentTaskResult = await selectTaskById(txDb, {
            taskId: updatedTask.parentId as TaskId,
            userId: parsed.data.userId as UserId,
          });

          if (
            parentTaskResult.success &&
            parentTaskResult.data.status === "waiting"
          ) {
            // 親タスクの全ての子タスクを取得
            const childTasksResult = await selectChildTasksByParentId(txDb, {
              parentId: updatedTask.parentId as TaskId,
              userId: parsed.data.userId as UserId,
            });

            if (!childTasksResult.success) {
              return Err(childTasksResult.error);
            }

            // 全ての子タスクがcompletedかチェック
            const allChildrenCompleted = childTasksResult.data.every(
              task => task.status === "completed",
            );

            // 全ての子タスクがcompletedの場合、親タスクをactiveに更新
            if (allChildrenCompleted) {
              const parentUpdateResult = await updateTaskStatus(txDb, {
                taskId: updatedTask.parentId as TaskId,
                userId: parsed.data.userId as UserId,
                status: "active",
              });

              if (!parentUpdateResult.success) {
                return Err(parentUpdateResult.error);
              }
            }
          }
        }

        return Ok(toDTO(updatedTask));
      }),
  );
};
