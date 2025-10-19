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
} from "@/server/db/schema/tasks";
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

export const insertProject = async (
  db: DBLike,
  values: {
    userId: UserId;
    name: string;
  },
): AsyncResult<SelectProject, AppError> => {
  try {
    const [project] = await db
      .insert(projects)
      .values({
        userId: values.userId,
        name: values.name,
      } satisfies InsertProject)
      .returning();
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
    const [task] = await db
      .insert(tasks)
      .values({
        userId: values.userId,
        projectId: values.projectId,
        name: values.name,
      } satisfies InsertTask)
      .returning();
    if (!task) {
      return Err(Errors.infraDb("DB_ERROR"));
    }

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
    const [deleted] = await db
      .delete(tasks)
      .where(and(eq(tasks.id, values.taskId), eq(tasks.userId, values.userId)))
      .returning();
    if (!deleted) {
      return Err(Errors.notFound());
    }
    return Ok(deleted);
  } catch (e) {
    return Err(Errors.infraDb("DB_ERROR", e));
  }
};
