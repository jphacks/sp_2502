import { z } from "zod";

import { TaskDTO } from "@/server/modules/task/_dto";
import { UserId } from "@/server/types/brand";

export const request = z.object({
  projectName: z.string().min(1).max(255),
  taskName: z.string().min(1).max(255),
});
export const response = TaskDTO;

export const input = z.object({
  userId: UserId,
  projectName: z.string().min(1).max(255),
  taskName: z.string().min(1).max(255),
});
export const output = TaskDTO;

export type Request = z.infer<typeof request>;
export type Response = z.infer<typeof response>;
export type Input = z.infer<typeof input>;
export type Output = z.infer<typeof output>;
