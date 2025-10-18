import { z } from "zod";

import { NoteDTO } from "@/server/modules/note/_dto";

export const request = z.object({
  noteId: z.string(),
  title: z.string().optional(),
  content: z.string().optional(),
});
export const response = NoteDTO;

export const input = z
  .object({
    noteId: z.string().min(1),
    userId: z.string().min(1),
    title: z.string().min(1).max(100).optional(),
    content: z.string().min(1).max(10000).optional(),
  })
  .refine(data => data.title !== undefined || data.content !== undefined, {
    message: "少なくとも1つの更新項目（titleまたはcontent）が必要です",
  });
export const output = NoteDTO;

export type Request = z.infer<typeof request>;
export type Response = z.infer<typeof response>;
export type Input = z.infer<typeof input>;
export type Output = z.infer<typeof output>;
