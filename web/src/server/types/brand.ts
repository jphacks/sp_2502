import { z } from "zod";

export type Brand<T, B> = T & { __brand: B };

export const UserId = z.string().min(1);
export type UserId = Brand<string, "UserId">;

export const NoteId = z.string().min(1);
export type NoteId = Brand<string, "NoteId">;

export const ProjectId = z.string().min(1);
export type ProjectId = Brand<string, "ProjectId">;

export const TaskId = z.string().min(1);
export type TaskId = Brand<string, "TaskId">;

export const TaskChildrenId = z.string().min(1);
export type TaskChildrenId = Brand<string, "TaskChildrenId">;
