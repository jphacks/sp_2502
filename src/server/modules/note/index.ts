import { insertNote, findNotesByUserId } from "./_repo";

export const Notes = {
  commands: {
    create: insertNote,
  },
  queries: {
    findByUserId: findNotesByUserId,
  },
};
