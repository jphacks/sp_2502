import { z } from "zod";

import type { SelectNote } from "@/server/db/schema/notes";
import { NoteId, UserId } from "@/server/types/brand";

export const NoteDTO = z.object({
  id: NoteId,
  userId: UserId,
  title: z.string().min(1).max(100),
  content: z.string().min(1).max(10000),
  createdAt: z.date(),
  updatedAt: z.date(),
});

export type NoteDTO = z.infer<typeof NoteDTO>;

export const toDTO = (note: SelectNote): NoteDTO => {
  return {
    id: NoteId.parse(note.id),
    userId: UserId.parse(note.userId),
    title: note.title,
    content: note.content,
    createdAt: note.createdAt,
    updatedAt: note.updatedAt ?? note.createdAt,
  };
};
