import { and, desc, eq, sql } from "drizzle-orm";

import type { DBLike } from "@/server/db";
import {
  type InsertNote,
  notes,
  type SelectNote,
} from "@/server/db/schema/notes";
import type { NoteId, UserId } from "@/server/types/brand";
import { type AppError, Errors } from "@/server/types/errors";
import { Err, Ok } from "@/server/types/result";
import type { AsyncResult } from "@/server/types/result";
import { type DefinedPatch, pickDefined } from "@/server/utils/object";

export const insertNote = async (
  db: DBLike,
  values: {
    userId: UserId;
    title: string;
    content: string;
  },
): AsyncResult<SelectNote, AppError> => {
  try {
    const [note] = await db
      .insert(notes)
      .values({
        userId: values.userId,
        title: values.title,
        content: values.content,
      } satisfies InsertNote)
      .returning();
    if (!note) {
      return Err(Errors.infraDb("DB_ERROR"));
    }
    return Ok(note);
  } catch (e) {
    return Err(Errors.infraDb("DB_ERROR", e));
  }
};

export const updateNoteById = async (
  db: DBLike,
  key: {
    id: NoteId;
    userId: UserId;
  },
  values: {
    title?: string;
    content?: string;
  },
): AsyncResult<SelectNote, AppError> => {
  try {
    const patch = pickDefined(values) as DefinedPatch<InsertNote>;

    const [note] = await db
      .update(notes)
      .set({
        ...patch,
        updatedAt: sql`now()`,
      })
      .where(and(eq(notes.id, key.id), eq(notes.userId, key.userId)))
      .returning();
    if (!note) {
      return Err(Errors.notFound());
    }
    return Ok(note as SelectNote);
  } catch (e) {
    return Err(Errors.infraDb("DB_ERROR", e));
  }
};

export const deleteNoteById = async (
  db: DBLike,
  key: {
    id: NoteId;
    userId: UserId;
  },
): AsyncResult<SelectNote, AppError> => {
  try {
    const [note] = await db
      .delete(notes)
      .where(and(eq(notes.id, key.id), eq(notes.userId, key.userId)))
      .returning();
    if (!note) {
      return Err(Errors.notFound());
    }
    return Ok(note);
  } catch (e) {
    return Err(Errors.infraDb("DB_ERROR", e));
  }
};

export async function findNotesByUserId(
  db: DBLike,
  userId: UserId,
  opts?: { limit?: number; offset?: number },
): AsyncResult<SelectNote[], AppError> {
  try {
    const { limit = 50, offset = 0 } = opts ?? {};
    const rows = await db
      .select()
      .from(notes)
      .where(eq(notes.userId, userId))
      .orderBy(desc(notes.createdAt))
      .limit(limit)
      .offset(offset);

    return Ok(rows);
  } catch (e) {
    return Err(Errors.infraDb("DB_ERROR", e));
  }
}
