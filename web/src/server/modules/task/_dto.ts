import { z } from "zod";

import { type SelectTask } from "@/server/db/schema/tasks";
import { UserId, TaskId, ProjectId } from "@/server/types/brand";

export const TaskDTO = z.object({
  id: TaskId,
  userId: UserId,
  projectId: ProjectId,
  name: z.string().min(1).max(100),
  createdAt: z.date(),
  updatedAt: z.date(),
  status: z.enum(["unprocessed", "active", "completed", "waiting"]),
  date: z.date().nullable(),
  priority: z.string().nullable(),
  parentId: TaskId.nullable(),
});
export type TaskDTO = z.infer<typeof TaskDTO>;

export const toDTO = (task: SelectTask): TaskDTO => {
  return {
    id: TaskId.parse(task.id),
    userId: UserId.parse(task.userId),
    projectId: ProjectId.parse(task.projectId),
    name: task.name,
    createdAt: task.createdAt,
    updatedAt: task.updatedAt ?? task.createdAt,
    status: task.status,
    date: task.date,
    priority: task.priority,
    parentId: task.parentId ? TaskId.parse(task.parentId) : null,
  };
};

export const TaskCompleteResultDTO = z.object({
  nextTask: TaskDTO.nullable(),
  activeTasks: z.array(TaskDTO),
});
export type TaskCompleteResultDTO = z.infer<typeof TaskCompleteResultDTO>;
