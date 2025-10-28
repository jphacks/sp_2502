import * as Sentry from "@sentry/nextjs";
import { and, desc, eq, sql } from "drizzle-orm";

import type { DBLike } from "@/server/db";
import {
  type InsertProject,
  type SelectProject,
  projects,
} from "@/server/db/schema/projects";
import {
  type InsertTask,
  type SelectTask,
  tasks,
  type taskStatusEnum,
} from "@/server/db/schema/tasks";
import type { UserId, TaskId } from "@/server/types/brand";
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
    const rows = await Sentry.startSpan(
      {
        name: "db.selectActiveTasksByUserId",
        op: "db.select",
      },
      async () =>
        await db
          .select()
          .from(tasks)
          .where(
            and(eq(tasks.userId, values.userId), eq(tasks.status, "active")),
          )
          .orderBy(
            opts?.orderBy === "asc" ? tasks.createdAt : desc(tasks.createdAt),
          ),
    );

    return Ok(rows);
  } catch (e) {
    return Err(Errors.infraDb("DB_ERROR", e));
  }
};

export const selectUnprocessedTasksByUserId = async (
  db: DBLike,
  values: {
    userId: UserId;
  },
  opts?: {
    orderBy?: "desc" | "asc";
  },
): AsyncResult<SelectTask[], AppError> => {
  try {
    const rows = await Sentry.startSpan(
      {
        name: "db.selectUnprocessedTasksByUserId",
        op: "db.select",
      },
      async () =>
        await db
          .select()
          .from(tasks)
          .where(
            and(
              eq(tasks.userId, values.userId),
              eq(tasks.status, "unprocessed"),
            ),
          )
          .orderBy(
            opts?.orderBy === "asc" ? tasks.createdAt : desc(tasks.createdAt),
          ),
    );
    return Ok(rows);
  } catch (e) {
    return Err(Errors.infraDb("DB_ERROR", e));
  }
};

export const insertProject = async (
  db: DBLike,
  values: {
    userId: UserId;
    name: string;
  },
): AsyncResult<SelectProject, AppError> => {
  try {
    const [project] = await Sentry.startSpan(
      {
        name: "db.insertProject",
        op: "db.insert",
      },
      async () =>
        await db
          .insert(projects)
          .values({
            userId: values.userId,
            name: values.name,
          } satisfies InsertProject)
          .returning(),
    );
    if (!project) {
      return Err(Errors.infraDb("DB_ERROR"));
    }
    return Ok(project);
  } catch (e) {
    return Err(Errors.infraDb("DB_ERROR", e));
  }
};

export const insertFirstTask = async (
  db: DBLike,
  values: {
    userId: UserId;
    projectId: string;
    name: string;
  },
): AsyncResult<SelectTask, AppError> => {
  try {
    const [task] = await Sentry.startSpan(
      {
        name: "db.insertFirstTask",
        op: "db.insert",
      },
      async () =>
        await db
          .insert(tasks)
          .values({
            userId: values.userId,
            projectId: values.projectId,
            name: values.name,
          } satisfies InsertTask)
          .returning(),
    );
    if (!task) {
      return Err(Errors.infraDb("DB_ERROR"));
    }

    await Sentry.startSpan(
      {
        name: "db.updateProjectRootTaskId",
        op: "db.update",
      },
      async () =>
        await db
          .update(projects)
          .set({
            rootTaskId: task.id,
            updatedAt: sql`now()`,
          })
          .where(
            and(
              eq(projects.id, values.projectId),
              eq(projects.userId, values.userId),
            ),
          ),
    );

    return Ok(task);
  } catch (e) {
    return Err(Errors.infraDb("DB_ERROR", e));
  }
};

export const deleteTask = async (
  db: DBLike,
  values: {
    taskId: string;
    userId: UserId;
  },
): AsyncResult<SelectTask, AppError> => {
  try {
    const [deleted] = await Sentry.startSpan(
      {
        name: "db.deleteTask",
        op: "db.delete",
      },
      async () =>
        await db
          .delete(tasks)
          .where(
            and(eq(tasks.id, values.taskId), eq(tasks.userId, values.userId)),
          )
          .returning(),
    );
    if (!deleted) {
      return Err(Errors.notFound());
    }
    return Ok(deleted);
  } catch (e) {
    return Err(Errors.infraDb("DB_ERROR", e));
  }
};

export const selectTaskById = async (
  db: DBLike,
  values: {
    taskId: TaskId;
    userId: UserId;
  },
): AsyncResult<SelectTask, AppError> => {
  try {
    const [task] = await Sentry.startSpan(
      {
        name: "db.selectTaskById",
        op: "db.select",
      },
      async () =>
        await db
          .select()
          .from(tasks)
          .where(
            and(eq(tasks.id, values.taskId), eq(tasks.userId, values.userId)),
          )
          .limit(1),
    );
    if (!task) {
      return Err(Errors.notFound());
    }
    return Ok(task);
  } catch (e) {
    return Err(Errors.infraDb("DB_ERROR", e));
  }
};

export const selectChildTasksByParentId = async (
  db: DBLike,
  values: {
    parentId: TaskId;
    userId: UserId;
  },
): AsyncResult<SelectTask[], AppError> => {
  try {
    const rows = await Sentry.startSpan(
      {
        name: "db.selectChildTasksByParentId",
        op: "db.select",
      },
      async () =>
        await db
          .select()
          .from(tasks)
          .where(
            and(
              eq(tasks.parentId, values.parentId),
              eq(tasks.userId, values.userId),
            ),
          ),
    );
    return Ok(rows);
  } catch (e) {
    return Err(Errors.infraDb("DB_ERROR", e));
  }
};

export const updateTaskStatus = async (
  db: DBLike,
  values: {
    taskId: TaskId;
    userId: UserId;
    status: (typeof taskStatusEnum.enumValues)[number];
  },
): AsyncResult<SelectTask, AppError> => {
  try {
    const [updated] = await Sentry.startSpan(
      {
        name: "db.updateTaskStatus",
        op: "db.update",
      },
      async () =>
        await db
          .update(tasks)
          .set({
            status: values.status,
            updatedAt: sql`now()`,
          })
          .where(
            and(eq(tasks.id, values.taskId), eq(tasks.userId, values.userId)),
          )
          .returning(),
    );
    if (!updated) {
      return Err(Errors.notFound());
    }
    return Ok(updated);
  } catch (e) {
    return Err(Errors.infraDb("DB_ERROR", e));
  }
};
