import { toDTO } from "@/server/modules/task/_dto";
import { selectUnprocessedTasksByUserId } from "@/server/modules/task/_repo";
import type { UserId } from "@/server/types/brand";
import { type AppError, Errors } from "@/server/types/errors";
import { type AsyncResult, Err, Ok } from "@/server/types/result";
import type { Deps } from "@/server/utils/deps";

import { input, type Output, type Request } from "./contract";

export const execute = async (
  deps: Deps,
  cmd: Request,
): AsyncResult<Output, AppError> => {
  const p = input.safeParse({
    ...cmd,
    userId: deps.authUserId,
  });
  if (!p.success) {
    return Err(Errors.validation("INVALID_INPUT", p.error.issues));
  }

  return deps.db.transaction(async tx => {
    const result = await selectUnprocessedTasksByUserId(
      tx,
      { userId: p.data.userId as UserId },
      { orderBy: p.data.order },
    );
    if (!result.success) {
      return Err(result.error);
    }

    return Ok({
      tasks: result.data.map(toDTO),
    });
  });
};
