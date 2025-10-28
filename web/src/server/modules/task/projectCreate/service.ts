import * as Sentry from "@sentry/nextjs";

import { toDTO } from "@/server/modules/task/_dto";
import { insertProject, insertFirstTask } from "@/server/modules/task/_repo";
import type { UserId } from "@/server/types/brand";
import { type AppError, Errors } from "@/server/types/errors";
import { type AsyncResult, Err, Ok } from "@/server/types/result";
import type { Deps } from "@/server/utils/deps";

import { input, type Output, type Request } from "./contract";

export const execute = async (
  deps: Deps,
  cmd: Request,
): AsyncResult<Output, AppError> => {
  if (!deps.authUserId) {
    return Err(Errors.auth());
  }

  const p = input.safeParse({
    ...cmd,
    userId: deps.authUserId,
  });
  if (!p.success) {
    return Err(Errors.validation("INVALID_INPUT", p.error.issues));
  }

  return Sentry.startSpan(
    {
      name: "task.projectCreate.execute",
      op: "db.tx",
    },
    async () =>
      deps.db.transaction(async tx => {
        const projectResult = await insertProject(tx, {
          userId: p.data.userId as UserId,
          name: p.data.projectName,
        });
        if (!projectResult.success) {
          return Err(projectResult.error);
        }

        const taskResult = await insertFirstTask(tx, {
          userId: p.data.userId as UserId,
          projectId: projectResult.data.id,
          name: p.data.taskName,
        });
        if (!taskResult.success) {
          return Err(taskResult.error);
        }

        return Ok(toDTO(taskResult.data));
      }),
  );
};
