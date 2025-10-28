import * as Sentry from "@sentry/nextjs";

import type { DBLike } from "@/server/db";
import { toDTO } from "@/server/modules/task/_dto";
import {
  selectTaskById,
  updateTaskStatus,
  selectChildTasksByParentId,
  selectActiveTasksByUserId,
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
      name: "task.complete.execute",
      op: "db.tx",
    },
    async () =>
      deps.db.transaction(async tx => {
        const txDb = tx as DBLike;

        // タスクをcompletedに更新
        const updateResult = await updateTaskStatus(txDb, {
          taskId: parsed.data.taskId as TaskId,
          userId: parsed.data.userId as UserId,
          status: "completed",
        });

        if (!updateResult.success) {
          return Err(updateResult.error);
        }

        const completedTask = updateResult.data;
        let nextTask = null;

        // 親タスクの処理
        if (completedTask.parentId) {
          const parentTaskResult = await selectTaskById(txDb, {
            taskId: completedTask.parentId as TaskId,
            userId: parsed.data.userId as UserId,
          });

          if (
            parentTaskResult.success &&
            parentTaskResult.data.status === "waiting"
          ) {
            // 親タスクの全ての子タスクを取得
            const childTasksResult = await selectChildTasksByParentId(txDb, {
              parentId: completedTask.parentId as TaskId,
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
                taskId: completedTask.parentId as TaskId,
                userId: parsed.data.userId as UserId,
                status: "active",
              });

              if (!parentUpdateResult.success) {
                return Err(parentUpdateResult.error);
              }

              // 親タスクがactiveになったので、それを次のタスクとする
              nextTask = toDTO(parentUpdateResult.data);
            } else {
              // 親はまだwaiting → 同じ親を持つ他のactiveタスクを探す
              const siblingTasksResult = await selectChildTasksByParentId(
                txDb,
                {
                  parentId: completedTask.parentId as TaskId,
                  userId: parsed.data.userId as UserId,
                },
              );

              if (siblingTasksResult.success) {
                const activeSibling = siblingTasksResult.data.find(
                  task => task.status === "active",
                );
                if (activeSibling) {
                  nextTask = toDTO(activeSibling);
                }
              }
            }
          }
        }

        // 更新後のアクティブタスク一覧を取得
        const activeTasksResult = await selectActiveTasksByUserId(txDb, {
          userId: parsed.data.userId as UserId,
        });

        if (!activeTasksResult.success) {
          return Err(activeTasksResult.error);
        }

        return Ok({
          nextTask,
          activeTasks: activeTasksResult.data.map(toDTO),
        });
      }),
  );
};
