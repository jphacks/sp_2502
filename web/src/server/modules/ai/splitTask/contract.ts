import { z } from "zod";

import { TaskId, UserId } from "@/server/types/brand";

import { SplitTaskResultDTO } from "../_dto";

export const request = z.object({
  taskId: z.string(),
});

export type Request = z.infer<typeof request>;

export const response = SplitTaskResultDTO;

export type Response = z.infer<typeof response>;

export const inputSchema = z.object({
  userId: UserId,
  taskId: TaskId,
});

export type Input = z.infer<typeof inputSchema>;

export const output = response;

export type Output = z.infer<typeof output>;
