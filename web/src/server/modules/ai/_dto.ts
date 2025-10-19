import { z } from "zod";

import type { SelectTask } from "@/server/db/schema/tasks";
import { ProjectId, TaskId, UserId } from "@/server/types/brand";

export const TaskDTO = z.object({
  id: TaskId,
  userId: UserId,
  projectId: ProjectId,
  name: z.string(),
  date: z.date().nullable(),
  status: z.enum(["unprocessed", "active", "completed", "waiting"]),
  priority: z.string().nullable(),
  parentId: TaskId.nullable(),
  createdAt: z.date(),
  updatedAt: z.date().nullable(),
});

export type TaskDTO = z.infer<typeof TaskDTO>;

export const SplitTaskResultDTO = z.object({
  first_task_id: TaskId,
  first_task_name: z.string(),
  second_task_id: TaskId,
  second_task_name: z.string(),
});

export type SplitTaskResultDTO = z.infer<typeof SplitTaskResultDTO>;

export const toTaskDTO = (task: SelectTask): TaskDTO => ({
  id: TaskId.parse(task.id),
  userId: UserId.parse(task.userId),
  projectId: ProjectId.parse(task.projectId),
  name: task.name,
  date: task.date,
  status: task.status,
  priority: task.priority,
  parentId: task.parentId ? TaskId.parse(task.parentId) : null,
  createdAt: task.createdAt,
  updatedAt: task.updatedAt,
});
