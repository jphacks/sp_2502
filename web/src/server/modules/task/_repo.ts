import { and, desc, eq } from "drizzle-orm";

import type { DBLike } from "@/server/db";
import { type SelectTask, tasks } from "@/server/db/schema/tasks";
import type { UserId } from "@/server/types/brand";
import { type AppError, Errors } from "@/server/types/errors";
import { Err, Ok } from "@/server/types/result";
import type { AsyncResult } from "@/server/types/result";

export const selectActiveTasksByUserId = async (
  db: DBLike,
  values: {
    userId: UserId;
  },
  opts?: {
    orderBy?: "desc" | "asc";
  },
): AsyncResult<SelectTask[], AppError> => {
  try {
    const rows = await db
      .select()
      .from(tasks)
      .where(and(eq(tasks.userId, values.userId), eq(tasks.status, "active")))
      .orderBy(
        opts?.orderBy === "asc" ? tasks.createdAt : desc(tasks.createdAt),
      );
    return Ok(rows);
  } catch (e) {
    return Err(Errors.infraDb("DB_ERROR", e));
  }
};
