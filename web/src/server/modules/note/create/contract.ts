import { z } from "zod";

import { NoteDTO } from "@/server/modules/note/_dto";
import { UserId } from "@/server/types/brand";

export const request = z.object({
  title: z.string(),
  content: z.string(),
});
export const response = NoteDTO;

export const input = z.object({
  userId: UserId,
  title: z.string().min(1).max(100),
  content: z.string().min(1).max(10000),
});
export const output = NoteDTO;

export type Request = z.infer<typeof request>;
export type Response = z.infer<typeof response>;
export type Input = z.infer<typeof input>;
export type Output = z.infer<typeof output>;
