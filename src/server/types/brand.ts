import { z } from "zod";

export type Brand<T, B> = T & { __brand: B };

export const UserId = z.string().min(1);
export type UserId = Brand<string, "UserId">;

export const NoteId = z.string().min(1);
export type NoteId = Brand<string, "NoteId">;
