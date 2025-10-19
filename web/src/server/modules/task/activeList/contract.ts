import { z } from "zod";

import { TaskDTO } from "@/server/modules/task/_dto";
import { UserId } from "@/server/types/brand";

export const request = z.object({
  order: z.enum(["desc", "asc"]).optional().default("desc"),
});
export const response = z.object({
  tasks: z.array(TaskDTO),
});

export const input = z.object({
  userId: UserId,
  order: z.enum(["desc", "asc"]).default("desc"),
});
export const output = z.object({
  tasks: z.array(TaskDTO),
});

export type Request = z.infer<typeof request>;
export type Response = z.infer<typeof response>;
export type Input = z.infer<typeof input>;
export type Output = z.infer<typeof output>;
