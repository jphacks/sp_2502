import * as Sentry from "@sentry/nextjs";
import { and, desc, eq, sql } from "drizzle-orm";

import type { DBLike } from "@/server/db";
import { projects, type SelectProject } from "@/server/db/schema/projects";
import {
  taskChildren,
  type InsertTaskChildren,
} from "@/server/db/schema/task_children";
import {
  tasks,
  type InsertTask,
  type SelectTask,
} from "@/server/db/schema/tasks";
import type { TaskId } from "@/server/types/brand";
import type { ProjectId, UserId } from "@/server/types/brand";
import { type AppError, Errors } from "@/server/types/errors";
import { type AsyncResult, Err, Ok } from "@/server/types/result";

export const insertChildTask = async (
  db: DBLike,
  values: {
    userId: UserId;
    projectId: ProjectId;
    name: string;
    parentId: TaskId;
  },
): AsyncResult<SelectTask, AppError> => {
  try {
    const [task] = await Sentry.startSpan(
      {
        name: "db.insertChildTask",
        op: "db.insert",
      },
      async () =>
        await db
          .insert(tasks)
          .values({
            userId: values.userId,
            projectId: values.projectId,
            name: values.name,
            parentId: values.parentId,
          } satisfies InsertTask)
          .returning(),
    );

    if (!task?.parentId) {
      return Err(Errors.infraDb("DB_ERROR"));
    }

    await Sentry.startSpan(
      {
        name: "db.insertTaskChildren",
        op: "db.insert",
      },
      async () =>
        await db
          .insert(taskChildren)
          .values({
            taskId: task.parentId!,
            childId: task.id,
          } satisfies InsertTaskChildren)
          .returning(),
    );

    return Ok(task);
  } catch (e) {
    return Err(Errors.infraDb("DB_ERROR", e));
  }
};

export const updateChildTaskById = async (
  db: DBLike,
  key: {
    id: TaskId;
    userId: UserId;
    parentId: TaskId;
  },
  values: {
    name?: string;
    status?: InsertTask["status"];
    priority?: InsertTask["priority"];
  },
): AsyncResult<SelectTask, AppError> => {
  try {
    const patch: Partial<InsertTask> = {};
    if (values.name !== undefined) patch.name = values.name;
    if (values.status !== undefined) patch.status = values.status;
    if (values.priority !== undefined) patch.priority = values.priority;
    const [task] = await Sentry.startSpan(
      {
        name: "db.updateChildTaskById",
        op: "db.update",
      },
      async () =>
        await db
          .update(tasks)
          .set({
            ...patch,
            updatedAt: sql`now()`,
          })
          .where(
            and(
              eq(tasks.id, key.id),
              eq(tasks.userId, key.userId),
              eq(tasks.parentId, key.parentId),
            ),
          )
          .returning(),
    );

    if (!task) {
      return Err(Errors.notFound());
    }
    return Ok(task as SelectTask);
  } catch (e) {
    return Err(Errors.infraDb("DB_ERROR", e));
  }
};

export const findProjectByTaskId = async (
  db: DBLike,
  taskId: TaskId,
): AsyncResult<SelectProject, AppError> => {
  try {
    const project = await Sentry.startSpan(
      {
        name: "db.findProjectByTaskId",
        op: "db.select",
      },
      async () =>
        await db
          .select({ project: projects })
          .from(tasks)
          .innerJoin(projects, eq(tasks.projectId, projects.id))
          .where(eq(tasks.id, taskId))
          .limit(1)
          .then(rows => rows[0]?.project ?? null),
    );

    if (!project) {
      return Err(Errors.notFound());
    }

    return Ok(project);
  } catch (e) {
    return Err(Errors.infraDb("DB_ERROR", e));
  }
};

export const findTasksByProjectId = async (
  db: DBLike,
  projectId: ProjectId,
): AsyncResult<SelectTask[], AppError> => {
  try {
    const rows = await Sentry.startSpan(
      {
        name: "db.findTasksByProjectId",
        op: "db.select",
      },
      async () =>
        await db
          .select()
          .from(tasks)
          .where(eq(tasks.projectId, projectId))
          .orderBy(desc(tasks.createdAt)),
    );

    return Ok(rows);
  } catch (e) {
    return Err(Errors.infraDb("DB_ERROR", e));
  }
};

export const findTaskById = async (
  db: DBLike,
  taskId: TaskId,
): AsyncResult<SelectTask, AppError> => {
  try {
    const [task] = await Sentry.startSpan(
      {
        name: "db.findTaskById",
        op: "db.select",
      },
      async () =>
        await db.select().from(tasks).where(eq(tasks.id, taskId)).limit(1),
    );

    if (!task) {
      return Err(Errors.notFound());
    }

    return Ok(task);
  } catch (e) {
    return Err(Errors.infraDb("DB_ERROR", e));
  }
};
