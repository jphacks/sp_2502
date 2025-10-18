import { z } from "zod";

import { NoteDTO } from "@/server/modules/note/_dto";
import { NoteId, UserId } from "@/server/types/brand";

export const request = z.object({
  noteId: z.string(),
});
export const response = NoteDTO;

export const input = z.object({
  userId: UserId,
  noteId: NoteId,
});
export const output = NoteDTO;

export type Request = z.infer<typeof request>;
export type Response = z.infer<typeof response>;
export type Input = z.infer<typeof input>;
export type Output = z.infer<typeof output>;
