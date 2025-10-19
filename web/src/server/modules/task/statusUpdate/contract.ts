import { z } from "zod";

import { TaskDTO } from "@/server/modules/task/_dto";
import { TaskId, UserId } from "@/server/types/brand";

export const request = z.object({
  taskId: TaskId,
  status: z.enum(["unprocessed", "active", "completed", "waiting"]),
});
export const response = TaskDTO;

export const input = z.object({
  userId: UserId,
  taskId: TaskId,
  status: z.enum(["unprocessed", "active", "completed", "waiting"]),
});
export const output = TaskDTO;

export type Request = z.infer<typeof request>;
export type Response = z.infer<typeof response>;
export type Input = z.infer<typeof input>;
export type Output = z.infer<typeof output>;
