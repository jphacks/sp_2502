import { z } from "zod";

import { TaskDTO } from "@/server/modules/task/_dto";
import { TaskId, UserId } from "@/server/types/brand";

// API boundary (minimal rules)
export const request = z.object({
  task_id: TaskId,
});
export const response = z.array(TaskDTO);

// Service boundary (strict rules)
export const input = z.object({
  userId: UserId,
  taskId: TaskId,
});
export const output = z.array(TaskDTO);

export type Request = z.infer<typeof request>;
export type Response = z.infer<typeof response>;
export type Input = z.infer<typeof input>;
export type Output = z.infer<typeof output>;
