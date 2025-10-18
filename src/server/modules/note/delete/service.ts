import { toDTO } from "@/server/modules/note/_dto";
import { deleteNoteById } from "@/server/modules/note/_repo";
import type { NoteId, UserId } from "@/server/types/brand";
import { type AppError, Errors } from "@/server/types/errors";
import { type AsyncResult, Err, Ok } from "@/server/types/result";
import type { Deps } from "@/server/utils/deps";

import { input, type Output, type Request } from "./contract";

export const execute = async (
  deps: Deps,
  cmd: Request,
): AsyncResult<Output, AppError> => {
  const p = input.safeParse({
    ...cmd,
    userId: deps.authUserId,
  });
  if (!p.success) {
    return Err(Errors.validation("INVALID_INPUT", p.error.issues));
  }

  return deps.db.transaction(async tx => {
    const note = await deleteNoteById(tx, {
      id: p.data.noteId as NoteId,
      userId: p.data.userId as UserId,
    });
    if (!note.success) {
      return Err(note.error);
    }

    return Ok(toDTO(note.data));
  });
};
