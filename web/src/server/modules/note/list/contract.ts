import { z } from "zod";

import { NoteDTO } from "@/server/modules/note/_dto";
import { UserId } from "@/server/types/brand";

export const request = z.object({
  limit: z.number().int().min(1).max(100).optional().default(50),
  offset: z.number().int().min(0).optional().default(0),
});
export const response = z.object({
  notes: z.array(NoteDTO),
});

export const input = z.object({
  userId: UserId,
  limit: z.number().int().min(1).max(100).default(50),
  offset: z.number().int().min(0).default(0),
});
export const output = z.object({
  notes: z.array(NoteDTO),
});

export type Request = z.infer<typeof request>;
export type Response = z.infer<typeof response>;
export type Input = z.infer<typeof input>;
export type Output = z.infer<typeof output>;
