import { createTRPCRouter } from "@/server/api/trpc";
import { createNote } from "@/server/modules/note/create/endpoint.trpc";
import { deleteNote } from "@/server/modules/note/delete/endpoint.trpc";
import { listNotes } from "@/server/modules/note/list/endpoint.trpc";
import { updateNote } from "@/server/modules/note/update/endpoint.trpc";

export const noteRouter = createTRPCRouter({
  create: createNote,
  list: listNotes,
  update: updateNote,
  delete: deleteNote,
});
