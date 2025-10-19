import { z } from "zod";

import { TaskCompleteResultDTO } from "@/server/modules/task/_dto";
import { TaskId, UserId } from "@/server/types/brand";

export const request = z.object({
  taskId: TaskId,
});
export const response = TaskCompleteResultDTO;

export const input = z.object({
  userId: UserId,
  taskId: TaskId,
});
export const output = TaskCompleteResultDTO;

export type Request = z.infer<typeof request>;
export type Response = z.infer<typeof response>;
export type Input = z.infer<typeof input>;
export type Output = z.infer<typeof output>;
